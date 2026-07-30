param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Init', 'Status', 'Audit', 'Read', 'Mark')]
    [string]$Mode,
    [string]$RelativePath,
    [int]$Start = -1,
    [int]$End = -1
)

$ErrorActionPreference = 'Stop'
$workspaceRoot = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $PSScriptRoot 'manifest.csv'
$coverageLogPath = Join-Path $PSScriptRoot 'coverage-events.jsonl'
$coverageAuditPath = Join-Path $PSScriptRoot 'coverage-audit.json'
$chunkChars = 7000
$scopes = @(
    '00-book',
    '00-paper',
    '01-book-report',
    '01-paper-report',
    '03-enhanced-report'
)

function Get-Manifest {
    if (-not (Test-Path -LiteralPath $manifestPath)) {
        throw "Manifest not found. Run -Mode Init first."
    }
    return @(Import-Csv -LiteralPath $manifestPath -Encoding UTF8)
}

if ($Mode -eq 'Init') {
    $rows = foreach ($scope in $scopes) {
        $scopePath = Join-Path $workspaceRoot $scope
        Get-ChildItem -LiteralPath $scopePath -Recurse -File -Filter '*.md' |
            Sort-Object FullName |
            ForEach-Object {
                $raw = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
                $relative = $_.FullName.Substring($workspaceRoot.Length + 1)
                $lineCount = if ($raw.Length -eq 0) { 0 } else { ([regex]::Matches($raw, "`n")).Count + 1 }
                [pscustomobject]@{
                    Category    = $scope
                    RelativePath = $relative
                    Bytes       = $_.Length
                    Chars       = $raw.Length
                    Lines       = $lineCount
                    SHA256      = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
                    ChunkChars  = $chunkChars
                    TotalChunks = [Math]::Ceiling($raw.Length / $chunkChars)
                    ReadUntil   = 0
                    Status      = 'PENDING'
                }
            }
    }
    $rows | Export-Csv -LiteralPath $manifestPath -NoTypeInformation -Encoding UTF8
    "INITIALIZED=$($rows.Count)"
    exit 0
}

$manifest = Get-Manifest

if ($Mode -eq 'Status') {
    $manifest |
        Group-Object Category |
        ForEach-Object {
            $completed = @($_.Group | Where-Object Status -eq 'COMPLETE').Count
            $inProgress = @($_.Group | Where-Object Status -eq 'IN_PROGRESS').Count
            $readChars = ($_.Group | Measure-Object -Property ReadUntil -Sum).Sum
            $totalChars = ($_.Group | Measure-Object -Property Chars -Sum).Sum
            "$($_.Name)`tFILES=$($_.Count)`tCOMPLETE=$completed`tIN_PROGRESS=$inProgress`tREAD_CHARS=$readChars`tTOTAL_CHARS=$totalChars"
        }
    exit 0
}

