$ErrorActionPreference = 'Stop'
$sp = 'C:\Users\UTIS LAPTOP 377\AppData\Local\Temp\claude\c--Microsoft-VS-Code-GDRSandbox\d08dd3dc-7817-4434-9679-5763d2940328\scratchpad'
$dir = 'C:\Microsoft VS Code\GDRSandbox\deployment\DataMigration_Account_Sandbox'
$out = "$dir\Account_SalesChannel_Sector_Update_Sandbox.xlsx"
function RGB($r, $g, $b) { return [int]($r + $g * 256 + $b * 65536) }
$hdr = RGB 31 56 100; $yellow = RGB 255 242 204; $blue = RGB 221 235 247; $green = RGB 198 239 206; $pink = RGB 244 204 204
$pilotIds = (Import-Csv "$dir\2a_Account_Update_PILOT_DataLoader.csv").Id
$ready = Import-Csv "$sp\mig_ready.csv" | % { $_ | Add-Member -NotePropertyName 'Pilot record' -NotePropertyValue $(if ($pilotIds -contains $_.'Record Id') { 'Yes' } else { '' }) -PassThru }
$ready | Export-Csv "$sp\mig_ready_x.csv" -NoTypeInformation -Encoding utf8

$xl = New-Object -ComObject Excel.Application; $xl.Visible = $false; $xl.DisplayAlerts = $false; $xl.ScreenUpdating = $false
$wb = $xl.Workbooks.Add(); while ($wb.Worksheets.Count -gt 1) { $wb.Worksheets.Item(2).Delete() }
$wb.Worksheets.Item(1).Name = 'Read Me'
function AddCsv($csv, $name) { $tmp = $xl.Workbooks.Open($csv); $tmp.Worksheets.Item(1).Copy([Type]::Missing, $wb.Worksheets.Item($wb.Worksheets.Count)); $tmp.Close($false); $ws = $wb.Worksheets.Item($wb.Worksheets.Count); $ws.Name = $name; return $ws }
function Style($ws, $widths) { $u = $ws.UsedRange; $u.Font.Name = 'Arial'; $u.Font.Size = 10; $u.Borders.LineStyle = 1; $u.Borders.Color = (RGB 191 191 191); $nc = $u.Columns.Count; $h = $ws.Range($ws.Cells.Item(1, 1), $ws.Cells.Item(1, $nc)); $h.Font.Bold = $true; $h.Font.Color = (RGB 255 255 255); $h.Interior.Color = $hdr; $h.WrapText = $true; $ws.Rows.Item(1).RowHeight = 30; for ($c = 0; $c -lt $widths.Count; $c++) { $ws.Columns.Item($c + 1).ColumnWidth = $widths[$c] }; $u.AutoFilter() | Out-Null; $ws.Activate(); $xl.ActiveWindow.SplitRow = 1; $xl.ActiveWindow.FreezePanes = $true }
function Put-Cell($ws, $r, $c, $v) { if ($null -ne $v -and "$v" -ne '') { $s = [string]$v; if ($s -match '^[+\-@]') { $s = "'" + $s }; $ws.Cells.Item($r, $c).Formula = $s } }

$ws = AddCsv "$sp\mig_ready_x.csv" 'Ready to Update'; Style $ws @(20, 42, 15, 17, 15, 20, 17, 13, 18, 16, 11)
$n = $ws.UsedRange.Rows.Count; $ws.Range("I2", "J$n").Interior.Color = $green; $ws.Range("I2", "J$n").Font.Bold = $true
for ($i = 2; $i -le $n; $i++) { if ($ws.Cells.Item($i, 11).Text -eq 'Yes') { $ws.Cells.Item($i, 11).Interior.Color = $yellow } }
$ws = AddCsv "$sp\mig_pending.csv" 'Decision Pending'; Style $ws @(20, 42, 15, 17, 15, 20, 17, 13, 22, 26, 40)
$n2 = $ws.UsedRange.Rows.Count; $ws.Range("I2", "J$n2").Interior.Color = $pink
$ws = AddCsv "$sp\mig_v1_backfill.csv" 'V1 Backfill (do first)'; Style $ws @(20, 42, 15, 18, 14, 22, 16, 20, 16)
$ws.Range("H2", "I4").Interior.Color = $yellow

