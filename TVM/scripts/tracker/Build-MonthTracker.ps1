<#
.SYNOPSIS
  Builds (or rebuilds) the monthly tracking workbook YYYY-MM/YYYY-MM_Tracker.xlsx from that month's documents.

.DESCRIPTION
  Reads YYYY-MM/MONTH-INDEX.md and the header table of every REQ, CR, CON, TECH, ATR and MTC document in the
  month folder, then writes one Excel workbook with these sheets:
    Overview, Requirements, Change Records, Conflicts & Open Items, Technical, QA
  The documents are the source of truth: update them first, then run this script.
  Run it only after the project lead has approved the requirement ("all good"), as part of the documentation step.
  Needs Microsoft Excel (COM automation).

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File scripts\tracker\Build-MonthTracker.ps1 -Month 2026-10
#>
param(
    [Parameter(Mandatory = $true)][ValidatePattern('^\d{4}-\d{2}$')][string]$Month,
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
)
$ErrorActionPreference = 'Stop'
$monthDir = Join-Path $ProjectRoot $Month
if (-not (Test-Path $monthDir)) { throw "Month folder not found: $monthDir" }
$outFile = Join-Path $monthDir "$($Month)_Tracker.xlsx"

# ---------- markdown helpers ----------
function Clean([string]$s) {
    if ($null -eq $s) { return '' }
    $s = [regex]::Replace($s, '\[([^\]]+)\]\([^)]*\)', '$1')       # links -> text
    $s = $s -replace '<br\s*/?>', '; ' -replace '\*\*', '' -replace '`', ''
    $s = [regex]::Replace($s, '[\u2600-\u27BF\uFE0F\u2139\u23F8]|[\uD800-\uDFFF]', '')   # emoji (Excel 2007 can't show them)
    ($s -replace '\s+', ' ').Trim(' ', ';')
}
function Read-Lines($path) { [IO.File]::ReadAllLines($path, [Text.Encoding]::UTF8) }
function Get-Title($lines) {
    $h = $lines | Where-Object { $_ -match '^# ' } | Select-Object -First 1
    Clean (($h -replace '^#\s+', '') -replace '^[A-Z]+-\d{3}\s*[\u2014:-]\s*', '')
}
# first "| **Key** | value |" table at the top of a document
function Get-Header($lines) {
    $h = @{}; $inTable = $false
    foreach ($l in $lines) {
        if ($l -match '^\|') { $inTable = $true
            if ($l -match '^\|\s*\*\*(.+?)\*\*\s*\|\s*(.*?)\s*\|\s*$') { $h[$Matches[1].Trim()] = $Matches[2] } }
        elseif ($inTable) { break }
    }
    $h
}
function HVal($h, [string[]]$keys) { foreach ($k in $keys) { foreach ($hk in $h.Keys) { if ($hk -like $k) { return (Clean $h[$hk]) } } }; '' }
# first paragraph of a section (or of the first section when the heading isn't found)
function Get-Section($lines, [string]$heading, [int]$max = 450) {
    $start = -1
    for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match "^## $heading") { $start = $i; break } }
    if ($start -lt 0) { for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match '^## ') { $start = $i; break } } }
    if ($start -lt 0) { return '' }
    $buf = @()
    for ($i = $start + 1; $i -lt $lines.Count; $i++) {
        $l = $lines[$i]; if ($l -match '^#{1,3} ') { break }
        if ($l -match '^\s*$') { if ($buf.Count) { break } else { continue } }
        if ($l -match '^\|') { continue }
        $buf += ($l -replace '^\s*([-*]|\d+\.)\s+', '')
    }
    $t = Clean ($buf -join ' '); if ($t.Length -gt $max) { $t = $t.Substring(0, $max).TrimEnd() + '...' }; $t
}
# first-column values of the table under a heading
function Get-TableCol($lines, [string]$heading) {
    $start = -1
    for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match "^## $heading") { $start = $i; break } }
    if ($start -lt 0) { return '' }
    $vals = @(); $seen = $false
    for ($i = $start + 1; $i -lt $lines.Count; $i++) {
        $l = $lines[$i]
        if ($l -match '^\|') { $seen = $true; $c = Clean (($l.Trim('|') -split '\|')[0]); if ($c -and $c -notmatch '^-+$' -and $c -ne 'Component') { $vals += $c } }
        elseif ($seen -or $l -match '^## ') { break }
    }
    ($vals | Select-Object -Unique) -join '; '
}
function Split-Row([string]$l) { ,@($l.Trim().Trim('|') -split '\|' | ForEach-Object { $_.Trim() }) }
function Find-Doc($folder, $id) { Get-ChildItem (Join-Path $monthDir $folder) -Filter "$id*.md" -ErrorAction SilentlyContinue | Select-Object -First 1 }
function RelLink($file) { $file.FullName.Substring($monthDir.Length + 1) -replace '\\', '/' }
function FirstDate([string]$s) { if ($s -match '(\d{4}-\d{2}-\d{2})') { $Matches[1] } else { '' } }

