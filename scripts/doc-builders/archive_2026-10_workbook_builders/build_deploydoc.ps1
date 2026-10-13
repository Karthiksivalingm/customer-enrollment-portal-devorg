$ErrorActionPreference = 'Stop'
$repo = 'C:\Microsoft VS Code\GDRSandbox'
$pkg  = "$repo\deployment\KeyAccount_Rename_PROD"
$out  = "$repo\deployment\KeyAccount_Rename_Deployment_Document.xlsx"

function RGB($r, $g, $b) { return [int]($r + $g * 256 + $b * 65536) }
$green   = RGB 0 255 0
$lgreen  = RGB 198 239 206
$yellow  = RGB 255 242 204
$band    = RGB 182 215 168
$pink    = RGB 244 204 204
$grey    = RGB 217 217 217
$hdrFill = RGB 255 255 255

$xl = New-Object -ComObject Excel.Application
$xl.Visible = $false; $xl.DisplayAlerts = $false; $xl.ScreenUpdating = $false
$wb = $xl.Workbooks.Add()
$names = 'Deployment Document', 'Deployment Steps', 'Test Plan', 'Team Records (100)', 'Sandbox vs Prod', 'package.xml'
while ($wb.Worksheets.Count -lt $names.Count) { [void]$wb.Worksheets.Add([Type]::Missing, $wb.Worksheets.Item($wb.Worksheets.Count)) }
for ($i = 1; $i -le $names.Count; $i++) { $wb.Worksheets.Item($i).Name = $names[$i - 1] }

function Set-Cell($ws, $r, $c, $v) { if ($null -ne $v -and "$v" -ne '') { $s = [string]$v; if ($s -match '^[=+\-@]') { $s = "'" + $s }; $ws.Cells.Item($r, $c).Formula = $s } }
function Header($ws, $r, $cols, $widths) {
    for ($c = 0; $c -lt $cols.Count; $c++) { Set-Cell $ws $r ($c + 1) $cols[$c]; if ($widths) { $ws.Columns.Item($c + 1).ColumnWidth = $widths[$c] } }
    $rg = $ws.Range($ws.Cells.Item($r, 1), $ws.Cells.Item($r, $cols.Count)); $rg.Font.Bold = $true; $rg.HorizontalAlignment = -4108
    $rg.Borders.Item(9).Weight = -4138; $rg.Borders.Item(9).LineStyle = 1
}
function Band($ws, $r, $ncol, $text) {
    $rg = $ws.Range($ws.Cells.Item($r, 1), $ws.Cells.Item($r, $ncol)); $rg.Interior.Color = $band
    $ws.Cells.Item($r, 1).Interior.ColorIndex = -4142
    $m = $ws.Range($ws.Cells.Item($r, 2), $ws.Cells.Item($r, $ncol)); $m.Merge(); Set-Cell $ws $r 2 $text; $m.Font.Bold = $true; $m.HorizontalAlignment = -4108
}
function Row($ws, $r, $vals) { for ($c = 0; $c -lt $vals.Count; $c++) { Set-Cell $ws $r ($c + 1) $vals[$c] } }

# ================================================================ Deployment Document (same layout as the GoodR sheet)
$ws = $wb.Worksheets.Item('Deployment Document')
$cols = 'Component Name', 'Description', 'Test Class', 'Component Type', 'Status', 'Deployment Status', 'Parent Object', 'Change (Before -> After)', 'Comments (why it was updated / impact)', 'Sandbox Deploy ID'
Header $ws 1 $cols @(40, 46, 30, 22, 20, 22, 16, 40, 70, 22)
$r = 3
$ws.Cells.Item(2, 1).Formula = 'Change 1: Sales Channel value "Key Accounts" renamed to "Key Account" (package deployment/KeyAccount_Rename_PROD). Change 2: Sector - new values added next to old values in config (Sellgoodr USA -> Self Service, Bridge -> Planned) (package deployment/Sector_NewValues_PROD, deploy AFTER Change 1). Change 3: Specialty CAN Phase 1 - flow, 2 test classes, 2 reports (package deployment/SpecialtyCAN_Phase1_PROD, deploy AFTER Change 1). Sandbox: GDRSAND (partial). Production: GDRPROD. Packages built from PRODUCTION versions. Updated 6 Oct 2026.'
$ws.Range("A2:J2").Merge(); $ws.Cells.Item(2, 1).Font.Italic = $true; $ws.Cells.Item(2, 1).WrapText = $true; $ws.Rows.Item(2).RowHeight = 45

