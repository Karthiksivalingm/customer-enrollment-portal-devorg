$ErrorActionPreference = 'Stop'
$sp = 'C:\Users\UTIS LAPTOP 377\AppData\Local\Temp\claude\c--Microsoft-VS-Code-GDRSandbox\d08dd3dc-7817-4434-9679-5763d2940328\scratchpad'
$out = 'C:\Microsoft VS Code\GDRSandbox\deployment\QA_LRP_Sections_by_SalesChannel_Sector.xlsx'
function RGB($r, $g, $b) { return [int]($r + $g * 256 + $b * 65536) }
$hdr = RGB 31 56 100; $band = RGB 182 215 168; $yellow = RGB 255 242 204; $blue = RGB 221 235 247; $green = RGB 198 239 206; $grey = RGB 217 217 217; $pink = RGB 244 204 204

$sec = Import-Csv "$sp\lrp_sections.csv"
$pageName = @{ 'Account_Company_Record_Page' = 'Account - Company Record Page'; 'Lead_Record_Page' = 'Lead Record Page'; 'Account_Store_Location_Record_Page1' = 'Account - Store Location Record Page'; 'Account_Franchise_Record_Page1' = 'Account - Franchise Record Page' }
$condSec = @($sec | ? { $_.Rule -ne 'ALWAYS' })
# evaluate a live rule string "LOGIC | 1) F = V; 2) F <> V" for a Sales Channel / Sector
function Show($rule, $sc, $se) {
  $parts = $rule -split '\|', 2; $logic = $parts[0].Trim(); $crit = @($parts[1] -split ';' | ? { $_.Trim() }); $vals = @()
  foreach ($c in $crit) { $m = [regex]::Match($c.Trim(), '^\d+\)\s*(\S+)\s*(<>|=)\s*(.*)$'); $act = if ($m.Groups[1].Value -eq 'Sales_Channel__c') { $sc } else { $se }; $eq = ($act -eq $m.Groups[3].Value.Trim()); $vals += $(if ($m.Groups[2].Value -eq '=') { $eq } else { -not $eq }) }
  if (-not $logic) { $logic = (1..$vals.Count) -join ' AND ' }
  $expr = [regex]::Replace($logic, '\d+', { param($x) '$' + $vals[[int]$x.Value - 1].ToString().ToLower() }) -replace 'AND', '-and' -replace 'OR', '-or'; return [bool](Invoke-Expression $expr) }
$combos = @(
  @('New', 'Key Account', 'Enterprise', 'Core'), @('New', 'Key Account', 'Strategic', 'Mid-Market'), @('New', 'Key Account', 'Development', 'Mid-Market'), @('New', 'Key Account', 'Discount', 'Off-Price'),
  @('New', 'Specialty', 'Self Service', 'Sellgoodr USA / Sellgoodr CAN'), @('New', 'Specialty', 'Planned', 'Bridge'),
  @('New', 'Partnerships', 'Partnerships', 'Partnerships (no change)'), @('New', 'Global', 'Distributor', 'Global'),
  @('Existing record (old value, not yet migrated)', 'Specialty', 'Sellgoodr USA', ''), @('Existing record (old value, not yet migrated)', 'Specialty', 'Bridge', ''),
  @('Existing record (old value, not yet migrated)', 'Specialty CAN', 'Sellgoodr CAN', ''), @('Existing record', 'Specialty', '', 'blank Sector'),
  @('Existing record (old value, not yet migrated)', 'Key Account', 'Core', ''), @('Existing record (old value, not yet migrated)', 'Global', 'Global', ''))
function Fmt2($s) { if ($s) { $s } else { '(blank)' } }

