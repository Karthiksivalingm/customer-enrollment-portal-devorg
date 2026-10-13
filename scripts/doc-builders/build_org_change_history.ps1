# Pulls the org's own change history into 04_Change_Records/Org_Change_History:
#   - deploys (DeployRequest, kept by Salesforce for ~30 days) and their components
#   - Setup Audit Trail (kept by Salesforce for 180 days)
# and writes a dated Markdown timeline. Re-run any time; it overwrites the generated files.
# Usage (repo root):  powershell -ExecutionPolicy Bypass -File scripts/doc-builders/build_org_change_history.ps1 [-Since 2026-08-01] [-UserLike 'sandipp@goodr.com%']
param([string]$Since = '2026-08-01', [string]$UserLike = 'sandipp@goodr.com%', [string[]]$Orgs = @('GDRSAND', 'GDRPROD'))
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$out = Join-Path $root '04_Change_Records\Org_Change_History'
New-Item -ItemType Directory -Force $out | Out-Null
function Q($org, $soql, [switch]$Tooling) {
  $a = @('data', 'query', '-o', $org, '-q', $soql, '--json'); if ($Tooling) { $a += '--use-tooling-api' }
  $r = & sf @a 2>$null | ConvertFrom-Json; if ($r.status -ne 0) { throw "$org query failed: $($r.message)" }; return @($r.result.records)
}
function LocalTime($d) { ([datetime]$d).ToString('yyyy-MM-dd HH:mm') }
$md = @("# Org Change History (generated)", "",
  "_Generated $(Get-Date -Format 'yyyy-MM-dd HH:mm') (local time) by ``scripts/doc-builders/build_org_change_history.ps1`` from each org's own records._",
  "_Sources: DeployRequest (Salesforce keeps it for about 30 days) and the Setup Audit Trail (180 days), filtered to user ``$UserLike`` since $Since._",
  "_Raw CSVs are in this folder. The narrative explanation of each change is in [../Change_Log.md](../Change_Log.md)._", "")
foreach ($org in $Orgs) {
  # ---- deploys ----
  $deps = Q $org "SELECT Id, Status, CheckOnly, CreatedDate, CompletedDate, CreatedBy.Name, NumberComponentsDeployed, NumberComponentErrors, NumberTestsCompleted, NumberTestErrors FROM DeployRequest WHERE CreatedDate >= ${Since}T00:00:00Z ORDER BY CreatedDate" -Tooling
  $depRows = $deps | ForEach-Object { [pscustomobject]@{ Date = LocalTime $_.CreatedDate; DeployId = $_.Id; Type = $(if ($_.CheckOnly) { 'Validation (check-only)' } else { 'Deploy' }); Status = $_.Status; Components = $_.NumberComponentsDeployed; ComponentErrors = $_.NumberComponentErrors; TestsRun = $_.NumberTestsCompleted; TestErrors = $_.NumberTestErrors; By = $_.CreatedBy.Name } }
  $depRows | Export-Csv "$out\${org}_deploys.csv" -NoTypeInformation -Encoding UTF8
  $comp = foreach ($d in ($depRows | Where-Object { $_.Type -eq 'Deploy' -and $_.Status -eq 'Succeeded' })) {
    $j = & sf project deploy report --job-id $d.DeployId -o $org --json 2>$null | ConvertFrom-Json
    foreach ($c in @($j.result.details.componentSuccesses)) {
      if (-not $c.componentType -or $c.fullName -eq 'package.xml') { continue }
      [pscustomobject]@{ Date = $d.Date; DeployId = $d.DeployId; Type = $c.componentType; Name = $c.fullName; Action = $(if ("$($c.created)" -eq 'true') { 'Created' } elseif ("$($c.deleted)" -eq 'true') { 'Deleted' } elseif ("$($c.changed)" -eq 'true') { 'Changed' } else { 'No change' }) }
    }
  }
  $comp | Export-Csv "$out\${org}_deploy_components.csv" -NoTypeInformation -Encoding UTF8
  # ---- setup audit trail ----
  $aud = Q $org "SELECT CreatedDate, CreatedBy.Username, Section, Action, Display, DelegateUser FROM SetupAuditTrail WHERE CreatedDate >= ${Since}T00:00:00Z AND CreatedBy.Username LIKE '$UserLike' ORDER BY CreatedDate"
  $audRows = $aud | ForEach-Object { [pscustomobject]@{ Date = LocalTime $_.CreatedDate; User = $_.CreatedBy.Username; Section = $_.Section; Action = $_.Action; Change = ($_.Display -replace '\s+', ' ') } }
  $audRows | Export-Csv "$out\${org}_setup_audit_trail.csv" -NoTypeInformation -Encoding UTF8
  # ---- markdown ----
  $md += "## $org", "", "Deploys: $(@($depRows | Where-Object Type -eq 'Deploy').Count) (succeeded $(@($depRows | Where-Object { $_.Type -eq 'Deploy' -and $_.Status -eq 'Succeeded' }).Count)) · validations: $(@($depRows | Where-Object Type -ne 'Deploy').Count) · Setup Audit Trail entries: $($audRows.Count)", ""
  $md += "### Deploys and validations", "", "| Date | Deploy ID | Type | Status | Components | Tests (errors) | Components deployed |", "|---|---|---|---|---|---|---|"
  foreach ($d in $depRows) {
    $names = @($comp | Where-Object DeployId -eq $d.DeployId | ForEach-Object { "$($_.Type):$($_.Name) ($($_.Action))" })
    $list = if ($names.Count -gt 8) { (($names | Select-Object -First 8) -join '<br>') + "<br>... +$($names.Count - 8) more (see CSV)" } else { $names -join '<br>' }
    $md += "| $($d.Date) | ``$($d.DeployId)`` | $($d.Type) | $($d.Status) | $($d.Components) | $($d.TestsRun) ($($d.TestErrors)) | $list |"
  }
  $md += "", "### Setup changes by day (Setup Audit Trail)", ""
  foreach ($g in ($audRows | Group-Object { $_.Date.Substring(0, 10) })) {
    $md += "#### $($g.Name)  ($($g.Count) entries)", ""
    $bySec = $g.Group | Group-Object Section
    foreach ($s in $bySec) {
      $items = @($s.Group)
      if ($items.Count -gt 12) { $md += "- **$($s.Name)**: $($items.Count) changes (e.g. $($items[0].Change.Substring(0, [Math]::Min(120, $items[0].Change.Length))) ...). Full list in CSV." }
      else { foreach ($i in $items) { $md += "- $($i.Date.Substring(11)) **$($s.Name)**: $($i.Change.Substring(0, [Math]::Min(300, $i.Change.Length)))" } }
    }
    $md += ""
  }
}
[IO.File]::WriteAllText("$out\Org_Change_History.md", ($md -join "`n") + "`n", (New-Object Text.UTF8Encoding($false)))
"Written to $out"