$sections = @(
  @{ Title = 'Pre-Deployment Manual Steps (Production - Setup, not in package)'; Rows = @(
    @('Sales Channel (Global Value Set: Sales_Channel)', 'Rename picklist value "Key Accounts" to "Key Account" (Label AND API Name). Setup > Picklist Value Sets > Sales Channel > Edit.', 'n/a', 'Global Value Set (manual)', 'Done in Sandbox (manual)', 'Pending - Production', 'Account, Contact, Opportunity', 'Key Accounts -> Key Account', 'Business renamed the channel. Editing the value in Setup updates every existing record, record type picklist and Sector field dependency automatically (verified in sandbox: 42 Accounts, 12 Contacts, 5 Opportunities show Key Account; record types and dependency updated). Do this immediately before the package deploy - the package and tests expect the new value.', 'Manual - no ID'),
    @('Lead.Sales_Channel__c (LOCAL picklist in Production)', 'Rename value "Key Accounts" to "Key Account" (Label AND API Name). Object Manager > Lead > Fields > Sales Channel > Edit value.', 'n/a', 'Picklist value (manual)', 'Done in Sandbox (via Sales_Channel1)', 'Pending - Production', 'Lead', 'Key Accounts -> Key Account', 'In PRODUCTION the Lead field uses its own local value list (Specialty, Specialty CAN, Key Accounts, Partnerships, Global); in the sandbox it uses the Sales_Channel1 value set. It must match the Account/Contact value or Lead conversion fails on the restricted picklist (LeadConversionService copies the value).', 'Manual - no ID'),
    @('Verify record types and Sector dependency', 'Account record types Company, Franchise, Store_Location and Opportunity record types Key_Account, Partnerships, Specialty show "Key Account"; Sector field dependency shows "Key Account" as controlling value.', 'n/a', 'Verification', 'Verified in Sandbox', 'Pending - Production', 'Account, Opportunity', 'auto-updated by rename', 'No deploy needed - Salesforce updates these when the value is renamed in Setup. Verify only.', '')
  ) },
  @{ Title = 'Key Account Rename - Cluster Rules (Custom Metadata: Sales_Channel_Cluster__mdt)'; Rows = @(
    @('Sales_Channel_Cluster.Keys_Account_Account', 'Cluster rule for Account: Sales Channel Key Account -> Cluster 1', 'ClusterRuleEngineTest, ClusterTriggerTest', 'Custom Metadata Record', 'Deployed to Sandbox', 'Ready for Production', 'Account', "Rule_Condition__c: Sales_Channel__c = 'Key Accounts' -> 'Key Account'", 'ClusterRuleEngine compares the record value with this text. After the rename no record has "Key Accounts", so new Key Account accounts got NO cluster and NO team. Updating the text restores Cluster 1 assignment. Cluster value unchanged.', '0Afdx00000GAgZSCA1'),
    @('Sales_Channel_Cluster.Key_Account_Lead', 'Cluster rule for Lead: Key Account -> Cluster 1', 'ClusterTriggerTest', 'Custom Metadata Record', 'Deployed to Sandbox', 'Ready for Production', 'Lead', "'Key Accounts' -> 'Key Account'", 'Same as above - restores Cluster 1 for new / channel-changed Key Account leads (LeadClusterTrigger).', '0Afdx00000GAgZSCA1'),
    @('Sales_Channel_Cluster.Key_Account_Opp', 'Cluster rule for Opportunity: Key Account -> Cluster 1', 'ClusterTriggerTest', 'Custom Metadata Record', 'Deployed to Sandbox', 'Ready for Production', 'Opportunity', "'Key Accounts' -> 'Key Account'", 'Same as above - restores Cluster 1 for Key Account opportunities (OpportunityClusterTrigger).', '0Afdx00000GAgZSCA1'),
    @('Sales_Channel_Cluster.Key_Account_Contact', 'Cluster rule for Contact: Key Account -> Cluster 1', 'n/a', 'Custom Metadata Record', 'Deployed to Sandbox', 'Ready for Production', 'Contact', "'Key Accounts' -> 'Key Account'", 'Kept consistent with the other rules. ClusterRuleEngine skips Contact (Contact.Cluster__c is a formula from the Account), so no runtime impact.', '0Afdx00000GAgZSCA1')
  ) },
  @{ Title = 'Key Account Rename - Lightning Record Pages'; Rows = @(
    @('Account_Company_Record_Page', 'Section "Key Account" visibility filter (Details tab). Shows Target IMU, EDI, Custom Tagging, Co-Op, New Store Discount Allowance.', 'n/a', 'Lightning Page (FlexiPage)', 'Deployed to Sandbox', 'Ready for Production', 'Account', 'Filter: Sales_Channel__c EQUAL Key Accounts -> Key Account', 'After the rename the filter matched no record, so the Key Account section was hidden on every Key Account company. One-line change. PRODUCTION package uses the PRODUCTION version of this page (prod page differs from sandbox), so no other page change is carried over.', '0Afdx00000GAi4zCAD'),
    @('Lead_Record_Page', 'Section "Key Account" visibility filter (Details > Fields accordion). Shows Tax ID, Operating Model, Total Doors, Target IMU and other fields.', 'n/a', 'Lightning Page (FlexiPage)', 'Deployed to Sandbox', 'Ready for Production', 'Lead', 'Filter: Sales_Channel__c EQUAL Key Accounts -> Key Account', 'Same as above for Key Account leads. Built from the PRODUCTION version of the page.', '0Afdx00000GAi4zCAD')
  ) },
  @{ Title = 'Key Account Rename - Cluster Team (Custom Metadata: Account_Cluster_Team__mdt)'; Rows = @(
    @('Account_Cluster_Team__mdt.Sales_Channel__c', 'Local picklist on the custom metadata type', 'n/a', 'Custom Field (CMDT picklist)', 'Deployed to Sandbox', 'Ready for Production', 'Account_Cluster_Team__mdt', 'Added value "Key Account" (Key Accounts kept)', 'Required so the 100 team records can hold "Key Account" (restricted picklist). The old value is kept (expand step) and can be removed later in a cleanup release. Must deploy in the same package as the records.', '0Afdx00000GAijJCAT'),
    @('Account_Cluster_Team records - 100 (Clusters 1-4)', 'Team member records for Key Account clusters (see sheet Team Records (100))', 'n/a', 'Custom Metadata Records', 'Deployed to Sandbox', 'Ready for Production', 'Account_Cluster_Team__mdt', 'Sales_Channel__c: Key Accounts -> Key Account', 'Consistency / reporting only: ClusterTeamEngine assigns team members by Cluster and Object (lines 27-35), not by this field, so team assignment is unchanged. PRODUCTION files keep PRODUCTION user identifiers (@goodr.com) - never deploy the sandbox copies (.partial users).', '0Afdx00000GAijJCAT')
  ) },
  @{ Title = 'Key Account Rename - Apex Test Classes'; Rows = @(
    @('ClusterTriggerTest', 'Tests Lead / Account / Opportunity cluster triggers', 'ClusterTriggerTest', 'Apex Class (Test)', 'Deployed to Sandbox', 'Ready for Production', 'Lead, Account, Opportunity', "9 lines: 'Key Accounts' -> 'Key Account' (test data + assertions)", 'Tests inserted Sales Channel = Key Accounts, which no longer exists -> INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST. Updated so the tests pass and production deployments are not blocked.', '0Afdx00000GAiL7CAL'),
    @('ClusterRuleEngineTest', 'Tests ClusterRuleEngine', 'ClusterRuleEngineTest', 'Apex Class (Test)', 'Deployed to Sandbox', 'Ready for Production', 'Account', '4 lines', 'Same reason - test data used the removed value.', '0Afdx00000GAiL7CAL'),
    @('ContactTriggerHandlerTest', 'Tests ContactTriggerHandler', 'ContactTriggerHandlerTest', 'Apex Class (Test)', 'Deployed to Sandbox', 'Ready for Production', 'Contact', '3 lines', 'Same reason - 36 test methods failed in sandbox because shared test data used Key Accounts.', '0Afdx00000GAiL7CAL'),
    @('LeadConversionHandlerTest1', 'Tests lead conversion (bulk / without opportunity)', 'LeadConversionHandlerTest1', 'Apex Class (Test)', 'Deployed to Sandbox', 'Ready for Production', 'Lead', '3 lines (incl. bulk channel list)', 'Same reason. Specialty CAN values in the same list intentionally unchanged.', '0Afdx00000GAiL7CAL'),
    @('LeadConversionHandlerTest', 'Tests LeadConversionHandler', 'LeadConversionHandlerTest', 'Apex Class (Test)', 'Deployed to Sandbox', 'Ready for Production', 'Lead', '1 line', 'Same reason.', '0Afdx00000GAiL7CAL'),
    @('AccountCascadeHandlerTest', 'Tests AccountCascadeHandler', 'AccountCascadeHandlerTest', 'Apex Class (Test)', 'Deployed to Sandbox', 'Ready for Production', 'Account', '1 line (old-value map)', 'Was still passing (in-memory value) - updated for consistency with the new value.', '0Afdx00000GAiL7CAL'),
    @('ShopifyAddressSyncTest', 'Tests Shopify address sync', 'ShopifyAddressSyncTest', 'Apex Class (Test)', 'Deployed to Sandbox', 'Ready for Production', 'Account', '1 line', 'Same reason - "no config for this channel" test used Key Accounts.', '0Afdx00000GAiL7CAL'),
    @('ShopifyOrderSyncTest', 'Tests Shopify order sync batch', 'ShopifyOrderSyncTest', 'Apex Class (Test)', 'Deployed to Sandbox', 'Ready for Production - see Test Plan', 'Account', '1 line', 'Same reason (testMissingConfig fixed). NOTE: 2 other methods (testNoAccountMatch_OrderSkipped, testNoOrdersToday) were already failing before this change (date assertion) - check in production before deploy.', '0Afdx00000GAiL7CAL'),
    @('ShopifySalesSyncServiceTest', 'Tests Shopify sales sync', 'ShopifySalesSyncServiceTest', 'Apex Class (Test)', 'Deployed to Sandbox', 'Ready for Production', 'Account', '1 line', 'Same reason.', '0Afdx00000GAiL7CAL')
  ) },
  @{ Title = 'SECTOR - Pre-Deployment Manual Steps (Production - Setup, not in package)'; Rows = @(
    @('Sector (Global Value Set: Sector)', 'Add 7 new values: Enterprise, Strategic, Development, Discount, Planned, Self Service, Distributor. Setup > Picklist Value Sets > Sector > New. Keep all old values active.', 'n/a', 'Global Value Set (manual)', 'Already in Sandbox', 'Pending - Production', 'Account, Contact, Lead, Opportunity', 'Add 7 values (old 8 kept)', 'PREREQUISITE. Production has only the 8 old Sector values (read-only check 6 Oct). The new cluster rules and page filters refer to Self Service / Planned, which must exist in Production for records to use them. Old values stay active because existing records still hold them (data migration is a separate step).', 'Manual - no ID'),
    @('Sector__c field dependency (Account, Contact, Lead, Opportunity)', 'Map the new values: Key Account -> Enterprise, Strategic, Development, Discount; Specialty -> Planned, Self Service; Global -> Distributor; Partnerships -> Partnerships. Object Manager > <Object> > Fields > Sector > Field Dependencies.', 'n/a', 'Field Dependency (manual)', 'Already in Sandbox', 'Pending - Production', 'Account, Contact, Lead, Opportunity', 'New values mapped under their Sales Channel', 'PREREQUISITE. Sector__c is controlled by Sales Channel; without the mapping users cannot select the new values. Do this AFTER the Key Account rename (Key Account must exist as controlling value). Keep existing old-value mappings.', 'Manual - no ID'),
    @('Record types - Sector values', 'Enable the 7 new Sector values on Account record types (Company, Franchise, Store_Location) and Opportunity record types (Key_Account, Partnerships, Specialty).', 'n/a', 'Record Type (manual)', 'Already in Sandbox', 'Pending - Production', 'Account, Opportunity', 'Enable 7 values', 'PREREQUISITE (UI only). Record types restrict which values users can pick on the page.', 'Manual - no ID')
  ) },
  @{ Title = 'SECTOR - Cluster Rules (Custom Metadata: Sales_Channel_Cluster__mdt) - NEW records, old rules kept'; Rows = @(
    @('Sales_Channel_Cluster.Specialty_Self_Service_Account', 'NEW cluster rule for Account: Specialty + Self Service -> Cluster 6 (copy of SpeciaSpecialtylity)', 'ClusterRuleEngineTest, ClusterTriggerTest (no change)', 'Custom Metadata Record (new)', 'Deployed to Sandbox', 'Ready for Production', 'Account', "New: Sales_Channel__c = 'Specialty' && Sector__c = 'Self Service'", 'Mapping Sellgoodr USA -> Self Service. Added NEXT TO the existing Sellgoodr USA rule so records with the old value keep Cluster 6 and records with the new value also get Cluster 6. Before this, a Self Service record got no cluster and no team. No code change - ClusterRuleEngine reads the condition text.', '0Afdx00000GAl4TCAT'),
    @('Sales_Channel_Cluster.Specialty_Self_Service_Lead', 'NEW rule for Lead: Specialty + Self Service -> Cluster 6 (copy of Specialty_Lead)', 'ClusterTriggerTest (no change)', 'Custom Metadata Record (new)', 'Deployed to Sandbox', 'Ready for Production', 'Lead', "New: ... Sector__c = 'Self Service'", 'Same as above for Leads (LeadClusterTrigger).', '0Afdx00000GAl4TCAT'),
    @('Sales_Channel_Cluster.Specialty_Self_Service_Opp', 'NEW rule for Opportunity: Specialty + Self Service -> Cluster 6 (copy of Specialty_Opp)', 'ClusterTriggerTest (no change)', 'Custom Metadata Record (new)', 'Deployed to Sandbox', 'Ready for Production', 'Opportunity', "New: ... Sector__c = 'Self Service'", 'Same as above for Opportunities (OpportunityClusterTrigger).', '0Afdx00000GAl4TCAT'),
    @('Sales_Channel_Cluster.Specialty_Self_Service_Contact', 'NEW rule for Contact (copy of Specialty_Contact)', 'n/a', 'Custom Metadata Record (new)', 'Deployed to Sandbox', 'Ready for Production', 'Contact', "New: ... Sector__c = 'Self Service'", 'Mirrors the existing rule set. ClusterRuleEngine skips Contact (Cluster is a formula from Account) - no runtime impact.', '0Afdx00000GAl4TCAT'),
    @('Sales_Channel_Cluster.Specialty_Planned_Account', 'NEW rule for Account: Specialty + Planned -> Cluster 5 (copy of Specialty_Bridge_Account)', 'ClusterRuleEngineTest, ClusterTriggerTest (no change)', 'Custom Metadata Record (new)', 'Deployed to Sandbox', 'Ready for Production', 'Account', "New: Sales_Channel__c = 'Specialty' && Sector__c = 'Planned'", 'Mapping Bridge -> Planned. Added next to the existing Bridge rule; both give Cluster 5. Before this, a Planned record got no cluster and no team.', '0Afdx00000GAl4TCAT'),
    @('Sales_Channel_Cluster.Specialty_Planned_Lead', 'NEW rule for Lead: Specialty + Planned -> Cluster 5', 'ClusterTriggerTest (no change)', 'Custom Metadata Record (new)', 'Deployed to Sandbox', 'Ready for Production', 'Lead', "New: ... Sector__c = 'Planned'", 'Same as above for Leads.', '0Afdx00000GAl4TCAT'),
    @('Sales_Channel_Cluster.Specialty_Planned_Opp', 'NEW rule for Opportunity: Specialty + Planned -> Cluster 5', 'ClusterTriggerTest (no change)', 'Custom Metadata Record (new)', 'Deployed to Sandbox', 'Ready for Production', 'Opportunity', "New: ... Sector__c = 'Planned'", 'Same as above for Opportunities.', '0Afdx00000GAl4TCAT'),
    @('Sales_Channel_Cluster.Specialty_Planned_Contact', 'NEW rule for Contact (copy of Specialty_Bridge_Contact)', 'n/a', 'Custom Metadata Record (new)', 'Deployed to Sandbox', 'Ready for Production', 'Contact', "New: ... Sector__c = 'Planned'", 'Mirrors the existing rule set; not evaluated at runtime.', '0Afdx00000GAl4TCAT')
  ) },
  @{ Title = 'SECTOR - Lightning Record Pages (same 2 pages as Key Account - deploy this version AFTER the Key Account package)'; Rows = @(
    @('Account_Company_Record_Page', 'Section "Specialty - Sellgoodr": added criterion 4 Sector <> Planned, logic (1 OR 3) AND 2 AND 4. Section "Specialty - Bridge": added criterion 4 Sector = Planned, logic (1 OR 3) AND (2 OR 4).', 'n/a', 'Lightning Page (FlexiPage)', 'Deployed to Sandbox', 'Ready for Production', 'Account', 'Bridge section: Sector = Bridge -> Bridge OR Planned; Sellgoodr section: excludes Bridge AND Planned', 'Mapping Bridge -> Planned. Without it a Planned account showed the Sellgoodr section and never the Bridge section. Old criteria kept, so every existing record shows exactly the same sections (verified for all combinations); only Specialty + Planned changes (now Bridge section). Package page = PRODUCTION page + Key Account fix + these criteria (cumulative).', '0Afdx00000GAp02CAD'),
    @('Lead_Record_Page', 'Same two section filters on the Lead page.', 'n/a', 'Lightning Page (FlexiPage)', 'Deployed to Sandbox', 'Ready for Production', 'Lead', 'Same as Account page', 'Same reason for Leads. Specialty CAN criterion (3) untouched.', '0Afdx00000GAp02CAD')
  ) },
  @{ Title = 'SECTOR - Not changed in config (data / later steps)'; Rows = @(
    @('Old-value cluster rules (8): SpeciaSpecialtylity, Specialty_Lead/Opp/Contact, Specialty_Bridge_Account/Lead/Opp/Contact', 'Existing Sellgoodr USA / Bridge rules', 'n/a', 'Custom Metadata Record', 'Kept - no change', 'n/a', 'All', 'none', 'Kept on purpose: Sector data is NOT migrated yet, records still hold old values. Remove in a cleanup release after the data migration.', ''),
    @('Core, Mid-Market, Off-Price, Global (Sector)', 'Mapped to Enterprise, Strategic/Development, Discount, Distributor', 'n/a', 'Data only', 'No config uses them', 'n/a', 'All', 'none', 'Not referenced in any Production/Sandbox config (flows, Apex, rules, pages, reports checked). Only record data - handled by the data migration. Mid-Market target (Strategic or Development) still to be decided.', ''),
    @('SpecialtyCAN_* cluster rules (Sellgoodr CAN, Bridge)', 'Specialty CAN rules', 'n/a', 'Custom Metadata Record', 'No change', 'n/a', 'All', 'none', 'Kept - Specialty CAN rules stay for existing records; see the SPECIALTY CAN section (old and new values both verified).', '')
  ) },
  @{ Title = 'SPECIALTY CAN - Phase 1 (old value kept, new value supported) - Production package: deployment/SpecialtyCAN_Phase1_PROD - deploy AFTER the Key Account package'; Rows = @(
    @('Lead_From_US_Retailer_Form_Assignment_And_Email', 'Lead after-save flow for Typeform retailer forms. Element Set_Canada_Sales_Channel_Value (Canada form ZpuPvJtA).', 'n/a', 'Flow', 'Deployed to Sandbox (v4 active)', 'Ready for Production', 'Lead', "Sales_Channel__c: 'Specialty CAN' -> 'Specialty'", 'Mapping Specialty CAN -> Specialty. New Canada form leads now get Specialty, so no new Specialty CAN records are created. Required before Specialty CAN can ever be removed: the flow has no fault path, so a removed value would roll back the whole lead insert. Queue (Lead Retailers Canada), email and Typeform file fetch unchanged; Shopify Canada store is chosen by country, not channel. Production active v4 = sandbox baseline v3 (verified).', '0Afdx00000GDSZyCAP'),
    @('LeadConversionHandlerTest1', 'Lead conversion tests (bulk channel list + test 7 Canada lead)', 'LeadConversionHandlerTest1', 'Apex Class (Test)', 'Deployed to Sandbox', 'Ready for Production', 'Lead', "5 lines: 'Specialty CAN' -> 'Specialty' (lines 182-183, 299; comment line 279; assert message 324)", 'Prepares tests for when the Specialty CAN value is removed (otherwise INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST blocks deployments). Test purpose unchanged. Production file = Key Account package version + these edits (cumulative).', '0Afdx00000GDXEfCAP'),
    @('ShopifyAssociationSyncSchedulableTest', 'Shopify association schedulable tests - Canada scenario', 'ShopifyAssociationSyncSchedulableTest', 'Apex Class (Test)', 'Deployed to Sandbox', 'Ready for Production', 'Account', "Line 63: 'Specialty CAN' -> 'Specialty' (BillingCountryCode = 'CA' kept)", 'Same reason. The test still proves Canada Shopify routing - routing uses the country, which is kept. 13/13 tests passing in sandbox (both classes).', '0Afdx00000GDXEfCAP'),
    @('Shopify Accounts CAN/Source (Shopify_Accounts_CANSource_Cluster_3_Abw)', 'Report - Production folder Cluster6 (sandbox folder Cluster3)', 'n/a', 'Report', 'Deployed to Sandbox', 'Ready for Production', 'Account', 'Logic 1 AND 2 AND 3 AND 4 -> 1 AND 2 AND 4 AND (3 OR (5 AND 6)); added 5 = Sales Channel equals Specialty, 6 = Billing Country Code equals CA', 'Additive: keeps Specialty CAN accounts AND adds Canadian Specialty companies (new Canada companies arrive as Specialty with Billing Country from the lead). No existing row removed.', '0Afdx00000GDXrNCAX'),
    @('Shopify Accounts Created CAN (Shopify_Accounts_Created_CAN_Cluster_3_k2J)', 'Report - Production folder Cluster6 (sandbox folder Cluster3); also has Created Date = last + this month', 'n/a', 'Report', 'Deployed to Sandbox', 'Ready for Production', 'Account', 'Logic 1 AND 2 AND 3 -> 1 AND 2 AND (3 OR (4 AND 5)); added 4 = Specialty, 5 = Billing Country Code = CA', 'Same as above. Sandbox: 361 -> 363 accounts (ignoring the date window).', '0Afdx00000GDXrNCAX')
  ) },
  @{ Title = 'SPECIALTY CAN - Verified working for OLD and NEW values (no change needed now)'; Rows = @(
    @('Sales_Channel_Cluster: SpecialtyCANAcc, SpecialtyCANLead, SpecialtyCAN_Opp, SpecialtyCAN_Contact', 'Cluster rules for Specialty CAN + Sellgoodr CAN -> Cluster 6', 'n/a', 'Custom Metadata Record', 'Kept - verified', 'No change', 'All', 'none', 'Kept for existing Specialty CAN records (data not migrated). New mapping Specialty + Self Service is covered by the Specialty_Self_Service_* rules = same Cluster 6. Verified with the live ClusterRuleEngine on in-memory records (no DML): old and new both Cluster 6 for Account, Lead, Opportunity.', ''),
    @('Sales_Channel_Cluster: SpecialtyCAN_Bridge_Account / _Lead / _Opportunity / _Contact', 'Cluster rules for Specialty CAN + Bridge -> Cluster 5', 'n/a', 'Custom Metadata Record', 'Kept - verified', 'No change', 'All', 'none', 'Kept. New mapping Specialty + Planned covered by Specialty_Planned_* rules = same Cluster 5 (verified).', ''),
    @('Account_Company_Record_Page / Lead_Record_Page - Specialty section filters', 'Criterion "Sales Channel = Specialty CAN" in Specialty - Sellgoodr and Specialty - Bridge sections', 'n/a', 'Lightning Page', 'Kept - verified', 'No change', 'Account, Lead', 'none', 'Criterion is OR-ed with Sales Channel = Specialty, so old (Specialty CAN) and new (Specialty) records show the same section. Verified on the live pages: Specialty CAN/Sellgoodr CAN and Specialty/Self Service -> Sellgoodr section; Specialty CAN/Bridge and Specialty/Planned -> Bridge section.', ''),
    @('Lead_Record_Page - Convert button', 'Hidden when Sales Channel = Specialty or Specialty CAN', 'n/a', 'Lightning Page', 'Kept - verified', 'No change', 'Lead', 'none', 'Hidden for both old and new values (verified).', ''),
    @('List view All Accounts; reports Accounts without Shopify Id, Fashion Report, Bridge Accounts, Specialty Classification', 'Filter Sales Channel equals Specialty, Specialty CAN', 'n/a', 'List View / Report', 'Kept', 'No change', 'Account', 'none', 'Already include both values - old and new records both appear.', ''),
    @('ShopifyConfigService + Shopify_Configuration__c record "Specialty CAN"', 'Canada Shopify store configuration, chosen by country', 'n/a', 'Apex Class / Config record', 'Not touched', 'Do NOT change', 'Account, Contact, Lead', 'none', 'Not a Sales Channel value - renaming or deleting it breaks Canadian Shopify sync.', '')
  ) },
  @{ Title = 'SPECIALTY CAN - Phase 2/3 PENDING (only after client approves the data migration)'; Rows = @(
    @('Specialty CAN records (Account, Contact, Lead)', 'Move Specialty CAN -> Specialty with Sector Sellgoodr CAN -> Self Service, Bridge -> Planned (same update)', 'n/a', 'Data', 'Not started', 'Pending client approval', 'Account, Contact, Lead', 'Prod: 728/392/26 (Sellgoodr CAN), 12/6/1 (Bridge), 2/3/11 (blank Sector)', 'Update Sales Channel and Sector together so ClusterRuleEngine (runs on Sales Channel change) keeps the same cluster. 346 Prod Specialty CAN companies have no Billing Country - fill Canada before migration or they drop out of the CAN reports and route to the US Shopify store.', ''),
    @('Cleanup after migration', '8 SpecialtyCAN* rules (delete); Specialty CAN criteria on 2 pages + Convert button; list view / 4 reports filters; deactivate Specialty CAN and Sellgoodr CAN', 'n/a', 'Various', 'Not started', 'Pending', 'All', 'remove old value', 'Only after no record uses Specialty CAN. Value removal last.', '')
  ) },
  @{ Title = 'Sandbox Only - NOT part of this Production deployment'; Rows = @(
    @('ShopifyAssociationRetryBatch', 'Retry batch for Shopify associations', 'none (0% coverage)', 'Apex Class', 'Deployed to Sandbox', 'Do NOT deploy with this change', 'Account', "Removed dead filter NOT IN ('Key Accounts')", 'Class does NOT exist in Production (sandbox-only work). Filter removed to match AccountTriggerHandler / ContactTriggerHandler ("ALL channels now sync") - no behaviour change (384 records with and without filter). Deploy with its own release; needs a test class (75% coverage) first.', '0Afdx00000GAizRCAT'),
    @('Sales_Channel_Cluster.Testtwoconditions', 'Duplicate Account rule (Cluster 1)', 'n/a', 'Custom Metadata Record', 'Deployed to Sandbox', 'Do NOT deploy', 'Account', "'Key Accounts' -> 'Key Account'", 'Record does not exist in Production (sandbox test record).', '0Afdx00000GAgZSCA1'),
    @('Account_Cluster_Team records - 16', 'Sandbox-only team records', 'n/a', 'Custom Metadata Records', 'Deployed to Sandbox', 'Do NOT deploy', 'Account_Cluster_Team__mdt', 'Key Accounts -> Key Account', 'These 16 records exist only in the sandbox. Production has 100 Key Account team records (all included in the package).', '0Afdx00000GAijJCAT')
  ) },
  @{ Title = 'Intentionally NOT changed'; Rows = @(
    @('ZendeskWebhookAPI (line 69)', "brand == 'Key Accounts'", 'n/a', 'Apex Class', 'No change', 'n/a', 'Case', 'none', 'This is the Zendesk brand name, not the Sales Channel picklist. Changing it would break Zendesk case routing.', ''),
    @('AccountTriggerHandler / ContactTriggerHandler comments', "Comments mentioning 'Key Accounts' exclusion", 'n/a', 'Apex Class', 'No change', 'n/a', 'Account, Contact', 'none', 'Historical comments only - no logic. Avoids redeploying working classes.', ''),
    @('Specialty CAN', 'Sales Channel value', 'n/a', 'Picklist value', 'No change', 'n/a', 'All', 'none', 'Value kept active - old and new values both work; see the SPECIALTY CAN section. Removal only after the data migration is approved.', '')
  ) }
)

