$ErrorActionPreference = 'Stop'
$out = 'C:\Microsoft VS Code\GDRSandbox\deployment\ChangeSet_Component_List.xlsx'
function RGB($r, $g, $b) { return [int]($r + $g * 256 + $b * 65536) }
$hdr = RGB 31 56 100; $band = RGB 182 215 168; $yellow = RGB 255 242 204; $green = RGB 198 239 206; $pink = RGB 244 204 204; $blue = RGB 221 235 247
$xl = New-Object -ComObject Excel.Application; $xl.Visible = $false; $xl.DisplayAlerts = $false; $xl.ScreenUpdating = $false
$wb = $xl.Workbooks.Add()
$names = 'Add to Change Set', 'Do NOT add (handle separately)', 'Manual Steps in Production', 'Deploy Order and Tests'
while ($wb.Worksheets.Count -lt $names.Count) { [void]$wb.Worksheets.Add([Type]::Missing, $wb.Worksheets.Item($wb.Worksheets.Count)) }
for ($i = 1; $i -le $names.Count; $i++) { $wb.Worksheets.Item($i).Name = $names[$i - 1] }
function Put-Cell($ws, $r, $c, $v) { if ($null -ne $v -and "$v" -ne '') { $s = [string]$v; if ($s -match '^[=+\-@]') { $s = "'" + $s }; $ws.Cells.Item($r, $c).Formula = $s } }
function Head($ws, $r, $cols, $w) { for ($c = 0; $c -lt $cols.Count; $c++) { Put-Cell $ws $r ($c + 1) $cols[$c]; $ws.Columns.Item($c + 1).ColumnWidth = $w[$c] }; $g = $ws.Range($ws.Cells.Item($r, 1), $ws.Cells.Item($r, $cols.Count)); $g.Font.Bold = $true; $g.Font.Color = (RGB 255 255 255); $g.Interior.Color = $hdr; $g.WrapText = $true; $g.VerticalAlignment = -4108 }
function Title($ws, $t, $s) { Put-Cell $ws 1 1 $t; $ws.Cells.Item(1, 1).Font.Size = 14; $ws.Cells.Item(1, 1).Font.Bold = $true; Put-Cell $ws 2 1 $s; $ws.Cells.Item(2, 1).Font.Italic = $true }
function Fmt($ws, $a, $b) { $g = $ws.Range($a, $b); $g.Font.Name = 'Arial'; $g.Font.Size = 10; $g.WrapText = $true; $g.VerticalAlignment = -4160; $g.Borders.LineStyle = 1; $g.Borders.Color = (RGB 191 191 191) }
function Band($ws, $r, $n, $t) { $m = $ws.Range($ws.Cells.Item($r, 1), $ws.Cells.Item($r, $n)); $m.Merge(); Put-Cell $ws $r 1 $t; $m.Font.Bold = $true; $m.Interior.Color = $band }