# Summary sheet (formulas over Ready to Update)
$ws = $wb.Worksheets.Add([Type]::Missing, $wb.Worksheets.Item(1)); $ws.Name = 'Summary'
$cols = 'Old Sales Channel', 'Old Sector', 'New Sales Channel', 'New Sector', 'Company', 'Store Location', 'Franchise', 'Total'
for ($c = 0; $c -lt $cols.Count; $c++) { Put-Cell $ws 3 ($c + 1) $cols[$c] }
$maps = @(@('Specialty','Sellgoodr USA','Specialty','Self Service'), @('Specialty','Sellgoodr CAN','Specialty','Self Service'), @('Specialty','Bridge','Specialty','Planned'), @('Specialty CAN','Sellgoodr CAN','Specialty','Self Service'), @('Key Account','Core','Key Account','Enterprise'), @('Key Account','Mid-Market','Key Account','Strategic'), @('Global','Global','Global','Distributor'))
$r = 4; foreach ($m in $maps) { for ($c = 0; $c -lt 4; $c++) { Put-Cell $ws $r ($c + 1) $m[$c] }; $k = 5; foreach ($rt in 'Company', 'Store Location', 'Franchise') { $ws.Cells.Item($r, $k).Formula = "=COUNTIFS('Ready to Update'!`$D:`$D,`$A$r,'Ready to Update'!`$E:`$E,`$B$r,'Ready to Update'!`$C:`$C,""$rt"")"; $k++ }; $ws.Cells.Item($r, 8).Formula = "=SUM(E$($r):G$($r))"; $r++ }
Put-Cell $ws $r 1 'TOTAL ready to update'; foreach ($c in 5..8) { $L = [char](64 + $c); $ws.Cells.Item($r, $c).Formula = "=SUM($($L)4:$($L)$($r-1))"; $ws.Cells.Item($r, $c).Font.Bold = $true }; $ws.Range("A$r", "H$r").Font.Bold = $true; $tot = $r
$r += 2; Put-Cell $ws $r 1 'Decision pending (not in the update file)'; $ws.Cells.Item($r, 1).Font.Bold = $true; $ws.Cells.Item($r, 8).Formula = "=COUNTA('Decision Pending'!`$A:`$A)-1"; $ws.Cells.Item($r, 8).Font.Bold = $true
$r++; Put-Cell $ws $r 1 'V1 backfill needed first'; $ws.Cells.Item($r, 1).Font.Bold = $true; $ws.Cells.Item($r, 8).Formula = "=COUNTA('V1 Backfill (do first)'!`$A:`$A)-1"; $ws.Cells.Item($r, 8).Font.Bold = $true
$ws.Cells.Item(1, 1).Formula = 'Account Sales Channel / Sector update - sandbox GDRSAND (data exported 9 Oct 2026)'; $ws.Cells.Item(1, 1).Font.Size = 14; $ws.Cells.Item(1, 1).Font.Bold = $true
$g = $ws.Range("A3", "H3"); $g.Font.Bold = $true; $g.Font.Color = (RGB 255 255 255); $g.Interior.Color = $hdr
$ws.Range("A3", "H$tot").Borders.LineStyle = 1; $ws.Range("A1", "H$r").Font.Name = 'Arial'; $ws.Range("C4", "D$($tot-1)").Interior.Color = $green
foreach ($c in 1..8) { $ws.Columns.Item($c).ColumnWidth = @(26, 16, 18, 16, 11, 14, 11, 10)[$c - 1] }

