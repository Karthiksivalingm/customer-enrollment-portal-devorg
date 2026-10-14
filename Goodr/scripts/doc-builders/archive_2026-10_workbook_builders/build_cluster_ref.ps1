$ErrorActionPreference = 'Stop'
$sp = 'C:\Users\UTIS LAPTOP 377\AppData\Local\Temp\claude\c--Microsoft-VS-Code-GDRSandbox\d08dd3dc-7817-4434-9679-5763d2940328\scratchpad'
$out = 'C:\Microsoft VS Code\GDRSandbox\deployment\QA_Cluster_Team_Assignment_Reference.xlsx'
function RGB($r, $g, $b) { return [int]($r + $g * 256 + $b * 65536) }
$hdr = RGB 31 56 100; $band = RGB 182 215 168; $yellow = RGB 255 242 204; $blue = RGB 221 235 247; $green = RGB 198 239 206; $grey = RGB 231 230 230; $pink = RGB 244 204 204

# ---------- data ----------
$detail = Import-Csv "$sp\team_detail.csv"
$nameOf = @{}; $detail | % { $nameOf[$_.Username] = $_.Name }
$verified = Get-Content "$sp\team_roles_verified.txt" | ? { $_ }
$ver = @{}; foreach ($l in $verified) { $p = $l -split '~'; $ver["$($p[0])|$($p[1])|$($p[2])"] = @{ Cluster = $p[3]; Team = @($p[4] -split ';' | ? { $_ }) } }
$combos = @(
  @('Key Account', 'Enterprise', 'Core'), @('Key Account', 'Strategic', 'Mid-Market'), @('Key Account', 'Development', 'Mid-Market'), @('Key Account', 'Discount', 'Off-Price'),
  @('Specialty', 'Planned', 'Bridge (Specialty and Specialty CAN)'), @('Specialty', 'Self Service', 'Sellgoodr USA, Sellgoodr CAN (Specialty and Specialty CAN)'),
  @('Partnerships', 'Partnerships', 'Partnerships (no change)'), @('Global', 'Distributor', 'Global'))
$objs = 'Account', 'Contact', 'Lead', 'Opportunity'
$relList = @{ Account = 'Account Team'; Contact = 'Contact Team'; Lead = 'Lead Team'; Opportunity = 'Opportunity Team' }
function TeamText($obj, $sc, $se) { $v = $ver["$obj|$sc|$se"]; ($v.Team | Sort-Object | % { $r, $u = $_ -split '=', 2; "$r - $($nameOf[$u])" }) -join "`n" }

# ---------- Excel ----------
$xl = New-Object -ComObject Excel.Application; $xl.Visible = $false; $xl.DisplayAlerts = $false; $xl.ScreenUpdating = $false
$wb = $xl.Workbooks.Add()
$names = 'Read Me', 'Cluster Mapping', 'Team by Cluster', 'QA Checklist', 'Notes'
while ($wb.Worksheets.Count -lt $names.Count) { [void]$wb.Worksheets.Add([Type]::Missing, $wb.Worksheets.Item($wb.Worksheets.Count)) }
for ($i = 1; $i -le $names.Count; $i++) { $wb.Worksheets.Item($i).Name = $names[$i - 1] }
function Put-Cell($ws, $r, $c, $v) { if ($null -ne $v -and "$v" -ne '') { $s = [string]$v; if ($s -match '^[=+\-@]') { $s = "'" + $s }; $ws.Cells.Item($r, $c).Formula = $s } }
function Head($ws, $r, $cols, $w) { for ($c = 0; $c -lt $cols.Count; $c++) { Put-Cell $ws $r ($c + 1) $cols[$c]; $ws.Columns.Item($c + 1).ColumnWidth = $w[$c] }; $g = $ws.Range($ws.Cells.Item($r, 1), $ws.Cells.Item($r, $cols.Count)); $g.Font.Bold = $true; $g.Font.Color = (RGB 255 255 255); $g.Interior.Color = $hdr; $g.WrapText = $true; $g.VerticalAlignment = -4108; $g.HorizontalAlignment = -4108 }
function Title($ws, $t, $s) { Put-Cell $ws 1 1 $t; $ws.Cells.Item(1, 1).Font.Size = 14; $ws.Cells.Item(1, 1).Font.Bold = $true; Put-Cell $ws 2 1 $s; $ws.Cells.Item(2, 1).Font.Italic = $true }
function Fmt($ws, $a, $b) { $g = $ws.Range($a, $b); $g.Font.Name = 'Arial'; $g.Font.Size = 10; $g.WrapText = $true; $g.VerticalAlignment = -4160; $g.Borders.LineStyle = 1; $g.Borders.Color = (RGB 191 191 191) }
function Band($ws, $r, $n, $t) { $m = $ws.Range($ws.Cells.Item($r, 1), $ws.Cells.Item($r, $n)); $m.Merge(); Put-Cell $ws $r 1 $t; $m.Font.Bold = $true; $m.Interior.Color = $band }

