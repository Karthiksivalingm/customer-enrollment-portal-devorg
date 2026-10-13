$ErrorActionPreference = 'Stop'
$sp   = 'C:\Users\UTISLA~1\AppData\Local\Temp\claude\c--Microsoft-VS-Code-GDRSandbox\d08dd3dc-7817-4434-9679-5763d2940328\scratchpad'
$repo = 'C:\Microsoft VS Code\GDRSandbox'
$out  = Join-Path $repo 'Sector_SalesChannel_Impact_Analysis.xlsx'
$flexDir = "$sp\org\unpackaged\unpackaged\flexipages"

function RGB($r, $g, $b) { return [int]($r + $g * 256 + $b * 65536) }
$sevColor = @{ 'Critical' = (RGB 255 199 206); 'High' = (RGB 252 213 180); 'Medium' = (RGB 255 235 156); 'Low' = (RGB 198 239 206); 'Info' = (RGB 231 230 230) }
$hdrColor = RGB 31 56 100
$visColor = RGB 198 239 206
$hidColor = RGB 217 217 217
$gapColor = RGB 255 199 206

# ------------------------------------------------------------------ data: impact register
# Object | Where used (metadata type) | Component | Location | Old values | What it does | Impact | Severity | Action | Proposed
$reg = New-Object System.Collections.ArrayList
function Add-Reg { param($o, $t, $c, $l, $v, $w, $i, $s, $a, $p) [void]$reg.Add(@($o, $t, $c, $l, $v, $w, $i, $s, $a, $p)) }

# Picklists / value sets
Add-Reg 'All objects' 'Global Value Set (existing)' 'Sector' 'Setup > Picklist Value Sets > Sector' 'Sellgoodr USA, Sellgoodr CAN, Bridge, Core, Mid-Market, Off-Price, Global' 'Value set behind the existing Sector__c field. Under the client mapping the field is kept (legacy) and the new values go into a new Sector V2 field.' 'No record uses the 7 new values (Enterprise ... Distributor) that were added to this set in GDRSAND. Leaving them here lets users pick them in the wrong field.' 'Medium' 'Remove the 7 new values from this set. Keep the old values for existing data. Decide later when to retire Sector__c.' 'Sector__c: legacy values only'
Add-Reg 'All objects' 'Global Value Set (NEW)' 'Sector V2 (to create)' 'Setup > Picklist Value Sets > New' 'None' 'Value set for the new Sector V2 field.' 'Does not exist yet. Nothing can store the new values until it is created.' 'High' 'Create the value set.' 'Enterprise, Strategic, Development, Discount, Planned, Self Service, Partnerships, Distributor'
foreach ($o in 'Account', 'Contact', 'Lead', 'Opportunity') {
    Add-Reg $o 'Custom Field (NEW)' "$o.Sector_V2__c (assumed API name)" "Object Manager > $o > Fields & Relationships > New" 'None' 'New restricted picklist on the Sector V2 value set, dependent on Sales_Channel__c.' 'Does not exist yet in GDRSAND (checked via FieldDefinition on 5 Oct 2026).' 'High' 'Create the field. Set field-level security. Add it to layouts and Lightning pages next to Sector.' 'Controlling field: Sales_Channel__c'
}
Add-Reg 'Account, Contact, Opportunity' 'Global Value Set' 'Sales_Channel' 'Setup > Picklist Value Sets > Sales Channel' 'Key Accounts, Specialty CAN, Key Account CAN (inactive), Mid-Market (inactive)' 'Value set behind Sales_Channel__c on Account, Contact and Opportunity (restricted).' 'Key Account does not exist yet. Specialty CAN is still active.' 'Critical' 'Add Key Account. Migrate data. Remove Key Accounts, Specialty CAN and the inactive values.' 'Final values: Key Account, Specialty, Partnerships, Global'
Add-Reg 'Lead' 'Global Value Set' 'Sales_Channel1' 'Setup > Picklist Value Sets > Sales Channel (Sales_Channel1)' 'Key Accounts, Specialty CAN, Mid-Market (inactive)' 'A separate value set behind Lead.Sales_Channel__c.' 'It must hold exactly the same values as Sales_Channel, or lead conversion fails when the value is copied to the Account or Contact (restricted picklist).' 'Critical' 'Make the same changes as Sales_Channel.' 'Final values: Key Account, Specialty, Partnerships, Global'
foreach ($o in 'Account', 'Contact', 'Lead', 'Opportunity') {
    Add-Reg $o 'Field Dependency (NEW)' "$o.Sector_V2__c (controlled by Sales_Channel__c)" "Object Manager > $o > Fields > Sector V2 > Field Dependencies" 'None' 'Limits the Sector V2 choices by Sales Channel.' 'Without it, users can pick any Sector V2 value for any channel.' 'High' 'Build the dependency matrix on this object.' 'Key Account > Enterprise, Strategic, Development, Discount; Specialty > Planned, Self Service; Partnerships > Partnerships; Global > Distributor'
    Add-Reg $o 'Field Dependency (existing)' "$o.Sector__c (controlled by Sales_Channel__c)" "Object Manager > $o > Fields > Sector > Field Dependencies" 'Specialty CAN > Sellgoodr CAN, Bridge; Key Accounts > Core, Mid-Market, Off-Price' 'Limits the legacy Sector choices by Sales Channel.' 'When Specialty CAN and Key Accounts are removed, Sellgoodr CAN, Core, Mid-Market and Off-Price lose their controlling value. Records moved to Specialty / Key Account keep those Sectors, and users editing them hit an invalid dependent value.' 'Medium' 'Map Sellgoodr CAN under Specialty and Core, Mid-Market, Off-Price under Key Account, or make Sector__c read-only.' 'Specialty > Sellgoodr USA, Sellgoodr CAN, Bridge; Key Account > Core, Mid-Market, Off-Price'
}
foreach ($rt in @(@('Account', 'Company', 'Specialty CAN, Key Accounts'), @('Account', 'Store_Location', 'Specialty CAN, Key Accounts'), @('Account', 'Franchise', 'Key Accounts'), @('Opportunity', 'Key_Account', 'Key Accounts'), @('Opportunity', 'Partnerships', 'Key Accounts'), @('Opportunity', 'Specialty', 'Key Accounts'))) {
    Add-Reg $rt[0] 'Record Type picklist values' "$($rt[0]) record type $($rt[1])" "Object Manager > $($rt[0]) > Record Types > $($rt[1]) > Sales Channel / Sector V2" "Sales Channel: $($rt[2])" 'Controls which values users can pick in the UI for this record type.' 'Key Account and the Sector V2 values will not be selectable on this record type until enabled. UI only: Apex, flows and Data Loader are not limited by record type.' 'High' 'Enable Key Account and all Sector V2 values. Remove the old Sales Channel values.' 'Sales Channel: Key Account, Specialty, Partnerships, Global'
}
Add-Reg 'Custom Metadata' 'CMDT field (local picklist)' 'Account_Cluster_Team__mdt.Sales_Channel__c' 'Setup > Custom Metadata Types > Account Cluster Team > Sales Channel' 'Key Accounts, Mid-Market' 'Label on each team record. ClusterTeamEngine matches team records by Cluster_Value__c only (line 33); this field is not used.' 'None functionally. Values go out of date.' 'Low' 'Optional: add Key Account and relabel the records for consistency.' 'Specialty, Key Account, Global, Partnerships'

# Lightning record pages - visibility rules
$lrp = @(
    @('Account', 'Account_Company_Record_Page', 'Section: Specialty - Sellgoodr', '(SC = Specialty OR SC = Specialty CAN) AND Sector <> Bridge', 'Specialty, Specialty CAN, Bridge', 'Shows Resale_Certificate_Status__c for Specialty accounts that are not Bridge.', 'Existing records keep working (legacy Sector stays). New records only get Sector V2, so a new Planned account also shows this section. The Specialty CAN criterion becomes dead.', 'High', 'Add a Sector V2 criterion and drop Specialty CAN.', 'SC = Specialty AND Sector <> Bridge AND Sector V2 <> Planned (confirm Planned = Bridge with business)'),
    @('Account', 'Account_Company_Record_Page', 'Section: Specialty - Bridge', '(SC = Specialty OR SC = Specialty CAN) AND Sector = Bridge', 'Specialty, Specialty CAN, Bridge', 'Shows Resale_Certificate_Status__c for Bridge accounts.', 'Existing Bridge records keep it. New Planned records never show it, because they have no legacy Sector.', 'High', 'Add a Sector V2 criterion and drop Specialty CAN.', 'SC = Specialty AND (Sector = Bridge OR Sector V2 = Planned) (confirm with business)'),
    @('Account', 'Account_Company_Record_Page', 'Section: Key Account', 'SC = Key Accounts', 'Key Accounts', 'Shows Target_IMU__c, EDI__c, Custom_Tagging__c, Co_Op__c and New_Store_Discount_Allowance__c.', 'Never visible after the rename to Key Account. Key Account users lose these fields on the page.', 'Critical', 'Update the filter value.', 'SC = Key Account'),
    @('Account', 'Account_Company_Record_Page', 'Section: Partnership', 'SC = Partnerships', 'Partnerships (unchanged)', 'Shows Target_IMU__c.', 'No change.', 'Info', 'None. Retest only.', 'SC = Partnerships'),
    @('Account', 'Account_Company_Record_Page', 'Section: Global', 'SC = Global', 'Global (channel unchanged)', 'Shows Target_IMU__c.', 'No change. The channel value Global stays.', 'Info', 'None. Retest only.', 'SC = Global'),
    @('Lead', 'Lead_Record_Page', 'Button: Convert (highlights panel)', 'SC <> Specialty AND SC <> Specialty CAN AND Status = Qualified', 'Specialty, Specialty CAN', 'Hides the standard Convert button for Specialty leads; they use the custom approval flow.', 'Criterion 2 becomes dead once Specialty CAN is gone. Behaviour stays correct as long as former Specialty CAN leads are migrated to Specialty.', 'Low', 'Remove criterion 2 (cleanup).', 'SC <> Specialty AND Status = Qualified'),
    @('Lead', 'Lead_Record_Page', 'Section: Specialty - Sellgoodr', '(SC = Specialty OR SC = Specialty CAN) AND Sector <> Bridge', 'Specialty, Specialty CAN, Bridge', 'Shows 18 retailer fields (Store_Square_Footage__c, Resale_Number__c, the tax and GST/HST/PST/QST numbers, Email_Status__c and others).', 'Existing leads keep working. New Planned leads also show this section. The Specialty CAN criterion becomes dead.', 'High', 'Add a Sector V2 criterion and drop Specialty CAN.', 'SC = Specialty AND Sector <> Bridge AND Sector V2 <> Planned (confirm with business)'),
    @('Lead', 'Lead_Record_Page', 'Section: Specialty - Bridge', '(SC = Specialty OR SC = Specialty CAN) AND Sector = Bridge', 'Specialty, Specialty CAN, Bridge', 'Shows 8 fields (Tax_ID__c, Operating_Model__c, Total_Doors_in_Chain__c, Target_IMU__c and others).', 'New Planned leads never show it.', 'High', 'Add a Sector V2 criterion and drop Specialty CAN.', 'SC = Specialty AND (Sector = Bridge OR Sector V2 = Planned) (confirm with business)'),
    @('Lead', 'Lead_Record_Page', 'Section: Key Account', 'SC = Key Accounts', 'Key Accounts', 'Shows 7 fields (Tax_ID__c, Operating_Model__c, Total_Doors_in_Chain__c, Target_IMU__c and others).', 'Never visible after the rename to Key Account.', 'Critical', 'Update the filter value.', 'SC = Key Account'),
    @('Lead', 'Lead_Record_Page', 'Section: Partnership', 'SC = Partnerships', 'Partnerships (unchanged)', 'Shows 8 fields.', 'No change.', 'Info', 'None. Retest only.', 'SC = Partnerships'),
    @('Lead', 'Lead_Record_Page', 'Section: Global', 'SC = Global', 'Global (channel unchanged)', 'Shows 8 fields.', 'No change.', 'Info', 'None. Retest only.', 'SC = Global')
)
foreach ($l in $lrp) { Add-Reg $l[0] 'Lightning Record Page - visibility filter' $l[1] $l[2] $l[4] $l[5] $l[6] $l[7] $l[8] $l[9] }