# ---------- read the month ----------
$idxLines = Read-Lines (Join-Path $monthDir 'MONTH-INDEX.md')
$summary = @(); $inSum = $false
foreach ($l in $idxLines) { if ($l -match '^## Summary') { $inSum = $true; continue }; if ($inSum -and $l -match '^## ') { break }; if ($inSum -and $l -match '^\s*[-*]\s+') { $summary += Clean ($l -replace '^\s*[-*]\s+', '') } }

# Requirement history rows from MONTH-INDEX
$reqs = @()
foreach ($l in $idxLines) {
    if ($l -notmatch '^\|\s*\[?REQ-\d{3}') { continue }
    $c = Split-Row $l
    $id = (Clean $c[0])
    $doc = Find-Doc '03-Requirements' $id
    $statusRaw = Clean $c[4]
    $state = if ($statusRaw -match 'On hold') { 'On hold' } elseif ($statusRaw -match 'Superseded') { 'Superseded' } elseif ($statusRaw -match 'Sandbox') { 'Done - in sandbox' } else { $statusRaw }
    $need = ''; $requested = ''; $approved = ''; $link = ''
    if ($doc) {
        $dl = Read-Lines $doc.FullName; $h = Get-Header $dl
        $need = Get-Section $dl 'Business need'
        $requested = FirstDate (HVal $h @('Requested*', 'Date*', 'Raised*'))
        $st = HVal $h @('Status')
        $approved = if ($st -match 'all good[^0-9]*(\d{4}-\d{2}-\d{2})') { $Matches[1] } else { FirstDate $st }
        $link = RelLink $doc
    }
    $crList = Clean $c[5]
    if (-not $approved -and $state -like 'Done*') {
        # older requirements have no "all good" date in the document: use the date of their last change record
        $nums = @([regex]::Matches($crList, 'CR-(\d{3})') | ForEach-Object { [int]$_.Groups[1].Value })
        if ($crList -match 'CR-(\d{3}) to CR-(\d{3})') { $nums += [int]$Matches[1]..[int]$Matches[2] }
        $dates = foreach ($n in $nums) { $f = Find-Doc '04-Change-Records' ('CR-{0:D3}' -f $n); if ($f) { FirstDate (HVal (Get-Header (Read-Lines $f.FullName)) @('Date')) } }
        $last = $dates | Where-Object { $_ } | Sort-Object | Select-Object -Last 1
        if ($last) { $approved = "$last (date of last change)" }
    }
    if ($state -notlike 'Done*') { $approved = '' }
    $other = Clean $c[6]
    $qa = (([regex]::Matches($other, '(ATR|MTC)-\d{3}') | ForEach-Object Value) | Select-Object -Unique) -join ', '
    $otherNoQa = ($other -replace '(,\s*)?(ATR|MTC)-\d{3}', '').Trim(' ', ',')
    $reqs += [pscustomobject]@{ ID = $id; Title = Clean $c[1]; Need = $need; Keywords = Clean $c[2]; Components = Clean $c[3]
        Requested = $requested; Approved = $approved; State = $state; Notes = $statusRaw; CRs = $crList; Docs = $otherNoQa
        QA = $(if ($qa) { $qa } else { 'Not required at the time' }); Prod = 'Not deployed'; Link = $link }
}
# any DEP document mentioning a REQ marks it as deployed to production
Get-ChildItem (Join-Path $monthDir '06-Deployment') -Filter 'DEP-*.md' -ErrorAction SilentlyContinue | ForEach-Object {
    $t = [IO.File]::ReadAllText($_.FullName); $depId = $_.Name.Substring(0, 7)
    foreach ($r in $reqs) { if ($t -match $r.ID) { $r.Prod = "Deployed ($depId)" } }
}

