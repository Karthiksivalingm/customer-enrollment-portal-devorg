public class AgentScorecardBatch
    implements Database.Batchable<SObject> {

    // ─────────────────────────────────────────────
    // START
    // ─────────────────────────────────────────────
    public Database.QueryLocator start(
        Database.BatchableContext bc
    ) {

        return Database.getQueryLocator([

            SELECT Id,
                   Name,
                   Agent_Status__c

            FROM Contact

            WHERE Agent_Status__c = 'Active'
            AND Email != null
            
        ]);
    }

    // ─────────────────────────────────────────────
    // EXECUTE
    // ─────────────────────────────────────────────
    public void execute(
        Database.BatchableContext bc,
        List<Contact> scope
    ) {

        Set<Id> contactIds =
            new Set<Id>();

        for (Contact con : scope) {

            contactIds.add(con.Id);
        }

        // ─────────────────────────────────────────
        // ACTIVE POLICIES
        // ─────────────────────────────────────────
        Map<Id, Integer> activePolicies =
            new Map<Id, Integer>();

        for (AggregateResult ar : [

            SELECT Agent__c agentId,
                   COUNT(Id) total

            FROM Upline_Policy__c

            WHERE Agent__c IN :contactIds
            AND Status__c = 'Active'

            GROUP BY Agent__c
        ]) {

            activePolicies.put(
                (Id) ar.get('agentId'),
                (Integer) ar.get('total')
            );
        }

        // ─────────────────────────────────────────
        // DISENROLLED LAST 12 MONTHS
        // ─────────────────────────────────────────
        Map<Id, Integer> disenrolledPolicies =
            new Map<Id, Integer>();

        for (AggregateResult ar : [

            SELECT Agent__c agentId,
                   COUNT(Id) total

            FROM Upline_Policy__c

            WHERE Agent__c IN :contactIds
            AND Status__c = 'Disenrolled'
            AND LastModifiedDate = LAST_N_MONTHS:12

            GROUP BY Agent__c
        ]) {

            disenrolledPolicies.put(
                (Id) ar.get('agentId'),
                (Integer) ar.get('total')
            );
        }

        // ─────────────────────────────────────────
        // PERIOD PRODUCTION
        // ─────────────────────────────────────────
        Map<Id, Integer> periodProduction =
            new Map<Id, Integer>();

        for (AggregateResult ar : [

            SELECT Agent__c agentId,
                   COUNT(Id) total

            FROM Upline_Policy__c

            WHERE Agent__c IN :contactIds
            AND CreatedDate = THIS_MONTH

            GROUP BY Agent__c
        ]) {

            periodProduction.put(
                (Id) ar.get('agentId'),
                (Integer) ar.get('total')
            );
        }

        // ─────────────────────────────────────────
        // PERIOD COMMISSIONS
        // ─────────────────────────────────────────
        Map<Id, Decimal> commissions =
            new Map<Id, Decimal>();

        for (AggregateResult ar : [

            SELECT Agent__c agentId,
                   SUM(Net_Amount__c) total

            FROM Commission_Record__c

            WHERE Agent__c IN :contactIds
            AND Payment_Date__c = THIS_MONTH

            GROUP BY Agent__c
        ]) {

            commissions.put(
                (Id) ar.get('agentId'),
                (Decimal) ar.get('total')
            );
        }

        // ─────────────────────────────────────────
        // ACTIVE RTS APPOINTMENTS
        // ─────────────────────────────────────────
        Map<Id, Integer> activeAppointments =
            new Map<Id, Integer>();

        for (AggregateResult ar : [

            SELECT Agent__c agentId,
                   COUNT(Id) total

            FROM Appointment__c

            WHERE Agent__c IN :contactIds
            AND Status__c = 'Active RTS'

            GROUP BY Agent__c
        ]) {

            activeAppointments.put(
                (Id) ar.get('agentId'),
                (Integer) ar.get('total')
            );
        }

        // ─────────────────────────────────────────
        // AVAILABLE CARRIERS
        // ─────────────────────────────────────────
        Integer totalAvailableCarriers = [

            SELECT COUNT()

            FROM Carrier__c

            WHERE Active__c = true
        ];

        // ─────────────────────────────────────────
        // UPDATE CONTACTS
        // ─────────────────────────────────────────
        List<Contact> updates =
            new List<Contact>();

        for (Contact con : scope) {

            Integer activeCount =
                activePolicies.containsKey(con.Id)
                ? activePolicies.get(con.Id)
                : 0;

            Integer disenrolledCount =
                disenrolledPolicies.containsKey(con.Id)
                ? disenrolledPolicies.get(con.Id)
                : 0;

            Integer productionCount =
                periodProduction.containsKey(con.Id)
                ? periodProduction.get(con.Id)
                : 0;

            Decimal commissionAmount =
                commissions.containsKey(con.Id)
                ? commissions.get(con.Id)
                : 0;

            Integer activeCarrierCount =
                activeAppointments.containsKey(con.Id)
                ? activeAppointments.get(con.Id)
                : 0;

            Decimal retentionRate = 0;

            Integer totalRetention =
                activeCount + disenrolledCount;

            if (totalRetention > 0) {

                retentionRate =
                    (
                        Decimal.valueOf(activeCount)
                        /
                        Decimal.valueOf(totalRetention)
                    ) * 100;
            }

            Decimal carrierCoverage = 0;

            if (totalAvailableCarriers > 0) {

                carrierCoverage =
                    (
                        Decimal.valueOf(
                            activeCarrierCount
                        )
                        /
                        Decimal.valueOf(
                            totalAvailableCarriers
                        )
                    ) * 100;
            }

            Contact upd = new Contact();

            upd.Id = con.Id;

            upd.Active_Policies_Count__c =
                activeCount;

            upd.Retention_Rate__c =
                retentionRate.setScale(2);

            upd.Period_Production__c =
                productionCount;

            upd.Period_Commissions__c =
                commissionAmount;

            upd.Carrier_Coverage__c =
                carrierCoverage;

            updates.add(upd);
        }

        // ─────────────────────────────────────────
        // UPDATE CONTACTS
        // ─────────────────────────────────────────
        if (!updates.isEmpty()) {

            update updates;

            System.debug(
                'AGENT SCORECARDS UPDATED → ' +
                updates.size()
            );
        }
    }

    // ─────────────────────────────────────────────
    // FINISH
    // ─────────────────────────────────────────────
    public void finish(
        Database.BatchableContext bc
    ) {

        System.debug(
            'Agent Scorecard Batch Completed'
        );
    }
}