# ---------------- Add to Change Set
$ws = $wb.Worksheets.Item('Add to Change Set')
Title $ws 'Outbound Change Set (GDRSAND -> Production): components to ADD' 'Setup > Outbound Change Sets > New > Add. "Type" = the value to pick in the Component Type list. Checked 9 Oct 2026 against Production (read-only).'
$cols = '#', 'Component Type (in Add screen)', 'Component Name', 'Area', 'What changed', 'Safe for change set?', 'Note', 'Added? (Y/N)'
Head $ws 4 $cols @(5, 26, 44, 16, 50, 16, 60, 11)
$rows = [ordered]@{
 'Apex Classes (13)' = @(
  @('Apex Class', 'ClusterRuleEngine', 'Cluster fix', 'Re-evaluates cluster when Sales Channel OR Sector changes', 'Yes', 'Sandbox = Production + our change only.'),
  @('Apex Class', 'AccountCascadeHandler', 'Cluster fix', 'Also syncs Sector to open Opportunities', 'REVIEW', 'Sandbox version ALSO contains a change not made by us: it enqueues ContactTeamReassignQueueable (exists in Production). Adding it from the sandbox will switch that on in Production. If not wanted, deploy the Production version + our change instead (CLI package).'),
  @('Apex Class', 'LeadConversionHandler', 'Cluster fix', 'Also syncs Sector to open Opportunities on conversion', 'Yes', ''),
  @('Apex Class', 'ClusterRuleEngineTest', 'Cluster fix + Key Account', 'Key Account test values + new Sector-change test', 'Yes', ''),
  @('Apex Class', 'AccountCascadeHandlerTest', 'Cluster fix + Key Account', 'Key Account test value + new Sector cascade test', 'Yes', ''),
  @('Apex Class', 'ClusterTriggerTest', 'Key Account', "'Key Accounts' -> 'Key Account'", 'Yes', ''),
  @('Apex Class', 'ContactTriggerHandlerTest', 'Key Account', "'Key Accounts' -> 'Key Account'", 'Yes', ''),
  @('Apex Class', 'LeadConversionHandlerTest', 'Key Account', "'Key Accounts' -> 'Key Account'", 'Yes', ''),
  @('Apex Class', 'LeadConversionHandlerTest1', 'Key Account + Specialty CAN', "'Key Accounts' -> 'Key Account', 'Specialty CAN' -> 'Specialty'", 'Yes', ''),
  @('Apex Class', 'ShopifyAddressSyncTest', 'Key Account', "'Key Accounts' -> 'Key Account'", 'Yes', ''),
  @('Apex Class', 'ShopifyOrderSyncTest', 'Key Account', "'Key Accounts' -> 'Key Account'", 'Yes', '2 date-based test methods fail in the sandbox (sandbox-only code differences); they pass in Production.'),
  @('Apex Class', 'ShopifySalesSyncServiceTest', 'Key Account', "'Key Accounts' -> 'Key Account'", 'Yes', ''),
  @('Apex Class', 'ShopifyAssociationSyncSchedulableTest', 'Specialty CAN', "'Specialty CAN' -> 'Specialty'", 'Yes', '')
 )
 'Flow (1)' = @(
  @('Flow', 'Lead_From_US_Retailer_Form_Assignment_And_Email (Lead From TypeForm Form Assignment And Email)', 'Specialty CAN', "Canada form path: Sales Channel 'Specialty CAN' -> 'Specialty'", 'Yes', 'Production active version = sandbox baseline. Arrives in Production as a new version - ACTIVATE it after deployment.')
 )
 'Custom Fields (3)' = @(
  @('Custom Field', 'Account.Sales Channel V1 (Sales_Channel_V1__c)', 'Data migration', 'New Text(50) backup field', 'Yes', 'Add Profile: System Administrator (Read + Edit). Not on any layout.'),
  @('Custom Field', 'Account.Sector V1 (Sector_V1__c)', 'Data migration', 'New Text(50) backup field', 'Yes', 'Same as above.'),
  @('Custom Field', 'Account Cluster Team.Sales Channel (Account_Cluster_Team__mdt.Sales_Channel__c)', 'Key Account', 'Picklist value "Key Account" added', 'Yes', 'Needed before the Account Cluster Team records are updated.')
 )
 'Custom Metadata Records - Sales Channel Cluster (12)' = @(
  @('Sales Channel Cluster (custom metadata record)', 'Keys_Account_Account', 'Key Account', "Rule: 'Key Accounts' -> 'Key Account'", 'Yes', ''),
  @('Sales Channel Cluster (custom metadata record)', 'Key_Account_Lead', 'Key Account', 'Same', 'Yes', ''),
  @('Sales Channel Cluster (custom metadata record)', 'Key_Account_Opp', 'Key Account', 'Same', 'Yes', ''),
  @('Sales Channel Cluster (custom metadata record)', 'Key_Account_Contact', 'Key Account', 'Same', 'Yes', ''),
  @('Sales Channel Cluster (custom metadata record)', 'Specialty_Self_Service_Account', 'Sector', 'NEW rule Specialty + Self Service -> Cluster 6', 'Yes', ''),
  @('Sales Channel Cluster (custom metadata record)', 'Specialty_Self_Service_Lead', 'Sector', 'NEW rule -> Cluster 6', 'Yes', ''),
  @('Sales Channel Cluster (custom metadata record)', 'Specialty_Self_Service_Opp', 'Sector', 'NEW rule -> Cluster 6', 'Yes', ''),
  @('Sales Channel Cluster (custom metadata record)', 'Specialty_Self_Service_Contact', 'Sector', 'NEW rule -> Cluster 6', 'Yes', ''),
  @('Sales Channel Cluster (custom metadata record)', 'Specialty_Planned_Account', 'Sector', 'NEW rule Specialty + Planned -> Cluster 5', 'Yes', ''),
  @('Sales Channel Cluster (custom metadata record)', 'Specialty_Planned_Lead', 'Sector', 'NEW rule -> Cluster 5', 'Yes', ''),
  @('Sales Channel Cluster (custom metadata record)', 'Specialty_Planned_Opp', 'Sector', 'NEW rule -> Cluster 5', 'Yes', ''),
  @('Sales Channel Cluster (custom metadata record)', 'Specialty_Planned_Contact', 'Sector', 'NEW rule -> Cluster 5', 'Yes', '')
 )
 'Lightning Pages (4) - REVIEW before adding' = @(
  @('Lightning Page', 'Account_Company_Record_Page', 'Key Account + Sector + V1', 'Key Account filter; Specialty sections = Self Service / Planned; V1 fields', 'REVIEW', 'Sandbox page ALSO contains other sandbox changes not in Production. Requires Key Account + new Sector values to exist in Production (otherwise deployment fails). Deploy after the data migration. Alternative: Production-built package or edit in Lightning App Builder.'),
  @('Lightning Page', 'Lead_Record_Page', 'Key Account + Sector + Specialty CAN', 'Key Account filter; Specialty sections; Convert button without Specialty CAN', 'REVIEW', 'Same as above.'),
  @('Lightning Page', 'Account_Store_Location_Record_Page1', 'V1 fields', 'Sales Channel V1 / Sector V1 added after Sector', 'REVIEW', 'Sandbox page differs from Production (other changes would be carried over).'),
  @('Lightning Page', 'Account_Franchise_Record_Page1', 'V1 fields', 'Sales Channel V1 / Sector V1 added after Sector', 'REVIEW', 'Same as above.')
 )
 'Profile Settings (in the change set "Profile Settings For Included Components")' = @(
  @('Profile', 'System Administrator', 'Data migration', 'Field access Read + Edit on Sales Channel V1 / Sector V1', 'Yes', 'Only System Administrator should get edit access.')
 )
}
$r = 5; $n = 0
foreach ($k in $rows.Keys) { Band $ws $r $cols.Count $k; $r++
  foreach ($x in $rows[$k]) { $n++; Put-Cell $ws $r 1 $n; for ($c = 0; $c -lt $x.Count; $c++) { Put-Cell $ws $r ($c + 2) $x[$c] }
    $s = $ws.Cells.Item($r, 6); $s.HorizontalAlignment = -4108; $s.Font.Bold = $true; if ($x[4] -eq 'Yes') { $s.Interior.Color = $green } else { $s.Interior.Color = $yellow }
    $ws.Cells.Item($r, 8).Interior.Color = $yellow; $r++ } }