$xl = New-Object -ComObject Excel.Application; $xl.Visible = $false; $xl.DisplayAlerts = $false; $xl.ScreenUpdating = $false
$wb = $xl.Workbooks.Add()
$names = 'Read Me', 'Section Matrix', 'Section Fields', 'QA Checklist', 'Always Shown Sections'
while ($wb.Worksheets.Count -lt $names.Count) { [void]$wb.Worksheets.Add([Type]::Missing, $wb.Worksheets.Item($wb.Worksheets.Count)) }
for ($i = 1; $i -le $names.Count; $i++) { $wb.Worksheets.Item($i).Name = $names[$i - 1] }
function Put-Cell($ws, $r, $c, $v) { if ($null -ne $v -and "$v" -ne '') { $s = [string]$v; if ($s -match '^[=+\-@]') { $s = "'" + $s }; $ws.Cells.Item($r, $c).Formula = $s } }
function Head($ws, $r, $cols, $w) { for ($c = 0; $c -lt $cols.Count; $c++) { Put-Cell $ws $r ($c + 1) $cols[$c]; $ws.Columns.Item($c + 1).ColumnWidth = $w[$c] }; $g = $ws.Range($ws.Cells.Item($r, 1), $ws.Cells.Item($r, $cols.Count)); $g.Font.Bold = $true; $g.Font.Color = (RGB 255 255 255); $g.Interior.Color = $hdr; $g.WrapText = $true; $g.VerticalAlignment = -4108; $g.HorizontalAlignment = -4108 }
function Title($ws, $t, $s) { Put-Cell $ws 1 1 $t; $ws.Cells.Item(1, 1).Font.Size = 14; $ws.Cells.Item(1, 1).Font.Bold = $true; Put-Cell $ws 2 1 $s; $ws.Cells.Item(2, 1).Font.Italic = $true }
function Fmt($ws, $a, $b) { $g = $ws.Range($a, $b); $g.Font.Name = 'Arial'; $g.Font.Size = 10; $g.WrapText = $true; $g.VerticalAlignment = -4160; $g.Borders.LineStyle = 1; $g.Borders.Color = (RGB 191 191 191) }
function Band($ws, $r, $n, $t) { $m = $ws.Range($ws.Cells.Item($r, 1), $ws.Cells.Item($r, $n)); $m.Merge(); Put-Cell $ws $r 1 $t; $m.Font.Bold = $true; $m.Interior.Color = $band }

# ---- Read Me
$ws = $wb.Worksheets.Item('Read Me')
Title $ws 'Lightning Record Pages - which section shows for each Sales Channel + Sector' 'Sandbox GDRSAND. Built from the LIVE page configuration on 9 Oct 2026.'
$rm = @(
 @('What QA checks', 'On the Account (Company record type) page and the Lead page, the Details tab shows ONE extra section depending on Sales Channel (and Sector for Specialty). QA confirms the right section appears, the others are hidden, and the section shows the listed fields.'),
 @('Pages with Sales Channel / Sector sections', 'Account - Company Record Page (Company accounts) and Lead Record Page. The Store Location and Franchise account pages have NO Sales Channel / Sector sections - they look the same for every value.'),
 @('Rules (simple)', 'Key Account -> "Key Account" section. Partnerships -> "Partnership" section. Global -> "Global" section. Specialty + Self Service -> "Specialty - Sellgoodr". Specialty + Planned -> "Specialty - Bridge". Anything else -> no extra section.'),
 @('Lead buttons', 'Convert button shows only when Status = Qualified AND Sales Channel is NOT Specialty. Approve / Reject buttons show while Status is not Qualified (unchanged).'),
 @('Sheets', 'Section Matrix = which section is shown per value. Section Fields = the fields inside each section. QA Checklist = steps + expected + result columns. Always Shown Sections = sections that appear for every value (for reference).'),
 @('How to test', 'Create or edit a record with the Sales Channel + Sector from the checklist, save, refresh, open the Details tab, check the section and its fields. Record names start with "QA TEST".'),
 @('Note', 'Sales Channel V1 / Sector V1 (in Account Information) are visible only to System Administrators - not part of this test.')
)
$r = 4; foreach ($x in $rm) { Put-Cell $ws $r 1 $x[0]; Put-Cell $ws $r 2 $x[1]; $ws.Cells.Item($r, 1).Font.Bold = $true; $ws.Cells.Item($r, 1).Interior.Color = $blue; $r++ }
$ws.Columns.Item(1).ColumnWidth = 30; $ws.Columns.Item(2).ColumnWidth = 125; Fmt $ws "A4" "B$($r-1)"