# Lightning pages that only display the fields (from org retrieve)
$fieldRows = Get-Content "$sp\flexi_fields.json" -Raw | ConvertFrom-Json
$pageObj = @{}
foreach ($f in Get-ChildItem $flexDir -Filter *.flexipage) { [xml]$x = Get-Content $f.FullName -Raw; $pageObj[$f.BaseName] = $x.FlexiPage.sobjectType }
$assigned = @{
    'Account_Company_Record_Page' = 'Org default (Account) + Company record type in GOODR, Cluster_3, Sales apps'
    'Account_Store_Location_Record_Page1' = 'Store_Location record type in GOODR, Cluster_3, Sales apps'
    'Account_Franchise_Record_Page1' = 'Franchise record type in GOODR, Cluster_3, Sales apps'
    'Contact_Record_Page' = 'Org default (Contact) + GOODR, Cluster_3 apps'
    'Lead_Record_Page' = 'Org default (Lead) + GOODR, Cluster_3, Sales, Sales Console, Inside_Sales, Sales_Leader, Sales_Operations, Success_Manager and other apps'
    'Opportunity_Record_Page_Three_Column' = 'Org default (Opportunity) + Sales Console app'
    'Opportunity_Record_Page_Updated' = 'GOODR, Cluster_3, Sales apps + Key_Account record type'
    'Case_Record' = 'Org default (Case)'
}
foreach ($g in ($fieldRows | Group-Object Page)) {
    $pg = $g.Name; $fl = ($g.Group | ForEach-Object { $_.Field } | Select-Object -Unique) -join ', '
    $asg = $assigned[$pg]; if (-not $asg) { $asg = 'NOT activated in any app / record type / profile' }
    $sev = if ($assigned[$pg]) { 'Medium' } else { 'Info' }
    Add-Reg $pageObj[$pg] 'Lightning Record Page - field on page' $pg "Fields: $fl" 'None (field placement only)' "Displays the field(s). Activation: $asg." $(if ($assigned[$pg]) { 'Users cannot see or edit Sector V2 until it is added to this page.' } else { 'None - page is not used.' }) $sev $(if ($assigned[$pg]) { 'Add Sector_V2__c next to Sector__c. Retest the dependent picklist.' } else { 'None.' }) $(if ($assigned[$pg]) { 'Add Sector_V2__c' } else { '' })
}

# Page layouts
$lay = @(
    @('Account', 'Account-Company Layout', 'Sales_Channel__c (line 42), Sector__c (line 46)', 'Company record type, 24 profiles', 'Low'),
    @('Account', 'Account-Store Layout', 'Sales_Channel__c (line 38), Sector__c (line 42)', 'Store_Location record type, 24 profiles', 'Low'),
    @('Account', 'Account-Franchise Layout', 'Sales_Channel__c (line 32), Sector__c (line 36)', 'Franchise record type, 24 profiles', 'Low'),
    @('Account', 'Account-Account Layout', 'Sector__c (line 40)', 'Master record type, 24 profiles', 'Low'),
    @('Account', 'Account-Specialty - Bridge Layout', 'Sales_Channel__c (line 59), Sector__c (line 104)', 'NOT assigned. Named after an old Sector', 'Info'),
    @('Account', 'Account-Speciality - Sellgoodr Layout', 'Sales_Channel__c (line 59), Sector__c (line 104)', 'NOT assigned. Named after an old Sector', 'Info'),
    @('Contact', 'Contact-Contact Layout', 'Sales_Channel__c (line 64). Sector__c is not on the layout', 'All profiles', 'Low'),
    @('Lead', 'Lead-Lead Layout', 'Sales_Channel__c (line 12), Sector__c (line 16)', 'All profiles', 'Low'),
    @('Opportunity', 'Opportunity-Opportunity Layout', 'Retailers_Sales_Channel__c (47), Sector__c (91), Sales_Channel__c (289)', 'All record types and profiles', 'Low'),
    @('Custom Metadata', 'Account_Cluster_Team__mdt layouts (2)', 'Sales_Channel__c (line 39)', 'CMDT record layouts', 'Low')
)
foreach ($l in $lay) {
    $isObj = $l[0] -ne 'Custom Metadata'; $used = $l[4] -ne 'Info'
    $sev = if ($used -and $isObj) { 'Medium' } else { $l[4] }
    Add-Reg $l[0] 'Page Layout' $l[1] $l[2] 'None (field placement only)' "Displays the field(s). Assignment: $($l[3])." $(if ($used -and $isObj) { 'Sector V2 is not on the layout, so it is missing in Classic and in record-detail components that use the layout.' } else { 'None.' }) $sev $(if (-not $used) { 'Optional: rename or delete the unused layout.' } elseif ($isObj) { 'Add Sector_V2__c. Retest the dependent picklist.' } else { 'None.' }) $(if ($used -and $isObj) { 'Add Sector_V2__c' } else { '' })
}

# Flows
Add-Reg 'Lead' 'Flow (record-triggered, after save)' 'Lead_From_US_Retailer_Form_Assignment_And_Email' 'Update Records: Set_Canada_Sales_Channel_Value (line 347)' 'Specialty CAN' 'Canada retailer Typeform (FormId ZpuPvJtA): assigns the Lead Retailers Canada queue, sets Sales Channel = Specialty CAN, sends the email.' 'The update fails (INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST). The flow has no fault path and runs after save in the same transaction, so the whole save rolls back: the Canada lead is NOT created, and there is no queue assignment, email or Typeform file fetch. The flow owner gets a fault email.' 'Critical' 'Change the value to Specialty before removing Specialty CAN. Optionally set Sector V2.' 'Sales_Channel__c = Specialty; Sector_V2__c = Planned / Self Service (confirm)'
Add-Reg 'Lead' 'Flow (record-triggered, after save)' 'Lead_From_US_Retailer_Form_Assignment_And_Email' 'Update Records: Set_Sales_Channel_Value (line 363)' 'Specialty (unchanged)' 'US retailer Typeform (FormId S0t1jVLc): Lead Retailers US queue, Sales Channel = Specialty, email.' 'No break. No Sector is set, so these leads match no Specialty cluster rule (already true today).' 'Low' 'Optional: also set Sector V2.' 'Sector_V2__c = Planned / Self Service (confirm)'
Add-Reg 'Opportunity' 'Flow (record-triggered, before save)' 'Opportunity_field_update_from_Account' 'Assignment: Opportunity_field_Assignment (lines 18-28)' 'None (copies values)' 'On Opportunity create, copies Sales_Channel__c, Sector__c and Cluster__c from the Account.' 'Sector V2 is not copied, so new Opportunities get no Sector V2.' 'Medium' 'Add an assignment: Opportunity.Sector_V2__c = Account.Sector_V2__c.' '$Record.Sector_V2__c = $Record.Account.Sector_V2__c'
Add-Reg 'Campaign Member' 'Flow' 'Campaign_member_creation / Update_the_campaign_member_status' 'Campaign.Name filter (lines 89 / 85)' "'2026-T2-Specialty-Sellgoodr-ALL-winback' (campaign name)" 'Filters on the campaign name, not the picklist.' 'None.' 'Info' 'None, unless the campaign is renamed.' ''
Add-Reg 'Case' 'Flow' 'Typeform_Case_Routing' 'line 49' "'Specialty_Support' (queue name)" 'Routes to a queue.' 'None.' 'Info' 'None.' ''
Add-Reg 'Account' 'Flow' 'Auto_Assign_Pricebook_Based_on_Account_Country' 'lines 39, 92' "'Global' (Pricebook name)" 'Picks the pricebook by BillingCountry.' 'None.' 'Info' 'None.' ''

# Validation rules, list views, rules
Add-Reg 'Account' 'Validation Rule (inactive)' 'Standard_Cluster_Assignment' 'Account > Validation Rules' 'Global, Mid-Market, Specialty' 'Old check of channel against cluster (Global = Cluster 7, Mid-Market = Cluster 5, Specialty = Cluster 6).' 'None while inactive. The logic is out of date.' 'Low' 'Delete it, or update it if it will be reactivated.' ''
Add-Reg 'Opportunity' 'Validation Rule (inactive)' 'Closed_Won_All_Fields_Required / Deal_Size_Required_Fields' 'Opportunity > Validation Rules' 'None (Retailers_Sales_Channel__c only)' 'Requires Retailers_Sales_Channel__c (In Store / Online).' 'None. This is a different field.' 'Info' 'None.' ''
Add-Reg 'Account' 'List View' 'All Accounts (AllAccounts)' 'Filter: Sales_Channel__c equals Specialty, Specialty CAN' 'Specialty CAN' 'List of Company accounts in the Specialty channels.' 'The Specialty CAN part of the filter becomes dead. Migrated accounts still show under Specialty.' 'Low' 'Remove Specialty CAN from the filter.' 'Sales_Channel__c equals Specialty'
Add-Reg 'Lead' 'Assignment Rule (inactive)' 'Lead: Specialty - USA' 'assignmentRules/Lead (line 4)' 'None (name only)' 'Inactive, with no criteria.' 'None.' 'Info' 'None.' ''
Add-Reg 'Case' 'Auto-Response Rule' 'Case auto-response' 'lines 14-48' 'None (template and sender names)' 'Criteria use Case.Origin only.' 'None.' 'Info' 'None.' ''
Add-Reg 'N/A' 'Visualforce Page' 'Tableau_View / Testing_Tableau' 'lines 106-142' 'Display labels (Bridge, Mid-Market, Key Account dashboards)' 'Tab labels for Tableau dashboards.' 'Labels only. The dashboards behind them may filter on the old values.' 'Low' 'Check the Tableau dashboards with the BI owner.' ''
Add-Reg 'Contact' 'Email Templates' 'Warm_Off_1-5, Shopify_At_Risk_Notice' 'email/unfiled$public' 'None' 'No Sector or Sales Channel merge fields.' 'None.' 'Info' 'None.' ''
Add-Reg 'All objects' 'Reports / Dashboards' 'Not scanned' 'Setup > Field > Where is this used?' 'Unknown' 'Report filters and groupings on Sector / Sales Channel.' 'Filters on old values return no rows after the migration.' 'Medium' 'Run "Where is this used?" on both fields for all 4 objects and list the reports here.' ''