Fmt $ws "A4" "H$($r-1)"
$dv = $ws.Range("H5", "H$($r-1)").Validation; $dv.Delete(); $dv.Add(3, 1, 1, 'Y,N')
$ws.Activate(); $xl.ActiveWindow.SplitRow = 4; $xl.ActiveWindow.FreezePanes = $true

# ---------------- Do NOT add
$ws = $wb.Worksheets.Item('Do NOT add (handle separately)')
Title $ws 'Components changed in the sandbox that must NOT go in the change set' 'Reason and how to deliver them instead.'
Head $ws 4 @('Component Type', 'Component', 'Reason', 'Deliver instead') @(24, 46, 60, 60)
$dn = @(
 @('Account Cluster Team (custom metadata records)', '116 records (Clusters 1-4, Sales Channel Key Accounts -> Key Account)', 'Sandbox records point to SANDBOX users (username@goodr.com.partial). A change set would overwrite Production team users and break team assignment. 16 of them do not exist in Production.', 'deployment/KeyAccount_Rename_PROD package (built from Production records, users kept) - or update the 100 Production records manually. Label-only change: team assignment works without it.'),
 @('Sales Channel Cluster (custom metadata record)', 'Testtwoconditions', 'Sandbox-only record - does not exist in Production.', 'Not needed.'),
 @('Apex Class', 'ShopifyAssociationRetryBatch', 'Class does not exist in Production (sandbox-only work, 0% test coverage).', 'Deploy with its own release + a test class.'),
 @('Report', 'Shopify Accounts CAN/Source - Cluster 3 (Shopify_Accounts_CANSource_Cluster_3_Abw)', 'Lives in folder Cluster3 in the sandbox but Cluster6 in Production - a change set would create a second copy.', 'Edit the Production report filter in the UI, or deploy deployment/SpecialtyCAN_Phase1_PROD (Cluster6 version).'),
 @('Report', 'Shopify Accounts Created CAN - Cluster 3 (Shopify_Accounts_Created_CAN_Cluster_3_k2J)', 'Same as above.', 'Same as above.'),
 @('Global Value Set / Picklist values', 'Sales Channel (Key Accounts -> Key Account rename), Lead Sales Channel, Sector new values, deactivations, field dependencies, record type values', 'A change set would ADD a value instead of RENAMING it (records would not be updated) and cannot reliably carry dependencies / record type values.', 'Manual steps in Production Setup - see sheet "Manual Steps in Production".'),
 @('Data', 'Account / Contact / Lead / Opportunity Sales Channel + Sector values', 'Data is not metadata.', 'Data Loader files in deployment/DataMigration_Account_Sandbox (Production files to be generated from Production data).')
)
$r = 5; foreach ($x in $dn) { for ($c = 0; $c -lt 4; $c++) { Put-Cell $ws $r ($c + 1) $x[$c] }; $ws.Cells.Item($r, 1).Interior.Color = $pink; $r++ }; Fmt $ws "A4" "D$($r-1)"