# ---- Read Me
$ws = $wb.Worksheets.Item('Read Me')
Title $ws 'Cluster & Team Assignment - QA Reference (new Sales Channel / Sector mapping)' 'Sandbox GDRSAND. Every expected value in this workbook was verified internally on 9 Oct 2026 (live test, rolled back - no data left).'
$rm = @(
 @('Purpose', 'Shows, for every NEW Sales Channel + Sector value, which Cluster and which Team members must be assigned on Account, Contact, Lead and Opportunity. QA re-tests the same in the UI.'),
 @('How the cluster is set', 'Automatically from Sales Channel + Sector (custom metadata rules) when a record is CREATED or when its Sales Channel OR Sector is CHANGED. Contact shows the cluster of its Account. A new Opportunity copies Sales Channel, Sector and Cluster from its Account.'),
 @('How the team is set', 'Automatically from the cluster (Account Cluster Team setup) whenever the cluster changes. Related lists: Account Team (Account), Contact Team (Contact), Lead Team (Lead), Opportunity Team (Opportunity).'),
 @('Important', 'Account Team and Opportunity Team list each user ONCE (a user with two roles shows one role). Contact Team and Lead Team list one row PER ROLE (the same user can appear twice).'),
 @('Sheets', 'Cluster Mapping = one-line summary per value. Team by Cluster = exact team members (role, name, access). QA Checklist = 32 create checks + 4 update checks with Expected / Verified internally / QA result columns. Notes = known points (not defects).'),
 @('Test data tips', 'Name test records "QA TEST ...". Company Account needs Tax ID (9 digits, unique) and billing address. Lead needs Tax ID, Terms of Service = I agree, Has Physical Store, Resale Certificate Status. Refresh the page after save before checking Cluster / team.')
)
$r = 4; foreach ($x in $rm) { Put-Cell $ws $r 1 $x[0]; Put-Cell $ws $r 2 $x[1]; $ws.Cells.Item($r, 1).Font.Bold = $true; $ws.Cells.Item($r, 1).Interior.Color = $blue; $r++ }
$ws.Columns.Item(1).ColumnWidth = 24; $ws.Columns.Item(2).ColumnWidth = 130; Fmt $ws "A4" "B$($r-1)"

# ---- Cluster Mapping
$ws = $wb.Worksheets.Item('Cluster Mapping')
Title $ws 'Cluster by Sales Channel + Sector (new values)' 'Same cluster on Account, Contact (via Account), Lead and Opportunity. Verified in sandbox 9 Oct 2026.'
Head $ws 4 @('Sales Channel', 'Sector (new)', 'Replaces old value', 'Account', 'Contact', 'Lead', 'Opportunity', 'Team members (Account / Contact / Lead / Opportunity)', 'Verified internally') @(15, 15, 34, 11, 11, 11, 12, 30, 16)
$r = 5
foreach ($c in $combos) {
  Put-Cell $ws $r 1 $c[0]; Put-Cell $ws $r 2 $c[1]; Put-Cell $ws $r 3 $c[2]
  $cnt = @(); $col = 4; foreach ($o in $objs) { $v = $ver["$o|$($c[0])|$($c[1])"]; Put-Cell $ws $r $col $v.Cluster; $cnt += $v.Team.Count; $col++ }
  Put-Cell $ws $r 8 ($cnt -join ' / '); Put-Cell $ws $r 9 'Pass'; $ws.Cells.Item($r, 9).Interior.Color = $green
  $ws.Range("D$r", "G$r").HorizontalAlignment = -4108; $ws.Range("D$r", "G$r").Font.Bold = $true; $r++ }
