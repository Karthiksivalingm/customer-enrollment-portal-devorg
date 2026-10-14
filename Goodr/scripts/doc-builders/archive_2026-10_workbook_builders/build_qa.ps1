$ErrorActionPreference = 'Stop'
$out = 'C:\Microsoft VS Code\GDRSandbox\deployment\QA_Test_Scenarios_KeyAccount_Sector_SpecialtyCAN.xlsx'
$sp = 'C:\Users\UTIS LAPTOP 377\AppData\Local\Temp\claude\c--Microsoft-VS-Code-GDRSandbox\d08dd3dc-7817-4434-9679-5763d2940328\scratchpad'
function RGB($r, $g, $b) { return [int]($r + $g * 256 + $b * 65536) }
$hdr = RGB 31 56 100; $band = RGB 182 215 168; $yellow = RGB 255 242 204; $blue = RGB 221 235 247; $pink = RGB 244 204 204; $grey = RGB 231 230 230; $green = RGB 198 239 206

$xl = New-Object -ComObject Excel.Application; $xl.Visible = $false; $xl.DisplayAlerts = $false; $xl.ScreenUpdating = $false
$wb = $xl.Workbooks.Add()
$names = 'Read Me', 'What Changed', 'Test Cases', 'Expected Results Matrix', 'Expected Team Members', 'Known Issues', 'Defect Log'
while ($wb.Worksheets.Count -lt $names.Count) { [void]$wb.Worksheets.Add([Type]::Missing, $wb.Worksheets.Item($wb.Worksheets.Count)) }
for ($i = 1; $i -le $names.Count; $i++) { $wb.Worksheets.Item($i).Name = $names[$i - 1] }

function Put-Cell($ws, $r, $c, $v) { if ($null -ne $v -and "$v" -ne '') { $s = [string]$v; if ($s -match '^[=+\-@]') { $s = "'" + $s }; $ws.Cells.Item($r, $c).Formula = $s } }
function Head($ws, $r, $cols, $w) { for ($c = 0; $c -lt $cols.Count; $c++) { Put-Cell $ws $r ($c + 1) $cols[$c]; $ws.Columns.Item($c + 1).ColumnWidth = $w[$c] }; $g = $ws.Range($ws.Cells.Item($r, 1), $ws.Cells.Item($r, $cols.Count)); $g.Font.Bold = $true; $g.Font.Color = (RGB 255 255 255); $g.Interior.Color = $hdr; $g.WrapText = $true; $g.VerticalAlignment = -4108; $g.HorizontalAlignment = -4108 }
function Band($ws, $r, $n, $t) { $m = $ws.Range($ws.Cells.Item($r, 1), $ws.Cells.Item($r, $n)); $m.Merge(); Put-Cell $ws $r 1 $t; $m.Font.Bold = $true; $m.Interior.Color = $band }
function Title($ws, $t, $s) { Put-Cell $ws 1 1 $t; $ws.Cells.Item(1, 1).Font.Size = 14; $ws.Cells.Item(1, 1).Font.Bold = $true; Put-Cell $ws 2 1 $s; $ws.Cells.Item(2, 1).Font.Italic = $true }
function Fmt($ws, $a, $b) { $g = $ws.Range($a, $b); $g.Font.Name = 'Arial'; $g.Font.Size = 10; $g.WrapText = $true; $g.VerticalAlignment = -4160; $g.Borders.LineStyle = 1; $g.Borders.Color = (RGB 191 191 191) }