# ---- Section Matrix
$ws = $wb.Worksheets.Item('Section Matrix')
Title $ws 'Which section is SHOWN (green) per Sales Channel + Sector' 'Evaluated from the live page rules. Rows marked "Existing record" = data still on old / blank values (old values are inactive and cannot be selected any more).'
$accSec = @($condSec | ? { $_.Page -eq 'Account_Company_Record_Page' }); $leadSec = @($condSec | ? { $_.Page -eq 'Lead_Record_Page' })
$cols = @('Record type', 'Sales Channel', 'Sector', 'Replaces') + ($accSec | % { "ACCOUNT: $($_.Section)" }) + ($leadSec | % { "LEAD: $($_.Section)" }) + @('LEAD: Convert button (Status = Qualified)')
Head $ws 4 $cols (@(18, 13, 13, 18) + (@(11) * ($accSec.Count + $leadSec.Count)) + @(14))
$ws.Range($ws.Cells.Item(4, 5), $ws.Cells.Item(4, $cols.Count)).Orientation = 90; $ws.Rows.Item(4).RowHeight = 130
$r = 5
foreach ($c in $combos) {
  Put-Cell $ws $r 1 $c[0]; Put-Cell $ws $r 2 $c[1]; Put-Cell $ws $r 3 (Fmt2 $c[2]); Put-Cell $ws $r 4 $c[3]; $col = 5
  foreach ($s in $accSec + $leadSec) { $v = Show $s.Rule $c[1] $c[2]; Put-Cell $ws $r $col $(if ($v) { 'SHOWN' } else { '-' }); $ws.Cells.Item($r, $col).Interior.Color = $(if ($v) { $green } else { $grey }); $ws.Cells.Item($r, $col).HorizontalAlignment = -4108; $col++ }
  $conv = ($c[1] -ne 'Specialty'); Put-Cell $ws $r $col $(if ($conv) { 'SHOWN' } else { 'Hidden' }); $ws.Cells.Item($r, $col).Interior.Color = $(if ($conv) { $green } else { $grey }); $ws.Cells.Item($r, $col).HorizontalAlignment = -4108
  if ($c[0] -ne 'New') { $ws.Range("A$r", "D$r").Interior.Color = $yellow }
  $r++ }
Fmt $ws "A4" "$([char](64 + $cols.Count))$($r-1)"
$ws.Activate(); $xl.ActiveWindow.SplitRow = 4; $xl.ActiveWindow.SplitColumn = 4; $xl.ActiveWindow.FreezePanes = $true

# ---- Section Fields
$ws = $wb.Worksheets.Item('Section Fields')
Title $ws 'Fields inside each Sales Channel / Sector section' 'Field labels as shown on the page.'
Head $ws 4 @('Page', 'Section', 'Shown when', '#', 'Field (label on page)') @(30, 22, 44, 5, 42)
$when = @{ 'Specialty - Sellgoodr' = 'Sales Channel = Specialty AND Sector = Self Service'; 'Specialty - Bridge' = 'Sales Channel = Specialty AND Sector = Planned'; 'Key Account' = 'Sales Channel = Key Account (any Sector)'; 'Partnership' = 'Sales Channel = Partnerships'; 'Global' = 'Sales Channel = Global (any Sector)' }
$r = 5
foreach ($pg in 'Account_Company_Record_Page', 'Lead_Record_Page') {
  Band $ws $r 5 $pageName[$pg]; $r++
  foreach ($s in ($condSec | ? { $_.Page -eq $pg })) { $i = 0; $first = $true
    foreach ($fl in ($s.Fields -split '; ')) { $i++; if ($first) { Put-Cell $ws $r 1 $pageName[$pg]; Put-Cell $ws $r 2 $s.Section; Put-Cell $ws $r 3 $when[$s.Section]; $ws.Range("A$r", "E$r").Borders.Item(8).Weight = -4138; $ws.Range("A$r", "C$r").Font.Bold = $true }; Put-Cell $ws $r 4 $i; Put-Cell $ws $r 5 $fl; $first = $false; $r++ } } }
Fmt $ws "A4" "E$($r-1)"; $ws.Range("D5", "D$r").HorizontalAlignment = -4108

