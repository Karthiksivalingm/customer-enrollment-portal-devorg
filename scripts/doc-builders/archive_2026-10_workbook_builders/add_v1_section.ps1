$ErrorActionPreference = 'Stop'
$loc = 'C:\Microsoft VS Code\GDRSandbox\force-app\main\default\flexipages'
$enc = New-Object System.Text.UTF8Encoding($false)
function Esc($s) { return [Security.SecurityElement]::Escape($s) }
$html = '<p><strong style="font-size: 14px; color: rgb(194, 57, 52);">DATA MIGRATION BACKUP - TESTING ONLY</strong></p>' +
 '<p><em>Temporary section, visible to System Administrators only. It will be removed after testing.</em></p>' +
 '<ul>' +
 '<li><strong>Sales Channel V1 / Sector V1</strong> keep the ORIGINAL values from before the 2026 Sales Channel / Sector transition (backup for audit and rollback).</li>' +
 '<li><strong>Step 1:</strong> Copy the current Sales Channel and Sector of this record into Sales Channel V1 and Sector V1 BEFORE changing anything.</li>' +
 '<li><strong>Step 2:</strong> Update Sector (and Sales Channel where mapped) to the new value: Sellgoodr USA &rarr; Self Service; Bridge &rarr; Planned; Core &rarr; Enterprise; Mid-Market &rarr; Strategic or Development (to be confirmed); Off-Price &rarr; Discount; Global &rarr; Distributor; Specialty CAN + Sellgoodr CAN &rarr; Specialty + Self Service; Specialty CAN + Bridge &rarr; Specialty + Planned.</li>' +
 '<li><strong>Do not change V1 again</strong> once it is filled - it is the backup used to restore the old value.</li>' +
 '<li>Cluster and team recalculate only when <strong>Sales Channel</strong> changes; a Sector-only change keeps the current cluster.</li>' +
 '</ul>'