# ================================================================ Read Me
$ws = $wb.Worksheets.Item('Read Me')
Title $ws 'QA Test Pack - Key Account rename, Sector new values, Specialty CAN (Sandbox GDRSAND)' 'Prepared 9 Oct 2026. UI-level testing of configuration changes deployed to the GDRSAND sandbox (partial copy).'
$rm = @(
 @('Purpose', 'Confirm in the Salesforce UI that the changes work for NEW values and that existing records with OLD values still behave exactly as before (no regression).'),
 @('Environment', 'Sandbox GDRSAND - https://energy-enterprise-8976--partial.sandbox.my.salesforce.com. Use your sandbox login.'),
 @('What changed (short)', '1) Sales Channel value "Key Accounts" renamed to "Key Account". 2) New Sector values (Enterprise, Strategic, Development, Discount, Planned, Self Service, Distributor) now drive the same clusters and page sections as the old values. 3) Canada Typeform leads now get Sales Channel "Specialty" (old "Specialty CAN" still works). Old values were NOT removed - both old and new must work.'),
 @('Key rule', 'Every new value must give the SAME cluster, team and page sections as the old value it replaces (see sheet "Expected Results Matrix").'),
 @('How to test', '1) Work through sheet "Test Cases" in order (P1 first). 2) Create your own test records - start names with "QA TEST" so they are easy to find and delete. 3) Fill Actual Result, Status (Pass / Fail / Blocked / Not Run), Tested By, Test Date. 4) Log failures in "Defect Log" and put the Defect ID on the test case. 5) Check "Known Issues" before logging a defect.'),
 @('Mandatory fields (test data)', 'Company Account: Account Name, Record Type = Company, Tax ID (9 digits, unique), Billing address. Lead: First/Last Name, Company, Email, Tax ID (9 digits, unique), Terms of Service = I agree, Has Physical Store = checked, Resale Certificate Status. Opportunity: Name, Account, Stage = Summary, Close Date.'),
 @('Where to look', 'Cluster: field "Cluster" on Account / Lead / Opportunity (Contact shows the Account cluster). Team: related lists "Account Team" (Account), "Lead Team" (Lead), "Contact Team" (Contact), "Opportunity Team" (Opportunity). Page sections: Details tab of the Account (Company) and Lead record pages.'),
 @('Important behaviour', 'Cluster is recalculated when a record is CREATED or when its SALES CHANNEL changes. Changing only the Sector does NOT recalculate the cluster (existing behaviour - not a defect). Team members are refreshed when the cluster or Sales Channel changes. A user holding two roles is listed once in the team.'),
 @('Status values', 'Pass = matches Expected Result. Fail = does not match (log defect). Blocked = cannot execute (e.g. missing access / Typeform). Not Run = not executed yet.'),
 @('Contacts', 'Raise questions to the Salesforce development team.')
)
$r = 4; foreach ($x in $rm) { Put-Cell $ws $r 1 $x[0]; Put-Cell $ws $r 2 $x[1]; $ws.Cells.Item($r, 1).Font.Bold = $true; $ws.Cells.Item($r, 1).Interior.Color = $blue; $r++ }
$ws.Columns.Item(1).ColumnWidth = 26; $ws.Columns.Item(2).ColumnWidth = 130; Fmt $ws "A4" "B$($r-1)"

# ================================================================ What Changed
$ws = $wb.Worksheets.Item('What Changed')
Title $ws 'What changed - old vs new (sandbox)' 'Old values are still active. Both old and new values must work.'
Head $ws 4 @('#', 'Area', 'Old (before)', 'New (after)', 'Where QA will see it in the UI', 'Covered by test cases') @(5, 26, 38, 44, 55, 22)
$wc = @(
 @('1', 'Sales Channel picklist', 'Key Accounts', 'Key Account (label and value renamed). Existing records updated automatically.', 'Sales Channel field on Account, Contact, Lead, Opportunity', 'KA-01, KA-06'),
 @('2', 'Cluster rules - Key Account', "Rule: Sales Channel = 'Key Accounts' -> Cluster 1", "Rule: Sales Channel = 'Key Account' -> Cluster 1", 'Cluster field + team on Key Account records', 'KA-03, KA-05, KA-07, KA-09'),
 @('3', 'Lightning page - Key Account section', 'Visible when Sales Channel = Key Accounts', 'Visible when Sales Channel = Key Account', 'Account (Company) page and Lead page - section "Key Account"', 'KA-04, KA-05'),
 @('4', 'Cluster team setup', 'Team records labelled Key Accounts', 'Labelled Key Account (team members unchanged)', 'Account / Lead / Contact / Opportunity team related lists', 'KA-03, KA-05, KA-07, KA-08'),
 @('5', 'Sector picklist (new values)', 'Sellgoodr USA, Sellgoodr CAN, Bridge, Core, Mid-Market, Off-Price, Global, Partnerships', 'ADDED: Enterprise, Strategic, Development, Discount (Key Account); Planned, Self Service (Specialty); Distributor (Global). Old values kept.', 'Sector field (dependent on Sales Channel)', 'SEC-01'),
 @('6', 'Cluster rules - Sector', 'Specialty + Sellgoodr USA -> Cluster 6; Specialty + Bridge -> Cluster 5', 'ADDED: Specialty + Self Service -> Cluster 6; Specialty + Planned -> Cluster 5 (old rules kept)', 'Cluster field + team', 'SEC-02 to SEC-09'),
 @('7', 'Lightning page - Specialty sections', 'Specialty - Bridge: Sector = Bridge. Specialty - Sellgoodr: Sector not Bridge', 'Specialty - Bridge: Sector = Bridge OR Planned. Specialty - Sellgoodr: Sector not Bridge AND not Planned', 'Account (Company) page and Lead page - sections "Specialty - Sellgoodr" / "Specialty - Bridge"', 'SEC-02 to SEC-07, CAN-03 to CAN-05'),
 @('8', 'Canada Typeform lead flow', 'Canada form lead -> Sales Channel = Specialty CAN', 'Canada form lead -> Sales Channel = Specialty (queue "Lead Retailers Canada" and email unchanged)', 'New lead created from the Canada retailer Typeform', 'CAN-01, CAN-02'),
 @('9', 'Shopify CAN reports (2)', 'Sales Channel = Specialty CAN', 'Sales Channel = Specialty CAN OR (Specialty AND Billing Country = Canada)', 'Reports "Shopify Accounts CAN/Source - Cluster 3" and "Shopify Accounts Created CAN - Cluster 3"', 'CAN-07'),
 @('10', 'Specialty CAN (old value)', 'Specialty CAN + Sellgoodr CAN -> Cluster 6; + Bridge -> Cluster 5', 'UNCHANGED - still works (kept until data migration)', 'Cluster, team, page sections on Specialty CAN records', 'CAN-03, CAN-04, CAN-06')
)
$r = 5; foreach ($x in $wc) { for ($c = 0; $c -lt $x.Count; $c++) { Put-Cell $ws $r ($c + 1) $x[$c] }; $r++ }; Fmt $ws "A4" "F$($r-1)"

