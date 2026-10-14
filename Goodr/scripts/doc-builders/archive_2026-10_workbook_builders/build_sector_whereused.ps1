$ErrorActionPreference = 'Stop'
$out = 'C:\Microsoft VS Code\GDRSandbox\deployment\Sector_Where_Used_Analysis.xlsx'
function RGB($r, $g, $b) { return [int]($r + $g * 256 + $b * 65536) }
$band = RGB 182 215 168; $yellow = RGB 255 242 204; $lgreen = RGB 198 239 206; $blue = RGB 221 235 247; $grey = RGB 231 230 230; $pink = RGB 244 204 204

$xl = New-Object -ComObject Excel.Application
$xl.Visible = $false; $xl.DisplayAlerts = $false; $xl.ScreenUpdating = $false
$wb = $xl.Workbooks.Add()
$names = 'Sector - Where Used', 'Data to Migrate', 'Not in Where-Used List'
while ($wb.Worksheets.Count -lt $names.Count) { [void]$wb.Worksheets.Add([Type]::Missing, $wb.Worksheets.Item($wb.Worksheets.Count)) }
for ($i = 1; $i -le $names.Count; $i++) { $wb.Worksheets.Item($i).Name = $names[$i - 1] }

function Set-Cell($ws, $r, $c, $v) { if ($null -ne $v -and "$v" -ne '') { $s = [string]$v; if ($s -match '^[=+\-@]') { $s = "'" + $s }; $ws.Cells.Item($r, $c).Formula = $s } }
function Header($ws, $r, $cols, $widths) {
    for ($c = 0; $c -lt $cols.Count; $c++) { Set-Cell $ws $r ($c + 1) $cols[$c]; $ws.Columns.Item($c + 1).ColumnWidth = $widths[$c] }
    $rg = $ws.Range($ws.Cells.Item($r, 1), $ws.Cells.Item($r, $cols.Count)); $rg.Font.Bold = $true; $rg.Interior.Color = (RGB 31 56 100); $rg.Font.Color = (RGB 255 255 255); $rg.HorizontalAlignment = -4108; $rg.WrapText = $true
}
function Band($ws, $r, $ncol, $text) { $m = $ws.Range($ws.Cells.Item($r, 1), $ws.Cells.Item($r, $ncol)); $m.Merge(); Set-Cell $ws $r 1 $text; $m.Font.Bold = $true; $m.Interior.Color = $band; $m.HorizontalAlignment = -4108 }
function Row($ws, $r, $vals) { for ($c = 0; $c -lt $vals.Count; $c++) { Set-Cell $ws $r ($c + 1) $vals[$c] } }

# ============================================================ Sheet 1: Where Used
$ws = $wb.Worksheets.Item('Sector - Where Used')
$ws.Cells.Item(1, 1).Formula = 'Sector__c - "Where is this used?" review (GDRSAND sandbox)'; $ws.Cells.Item(1, 1).Font.Size = 14; $ws.Cells.Item(1, 1).Font.Bold = $true
$ws.Cells.Item(2, 1).Formula = 'Every component verified against the current sandbox metadata on 7 Oct 2026. Only components that use Sector VALUES need a change - both were already updated (2.1, 2.2). Components that copy, display or expose the field work automatically with any value.'
$ws.Range("A2:H2").Merge(); $ws.Cells.Item(2, 1).WrapText = $true; $ws.Rows.Item(2).RowHeight = 30; $ws.Cells.Item(2, 1).Font.Italic = $true
$cols = 'Object', 'Reference Type', 'Reference Label', 'Change Needed?', 'Comment / Reason', 'Evidence (verified)', 'Status', 'Sandbox Deploy ID'
Header $ws 4 $cols @(13, 22, 42, 18, 70, 48, 20, 22)