# Custom metadata cluster rules (grouped; detail sheet has every record)
Add-Reg 'Custom Metadata' 'CMDT: Sales_Channel_Cluster__mdt' '5 records: Keys_Account_Account, Key_Account_Contact, Key_Account_Lead, Key_Account_Opp, Testtwoconditions' "Rule_Condition__c: Sales_Channel__c = 'Key Accounts'" 'Key Accounts' 'ClusterRuleEngine sets Cluster 1.' 'No match after the rename. Cluster__c is left as it was with no error, so new Key Account records get no cluster and no team.' 'Critical' "Change to 'Key Account'. Add a Sector V2 condition if Clusters 1-4 should split by Sector V2." "Sales_Channel__c = 'Key Account' [&& Sector_V2__c = ...]"
Add-Reg 'Custom Metadata' 'CMDT: Sales_Channel_Cluster__mdt' '4 records: Mid_Market, Mid_Market_Contact, Mid_Market_Lead, Mid_Market_Opp' "Sales_Channel__c = 'Mid-Market'" 'Mid-Market (inactive channel)' 'Sets Cluster 5.' 'The channel value is already inactive, so this rule is already dead.' 'Low' 'Delete (cleanup).' ''
Add-Reg 'Custom Metadata' 'CMDT: Sales_Channel_Cluster__mdt' '4 records: SpeciaSpecialtylity, Specialty_Contact, Specialty_Lead, Specialty_Opp' "Sales_Channel__c = 'Specialty' && Sector__c = 'Sellgoodr USA'" 'Sellgoodr USA' 'Sets Cluster 6.' 'Still matches existing records (legacy Sector stays). New records that only have Sector V2 match no rule and get no cluster.' 'High' 'Keep these. Add new rules on Sector V2.' "NEW: Sales_Channel__c = 'Specialty' && Sector_V2__c = 'Self Service' -> Cluster 6 (confirm)"
Add-Reg 'Custom Metadata' 'CMDT: Sales_Channel_Cluster__mdt' '4 records: Specialty_Bridge_Account, _Contact, _Lead, _Opp' "Sales_Channel__c = 'Specialty' && Sector__c = 'Bridge'" 'Bridge' 'Sets Cluster 5.' 'Same: legacy records match, new Sector V2 records do not.' 'High' 'Keep these. Add new rules on Sector V2.' "NEW: Sales_Channel__c = 'Specialty' && Sector_V2__c = 'Planned' -> Cluster 5 (confirm)"
Add-Reg 'Custom Metadata' 'CMDT: Sales_Channel_Cluster__mdt' '4 records: SpecialtyCANAcc, SpecialtyCAN_Contact, SpecialtyCANLead, SpecialtyCAN_Opp' "Sales_Channel__c = 'Specialty CAN' && Sector__c = 'Sellgoodr CAN'" 'Specialty CAN, Sellgoodr CAN' 'Sets Cluster 6.' 'Dead once Specialty CAN is removed. See sheet Specialty CAN.' 'Low' 'Delete. Add a Specialty + Sellgoodr CAN rule if those records must stay on Cluster 6.' "Sales_Channel__c = 'Specialty' && Sector__c = 'Sellgoodr CAN' -> Cluster 6 (optional)"
Add-Reg 'Custom Metadata' 'CMDT: Sales_Channel_Cluster__mdt' '4 records: SpecialtyCAN_Bridge_Account, _Contact, _Lead, _Opportunity' "Sales_Channel__c = 'Specialty CAN' && Sector__c = 'Bridge'" 'Specialty CAN, Bridge' 'Sets Cluster 5.' 'Dead once Specialty CAN is removed. Moved records are covered by the Specialty + Bridge rule (same Cluster 5).' 'Low' 'Delete.' ''
Add-Reg 'Custom Metadata' 'CMDT: Sales_Channel_Cluster__mdt' '4 records: Global, Global_Contact, Global_Lead, Global_Opp' "Sales_Channel__c = 'Global'" 'Global (channel unchanged)' 'Sets Cluster 7.' 'Still matches.' 'Low' 'None. Optional: add Sector_V2__c = Distributor.' "Sales_Channel__c = 'Global'"
Add-Reg 'Custom Metadata' 'CMDT: Sales_Channel_Cluster__mdt' '4 records: PartnershipsAccount, PartnershipsContact, PartnershipsLead, PartnershipsOpp' "Sales_Channel__c = 'Partnerships'" 'Partnerships (unchanged)' 'Sets Cluster 8.' 'No change.' 'Info' 'None.' ''
Add-Reg 'Custom Metadata' 'CMDT: Sales_Channel_Cluster__mdt' '8 *_Contact rules (all channels)' 'ObjectAPIName__c = Contact' 'n/a' 'Rules for Contact.' 'Never used: ClusterRuleEngine returns immediately for Contact (line 9); Contact.Cluster__c is a formula from the Account.' 'Info' 'None. Optional cleanup.' ''
Add-Reg 'Custom Metadata' 'CMDT: Account_Cluster_Team__mdt' '218 records (Clusters 1-8)' 'Sales_Channel__c = Key Accounts (116), Mid-Market (29), others (73)' 'Key Accounts, Mid-Market' 'ClusterTeamEngine adds these users to the record team. It matches by Cluster_Value__c and ObjectAPIName__c only (lines 27-35).' 'None. The Sales_Channel__c value on these records is a label only. (Corrects the earlier Critical rating.)' 'Low' 'Optional: relabel Key Accounts to Key Account for consistency.' ''

# Apex
$apex = @(
    @('Account', 'ShopifyAssociationRetryBatch.cls', 'line 18 (SOQL); 12, 40, 68', "'Key Accounts'", "SOQL: Sales_Channel__c NOT IN ('Key Accounts') excludes Key Account stores from the Shopify retry.", 'After the rename nothing is excluded, so Key Account stores are retried against Shopify.', 'High', "Change to 'Key Account'.", "NOT IN ('Key Account')"),
    @('All objects', 'ClusterRuleEngine.cls', 'lines 9, 21-31, 43, 72', 'None (reads CMDT rules)', 'Evaluates Sales_Channel_Cluster rules and sets Cluster__c. Reads fields dynamically (record.get), so a Sector_V2__c condition works without code change. On update it runs only if Sales_Channel__c changed. Skips Contact.', 'A Sector V2-only change (or a Sector V2 backfill) never re-clusters. If no rule matches, Cluster__c keeps its old value. Rules are queried without ORDER BY, so overlapping rules match in no fixed order.', 'Medium', 'Also run when Sector_V2__c changes. Keep rules non-overlapping.', ''),
    @('Lead', 'LeadClusterTrigger.trigger', 'lines 20-22', 'None', 'Reassigns the team when Cluster or Sales Channel changes.', 'Same Sector V2-only gap.', 'Medium', 'Add Sector_V2__c to the change check.', ''),
    @('Opportunity', 'OpportunityClusterTrigger.trigger', 'lines 20-21', 'None', 'Same as the Lead trigger.', 'Same Sector V2-only gap.', 'Medium', 'Add Sector_V2__c to the change check.', ''),
    @('Account', 'AccountCascadeHandler.cls', 'lines 9-10, 45-48, 77-78', 'None', 'Copies Cluster__c and Sales_Channel__c from the Account to open Opportunities. The Contact copy is commented out.', 'Sector V2 is not cascaded, so open Opportunities keep a stale Sector V2.', 'Medium', 'Also cascade Sector_V2__c (and check it in the change condition).', ''),
    @('Lead', 'LeadConversionService.cls', 'lines 178, 227/248, 599/633, 649/671; 55, 512', 'None (copies values)', 'Copies Sales Channel and Sector from the Lead to the Contact, Company Account and Store Account.', 'Sector V2 is not copied, so it is lost on conversion. Lead uses the Sales_Channel1 value set; if it differs from Sales_Channel the insert fails on the restricted picklist.', 'High', 'Add Sector_V2__c to the SOQL (line 178) and to the 3 record builders. Keep the two Sales Channel value sets identical.', 'Sector_V2__c = lead.Sector_V2__c'),
    @('Lead', 'LeadConversionHandler.cls', 'lines 22, 31, 43-45', 'None', 'After conversion, copies the Account Cluster and Sales Channel to open Opportunities.', 'Sector V2 is not copied.', 'Low', 'Optional: copy Sector_V2__c.', ''),
    @('Contact', 'ContactTriggerHandler.cls', 'lines 10-22, 138-139', 'None (comments at 38, 89 mention Key Accounts)', 'Inherits Sales Channel from the Account when blank. Reassigns the team on a change.', 'Sector V2 is not inherited.', 'Low', 'Optional: inherit Sector_V2__c.', ''),
    @('Account, Contact', 'ShopifySyncButton.cls', 'lines 25, 32', 'None', 'Throws an error if Sales_Channel__c is blank.', 'Any record blanked during the migration cannot be synced.', 'Medium', 'Never blank Sales Channel during the migration.', ''),
    @('Account', 'ShopifyOrderSyncBatch.cls', 'lines 60, 90', 'None', "SOQL filter: Sales_Channel__c != null.", 'Records with a blank channel are skipped.', 'Medium', 'Same as above.', ''),
    @('Account', 'ShopifyConfigService.cls', 'lines 31-37', "'Specialty', 'Specialty CAN'", 'Looks up Shopify_Configuration__c by record Name (chosen by country).', 'None. These are record names, not picklist values.', 'Info', 'None, unless the config records are renamed.', ''),
    @('Case', 'ZendeskWebhookAPI.cls', 'line 69', "'Key Accounts'", 'Zendesk brand name mapped to the Retail Orders queue.', 'None. This is a Zendesk brand, not the picklist.', 'Info', 'None, unless the Zendesk brand is renamed.', ''),
    @('Product', 'NetSuiteProductSyncBatch.cls', 'lines 13, 15', "'Global'", 'Pricebook2 name.', 'None.', 'Info', 'None.', ''),
    @('Contact', 'WinbackStatusSync.cls', 'line 4', "'2026-T2-Specialty-Sellgoodr-ALL-winback'", 'Campaign / tag name.', 'None.', 'Info', 'Confirm with the business whether the campaign will be renamed.', ''),
    @('Account', 'accountShopifySyncButton (LWC)', 'js lines 13, 16', 'None', 'Checks that Account.Sales_Channel__c is not blank.', 'None.', 'Low', 'Retest.', ''),
    @('All objects', 'Sales_Team_User (Permission Set)', 'field permissions', 'None', 'Field-level security on Sales Channel and Sector.', 'None.', 'Low', 'None.', '')
)
foreach ($a in $apex) { $t = if ($a[1] -match 'LWC') { 'Lightning Web Component' } elseif ($a[1] -match 'Permission') { 'Permission Set' } elseif ($a[1] -match 'trigger') { 'Apex Trigger' } else { 'Apex Class' }; Add-Reg $a[0] $t $a[1] $a[2] $a[3] $a[4] $a[5] $a[6] $a[7] $a[8] }
foreach ($c in @(@('ContactTeamReassignQueueable.cls', '11', 'Contact'), @('AccountTriggerHandler.cls', '114 (8, 44, 112 comments)', 'Account'), @('AccountTriggerHelper.cls', '361', 'Account'), @('AccountContactRelationHandler.cls', '19, 25, 53', 'Account'), @('ShopifyAssociationSyncQueueable.cls', '35, 38, 57', 'Account'), @('ShopifyAssociationSyncSchedulable.cls', '12, 35', 'Account'), @('ShopifyManualAssociationQueueable.cls', '11, 39', 'Account'), @('ShopifyAccountIntegration.cls', '22, 30, 48, 251, 319', 'Account'), @('ShopifyActiveStatusPushService.cls', '17, 37, 108', 'Account'), @('ShopifyAddressSyncService.cls', '13, 28', 'Account'), @('ShopifyContactIntegration.cls', '24', 'Contact'), @('ShopifySalesSyncBatch.cls', '7, 9', 'Account'), @('ShopifyStoreLocationManualSyncQueueable.cls', '48, 52', 'Account'))) {
    Add-Reg $c[2] 'Apex Class' $c[0] "lines $($c[1])" 'None' 'Selects Sales_Channel__c or passes it into ShopifyAssociationInput. Routing uses the country.' 'None.' 'Low' 'Retest via the test classes.' ''
}

# Tests that break
$tests = @(
    @('AccountCascadeHandlerTest.cls', '116', "Key Accounts"), @('ClusterRuleEngineTest.cls', '109, 243, 260, 291', 'Key Accounts'), @('ClusterTriggerTest.cls', '101, 106, 202, 210, 214, 255, 260, 309, 315', 'Key Accounts'),
    @('ContactTriggerHandlerTest.cls', '31, 469, 474', 'Key Accounts'), @('LeadConversionHandlerTest.cls', '135', 'Key Accounts'), @('LeadConversionHandlerTest1.cls', '108, 182-183, 299', 'Key Accounts, Specialty CAN'),
    @('ShopifyAddressSyncTest.cls', '249', 'Key Accounts'), @('ShopifyAssociationSyncSchedulableTest.cls', '63', 'Specialty CAN'), @('ShopifyOrderSyncTest.cls', '688', 'Key Accounts'), @('ShopifySalesSyncServiceTest.cls', '604', 'Key Accounts')
)
foreach ($t in $tests) { Add-Reg 'Test' 'Apex Test Class' $t[0] "lines $($t[1])" $t[2] 'Inserts or asserts Sales_Channel__c with an old value.' 'Fails with INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST once the value is removed, which blocks production deployment.' 'High' 'Replace with the new value and update the assertions.' $(if ($t[2] -match 'CAN') { 'Specialty / Key Account' } else { 'Key Account' }) }

