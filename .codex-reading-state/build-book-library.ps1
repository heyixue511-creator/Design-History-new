param(
    [string]$RepoRoot = 'D:\Design-history-new'
)

$ErrorActionPreference = 'Stop'
$libraryRoot = Join-Path $RepoRoot '07-textbook-writing\00-总纲与规范\文献研究库'
$summariesRoot = Join-Path $libraryRoot 'summaries'
$topicsRoot = Join-Path $libraryRoot 'topics'
$booksPointerRoot = Join-Path $libraryRoot 'books'
$manifestCsv = Join-Path $RepoRoot '.codex-reading-state\manifest.csv'
$assessmentsPath = Join-Path $RepoRoot '.codex-reading-state\source-assessments.md'
$jsonlPath = Join-Path $libraryRoot 'BOOK_MANIFEST.jsonl'

New-Item -ItemType Directory -Force -Path $libraryRoot, $summariesRoot, $topicsRoot, $booksPointerRoot | Out-Null

$rows = Import-Csv -LiteralPath $manifestCsv |
    Where-Object { $_.Category -eq '00-book' } |
    Sort-Object RelativePath

$existingIds = @{}
$maxId = 0
if (Test-Path -LiteralPath $jsonlPath) {
    foreach ($line in Get-Content -LiteralPath $jsonlPath -Encoding UTF8) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $record = $line | ConvertFrom-Json
        $existingIds[$record.path] = $record.id
        if ($record.id -match '^book-(\d+)$') {
            $maxId = [Math]::Max($maxId, [int]$Matches[1])
        }
    }
}

$assessmentMap = @{}
if (Test-Path -LiteralPath $assessmentsPath) {
    $assessmentText = Get-Content -LiteralPath $assessmentsPath -Raw -Encoding UTF8
    $pattern = '(?ms)^### `(?<name>[^`]+)`\r?\n(?<body>.*?)(?=^### `|\z)'
    foreach ($match in [regex]::Matches($assessmentText, $pattern)) {
        $assessmentMap[$match.Groups['name'].Value] = $match.Groups['body'].Value.Trim()
    }
}

function Get-AssessmentBlocks {
    param([string]$Body)

    $blocks = [System.Collections.Generic.List[object]]::new()
    $pattern = '(?m)^-[ \t]+(?<label>[^：:\r\n]+)[：:](?<head>[^\r\n]*)(?<nested>(?:\r?\n[ \t]+[^\r\n]*)*)'
    foreach ($match in [regex]::Matches($Body, $pattern)) {
        $blocks.Add([pscustomobject]@{
            Label = $match.Groups['label'].Value.Trim()
            Head = $match.Groups['head'].Value.Trim()
            Nested = $match.Groups['nested'].Value.TrimEnd()
        })
    }
    return @($blocks)
}

function Format-AssessmentBlocks {
    param(
        [object[]]$Blocks,
        [string]$Fallback
    )

    if (@($Blocks).Count -eq 0) {
        return "- $Fallback"
    }

    $formatted = [System.Collections.Generic.List[string]]::new()
    foreach ($block in @($Blocks)) {
        $line = if ([string]::IsNullOrWhiteSpace($block.Head)) {
            "- **$($block.Label)**："
        } else {
            "- **$($block.Label)**：$($block.Head)"
        }
        if (-not [string]::IsNullOrWhiteSpace($block.Nested)) {
            $line += [Environment]::NewLine + $block.Nested
        }
        $formatted.Add($line)
    }
    return $formatted -join [Environment]::NewLine
}

