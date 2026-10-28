<#
.SYNOPSIS
  Searches the monthly tracking workbooks (YYYY-MM/YYYY-MM_Tracker.xlsx) and prints only the matching rows.

.DESCRIPTION
  This is the first lookup step for every requirement prompt (Project-Rules section 3). Instead of opening
  folders and documents, it reads the Requirements, Change Records and Conflicts & Open Items sheets of
  every month's tracker and lists the rows where every search word appears (case-insensitive), newest month first.
  Each row shows the ID, title, status, components, related documents and the document path, so you can open
  just the documents you need.
  Needs Microsoft Excel (COM automation). Read-only: the workbooks are never changed.

.EXAMPLE
  & scripts\tracker\Find-Requirement.ps1 -Search "payment schedule"
.EXAMPLE
  & scripts\tracker\Find-Requirement.ps1 -Search REQ-019
.EXAMPLE
  & scripts\tracker\Find-Requirement.ps1 -Search "suite lease" -Month 2026-10 -Sheet Requirements
#>
param(
    [Parameter(Mandatory = $true)][string]$Search,
    [ValidatePattern('^\d{4}-\d{2}$')][string]$Month,
    [ValidateSet('All', 'Requirements', 'Change Records', 'Conflicts & Open Items')][string]$Sheet = 'All',
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
)
$ErrorActionPreference = 'Stop'
$words = @($Search.ToLower().Split(' ', [StringSplitOptions]::RemoveEmptyEntries))
$sheets = if ($Sheet -eq 'All') { @('Requirements', 'Change Records', 'Conflicts & Open Items') } else { @($Sheet) }
# columns printed per sheet (header names as built by Build-MonthTracker.ps1)
$show = @{
    'Requirements'           = @('Requirement', 'Status', 'Objects / main components', 'Change records', 'Technical / conflict documents', 'QA documents', 'Document')
    'Change Records'         = @('Change', 'Date', 'Requirement', 'Deploy ID', 'Document')
    'Conflicts & Open Items' = @('Conflict / open item', 'State', 'Related documents', 'Document')
}

$trackers = Get-ChildItem $ProjectRoot -Directory | Where-Object { $_.Name -match '^\d{4}-\d{2}$' -and (-not $Month -or $_.Name -eq $Month) } |
    Sort-Object Name -Descending | ForEach-Object { Join-Path $_.FullName "$($_.Name)_Tracker.xlsx" } | Where-Object { Test-Path $_ }
if (-not $trackers) { Write-Output 'No tracker found. Fall back to DOCUMENT-INDEX.md.'; return }

$xl = New-Object -ComObject Excel.Application
$xl.Visible = $false; $xl.DisplayAlerts = $false
$hits = 0
try {
    foreach ($file in $trackers) {
        $mon = Split-Path (Split-Path $file -Parent) -Leaf
        $wb = $xl.Workbooks.Open($file, 0, $true)
        try {
            foreach ($name in $sheets) {
                $ws = $null; foreach ($w in $wb.Worksheets) { if ($w.Name -eq $name) { $ws = $w } }
                if (-not $ws) { continue }
                $data = $ws.UsedRange.Value2          # one COM call for the whole sheet
                $rows = $data.GetLength(0); $cols = $data.GetLength(1)
                $hdr = @{}; for ($c = 1; $c -le $cols; $c++) { $hdr["$($data[1, $c])"] = $c }
                for ($r = 2; $r -le $rows; $r++) {
                    $cells = for ($c = 1; $c -le $cols; $c++) { "$($data[$r, $c])" }
                    $text = ($cells -join ' ').ToLower()
                    if (-not $cells[0] -or ($words | Where-Object { -not $text.Contains($_) })) { continue }
                    $hits++
                    Write-Output ("[$mon / $name] " + $cells[0])
                    foreach ($h in $show[$name]) {
                        if ($hdr.ContainsKey($h)) {
                            $v = "$($data[$r, $hdr[$h]])" -replace '\s+', ' '
                            if ($h -eq 'Document') {
                                # the cell shows "Open"; the path is in its hyperlink (relative to the month folder)
                                $links = $ws.Cells.Item($r, $hdr[$h]).Hyperlinks
                                $v = if ($links.Count -gt 0) { "$mon/" + ($links.Item(1).Address -replace '\\', '/') } else { '' }
                            }
                            if ($v.Length -gt 220) { $v = $v.Substring(0, 217) + '...' }
                            if ($v) { Write-Output "    $($h): $v" }
                        }
                    }
                }
            }
        } finally { $wb.Close($false) }
    }
} finally {
    $xl.Quit(); [void][Runtime.InteropServices.Marshal]::ReleaseComObject($xl)
}
if ($hits -eq 0) { Write-Output "No match for '$Search' in the trackers. It is probably a new requirement; confirm in DOCUMENT-INDEX.md (Requirement lookup)." }
else { Write-Output "$hits match(es). Open only the documents listed above." }