# Data
Add-Reg 'Test' 'Apex Test Class (NEW coverage)' 'LeadConversionServiceTest / ClusterRuleEngineTest / AccountCascadeHandlerTest' 'new test methods' 'None' 'Coverage for the Sector V2 changes.' 'Without new asserts, the Sector V2 copy and re-cluster logic ship untested.' 'Medium' 'Add tests: Sector V2 copied on conversion, cascade to Opportunities, re-cluster on a Sector V2 change.' ''
foreach ($d in @(@('Account', '712'), @('Contact', '18'), @('Lead', '32'), @('Opportunity', '6'))) {
    Add-Reg $d[0] 'Data (records)' "$($d[0]) records whose Sales Channel changes" 'See sheet Data Volume' 'Key Accounts, Specialty CAN, Mid-Market' "$($d[1]) records hold a Sales Channel value that is removed." 'Restricted picklist: once the value is removed these records cannot be saved by users, flows or integrations until updated.' 'Critical' 'Update Sales Channel before removing the old values (Specialty CAN > Specialty, Key Accounts > Key Account).' 'See Data Volume'
}
Add-Reg 'All objects' 'Data (records)' 'Sector V2 backfill (optional)' 'See sheet Data Volume, column Target Sector V2' 'n/a' 'Fill Sector V2 on existing records from the legacy Sector.' 'Business decision. A backfill alone does not re-cluster (ClusterRuleEngine runs only on a Sales Channel change).' 'Medium' 'Confirm the mapping. If clusters must follow Sector V2, set Cluster__c in the same load or extend ClusterRuleEngine first.' 'See Data Volume'

# ------------------------------------------------------------------ Excel helpers
$xl = New-Object -ComObject Excel.Application
$xl.Visible = $false; $xl.DisplayAlerts = $false; $xl.ScreenUpdating = $false
$wb = $xl.Workbooks.Add()
$names = 'Summary', 'Specialty CAN', 'Impact Register', 'LRP Visibility Rules', 'Visibility Matrix', 'Record Page Assignment', 'Cluster Rules (CMDT)', 'Cluster Team (CMDT)', 'Apex Tests', 'Data Volume', 'Value Mapping'
while ($wb.Worksheets.Count -lt $names.Count) { [void]$wb.Worksheets.Add([Type]::Missing, $wb.Worksheets.Item($wb.Worksheets.Count)) }
for ($i = 1; $i -le $names.Count; $i++) { $wb.Worksheets.Item($i).Name = $names[$i - 1] }
$xl.StandardFont = 'Arial'

function ColL($n) { $s = ''; while ($n -gt 0) { $m = ($n - 1) % 26; $s = [char](65 + $m) + $s; $n = [math]::Floor(($n - 1) / 26) }; return $s }
function Write-Table($ws, $startRow, $headers, $rows, $widths) {
    $nc = $headers.Count; $nr = $rows.Count
    $arr = New-Object 'object[,]' ($nr + 1), $nc
    for ($c = 0; $c -lt $nc; $c++) { $arr[0, $c] = $headers[$c] }
    for ($r = 0; $r -lt $nr; $r++) { for ($c = 0; $c -lt $nc; $c++) { $v = $rows[$r][$c]; if ($v -is [string] -and $v.StartsWith('=') -eq $false -and $v -match '^[+-]') { $v = "'" + $v }; $arr[($r + 1), $c] = $v } }
    $rng = $ws.Range("A$startRow", "$(ColL $nc)$($startRow + $nr)")
    for ($rr = 0; $rr -le $nr; $rr++) { for ($cc = 0; $cc -lt $nc; $cc++) { $vv = $arr[$rr, $cc]; if ($null -ne $vv -and "$vv" -ne "") { $ws.Cells.Item($startRow + $rr, $cc + 1).Formula = [string]$vv } } }
    $rng.Font.Name = 'Arial'; $rng.Font.Size = 9; $rng.WrapText = $true; $rng.VerticalAlignment = -4160
    $rng.Borders.LineStyle = 1; $rng.Borders.Color = (RGB 191 191 191)
    $h = $ws.Range("A$startRow", "$(ColL $nc)$startRow")
    $h.Font.Bold = $true; $h.Font.Color = (RGB 255 255 255); $h.Interior.Color = $hdrColor
    for ($c = 0; $c -lt $widths.Count; $c++) { $ws.Columns.Item($c + 1).ColumnWidth = $widths[$c] }
    return $rng
}
function Color-Sev($ws, $col, $r1, $r2) {
    for ($r = $r1; $r -le $r2; $r++) { $cell = $ws.Cells.Item($r, $col); $v = [string]$cell.Value2; if ($sevColor.ContainsKey($v)) { $cell.Interior.Color = $sevColor[$v]; $cell.Font.Bold = $true } }
}
function Title($ws, $text, $sub) {
    $ws.Cells.Item(1, 1).Value2 = $text; $ws.Cells.Item(1, 1).Font.Size = 14; $ws.Cells.Item(1, 1).Font.Bold = $true; $ws.Cells.Item(1, 1).Font.Name = 'Arial'
    $ws.Cells.Item(2, 1).Value2 = $sub; $ws.Cells.Item(2, 1).Font.Size = 9; $ws.Cells.Item(2, 1).Font.Italic = $true; $ws.Cells.Item(2, 1).Font.Name = 'Arial'
}
$src = 'Source: GDRSAND metadata retrieve (28 Sep 2026) + local force-app source. Updated 5 Oct 2026 for the client mapping: Sales Channel kept, Sector kept as legacy, new Sector V2 field. SC = Sales_Channel__c.'

# ------------------------------------------------------------------ Impact Register
$ws = $wb.Worksheets.Item('Impact Register')
Title $ws 'Impact Register - every component that uses Sales Channel / Sector' ($src + ' Fill in Status, Verified By, Verified On and Notes (yellow columns).')
$rows = @(); $i = 1
foreach ($r in $reg) { $rows += , (@(('IMP-{0:000}' -f $i)) + $r + @('Not Started', '', '', '')); $i++ }
$hdr = 'ID', 'Object', 'Where Used (Metadata Type)', 'Component Name', 'Location / Element / Line', 'Old Value(s) Referenced', 'What It Does', 'Impact if Values Replaced', 'Severity', 'Action Required', 'Proposed New Value / Rule', 'Status', 'Verified By', 'Verified On', 'Notes'
$rng = Write-Table $ws 4 $hdr $rows @(9, 14, 22, 32, 30, 26, 40, 45, 10, 32, 32, 12, 14, 12, 25)
$last = 4 + $rows.Count
Color-Sev $ws 9 5 $last
$ws.Range("L5", "O$last").Interior.Color = (RGB 255 255 204)
$v = $ws.Range("L5", "L$last").Validation; $v.Delete(); $v.Add(3, 1, 1, 'Not Started,In Progress,Done,N/A')
$ws.Range("A4", "O$last").AutoFilter() | Out-Null
$ws.Activate(); $xl.ActiveWindow.SplitRow = 4; $xl.ActiveWindow.SplitColumn = 4; $xl.ActiveWindow.FreezePanes = $true
$regLast = $last

# ------------------------------------------------------------------ LRP Visibility Rules
$ws = $wb.Worksheets.Item('LRP Visibility Rules')
Title $ws 'Lightning Record Page visibility filters driven by Sales Channel / Sector' ($src + ' Parsed from every FlexiPage in the org; only these 11 rules reference the two fields.')
$rules = Get-Content "$sp\flexi_rules.json" -Raw | ConvertFrom-Json
$lrpMap = @{}; foreach ($l in $lrp) { $lrpMap["$($l[1])|$($l[2])"] = $l }
$rows = @()
foreach ($r in $rules) {
    $kind = if ($r.Type -match 'Button') { 'Button' } else { 'Section' }
    $key = "$($r.Page)|$kind`: $($r.Component -replace '\s+', ' ')"
    $meta = $null; foreach ($k in $lrpMap.Keys) { if (($k -replace '\s+', ' ') -eq ($key -replace '\s+', ' ') -or ($k -replace '\s+', ' ') -like (($key -replace '\s+', ' ') + '*')) { $meta = $lrpMap[$k] } }
    $asg = $assigned[$r.Page]
    $rows += , @($r.Object, $r.Page, $asg, $kind, ($r.Component -replace '\s+', ' '), ($r.Parent -replace 'flexipage_tabset > Standard.Tab.detail', 'Details tab' -replace ' > flexipage_accordion > Standard.Tab.fields', ' > Fields accordion' -replace 'force:highlightsPanel \(actionNames\)', 'Highlights panel (actions)'), $r.Contains, $r.Filter, $r.Criteria, $r.Values, $meta[3], $meta[6], $meta[7], $meta[9], 'Not Started')
}
$hdr = 'Object', 'Record Page (API)', 'Activated For', 'Element Type', 'Section / Button Label', 'Location on Page', 'Fields Inside Section', 'Filter Logic', 'Filter Criteria (as configured)', 'Values Referenced', 'Visible When (plain)', 'Impact After Replacement', 'Severity', 'Proposed New Filter', 'Status'
$rng = Write-Table $ws 4 $hdr $rows @(10, 26, 34, 10, 22, 26, 40, 14, 36, 22, 36, 45, 10, 36, 12)
$last = 4 + $rows.Count
Color-Sev $ws 13 5 $last
$ws.Range("O5", "O$last").Interior.Color = (RGB 255 255 204)
$v = $ws.Range("O5", "O$last").Validation; $v.Delete(); $v.Add(3, 1, 1, 'Not Started,In Progress,Done,N/A')
$ws.Range("A4", "O$last").AutoFilter() | Out-Null
$n = $last + 2
$ws.Cells.Item($n, 1).Value2 = 'Other visibility filters on the same pages (not driven by Sales Channel / Sector, no change needed):'; $ws.Cells.Item($n, 1).Font.Bold = $true
$other = Get-Content "$sp\flexi_allrules.json" -Raw | ConvertFrom-Json | Where-Object { $_.Values -eq '' }
$rows = @(); foreach ($o in $other) { $rows += , @($o.Object, $o.Page, ($o.Type -replace ' \(flexipage:.*\)', ''), $o.Component, $o.Filter, $o.Criteria) }
[void](Write-Table $ws ($n + 1) @('Object', 'Record Page', 'Element Type', 'Element', 'Filter Logic', 'Criteria') $rows @())
$ws.Activate(); $xl.ActiveWindow.SplitRow = 4; $xl.ActiveWindow.SplitColumn = 0; $xl.ActiveWindow.FreezePanes = $true