if ($Mode -eq 'Audit') {
    $auditScopes = @('00-book', '00-paper')
    $auditIssues = [System.Collections.Generic.List[string]]::new()
    $auditResults = [System.Collections.Generic.List[object]]::new()

    foreach ($scope in $auditScopes) {
        $scopeRows = @($manifest | Where-Object Category -eq $scope)
        $totalChars = [int64](($scopeRows | Measure-Object -Property Chars -Sum).Sum)
        $readChars = [int64](($scopeRows | Measure-Object -Property ReadUntil -Sum).Sum)
        $complete = @($scopeRows | Where-Object {
            $_.Status -eq 'COMPLETE' -and [int64]$_.ReadUntil -eq [int64]$_.Chars
        }).Count
        $hashOk = 0
        $inconsistent = 0

        foreach ($auditRow in $scopeRows) {
            $auditFullPath = Join-Path $workspaceRoot $auditRow.RelativePath
            if (-not (Test-Path -LiteralPath $auditFullPath)) {
                $auditIssues.Add("MISSING`t$($auditRow.RelativePath)")
                continue
            }

            $auditFile = Get-Item -LiteralPath $auditFullPath
            $auditRaw = Get-Content -LiteralPath $auditFullPath -Raw -Encoding UTF8
            $auditHash = (Get-FileHash -LiteralPath $auditFullPath -Algorithm SHA256).Hash
            if ($auditHash -eq $auditRow.SHA256 -and
                $auditFile.Length -eq [int64]$auditRow.Bytes -and
                $auditRaw.Length -eq [int64]$auditRow.Chars) {
                $hashOk++
            } else {
                $auditIssues.Add("SOURCE_CHANGED`t$($auditRow.RelativePath)")
            }

            $readUntil = [int64]$auditRow.ReadUntil
            $chars = [int64]$auditRow.Chars
            $statusConsistent = (
                $readUntil -ge 0 -and
                $readUntil -le $chars -and
                (($auditRow.Status -eq 'COMPLETE' -and $readUntil -eq $chars) -or
                 ($auditRow.Status -eq 'IN_PROGRESS' -and $readUntil -gt 0 -and $readUntil -lt $chars) -or
                 ($auditRow.Status -eq 'PENDING' -and $readUntil -eq 0))
            )
            if (-not $statusConsistent) {
                $inconsistent++
                $auditIssues.Add("LEDGER_INCONSISTENT`t$($auditRow.RelativePath)")
            }
        }

        $coverage = if ($totalChars -eq 0) { 100 } else { [Math]::Round(($readChars * 100.0) / $totalChars, 6) }
        $auditResults.Add([pscustomobject][ordered]@{
            scope = $scope
            files = $scopeRows.Count
            hash_ok = $hashOk
            complete = $complete
            read_chars = $readChars
            total_chars = $totalChars
            coverage_percent = $coverage
            inconsistent = $inconsistent
        })
        "$scope`tFILES=$($scopeRows.Count)`tHASH_OK=$hashOk`tCOMPLETE=$complete`tREAD_CHARS=$readChars`tTOTAL_CHARS=$totalChars`tCOVERAGE_PERCENT=$coverage`tINCONSISTENT=$inconsistent"
    }

    $auditDocument = [ordered]@{
        audited_at_utc = [DateTime]::UtcNow.ToString('o')
        full_read_scopes = $auditScopes
        excluded_from_full_read = @('01-book-report', '01-paper-report', '03-enhanced-report')
        completion_rule = 'Every current source hash must match and ReadUntil must continuously reach Chars for every file.'
        scopes = $auditResults
        issues = $auditIssues
    }
    Set-Content -LiteralPath $coverageAuditPath -Value ($auditDocument | ConvertTo-Json -Depth 5) -Encoding UTF8

    if ($auditIssues.Count -gt 0) {
        '---AUDIT_ISSUES---'
        $auditIssues
        throw "Coverage audit failed with $($auditIssues.Count) source or ledger issue(s)."
    }
    exit 0
}

if ([string]::IsNullOrWhiteSpace($RelativePath)) {
    throw 'RelativePath is required for Read and Mark.'
}

$row = $manifest | Where-Object RelativePath -eq $RelativePath | Select-Object -First 1
if (-not $row) {
    throw "Path not found in manifest: $RelativePath"
}

$fullPath = Join-Path $workspaceRoot $RelativePath
$currentHash = (Get-FileHash -LiteralPath $fullPath -Algorithm SHA256).Hash
if ($currentHash -ne $row.SHA256) {
    throw "File hash changed: $RelativePath"
}

if ($Mode -eq 'Read') {
    $raw = Get-Content -LiteralPath $fullPath -Raw -Encoding UTF8
    $readStart = if ($Start -ge 0) { $Start } else { [int]$row.ReadUntil }
    if ($readStart -lt 0 -or $readStart -gt $raw.Length) {
        throw "Invalid start offset: $readStart"
    }
    $readLength = [Math]::Min([int]$row.ChunkChars, $raw.Length - $readStart)
    "PATH=$RelativePath START=$readStart END=$($readStart + $readLength) TOTAL=$($raw.Length) SHA256=$currentHash"
    if ($readLength -gt 0) {
        $raw.Substring($readStart, $readLength)
    }
    exit 0
}

if ($Start -lt 0 -or $End -lt 0 -or $End -le $Start) {
    throw 'Mark requires valid Start and End offsets.'
}
if ($Start -ne [int]$row.ReadUntil) {
    throw "Non-contiguous mark. Expected start $($row.ReadUntil), got $Start."
}
if ($End -gt [int]$row.Chars) {
    throw "End exceeds file length."
}

$row.ReadUntil = $End
$row.Status = if ($End -eq [int]$row.Chars) { 'COMPLETE' } else { 'IN_PROGRESS' }
$manifest | Export-Csv -LiteralPath $manifestPath -NoTypeInformation -Encoding UTF8
$coverageEvent = [ordered]@{
    timestamp_utc = [DateTime]::UtcNow.ToString('o')
    path = $RelativePath
    hash = $currentHash
    start = $Start
    end = $End
    total_chars = [int64]$row.Chars
    status = $row.Status
}
Add-Content -LiteralPath $coverageLogPath -Value ($coverageEvent | ConvertTo-Json -Compress) -Encoding UTF8
"MARKED=$RelativePath START=$Start END=$End STATUS=$($row.Status)"