foreach ($s in $sections) {
    Band $ws $r $cols.Count $s.Title; $r++
    foreach ($row in $s.Rows) {
        Row $ws $r $row
        $ws.Cells.Item($r, 1).Interior.Color = $yellow
        $e = $ws.Cells.Item($r, 5); $f = $ws.Cells.Item($r, 6)
        if ($row[4] -like 'Deployed to Sandbox*' -or $row[4] -like 'Done in Sandbox*' -or $row[4] -like 'Verified*') { $e.Interior.Color = $lgreen }
        if ($row[5] -like 'Ready for Production*') { $f.Interior.Color = $yellow } elseif ($row[5] -like 'Do NOT*') { $f.Interior.Color = $pink; $ws.Range($ws.Cells.Item($r, 1), $ws.Cells.Item($r, 1)).Interior.Color = $pink } elseif ($row[5] -like 'Pending*') { $f.Interior.Color = $yellow }
        $r++
    }
    $r++
}
$all = $ws.Range("A1", "J$r"); $all.Font.Name = 'Arial'; $all.Font.Size = 10; $all.WrapText = $true; $all.VerticalAlignment = -4108
$ws.Range("A3", "G$r").HorizontalAlignment = -4108
$ws.Range("A1", "J1").HorizontalAlignment = -4108
$ws.Activate(); $xl.ActiveWindow.SplitRow = 1; $xl.ActiveWindow.FreezePanes = $true

