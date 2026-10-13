$ErrorActionPreference = 'Stop'
$sp = 'C:\Users\UTIS LAPTOP 377\AppData\Local\Temp\claude\c--Microsoft-VS-Code-GDRSandbox\d08dd3dc-7817-4434-9679-5763d2940328\scratchpad'
$out = 'C:\Microsoft VS Code\GDRSandbox\deployment\DataMigration_Account_Sandbox\SalesChannel_Sector_Records_To_Update_Sandbox.xlsx'
function RGB($r, $g, $b) { return [int]($r + $g * 256 + $b * 65536) }
$hdr = RGB 31 56 100; $yellow = RGB 255 242 204; $green = RGB 198 239 206; $pink = RGB 244 204 204; $blue = RGB 221 235 247
$data = Import-Csv "$sp\mig_all_objects.csv"
$combos = $data | Group-Object 'Existing Sales Channel', 'Existing Sector', 'New Sales Channel', 'New Sector' | % { $_.Group[0] } | Sort-Object @{ e = { if ($_.Status -eq 'Decision needed') { 1 } else { 0 } } }, 'Existing Sales Channel', 'Existing Sector'
$sumRows = $combos.Count + 3; $top = 4 + $sumRows + 3   # header row of the record list
$xl = New-Object -ComObject Excel.Application; $xl.Visible = $false; $xl.DisplayAlerts = $false; $xl.ScreenUpdating = $false
$wb = $xl.Workbooks.Open("$sp\mig_all_objects.csv"); $ws = $wb.Worksheets.Item(1); $ws.Name = 'Records to Update'
$nData = $ws.UsedRange.Rows.Count - 1; $nCol = $ws.UsedRange.Columns.Count
[void]$ws.Range("A1", "A$($top - 1)").EntireRow.Insert()
$first = $top + 1; $last = $top + $nData
function Put-Cell($r, $c, $v) { if ($null -ne $v -and "$v" -ne '') { $s = [string]$v; if ($s -match '^[+\-@]') { $s = "'" + $s }; $ws.Cells.Item($r, $c).Formula = $s } }
Put-Cell 1 1 'Sales Channel / Sector - records to update in the sandbox (GDRSAND, exported 9 Oct 2026)'; $ws.Cells.Item(1, 1).Font.Size = 14; $ws.Cells.Item(1, 1).Font.Bold = $true
Put-Cell 2 1 'Top: how many records per mapping (live counts from the list below). Below: every record with its existing value and the new value to set. Status "Decision needed" = no mapping yet (not to be loaded).'; $ws.Cells.Item(2, 1).Font.Italic = $true
$sh = 'Existing Sales Channel', 'Existing Sector', 'New Sales Channel', 'New Sector', 'Account', 'Contact', 'Lead', 'Opportunity', 'Total', 'Status'
for ($c = 0; $c -lt $sh.Count; $c++) { Put-Cell 4 ($c + 1) $sh[$c] }
$g = $ws.Range("A4", "J4"); $g.Font.Bold = $true; $g.Font.Color = (RGB 255 255 255); $g.Interior.Color = $hdr; $g.WrapText = $true
$r = 5
foreach ($cb in $combos) {
  Put-Cell $r 1 $cb.'Existing Sales Channel'; Put-Cell $r 2 $(if ($cb.'Existing Sector') { $cb.'Existing Sector' } else { '(blank)' }); Put-Cell $r 3 $cb.'New Sales Channel'; Put-Cell $r 4 $cb.'New Sector'
  $secCrit = if ($cb.'Existing Sector') { "`$B$r" } else { '"="' }
  $k = 5; foreach ($o in 'Account', 'Contact', 'Lead', 'Opportunity') { $ws.Cells.Item($r, $k).Formula = "=COUNTIFS(`$A`$$($first):`$A`$$last,""$o"",`$E`$$($first):`$E`$$last,`$A$r,`$F`$$($first):`$F`$$last,$secCrit,`$H`$$($first):`$H`$$last,`$D$r)"; $k++ }
  $ws.Cells.Item($r, 9).Formula = "=SUM(E$($r):H$($r))"; $st = if ($cb.Status -eq 'Decision needed') { 'Decision needed' } else { 'Ready' }; Put-Cell $r 10 $st
  $ws.Range("C$r", "D$r").Interior.Color = $(if ($st -eq 'Ready') { $green } else { $pink }); $r++ }