# ---------------- Manual Steps
$ws = $wb.Worksheets.Item('Manual Steps in Production')
Title $ws 'Manual Setup steps in Production (not in the change set)' 'Order matters - the change set deployment needs these values to exist.'
Head $ws 4 @('When', 'Step', 'Where', 'Status') @(18, 80, 60, 14)
$ms = @(
 @('BEFORE deploy', "Rename Sales Channel value 'Key Accounts' -> 'Key Account' (Label + API Name)", 'Setup > Picklist Value Sets > Sales Channel', ''),
 @('BEFORE deploy', "Rename Lead Sales Channel value 'Key Accounts' -> 'Key Account' (Production Lead field is a LOCAL picklist)", 'Object Manager > Lead > Fields > Sales Channel', ''),
 @('BEFORE deploy', 'Add Sector values: Enterprise, Strategic, Development, Discount, Planned, Self Service, Distributor', 'Setup > Picklist Value Sets > Sector', ''),
 @('BEFORE deploy', 'Sector field dependency on Account, Contact, Lead, Opportunity: Key Account -> Enterprise, Strategic, Development, Discount; Specialty -> Planned, Self Service; Global -> Distributor; Partnerships -> Partnerships', 'Object Manager > <Object> > Fields > Sector > Field Dependencies', ''),
 @('BEFORE deploy', 'Enable Key Account + new Sector values on record types (Account: Company, Franchise, Store_Location; Opportunity: Key_Account, Partnerships, Specialty)', 'Object Manager > Record Types', ''),
 @('AFTER deploy', 'Activate the new version of flow "Lead From TypeForm Form Assignment And Email"', 'Setup > Flows', ''),
 @('AFTER deploy', 'Fix report "Accounts without NetSuite Id" filter -> Key Account, Key Account CAN (the rename removes Key Accounts from the filter)', 'Reports > Public Reports', ''),
 @('AFTER deploy', 'Update the 2 Shopify CAN reports (Cluster 6 folder) filter: Specialty CAN OR (Specialty AND Billing Country = CA)', 'Reports > Cluster 6', ''),
 @('AFTER data migration', 'Deactivate old Sector values (Sellgoodr USA, Sellgoodr CAN, Bridge, Core, Mid-Market, Off-Price, Global) and Sales Channel Specialty CAN', 'Picklist Value Sets', ''),
 @('AFTER data migration', 'Deploy / edit the Lightning pages (they reference only the new values)', 'Lightning App Builder or package', '')
)
$r = 5; foreach ($x in $ms) { for ($c = 0; $c -lt 4; $c++) { Put-Cell $ws $r ($c + 1) $x[$c] }; $ws.Cells.Item($r, 4).Interior.Color = $yellow; $r++ }; Fmt $ws "A4" "D$($r-1)"