# ================================================================ Deployment Steps
$ws = $wb.Worksheets.Item('Deployment Steps')
Header $ws 1 @('Step', 'Phase', 'Action', 'Command / Where', 'Expected Result', 'Owner', 'Status') @(6, 16, 60, 70, 50, 14, 14)
$steps = @(
 @('1', 'Pre-check', 'Confirm the package matches current Production (no one changed these components since 6 Oct).', 'sf project retrieve start -o GDRPROD -x deployment/KeyAccount_Rename_PROD/package.xml --target-metadata-dir <temp>  then compare with deployment/KeyAccount_Rename_PROD_ROLLBACK', 'No differences. If different: rebuild package from the new Production version.', '', 'Not Started'),
 @('2', 'Pre-check', 'Check the 2 known failing ShopifyOrderSyncTest methods in Production (read-only test run).', 'sf apex run test -o GDRPROD -n ShopifyOrderSyncTest --wait 20', 'If they already fail in Production they are pre-existing; decide to fix first or leave ShopifyOrderSyncTest out of the specified tests.', '', 'Not Started'),
 @('3', 'Pre-check', 'Export current Sales Channel values (backup) for Account, Contact, Lead, Opportunity.', "Data Loader / SOQL: SELECT Id, Sales_Channel__c FROM <Object> WHERE Sales_Channel__c = 'Key Accounts'", 'CSV backup saved.', '', 'Not Started'),
 @('4', 'Maintenance window', 'Rename value in Global Value Set Sales Channel: Key Accounts -> Key Account (Label + API Name).', 'Setup > Picklist Value Sets > Sales Channel > Edit "Key Accounts"', 'Account / Contact / Opportunity records, record types and Sector dependency show Key Account.', '', 'Not Started'),
 @('5', 'Maintenance window', 'Rename value on Lead.Sales_Channel__c (local picklist in Production): Key Accounts -> Key Account (Label + API Name).', 'Object Manager > Lead > Fields & Relationships > Sales Channel > Edit "Key Accounts"', 'Lead records show Key Account. Values match Account/Contact.', '', 'Not Started'),
 @('6', 'Maintenance window', 'Validate the package with the specified tests (check-only).', 'sf project deploy validate -o GDRPROD --metadata-dir deployment/KeyAccount_Rename_PROD --test-level RunSpecifiedTests --tests AccountCascadeHandlerTest ClusterRuleEngineTest ClusterTriggerTest ContactTriggerHandlerTest LeadConversionHandlerTest LeadConversionHandlerTest1 ShopifyAddressSyncTest ShopifyOrderSyncTest ShopifySalesSyncServiceTest', '116 components validated, all specified tests pass. Note the Job ID.', '', 'Not Started'),
 @('7', 'Maintenance window', 'Quick-deploy the validated package.', 'sf project deploy quick -o GDRPROD --job-id <Job ID from step 6>', 'Deploy Succeeded.', '', 'Not Started'),
 @('8', 'Post-deploy', 'Verify cluster rules.', 'SOQL: SELECT DeveloperName, Rule_Condition__c FROM Sales_Channel_Cluster__mdt WHERE DeveloperName LIKE \u0027Key%\u0027', "4 rules show Sales_Channel__c = 'Key Account'.", '', 'Not Started'),
 @('9', 'Post-deploy', 'Verify team records.', 'SOQL: SELECT Sales_Channel__c, COUNT(Id) FROM Account_Cluster_Team__mdt GROUP BY Sales_Channel__c', 'Key Account = 100, Key Accounts = 0; User_Identifier__c unchanged.', '', 'Not Started'),
 @('10', 'Post-deploy', 'Functional test: create a Key Account Company account and a Key Account lead.', 'UI', 'Cluster__c = Cluster 1; account team created; "Key Account" section visible on Account and Lead pages.', '', 'Not Started'),
 @('11', 'Post-deploy', 'Convert a Key Account lead.', 'UI', 'Conversion succeeds; Contact / Account Sales Channel = Key Account.', '', 'Not Started'),
 @('S1', 'SECTOR - Pre-check', 'Run AFTER the Key Account deployment (steps 1-11) is complete.', 'n/a', 'Key Account change verified in Production.', '', 'Not Started'),
 @('S2', 'SECTOR - Manual', 'Add 7 values to Sector value set (Enterprise, Strategic, Development, Discount, Planned, Self Service, Distributor). Keep old values active.', 'Setup > Picklist Value Sets > Sector > New', 'Sector has 15 values.', '', 'Not Started'),
 @('S3', 'SECTOR - Manual', 'Field dependency on Sector__c for Account, Contact, Lead, Opportunity: Key Account -> Enterprise, Strategic, Development, Discount; Specialty -> Planned, Self Service; Global -> Distributor.', 'Object Manager > <Object> > Fields > Sector > Field Dependencies > Edit', 'New values selectable under their Sales Channel.', '', 'Not Started'),
 @('S4', 'SECTOR - Manual', 'Enable the 7 new values on record types: Account (Company, Franchise, Store_Location), Opportunity (Key_Account, Partnerships, Specialty).', 'Object Manager > Record Types > Sector > Edit', 'Values visible on the page per record type.', '', 'Not Started'),
 @('S5', 'SECTOR - Deploy', 'Validate the Sector package (no Apex in package).', 'sf project deploy validate -o GDRPROD --metadata-dir deployment/Sector_NewValues_PROD --test-level NoTestRun', '10 components validated. Note Job ID. (If Production requires tests for every deploy, use RunSpecifiedTests with ClusterRuleEngineTest ClusterTriggerTest.)', '', 'Not Started'),
 @('S6', 'SECTOR - Deploy', 'Quick-deploy the validated Sector package.', 'sf project deploy quick -o GDRPROD --job-id <Job ID from S5>', 'Deploy Succeeded.', '', 'Not Started'),
 @('S7', 'SECTOR - Post-deploy', 'Verify new cluster rules.', "SOQL: SELECT DeveloperName, Cluster_Value__c, Rule_Condition__c FROM Sales_Channel_Cluster__mdt WHERE DeveloperName LIKE 'Specialty_%'", '8 old + 8 new Specialty rules; Self Service = Cluster 6, Planned = Cluster 5.', '', 'Not Started'),
 @('S8', 'SECTOR - Post-deploy', 'Functional test on a test Specialty account / lead.', 'UI', 'Sector = Planned -> Specialty - Bridge section + Cluster 5. Sector = Self Service -> Specialty - Sellgoodr section + Cluster 6. Existing Sellgoodr USA / Bridge records unchanged.', '', 'Not Started'),
 @('R2', 'SECTOR - Rollback', 'Delete the 8 new rules and restore the pages to the Key Account version.', 'sf project deploy start -o GDRPROD --metadata-dir deployment/Sector_NewValues_PROD_ROLLBACK  (contains destructiveChangesPost.xml for the 8 rules)', 'Production back to the post-Key Account state.', '', ''), @('C1', 'SPECIALTY CAN - Pre-check', 'Run AFTER the Key Account deployment (LeadConversionHandlerTest1 in this package also contains the Key Account fix).', 'n/a', 'Key Account change verified in Production.', '', 'Not Started'),
 @('C2', 'SPECIALTY CAN - Deploy', 'Validate the Specialty CAN package with its 2 test classes.', 'sf project deploy validate --target-org GDRPROD --metadata-dir deployment/SpecialtyCAN_Phase1_PROD --test-level RunSpecifiedTests --tests LeadConversionHandlerTest1 --tests ShopifyAssociationSyncSchedulableTest', '5 components validated, all tests pass. Note Job ID.', '', 'Not Started'),
 @('C3', 'SPECIALTY CAN - Deploy', 'Quick-deploy the validated package.', 'sf project deploy quick --target-org GDRPROD --job-id <Job ID from C2>', 'Deploy Succeeded; flow becomes a new active version.', '', 'Not Started'),
 @('C4', 'SPECIALTY CAN - Post-deploy', 'Verify the flow active version sets Specialty on the Canada path.', 'Setup > Flows > Lead From TypeForm Form Assignment And Email > active version > Set Canada Sales Channel Value', 'Sales Channel = Specialty.', '', 'Not Started'),
 @('C5', 'SPECIALTY CAN - Post-deploy', 'Functional test: submit / simulate a Canada Typeform lead.', 'UI / Typeform test', 'Lead created, owner = Lead Retailers Canada queue, Sales Channel = Specialty, Under Review email sent, files fetched.', '', 'Not Started'),
 @('C6', 'SPECIALTY CAN - Post-deploy', 'Open the 2 Shopify CAN reports (Cluster 6 folder).', 'Reports', 'Filter logic shows Specialty CAN OR (Specialty AND Billing Country CA); existing rows still present.', '', 'Not Started'),
 @('R3', 'SPECIALTY CAN - Rollback', 'Restore flow, 2 test classes and 2 reports to their pre-change versions.', 'sf project deploy start --target-org GDRPROD --metadata-dir deployment/SpecialtyCAN_Phase1_PROD_ROLLBACK --test-level RunSpecifiedTests --tests LeadConversionHandlerTest1 --tests ShopifyAssociationSyncSchedulableTest  (or reactivate the previous flow version)', 'Back to the post-Key Account state.', '', ''), @('R', 'Rollback (if needed)', 'Redeploy Production originals and rename the picklist values back.', 'sf project deploy start -o GDRPROD --metadata-dir deployment/KeyAccount_Rename_PROD_ROLLBACK  +  rename Key Account -> Key Accounts in steps 4-5', 'Production back to the pre-deployment state.', '', '')
)
$r = 2; foreach ($s in $steps) { Row $ws $r ($s | % { $_ -replace '\\u0027', "'" }); $r++ }
$ws.Range("A1", "G$r").Font.Name = 'Arial'; $ws.Range("A1", "G$r").Font.Size = 10; $ws.Range("A2", "G$r").WrapText = $true; $ws.Range("A2", "G$r").VerticalAlignment = -4160
$ws.Range("G2", "G$($r-1)").Interior.Color = $yellow
$v = $ws.Range("G2", "G$($r-1)").Validation; $v.Delete(); $v.Add(3, 1, 1, 'Not Started,In Progress,Done,N/A')
$ws.Cells.Item($r + 1, 1).Formula = 'Steps 4-7 must run in one window: after the rename, the old tests and rules no longer match until the package is deployed; before the rename, the new tests cannot pass.'
$ws.Cells.Item($r + 1, 1).Font.Bold = $true