$crs = foreach ($f in Get-ChildItem (Join-Path $monthDir '04-Change-Records') -Filter 'CR-*.md' | Sort-Object Name) {
    $dl = Read-Lines $f.FullName; $h = Get-Header $dl
    [pscustomobject]@{ ID = $f.Name.Substring(0, 6); Title = Get-Title $dl; Date = HVal $h @('Date'); Req = HVal $h @('Requirement*', 'Related*')
        Components = Get-TableCol $dl 'What changed'; Deploy = HVal $h @('Deploy*'); Status = HVal $h @('Status'); Link = RelLink $f }
}
$cons = foreach ($f in Get-ChildItem (Join-Path $monthDir '05-Conflicts') -Filter 'CON-*.md' | Sort-Object Name) {
    $dl = Read-Lines $f.FullName; $h = Get-Header $dl; $st = HVal $h @('Status')
    $state = if ($st -match '^(Open|Partly)|waiting|open') { 'Open' } elseif ($st -match 'Known|Info') { 'Known limitation' } else { 'Closed' }
    [pscustomobject]@{ ID = $f.Name.Substring(0, 7); Title = Get-Title $dl; State = $state; Status = $st; Found = FirstDate (HVal $h @('Found*', 'Date*', 'Raised*'))
        Related = HVal $h @('Related*', 'Requirement*'); Problem = Get-Section $dl '(Problem|Issue|Conflict|What)'; Link = RelLink $f }
}
$techs = foreach ($f in Get-ChildItem (Join-Path $monthDir '07-Technical') -Filter 'TECH-*.md' | Sort-Object Name) {
    $dl = Read-Lines $f.FullName; $h = Get-Header $dl
    [pscustomobject]@{ ID = $f.Name.Substring(0, 8); Title = Get-Title $dl; Related = HVal $h @('Requirement*', 'Related*'); Link = RelLink $f }
}
$qas = @()
foreach ($f in Get-ChildItem (Join-Path $monthDir '08-QA') -Recurse -Filter '*.md' | Where-Object { $_.Name -match '^(ATR|MTC)-\d{3}' } | Sort-Object Name) {
    $dl = Read-Lines $f.FullName; $h = Get-Header $dl
    $isAtr = $f.Name -like 'ATR-*'
    $cases = ([regex]::Matches(($dl -join "`n"), 'TC-\d{3}-\d{2}') | ForEach-Object Value | Select-Object -Unique).Count
    $qas += [pscustomobject]@{ ID = $f.Name.Substring(0, 7); Type = $(if ($isAtr) { 'Automated test report' } else { 'Manual test cases' }); Title = Get-Title $dl
        Reqs = (([regex]::Matches((HVal $h @('Requirement*')), 'REQ-\d{3}') | ForEach-Object Value) -join ', ')
        Date = $(if ($isAtr) { HVal $h @('Run date') } else { FirstDate (HVal $h @('Automated test report')) }); Cases = $cases
        Result = $(if ($isAtr) { HVal $h @('Result') } else { 'Ready for the QA tester (Actual result / Status to be filled in)' }); Link = RelLink $f }
}

# ---------- write the workbook ----------
function RGB($r, $g, $b) { $r + 256 * $g + 65536 * $b }
$navy = RGB 31 56 100; $green = RGB 226 239 218; $amber = RGB 255 242 204; $grey = RGB 237 237 237; $red = RGB 252 228 214; $zebra = RGB 246 248 252