# ================================================================ Test Cases
$ws = $wb.Worksheets.Item('Test Cases')
Title $ws 'Test Cases - UI testing (sandbox GDRSAND)' 'Fill the yellow columns. Use record names starting "QA TEST". Expected clusters / sections / teams: see "Expected Results Matrix" and "Expected Team Members".'
$cols = 'TC ID', 'Module', 'Test Scenario', 'Value Type', 'Pre-conditions / Test Data', 'Test Steps', 'Expected Result', 'Priority', 'Actual Result', 'Status', 'Tested By', 'Test Date', 'Defect ID / Comments'
Head $ws 4 $cols @(9, 15, 34, 10, 36, 52, 52, 8, 30, 11, 14, 12, 26)
$acc = 'Create a Company Account'
$tc = [ordered]@{
 'A. KEY ACCOUNT (Sales Channel "Key Accounts" renamed to "Key Account")' = @(
  @('KA-01', 'Picklist', 'Sales Channel shows "Key Account" (not "Key Accounts") on all objects', 'New', 'Any user with edit access', "1. Open any Account and click Edit.`n2. Open the Sales Channel picklist.`n3. Repeat on a Lead, a Contact and an Opportunity.", '"Key Account" is listed. "Key Accounts" is NOT listed. Other values (Specialty, Specialty CAN, Partnerships, Global) unchanged.', 'P1'),
  @('KA-02', 'Picklist', 'Sector options for Key Account', 'New + Old', 'Any Account (Company)', "1. Edit an Account.`n2. Set Sales Channel = Key Account.`n3. Open the Sector picklist.", 'Sector shows Enterprise, Strategic, Development, Discount (new) AND Core, Mid-Market, Off-Price (old, still available).', 'P1'),
  @('KA-03', 'Cluster + Team', 'New Key Account company gets Cluster 1 and the Cluster 1 team', 'New', 'QA TEST KA Account; Sales Channel = Key Account; Sector = Enterprise; Tax ID 9 digits', "1. $acc with the test data.`n2. Save and refresh the page.`n3. Check the Cluster field.`n4. Open the Account Team related list.", 'Cluster = Cluster 1. Account Team = Cluster 1 Account members (see Expected Team Members).', 'P1'),
  @('KA-04', 'Lightning Page', 'Key Account section visible on the Account page', 'New', 'Account from KA-03', "1. Open the account from KA-03.`n2. Go to the Details tab.", 'Section "Key Account" is visible (Target IMU, EDI, Custom Tagging, Co-Op, New Store Discount Allowance). Sections "Specialty - Sellgoodr", "Specialty - Bridge", "Partnership", "Global" are NOT visible.', 'P1'),
  @('KA-05', 'Lead', 'Key Account lead - cluster, team, page section, Convert button', 'New', 'QA TEST KA Lead; Sales Channel = Key Account; Sector = Strategic; mandatory lead fields', "1. Create the lead and save.`n2. Check Cluster.`n3. Open the Lead Team related list.`n4. Details tab: check sections.`n5. Set Status = Qualified and save; check the Convert button.", 'Cluster = Cluster 1. Lead Team = Cluster 1 Lead members. Section "Key Account" visible; Specialty sections hidden. Convert button visible when Status = Qualified.', 'P1'),
  @('KA-06', 'Regression', 'Existing Key Account record still works', 'Old (renamed)', 'Any EXISTING account with Sales Channel = Key Account (e.g. list view filter)', "1. Open an existing Key Account account.`n2. Check Sales Channel, Cluster, Account Team and the Key Account section.", 'Sales Channel shows "Key Account". Cluster and team unchanged (Cluster 1-4). Key Account section visible.', 'P1'),
  @('KA-07', 'Opportunity', 'Opportunity on a Key Account account copies values', 'New', 'Account from KA-03', "1. From the KA-03 account, create an Opportunity (Stage = Summary, Close Date in future).`n2. Save and check Sales Channel, Sector, Cluster.`n3. Open the Opportunity Team related list.", 'Opportunity Sales Channel = Key Account, Sector = Enterprise, Cluster = Cluster 1. Opportunity Team = Cluster 1 Opportunity members.', 'P1'),
  @('KA-08', 'Contact', 'Contact on a Key Account account', 'New', 'Account from KA-03', "1. Create a Contact on the KA-03 account (leave Sales Channel blank).`n2. Save; check Sales Channel, Cluster and the Contact Team related list.", 'Contact Sales Channel = Key Account (inherited from account). Cluster = Cluster 1. Contact Team = Cluster 1 Contact members.', 'P2'),
  @('KA-09', 'Cluster + Team', 'Changing Sales Channel to Key Account re-assigns cluster and team', 'New', 'QA TEST account with Sales Channel = Specialty, Sector = Sellgoodr USA (Cluster 6)', "1. Note the Cluster (6) and Account Team.`n2. Edit: Sales Channel = Key Account, Sector = Enterprise. Save and refresh.`n3. Check Cluster, Account Team and any open Opportunity on the account.", 'Cluster changes to Cluster 1. Account Team replaced by Cluster 1 members. Open Opportunities show Sales Channel = Key Account and Cluster 1.', 'P2'),
  @('KA-10', 'Lead Conversion', 'Convert a Key Account lead', 'New', 'Lead from KA-05 (Status = Qualified)', "1. Click Convert on the KA-05 lead.`n2. Complete the conversion.`n3. Open the new Account and Contact.", 'Conversion succeeds. Account and Contact Sales Channel = Key Account, Sector = Strategic.', 'P2')
 )
 'B. SECTOR (new values added next to old values)' = @(
  @('SEC-01', 'Picklist', 'Sector options per Sales Channel', 'New + Old', 'Any Account (Company)', "1. Edit an Account.`n2. Set Sales Channel = Specialty; open Sector.`n3. Set Sales Channel = Global; open Sector.`n4. Set Sales Channel = Partnerships; open Sector.", 'Specialty: Planned, Self Service (new) + Sellgoodr USA, Bridge (old). Global: Distributor (new) + Global (old). Partnerships: Partnerships.', 'P1'),
  @('SEC-02', 'Cluster + LRP', 'Specialty + Self Service', 'New', 'QA TEST Self Service; Sales Channel = Specialty; Sector = Self Service', "1. $acc and save; refresh.`n2. Check Cluster and Account Team.`n3. Details tab: check sections.", 'Cluster = Cluster 6; Account Team = Cluster 6 members. Section "Specialty - Sellgoodr" visible; "Specialty - Bridge" NOT visible.', 'P1'),
  @('SEC-03', 'Cluster + LRP', 'Specialty + Planned', 'New', 'QA TEST Planned; Sales Channel = Specialty; Sector = Planned', "1. $acc and save; refresh.`n2. Check Cluster and Account Team.`n3. Details tab: check sections.", 'Cluster = Cluster 5; Account Team = Cluster 5 members. Section "Specialty - Bridge" visible; "Specialty - Sellgoodr" NOT visible.', 'P1'),
  @('SEC-04', 'Regression', 'Specialty + Sellgoodr USA (old value)', 'Old', 'QA TEST Sellgoodr USA; Sales Channel = Specialty; Sector = Sellgoodr USA', "1. $acc and save; refresh.`n2. Check Cluster, Account Team, sections.", 'Same as SEC-02: Cluster 6, Cluster 6 team, "Specialty - Sellgoodr" visible.', 'P1'),
  @('SEC-05', 'Regression', 'Specialty + Bridge (old value)', 'Old', 'QA TEST Bridge; Sales Channel = Specialty; Sector = Bridge', "1. $acc and save; refresh.`n2. Check Cluster, Account Team, sections.", 'Same as SEC-03: Cluster 5, Cluster 5 team, "Specialty - Bridge" visible.', 'P1'),
  @('SEC-06', 'Lead', 'Lead Specialty + Self Service', 'New', 'QA TEST lead; Sales Channel = Specialty; Sector = Self Service', "1. Create the lead and save.`n2. Check Cluster and Lead Team.`n3. Details tab sections.`n4. Set Status = Qualified; check Convert button.", 'Cluster 6; Lead Team = Cluster 6 Lead members; "Specialty - Sellgoodr" visible; Convert button NOT visible (Specialty leads use the approval process).', 'P1'),
  @('SEC-07', 'Lead', 'Lead Specialty + Planned', 'New', 'QA TEST lead; Sales Channel = Specialty; Sector = Planned', "Same steps as SEC-06.", 'Cluster 5; Lead Team = Cluster 5 Lead members; "Specialty - Bridge" visible; Convert button NOT visible.', 'P1'),
  @('SEC-08', 'Cluster', 'Key Account with each new Sector', 'New', '3 QA TEST accounts: Key Account + Strategic / Development / Discount', "1. Create each account; refresh.`n2. Check Cluster and section.", 'All three: Cluster 1, "Key Account" section visible.', 'P2'),
  @('SEC-09', 'Cluster + LRP', 'Global + Distributor', 'New', 'QA TEST Distributor; Sales Channel = Global; Sector = Distributor', "1. $acc; refresh.`n2. Check Cluster, Account Team, section.", 'Cluster 7; Cluster 7 team; section "Global" visible. Same result as Global + Global (old).', 'P2'),
  @('SEC-10', 'Behaviour', 'Changing only the Sector does not change the cluster', 'New', 'Account from SEC-04 (Specialty + Sellgoodr USA, Cluster 6)', "1. Edit: change Sector to Self Service only. Save; refresh.`n2. Check Cluster and sections.", 'Cluster stays Cluster 6 (expected - cluster recalculates only on Sales Channel change; mapping keeps the same cluster anyway). Section "Specialty - Sellgoodr" still visible.', 'P2'),
  @('SEC-11', 'Behaviour', 'Changing Sector Bridge -> Planned keeps the Bridge section', 'New', 'Account from SEC-05', "1. Edit: Sector = Planned. Save; refresh.`n2. Check sections and Cluster.", '"Specialty - Bridge" still visible; Cluster stays Cluster 5.', 'P2'),
  @('SEC-12', 'Opportunity', 'Opportunity copies new Sector', 'New', 'Account from SEC-03 (Specialty + Planned)', "1. Create an Opportunity on the account.`n2. Check Sales Channel, Sector, Cluster and Opportunity Team.", 'Opportunity: Specialty / Planned / Cluster 5; Opportunity Team = Cluster 5 members.', 'P2'),
  @('SEC-13', 'Lead Conversion', 'Convert a Specialty + Self Service lead (approval flow)', 'New', 'Lead from SEC-06', "1. Complete the normal Specialty approval / conversion process used for Specialty leads.`n2. Open the created Account and Contact.", 'Account and Contact Sector = Self Service, Sales Channel = Specialty, Cluster 6.', 'P3'),
  @('SEC-14', 'Regression', 'Specialty with blank Sector', 'Old', 'QA TEST; Sales Channel = Specialty; Sector blank', "1. $acc; refresh.`n2. Check Cluster and sections.", 'Cluster stays blank (existing behaviour - no rule for blank Sector). Section "Specialty - Sellgoodr" visible.', 'P3')
 )
 'C. SPECIALTY CAN (Canada leads now Specialty; old Specialty CAN still works)' = @(
  @('CAN-01', 'Flow', 'Canada retailer Typeform creates a Specialty lead', 'New', 'Canada retailer Typeform (form ZpuPvJtA) connected to the sandbox. NOTE: no Typeform form records exist in the sandbox today - mark Blocked if Typeform cannot be submitted; developers verified this in an automated test.', "1. Submit the Canada retailer Typeform.`n2. Open the new lead.", 'Sales Channel = Specialty (NOT Specialty CAN). Owner = queue "Lead Retailers Canada". "Under Review" email sent from retailsupportb2b@goodr.com. Uploaded files attached.', 'P1'),
  @('CAN-02', 'Flow', 'US retailer Typeform unchanged', 'Old', 'US retailer Typeform (form S0t1jVLc). Same note as CAN-01.', "1. Submit the US retailer Typeform.`n2. Open the new lead.", 'Sales Channel = Specialty. Owner = queue "Lead Retailers US". Email sent.', 'P1'),
  @('CAN-03', 'Regression', 'Specialty CAN + Sellgoodr CAN still works', 'Old', 'QA TEST CAN; Sales Channel = Specialty CAN; Sector = Sellgoodr CAN', "1. $acc; refresh.`n2. Check Cluster, Account Team, sections.", 'Cluster 6; Cluster 6 team; "Specialty - Sellgoodr" visible.', 'P1'),
  @('CAN-04', 'Regression', 'Specialty CAN + Bridge still works', 'Old', 'QA TEST CAN Bridge; Sales Channel = Specialty CAN; Sector = Bridge', "1. $acc; refresh.`n2. Check Cluster, Account Team, sections.", 'Cluster 5; Cluster 5 team; "Specialty - Bridge" visible.', 'P1'),
  @('CAN-05', 'New mapping', 'Canadian account on the new values gives the same result', 'New', 'QA TEST Canada; Sales Channel = Specialty; Sector = Self Service; Billing Country = Canada', "1. $acc; refresh.`n2. Check Cluster, Account Team, sections.`n3. Compare with CAN-03.", 'Same as CAN-03: Cluster 6, Cluster 6 team, "Specialty - Sellgoodr" visible.', 'P1'),
  @('CAN-06', 'Lead', 'Convert button hidden for Specialty CAN and Specialty leads', 'Old + New', 'Two QA TEST leads: Sales Channel = Specialty CAN and Specialty; Status = Qualified', "1. Open each lead.`n2. Check the buttons at the top.", 'Convert button NOT visible on either lead (Approve / Reject per status as today).', 'P2'),
  @('CAN-07', 'Report', 'Shopify CAN reports include Specialty CAN and Canadian Specialty accounts', 'Old + New', 'Reports folder "Cluster 3": "Shopify Accounts CAN/Source - Cluster 3", "Shopify Accounts Created CAN - Cluster 3"', "1. Open each report and click Edit / Filters.`n2. Check the filter logic.`n3. Run the report.", 'Filters: Sales Channel = Specialty CAN OR (Sales Channel = Specialty AND Billing Country = Canada). Existing rows still shown. (Created CAN report also filters Created Date = last + this month, so it may return 0 rows - expected.)', 'P2'),
  @('CAN-08', 'Shopify', 'Canadian Shopify routing unchanged', 'Old', 'Existing Specialty CAN store location with Shipping Country = Canada and a Shopify Id', "1. Click the Shopify Sync button on the account (if available to QA).`n2. Check the result message / Shopify Sync log.", 'Sync uses the Canada Shopify store (routing is by country). No error about Sales Channel.', 'P3')
 )
 'D. GENERAL REGRESSION' = @(
  @('REG-01', 'Regression', 'Partnerships account', 'Old', 'QA TEST; Sales Channel = Partnerships; Sector = Partnerships', "1. $acc; refresh.`n2. Check Cluster, Account Team, section.", 'Cluster 8; Cluster 8 team; "Partnership" section visible.', 'P2'),
  @('REG-02', 'Regression', 'Global + Global (old value)', 'Old', 'QA TEST; Sales Channel = Global; Sector = Global', "1. $acc; refresh.", 'Cluster 7; Cluster 7 team; "Global" section visible.', 'P2'),
  @('REG-03', 'Regression', 'Store Location and Franchise pages show Sector values', 'Old + New', 'Existing Store Location and Franchise accounts', "1. Open a Store Location account and a Franchise account.`n2. Edit Sector to a new value (e.g. Self Service) and save.", 'Field saves and displays the new value; no error; page layout unchanged.', 'P3'),
  @('REG-04', 'Regression', 'Contact and Opportunity pages show Sales Channel / Sector', 'Old + New', 'Any Contact / Opportunity', "1. Open a Contact and an Opportunity.`n2. Check Sales Channel / Sector display.", 'Values display correctly (Key Account, new Sectors); no page errors.', 'P3')
 )
}
$r = 5
foreach ($sec in $tc.Keys) {
  Band $ws $r $cols.Count $sec; $r++
  foreach ($t in $tc[$sec]) { for ($c = 0; $c -lt $t.Count; $c++) { Put-Cell $ws $r ($c + 1) $t[$c] }; Put-Cell $ws $r 10 'Not Run'
    $p = $ws.Cells.Item($r, 8); $p.HorizontalAlignment = -4108; if ($t[7] -eq 'P1') { $p.Interior.Color = $pink } elseif ($t[7] -eq 'P2') { $p.Interior.Color = $yellow } else { $p.Interior.Color = $grey }
    $v = $ws.Cells.Item($r, 4); if ($t[3] -like 'New*') { $v.Interior.Color = $green } elseif ($t[3] -like 'Old*') { $v.Interior.Color = $blue }
    $r++ }
}
$last = $r - 1
Fmt $ws "A4" "M$last"; $ws.Range("A4", "M4").VerticalAlignment = -4108
$ws.Range("I5", "M$last").Interior.Color = $yellow
for ($i = 5; $i -le $last; $i++) { if ($ws.Cells.Item($i, 2).Text -eq '' -and $ws.Cells.Item($i, 1).Text -ne '') { $ws.Range("A$i", "M$i").Interior.Color = $band } }
$dv = $ws.Range("J5", "J$last").Validation; $dv.Delete(); $dv.Add(3, 1, 1, 'Not Run,Pass,Fail,Blocked')
$ws.Activate(); $xl.ActiveWindow.SplitRow = 4; $xl.ActiveWindow.SplitColumn = 3; $xl.ActiveWindow.FreezePanes = $true
$tcLast = $last
# summary counters
Put-Cell $ws 2 9 'Summary:'; $ws.Cells.Item(2, 9).Font.Bold = $true
$k = 10; foreach ($st in 'Pass','Fail','Blocked','Not Run') { $ws.Cells.Item(1, $k).Formula = $st; $ws.Cells.Item(1, $k).Font.Bold = $true; $ws.Cells.Item(2, $k).Formula = "=COUNTIF(`$J`$5:`$J`$$tcLast,""$st"")"; $k++ }

