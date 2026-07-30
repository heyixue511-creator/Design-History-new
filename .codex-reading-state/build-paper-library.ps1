param(
    [string]$RepoRoot = 'D:\Design-history-new'
)

$ErrorActionPreference = 'Stop'
$libraryRoot = Join-Path $RepoRoot '07-textbook-writing\00-总纲与规范\文献研究库'
$summariesRoot = Join-Path $libraryRoot 'paper-summaries'
$manifestCsv = Join-Path $RepoRoot '.codex-reading-state\manifest.csv'
$assessmentsPath = Join-Path $RepoRoot '.codex-reading-state\paper-source-assessments.md'
$jsonlPath = Join-Path $libraryRoot 'PAPER_MANIFEST.jsonl'
$indexPath = Join-Path $libraryRoot 'PAPER_INDEX.md'

New-Item -ItemType Directory -Force -Path $libraryRoot, $summariesRoot | Out-Null

$rows = Import-Csv -LiteralPath $manifestCsv -Encoding UTF8 |
    Where-Object { $_.Category -eq '00-paper' } |
    Sort-Object RelativePath

$assessmentMap = @{}
if (Test-Path -LiteralPath $assessmentsPath) {
    $assessmentText = Get-Content -LiteralPath $assessmentsPath -Raw -Encoding UTF8
    $pattern = '(?ms)^### `(?<name>[^`]+)`\r?\n(?<body>.*?)(?=^### `|\z)'
    foreach ($match in [regex]::Matches($assessmentText, $pattern)) {
        $assessmentMap[$match.Groups['name'].Value] = $match.Groups['body'].Value.Trim()
    }
}

function Get-AssessmentItems {
    param([string]$Body)

    $items = [System.Collections.Generic.List[object]]::new()
    foreach ($line in ($Body -split '\r?\n')) {
        if ($line -match '^\s*-\s+(?<label>[^：:]+)[：:]\s*(?<text>.+?)\s*$') {
            $items.Add([pscustomobject]@{
                Label = $Matches['label'].Trim()
                Text = $Matches['text'].Trim()
            })
        }
    }
    return @($items)
}

function Format-AssessmentItems {
    param(
        [object[]]$Items,
        [string]$Fallback
    )

    if (@($Items).Count -eq 0) {
        return "- $Fallback"
    }
    return (@($Items) | ForEach-Object {
        "- **$($_.Label)**：$($_.Text)"
    }) -join [Environment]::NewLine
}

function Format-EvidenceCandidates {
    param([object[]]$Items)

    if (@($Items).Count -eq 0) {
        return @"
- 当前全文审读记录没有可安全自动转换的证据条目；必须回到原文补充章节标题或行号。
"@
    }

    $blocks = [System.Collections.Generic.List[string]]::new()
    foreach ($item in (@($Items) | Select-Object -First 3)) {
        $blocks.Add(@"
- 结论：$($item.Label)：$($item.Text)
  - 原文位置：已完成全文读取；具体章节标题或行号仍须逐条回查
  - 必要摘录：暂不自动生成，避免把审读转述误作原文
  - 证据状态：结论已进入审读记录，精确定位待补
"@.TrimEnd())
    }
    return $blocks -join [Environment]::NewLine
}

$existingIds = @{}
$maxId = 0
if (Test-Path -LiteralPath $jsonlPath) {
    foreach ($line in Get-Content -LiteralPath $jsonlPath -Encoding UTF8) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $oldRecord = $line | ConvertFrom-Json
        $existingIds[$oldRecord.path] = $oldRecord.id
        if ($oldRecord.id -match '^paper-(\d+)$') {
            $maxId = [Math]::Max($maxId, [int]$Matches[1])
        }
    }
}