# ------------------------------------------------------------------ Visibility Matrix
$ws = $wb.Worksheets.Item('Visibility Matrix')
Title $ws 'What shows on the page for each Sales Channel / Sector / Sector V2 - current filters vs proposed filters' 'Client mapping: Sales Channel kept, legacy Sector kept, new Sector V2 field added. Rules evaluated exactly as configured; Convert assumes Lead Status = Qualified. Red = the current filter shows the wrong thing for that record. Proposed filters assume Planned = Bridge section and Self Service = Sellgoodr section (confirm with business).'
$cur = [ordered]@{
    'Specialty - Sellgoodr' = { param($c, $s, $v) (($c -eq 'Specialty') -or ($c -eq 'Specialty CAN')) -and ($s -ne 'Bridge') }
    'Specialty - Bridge'    = { param($c, $s, $v) (($c -eq 'Specialty') -or ($c -eq 'Specialty CAN')) -and ($s -eq 'Bridge') }
    'Key Account'           = { param($c, $s, $v) $c -eq 'Key Accounts' }
    'Partnership'           = { param($c, $s, $v) $c -eq 'Partnerships' }
    'Global'                = { param($c, $s, $v) $c -eq 'Global' }
    'Convert button (Lead)' = { param($c, $s, $v) ($c -ne 'Specialty') -and ($c -ne 'Specialty CAN') }
}
$new = [ordered]@{
    'Specialty - Sellgoodr' = { param($c, $s, $v) ($c -eq 'Specialty') -and ($s -ne 'Bridge') -and ($v -ne 'Planned') }
    'Specialty - Bridge'    = { param($c, $s, $v) ($c -eq 'Specialty') -and (($s -eq 'Bridge') -or ($v -eq 'Planned')) }
    'Key Account'           = { param($c, $s, $v) $c -eq 'Key Account' }
    'Partnership'           = { param($c, $s, $v) $c -eq 'Partnerships' }
    'Global'                = { param($c, $s, $v) $c -eq 'Global' }
    'Convert button (Lead)' = { param($c, $s, $v) $c -ne 'Specialty' }
}
# Stage | Sales Channel | Sector (legacy) | Sector V2 | expected section | finding
$scen = @(
    @('Today', 'Specialty', 'Sellgoodr USA', '(blank)', '', 'Existing record - unchanged.'),
    @('Today', 'Specialty', 'Bridge', '(blank)', '', 'Existing record - unchanged.'),
    @('Today', 'Specialty', '(blank)', '(blank)', '', '7,521 Accounts / 175 Contacts / 233 Leads. Keeps Specialty - Sellgoodr under both filters.'),
    @('Today', 'Specialty CAN', 'Sellgoodr CAN', '(blank)', '', 'Moves to Specialty - see next block.'),
    @('Today', 'Specialty CAN', 'Bridge', '(blank)', '', 'Moves to Specialty - see next block.'),
    @('Today', 'Key Accounts', 'Core', '(blank)', '', 'Moves to Key Account - see next block.'),
    @('Today', 'Partnerships', 'Partnerships', '(blank)', '', 'Unchanged.'),
    @('Today', 'Global', 'Global', '(blank)', '', 'Unchanged.'),
    @('After migration', 'Specialty', 'Sellgoodr CAN', '(blank)', 'Specialty - Sellgoodr', 'Former Specialty CAN record. Same section as before under both filters.'),
    @('After migration', 'Specialty', 'Bridge', '(blank)', 'Specialty - Bridge', 'Former Specialty CAN Bridge record. Same section as before under both filters.'),
    @('After migration', 'Key Account', 'Core', '(blank)', 'Key Account', 'Former Key Accounts record. Current filter hides the Key Account section.'),
    @('New record', 'Key Account', '(blank)', 'Enterprise', 'Key Account', ''),
    @('New record', 'Key Account', '(blank)', 'Strategic', 'Key Account', ''),
    @('New record', 'Key Account', '(blank)', 'Development', 'Key Account', ''),
    @('New record', 'Key Account', '(blank)', 'Discount', 'Key Account', ''),
    @('New record', 'Specialty', '(blank)', 'Planned', 'Specialty - Bridge', ''),
    @('New record', 'Specialty', '(blank)', 'Self Service', 'Specialty - Sellgoodr', ''),
    @('New record', 'Partnerships', '(blank)', 'Partnerships', 'Partnership', ''),
    @('New record', 'Global', '(blank)', 'Distributor', 'Global', '')
)
$secs = @($cur.Keys)
$hdr = @('Stage', 'Sales Channel', 'Sector (legacy)', 'Sector V2 (new)') + ($secs | ForEach-Object { "CURRENT: $_" }) + ($secs | ForEach-Object { "PROPOSED: $_" }) + @('Expected section', 'Finding')
$rows = @(); $gapCells = @()
$ri = 0
foreach ($s in $scen) {
    $sec = if ($s[2] -eq '(blank)') { '' } else { $s[2] }; $v2 = if ($s[3] -eq '(blank)') { '' } else { $s[3] }
    $a = @(); foreach ($k in $secs) { $a += $(if (& $cur[$k] $s[1] $sec $v2) { 'Visible' } else { 'Hidden' }) }
    $b = @(); foreach ($k in $secs) { $b += $(if (& $new[$k] $s[1] $sec $v2) { 'Visible' } else { 'Hidden' }) }
    $find = $s[5]; $exp = $s[4]
    if ($exp) {
        $bad = @()
        for ($j = 0; $j -lt 5; $j++) { $should = ($secs[$j] -eq $exp); if (($a[$j] -eq 'Visible') -ne $should) { $bad += $secs[$j]; $gapCells += , @($ri, $j) } }
        $okNew = $true; for ($j = 0; $j -lt 5; $j++) { if (($b[$j] -eq 'Visible') -ne ($secs[$j] -eq $exp)) { $okNew = $false } }
        if ($bad.Count -gt 0) { $find = (($find + ' GAP with current filters: wrong for ' + ($bad -join ', ') + '.').Trim()) }
        $find = ($find + $(if ($okNew) { ' Proposed filters: correct.' } else { ' Proposed filters: STILL WRONG.' })).Trim()
    }
    $rows += , (@($s[0], $s[1], $s[2], $s[3]) + $a + $b + @($exp, $find)); $ri++
}
$rng = Write-Table $ws 4 $hdr $rows (@(14, 14, 14, 14) + (@(12) * 12) + @(20, 55))
$last = 4 + $rows.Count
for ($r = 5; $r -le $last; $r++) {
    for ($c = 5; $c -le 16; $c++) {
        $cell = $ws.Cells.Item($r, $c); $val = $cell.Value2
        $cell.Interior.Color = $(if ($val -eq 'Visible') { $visColor } else { $hidColor }); $cell.HorizontalAlignment = -4108
    }
    if ($ws.Cells.Item($r, 18).Value2 -like '*GAP*') { $ws.Cells.Item($r, 18).Interior.Color = $gapColor }
}
foreach ($gc in $gapCells) { $cell = $ws.Cells.Item(5 + $gc[0], 5 + $gc[1]); $cell.Interior.Color = $gapColor; $cell.Font.Bold = $true }
$ws.Range("E4", "P4").Orientation = 90; $ws.Rows.Item(4).RowHeight = 150
$ws.Activate(); $xl.ActiveWindow.SplitRow = 4; $xl.ActiveWindow.SplitColumn = 4; $xl.ActiveWindow.FreezePanes = $true
$n = $last + 2
$ws.Cells.Item($n, 1).Value2 = 'Pages these apply to: Account_Company_Record_Page (Account, Company record type) and Lead_Record_Page (Lead). Both pages carry the same 5 section filters. Store_Location, Franchise, Contact and Opportunity pages have no Sales Channel / Sector filters.'
$ws.Cells.Item($n, 1).Font.Italic = $true

# ------------------------------------------------------------------ Record Page Assignment
$ws = $wb.Worksheets.Item('Record Page Assignment')
Title $ws 'Lightning record pages that use Sales Channel / Sector - where each is activated' $src
$pageRows = @()
$fieldByPage = @{}; foreach ($g in ($fieldRows | Group-Object Page)) { $fieldByPage[$g.Name] = ($g.Group | ForEach-Object { $_.Field } | Select-Object -Unique) -join ', ' }
$rulesByPage = @{}; foreach ($g in ($rules | Group-Object Page)) { $rulesByPage[$g.Name] = $g.Count }
foreach ($p in ($fieldByPage.Keys + $rulesByPage.Keys | Select-Object -Unique | Sort-Object)) {
    $asg = $assigned[$p]; $act = if ($asg) { 'Yes' } else { 'No' }; if (-not $asg) { $asg = 'Not activated in any app, record type or profile' }
    $nr = $rulesByPage[$p]; if (-not $nr) { $nr = 0 }
    $sev = if ($nr -gt 0) { 'Critical' } elseif ($act -eq 'Yes') { 'Low' } else { 'Info' }
    $pageRows += , @($pageObj[$p], $p, $act, $asg, $fieldByPage[$p], $nr, $sev, $(if ($nr -gt 0) { 'Update visibility filters - see LRP Visibility Rules' } elseif ($act -eq 'Yes') { 'Display only - retest' } else { 'Unused - optional cleanup' }))
}
$rng = Write-Table $ws 4 @('Object', 'Record Page (API)', 'Active?', 'Activated For (app / record type / profile)', 'Sales Channel / Sector fields on page', '# Visibility Filters on SC / Sector', 'Severity', 'Action') $pageRows @(12, 36, 9, 60, 36, 14, 10, 42)
$last = 4 + $pageRows.Count; Color-Sev $ws 7 5 $last
$ws.Range("A4", "H$last").AutoFilter() | Out-Null

# ------------------------------------------------------------------ Cluster Rules (CMDT)
$ws = $wb.Worksheets.Item('Cluster Rules (CMDT)')
Title $ws 'Sales_Channel_Cluster__mdt - every rule record (drives Cluster__c via ClusterRuleEngine)' 'Parsed from force-app/main/default/customMetadata. Fill in "New Rule_Condition__c" (yellow) once the business confirms the cluster mapping.'
$rows = @()
foreach ($f in Get-ChildItem "$repo\force-app\main\default\customMetadata" -Filter 'Sales_Channel_Cluster.*.md-meta.xml') {
    [xml]$x = Get-Content $f.FullName -Raw; $vals = @{}
    foreach ($v in $x.CustomMetadata.values) { $vals[$v.field] = $v.value.'#text'; if (-not $vals[$v.field]) { $vals[$v.field] = [string]$v.value } }
    $cond = $vals['Rule_Condition__c']; $objN = $vals['ObjectAPIName__c']
    if ($objN -eq 'Contact') { $action = 'Never evaluated (engine skips Contact) - optional cleanup'; $sev = 'Info'; $prop = '' }
    else {
        $action = if ($cond -match 'Specialty CAN') { 'Delete' } elseif ($cond -match "Mid-Market") { 'Delete (already dead)' } elseif ($cond -match 'Key Accounts') { 'Rewrite' } elseif ($cond -match 'Sellgoodr USA|Bridge') { 'Keep for legacy Sector + add Sector V2 rule' } elseif ($cond -match 'Global') { 'Keep' } else { 'Keep' }
        $sev = switch -regex ($action) { '^Rewrite' { 'Critical' } '^Delete$' { 'Low' } 'already dead' { 'Low' } 'add Sector V2' { 'High' } default { $(if ($cond -match 'Global') { 'Low' } else { 'Info' }) } }
        $prop = switch -regex ($cond) {
            "Key Accounts" { "Sales_Channel__c = 'Key Account'" }
            "Sellgoodr USA" { "Unchanged. NEW rule: Sales_Channel__c = 'Specialty' && Sector_V2__c = 'Self Service' (confirm)" }
            "'Specialty' && Sector__c = 'Bridge'" { "Unchanged. NEW rule: Sales_Channel__c = 'Specialty' && Sector_V2__c = 'Planned' (confirm)" }
            default { '' }
        }
    }
    $dn = $f.Name -replace '^Sales_Channel_Cluster\.', '' -replace '\.md-meta\.xml$', ''; $rows += , @($dn, $x.CustomMetadata.label, $objN, $vals['Cluster_Value__c'], $cond, $action, $sev, $prop, 'Not Started')
}
$rows = @($rows | Sort-Object { $_[3] }, { $_[2] })
foreach ($o in 'Account', 'Lead', 'Opportunity') {
    $rows += , @("NEW: Specialty_SelfService_$o", "Specialty Self Service - $o", $o, 'Cluster 6 (confirm)', '(new record)', 'Create', 'High', "Sales_Channel__c = 'Specialty' && Sector_V2__c = 'Self Service'", 'Not Started')
    $rows += , @("NEW: Specialty_Planned_$o", "Specialty Planned - $o", $o, 'Cluster 5 (confirm)', '(new record)', 'Create', 'High', "Sales_Channel__c = 'Specialty' && Sector_V2__c = 'Planned'", 'Not Started')
}
$rng = Write-Table $ws 4 @('DeveloperName', 'Label', 'Object', 'Cluster', 'Current Rule_Condition__c', 'Action', 'Severity', 'New Rule_Condition__c (proposed)', 'Status') $rows @(30, 30, 12, 10, 55, 24, 10, 55, 12)
$last = 4 + $rows.Count; Color-Sev $ws 7 5 $last
$ws.Range("H5", "I$last").Interior.Color = (RGB 255 255 204)
$v = $ws.Range("I5", "I$last").Validation; $v.Delete(); $v.Add(3, 1, 1, 'Not Started,In Progress,Done,N/A')
$ws.Range("A4", "I$last").AutoFilter() | Out-Null