# ================================================================ Expected Results Matrix
$ws = $wb.Worksheets.Item('Expected Results Matrix')
Title $ws 'Expected results by Sales Channel + Sector (Account Company page and Lead page)' 'Rows in the same colour band are an OLD value and the NEW value that replaces it - they must give identical results.'
Head $ws 4 @('Sales Channel', 'Sector', 'Old / New', 'Cluster', 'Team (see Expected Team Members)', 'Section visible on Account (Company) + Lead page', 'Lead Convert button (Status = Qualified)', 'Replaces / same as') @(16, 16, 10, 11, 26, 34, 22, 30)
$mx = @(
 @('Specialty', 'Sellgoodr USA', 'Old', 'Cluster 6', 'Cluster 6 members', 'Specialty - Sellgoodr', 'Hidden', ''),
 @('Specialty', 'Self Service', 'New', 'Cluster 6', 'Cluster 6 members', 'Specialty - Sellgoodr', 'Hidden', 'Replaces Sellgoodr USA / Sellgoodr CAN'),
 @('Specialty CAN', 'Sellgoodr CAN', 'Old', 'Cluster 6', 'Cluster 6 members', 'Specialty - Sellgoodr', 'Hidden', 'Future: Specialty + Self Service'),
 @('Specialty', 'Bridge', 'Old', 'Cluster 5', 'Cluster 5 members', 'Specialty - Bridge', 'Hidden', ''),
 @('Specialty', 'Planned', 'New', 'Cluster 5', 'Cluster 5 members', 'Specialty - Bridge', 'Hidden', 'Replaces Bridge'),
 @('Specialty CAN', 'Bridge', 'Old', 'Cluster 5', 'Cluster 5 members', 'Specialty - Bridge', 'Hidden', 'Future: Specialty + Planned'),
 @('Specialty / Specialty CAN', '(blank)', 'Old', '(blank)', 'none', 'Specialty - Sellgoodr', 'Hidden', 'Existing behaviour'),
 @('Key Account', 'Core / Mid-Market / Off-Price', 'Old', 'Cluster 1', 'Cluster 1 members', 'Key Account', 'Visible', ''),
 @('Key Account', 'Enterprise / Strategic / Development / Discount', 'New', 'Cluster 1', 'Cluster 1 members', 'Key Account', 'Visible', 'Replaces Core / Mid-Market / Off-Price'),
 @('Global', 'Global', 'Old', 'Cluster 7', 'Cluster 7 members', 'Global', 'Visible', ''),
 @('Global', 'Distributor', 'New', 'Cluster 7', 'Cluster 7 members', 'Global', 'Visible', 'Replaces Global'),
 @('Partnerships', 'Partnerships', 'Old (unchanged)', 'Cluster 8', 'Cluster 8 members', 'Partnership', 'Visible', '')
)
$r = 5; $bands = @($blue, $blue, $blue, $green, $green, $green, $grey, $yellow, $yellow, $blue, $blue, $grey)
for ($j = 0; $j -lt $mx.Count; $j++) { for ($c = 0; $c -lt 8; $c++) { Put-Cell $ws $r ($c + 1) $mx[$j][$c] }; $ws.Range("A$r", "H$r").Interior.Color = $bands[$j]; $r++ }
Fmt $ws "A4" "H$($r-1)"
Put-Cell $ws ($r + 1) 1 'Note: Key Account clusters 1-4 exist in the team setup; new Key Account records are assigned Cluster 1 by the rules (same as before the rename).'
$ws.Cells.Item($r + 1, 1).Font.Italic = $true