Fmt $ws "A4" "I$($r-1)"; $ws.Range("H5", "H$r").HorizontalAlignment = -4108

# ---- Team by Cluster
$ws = $wb.Worksheets.Item('Team by Cluster')
Title $ws 'Team members assigned per cluster and object (sandbox users)' 'Source: Account Cluster Team setup, confirmed by the live test. Rows marked "Not assigned" are configured but skipped because the user is inactive / not found.'
Head $ws 4 @('Cluster', 'Used for (Sales Channel + Sector)', 'Object (related list)', 'Team Role', 'User Name', 'Username', 'Access Level', 'Assigned in test?') @(10, 34, 22, 24, 20, 34, 12, 16)
$usedFor = @{ 'Cluster 1' = 'Key Account + Enterprise / Strategic / Development / Discount'; 'Cluster 5' = 'Specialty + Planned'; 'Cluster 6' = 'Specialty + Self Service'; 'Cluster 7' = 'Global + Distributor'; 'Cluster 8' = 'Partnerships + Partnerships' }
$repCombo = @{ 'Cluster 1' = @('Key Account', 'Enterprise'); 'Cluster 5' = @('Specialty', 'Planned'); 'Cluster 6' = @('Specialty', 'Self Service'); 'Cluster 7' = @('Global', 'Distributor'); 'Cluster 8' = @('Partnerships', 'Partnerships') }
$r = 5
foreach ($cl in 'Cluster 1', 'Cluster 5', 'Cluster 6', 'Cluster 7', 'Cluster 8') {
  Band $ws $r 8 "$cl - $($usedFor[$cl])"; $r++
  foreach ($o in $objs) {
    $rc = $repCombo[$cl]; $assigned = @($ver["$o|$($rc[0])|$($rc[1])"].Team)
    foreach ($d in ($detail | ? { $_.Cluster -eq $cl -and $_.Object -eq $o } | Sort-Object Role)) {
      Put-Cell $ws $r 1 $cl; Put-Cell $ws $r 2 $usedFor[$cl]; Put-Cell $ws $r 3 "$o ($($relList[$o]))"; Put-Cell $ws $r 4 $d.Role; Put-Cell $ws $r 5 $d.Name; Put-Cell $ws $r 6 $d.Username; Put-Cell $ws $r 7 $d.Access
      $isIn = ($assigned -contains "$($d.Role)=$($d.Username)") -or (($o -in 'Account', 'Opportunity') -and (@($assigned | % { ($_ -split '=', 2)[1] }) -contains $d.Username))
      if ($d.Active -ne 'True') { Put-Cell $ws $r 8 'Not assigned (inactive)'; $ws.Range("A$r", "H$r").Interior.Color = $pink }
      elseif ($isIn) { Put-Cell $ws $r 8 'Yes'; $ws.Cells.Item($r, 8).Interior.Color = $green }
      else { Put-Cell $ws $r 8 'Shown once (2 roles)'; $ws.Cells.Item($r, 8).Interior.Color = $yellow }
      $r++ } } }
Fmt $ws "A4" "H$($r-1)"; $ws.Range("A4", "H$($r-1)").AutoFilter() | Out-Null
$ws.Activate(); $xl.ActiveWindow.SplitRow = 4; $xl.ActiveWindow.FreezePanes = $true