$vis = "                <visibilityRule>`n                    <criteria>`n                        <leftValue>{!`$User.Profile.Name}</leftValue>`n                        <operator>EQUAL</operator>`n                        <rightValue>System Administrator</rightValue>`n                    </criteria>`n                </visibilityRule>`n"
foreach ($n in 'Account_Company_Record_Page', 'Account_Store_Location_Record_Page1', 'Account_Franchise_Record_Page1') {
  $p = "$loc\$n.flexipage-meta.xml"; $t = [IO.File]::ReadAllText($p)
  if ($t -match 'Sales_Channel_V1__c') { "SKIP $n (already has V1)"; continue }
  [xml]$x = $t
  # region that holds the section containing Sector__c
  $sectorFacet = ($x.FlexiPage.flexiPageRegions | ? { $_.itemInstances.fieldInstance.fieldItem -contains 'Record.Sector__c' }).name
  $colComp = $x.FlexiPage.flexiPageRegions | ? { $_.itemInstances.componentInstance.componentInstanceProperties.value -contains $sectorFacet }
  $secRegion = ($x.FlexiPage.flexiPageRegions | ? { $_.itemInstances.componentInstance.componentInstanceProperties.value -contains $colComp.name })
  $secName = (($secRegion.itemInstances.componentInstance | ? { ($_.componentInstanceProperties | ? { $_.name -eq 'columns' }).value -eq $colComp.name }).componentInstanceProperties | ? { $_.name -eq 'label' }).value
  $region = $secRegion.name
  $g = @(); 1..4 | % { $g += 'Facet-' + [guid]::NewGuid().ToString() }   # columns, col1 body, col2 body
  $sec = "        <itemInstances>`n            <componentInstance>`n                <componentInstanceProperties>`n                    <name>decorate</name>`n                    <value>true</value>`n                </componentInstanceProperties>`n                <componentInstanceProperties>`n                    <name>richTextValue</name>`n                    <value>$(Esc $html)</value>`n                </componentInstanceProperties>`n                <componentName>flexipage:richText</componentName>`n                <identifier>flexipage_richText_V1Backup</identifier>`n$vis            </componentInstance>`n        </itemInstances>`n" +
         "        <itemInstances>`n            <componentInstance>`n                <componentInstanceProperties>`n                    <name>columns</name>`n                    <value>$($g[0])</value>`n                </componentInstanceProperties>`n                <componentInstanceProperties>`n                    <name>horizontalAlignment</name>`n                    <value>false</value>`n                </componentInstanceProperties>`n                <componentInstanceProperties>`n                    <name>label</name>`n                    <value>Data Migration Backup (Testing)</value>`n                </componentInstanceProperties>`n                <componentName>flexipage:fieldSection</componentName>`n                <identifier>flexipage_fieldSection_V1Backup</identifier>`n$vis            </componentInstance>`n        </itemInstances>`n"
  $facets = "    <flexiPageRegions>`n        <itemInstances>`n            <fieldInstance>`n                <fieldInstanceProperties>`n                    <name>uiBehavior</name>`n                    <value>none</value>`n                </fieldInstanceProperties>`n                <fieldItem>Record.Sales_Channel_V1__c</fieldItem>`n                <identifier>RecordSales_Channel_V1_cField</identifier>`n            </fieldInstance>`n        </itemInstances>`n        <name>$($g[1])</name>`n        <type>Facet</type>`n    </flexiPageRegions>`n" +
            "    <flexiPageRegions>`n        <itemInstances>`n            <fieldInstance>`n                <fieldInstanceProperties>`n                    <name>uiBehavior</name>`n                    <value>none</value>`n                </fieldInstanceProperties>`n                <fieldItem>Record.Sector_V1__c</fieldItem>`n                <identifier>RecordSector_V1_cField</identifier>`n            </fieldInstance>`n        </itemInstances>`n        <name>$($g[2])</name>`n        <type>Facet</type>`n    </flexiPageRegions>`n" +
            "    <flexiPageRegions>`n        <itemInstances>`n            <componentInstance>`n                <componentInstanceProperties>`n                    <name>body</name>`n                    <value>$($g[1])</value>`n                </componentInstanceProperties>`n                <componentName>flexipage:column</componentName>`n                <identifier>flexipage_column_V1Backup1</identifier>`n            </componentInstance>`n        </itemInstances>`n        <itemInstances>`n            <componentInstance>`n                <componentInstanceProperties>`n                    <name>body</name>`n                    <value>$($g[2])</value>`n                </componentInstanceProperties>`n                <componentName>flexipage:column</componentName>`n                <identifier>flexipage_column_V1Backup2</identifier>`n            </componentInstance>`n        </itemInstances>`n        <name>$($g[0])</name>`n        <type>Facet</type>`n    </flexiPageRegions>`n"
  # insert the two items right after the Sales Channel / Sector section inside its region
  $secCompXml = [regex]::Match($t, "(?s)<itemInstances>\s*<componentInstance>\s*<componentInstanceProperties>\s*<name>columns</name>\s*<value>$([regex]::Escape($colComp.name))</value>.*?</itemInstances>\s*")
  if (-not $secCompXml.Success) { throw "section not found in $n" }
  $t2 = $t.Substring(0, $secCompXml.Index + $secCompXml.Length) + $sec + $t.Substring($secCompXml.Index + $secCompXml.Length)
  $lastRegion = $t2.LastIndexOf('</flexiPageRegions>') + '</flexiPageRegions>'.Length
  $t2 = $t2.Substring(0, $lastRegion) + "`n" + $facets.TrimEnd("`n") + $t2.Substring($lastRegion)
  [IO.File]::WriteAllText($p, $t2, $enc); [xml]$chk = $t2
  "{0}: added after section '{1}' (region {2}); XML valid; V1 fields={3}" -f $n, $secName, $region, ([regex]::Matches($t2, '_V1__c</fieldItem>')).Count
}