# ================================================================ Test Plan
$ws = $wb.Worksheets.Item('Test Plan')
Header $ws 1 @('Test Class', 'Lines Changed', 'Covers', 'Sandbox Result (before)', 'Sandbox Result (after deploy)', 'Notes') @(30, 14, 40, 26, 26, 70)
$tp = @(
 @('ClusterTriggerTest', '9', 'LeadClusterTrigger, AccountClusterTrigger, OpportunityClusterTrigger', '4 failing', 'All pass', ''),
 @('ClusterRuleEngineTest', '4', 'ClusterRuleEngine', '2 failing', 'All pass', ''),
 @('ContactTriggerHandlerTest', '3', 'ContactTriggerHandler', '36 failing', 'All pass', ''),
 @('LeadConversionHandlerTest1', '3', 'LeadConversionHandler / LeadConversionService', '2 failing', 'All pass', ''),
 @('LeadConversionHandlerTest', '1', 'LeadConversionHandler', '1 failing', 'All pass', ''),
 @('AccountCascadeHandlerTest', '1', 'AccountCascadeHandler', 'Pass', 'All pass', 'Updated for consistency only.'),
 @('ShopifyAddressSyncTest', '1', 'ShopifyAddressSyncService', '1 failing', 'All pass', ''),
 @('ShopifyOrderSyncTest', '1', 'ShopifyOrderSyncBatch / Service', '3 failing', '2 failing (pre-existing)', 'testNoAccountMatch_OrderSkipped and testNoOrdersToday fail on a date assertion (Expected today, Actual null) - not related to Sales Channel; failing before this change. Check in Production (Deployment Steps #2).'),
 @('ShopifySalesSyncServiceTest', '1', 'ShopifySalesSyncService', '1 failing', 'All pass', ''),
 @('TOTAL (9 classes)', '24', '', '98 / 149 passing (51 failing)', '143 / 145 passing', 'Sandbox run 6 Oct 2026 (GDRSAND).')
)
$r = 2; foreach ($t in $tp) { Row $ws $r $t; $r++ }
$ws.Range("A$($r-1)", "F$($r-1)").Font.Bold = $true
$ws.Range("A1", "F$r").Font.Name = 'Arial'; $ws.Range("A1", "F$r").Font.Size = 10; $ws.Range("A2", "F$r").WrapText = $true
$ws.Cells.Item($r + 3, 1).Formula = 'SPECIALTY CAN package: LeadConversionHandlerTest1 + ShopifyAssociationSyncSchedulableTest updated (Specialty CAN -> Specialty); 13/13 tests passing in sandbox. Run both as RunSpecifiedTests in Production.'
$ws.Cells.Item($r + 2, 1).Formula = 'SECTOR package: no Apex classes and no test class changes. ClusterRuleEngine reads rule text dynamically, so no code change was needed. Existing ClusterRuleEngineTest / ClusterTriggerTest still pass (143/145, same 2 pre-existing ShopifyOrderSyncTest failures).'
$ws.Cells.Item($r + 1, 1).Formula = 'Test level for Production: RunSpecifiedTests with the 9 classes above. Only test classes are deployed, so no 75% per-class coverage requirement applies to this package.'