# ---- QA Checklist
$ws = $wb.Worksheets.Item('QA Checklist')
Title $ws 'QA Checklist - page sections by Sales Channel + Sector' 'Fill the yellow columns. Expected = from the live page rules.'
$cols = 'TC ID', 'Page', 'Sales Channel', 'Sector', 'Steps', 'Expected section SHOWN', 'Expected sections HIDDEN', 'Fields to check in the shown section', 'Lead Convert button (Status = Qualified)', 'QA Result', 'Status', 'Tested By', 'Date', 'Comments / Defect'
Head $ws 4 $cols @(8, 18, 13, 13, 40, 22, 30, 46, 16, 22, 11, 12, 11, 24)
$r = 5; $n = 0
foreach ($pg in 'Account_Company_Record_Page', 'Lead_Record_Page') {
  $ps = @($condSec | ? { $_.Page -eq $pg }); Band $ws $r $cols.Count $pageName[$pg]; $r++
  foreach ($c in $combos) { $n++
    $shown = @($ps | ? { Show $_.Rule $c[1] $c[2] }); $hidden = @($ps | ? { -not (Show $_.Rule $c[1] $c[2]) })
    $obj = if ($pg -like 'Account*') { 'Company Account' } else { 'Lead' }
    $steps = if ($c[0] -eq 'New') { "Create or edit a $obj with Sales Channel = $($c[1]), Sector = $($c[2]). Save, refresh, open the Details tab." } else { "Open an EXISTING $obj that still has Sales Channel = $($c[1]), Sector = $(Fmt2 $c[2]) (use a list view / report). Open the Details tab." }
    $conv = if ($pg -eq 'Lead_Record_Page') { $(if ($c[1] -ne 'Specialty') { 'Shown' } else { 'Hidden' }) } else { 'n/a' }
    $row = @(('LP-{0:00}' -f $n), $pageName[$pg], $c[1], (Fmt2 $c[2]), $steps, $(if ($shown) { ($shown.Section -join ', ') } else { 'NONE (no extra section)' }), ($hidden.Section -join ', '), $(if ($shown) { $shown[0].Fields } else { '-' }), $conv, '', 'Not Run', '', '', '')
    for ($k = 0; $k -lt $row.Count; $k++) { Put-Cell $ws $r ($k + 1) $row[$k] }
    $ws.Cells.Item($r, 6).Font.Bold = $true; $ws.Cells.Item($r, 6).Interior.Color = $(if ($shown) { $green } else { $grey }); $ws.Range("J$r", "N$r").Interior.Color = $yellow
    if ($c[0] -ne 'New') { $ws.Range("C$r", "D$r").Interior.Color = $pink }
    $r++ } }
$last = $r - 1; Fmt $ws "A4" "N$last"; $ws.Range("A4", "N4").VerticalAlignment = -4108
$dv = $ws.Range("K5", "K$last").Validation; $dv.Delete(); $dv.Add(3, 1, 1, 'Not Run,Pass,Fail,Blocked')
$ws.Activate(); $xl.ActiveWindow.SplitRow = 4; $xl.ActiveWindow.SplitColumn = 4; $xl.ActiveWindow.FreezePanes = $true
Put-Cell $ws 2 10 'Summary:'; $ws.Cells.Item(2, 10).Font.Bold = $true; $k = 11; foreach ($st in 'Pass', 'Fail', 'Blocked', 'Not Run') { $ws.Cells.Item(1, $k).Formula = $st; $ws.Cells.Item(1, $k).Font.Bold = $true; $ws.Cells.Item(2, $k).Formula = "=COUNTIF(`$K`$5:`$K`$$last,""$st"")"; $k++ }

# ---- Always Shown Sections
$ws = $wb.Worksheets.Item('Always Shown Sections')
Title $ws 'Sections shown for EVERY Sales Channel / Sector (reference - no change)' 'Fields marked [only when ...] have their own condition not related to Sales Channel / Sector.'
Head $ws 4 @('Page', 'Section', 'Fields') @(34, 26, 120)
$r = 5; foreach ($s in ($sec | ? { $_.Rule -eq 'ALWAYS' } | Sort-Object Page)) { Put-Cell $ws $r 1 $pageName[$s.Page]; Put-Cell $ws $r 2 $s.Section; Put-Cell $ws $r 3 ($s.Fields -replace '__c', '' -replace 'Active_', 'Active ') ; $r++ }
Fmt $ws "A4" "C$($r-1)"

foreach ($s in $wb.Worksheets) { $s.PageSetup.Orientation = 2; $s.PageSetup.Zoom = $false; $s.PageSetup.FitToPagesWide = 1; $s.PageSetup.FitToPagesTall = $false }
$wb.Worksheets.Item('Read Me').Activate(); $xl.ScreenUpdating = $true; $xl.CalculateFull()
if (Test-Path $out) { Remove-Item $out -Force -Confirm:$false }
$wb.SaveAs($out, 51)
$m = $wb.Worksheets.Item('Section Matrix'); for ($i = 5; $i -le 18; $i++) { $l = @(); for ($c = 2; $c -le 3; $c++) { $l += $m.Cells.Item($i, $c).Text }; $sh = @(); for ($c = 5; $c -le 15; $c++) { if ($m.Cells.Item($i, $c).Text -eq 'SHOWN') { $sh += ($m.Cells.Item(4, $c).Text -replace 'ACCOUNT: ','A:' -replace 'LEAD: ','L:') } }; "{0,-13} {1,-14} -> {2}" -f $l[0], $l[1], ($sh -join ' | ') }
"QA rows: $($wb.Worksheets.Item('QA Checklist').Cells.Item(2, 14).Text)"
$wb.Close($false); $xl.Quit(); [Runtime.InteropServices.Marshal]::ReleaseComObject($xl) | Out-Null
"Saved $out"
