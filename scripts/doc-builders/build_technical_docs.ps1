# Generates the inventory files in 07_Technical_Documents from force-app/main/default.
# Run from the repo root:  powershell -File scripts/doc-builders/build_technical_docs.ps1
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$src = Join-Path $root 'force-app\main\default'
$out = Join-Path $root '07_Technical_Documents'
$today = Get-Date -Format 'yyyy-MM-dd'
function Esc($s) { if ($null -eq $s) { return '' }; return ($s -replace '\|', '\|' -replace '\r?\n', ' ').Trim() }
function Write-Md($name, $lines) { [IO.File]::WriteAllText((Join-Path $out $name), ($lines -join "`n") + "`n", (New-Object Text.UTF8Encoding($false))) }
function Area($n) {
  switch -Regex ($n) {
    '^(Cluster|AccountCascade|ContactTeam)' { 'Cluster & Team' ; break }
    '^Shopify|^BackfillLastShopify|^ExternalStore|^SendWarmOff' { 'Shopify integration' ; break }
    '^NetSuite' { 'NetSuite integration' ; break }
    '^(TypeForm|Typeform)' { 'Typeform integration' ; break }
    '^Zendesk' { 'Zendesk integration' ; break }
    '^Case|^EmailMessage|^AutomatedTask|^DeleteAutomated' { 'Case management / Service' ; break }
    '^Lead|^ConversionContext' { 'Lead' ; break }
    '^(Account|Contact|AddressDuplicate|CountryTo|StateTo)' { 'Account / Contact' ; break }
    '^(API|Api)Log' { 'API logging' ; break }
    '^(Winback|CategoryRevenue|PurchaseOrder|Content)' { 'Sales ops / Files' ; break }
    'Communities|Site|Password|Login|SelfReg|MyProfile|Microbatch' { 'Experience Cloud (standard)' ; break }
    default { 'Other' }
  }
}

# ---------- Apex classes ----------
$classes = Get-ChildItem "$src\classes\*.cls" | Sort-Object Name
$names = $classes | ForEach-Object { $_.BaseName }
$rows = foreach ($f in $classes) {
  $t = Get-Content $f.FullName -Raw; $n = $f.BaseName
  $isTest = $t -match '@isTest|@IsTest|testMethod'
  $kind = @()
  if ($t -match '@RestResource') { $kind += 'REST API' }
  if ($t -match 'Database\.Batchable') { $kind += 'Batch' }
  if ($t -match 'implements[^{]*Queueable') { $kind += 'Queueable' }
  if ($t -match 'implements[^{]*Schedulable') { $kind += 'Schedulable' }
  if ($t -match '@InvocableMethod') { $kind += 'Invocable (Flow)' }
  if ($t -match '@AuraEnabled') { $kind += 'LWC/Aura controller' }
  if ($t -match 'AllowsCallouts|HttpRequest') { $kind += 'Callout' }
  if (-not $kind) { $kind = @($(if ($n -match 'Handler$|TriggerHelper$') { 'Trigger handler' } elseif ($n -match 'Helper$') { 'Helper' } elseif ($n -match 'Service|Engine') { 'Service' } elseif ($n -match 'Controller') { 'Controller' } else { 'Class' })) }
  $objs = [regex]::Matches($t, '(?is)\[\s*SELECT\b[^\]]*?\bFROM\s+(\w+)') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
  $calls = [regex]::Matches($t, 'callout:([A-Za-z0-9_]+)') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
  $methods = [regex]::Matches($t, '(?m)^\s*(?:@\w+(?:\([^)]*\))?\s*)*(?:global|public)\s+(?:static\s+)?(?:override\s+)?[\w<>,\s\.]+?\s+(\w+)\s*\(') | ForEach-Object { $_.Groups[1].Value } | Where-Object { $_ -ne $n } | Select-Object -Unique -First 6
  $test = @("${n}Test", "${n}_Test", "Test${n}") | Where-Object { $names -contains $_ } | Select-Object -First 1
  [pscustomobject]@{ Name = $n; Test = $isTest; Area = (Area $n); Kind = ($kind -join ', '); Objects = ($objs -join ', '); Callouts = ($calls -join ', '); Methods = ($methods -join ', '); TestClass = $test; Lines = ($t -split "`n").Count; Api = ([regex]::Match((Get-Content "$($f.FullName)-meta.xml" -Raw), '<apiVersion>([^<]+)')).Groups[1].Value }
}
$main = $rows | Where-Object { -not $_.Test }; $tests = $rows | Where-Object { $_.Test }
$L = @("# Apex Classes", "", "_Generated $today from ``force-app/main/default/classes`` by ``scripts/doc-builders/build_technical_docs.ps1``._", "",
  "$($main.Count) classes + $($tests.Count) test classes. **Kind**, **Objects** (SOQL ``FROM``) and **Callouts** are read from the code.", "")