$NO = 'No'; $DONE = 'Already done'; $NOTUSED = 'No - not used'
$cmdtTeam = @('Custom Metadata', 'Account_Cluster_Team__mdt', $NOTUSED, 'Does not use Sector at all. Fields: Access Level, Cluster Value, Object API Name, Sales Channel, Team Role, User Identifier. Team members are assigned by Cluster (ClusterTeamEngine lines 27-35), not by Sector.', 'No Sector field on the type; 0 of 218 records mention Sector', 'No change', '')
$lcs = { param($line) @('ApexClass', 'LeadConversionService', $NO, "Copies Sector__c from the Lead during conversion ($line). No Sector value is hard-coded, so old and new values are copied as they are.", 'Sector lines 184 (SOQL), 248, 633, 671; 0 value literals', 'No change', '') }
$data = [ordered]@{
  'Lead' = @(
    (& $lcs 'Lead -> Contact line 248, Company Account line 633, Store Account line 671'),
    @('FlexipageFieldInstance', 'Specialty_Bridge', $NO, 'Lead page that only displays the Sector field - no filter on Sector values. Page is NOT activated for any app / record type / profile, so users never see it. Optional cleanup later.', '1 Sector field, 0 Sector filters, not activated', 'No change', ''),
    @('FlexipageFieldInstance', 'Partnership', $NO, 'Same as above - display only, not activated.', '1 Sector field, 0 Sector filters, not activated', 'No change', ''),
    @('FlexipageFieldInstance', 'Key Account', $NO, 'Same as above - display only, not activated.', '1 Sector field, 0 Sector filters, not activated', 'No change', ''),
    @('FlexipageFieldInstance', 'Specialty_Sellgoodr', $NO, 'Same as above - display only, not activated.', '1 Sector field, 0 Sector filters, not activated', 'No change', ''),
    @('FlexipageFieldInstance', 'Global', $NO, 'Same as above - display only, not activated.', '1 Sector field, 0 Sector filters, not activated', 'No change', ''),
    @('FlexipageFieldInstance', 'Lead Record Page', $DONE, 'The field instance only displays Sector. The page also has 2 section filters that use Sector values: "Specialty - Bridge" (Sector = Bridge) and "Specialty - Sellgoodr" (Sector <> Bridge). Planned was ADDED next to Bridge so new-value records show the right section; old values unchanged.', 'Filters now: Bridge OR Planned / not Bridge AND not Planned', 'Deployed to Sandbox (2.2)', '0Afdx00000GAp02CAD'),
    @('Layout', 'Lead Layout', $NO, 'Places the field on the page layout. Layouts do not filter by value; the picklist shows the new values automatically.', '0 Sector value literals', 'No change', ''),
    @('ReportType', 'Leads_with_Daily_Engagements', $NO, 'Report type only makes Sector available as a column; it holds no values.', '0 Sector value literals', 'No change', ''),
    @('ReportType', 'Leads_with_Monthly_Engagements', $NO, 'Field availability only.', '0 value literals', 'No change', ''),
    @('ReportType', 'Leads_and_Sales_Cadence_Trackers', $NO, 'Field availability only.', '0 value literals', 'No change', ''),
    @('ReportType', 'Leads_With_or_Without_Sales_Cadence_Trackers', $NO, 'Field availability only.', '0 value literals', 'No change', ''),
    @('ReportType', 'Lead_Duplicates', $NO, 'Field availability only.', '0 value literals', 'No change', ''),
    @('Custom Metadata', 'Sales_Channel_Cluster__mdt', $DONE, 'Lead cluster rules compare Sector values in Rule_Condition__c. Added Specialty_Self_Service_Lead (Self Service -> Cluster 6) and Specialty_Planned_Lead (Planned -> Cluster 5). Old Sellgoodr USA / Bridge rules kept because Lead data still has old values.', '24 rules use Sector__c (incl. 8 new)', 'Deployed to Sandbox (2.1)', '0Afdx00000GAl4TCAT'),
    $cmdtTeam
  )
  'Account' = @(
    (& $lcs 'sets the Company Account (line 633) and Store Account (line 671) Sector from the Lead'),
    @('FlexipageFieldInstance', 'Account Record Page - Three Column', $NO, 'Display only, no Sector filter. Page is NOT activated.', '1 Sector field, 0 Sector filters, not activated', 'No change', ''),
    @('FlexipageFieldInstance', 'Account Franchise Record Page', $NO, 'Display only, no Sector filter. Active for the Franchise record type.', '1 Sector field, 0 Sector filters', 'No change', ''),
    @('FlexipageFieldInstance', 'Account Company Record Page', $DONE, 'Field displayed + 2 Specialty section filters use Sector values. Planned added next to Bridge (same change as Lead Record Page).', 'Filters now: Bridge OR Planned / not Bridge AND not Planned', 'Deployed to Sandbox (2.2)', '0Afdx00000GAp02CAD'),
    @('FlexipageFieldInstance', 'Account Store Location Record Page', $NO, 'Display only, no Sector filter. Active for the Store_Location record type.', '1 Sector field, 0 Sector filters', 'No change', ''),
    @('Flow', 'Opportunity field update from Account', $NO, 'Before-save flow on Opportunity create: copies Sector, Sales Channel and Cluster from the Account. No value is hard-coded, so new values are copied as they are.', 'Assignments: Opp.Sector__c <- Account.Sector__c; 0 value literals', 'No change', ''),
    @('Layout', 'Company Layout', $NO, 'Field placement only.', '0 value literals', 'No change', ''),
    @('Layout', 'Franchise Layout', $NO, 'Field placement only.', '0 value literals', 'No change', ''),
    @('Layout', 'Store Layout', $NO, 'Field placement only.', '0 value literals', 'No change', ''),
    @('Layout', 'Speciality - Sellgoodr Layout', $NO, 'Field placement only. Layout is NOT assigned to any profile / record type. Its name uses an old Sector name - rename or delete is optional cleanup.', 'Not assigned', 'No change (optional cleanup)', ''),
    @('Layout', 'Specialty - Bridge Layout', $NO, 'Same as above - not assigned; name uses an old Sector name.', 'Not assigned', 'No change (optional cleanup)', ''),
    @('Layout', 'Account Layout', $NO, 'Field placement only.', '0 value literals', 'No change', ''),
    @('ReportType', 'Accounts_with_Contacts_with_Daily_Engagements', $NO, 'Field availability only.', '0 value literals', 'No change', ''),
    @('ReportType', 'Accounts_with_Activities', $NO, 'Field availability only.', '0 value literals', 'No change', ''),
    @('ReportType', 'Account_Duplicates', $NO, 'Field availability only.', '0 value literals', 'No change', ''),
    @('Custom Metadata', 'Sales_Channel_Cluster__mdt', $DONE, 'Added Specialty_Self_Service_Account (Cluster 6) and Specialty_Planned_Account (Cluster 5) next to the old-value rules.', '8 new rules created', 'Deployed to Sandbox (2.1)', '0Afdx00000GAl4TCAT'),
    $cmdtTeam
  )
  'Contact' = @(
    (& $lcs 'sets the Contact Sector from the Lead, line 248'),
    @('FlexipageFieldInstance', 'Contact Record Page', $NO, 'Display only, no Sector filter. Org default Contact page.', '1 Sector field, 0 Sector filters', 'No change', ''),
    @('FlexipageFieldInstance', 'Contact Record Page - Three Column', $NO, 'Display only. Page is NOT activated.', '1 Sector field, 0 Sector filters, not activated', 'No change', ''),
    @('ReportType', 'Accounts_with_Contacts_with_Daily_Engagements', $NO, 'Field availability only.', '0 value literals', 'No change', ''),
    @('ReportType', 'Contacts_with_Daily_Engagements', $NO, 'Field availability only.', '0 value literals', 'No change', ''),
    @('ReportType', 'Contacts_with_Monthly_Engagements', $NO, 'Field availability only.', '0 value literals', 'No change', ''),
    @('ReportType', 'Contacts_and_Sales_Cadence_Trackers', $NO, 'Field availability only.', '0 value literals', 'No change', ''),
    @('ReportType', 'Contact_Duplicates', $NO, 'Field availability only.', '0 value literals', 'No change', ''),
    @('Custom Metadata', 'Sales_Channel_Cluster__mdt', 'Done (no runtime effect)', 'Specialty_Self_Service_Contact and Specialty_Planned_Contact added for consistency. ClusterRuleEngine skips Contact (line 9); Contact.Cluster__c is a formula from the Account.', 'ClusterRuleEngine line 9: if objectName == Contact return', 'Deployed to Sandbox (2.1)', '0Afdx00000GAl4TCAT'),
    $cmdtTeam
  )
  'Opportunity' = @(
    @('FlexipageFieldInstance', 'Opportunity Record Page - Three Column', $NO, 'Display only, no Sector filter. Org default Opportunity page.', '1 Sector field, 0 Sector filters', 'No change', ''),
    @('FlexipageFieldInstance', 'Opportunity Record Page Updated', $NO, 'Display only. The field is shown after the record is saved (Is_Saved__c = true) - not dependent on the Sector value.', 'Visibility rule on Is_Saved__c only', 'No change', ''),
    @('Flow', 'Opportunity field update from Account', $NO, 'Copies the Account Sector onto new Opportunities. No value literals.', 'Opp.Sector__c <- Account.Sector__c', 'No change', ''),
    @('Layout', 'Opportunity Layout', $NO, 'Field placement only.', '0 value literals', 'No change', ''),
    @('ReportType', 'Opportunities_with_Historical_Trending', $NO, 'Field availability only.', '0 value literals', 'No change', ''),
    @('ReportType', 'Opptys', $NO, 'Field availability only.', '0 value literals', 'No change', ''),
    @('ReportType', 'Opportunities_with_Activities', $NO, 'Field availability only.', '0 value literals', 'No change', ''),
    @('Custom Metadata', 'Sales_Channel_Cluster__mdt', $DONE, 'Added Specialty_Self_Service_Opp (Cluster 6) and Specialty_Planned_Opp (Cluster 5) next to the old-value rules.', '8 new rules created', 'Deployed to Sandbox (2.1)', '0Afdx00000GAl4TCAT'),
    $cmdtTeam
  )
}
$r = 5; $first = 5
foreach ($obj in $data.Keys) {
    Band $ws $r $cols.Count $obj; $r++
    foreach ($row in $data[$obj]) {
        Row $ws $r (@($obj) + $row)
        $c = $ws.Cells.Item($r, 4); $s = $ws.Cells.Item($r, 7)
        if ($row[2] -like 'Already done*' -or $row[2] -like 'Done*') { $c.Interior.Color = $lgreen; $s.Interior.Color = $lgreen } elseif ($row[2] -like '*not used*') { $c.Interior.Color = $grey } else { $c.Interior.Color = $blue }
        $r++
    }
    $r++
}
$rg = $ws.Range("A4", "H$r"); $rg.Font.Name = 'Arial'; $rg.Font.Size = 10
$ws.Range("A5", "H$r").WrapText = $true; $ws.Range("A5", "H$r").VerticalAlignment = -4160
$ws.Range("A4", "H$($r-1)").Borders.LineStyle = 1; $ws.Range("A4", "H$($r-1)").Borders.Color = (RGB 191 191 191)
$ws.Range("D5", "D$r").Font.Bold = $true
$lg = $r + 1
$ws.Cells.Item($lg, 1).Formula = 'Legend:'; $ws.Cells.Item($lg, 1).Font.Bold = $true
$ws.Cells.Item($lg, 2).Formula = 'Already done'; $ws.Cells.Item($lg, 2).Interior.Color = $lgreen; $ws.Cells.Item($lg, 3).Formula = 'Uses Sector values - new value added in sandbox'
$ws.Cells.Item($lg + 1, 2).Formula = 'No'; $ws.Cells.Item($lg + 1, 2).Interior.Color = $blue; $ws.Cells.Item($lg + 1, 3).Formula = 'Copies / displays / exposes the field only - works with any value'
$ws.Cells.Item($lg + 2, 2).Formula = 'No - not used'; $ws.Cells.Item($lg + 2, 2).Interior.Color = $grey; $ws.Cells.Item($lg + 2, 3).Formula = 'Component does not reference Sector'
$ws.Activate(); $xl.ActiveWindow.SplitRow = 4; $xl.ActiveWindow.FreezePanes = $true
$ws.Range("A4", "H$($r-1)").AutoFilter() | Out-Null