# ---- QA Checklist
$ws = $wb.Worksheets.Item('QA Checklist')
Title $ws 'QA Checklist - cluster and team per Sales Channel + Sector and object' 'Fill the yellow columns. Expected values = what the sandbox produced in the internal test on 9 Oct 2026.'
$cols = 'TC ID', 'Sales Channel', 'Sector', 'Object', 'Steps', 'Expected Cluster', 'Expected Team (Role - Name)', 'Verified internally', 'QA Actual Cluster', 'QA Team matches?', 'Status', 'Tested By', 'Test Date', 'Comments / Defect'
Head $ws 4 $cols @(9, 13, 13, 12, 46, 11, 40, 12, 12, 12, 11, 13, 11, 26)
$steps = @{
 Account = 'Create a Company Account: Sales Channel = {0}, Sector = {1} (Tax ID 9 digits, billing address). Save, refresh. Check the Cluster field and the Account Team related list.'
 Contact = 'On the Account created for the same Sales Channel / Sector, create a Contact. Save, refresh. Check Cluster (comes from the Account) and the Contact Team related list.'
 Lead = 'Create a Lead: Sales Channel = {0}, Sector = {1} (mandatory lead fields). Save, refresh. Check the Cluster field and the Lead Team related list.'
 Opportunity = 'From the same Account, create an Opportunity (Stage = Summary). Save, refresh. Check Sales Channel = {0}, Sector = {1} (copied), Cluster, and the Opportunity Team related list.' }
$r = 5; $n = 0
foreach ($c in $combos) {
  Band $ws $r $cols.Count "$($c[0]) + $($c[1])  (replaces: $($c[2]))"; $r++
  foreach ($o in $objs) { $n++; $v = $ver["$o|$($c[0])|$($c[1])"]
    $row = @(('CT-{0:00}' -f $n), $c[0], $c[1], $o, ($steps[$o] -f $c[0], $c[1]), $v.Cluster, (TeamText $o $c[0] $c[1]), 'Pass', '', '', 'Not Run', '', '', '')
    for ($k = 0; $k -lt $row.Count; $k++) { Put-Cell $ws $r ($k + 1) $row[$k] }; $ws.Cells.Item($r, 8).Interior.Color = $green; $ws.Cells.Item($r, 6).Font.Bold = $true; $r++ } }
Band $ws $r $cols.Count 'UPDATE scenarios (cluster and team must follow a change of Sector or Sales Channel)'; $r++
$upd = @(
 @('CU-01', 'Specialty', 'Planned -> Self Service', 'Account', 'Open a Specialty + Planned account (Cluster 5). Change ONLY Sector to Self Service. Save, refresh.', 'Cluster 6', 'Account Team replaced by the Cluster 6 Account team; its Contacts show Cluster 6 and get the Cluster 6 Contact team.'),
 @('CU-02', 'Specialty', 'Planned -> Self Service', 'Lead', 'Open a Specialty + Planned lead (Cluster 5). Change ONLY Sector to Self Service. Save, refresh.', 'Cluster 6', 'Lead Team replaced by the Cluster 6 Lead team.'),
 @('CU-03', 'Specialty', 'Planned -> Self Service', 'Opportunity', 'Open a Specialty + Planned opportunity. Change ONLY Sector to Self Service. Save, refresh.', 'Cluster 6', 'Opportunity Team replaced by the Cluster 6 Opportunity team.'),
 @('CU-04', 'Key Account -> Specialty', 'Enterprise -> Self Service', 'Account + open Opportunity', 'Account Key Account + Enterprise WITH an open Opportunity. Edit Account: Sales Channel = Specialty, Sector = Self Service. Save, refresh account and the opportunity.', 'Cluster 6', 'Save succeeds. Account Team = Cluster 6. Open Opportunity shows Specialty / Self Service / Cluster 6 with the Cluster 6 Opportunity team.')
)
foreach ($u in $upd) { $row = @($u[0], $u[1], $u[2], $u[3], $u[4], $u[5], $u[6], 'Pass', '', '', 'Not Run', '', '', ''); for ($k = 0; $k -lt $row.Count; $k++) { Put-Cell $ws $r ($k + 1) $row[$k] }; $ws.Cells.Item($r, 8).Interior.Color = $green; $ws.Cells.Item($r, 6).Font.Bold = $true; $r++ }
$last = $r - 1; Fmt $ws "A4" "N$last"; $ws.Range("A4", "N4").VerticalAlignment = -4108
for ($i = 5; $i -le $last; $i++) { if ($ws.Cells.Item($i, 2).Text -ne '' -and $ws.Cells.Item($i, 4).Text -ne '') { $ws.Range("I$i", "N$i").Interior.Color = $yellow } }
$dv = $ws.Range("K5", "K$last").Validation; $dv.Delete(); $dv.Add(3, 1, 1, 'Not Run,Pass,Fail,Blocked')
$dv2 = $ws.Range("J5", "J$last").Validation; $dv2.Delete(); $dv2.Add(3, 1, 1, 'Yes,No')
$ws.Activate(); $xl.ActiveWindow.SplitRow = 4; $xl.ActiveWindow.SplitColumn = 4; $xl.ActiveWindow.FreezePanes = $true
Put-Cell $ws 2 10 'Summary:'; $ws.Cells.Item(2, 10).Font.Bold = $true; $k = 11; foreach ($st in 'Pass', 'Fail', 'Blocked', 'Not Run') { $ws.Cells.Item(1, $k).Formula = $st; $ws.Cells.Item(1, $k).Font.Bold = $true; $ws.Cells.Item(2, $k).Formula = "=COUNTIF(`$K`$5:`$K`$$last,""$st"")"; $k++ }