function Format-BookEvidenceCandidates {
    param([object[]]$Blocks)

    if (@($Blocks).Count -eq 0) {
        return '- 尚无可安全转换的证据候选；须回到原文补充章、节、页码或字符范围。'
    }

    $formatted = [System.Collections.Generic.List[string]]::new()
    foreach ($block in (@($Blocks) | Select-Object -First 4)) {
        $summary = if (-not [string]::IsNullOrWhiteSpace($block.Head)) {
            $block.Head
        } elseif (-not [string]::IsNullOrWhiteSpace($block.Nested)) {
            (($block.Nested -split '\r?\n' | Select-Object -First 1) -replace '^\s*-\s*', '').Trim()
        } else {
            $block.Label
        }
        $formatted.Add(@"
- 结论：$($block.Label)：$summary
  - 原文位置：全文已经连续读取；具体章／节标题、页码或字符范围仍须逐条回查
  - 必要摘录：暂不自动生成，避免把审读转述误作原文
  - 证据状态：已形成审读判断，精确定位待补
"@.TrimEnd())
    }
    return $formatted -join [Environment]::NewLine
}

$records = [System.Collections.Generic.List[object]]::new()
foreach ($row in $rows) {
    $path = $row.RelativePath.Replace('\', '/')
    if ($existingIds.ContainsKey($path)) {
        $id = $existingIds[$path]
    } else {
        $maxId++
        $id = ('book-{0:D4}' -f $maxId)
    }

    $fileName = [System.IO.Path]::GetFileName($row.RelativePath)
    $title = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
    $yearMatch = [regex]::Match($title, '(?:，|,|\(|（)\s*(?<year>(?:18|19|20)\d{2})\s*(?:\)|）)?$')
    $year = if ($yearMatch.Success) { $yearMatch.Value } else { $null }
    $author = if ($title -match '^(.*?)：《') {
        $Matches[1].Trim()
    } elseif ($title -match '^(.*?)：') {
        $Matches[1].Trim()
    } else {
        $null
    }
    if ($author -match '^[\d\s\-–—]+$') {
        $author = $null
    }
    if ($yearMatch.Success) {
        $year = $yearMatch.Groups['year'].Value
    }

    $summaryRelative = "summaries/$id.summary.md"
    $summaryAbsolute = Join-Path $libraryRoot $summaryRelative.Replace('/', '\')
    $readingStatus = $row.Status.ToLowerInvariant()
    $hasAssessment = $assessmentMap.ContainsKey($fileName)
    $summaryStatus = if ($hasAssessment) {
        'structured-needs-evidence-locators'
    } elseif ($row.Status -eq 'IN_PROGRESS') {
        'in-progress'
    } else {
        'pending'
    }

    $isCurated = $false
    $summaryTopics = @()
    if (Test-Path -LiteralPath $summaryAbsolute) {
        $existingSummaryText = Get-Content -LiteralPath $summaryAbsolute -Raw -Encoding UTF8
        if ($existingSummaryText -match "(?m)^summary_status:\s*'(?<status>curated(?:-[^']*)?)'") {
            $isCurated = $true
            $summaryStatus = $Matches['status']
        }
        if ($existingSummaryText -match "(?m)^title:\s*'(?<title>(?:[^']|'')*)'\s*$") {
            $curatedTitle = $Matches['title'].Replace("''", "'").Trim()
            if (-not [string]::IsNullOrWhiteSpace($curatedTitle)) {
                $title = $curatedTitle
            }
        }
        if ($existingSummaryText -match "(?m)^author:\s*'(?<author>(?:[^']|'')*)'\s*$") {
            $curatedAuthor = $Matches['author'].Replace("''", "'").Trim()
            if (-not [string]::IsNullOrWhiteSpace($curatedAuthor)) {
                $author = $curatedAuthor
            }
        }
        if ($isCurated -and $existingSummaryText -match '(?m)^year:\s*(?<year>\d{4})\s*$') {
            $year = $Matches['year']
        } elseif (-not $year -and $existingSummaryText -match '(?m)^year:\s*(?<year>\d{4})\s*$') {
            $year = $Matches['year']
        }
        if ($existingSummaryText -match '(?m)^topics:\s*\[(?<topics>[^\]]*)\]\s*$') {
            $summaryTopics = @($Matches['topics'] -split ',' | ForEach-Object {
                $_.Trim().Trim("'").Trim('"')
            } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        }
    }

    if (-not $isCurated) {
        $yamlTitle = $title.Replace("'", "''")
        $yamlAuthor = if ($author) { $author.Replace("'", "''") } else { '' }
        $sourceRelative = "../../../../$path"
        $body = if ($hasAssessment) {
            $assessmentMap[$fileName]
        } elseif ($row.Status -eq 'IN_PROGRESS') {
            "- 当前已读字符：$($row.ReadUntil) / $($row.Chars)`n- 本文件仍在全文读取中；以下栏目将在完成后定稿。"
        } else {
            "- 当前已读字符：0 / $($row.Chars)`n- 本文件尚未开始连续全文读取；本摘要仅为处理占位，不包含任何由题名推断的主题或观点。"
        }

        if ($hasAssessment) {
            $assessmentBlocks = @(Get-AssessmentBlocks -Body $body)
            $coreBlocks = @($assessmentBlocks | Where-Object {
                $_.Label -match '核心|候选议题|内容范围|体系|总体|方法框架|历史线索'
            } | Select-Object -First 7)
            if ($coreBlocks.Count -eq 0) {
                $coreBlocks = @($assessmentBlocks | Where-Object {
                    $_.Label -notmatch '全文状态|文献性质|版本|证据|风险|使用约束|初步使用定位|章节匹配'
                } | Select-Object -First 5)
            }
            $chapterBlocks = @($assessmentBlocks | Where-Object {
                $_.Label -match '各章|章节|全书叙事结构|内容范围|主要文本|主要历史|历史线索'
            } | Select-Object -First 8)
            $argumentBlocks = @($assessmentBlocks | Where-Object {
                $_.Label -match '核心|论证|体系|框架|方法|历史线索|内容范围|史料|教育|可用|色彩|主要'
            } | Select-Object -First 12)
            $entityBlocks = @($assessmentBlocks | Where-Object {
                $_.Label -match '人物|机构|作品|事件|案例|个案|展览|材料|史料|内容范围|链条'
            } | Select-Object -First 8)
            $timeBlocks = @($assessmentBlocks | Where-Object {
                $_.Label -match '历史|时间|年代|事件|线索|链条|叙事'
            } | Select-Object -First 8)
            $evidenceBlocks = @($assessmentBlocks | Where-Object {
                $_.Label -match '证据|史料|可用|材料'
            } | Select-Object -First 6)
            if ($evidenceBlocks.Count -eq 0) {
                $evidenceBlocks = @($argumentBlocks | Select-Object -First 4)
            }
            $relationBlocks = @($assessmentBlocks | Where-Object {
                $_.Label -match '对话|关系|比较|匹配|候选议题|章节匹配|初步使用定位|使用约束'
            } | Select-Object -First 7)
            $limitBlocks = @($assessmentBlocks | Where-Object {
                $_.Label -match '边界|风险|局限|版本|性质|立场|质量|规则|约束'
            } | Select-Object -First 10)

            $coreSection = Format-AssessmentBlocks -Blocks $coreBlocks -Fallback '全文已读，但核心主题仍需人工归纳。'
            $chapterSection = Format-AssessmentBlocks -Blocks $chapterBlocks -Fallback '审读记录没有单列章节结构；应回查原书目录和章题。'
            $argumentSection = Format-AssessmentBlocks -Blocks $argumentBlocks -Fallback '全文已读，但主要观点仍需人工归纳。'
            $entitySection = Format-AssessmentBlocks -Blocks $entityBlocks -Fallback '审读记录没有单列人物、机构或作品。'
            $timeSection = Format-AssessmentBlocks -Blocks $timeBlocks -Fallback '审读记录没有单列时间、地点或事件。'
            $evidenceSection = Format-BookEvidenceCandidates -Blocks $evidenceBlocks
            $relationSection = Format-AssessmentBlocks -Blocks $relationBlocks -Fallback '跨书主证、互证和争议关系仍须在专题层建立。'
            $limitSection = Format-AssessmentBlocks -Blocks $limitBlocks -Fallback '审读记录没有单列作者立场或证据局限。'
        } else {
            $coreSection = '- 依据全文审读记录持续归纳；专题标签将在跨书比较后写入，避免仅凭文件名预判。'
            $chapterSection = '- 已读材料的章节、主题和论证结构见“全文审读记录”。正式摘要将保留原书章／节标题。'
            $argumentSection = '- 见“全文审读记录”；作者观点、编者观点和历史文献原话须分别标注。'
            $entitySection = '- 见“全文审读记录”；人名、机构、作品名和年代在进入教材前须回查原文及权威记录。'
            $timeSection = '- 见“全文审读记录”；对“第一”“首次”和因果关系等强判断执行交叉核验。'
            $evidenceSection = '- 原文尚未完成，不生成证据结论。'
            $relationSection = '- 原文完成后在专题综合中建立主证、互证、争议与不采用关系。'
            $limitSection = '- 原文尚未完成，不能形成作者立场或证据局限的全文判断。'
        }

        $summaryText = @"
---
id: $id
title: '$yamlTitle'
author: '$yamlAuthor'
year: $year
source: '$sourceRelative'
source_hash: '$($row.SHA256)'
reading_status: '$readingStatus'
summary_status: '$summaryStatus'
read_chars: $($row.ReadUntil)
total_chars: $($row.Chars)
topics: []
generated_from: 'auditable-reading-ledger'
---

# 核心主题

$coreSection

# 章节摘要

$chapterSection

# 主要观点

$argumentSection

# 重要人物、机构与作品

$entitySection

# 时间、地点与历史事件

$timeSection

# 可引用证据

$evidenceSection

# 与其他书籍的关系

$relationSection

# 作者立场与可能局限

$limitSection

# 待核实问题

- 补齐可引用证据的章／节标题、页码、图版号或稳定字符范围。
- 与专项文献、原始档案和较新研究核对关键年代、人物、机构及“首创”判断。

# 全文审读记录

$body
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
        summary = if (Test-Path -LiteralPath $summaryAbsolute) { $summaryRelative } else { $null }
        title = $title
        author = $author
        year = $year
        topics = $summaryTopics
    })
}

$jsonLines = foreach ($record in $records) {
    $record | ConvertTo-Json -Compress -Depth 4
}
Set-Content -LiteralPath $jsonlPath -Value $jsonLines -Encoding UTF8

$indexLines = [System.Collections.Generic.List[string]]::new()
$indexLines.Add('# BOOK_INDEX')
$indexLines.Add('')
$indexLines.Add('> 本索引对应 `00-book` 中的原始Markdown。原文不复制、不改写；编号一经分配不因排序变化而重用。')
$indexLines.Add('')
$indexLines.Add('| 编号 | 书名 | 作者 | 年代 | 读取状态 | 摘要状态 | 摘要 |')
$indexLines.Add('|---|---|---|---:|---|---|---|')
foreach ($record in $records) {
    $safeTitle = $record.title.Replace('|', '\|')
    $safeAuthor = if ($record.author) { $record.author.Replace('|', '\|') } else { '' }
    $yearCell = if ($record.year) { $record.year } else { '' }
    $summaryCell = if ($record.summary) { "[$($record.id)]($($record.summary))" } else { '' }
    $indexLines.Add("| $($record.id) | $safeTitle | $safeAuthor | $yearCell | $($record.reading_status) | $($record.summary_status) | $summaryCell |")
}
Set-Content -LiteralPath (Join-Path $libraryRoot 'BOOK_INDEX.md') -Value $indexLines -Encoding UTF8

$complete = @($records | Where-Object { $_.reading_status -eq 'complete' }).Count
$inProgress = @($records | Where-Object { $_.reading_status -eq 'in_progress' }).Count
$pending = @($records | Where-Object { $_.reading_status -eq 'pending' }).Count
$readChars = ($records | Measure-Object -Property read_until -Sum).Sum
$totalChars = ($records | Measure-Object -Property chars -Sum).Sum

$contextPath = Join-Path $libraryRoot 'PROJECT_CONTEXT.md'
if (Test-Path -LiteralPath $contextPath) {
    # PROJECT_CONTEXT 是人工维护的书库总览。自动更新只刷新两处进度，
    # 不得用机械模板覆盖已经整理的研究范围、冲突和证据规则。
    $contextText = Get-Content -LiteralPath $contextPath -Raw -Encoding UTF8
    $progressSentence = '当前书籍层共登记 {0} 个 Markdown 文件，总字符数 {1:N0}。已经全文读完 {2} 个，正在读取 {3} 个，待读 {4} 个；已审计读取 {5:N0} 字符。原始论文目录 `00-paper/` 也纳入全文读取范围；书籍报告、论文报告和增强报告不再逐文件全文读取，只作按需辅助索引。' -f $records.Count, $totalChars, $complete, $inProgress, $pending, $readChars
    $bookProgress = '- `00-book/`：{0} 个文件；全文完成 {1} 个，在读 {2} 个。' -f $records.Count, $complete, $inProgress
    $contextText = [regex]::Replace($contextText, '当前书籍层共登记[^\r\n]*', $progressSentence, 1)
    $contextText = [regex]::Replace($contextText, '- `00-book/`：[^\r\n]*', $bookProgress, 1)
    Set-Content -LiteralPath $contextPath -Value $contextText -Encoding UTF8
}

$booksReadme = @"
# 原始书籍层

原始Markdown统一保存在仓库根目录 [`00-book`](../../../../00-book)，本目录不复制文件，避免产生两个真源。

任何摘要结论和教材引文都必须回查该目录中的原文。原文哈希及读取状态记录在 [`BOOK_MANIFEST.jsonl`](../BOOK_MANIFEST.jsonl)。
"@
Set-Content -LiteralPath (Join-Path $booksPointerRoot 'README.md') -Value $booksReadme -Encoding UTF8

if (-not (Test-Path -LiteralPath (Join-Path $topicsRoot '00-专题索引.md'))) {
    $topicIndex = @"
# 专题索引

专题文件将在逐书全文读取过程中增量生成。每个专题必须列出：

- 核心问题与时间、地域边界
- 主要证据
- 交叉参照
- 相互冲突的观点
- 不采用或降级使用的材料及原因
- 单书摘要链接与原文定位
- 对应教材章节
"@
    Set-Content -LiteralPath (Join-Path $topicsRoot '00-专题索引.md') -Value $topicIndex -Encoding UTF8
}

if (-not (Test-Path -LiteralPath (Join-Path $libraryRoot 'GLOSSARY.md'))) {
    Set-Content -LiteralPath (Join-Path $libraryRoot 'GLOSSARY.md') -Encoding UTF8 -Value "# GLOSSARY`n`n> 人物、机构、流派和术语将在全文读取及跨书核验中增量写入。每条记录必须链接单书摘要和原文锚点。`n"
}

if (-not (Test-Path -LiteralPath (Join-Path $libraryRoot 'TIMELINE.md'))) {
    Set-Content -LiteralPath (Join-Path $libraryRoot 'TIMELINE.md') -Encoding UTF8 -Value "# TIMELINE`n`n> 年代与事件将在跨书核验后增量写入。存在争议的日期并列记录来源，不提前合并为单一定论。`n"
}

"BOOKS=$($records.Count) COMPLETE=$complete IN_PROGRESS=$inProgress PENDING=$pending READ_CHARS=$readChars TOTAL_CHARS=$totalChars"