# ============================================================ Sheet 2: Data to Migrate
$ws = $wb.Worksheets.Item('Data to Migrate')
$ws.Cells.Item(1, 1).Formula = 'Records holding old Sector values (GDRSAND, 7 Oct 2026) - data migration pending, nothing changed yet'; $ws.Cells.Item(1, 1).Font.Size = 13; $ws.Cells.Item(1, 1).Font.Bold = $true
$ws.Cells.Item(2, 1).Formula = 'Source: SOQL GROUP BY Sales_Channel__c, Sector__c. Totals are formulas. Yellow = decision needed. Specialty CAN records are excluded until the Specialty CAN step.'
$ws.Cells.Item(2, 1).Font.Italic = $true
Header $ws 4 @('Sales Channel', 'Old Sector', 'New Sector', 'Account', 'Contact', 'Lead', 'Opportunity', 'Total', 'Comment') @(16, 18, 30, 11, 11, 11, 13, 11, 60)
$dm = @(
 @('Specialty', 'Sellgoodr USA', 'Self Service', 123, 46, 65, 2, 'Approved mapping.'),
 @('Specialty', 'Bridge', 'Planned', 10, 4, 8, 0, 'Approved mapping (Specialty records only).'),
 @('Key Account', 'Core', 'Enterprise', 11, 3, 5, 3, 'Approved mapping.'),
 @('Key Account', 'Mid-Market', 'Strategic or Development?', 5, 3, 3, 0, 'DECISION NEEDED: mapping lists Mid-Market for both Strategic and Development.'),
 @('Key Account', 'Off-Price', 'Discount', 0, 0, 0, 0, 'No records today.'),
 @('Global', 'Global', 'Distributor', 6, 1, 2, 0, 'Approved mapping.'),
 @('Specialty', 'Sellgoodr CAN', 'Self Service', 1, 1, 1, 0, 'Approved mapping (Specialty records only).'),
 @('Partnerships', 'Partnerships', 'Partnerships', 8, 5, 5, 0, 'No change needed - same value.'),
 @('Specialty CAN', 'Sellgoodr CAN', 'Out of scope now', 5, 2, 2, 0, 'Excluded - handled in the Specialty CAN step.'),
 @('Specialty CAN', 'Bridge', 'Out of scope now', 0, 0, 2, 0, 'Excluded - handled in the Specialty CAN step.')
)
$r = 5; foreach ($d in $dm) { Row $ws $r $d[0..6]; $ws.Cells.Item($r, 8).Formula = "=SUM(D$($r):G$($r))"; Set-Cell $ws $r 9 $d[7]; if ($d[2] -like '*?') { $ws.Cells.Item($r, 3).Interior.Color = $yellow }; if ($d[2] -like 'Out of scope*' -or $d[1] -eq 'Partnerships') { $ws.Range("A$r", "I$r").Font.Color = (RGB 128 128 128) }; $r++ }
$last = $r - 1
Set-Cell $ws $r 1 'Total to migrate (excl. Partnerships and Specialty CAN)'; $ws.Range("A$r", "C$r").Merge(); $ws.Cells.Item($r, 1).Font.Bold = $true
foreach ($c in 4..8) { $L = [char](64 + $c); $ws.Cells.Item($r, $c).Formula = "=SUM($($L)5:$($L)11)"; $ws.Cells.Item($r, $c).Font.Bold = $true }
$ws.Range("A4", "I$r").Font.Name = 'Arial'; $ws.Range("A4", "I$r").Font.Size = 10; $ws.Range("A4", "I$r").Borders.LineStyle = 1; $ws.Range("A4", "I$r").Borders.Color = (RGB 191 191 191); $ws.Range("I5", "I$r").WrapText = $true
$n = $r + 2
$notes = @('Notes for the data migration:',
 '1. Back up (export) the records before updating.',
 '2. Updating Sector alone does NOT re-run cluster assignment (ClusterRuleEngine only runs when Sales Channel changes). Clusters stay the same anyway: Self Service -> Cluster 6 and Planned -> Cluster 5, same as Sellgoodr USA and Bridge today.',
 '3. After the migration: remove the old-value cluster rules and Bridge criteria (cleanup), then deactivate the old Sector values.')