# ================================================================ Team Records
$ws = $wb.Worksheets.Item('Team Records (100)')
Header $ws 1 @('#', 'Custom Metadata Record (DeveloperName)', 'Cluster', 'Object', 'Team Role', 'User (Production)', 'Sales Channel Before', 'Sales Channel After') @(5, 50, 12, 14, 26, 36, 18, 18)
$r = 2; $i = 1
foreach ($f in (Get-ChildItem "$pkg\customMetadata" -Filter 'Account_Cluster_Team.*' | Sort-Object Name)) {
    [xml]$x = Get-Content -LiteralPath $f.FullName; $v = @{}; $x.CustomMetadata.values | % { $v[$_.field] = [string]$_.value.'#text' }
    Row $ws $r @($i, ($f.BaseName -replace '\.md$', ''), $v['Cluster_Value__c'], $v['ObjectAPIName__c'], $v['Team_Role__c'], $v['User_Identifier__c'], 'Key Accounts', $v['Sales_Channel__c']); $r++; $i++
}
$ws.Range("A1", "H$r").Font.Name = 'Arial'; $ws.Range("A1", "H$r").Font.Size = 10
$ws.Range("A1", "H$($r-1)").AutoFilter() | Out-Null
$ws.Activate(); $xl.ActiveWindow.SplitRow = 1; $xl.ActiveWindow.FreezePanes = $true