foreach ($g in ($main | Group-Object Area | Sort-Object Name)) {
  $L += "## $($g.Name)", "", "| Class | Kind | Objects queried | Named credential | Main methods | Test class | Lines |", "|---|---|---|---|---|---|---|"
  foreach ($r in $g.Group) { $L += "| ``$($r.Name)`` | $($r.Kind) | $(Esc $r.Objects) | $($r.Callouts) | $(Esc $r.Methods) | $($r.TestClass) | $($r.Lines) |" }
  $L += ""
}
$L += "## Test classes", "", ($tests | ForEach-Object { "``$($_.Name)``" }) -join ' - '
Write-Md 'Apex_Classes.md' $L

# ---------- Triggers ----------
$L = @("# Apex Triggers", "", "_Generated $today._ Watch for objects that have more than one trigger, because Salesforce doesn't guarantee the order they run in.", "", "| Trigger | Object | Events | Calls |", "|---|---|---|---|")
foreach ($f in Get-ChildItem "$src\triggers\*.trigger" | Sort-Object Name) {
  $t = Get-Content $f.FullName -Raw; $flat = $t -replace '\s+', ' '
  $m = [regex]::Match($flat, 'trigger\s+(\w+)\s+on\s+(\w+)\s*\(([^)]*)\)')
  $calls = [regex]::Matches($t, '\b([A-Z]\w+)\.\w+\s*\(') | ForEach-Object { $_.Groups[1].Value } | Where-Object { $names -contains $_ } | Sort-Object -Unique
  $L += "| ``$($m.Groups[1].Value)`` | $($m.Groups[2].Value) | $($m.Groups[3].Value.Trim()) | $($calls -join ', ') |"
}
Write-Md 'Apex_Triggers.md' $L

# ---------- Flows ----------
$L = @("# Flows", "", "_Generated $today from ``force-app/main/default/flows``._", "", "| Flow (API name) | Label | Type | Object | Trigger | Status | Description |", "|---|---|---|---|---|---|---|")
foreach ($f in Get-ChildItem "$src\flows\*.flow-meta.xml" | Sort-Object Name) {
  [xml]$x = Get-Content $f.FullName -Raw; $fl = $x.Flow
  $st = $fl.start; $trig = (@($st.triggerType, $st.recordTriggerType) | Where-Object { $_ }) -join ' / '
  $L += "| ``$($f.Name -replace '\.flow-meta\.xml$','')`` | $(Esc $fl.label) | $($fl.processType) | $($st.object) | $trig | **$($fl.status)** | $(Esc $fl.description) |"
}
Write-Md 'Flows.md' $L