# ================================================================ Expected Team Members
$ws = $wb.Worksheets.Item('Expected Team Members')
Title $ws 'Expected team members per cluster (sandbox users)' 'A user holding two roles appears ONCE in the team related list - compare the distinct users. Source: Account_Cluster_Team custom metadata in GDRSAND.'
Head $ws 4 @('Cluster', 'Object (related list)', 'Distinct users expected', 'Team Role', 'User (sandbox username)') @(11, 30, 12, 28, 46)
$team = Import-Csv "$sp\team_setup.csv"
$rl = @{ Account = 'Account (Account Team)'; Lead = 'Lead (Lead Team)'; Contact = 'Contact (Contact Team)'; Opportunity = 'Opportunity (Opportunity Team)'; Case = 'Case' }
$r = 5
foreach ($g in ($team | ? { $_.ObjectAPIName__c -ne 'Case' } | Group-Object Cluster_Value__c, ObjectAPIName__c | Sort-Object { $_.Group[0].Cluster_Value__c }, { @('Account','Lead','Contact','Opportunity').IndexOf($_.Group[0].ObjectAPIName__c) })) {
  $first = $true; $distinct = @($g.Group.User_Identifier__c | Select -Unique).Count
  foreach ($m in ($g.Group | Sort-Object Team_Role__c)) { if ($first) { Put-Cell $ws $r 1 $m.Cluster_Value__c; Put-Cell $ws $r 2 $rl[$m.ObjectAPIName__c]; Put-Cell $ws $r 3 $distinct; $ws.Range("A$r", "E$r").Borders.Item(8).Weight = -4138 }; Put-Cell $ws $r 4 $m.Team_Role__c; Put-Cell $ws $r 5 $m.User_Identifier__c; $first = $false; $r++ }
}
Fmt $ws "A4" "E$($r-1)"; $ws.Range("C5", "C$r").HorizontalAlignment = -4108
$ws.Range("A4", "E$($r-1)").AutoFilter() | Out-Null
$ws.Activate(); $xl.ActiveWindow.SplitRow = 4; $xl.ActiveWindow.FreezePanes = $true