# ---------------- Deploy order
$ws = $wb.Worksheets.Item('Deploy Order and Tests')
Title $ws 'Recommended order and test settings' ''
Head $ws 4 @('#', 'Step', 'Detail') @(5, 40, 110)
$do = @(
 @('1', 'Manual steps BEFORE deploy', 'Sheet "Manual Steps in Production" rows 1-5.'),
 @('2', 'Upload the change set from GDRSAND', 'Setup > Outbound Change Sets > (your change set) > Upload > target = Production.'),
 @('3', 'Validate in Production', 'Setup > Inbound Change Sets > Validate > Run specified tests: ClusterRuleEngineTest, AccountCascadeHandlerTest, ClusterTriggerTest, ContactTriggerHandlerTest, LeadConversionHandlerTest, LeadConversionHandlerTest1, ShopifyAddressSyncTest, ShopifyOrderSyncTest, ShopifySalesSyncServiceTest, ShopifyAssociationSyncSchedulableTest. (Apex classes ClusterRuleEngine, AccountCascadeHandler, LeadConversionHandler need 75% coverage - sandbox: 93% / 100% / 88%.)'),
 @('4', 'Quick Deploy', 'After a successful validation.'),
 @('5', 'Manual steps AFTER deploy', 'Activate the flow; fix the 3 reports.'),
 @('6', 'Data migration', 'Production data files (backup V1 first, then update), then deactivate old values.'),
 @('7', 'Lightning pages', 'Deploy / edit the 4 pages last (they need the new values and migrated data).'),
 @('Note', 'Lightning pages in the change set', 'If you add the 4 Lightning pages to this change set, the validation will FAIL until Key Account and the new Sector values exist in Production, and they will carry other sandbox page changes. Safer: a separate change set / package for the pages after the data migration.')
)
$r = 5; foreach ($x in $do) { for ($c = 0; $c -lt 3; $c++) { Put-Cell $ws $r ($c + 1) $x[$c] }; $r++ }; Fmt $ws "A4" "C$($r-1)"

foreach ($s in $wb.Worksheets) { $s.PageSetup.Orientation = 2; $s.PageSetup.Zoom = $false; $s.PageSetup.FitToPagesWide = 1; $s.PageSetup.FitToPagesTall = $false }
$wb.Worksheets.Item(1).Activate(); $xl.ScreenUpdating = $true
if (Test-Path $out) { Remove-Item $out -Force -Confirm:$false }
$wb.SaveAs($out, 51); "components to add listed: $n"
$wb.Close($false); $xl.Quit(); [Runtime.InteropServices.Marshal]::ReleaseComObject($xl) | Out-Null
"Saved $out"