# ---------- Fields & custom metadata ----------
$L = @("# Fields and Custom Metadata", "", "_Generated $today._ This project only tracks the objects and fields that were changed or used during the Sales Channel / Sector work. Retrieve more objects from the org to extend this list.", "")
foreach ($od in Get-ChildItem "$src\objects" -Directory) {
  $L += "## $($od.Name)", "", "| Field | Label | Type | Length | Help text / description |", "|---|---|---|---|---|"
  foreach ($ff in Get-ChildItem "$($od.FullName)\fields\*.xml" -ErrorAction SilentlyContinue) {
    [xml]$x = Get-Content $ff.FullName -Raw; $cf = $x.CustomField
    $L += "| ``$($cf.fullName)`` | $(Esc $cf.label) | $($cf.type) | $($cf.length) | $(Esc ((@($cf.inlineHelpText, $cf.description) | Where-Object { $_ }) -join ' / ')) |"
  }
  $L += ""
}
$L += "## Custom metadata records", "", "| Type | Records | Purpose |", "|---|---|---|"
$purpose = @{ 'Sales_Channel_Cluster' = 'Cluster rules: Rule_Condition__c (e.g. Sales_Channel__c = ''Specialty'' && Sector__c = ''Self Service'') -> Cluster_Value__c, per ObjectAPIName__c. Read by ClusterRuleEngine.'
  'Account_Cluster_Team' = 'Team members per cluster and object: Team_Role__c, User_Identifier__c, Access_Level__c. Read by ClusterTeamEngine.'
  'Case_Queue_Team_Routing' = 'Case queue -> case team routing.'; 'SLA_Configuration' = 'Case SLA targets.'
  'NetSuite_Config' = 'NetSuite OAuth 2.0 settings. **Secret fields are not stored in git.**'; 'NetSuite_Credential' = 'NetSuite TBA credentials. **Not stored in git.**'
  'Shopify_At_Risk_Config' = 'At-risk / offboarding thresholds, email template, org-wide email.' }
Get-ChildItem "$src\customMetadata\*.md-meta.xml" | Group-Object { $_.Name.Split('.')[0] } | Sort-Object Name | ForEach-Object { $L += "| ``$($_.Name)__mdt`` | $($_.Count) | $($purpose[$_.Name]) |" }
$L += "", "## Sales Channel -> Cluster rules (Sales_Channel_Cluster__mdt)", "", "| Record | Object | Rule condition | Cluster |", "|---|---|---|---|"
foreach ($ff in Get-ChildItem "$src\customMetadata\Sales_Channel_Cluster.*.md-meta.xml" | Sort-Object Name) {
  [xml]$x = Get-Content $ff.FullName -Raw; $v = @{}; foreach ($val in $x.CustomMetadata.values) { $v[$val.field] = $val.value.'#text' }
  $L += "| ``$($ff.Name.Split('.')[1])`` | $($v['ObjectAPIName__c']) | ``$(Esc $v['Rule_Condition__c'])`` | $($v['Cluster_Value__c']) |"
}
Write-Md 'Fields_and_Custom_Metadata.md' $L

# ---------- UI components ----------
$L = @("# UI Components", "", "_Generated $today._", "", "## Lightning record pages (FlexiPages)", "", "| Page | Type | Object | Visibility rules |", "|---|---|---|---|")
foreach ($ff in Get-ChildItem "$src\flexipages\*.xml" | Sort-Object Name) {
  $t = Get-Content $ff.FullName -Raw
  $L += "| ``$($ff.Name -replace '\.flexipage-meta\.xml$','')`` | $([regex]::Match($t,'<type>([^<]+)</type>\s*</FlexiPage>|<type>(\w+Page)</type>').Value -replace '<[^>]+>|\s','') | $([regex]::Match($t,'<sobjectType>([^<]+)').Groups[1].Value) | $([regex]::Matches($t,'<visibilityRule>').Count) |"
}
$L += "", "## Lightning Web Components", "", ((Get-ChildItem "$src\lwc" -Directory | ForEach-Object { "- ``$($_.Name)``" }) -join "`n")
$L += "", "## Aura components", "", ((Get-ChildItem "$src\aura" -Directory | ForEach-Object { "- ``$($_.Name)``" }) -join "`n")
$L += "", "## Visualforce pages", "", ((Get-ChildItem "$src\pages\*.page" | ForEach-Object { "- ``$($_.BaseName)``" }) -join "`n")
Write-Md 'UI_Components.md' $L
"done: $($main.Count) classes, $($tests.Count) tests"