# ================================================================ Sandbox vs Prod
$ws = $wb.Worksheets.Item('Sandbox vs Prod')
Header $ws 1 @('Component', 'Sandbox (GDRSAND)', 'Production (GDRPROD)', 'Impact on Deployment') @(42, 45, 45, 70)
$sv = @(
 @('Lead.Sales_Channel__c', 'Uses Global Value Set Sales_Channel1', 'Local picklist (Specialty, Specialty CAN, Key Accounts, Partnerships, Global)', 'Rename in Production is done on the Lead field itself (Deployment Steps #5).'),
 @('Account_Cluster_Team records', '116 Key Accounts records, sandbox users (@goodr.com.partial)', '100 Key Accounts records, production users (@goodr.com)', 'Package built from PRODUCTION records: only Sales_Channel__c changed, users preserved. 16 sandbox-only records excluded.'),
 @('Account_Company_Record_Page / Lead_Record_Page', 'Changed in sandbox after 28 Sep', 'Different from sandbox', 'Package uses the PRODUCTION page with only the one filter value changed - sandbox page changes are NOT carried to Production.'),
 @('ShopifyAssociationRetryBatch', 'Exists', 'Does not exist', 'Excluded from this deployment.'),
 @('Sales_Channel_Cluster.Testtwoconditions', 'Exists', 'Does not exist', 'Excluded from this deployment.'),
 @('Sector value set', 'Has the 7 new values (added before this work)', 'Only the 8 old values', 'Manual prerequisite steps S2-S4 before the Sector package.'),
 @('Sector field dependency', 'New values mapped', 'No new values mapped', 'Manual prerequisite step S3.'),
 @('8 old Specialty cluster rules', 'Unchanged', 'Identical to sandbox', 'Safe - not modified by this change.'),
 @('8 new Specialty cluster rules', 'Created (0Afdx00000GAl4TCAT)', 'Do not exist', 'Created by the Sector package.'),
 @('Specialty sections on both pages', 'Before-change filters (1 OR 3) AND 2', 'Identical filters', 'Sector package page = Production page + Key Account fix + Sector criteria.'), @('Specialty CAN flow', 'Active v4 (after change); baseline v3', 'Active v4 = identical to sandbox baseline v3', 'Same one-line change applied to the Production version.'),
 @('2 Shopify CAN reports', 'Folder Cluster3, name ...Cluster 3', 'Folder Cluster6, name ...Cluster 6, same filters', 'Production package uses the Cluster6 versions with the same added criteria.'),
 @('LeadConversionHandlerTest1', 'Has Key Account + Specialty CAN fixes', 'Still has Key Accounts and Specialty CAN', 'Package version = Key Account package version + Specialty CAN edits; deploy after Key Account.'),
 @('Specialty CAN companies without Billing Country', '355', '346', 'Covered while they stay Specialty CAN; fill Billing Country before any data migration.'), @('9 test classes', 'Before-change version', 'Identical to sandbox before-change version', 'Safe: package classes are identical to what was deployed to the sandbox.'),
 @('4 Key Account cluster rules', 'Before-change version', 'Identical', 'Safe.')
)
$r = 2; foreach ($t in $sv) { Row $ws $r $t; $r++ }
$ws.Range("A1", "D$r").Font.Name = 'Arial'; $ws.Range("A1", "D$r").Font.Size = 10; $ws.Range("A2", "D$r").WrapText = $true; $ws.Range("A2", "D$r").VerticalAlignment = -4160
$ws.Cells.Item($r + 1, 1).Formula = 'Source: read-only retrieve from GDRPROD on 6 Oct 2026 (no changes made to Production).'