# ---- Notes
$ws = $wb.Worksheets.Item('Notes')
Title $ws 'Notes for QA - expected behaviour, not defects' ''
Head $ws 4 @('#', 'Point', 'Detail') @(5, 40, 110)
$nt = @(
 @('1', 'Global (Cluster 7) has 4 team members, not 5', 'The Sales Director in the setup is planda@goodr.com (Pepe Landa), inactive in Production and not present in the sandbox. Inactive / missing users are skipped by design. Business to confirm the replacement.'),
 @('2', 'Key Account always gets Cluster 1', 'The rules assign Cluster 1 to every Key Account record (any Sector). Clusters 2-4 exist in the team setup and are set manually; a manual cluster is kept until Sales Channel or Sector changes.'),
 @('3', 'Account / Opportunity team show a user once', 'Salesforce allows one Account Team / Opportunity Team row per user, so a user holding two roles (e.g. Tam Win: Field Marketing Support + Field Support) appears once. Contact Team and Lead Team show one row per role.'),
 @('4', 'Contact cluster comes from the Account', 'Contact.Cluster is a formula from the Account; it changes when the Account cluster changes.'),
 @('5', 'Cluster now follows Sector changes', 'Fixed 9 Oct 2026 (deploy 0Afdx00000GEpsfCAD): changing only the Sector re-assigns the cluster and team. Two older test accounts (R12 Test Company Sandbox, Test Team) still show Cluster 5 with Self Service - they correct on their next Sector / Sales Channel save.'),
 @('6', 'Old Sector values are inactive', 'Sellgoodr USA, Sellgoodr CAN, Bridge, Core, Mid-Market, Off-Price, Global and Sales Channel Specialty CAN can no longer be selected; existing records still hold them until the data migration.'),
 @('7', 'Mid-Market mapping', 'Old Mid-Market maps to Strategic OR Development (client to confirm per account). Both give Cluster 1.')
)
$r = 5; foreach ($x in $nt) { for ($c = 0; $c -lt 3; $c++) { Put-Cell $ws $r ($c + 1) $x[$c] }; $r++ }; Fmt $ws "A4" "C$($r-1)"

foreach ($s in $wb.Worksheets) { $s.PageSetup.Orientation = 2; $s.PageSetup.Zoom = $false; $s.PageSetup.FitToPagesWide = 1; $s.PageSetup.FitToPagesTall = $false }
$wb.Worksheets.Item('Read Me').Activate(); $xl.ScreenUpdating = $true; $xl.CalculateFull()
if (Test-Path $out) { Remove-Item $out -Force -Confirm:$false }
$wb.SaveAs($out, 51)
$q = $wb.Worksheets.Item('QA Checklist'); "QA rows: Not Run counter = $($q.Cells.Item(2, 14).Text)"
$m = $wb.Worksheets.Item('Cluster Mapping'); for ($i = 5; $i -le 12; $i++) { "{0} + {1}: {2} | {3} | {4} | {5} | team {6}" -f $m.Cells.Item($i,1).Text, $m.Cells.Item($i,2).Text, $m.Cells.Item($i,4).Text, $m.Cells.Item($i,5).Text, $m.Cells.Item($i,6).Text, $m.Cells.Item($i,7).Text, $m.Cells.Item($i,8).Text }
$wb.Close($false); $xl.Quit(); [Runtime.InteropServices.Marshal]::ReleaseComObject($xl) | Out-Null
"Saved $out"