$records = [System.Collections.Generic.List[object]]::new()
foreach ($row in $rows) {
    $path = $row.RelativePath.Replace('\', '/')
    if ($existingIds.ContainsKey($path)) {
        $id = $existingIds[$path]
    } else {
        $maxId++
        $id = ('paper-{0:D4}' -f $maxId)
    }

    $fileName = [System.IO.Path]::GetFileName($row.RelativePath)
    $title = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
    $summaryRelative = "paper-summaries/$id.summary.md"
    $summaryAbsolute = Join-Path $libraryRoot $summaryRelative.Replace('/', '\')
    $readingStatus = $row.Status.ToLowerInvariant()
    $hasAssessment = $assessmentMap.ContainsKey($fileName)
    $summaryStatus = if ($hasAssessment) {
        'structured-needs-evidence-locators'
    } elseif ($row.Status -eq 'COMPLETE') {
        'complete-needs-curation'
    } elseif ($row.Status -eq 'IN_PROGRESS') {
        'in-progress'
    } else {
        'pending'
    }

    $isCurated = $false
    if (Test-Path -LiteralPath $summaryAbsolute) {
        $existingText = Get-Content -LiteralPath $summaryAbsolute -Raw -Encoding UTF8
        $isCurated = $existingText -match "(?m)^summary_status:\s*'curated'"
    }

    if (-not $isCurated) {
        $yamlTitle = $title.Replace("'", "''")
        $sourceRelative = "../../../../$path"
        $assessmentItems = if ($hasAssessment) {
            @(Get-AssessmentItems -Body $assessmentMap[$fileName])
        } else {
            @()
        }
        $sourceItems = @($assessmentItems | Where-Object {
            $_.Label -match '来源|文本|版本|文件|审计|完整|缺陷'
        })
        $coreItems = @($assessmentItems | Where-Object {
            $_.Label -match '核心|问题|命题|主张|定义|对象|起点|理论位置|总体论旨|总体命题|历史定位|研究空白'
        } | Select-Object -First 6)
        if ($coreItems.Count -eq 0) {
            $coreItems = @($assessmentItems | Where-Object {
                $_.Label -notmatch '来源|文本|版本|文件|审计|完整|缺陷|教材用途|教材章节匹配'
            } | Select-Object -First 4)
        }
        $methodItems = @($assessmentItems | Where-Object {
            $_.Label -match '方法|立场|局限|边界|限定|风险|批评|证据|样本|地域|时效|语言|伦理|自述|自设'
        })
        $caseItems = @($assessmentItems | Where-Object {
            $_.Label -match '人物|机构|作品|事件|案例|个案|展览|会议|组织|院校|学校|材料|支线|篇$'
        })
        $relationItems = @($assessmentItems | Where-Object {
            $_.Label -match '对照|比较|关系|分歧|谱系|互证|支线|跨篇|引用规则|转译'
        })
        $textbookItems = @($assessmentItems | Where-Object {
            $_.Label -match '教材|设计史|史学价值|本项目|章节匹配|研究与教学|学科史'
        })
        $argumentItems = @($assessmentItems | Where-Object {
            $_.Label -notmatch '来源|文本|版本|文件|审计|完整|缺陷|教材用途|教材章节匹配|引用规则'
        } | Select-Object -First 18)

        $sourceSection = Format-AssessmentItems -Items $sourceItems -Fallback '尚无可转换的来源性质记录。'
        $coreSection = Format-AssessmentItems -Items $coreItems -Fallback '全文已读，但核心问题仍需人工归纳。'
        $argumentSection = Format-AssessmentItems -Items $argumentItems -Fallback '全文已读，但论证结构仍需人工归纳。'
        $caseSection = Format-AssessmentItems -Items $caseItems -Fallback '审读记录未单列人物、机构、作品或事件。'
        $relationSection = Format-AssessmentItems -Items $relationItems -Fallback '尚未建立与其他书籍或论文的明确互证关系。'
        $methodSection = Format-AssessmentItems -Items $methodItems -Fallback '审读记录未单列作者方法、立场或局限。'
        $textbookSection = Format-AssessmentItems -Items $textbookItems -Fallback '尚未形成明确教材使用判断。'
        $evidenceSection = Format-EvidenceCandidates -Items $argumentItems
        $statusNote = if ($hasAssessment) {
            '- 原文对应哈希已连续读取至文件末尾；以下标准栏目由逐篇全文审读记录分栏生成，并保留原审读记录供复核。'
        } elseif ($row.Status -eq 'COMPLETE') {
            '- 原文对应哈希已连续读取至文件末尾；以下栏目等待逐项整理。'
        } elseif ($row.Status -eq 'IN_PROGRESS') {
            "- 当前已读字符：$($row.ReadUntil) / $($row.Chars)；尚不能形成全文结论。"
        } else {
            "- 当前已读字符：0 / $($row.Chars)；本摘要仅为处理占位，不依据题名推断内容。"
        }
        $assessmentBody = if ($hasAssessment) {
            $assessmentMap[$fileName]
        } else {
            '- 尚无全文审读记录。'
        }

        $summaryText = @"
---
id: $id
title: '$yamlTitle'
source: '$sourceRelative'
source_hash: '$($row.SHA256)'
reading_status: '$readingStatus'
summary_status: '$summaryStatus'
read_chars: $($row.ReadUntil)
total_chars: $($row.Chars)
source_type: '已由全文审读判定，见“来源性质与完整性”'
topics: []
generated_from: 'auditable-reading-ledger'
---

# 来源性质与完整性

$statusNote
$sourceSection

# 核心问题

$coreSection

# 论证结构与主要观点

$argumentSection

# 人物、机构、作品与事件

$caseSection

# 可引用证据

$evidenceSection

# 与书籍及其他论文的关系

$relationSection

# 作者立场、方法与局限

$methodSection

# 源文件问题

$sourceSection

# 教材适用判断

$textbookSection

# 待核实问题

- 精确证据定位仍须回到对应原文，补充章节标题、页码或稳定行号。
- 对审读记录中涉及的专名、年代和正式书目信息，在进入教材正文前逐项复核。

# 全文审读记录

$assessmentBody
"@
        Set-Content -LiteralPath $summaryAbsolute -Value $summaryText -Encoding UTF8
    }

    $records.Add([pscustomobject][ordered]@{
        id = $id
        path = $path
        hash = $row.SHA256
        bytes = [int64]$row.Bytes
        chars = [int64]$row.Chars
        read_until = [int64]$row.ReadUntil
        reading_status = $readingStatus
        summary_status = $summaryStatus
        summary = $summaryRelative
        title = $title
        topics = @()
    })
}

$jsonLines = foreach ($record in $records) {
    $record | ConvertTo-Json -Compress -Depth 4
}
Set-Content -LiteralPath $jsonlPath -Value $jsonLines -Encoding UTF8

$indexLines = [System.Collections.Generic.List[string]]::new()
$indexLines.Add('# PAPER_INDEX')
$indexLines.Add('')
$indexLines.Add('> 本索引对应 `00-paper/` 中的原始 Markdown。文件名所称“论文”可能实际是书评、会议启事、资料页、目录或不完整摘录，来源性质必须在全文读取后判定。')
$indexLines.Add('')
$indexLines.Add('| 编号 | 题名 | 读取状态 | 摘要状态 | 字符数 | 摘要 |')
$indexLines.Add('|---|---|---|---|---:|---|')
foreach ($record in $records) {
    $safeTitle = $record.title.Replace('|', '\|')
    $indexLines.Add("| $($record.id) | $safeTitle | $($record.reading_status) | $($record.summary_status) | $($record.chars) | [$($record.id)]($($record.summary)) |")
}
Set-Content -LiteralPath $indexPath -Value $indexLines -Encoding UTF8

$complete = @($records | Where-Object reading_status -eq 'complete').Count
$inProgress = @($records | Where-Object reading_status -eq 'in_progress').Count
$readChars = [int64](($records | Measure-Object -Property read_until -Sum).Sum)
$totalChars = [int64](($records | Measure-Object -Property chars -Sum).Sum)
"PAPERS=$($records.Count) COMPLETE=$complete IN_PROGRESS=$inProgress READ_CHARS=$readChars TOTAL_CHARS=$totalChars"