# ================================================================ package.xml
$ws = $wb.Worksheets.Item('package.xml')
$ws.Cells.Item(1, 1).Formula = 'deployment/KeyAccount_Rename_PROD/package.xml  (ApexClass 9, CustomField 1, CustomMetadata 104, FlexiPage 2 = 116 members)'; $ws.Cells.Item(1, 1).Font.Bold = $true
$lines = Get-Content "$pkg\package.xml"; $r = 3; foreach ($l in $lines) { Set-Cell $ws $r 1 $l; $r++ }
$ws.Columns.Item(1).ColumnWidth = 90; $ws.Range("A3", "A$r").Font.Name = 'Consolas'; $ws.Range("A3", "A$r").Font.Size = 9

$r += 2; Set-Cell $ws $r 1 'deployment/Sector_NewValues_PROD/package.xml  (CustomMetadata 8, FlexiPage 2 = 10 members) - deploy AFTER the Key Account package'; $ws.Cells.Item($r, 1).Font.Bold = $true; $r += 2; foreach ($l in (Get-Content "$repo\deployment\Sector_NewValues_PROD\package.xml")) { Set-Cell $ws $r 1 $l; $ws.Cells.Item($r, 1).Font.Name = 'Consolas'; $ws.Cells.Item($r, 1).Font.Size = 9; $r++ }
$r += 2; Set-Cell $ws $r 1 'deployment/SpecialtyCAN_Phase1_PROD/package.xml  (ApexClass 2, Flow 1, Report 2 = 5 members) - deploy AFTER the Key Account package'; $ws.Cells.Item($r, 1).Font.Bold = $true; $r += 2; foreach ($l in (Get-Content "$repo\deployment\SpecialtyCAN_Phase1_PROD\package.xml")) { Set-Cell $ws $r 1 $l; $ws.Cells.Item($r, 1).Font.Name = 'Consolas'; $ws.Cells.Item($r, 1).Font.Size = 9; $r++ }
foreach ($s in $wb.Worksheets) { $s.PageSetup.Orientation = 2; $s.PageSetup.Zoom = $false; $s.PageSetup.FitToPagesWide = 1; $s.PageSetup.FitToPagesTall = $false }
$wb.Worksheets.Item('Deployment Document').Activate()
$xl.ScreenUpdating = $true
if (Test-Path $out) { Remove-Item $out -Force -Confirm:$false }
$wb.SaveAs($out, 51)
"Deployment Document rows: $($wb.Worksheets.Item('Deployment Document').UsedRange.Rows.Count)  Team rows: $($wb.Worksheets.Item('Team Records (100)').UsedRange.Rows.Count - 1)"
$wb.Close($false); $xl.Quit(); [Runtime.InteropServices.Marshal]::ReleaseComObject($xl) | Out-Null
"Saved $out"