# ================================================================ Known Issues
$ws = $wb.Worksheets.Item('Known Issues')
Title $ws 'Known issues - do NOT log these as new defects' 'Found during developer testing on 8 Oct 2026. None is caused by the Key Account / Sector / Specialty CAN deployments.'
Head $ws 4 @('#', 'Issue', 'What QA will see', 'Cause', 'Status / Plan') @(5, 34, 46, 50, 36)
$ki = @(
 @('1', 'Report "Accounts without NetSuite Id" (Public Reports) and its dashboard', 'Report shows no Key Account accounts', 'Renaming Key Accounts -> Key Account in Setup removed "Key Accounts" from the report filter (Salesforce behaviour).', 'Fix pending: filter to "Key Account, Key Account CAN".'),
 @('2', 'Opportunity on a Specialty CAN account (sandbox only)', 'Saving a new Opportunity on a Specialty CAN account fails: "bad value for restricted picklist field: Specialty CAN"', 'Sandbox Opportunity record types do not include Specialty CAN (existing sandbox config; Production includes it).', 'Sandbox-only. Skip for Specialty CAN accounts.'),
 @('3', 'Specialty + Sellgoodr CAN (invalid combination)', 'Record gets no Cluster', 'No cluster rule has ever covered this combination (existing behaviour).', 'Optional rule or data fix - client decision.'),
 @('4', 'Typeform forms not set up in sandbox', 'CAN-01 / CAN-02 cannot be executed through Typeform', 'No Typeform form records exist in GDRSAND.', 'Mark Blocked; flow verified by developers in an automated rollback test.'),
 @('5', 'Cluster not recalculated when only Sector changes', 'Cluster stays the same after editing only the Sector', 'Existing design: cluster recalculates on create or Sales Channel change.', 'Expected behaviour (SEC-10).')
)
$r = 5; foreach ($x in $ki) { for ($c = 0; $c -lt 5; $c++) { Put-Cell $ws $r ($c + 1) $x[$c] }; $r++ }; Fmt $ws "A4" "E$($r-1)"