Put-Cell $r 1 'TOTAL'; foreach ($c in 5..9) { $L = [char](64 + $c); $ws.Cells.Item($r, $c).Formula = "=SUM($($L)5:$($L)$($r-1))" }; $ws.Range("A$r", "J$r").Font.Bold = $true; $totRow = $r
$r++; Put-Cell $r 1 'Ready to load'; foreach ($c in 5..9) { $L = [char](64 + $c); $ws.Cells.Item($r, $c).Formula = "=SUMIF(`$J`$5:`$J`$$($totRow-1),""Ready"",$($L)5:$($L)$($totRow-1))" }; $ws.Range("A$r", "J$r").Font.Bold = $true
$ws.Range("A4", "J$r").Borders.LineStyle = 1; $ws.Range("A4", "J$r").Borders.Color = (RGB 191 191 191); $ws.Range("E5", "I$r").HorizontalAlignment = -4108
# record list header styling
$h = $ws.Range($ws.Cells.Item($top, 1), $ws.Cells.Item($top, $nCol)); $h.Font.Bold = $true; $h.Font.Color = (RGB 255 255 255); $h.Interior.Color = $hdr; $h.WrapText = $true; $ws.Rows.Item($top).RowHeight = 30
Put-Cell ($top - 1) 1 "RECORD LIST ($nData records) - filter by Object / Status. Columns G-H = new values to set."; $ws.Cells.Item($top - 1, 1).Font.Bold = $true
$ws.Range("G$first", "H$last").Interior.Color = $green; $ws.Range("G$first", "H$last").Font.Bold = $true
for ($i = $first; $i -le $last; $i++) { if ($ws.Cells.Item($i, 14).Text -eq 'Decision needed') { $ws.Range("G$i", "H$i").Interior.Color = $pink; $ws.Cells.Item($i, 14).Interior.Color = $pink } elseif ($ws.Cells.Item($i, 14).Text -like 'Ready (*') { $ws.Cells.Item($i, 14).Interior.Color = $yellow } }
$ws.Range($ws.Cells.Item($top, 1), $ws.Cells.Item($last, $nCol)).Borders.LineStyle = 1; $ws.Range($ws.Cells.Item($top, 1), $ws.Cells.Item($last, $nCol)).Borders.Color = (RGB 191 191 191)
[void]$ws.Range($ws.Cells.Item($top, 1), $ws.Cells.Item($last, $nCol)).AutoFilter()
$w = 13, 20, 38, 30, 18, 15, 17, 15, 12, 11, 12, 16, 20, 30; for ($c = 0; $c -lt $w.Count; $c++) { $ws.Columns.Item($c + 1).ColumnWidth = $w[$c] }
$ws.UsedRange.Font.Name = 'Arial'; $ws.UsedRange.Font.Size = 10; $ws.Cells.Item(1, 1).Font.Size = 14
$ws.Activate(); $xl.ActiveWindow.SplitRow = $top; $xl.ActiveWindow.FreezePanes = $true
$xl.ScreenUpdating = $true; $xl.CalculateFull()
if (Test-Path $out) { Remove-Item $out -Force -Confirm:$false }
$wb.SaveAs($out, 51)
for ($i = 5; $i -le $totRow + 1; $i++) { "{0} / {1} -> {2} / {3} | A={4} C={5} L={6} O={7} T={8} {9}" -f $ws.Cells.Item($i,1).Text, $ws.Cells.Item($i,2).Text, $ws.Cells.Item($i,3).Text, $ws.Cells.Item($i,4).Text, $ws.Cells.Item($i,5).Text, $ws.Cells.Item($i,6).Text, $ws.Cells.Item($i,7).Text, $ws.Cells.Item($i,8).Text, $ws.Cells.Item($i,9).Text, $ws.Cells.Item($i,10).Text }
"list rows $first..$last ; sheets: $($wb.Worksheets.Count)"
$wb.Close($false); $xl.Quit(); [Runtime.InteropServices.Marshal]::ReleaseComObject($xl) | Out-Null
"Saved $out"