for ($j = 0; $j -lt $notes.Count; $j++) { Set-Cell $ws ($n + $j) 1 $notes[$j]; $ws.Cells.Item($n + $j, 1).Font.Name = 'Arial'; $ws.Cells.Item($n + $j, 1).Font.Size = 10 }
$ws.Cells.Item($n, 1).Font.Bold = $true

# ============================================================ Sheet 3: Not in Where-Used List
$ws = $wb.Worksheets.Item('Not in Where-Used List')
$ws.Cells.Item(1, 1).Formula = 'Sector-related items NOT shown by "Where is this used?" (report filters and setup prerequisites)'; $ws.Cells.Item(1, 1).Font.Size = 13; $ws.Cells.Item(1, 1).Font.Bold = $true
$ws.Cells.Item(2, 1).Formula = '"Where is this used?" does not list report filters. Reports were checked in PRODUCTION (read-only, 281 reports) because 4 of the 5 do not exist in the sandbox.'; $ws.Cells.Item(2, 1).Font.Italic = $true
Header $ws 4 @('Type', 'Component', 'Folder / Location', 'Current Sector Use (Production)', 'Change Needed', 'In Sandbox?', 'Last Run (Prod)', 'Comment') @(16, 40, 22, 42, 46, 22, 14, 55)
$nr = @(
 @('Report', 'Locally Locations - Store Locations (Locally_Locations_Store_Locations_8CG)', 'Activity Reports', 'Sector equals Sellgoodr USA, Sellgoodr CAN, Bridge', 'Add Self Service, Planned', 'No', '2026-08-07', 'Additive - old values kept so current records still show.'),
 @('Report', 'Locally Locations - US/Bridge Only (Locally_Locations_PVL)', 'Admin Report', 'Sector equals Sellgoodr USA, Bridge', 'Add Self Service, Planned', 'No', '2026-08-14', 'Additive.'),
 @('Report', 'Accounts - Bridge, Core, MM, P, G (All_Accounts_Company_w_NS_IDs_QK8)', 'Admin Report', 'Sector equals Bridge, Core, Mid-Market, Off-Price, Partnerships, Global', 'Add Planned, Enterprise, Strategic, Development, Discount, Distributor', 'No', '2026-08-12', 'Additive. Report name uses old Sector names - rename optional.'),
 @('Report', 'Bridge Accounts (Bridge_Accounts)', 'Public Reports', 'Sector equals Bridge (and Sales Channel = Specialty, Specialty CAN)', 'Add Planned', 'No', '2026-08-03', 'Additive. Sales Channel part belongs to the Specialty CAN step.'),
 @('Report', 'Specialty Classification (Specialty_Classification)', 'Public Reports', 'Sector equals Sellgoodr USA, Sellgoodr CAN, Bridge', 'Add Self Service, Planned', 'Yes - but older copy WITHOUT the Sector filter', '2026-09-21', 'Build from the Production version.'),
 @('Setup (prerequisite)', 'Sector value set - 7 new values', 'Setup > Picklist Value Sets > Sector', 'Production has only the 8 old values', 'Add Enterprise, Strategic, Development, Discount, Planned, Self Service, Distributor', 'Already in sandbox', '', 'Manual step before the Sector production deployment.'),
 @('Setup (prerequisite)', 'Sector field dependency (Account, Contact, Lead, Opportunity)', 'Object Manager > Sector > Field Dependencies', 'No new values mapped in Production', 'Key Account -> Enterprise, Strategic, Development, Discount; Specialty -> Planned, Self Service; Global -> Distributor', 'Already in sandbox', '', 'Manual step; do after the Key Account rename.'),
 @('Setup (prerequisite)', 'Record type picklist values (Account x3, Opportunity x3)', 'Object Manager > Record Types', 'New values not enabled in Production', 'Enable the 7 new Sector values', 'Already in sandbox', '', 'Manual step (UI visibility of values).')
)
$r = 5; foreach ($d in $nr) { Row $ws $r $d; if ($d[0] -eq 'Report') { $ws.Cells.Item($r, 5).Interior.Color = $yellow }; $r++ }
$ws.Range("A4", "H$($r-1)").Font.Name = 'Arial'; $ws.Range("A4", "H$($r-1)").Font.Size = 10; $ws.Range("A5", "H$($r-1)").WrapText = $true; $ws.Range("A5", "H$($r-1)").VerticalAlignment = -4160
$ws.Range("A4", "H$($r-1)").Borders.LineStyle = 1; $ws.Range("A4", "H$($r-1)").Borders.Color = (RGB 191 191 191)
Set-Cell $ws ($r + 1) 1 'Also: 2 private Production reports owned by other users could not be read - confirm with "Where is this used?" in Production.'
$ws.Cells.Item($r + 1, 1).Font.Italic = $true

foreach ($s in $wb.Worksheets) { $s.PageSetup.Orientation = 2; $s.PageSetup.Zoom = $false; $s.PageSetup.FitToPagesWide = 1; $s.PageSetup.FitToPagesTall = $false }
$wb.Worksheets.Item(1).Activate()
$xl.ScreenUpdating = $true
$xl.CalculateFull()
if (Test-Path $out) { Remove-Item $out -Force -Confirm:$false }
$wb.SaveAs($out, 51)
$d2 = $wb.Worksheets.Item('Data to Migrate'); "migrate totals row: " + ((4..8 | % { $d2.Cells.Item(15, $_).Text }) -join ' | ')
$errs = 0; foreach ($s in $wb.Worksheets) { foreach ($c in $s.UsedRange.Cells) { if ($c.HasFormula -and $c.Text -match '^#') { $errs++ } } }; "formula errors: $errs"
"rows on sheet 1: " + ($wb.Worksheets.Item(1).UsedRange.Rows.Count)
$wb.Close($false); $xl.Quit(); [Runtime.InteropServices.Marshal]::ReleaseComObject($xl) | Out-Null
"Saved $out"