# ================================================================ Defect Log
$ws = $wb.Worksheets.Item('Defect Log')
Title $ws 'Defect Log' 'One row per defect. Put the Defect ID in the Test Cases sheet.'
Head $ws 4 @('Defect ID', 'TC ID', 'Summary', 'Steps to Reproduce', 'Expected', 'Actual', 'Record Link / ID', 'Screenshot', 'Severity', 'Raised By', 'Date', 'Status', 'Developer Comments') @(10, 9, 32, 40, 30, 30, 26, 14, 10, 14, 11, 12, 30)
Put-Cell $ws 5 1 'DEF-001'; Put-Cell $ws 5 2 '(example)'; Put-Cell $ws 5 3 'Example: Cluster blank on Specialty + Planned account'; Put-Cell $ws 5 9 'High'; Put-Cell $ws 5 12 'Open'
$ws.Range("A5", "M5").Font.Italic = $true; $ws.Range("A5", "M5").Font.Color = (RGB 128 128 128)
Fmt $ws "A4" "M30"
$sv = $ws.Range("I5", "I30").Validation; $sv.Delete(); $sv.Add(3, 1, 1, 'Critical,High,Medium,Low')
$st = $ws.Range("L5", "L30").Validation; $st.Delete(); $st.Add(3, 1, 1, 'Open,In Progress,Fixed,Retest,Closed,Rejected')

foreach ($s in $wb.Worksheets) { $s.PageSetup.Orientation = 2; $s.PageSetup.Zoom = $false; $s.PageSetup.FitToPagesWide = 1; $s.PageSetup.FitToPagesTall = $false }
$wb.Worksheets.Item('Read Me').Activate(); $xl.ScreenUpdating = $true; $xl.CalculateFull()
if (Test-Path $out) { Remove-Item $out -Force -Confirm:$false }
$wb.SaveAs($out, 51)
$t = $wb.Worksheets.Item('Test Cases'); $n = 0; for ($i = 5; $i -le $tcLast; $i++) { if ($t.Cells.Item($i, 2).Text) { $n++ } }; "test cases: $n  (Not Run counter: $($t.Cells.Item(2,13).Text))"
"team rows: $($wb.Worksheets.Item('Expected Team Members').UsedRange.Rows.Count - 4)"
$wb.Close($false); $xl.Quit(); [Runtime.InteropServices.Marshal]::ReleaseComObject($xl) | Out-Null
"Saved $out"