# ------------------------------------------------------------------ Cluster Team (CMDT)
$ws = $wb.Worksheets.Item('Cluster Team (CMDT)')
Title $ws 'Account_Cluster_Team__mdt - records by Sales Channel, cluster and object' 'Parsed from force-app/main/default/customMetadata. ClusterTeamEngine.cls (lines 27-35) matches these records by Cluster_Value__c and ObjectAPIName__c only; Sales_Channel__c here is a label, so the picklist change does not affect team assignment.'
$teams = foreach ($f in Get-ChildItem "$repo\force-app\main\default\customMetadata" -Filter 'Account_Cluster_Team.*.md-meta.xml') {
    [xml]$x = Get-Content $f.FullName -Raw; $vals = @{}
    foreach ($v in $x.CustomMetadata.values) { $t = $v.value.'#text'; if (-not $t) { $t = [string]$v.value }; $vals[$v.field] = $t }
    [pscustomobject]@{ SC = $vals['Sales_Channel__c']; Cl = $vals['Cluster_Value__c']; Obj = $vals['ObjectAPIName__c'] }
}
$rows = @()
foreach ($g in ($teams | Group-Object SC, Cl | Sort-Object Name)) {
    $sc = $g.Group[0].SC; $cl = $g.Group[0].Cl
    $cnt = @{}; foreach ($o in 'Account', 'Contact', 'Lead', 'Opportunity', 'Case') { $cnt[$o] = @($g.Group | Where-Object { $_.Obj -eq $o }).Count }
    $act = switch ($sc) { 'Key Accounts' { 'Optional relabel to Key Account' } 'Mid-Market' { 'Optional relabel' } default { 'No change' } }
    $sev = switch ($sc) { 'Key Accounts' { 'Low' } 'Mid-Market' { 'Low' } default { 'Info' } }
    $rows += , @($sc, $cl, $cnt['Account'], $cnt['Contact'], $cnt['Lead'], $cnt['Opportunity'], $cnt['Case'], '', $act, $sev)
}
$rng = Write-Table $ws 4 @('Sales_Channel__c', 'Cluster', 'Account', 'Contact', 'Lead', 'Opportunity', 'Case', 'Total', 'Action', 'Severity') $rows @(16, 12, 10, 10, 10, 12, 10, 10, 28, 10)
$last = 4 + $rows.Count
for ($r = 5; $r -le $last; $r++) { $ws.Cells.Item($r, 8).Formula = "=SUM(C$($r):G$($r))" }
$ws.Cells.Item($last + 1, 1).Value2 = 'Total'; $ws.Cells.Item($last + 1, 1).Font.Bold = $true
foreach ($c in 3..8) { $L = ColL $c; $ws.Cells.Item($last + 1, $c).Formula = "=SUM($($L)5:$($L)$last)"; $ws.Cells.Item($last + 1, $c).Font.Bold = $true }
Color-Sev $ws 10 5 $last

# ------------------------------------------------------------------ Apex Tests
$ws = $wb.Worksheets.Item('Apex Tests')
Title $ws 'Apex test classes that hardcode old values' 'These fail once the old values are removed from the restricted picklists. Tests that use only Specialty, Global or Partnerships keep passing.'
$rows = @(); foreach ($t in $tests) { $rows += , @($t[0], $t[1], $t[2], $(if ($t[2] -match 'CAN') { 'Specialty / Key Account' } else { 'Key Account' }), 'High', 'Not Started', '') }
$rows += , @('ClusterTeamEngineTest.cls, ContactClusterTriggerTest.cls', '-', 'Global (still valid)', '-', 'Low', 'Not Started', 'Assert cluster numbers; recheck if cluster rules change')
$rows += , @('ShopifyContactIntegrationTest.cls', '62, 277, 299', "'Specialty CAN' as a Shopify config name / message text", '-', 'Low', 'Not Started', 'Not a picklist insert; recheck the message assertion')
$rng = Write-Table $ws 4 @('Test Class', 'Lines', 'Old Value(s)', 'Replace With', 'Severity', 'Status', 'Notes') $rows @(45, 34, 34, 22, 10, 12, 45)
$last = 4 + $rows.Count; Color-Sev $ws 5 5 $last
$ws.Range("F5", "G$last").Interior.Color = (RGB 255 255 204)
$v = $ws.Range("F5", "F$last").Validation; $v.Delete(); $v.Add(3, 1, 1, 'Not Started,In Progress,Done,N/A')