$xl = New-Object -ComObject Excel.Application
$xl.Visible = $false; $xl.DisplayAlerts = $false; $xl.ScreenUpdating = $false
try {
    $wb = $xl.Workbooks.Add()
    while ($wb.Worksheets.Count -lt 6) { [void]$wb.Worksheets.Add([Type]::Missing, $wb.Worksheets.Item($wb.Worksheets.Count)) }
    $names = 'Overview', 'Requirements', 'Change Records', 'Conflicts & Open Items', 'Technical', 'QA'
    for ($i = 1; $i -le 6; $i++) { $wb.Worksheets.Item($i).Name = $names[$i - 1] }
    foreach ($ws in $wb.Worksheets) { $ws.Cells.Font.Name = 'Arial'; $ws.Cells.Font.Size = 10 }

    # writes a table: headers, rows (array of arrays), column widths; returns last row number
    function Write-Table($ws, [string[]]$headers, $rows, [int[]]$widths, [int]$linkCol = 0) {
        $n = $headers.Count; $m = @($rows).Count
        $data = New-Object 'object[,]' ($m + 1), $n
        for ($c = 0; $c -lt $n; $c++) { $data[0, $c] = $headers[$c] }
        for ($r = 0; $r -lt $m; $r++) { for ($c = 0; $c -lt $n; $c++) { $v = $rows[$r][$c]; $data[($r + 1), $c] = $(if ($null -eq $v -or $v -eq '') { '-' } else { "$v" }) } }
        $rng = $ws.Range($ws.Cells.Item(1, 1), $ws.Cells.Item($m + 1, $n))
        $rng.NumberFormat = '@'; $rng.Value2 = $data
        $rng.WrapText = $true; $rng.VerticalAlignment = -4160   # top
        $rng.Borders.LineStyle = 1; $rng.Borders.Color = RGB 191 191 191
        $hdr = $ws.Range($ws.Cells.Item(1, 1), $ws.Cells.Item(1, $n))
        $hdr.Interior.Color = $navy; $hdr.Font.Color = RGB 255 255 255; $hdr.Font.Bold = $true; $hdr.RowHeight = 30; $hdr.VerticalAlignment = -4108
        for ($c = 0; $c -lt $n; $c++) { $ws.Columns.Item($c + 1).ColumnWidth = $widths[$c] }
        for ($r = 2; $r -le $m + 1; $r++) { if ($r % 2 -eq 1) { $ws.Range($ws.Cells.Item($r, 1), $ws.Cells.Item($r, $n)).Interior.Color = $zebra } }
        $ws.Range($ws.Cells.Item(2, 1), $ws.Cells.Item($m + 1, 1)).Font.Bold = $true
        if ($linkCol -gt 0) {
            for ($r = 2; $r -le $m + 1; $r++) { $cell = $ws.Cells.Item($r, $linkCol); $addr = "$($cell.Value2)"; if ($addr -and $addr -ne '-') { [void]$ws.Hyperlinks.Add($cell, $addr, [Type]::Missing, 'Open the document', 'Open') } }
        }
        [void]$rng.AutoFilter()
        $ws.Activate(); $xl.ActiveWindow.SplitRow = 1; $xl.ActiveWindow.SplitColumn = 0; $xl.ActiveWindow.FreezePanes = $true
        $ws.PageSetup.Orientation = 2; $ws.PageSetup.Zoom = $false; $ws.PageSetup.FitToPagesWide = 1; $ws.PageSetup.FitToPagesTall = $false
        $m + 1
    }
    function Color-Col($ws, [int]$col, [int]$last, [hashtable]$map) {
        for ($r = 2; $r -le $last; $r++) { $cell = $ws.Cells.Item($r, $col); $v = "$($cell.Value2)"
            foreach ($k in $map.Keys) { if ($v -like $k) { $cell.Interior.Color = $map[$k]; $cell.Font.Bold = $true; break } } }
    }

    # Requirements
    $ws = $wb.Worksheets.Item('Requirements')
    $rows = @($reqs | ForEach-Object { , @($_.ID, $_.Title, $_.Need, $_.State, $_.Requested, $_.Approved, $_.Prod, $_.Components, $_.Keywords, $_.CRs, $_.Docs, $_.QA, $_.Notes, $_.Link) })
    $lastReq = Write-Table $ws @('REQ ID', 'Requirement', 'What the client asked for', 'Status', 'Requested on', 'Approved on ("all good")', 'Production', 'Objects / main components', 'Keywords (for search)', 'Change records', 'Technical / conflict documents', 'QA documents', 'Status detail', 'Document') $rows @(9, 30, 60, 16, 12, 14, 14, 34, 28, 20, 24, 16, 30, 12) 14
    Color-Col $ws 4 $lastReq @{ 'Done*' = $green; 'On hold' = $amber; 'Superseded' = $grey }
    Color-Col $ws 7 $lastReq @{ 'Not deployed' = $grey; 'Deployed*' = $green }

    $ws = $wb.Worksheets.Item('Change Records')
    $rows = @($crs | ForEach-Object { , @($_.ID, $_.Title, $_.Date, $_.Req, $_.Components, $_.Deploy, $_.Status, $_.Link) })
    [void](Write-Table $ws @('CR ID', 'Change', 'Date', 'Requirement', 'Components changed', 'Deploy ID', 'Status', 'Document') $rows @(9, 34, 11, 26, 50, 26, 26, 12) 8)

    $ws = $wb.Worksheets.Item('Conflicts & Open Items')
    $rows = @($cons | ForEach-Object { , @($_.ID, $_.Title, $_.State, $_.Found, $_.Problem, $_.Related, $_.Status, $_.Link) })
    $lastCon = Write-Table $ws @('CON ID', 'Conflict / open item', 'State', 'Found on', 'What the problem is', 'Related documents', 'Status detail', 'Document') $rows @(9, 34, 14, 11, 60, 26, 30, 12) 8
    Color-Col $ws 3 $lastCon @{ 'Open' = $red; 'Closed' = $green; 'Known limitation' = $amber }

    $ws = $wb.Worksheets.Item('Technical')
    $rows = @($techs | ForEach-Object { , @($_.ID, $_.Title, $_.Related, $_.Link) })
    [void](Write-Table $ws @('TECH ID', 'Technical document', 'Related requirements / changes', 'Document') $rows @(10, 50, 50, 12) 4)

    $ws = $wb.Worksheets.Item('QA')
    $rows = @($qas | ForEach-Object { , @($_.ID, $_.Type, $_.Title, $_.Reqs, $_.Date, "$($_.Cases)", $_.Result, $_.Link) })
    [void](Write-Table $ws @('QA ID', 'Type', 'Title', 'Requirements covered', 'Run / based on date', 'Test IDs (incl. retests)', 'Result', 'Document') $rows @(9, 20, 40, 22, 14, 10, 50, 12) 8)

    # Overview
    $ws = $wb.Worksheets.Item('Overview')
    $ws.Columns.Item(1).ColumnWidth = 34; $ws.Columns.Item(2).ColumnWidth = 14; $ws.Columns.Item(3).ColumnWidth = 90
    $ws.Cells.Item(1, 1).Value2 = "TVM project - monthly tracker $Month"; $ws.Cells.Item(1, 1).Font.Size = 16; $ws.Cells.Item(1, 1).Font.Bold = $true; $ws.Cells.Item(1, 1).Font.Color = $navy
    $ws.Cells.Item(2, 1).Value2 = "Last updated: $(Get-Date -Format 'yyyy-MM-dd'). Built from the $Month documents after the project lead approved each requirement. Do not edit by hand: update the documents and run scripts/tracker/Build-MonthTracker.ps1."
    $ws.Range('A2:C2').Merge(); $ws.Range('A2:C2').WrapText = $true; $ws.Rows.Item(2).RowHeight = 28; $ws.Cells.Item(2, 1).Font.Italic = $true

    $ws.Cells.Item(4, 1).Value2 = 'At a glance'; $ws.Cells.Item(4, 1).Font.Bold = $true; $ws.Cells.Item(4, 1).Font.Size = 12
    $kpi = @(
        @('Requirements this month', '=COUNTA(Requirements!A:A)-1', 'All requirements worked in the month (Requirements sheet)'),
        @('  Done - in sandbox', '=COUNTIF(Requirements!D:D,"Done*")', 'Built, tested and approved by the project lead'),
        @('  On hold', '=COUNTIF(Requirements!D:D,"On hold")', 'Paused by the client'),
        @('  Superseded', '=COUNTIF(Requirements!D:D,"Superseded")', 'Replaced by a later requirement'),
        @('  Deployed to production', '=COUNTIF(Requirements!G:G,"Deployed*")', 'Only counts requirements with a DEP document'),
        @('Change records', '=COUNTA(''Change Records''!A:A)-1', 'Every change made to the org (Change Records sheet)'),
        @('Conflicts / open items', '=COUNTA(''Conflicts & Open Items''!A:A)-1', 'Problems, clashes and risks found'),
        @('  Still open', '=COUNTIF(''Conflicts & Open Items''!C:C,"Open")', 'Need a decision or action - see the list below'),
        @('Technical documents', '=COUNTA(Technical!A:A)-1', 'Design and component detail'),
        @('QA documents', '=COUNTA(QA!A:A)-1', 'Automated test reports and manual test case documents'))
    $r = 5
    foreach ($k in $kpi) { $ws.Cells.Item($r, 1).Value2 = $k[0]; $ws.Cells.Item($r, 2).Formula = $k[1]; $ws.Cells.Item($r, 3).Value2 = $k[2]; $r++ }
    $box = $ws.Range("A5:C$($r - 1)"); $box.Borders.LineStyle = 1; $box.Borders.Color = RGB 191 191 191
    $ws.Range("B5:B$($r - 1)").Font.Bold = $true; $ws.Range("B5:B$($r - 1)").HorizontalAlignment = -4108; $ws.Range("B5:B$($r - 1)").Interior.Color = $green
    $ws.Cells.Item(12, 2).Interior.Color = $red

    $r++; $ws.Cells.Item($r, 1).Value2 = 'What happened this month'; $ws.Cells.Item($r, 1).Font.Bold = $true; $ws.Cells.Item($r, 1).Font.Size = 12; $r++
    foreach ($s in $summary) { $ws.Cells.Item($r, 1).Value2 = '- ' + $s; $ws.Range("A$($r):C$($r)").Merge(); $ws.Range("A$($r):C$($r)").WrapText = $true; $ws.Rows.Item($r).RowHeight = [Math]::Max(15, 13 * [Math]::Ceiling($s.Length / 130)); $r++ }

    $r++; $ws.Cells.Item($r, 1).Value2 = 'Open items needing a decision'; $ws.Cells.Item($r, 1).Font.Bold = $true; $ws.Cells.Item($r, 1).Font.Size = 12; $r++
    $open = @($cons | Where-Object State -eq 'Open')
    if (-not $open) { $ws.Cells.Item($r, 1).Value2 = 'None'; $r++ }
    foreach ($o in $open) { $ws.Cells.Item($r, 1).Value2 = "$($o.ID)  $($o.Title)"; $ws.Cells.Item($r, 3).Value2 = $o.Problem; $ws.Range("A$($r):C$($r)").WrapText = $true; $ws.Range("A$($r):C$($r)").VerticalAlignment = -4160; $r++ }

    $r++; $ws.Cells.Item($r, 1).Value2 = 'How to use this workbook'; $ws.Cells.Item($r, 1).Font.Bold = $true; $ws.Cells.Item($r, 1).Font.Size = 12; $r++
    $help = @(
        @('Requirements', 'One row per requirement: what was asked, status, dates, components and every related document. Click Open to read the requirement.'),
        @('Change Records', 'Every change made in the sandbox, with date, deploy ID and the components touched.'),
        @('Conflicts & Open Items', 'Problems and decisions. Filter State = Open to see what is still waiting.'),
        @('Technical', 'Design documents for the developers.'),
        @('QA', 'Automated test results and the manual test case documents for the QA tester.'),
        @('Colours', 'Green = done / closed; amber = on hold or known limitation; red = open; grey = superseded or not yet in production.'),
        @('Filters', 'Every sheet has filters on the header row. Use them to find a requirement, object or status.'))
    foreach ($hp in $help) { $ws.Cells.Item($r, 1).Value2 = $hp[0]; $ws.Cells.Item($r, 1).Font.Bold = $true; $ws.Cells.Item($r, 3).Value2 = $hp[1]; $ws.Cells.Item($r, 3).WrapText = $true; $r++ }
    $ws.PageSetup.Orientation = 2; $ws.PageSetup.Zoom = $false; $ws.PageSetup.FitToPagesWide = 1; $ws.PageSetup.FitToPagesTall = $false
    $ws.Activate(); $ws.Range('A1').Select() | Out-Null

    $xl.ScreenUpdating = $true
    if (Test-Path $outFile) { Remove-Item -LiteralPath $outFile }
    $wb.SaveAs($outFile, 51)   # xlOpenXMLWorkbook
    $wb.Close($false)
    "Saved $outFile  (requirements: $($reqs.Count), CRs: $(@($crs).Count), conflicts: $(@($cons).Count), technical: $(@($techs).Count), QA: $($qas.Count))"
}
finally {
    $xl.Quit(); [void][Runtime.InteropServices.Marshal]::ReleaseComObject($xl); [GC]::Collect()
}
