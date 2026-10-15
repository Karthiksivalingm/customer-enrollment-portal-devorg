# Deployment Commands (Salesforce CLI `sf`)

The org alias used in this project is `EverquotefullSandbox`. Replace `<target>` with the alias of the org you're deploying to.

## Authorise an org
```bash
sf org login web -a <alias> -r https://test.salesforce.com   # sandbox
sf org login web -a <alias> -r https://login.salesforce.com  # production
sf org list
```

## Retrieve (backup or refresh from the org)
```bash
sf project retrieve start -x manifest/package.xml -o EverquotefullSandbox
sf project retrieve start -m ApexClass:LeadTriggerHandler -m ApexTrigger:LeadTrigger -o EverquotefullSandbox
sf project retrieve start -m "Flow:Case_Move_to_Smart_Campaign_Queue" -o EverquotefullSandbox
```
`manifest/package.xml` only covers Apex classes, triggers, pages and components, static resources, and Aura and LWC bundles. Flows, workflows, permission sets, profiles and queues must be named explicitly or added to a manifest.

## Validate (no changes made to the org)
```bash
sf project deploy validate -x manifest/<release>.xml -o <target> -l RunSpecifiedTests -t LeadTriggerTest -t TriggerHandlerTest
```

## Quick deploy a successful validation
```bash
sf project deploy quick --job-id <validationId> -o <target>
```

## Deploy
```bash
sf project deploy start -x manifest/<release>.xml -o <target> -l RunSpecifiedTests -t <TestClass>
sf project deploy report --job-id <deployId> -o <target>
```

## Run tests
```bash
sf apex run test -n LeadTriggerTest -n TriggerHandlerTest -o <target> -c -r human -w 20
sf apex run test -l RunLocalTests -o <target> -c -r human -w 60
```

## Scheduled jobs (before and after deploying scheduled or batch classes)
```bash
sf data query -o <target> -q "SELECT Id, CronJobDetail.Name, CronExpression, NextFireTime FROM CronTrigger WHERE State = 'WAITING'"
```
Abort the jobs under **Setup → Scheduled Jobs**, deploy, then re-schedule them with anonymous Apex using the cron expressions you recorded. Each job's schedule is listed in [Batches-and-Schedulers](../07-Technical-Documents/Apex-Classes/).

## Destructive changes (deleting components)
Create `manifest/destructiveChanges.xml` alongside an empty `package.xml`, then run:
```bash
sf project deploy start -x manifest/package.xml --post-destructive-changes manifest/destructiveChanges.xml -o <target>
```
Deletion needs explicit approval and a change record.