# ------------------------------------------------------------------ Data Volume
$ws = $wb.Worksheets.Item('Data Volume')
Title $ws 'Records per Sales Channel / Sector (GDRSAND, 28 Sep 2026)' 'Source: SOQL GROUP BY Sales_Channel__c, Sector__c on each object. Legacy Sector__c is kept as is. Yellow = Sector V2 backfill values to confirm with the business (? = undecided, blank = do not backfill). Re-run the counts in production before go-live.'
$dv = @(
    @('Specialty', '(blank)', 7521, 175, 233, 5, 'Specialty', '(blank)'),
    @('Specialty', 'Sellgoodr USA', 123, 46, 65, 2, 'Specialty', 'Self Service?'),
    @('Specialty', 'Bridge', 10, 4, 8, 0, 'Specialty', 'Planned?'),
    @('Specialty', 'Sellgoodr CAN', 1, 1, 1, 0, 'Specialty', '?'),
    @('Specialty CAN', '(blank)', 665, 4, 4, 0, 'Specialty', '?'),
    @('Specialty CAN', 'Sellgoodr CAN', 5, 2, 2, 0, 'Specialty', '?'),
    @('Specialty CAN', 'Bridge', 0, 0, 2, 0, 'Specialty', 'Planned?'),
    @('Key Accounts', '(blank)', 26, 6, 14, 2, 'Key Account', '(blank)'),
    @('Key Accounts', 'Core', 10, 3, 5, 3, 'Key Account', '?'),
    @('Key Accounts', 'Mid-Market', 5, 3, 3, 0, 'Key Account', '?'),
    @('Mid-Market', '(blank)', 1, 0, 2, 1, 'Key Account?', '?'),
    @('Global', 'Global', 6, 1, 2, 0, 'Global', 'Distributor'),
    @('Global', '(blank)', 5, 7, 11, 2, 'Global', '(blank)'),
    @('Partnerships', 'Partnerships', 8, 5, 5, 0, 'Partnerships', 'Partnerships'),
    @('Partnerships', '(blank)', 1, 8, 4, 0, 'Partnerships', '(blank)'),
    @('(blank)', '(blank)', 45, 4202, 4, 60, '(blank)', '(blank)')
)
$rows = @(); foreach ($d in $dv) { $rows += , @($d[0], $d[1], $d[2], $d[3], $d[4], $d[5], '', $d[6], $d[7], '', '') }
$rng = Write-Table $ws 4 @('Current Sales Channel', 'Current Sector (legacy, kept)', 'Account', 'Contact', 'Lead', 'Opportunity', 'Total', 'Target Sales Channel', 'Target Sector V2 (backfill)', 'Sales Channel Update?', 'Sector V2 Backfill?') $rows @(22, 24, 10, 10, 10, 12, 10, 20, 22, 14, 14)
$last = 4 + $rows.Count
for ($r = 5; $r -le $last; $r++) {
    $ws.Cells.Item($r, 7).Formula = "=SUM(C$($r):F$($r))"
    $ws.Cells.Item($r, 10).Formula = "=IF(SUBSTITUTE(H$r,""?"","""")=A$r,""No"",""Yes"")"
    $ws.Cells.Item($r, 11).Formula = "=IF(I$r=""(blank)"",""No"",IF(I$r=""?"",""TBD"",""Yes""))"
}
$ws.Cells.Item($last + 1, 1).Value2 = 'Total'; $ws.Cells.Item($last + 1, 1).Font.Bold = $true
foreach ($c in 3..7) { $L = ColL $c; $ws.Cells.Item($last + 1, $c).Formula = "=SUM($($L)5:$($L)$last)"; $ws.Cells.Item($last + 1, $c).Font.Bold = $true }
$ws.Cells.Item($last + 2, 1).Value2 = 'Sales Channel updates (required)'; $ws.Cells.Item($last + 2, 1).Font.Bold = $true
foreach ($c in 3..7) { $L = ColL $c; $ws.Cells.Item($last + 2, $c).Formula = "=SUMIF(`$J`$5:`$J`$$last,""Yes"",$($L)5:$($L)$last)"; $ws.Cells.Item($last + 2, $c).Font.Bold = $true }
$ws.Cells.Item($last + 3, 1).Value2 = 'Sector V2 backfill (optional)'; $ws.Cells.Item($last + 3, 1).Font.Bold = $true
foreach ($c in 3..7) { $L = ColL $c; $ws.Cells.Item($last + 3, $c).Formula = "=SUMIF(`$K`$5:`$K`$$last,""Yes"",$($L)5:$($L)$last)"; $ws.Cells.Item($last + 3, $c).Font.Bold = $true }
$ws.Range("C5", "G$($last + 3)").NumberFormat = '#,##0'
$ws.Range("I5", "I$last").Interior.Color = (RGB 255 255 204)
$ws.Cells.Item($last + 5, 1).Value2 = 'Note: a Sector V2 backfill does not re-cluster records, because ClusterRuleEngine only runs when Sales Channel changes. Set Cluster__c in the same load if clusters must follow Sector V2.'
$ws.Cells.Item($last + 5, 1).Font.Italic = $true
$dvLast = $last

# ------------------------------------------------------------------ Value Mapping
$ws = $wb.Worksheets.Item('Value Mapping')
Title $ws 'Client mapping - Sales Channel kept, Sector kept (legacy), new Sector V2 field' 'Source: client mapping ("Keep this field: Sales Channel / Add new field: Sector V2") and the existing production/sandbox mapping, both supplied by the user.'
$rows = @(
    @('Specialty', 'Sellgoodr USA, Bridge', '', 'Specialty', 'Planned, Self Service', 'Channel kept'),
    @('Specialty CAN', 'Sellgoodr CAN, Bridge', '', '(removed)', '-', 'Channel removed - records move to Specialty (see sheet Specialty CAN)'),
    @('Key Accounts', 'Core, Mid-Market, Off-Price', '', 'Key Account', 'Enterprise, Strategic, Development, Discount', 'Channel renamed (assumed)'),
    @('Partnerships', 'Partnerships', '', 'Partnerships', 'Partnerships', 'No change'),
    @('Global', 'Global', '', 'Global', 'Distributor', 'Channel kept')
)
$rng = Write-Table $ws 4 @('EXISTING Sales Channel', 'EXISTING Sector (kept as legacy field)', '', 'NEW Sales Channel', 'NEW Sector V2 (new field)', 'Sales Channel change') $rows @(22, 30, 3, 20, 40, 50)
$ws.Range("C4", "C9").Interior.ColorIndex = -4142; $ws.Range("C4", "C9").Borders.LineStyle = -4142
$notes = @(
    'Sector__c is not edited: it keeps its old values for existing records. Sector V2 (Sector_V2__c, assumed API name) is a new dependent picklist controlled by Sales Channel.',
    'Removed Sales Channel values: Specialty CAN, Key Accounts (replaced by Key Account), plus the already-inactive Mid-Market and Key Account CAN.',
    'The 7 new values were already added to the existing Sector value set in GDRSAND; under this mapping they belong in Sector V2 and should be removed from Sector.',
    'Open question: the client list says "Key Account"; the org value today is "Key Accounts". This workbook assumes a rename to "Key Account".'
)
for ($j = 0; $j -lt $notes.Count; $j++) { $ws.Cells.Item(11 + $j, 1).Value2 = $notes[$j]; $ws.Cells.Item(11 + $j, 1).Font.Italic = $true }

# ------------------------------------------------------------------ Specialty CAN
$ws = $wb.Worksheets.Item('Specialty CAN')
Title $ws 'Removing Sales Channel = Specialty CAN - every touchpoint and its impact' 'One thing breaks: the Canada retailer form flow. Shopify sync does not break (Canada routing uses country, not Sales Channel). Everything else is data to move or dead references to clean up. Source: GDRSAND metadata + local source, checked 5 Oct 2026.'
$ws.Cells.Item(4, 1).Value2 = 'A. Components that use Specialty CAN'; $ws.Cells.Item(4, 1).Font.Bold = $true
$can = @(
    @('Flow', 'Lead', 'Lead_From_US_Retailer_Form_Assignment_And_Email', 'Update Records: Set_Canada_Sales_Channel_Value (line 347)', "Sets Lead.Sales_Channel__c = 'Specialty CAN' for the Canada Typeform (FormId ZpuPvJtA), assigns queue Lead Retailers Canada, sends the email.", 'The update fails (INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST). The flow has no fault path and runs after save in the same transaction, so the whole save rolls back: the Canada lead is NOT created, and there is no queue assignment, email or Typeform file fetch. The flow owner gets a fault email.', 'Critical', "Change the value to 'Specialty'. Optionally set Sector V2.", 'Before removal'),
    @('Data', 'Account', '670 Account records', 'Sales_Channel__c', 'Specialty CAN (665 with blank Sector, 5 with Sellgoodr CAN)', 'After removal these records cannot be saved by users, flows or integrations until updated.', 'Critical', 'Update Sales_Channel__c to Specialty (Data Loader / batch).', 'Before removal'),
    @('Data', 'Contact', '6 Contact records', 'Sales_Channel__c', 'Specialty CAN (4 blank Sector, 2 Sellgoodr CAN)', 'Same as above.', 'Critical', 'Update to Specialty.', 'Before removal'),
    @('Data', 'Lead', '8 Lead records', 'Sales_Channel__c', 'Specialty CAN (4 blank, 2 Sellgoodr CAN, 2 Bridge)', 'Same as above.', 'Critical', 'Update to Specialty.', 'Before removal'),
    @('Data', 'Opportunity', '0 Opportunity records', 'Sales_Channel__c', 'None in GDRSAND', 'None. Re-check in production.', 'Info', 'Re-run the count in production.', 'Before removal'),
    @('Apex Test', 'Test', 'LeadConversionHandlerTest1.cls', 'line 299 (insert); lines 182-183 (value list)', "Inserts a Lead with Sales_Channel__c = 'Specialty CAN'.", 'Test fails once the value is gone, which blocks the production deployment.', 'High', "Use 'Specialty'.", 'Same deployment as the flow fix'),
    @('Apex Test', 'Test', 'ShopifyAssociationSyncSchedulableTest.cls', 'line 63', "Inserts a record with Sales_Channel__c = 'Specialty CAN'.", 'Same as above.', 'High', "Use 'Specialty'.", 'Same deployment as the flow fix'),
    @('Global Value Set', 'Account, Contact, Opportunity', 'Sales_Channel', 'Setup > Picklist Value Sets > Sales Channel', 'Active value.', 'This is the change itself.', 'High', 'Deactivate, then delete, after the data is moved.', 'Removal step'),
    @('Global Value Set', 'Lead', 'Sales_Channel1', 'Setup > Picklist Value Sets > Sales Channel (Lead)', 'Active value.', 'Must be removed too, so both sets stay identical (Lead conversion copies the value).', 'High', 'Remove at the same time as Sales_Channel.', 'Removal step'),
    @('Record Type', 'Account', 'Company', 'Record type picklist values', 'Specialty CAN enabled.', 'Removed automatically with the value. UI only.', 'Low', 'Verify after removal.', 'Removal step'),
    @('Record Type', 'Account', 'Store_Location', 'Record type picklist values', 'Specialty CAN enabled.', 'Same as above.', 'Low', 'Verify after removal.', 'Removal step'),
    @('Field Dependency (legacy Sector)', 'Account, Contact, Lead, Opportunity', 'Sector__c controlled by Sales_Channel__c', 'Specialty CAN > Sellgoodr CAN, Bridge', 'Sellgoodr CAN is available only under Specialty CAN.', 'Sellgoodr CAN loses its controlling value. 12 records hold Sellgoodr CAN (6 Accounts, 3 Contacts, 3 Leads); after the move they are Specialty + Sellgoodr CAN, and users editing them hit an invalid dependent value.', 'Medium', 'Add Sellgoodr CAN under Specialty in the Sector dependency on all 4 objects, or clear Sector on those 12 records.', 'Before removal'),
    @('Custom Metadata', 'Account', 'Sales_Channel_Cluster: SpecialtyCANAcc', "Rule_Condition__c = Sales_Channel__c = 'Specialty CAN' && Sector__c = 'Sellgoodr CAN'", 'Sets Cluster 6.', 'Dead rule. Moved records keep their current Cluster__c (no other rule matches Specialty + Sellgoodr CAN).', 'Low', "Delete. Optional: add Specialty && Sector__c = 'Sellgoodr CAN' -> Cluster 6.", 'After removal'),
    @('Custom Metadata', 'Lead', 'Sales_Channel_Cluster: SpecialtyCANLead', 'same condition', 'Sets Cluster 6.', 'Dead rule.', 'Low', 'Delete.', 'After removal'),
    @('Custom Metadata', 'Opportunity', 'Sales_Channel_Cluster: SpecialtyCAN_Opp', 'same condition', 'Sets Cluster 6.', 'Dead rule.', 'Low', 'Delete.', 'After removal'),
    @('Custom Metadata', 'Account', 'Sales_Channel_Cluster: SpecialtyCAN_Bridge_Account', "Sales_Channel__c = 'Specialty CAN' && Sector__c = 'Bridge'", 'Sets Cluster 5.', 'Dead rule. Moved Bridge records match Specialty_Bridge_Account instead (same Cluster 5).', 'Low', 'Delete.', 'After removal'),
    @('Custom Metadata', 'Lead', 'Sales_Channel_Cluster: SpecialtyCAN_Bridge_Lead', 'same condition', 'Sets Cluster 5.', 'Dead rule. Covered by Specialty_Bridge_Lead.', 'Low', 'Delete.', 'After removal'),
    @('Custom Metadata', 'Opportunity', 'Sales_Channel_Cluster: SpecialtyCAN_Bridge_Opportunity', 'same condition', 'Sets Cluster 5.', 'Dead rule. Covered by Specialty_Bridge_Opp.', 'Low', 'Delete.', 'After removal'),
    @('Custom Metadata', 'Contact', 'Sales_Channel_Cluster: SpecialtyCAN_Contact, SpecialtyCAN_Bridge_Contact', 'ObjectAPIName__c = Contact', 'Never evaluated (ClusterRuleEngine line 9 skips Contact).', 'None.', 'Info', 'Delete (cleanup).', 'After removal'),
    @('Lightning Page', 'Account', 'Account_Company_Record_Page: sections Specialty - Sellgoodr, Specialty - Bridge', 'Visibility filter criterion 3: SC = Specialty CAN', 'Shows the Specialty sections for Specialty CAN accounts.', 'None for moved records: they match criterion 1 (SC = Specialty) and see the same section.', 'Low', 'Remove criterion 3.', 'With / after removal'),
    @('Lightning Page', 'Lead', 'Lead_Record_Page: sections Specialty - Sellgoodr, Specialty - Bridge', 'Visibility filter criterion 3: SC = Specialty CAN', 'Same as Account.', 'None for moved records.', 'Low', 'Remove criterion 3.', 'With / after removal'),
    @('Lightning Page', 'Lead', 'Lead_Record_Page: Convert button', 'Criterion 2: SC <> Specialty CAN', 'Hides Convert for Specialty CAN leads.', 'None: moved leads are Specialty and stay hidden by criterion 1.', 'Low', 'Remove criterion 2.', 'With / after removal'),
    @('List View', 'Account', 'All Accounts (AllAccounts)', 'Filter: Sales_Channel__c equals Specialty, Specialty CAN', 'Includes Specialty CAN accounts.', 'None for moved records (they match Specialty).', 'Low', 'Remove Specialty CAN from the filter.', 'With / after removal'),
    @('Apex (Shopify)', 'Account, Contact, Lead', 'ShopifyConfigService.cls', "lines 26, 35: channelName = 'Specialty CAN'", 'Name of the Shopify_Configuration__c record for the Canada store, chosen by country (CA / CAN / CANADA).', 'None. Canada routing uses the address country, not Sales Channel.', 'Info', "Do NOT rename or delete the Shopify_Configuration__c record named 'Specialty CAN'.", 'n/a'),
    @('Apex (Shopify)', 'Lead', 'LeadConversionService.cls', 'line 729: getConfigByCountry(lead.CountryCode)', 'Shopify duplicate-email check on conversion.', 'None (country-based).', 'Info', 'None.', 'n/a'),
    @('Apex (Shopify)', 'Account', 'AccountTriggerHandler.cls', 'lines 80-125', 'Pushes Active / Inactive to Shopify.', 'Fires only when Active__c changes, so updating Sales Channel on 670 accounts makes no Shopify callouts.', 'Info', 'None.', 'n/a'),
    @('Apex (Shopify)', 'Account, Contact', '13 Shopify classes that read Sales_Channel__c', 'see Impact Register', 'Pass the channel into ShopifyAssociationInput; routing uses the country.', 'None.', 'Info', 'None.', 'n/a'),
    @('Apex', 'All objects', 'ClusterTeamEngine.cls', 'lines 27-35', 'Assigns team members by Cluster_Value__c.', 'None. No Account_Cluster_Team record uses Specialty CAN.', 'Info', 'None.', 'n/a'),
    @('Apex Test', 'Test', 'ShopifyContactIntegrationTest.cls (277, 299); AccountTriggerHelperTest.cls (19)', 'Shopify config name / log message text', "'Specialty CAN' as a config record Name, not a picklist value.", 'None.', 'Info', 'None.', 'n/a'),
    @('Auto-Response Rule', 'Case', 'Case auto-response: First_Reply_Specialty_Inbounds_CAN template', 'lines 14-48', 'Criteria on Case.Origin only.', 'None.', 'Info', 'None.', 'n/a')
)
$rows = @(); $i = 1; foreach ($c in $can) { $rows += , (@(('CAN-{0:00}' -f $i)) + $c + @('Not Started', '', '')); $i++ }
$canHdr = 'ID', 'Area', 'Object', 'Component', 'Location / Line', 'How Specialty CAN Is Used', 'Impact When Removed', 'Severity', 'Action', 'When', 'Status', 'Verified By', 'Notes'
[void](Write-Table $ws 5 $canHdr $rows @(9, 18, 18, 36, 34, 40, 48, 10, 40, 18, 12, 14, 24))
$canLast = 5 + $rows.Count
Color-Sev $ws 8 6 $canLast
$ws.Range("K6", "M$canLast").Interior.Color = (RGB 255 255 204)
$v = $ws.Range("K6", "K$canLast").Validation; $v.Delete(); $v.Add(3, 1, 1, 'Not Started,In Progress,Done,N/A')
$ws.Range("A5", "M$canLast").AutoFilter() | Out-Null

$b = $canLast + 2
$ws.Cells.Item($b, 1).Value2 = 'B. What fires when the records are updated from Specialty CAN to Specialty'; $ws.Cells.Item($b, 1).Font.Bold = $true
$fire = @(
    @('ClusterRuleEngine (Account, Lead, Opportunity triggers)', 'Yes - Sales Channel changed', 'Bridge records re-match Specialty + Bridge = Cluster 5 (same as today). Sellgoodr CAN and blank-Sector records match no rule, so Cluster__c is left unchanged.', 'None. Spot-check Cluster__c after the load.'),
    @('AccountCascadeHandler (Account update)', 'Yes', 'Copies Cluster__c and Sales Channel to open Opportunities of these accounts and reassigns teams. No Opportunity has Specialty CAN today.', 'Check team members after the load.'),
    @('ContactTriggerHandler / LeadClusterTrigger', 'Yes', 'Reassigns record teams where Sales Channel changed (same cluster, so same team members).', 'None.'),
    @('Shopify integrations', 'No', 'The Shopify push fires only on an Active__c change. No callouts.', 'None.'),
    @('Lead_From_US_Retailer_Form flow', 'No', 'Runs only on Lead create with a Typeform mapping.', 'None.'),
    @('Restricted dependent picklist (legacy Sector)', 'n/a', 'Data Loader / API saves are not blocked by the dependency, but records with Sellgoodr CAN show an invalid dependent value in the UI.', 'Fix the dependency first (CAN-12).')
)
[void](Write-Table $ws ($b + 1) @('Automation', 'Fires?', 'Effect', 'Action') $fire @())

$cR = $b + 1 + $fire.Count + 2
$ws.Cells.Item($cR, 1).Value2 = 'C. Records to move (GDRSAND, 28 Sep 2026 - re-run in production)'; $ws.Cells.Item($cR, 1).Font.Bold = $true
$cnt = @(
    @('Specialty CAN', '(blank)', 665, 4, 4, 0, '', 'Specialty', 'Keep blank'),
    @('Specialty CAN', 'Sellgoodr CAN', 5, 2, 2, 0, '', 'Specialty', 'Keep (fix dependency) or clear'),
    @('Specialty CAN', 'Bridge', 0, 0, 2, 0, '', 'Specialty', 'Keep')
)
[void](Write-Table $ws ($cR + 1) @('Current Sales Channel', 'Current Sector', 'Account', 'Contact', 'Lead', 'Opportunity', 'Total', 'Target Sales Channel', 'Legacy Sector') $cnt @())
$t1 = $cR + 2; $t2 = $cR + 1 + $cnt.Count
for ($r = $t1; $r -le $t2; $r++) { $ws.Cells.Item($r, 7).Formula = "=SUM(C$($r):F$($r))" }
$ws.Cells.Item($t2 + 1, 1).Value2 = 'Total'; $ws.Cells.Item($t2 + 1, 1).Font.Bold = $true
foreach ($c in 3..7) { $L = ColL $c; $ws.Cells.Item($t2 + 1, $c).Formula = "=SUM($($L)$($t1):$($L)$t2)"; $ws.Cells.Item($t2 + 1, $c).Font.Bold = $true }
$canTotalCell = "G$($t2 + 1)"
$ws.Cells.Item($t2 + 2, 1).Value2 = 'Also check: 1 Account, 1 Contact and 1 Lead already have Specialty + Sellgoodr CAN (invalid pair today).'
$ws.Cells.Item($t2 + 2, 1).Font.Italic = $true

$d0 = $t2 + 4
$ws.Cells.Item($d0, 1).Value2 = 'D. Removal order'; $ws.Cells.Item($d0, 1).Font.Bold = $true
$steps = @(
    '1. Deploy the flow fix (Specialty CAN > Specialty) and the 2 test-class fixes together.',
    '2. Add Sellgoodr CAN under Specialty in the legacy Sector dependency on Account, Contact, Lead and Opportunity (or plan to clear Sector on those 12 records).',
    '3. Update 670 Accounts, 6 Contacts and 8 Leads from Specialty CAN to Specialty. Re-run the counts in production first.',
    '4. Spot-check Cluster__c and record teams on a sample of moved records.',
    '5. Deactivate Specialty CAN in the Sales_Channel and Sales_Channel1 value sets. Confirm the Canada form creates a lead end to end.',
    '6. Clean up: delete the 8 Specialty CAN cluster rules, and remove Specialty CAN from the 2 Lightning page filters and the AllAccounts list view.',
    '7. Delete the deactivated value once nothing references it.'
)
for ($j = 0; $j -lt $steps.Count; $j++) { $ws.Cells.Item($d0 + 1 + $j, 1).Value2 = $steps[$j] }
$ws.Range("A1", "M$($d0 + $steps.Count)").Font.Name = 'Arial'
$ws.Activate(); $xl.ActiveWindow.SplitRow = 5; $xl.ActiveWindow.SplitColumn = 0; $xl.ActiveWindow.FreezePanes = $true

# ------------------------------------------------------------------ Summary
$ws = $wb.Worksheets.Item('Summary')
Title $ws 'Sales Channel / Sector V2 change - impact summary' $src
$ws.Cells.Item(4, 1).Value2 = 'Components by object and severity (live counts from Impact Register)'; $ws.Cells.Item(4, 1).Font.Bold = $true
$objs = 'Account', 'Contact', 'Lead', 'Opportunity', 'Account, Contact, Opportunity', 'Account, Contact', 'All objects', 'Custom Metadata', 'Test', 'Case', 'Campaign Member', 'Product', 'N/A'
$sevs = 'Critical', 'High', 'Medium', 'Low', 'Info'
$hdr = @('Object') + $sevs + @('Total', 'Done')
$rows = @(); foreach ($o in $objs) { $rows += , (@($o) + @('') * 7) }
$rng = Write-Table $ws 5 $hdr $rows @(30, 11, 11, 11, 11, 11, 11, 11)
$r0 = 6; $r1 = 5 + $objs.Count
for ($r = $r0; $r -le $r1; $r++) {
    for ($c = 2; $c -le 6; $c++) { $ws.Cells.Item($r, $c).Formula = "=COUNTIFS('Impact Register'!`$B`$5:`$B`$$regLast,`$A$r,'Impact Register'!`$I`$5:`$I`$$regLast,$(ColL $c)`$5)" }
    $ws.Cells.Item($r, 7).Formula = "=SUM(B$($r):F$($r))"
    $ws.Cells.Item($r, 8).Formula = "=COUNTIFS('Impact Register'!`$B`$5:`$B`$$regLast,`$A$r,'Impact Register'!`$L`$5:`$L`$$regLast,""Done"")"
}
$tr = $r1 + 1
$ws.Cells.Item($tr, 1).Value2 = 'Total'; $ws.Cells.Item($tr, 1).Font.Bold = $true
foreach ($c in 2..8) { $L = ColL $c; $ws.Cells.Item($tr, $c).Formula = "=SUM($($L)$($r0):$($L)$r1)"; $ws.Cells.Item($tr, $c).Font.Bold = $true }
for ($c = 2; $c -le 6; $c++) { $ws.Cells.Item(5, $c).Interior.Color = $sevColor[$sevs[$c - 2]]; $ws.Cells.Item(5, $c).Font.Color = 0 }
$ws.Cells.Item($tr + 1, 1).Value2 = 'Check: rows in Impact Register'; $ws.Cells.Item($tr + 1, 7).Formula = "=COUNTA('Impact Register'!`$A`$5:`$A`$$regLast)"

$k = $tr + 3
$ws.Cells.Item($k, 1).Value2 = 'Key numbers'; $ws.Cells.Item($k, 1).Font.Bold = $true
$kp = @(
    @('Lightning page visibility filters on SC / Sector', "=COUNTA('LRP Visibility Rules'!`$A`$5:`$A`$15)"),
    @('...of which break or change behaviour (Critical/High)', "=COUNTIF('LRP Visibility Rules'!`$M`$5:`$M`$15,""Critical"")+COUNTIF('LRP Visibility Rules'!`$M`$5:`$M`$15,""High"")"),
    @('Cluster rules (33 existing + 6 proposed new)', "=COUNTA('Cluster Rules (CMDT)'!`$A`$5:`$A`$43)"),
    @('...to rewrite or create (Critical/High)', "=COUNTIF('Cluster Rules (CMDT)'!`$G`$5:`$G`$43,""Critical"")+COUNTIF('Cluster Rules (CMDT)'!`$G`$5:`$G`$43,""High"")"),
    @('Specialty CAN: Critical items (flow fix + records to move)', "=COUNTIF('Specialty CAN'!`$H`$6:`$H`$$canLast,""Critical"")"),
    @('Specialty CAN: records to move to Specialty', "='Specialty CAN'!$canTotalCell"),
    @('Apex test classes that will fail', "=COUNTIF('Apex Tests'!`$E`$5:`$E`$20,""High"")"),
    @('Records needing a Sales Channel update (all channels)', "='Data Volume'!`$G`$$($dvLast + 2)")
)
for ($j = 0; $j -lt $kp.Count; $j++) { $ws.Cells.Item($k + 1 + $j, 1).Value2 = $kp[$j][0]; $ws.Cells.Item($k + 1 + $j, 7).Formula = $kp[$j][1]; $ws.Cells.Item($k + 1 + $j, 7).NumberFormat = '#,##0'; $ws.Cells.Item($k + 1 + $j, 7).Font.Bold = $true }

$g = $k + $kp.Count + 2
$ws.Cells.Item($g, 1).Value2 = 'Severity legend'; $ws.Cells.Item($g, 1).Font.Bold = $true
$leg = @(
    @('Critical', 'Breaks or errors as soon as the old values are removed (failed saves, flow faults, no cluster for new Key Account records, hidden Key Account section).'),
    @('High', 'Silently wrong behaviour or blocks users/deployment (wrong section shown, dead rules, failing tests, value not selectable).'),
    @('Medium', 'Logic gap or missed processing that should be fixed with the change (Sector-only edits, blank channels, reports).'),
    @('Low', 'Reads or displays the field only - retest after the change.'),
    @('Info', 'Same word with a different meaning (queue, pricebook, campaign, config name) or unused component - no change.')
)
for ($j = 0; $j -lt $leg.Count; $j++) { $c1 = $ws.Cells.Item($g + 1 + $j, 1); $c1.Value2 = $leg[$j][0]; $c1.Interior.Color = $sevColor[$leg[$j][0]]; $c1.Font.Bold = $true; $ws.Cells.Item($g + 1 + $j, 2).Value2 = $leg[$j][1] }

$h = $g + $leg.Count + 2
$ws.Cells.Item($h, 1).Value2 = 'How to use this workbook'; $ws.Cells.Item($h, 1).Font.Bold = $true
$how = @(
    'Specialty CAN - everything affected by removing that one Sales Channel value, what fires during the data move, record counts and the removal order.',
    'Impact Register - master list of every component. Filter by Object / Severity. Update Status, Verified By, Verified On and Notes (yellow).',
    'LRP Visibility Rules - each section / button on a Lightning page whose visibility depends on Sales Channel or Sector, with fields inside and the proposed filter.',
    'Visibility Matrix - for existing, migrated and new records (Sales Channel + legacy Sector + Sector V2): which section shows with the current filters and with the proposed ones.',
    'Record Page Assignment - which Lightning pages use the fields and where each is activated.',
    'Cluster Rules / Cluster Team - custom metadata records to rewrite. Apex Tests - failing tests. Data Volume - records to migrate and the target mapping to confirm.',
    'Example: IMP row "Account_Company_Record_Page > Section: Key Account" - filter SC = Key Accounts - Critical - change to SC = Key Account - set Status to Done after retest.'
)
for ($j = 0; $j -lt $how.Count; $j++) { $ws.Cells.Item($h + 1 + $j, 1).Value2 = $how[$j] }
$ws.Range("A1", "H$($h + $how.Count)").Font.Name = 'Arial'
$ws.Columns.Item(1).ColumnWidth = 52

# finish
foreach ($s in $wb.Worksheets) { $s.PageSetup.Orientation = 2; $s.PageSetup.Zoom = $false; $s.PageSetup.FitToPagesWide = 1; $s.PageSetup.FitToPagesTall = $false }
$wb.Worksheets.Item('Summary').Activate()
$xl.ScreenUpdating = $true
$xl.CalculateFull()
if (Test-Path $out) { Remove-Item $out -Force -Confirm:$false }
$wb.SaveAs($out, 51)
# error scan
$errs = 0
foreach ($s in $wb.Worksheets) { $u = $s.UsedRange; foreach ($c in $u.Cells) { if ($c.HasFormula -and ($c.Text -match '^#')) { $errs++; "ERR $($s.Name)!$($c.Address(0,0)) $($c.Formula) -> $($c.Text)" } } }
"Formula errors: $errs"
$sum = $wb.Worksheets.Item('Summary')
for ($r = 5; $r -le 30; $r++) { $line = @(); for ($c = 1; $c -le 8; $c++) { $line += $sum.Cells.Item($r, $c).Text }; ($line -join ' | ') }
"Register rows: $($reg.Count)"
$wb.Close($false); $xl.Quit(); [Runtime.InteropServices.Marshal]::ReleaseComObject($xl) | Out-Null
"Saved $out"











