$ErrorActionPreference = 'Stop'
$sp = 'C:\Users\UTISLA~1\AppData\Local\Temp\claude\c--Microsoft-VS-Code-GDRSandbox\d08dd3dc-7817-4434-9679-5763d2940328\scratchpad'
$dir = "$sp\org\unpackaged\unpackaged\flexipages"
$fieldPat = 'Sales_Channel__c|Sector__c'; $rulePat = '.'
$rows = New-Object System.Collections.ArrayList
$pageFieldRows = New-Object System.Collections.ArrayList

function Get-Prop($ci, $name) {
    foreach ($p in $ci.componentInstanceProperties) { if ($p.name -eq $name) { return $p.value } }
    return $null
}
function Rule-Text($vr) {
    if (-not $vr) { return @('', '', '') }
    $crit = @(); $i = 1
    foreach ($c in $vr.criteria) {
        $l = $c.leftValue -replace '^\{!Record\.', '' -replace '\}$', '' -replace '^\{!', ''
        $crit += ("{0}) {1} {2} '{3}'" -f $i, $l, $c.operator, $c.rightValue); $i++
    }
    $bf = $vr.booleanFilter
    if (-not $bf) { $bf = if ($crit.Count -gt 1) { (1..$crit.Count) -join ' AND ' } else { '1' } }
    $vals = @($vr.criteria | Where-Object { $_.leftValue -match $fieldPat } | ForEach-Object { $_.rightValue }) | Select-Object -Unique
    return @($bf, ($crit -join "`n"), ($vals -join ', '))
}

foreach ($file in Get-ChildItem $dir -Filter *.flexipage) {
    [xml]$x = Get-Content $file.FullName -Raw
    $fp = $x.FlexiPage
    $page = $file.BaseName
    $obj = $fp.sobjectType; if (-not $obj) { $obj = '(none)' }
    $regions = @{}
    foreach ($r in $fp.flexiPageRegions) { $regions[$r.name] = $r }

    # field placement (does the page show the fields at all)
    foreach ($r in $fp.flexiPageRegions) { foreach ($it in $r.itemInstances) { if ($it.fieldInstance -and $it.fieldInstance.fieldItem -match $fieldPat) {
        [void]$pageFieldRows.Add([pscustomobject]@{ Page = $page; Object = $obj; Label = $fp.masterLabel; Field = ($it.fieldInstance.fieldItem -replace 'Record\.', '') })
    } } }

    # parent map: facet -> owning component label
    $owner = @{}
    foreach ($r in $fp.flexiPageRegions) { foreach ($it in $r.itemInstances) { $ci = $it.componentInstance; if ($ci) {
        foreach ($p in $ci.componentInstanceProperties) { if ($p.value -and $regions.ContainsKey($p.value)) {
            $lbl = Get-Prop $ci 'label'; if (-not $lbl) { $lbl = Get-Prop $ci 'title' }; if (-not $lbl) { $lbl = $ci.identifier }
            $owner[$p.value] = [pscustomobject]@{ Label = $lbl; Region = $r.name; Comp = $ci.componentName }
        } }
    } } }
    function Top-Section($regionName) {
        $chain = @(); $n = $regionName; $guard = 0
        while ($owner.ContainsKey($n) -and $guard -lt 10) { $o = $owner[$n]; if ($o.Comp -notmatch 'column$') { $chain += $o.Label }; $n = $o.Region; $guard++ }
        if ($chain.Count -eq 0) { return $regionName }
        [array]::Reverse($chain); return ($chain -join ' > ')
    }
    function Collect-Fields($regionName, $depth) {
        $out = @()
        if ($depth -gt 6 -or -not $regions.ContainsKey($regionName)) { return $out }
        foreach ($it in $regions[$regionName].itemInstances) {
            if ($it.fieldInstance) { $out += ($it.fieldInstance.fieldItem -replace 'Record\.', '') }
            if ($it.componentInstance) { foreach ($p in $it.componentInstance.componentInstanceProperties) { if ($p.value -and $regions.ContainsKey($p.value)) { $out += Collect-Fields $p.value ($depth + 1) } } }
        }
        return $out
    }

    foreach ($r in $fp.flexiPageRegions) {
        foreach ($it in $r.itemInstances) {
            $ci = $it.componentInstance; $fi = $it.fieldInstance
            if ($fi -and $fi.visibilityRule -and ($fi.visibilityRule.OuterXml -match $rulePat)) {
                $rt = Rule-Text $fi.visibilityRule
                [void]$rows.Add([pscustomobject]@{ Page = $page; Object = $obj; PageLabel = $fp.masterLabel; Type = 'Field'; Component = ($fi.fieldItem -replace 'Record\.', ''); Parent = (Top-Section $r.name); Contains = ''; Filter = $rt[0]; Criteria = $rt[1]; Values = $rt[2] })
            }
            if ($ci) {
                if ($ci.visibilityRule -and ($ci.visibilityRule.OuterXml -match $rulePat)) {
                    $lbl = Get-Prop $ci 'label'; if (-not $lbl) { $lbl = Get-Prop $ci 'title' }; if (-not $lbl) { $lbl = $ci.identifier }
                    $type = switch -regex ($ci.componentName) { 'fieldSection' { 'Section' } '^flexipage:tab$' { 'Tab' } 'relatedList' { 'Related List' } default { 'Component' } }
                    $contains = @(); foreach ($p in $ci.componentInstanceProperties) { if ($p.value -and $regions.ContainsKey($p.value)) { $contains += Collect-Fields $p.value 0 } }
                    $rt = Rule-Text $ci.visibilityRule
                    [void]$rows.Add([pscustomobject]@{ Page = $page; Object = $obj; PageLabel = $fp.masterLabel; Type = "$type ($($ci.componentName))"; Component = $lbl; Parent = (Top-Section $r.name); Contains = (($contains | Select-Object -Unique) -join ', '); Filter = $rt[0]; Criteria = $rt[1]; Values = $rt[2] })
                }
                foreach ($p in $ci.componentInstanceProperties) {
                    foreach ($vli in $p.valueList.valueListItems) {
                        if ($vli.visibilityRule -and ($vli.visibilityRule.OuterXml -match $rulePat)) {
                            $rt = Rule-Text $vli.visibilityRule
                            [void]$rows.Add([pscustomobject]@{ Page = $page; Object = $obj; PageLabel = $fp.masterLabel; Type = 'Button / Action'; Component = $vli.value; Parent = "$($ci.componentName) ($($p.name))"; Contains = ''; Filter = $rt[0]; Criteria = $rt[1]; Values = $rt[2] })
                        }
                    }
                }
            }
        }
    }
}
$rows | ConvertTo-Json -Depth 4 | Out-File "$sp\flexi_allrules.json" -Encoding utf8
$pageFieldRows | ConvertTo-Json -Depth 4 | Out-File "$sp\flexi_fields.json" -Encoding utf8
"rules: $($rows.Count); field placements: $($pageFieldRows.Count)"
$rows | Format-Table Page, Type, Component, Filter, Values -AutoSize | Out-String -Width 250