# Read Me
$ws = $wb.Worksheets.Item('Read Me')
$rm = @(
 @('Purpose', 'Account records in the sandbox whose Sales Channel / Sector must change to the new mapping. Old values are already backed up in Sales Channel V1 / Sector V1.'),
 @('Mapping used', 'Specialty + Sellgoodr USA / Sellgoodr CAN -> Specialty + Self Service | Specialty + Bridge -> Specialty + Planned | Specialty CAN + Sellgoodr CAN -> Specialty + Self Service | Specialty CAN + Bridge -> Specialty + Planned | Key Account + Core -> Enterprise | Key Account + Mid-Market -> Strategic (confirmed) | Key Account + Off-Price -> Discount | Global + Global -> Distributor | Partnerships unchanged.'),
 @('Sheets', 'Summary = counts per mapping. Ready to Update = 161 records with old + new values (Pilot record = Yes marks 7 records, one per mapping). Decision Pending = 666 records with no mapping yet (Specialty CAN + blank Sector, and 1 on the inactive channel Mid-Market) - NOT in the update file. V1 Backfill = 3 records whose V1 backup is empty - do these first.'),
 @('Data Loader files (same folder)', '1_V1_Backfill_DataLoader.csv (Id, Sales_Channel_V1__c, Sector_V1__c) -> 2a_Account_Update_PILOT_DataLoader.csv (7 rows) -> 2_Account_Update_DataLoader.csv (161 rows: Id, Sales_Channel__c, Sector__c) -> 3_Account_Rollback_DataLoader.csv (restores the V1 values if needed).'),
 @('Order', '1) Load file 1 (V1 backfill). 2) Load the PILOT file, then check the 7 accounts: Sales Channel / Sector, Cluster, Account Team and page section (see QA sheets). 3) Load file 2 (all 161; the 7 pilot rows are included again - harmless). 4) Verify with a report: Sales Channel V1 / Sector V1 vs Sales Channel / Sector. 5) If needed, load file 3 to roll back.'),
 @('Data Loader settings', 'Operation = Update, object = Account, map the column names 1:1 (Id, Sales_Channel__c, Sector__c). Batch size 200 or less. Keep the success / error files.'),
 @('What happens automatically', 'Cluster and team recalculate (Sales Channel or Sector changed). Clusters stay the same under this mapping (Self Service = 6, Planned = 5, Key Account = 1, Distributor = 7). Open Opportunities (4) get the new Sales Channel and Sector. Contacts follow the Account cluster.')
)
Put-Cell $ws 1 1 'Account data update - instructions'; $ws.Cells.Item(1, 1).Font.Size = 14; $ws.Cells.Item(1, 1).Font.Bold = $true
$r = 3; foreach ($x in $rm) { Put-Cell $ws $r 1 $x[0]; Put-Cell $ws $r 2 $x[1]; $ws.Cells.Item($r, 1).Font.Bold = $true; $ws.Cells.Item($r, 1).Interior.Color = $blue; $r++ }
$ws.Columns.Item(1).ColumnWidth = 28; $ws.Columns.Item(2).ColumnWidth = 130; $g = $ws.Range("A3", "B$($r-1)"); $g.WrapText = $true; $g.Font.Name = 'Arial'; $g.Font.Size = 10; $g.Borders.LineStyle = 1; $g.VerticalAlignment = -4160

$wb.Worksheets.Item('Read Me').Activate(); $xl.ScreenUpdating = $true; $xl.CalculateFull()
if (Test-Path $out) { Remove-Item $out -Force -Confirm:$false }
$wb.SaveAs($out, 51)
$s = $wb.Worksheets.Item('Summary'); for ($i = 4; $i -le $tot; $i++) { "{0} / {1} -> {2} / {3}: C={4} S={5} F={6} T={7}" -f $s.Cells.Item($i,1).Text, $s.Cells.Item($i,2).Text, $s.Cells.Item($i,3).Text, $s.Cells.Item($i,4).Text, $s.Cells.Item($i,5).Text, $s.Cells.Item($i,6).Text, $s.Cells.Item($i,7).Text, $s.Cells.Item($i,8).Text }
"pending: $($s.Cells.Item($tot+2,8).Text)  backfill: $($s.Cells.Item($tot+3,8).Text)"
"sheets: " + (($wb.Worksheets | % { $_.Name }) -join ', ')
$rs = $wb.Worksheets.Item('Ready to Update'); "Ready sheet sample Id: $($rs.Cells.Item(2,1).Text) (length $($rs.Cells.Item(2,1).Text.Length))"
$wb.Close($false); $xl.Quit(); [Runtime.InteropServices.Marshal]::ReleaseComObject($xl) | Out-Null
"Saved $out"
