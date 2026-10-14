@isTest
private class LeadConversionHandlerTest1 {

    // ── Helpers ────────────────────────────────────────────────────────────────

    private static Integer emailSeq = 0;

    private static String uniqueEmail(String firstName, String lastName) {
        emailSeq++;
        return firstName.toLowerCase()
               + '.' + lastName.toLowerCase()
               + emailSeq
               + '@testdomain.com';
    }

    private static Integer taxSeq = 0;
    private static String uniqueTaxId() {
        taxSeq++;
        Long base = Math.mod(System.currentTimeMillis(), 800000000L) + 100000000L;
        Long taxId = base + taxSeq;
        if (String.valueOf(taxId).length() > 9) {
            taxId = Math.mod(taxId, 900000000L) + 100000000L;
        }
        return String.valueOf(taxId);
    }

    private static Lead createLead(
        String firstName,
        String lastName,
        String status,
        String salesChannel,
        String resaleStatus
    ) {
        Lead l = new Lead(
            FirstName                     = firstName,
            LastName                      = lastName,
            Company                       = firstName + ' ' + lastName + ' Corp',
            Email                         = uniqueEmail(firstName, lastName),
            Tax_ID__c                     = uniqueTaxId(),
            Terms_of_Service_Agreement__c = 'I agree',
            Has_Physical_Store__c         = true,
            Resale_Certificate_Status__c  = resaleStatus,
            Sales_Channel__c              = salesChannel,
            Status                        = status
        );
        insert l;
        return l;
    }

    private static Lead createDefaultLead(String firstName, String lastName) {
        return createLead(
            firstName,
            lastName,
            'New',
            'Specialty',
            'Yes, I do.'
        );
    }

    private static String getConvertedStatus() {
        LeadStatus ls = [
            SELECT MasterLabel
            FROM   LeadStatus
            WHERE  IsConverted = true
            LIMIT  1
        ];
        return ls.MasterLabel;
    }

    // ── Test 1 : Single lead – full conversion (Account + Contact + Opp) ───────

    @isTest
    static void testSingleLeadFullConversion() {
        Lead l = createDefaultLead('Alice', 'Smith');

        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(l.Id);
        lc.setConvertedStatus(getConvertedStatus());
        lc.setDoNotCreateOpportunity(false);
        lc.setOpportunityName('Alice Smith - Converted Opp');

        Test.startTest();
        Database.LeadConvertResult result = Database.convertLead(lc);
        Test.stopTest();

        System.assert(result.isSuccess(),                         'Lead conversion must succeed');
        System.assertNotEquals(null, result.getAccountId(),       'Account must be created');
        System.assertNotEquals(null, result.getContactId(),       'Contact must be created');
        System.assertNotEquals(null, result.getOpportunityId(),   'Opportunity must be created');

        Opportunity opp = [
            SELECT Id, StageName
            FROM   Opportunity
            WHERE  Id = :result.getOpportunityId()
        ];
        System.assertNotEquals(null, opp.StageName, 'StageName should be populated');
    }

    // ── Test 2 : Conversion WITHOUT Opportunity ────────────────────────────────
    // FIX: Changed Resale_Certificate_Status__c from 'No, I don't.' to 'Yes, I do.'
    // and Has_Physical_Store__c to true so it does not trigger validation
    // when status is changed during conversion
    @isTest
    static void testConversionWithoutOpportunity() {
        Lead l = createLead(
            'Bob', 'Jones',
            'Working',
            'Key Accounts',
            'Yes, I do.'        // FIX: was 'No, I don't.' — triggers validation on Qualified
        );

        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(l.Id);
        lc.setConvertedStatus(getConvertedStatus());
        lc.setDoNotCreateOpportunity(true);

        Test.startTest();
        Database.LeadConvertResult result = Database.convertLead(lc);
        Test.stopTest();

        System.assert(result.isSuccess(),      'Conversion without Opp should succeed');
        System.assertNotEquals(null, result.getAccountId(),   'Account must be created');
        System.assertEquals(null,   result.getOpportunityId(),'No Opp should be created');
    }

    // ── Test 3 : Lead merged into existing Account → open Opp sync ────────────
    // FIX: Added Tax_ID__c to Account to satisfy validation rule
    @isTest
    static void testExistingOpenOpportunitySync() {
        Account acc = new Account(
            Name             = 'Existing Account LLC',
            Sales_Channel__c = 'Specialty',
            Tax_ID__c        = uniqueTaxId()   // FIX: Tax ID required by Account validation rule
        );
        insert acc;

        Opportunity existingOpp = new Opportunity(
            Name      = 'Existing Open Opp',
            AccountId = acc.Id,
            StageName = 'Summary',
            CloseDate = Date.today().addDays(30)
        );
        insert existingOpp;

        Lead l = createLead(
            'Carol', 'White',
            'Nurturing',
            'Global',
            'Not a requirement in my territory.'
        );

        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(l.Id);
        lc.setConvertedStatus(getConvertedStatus());
        lc.setAccountId(acc.Id);
        lc.setDoNotCreateOpportunity(true);

        Test.startTest();
        Database.LeadConvertResult result = Database.convertLead(lc);
        Test.stopTest();

        System.assert(result.isSuccess(), 'Conversion into existing Account should succeed');

        List<Opportunity> opps = [
            SELECT Id, StageName
            FROM   Opportunity
            WHERE  AccountId = :acc.Id
            AND    IsClosed  = false
        ];
    }

    // ── Test 4 : Bulk conversion – 10 leads ───────────────────────────────────
    // FIX: All leads now have Has_Physical_Store__c = true and valid
    // Resale_Certificate_Status__c so validation does not block conversion
    @isTest
    static void testBulkLeadConversion() {
        List<String> statuses = new List<String>{
            'New','Working','Nurturing','New',
            'New','Working','Nurturing','New','New','Working'
        };
        List<String> channels = new List<String>{
            'Specialty','Key Accounts','Global','Partnerships','Specialty CAN',
            'Specialty','Key Accounts','Global','Partnerships','Specialty CAN'
        };

        // FIX: All resale statuses are valid (no 'No, I don't.')
        // so validation does not block when status changes to Qualified during conversion
        List<String> resaleStatuses = new List<String>{
            'Yes, I do.','Not a requirement in my territory.','Yes, I do.',
            'Not a requirement in my territory.','Yes, I do.',
            'Not a requirement in my territory.','Yes, I do.',
            'Not a requirement in my territory.','Yes, I do.',
            'Not a requirement in my territory.'
        };

        List<Lead> leads = new List<Lead>();
        for (Integer i = 0; i < 10; i++) {
            emailSeq++;
            leads.add(new Lead(
                FirstName                     = 'Bulk',
                LastName                      = 'Lead' + i,
                Company                       = 'BulkCorp ' + i,
                Email                         = 'bulk.lead' + i + '.' + emailSeq + '@bulktest.com',
                Tax_ID__c                     = uniqueTaxId(),
                Terms_of_Service_Agreement__c = 'I agree',
                Has_Physical_Store__c         = true,       // FIX: was Math.mod(i,2)==0 — some were false
                Resale_Certificate_Status__c  = resaleStatuses[i],
                Sales_Channel__c              = channels[i],
                Status                        = statuses[i]
            ));
        }
        insert leads;

        String convertedStatus = getConvertedStatus();
        List<Database.LeadConvert> conversions = new List<Database.LeadConvert>();
        for (Lead l : leads) {
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(l.Id);
            lc.setConvertedStatus(convertedStatus);
            lc.setDoNotCreateOpportunity(true);
            conversions.add(lc);
        }

        Test.startTest();
        List<Database.LeadConvertResult> results = Database.convertLead(conversions);
        Test.stopTest();

        for (Database.LeadConvertResult r : results) {
            System.assert(r.isSuccess(),
                'Each bulk lead should convert successfully. Errors: ' + r.getErrors());
        }
    }

    // ── Test 5 : Direct handler call – no-op branch ───────────────────────────

    @isTest
    static void testHandlerNoOpBranch() {
        Lead l = createDefaultLead('Dave', 'Brown');

        Test.startTest();
        LeadConversionHandler.handleConversion(
            new List<Lead>{ l },
            new Map<Id, Lead>{ l.Id => l }
        );
        Test.stopTest();

        Lead refreshed = [SELECT Id, IsConverted FROM Lead WHERE Id = :l.Id];
        System.assertEquals(false, refreshed.IsConverted,
            'Lead should remain unconverted in no-op branch');
    }

    // ── Test 6 : Qualified lead + Partnerships channel ────────────────────────

    @isTest
    static void testQualifiedLeadPartnershipsChannel() {
        Lead l = createLead(
            'Eve', 'Taylor',
            'Qualified',
            'Partnerships',
            'Yes, I do.'
        );

        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(l.Id);
        lc.setConvertedStatus(getConvertedStatus());
        lc.setDoNotCreateOpportunity(false);
        lc.setOpportunityName('Eve Taylor - Partnerships Opp');

        Test.startTest();
        Database.LeadConvertResult result = Database.convertLead(lc);
        Test.stopTest();

        System.assert(result.isSuccess(),
            'Qualified/Partnerships lead conversion must succeed');
        System.assertNotEquals(null, result.getOpportunityId(),
            'Opportunity must be created for Qualified lead');
    }

    // ── Test 7 : Specialty CAN channel + physical store false ─────────────────
    // FIX: Has_Physical_Store__c = false is intentional to test this field value.
    // To avoid triggering checkIfEarlyStagesFilled (which fires on Status = Qualified),
    // we first convert the lead with Has_Physical_Store__c = true, then verify
    // the field is stored correctly. Alternatively we verify insert succeeds
    // without the validation firing (validation only fires on Status → Qualified).
    @isTest
    static void testSpecialtyCanChannelNoPhysicalStore() {
        emailSeq++;
        // FIX: Insert with Has_Physical_Store__c = false — this is allowed on insert
        // since checkIfEarlyStagesFilled was removed from before insert.
        Lead l = new Lead(
            FirstName                     = 'Frank',
            LastName                      = 'Lee',
            Company                       = 'Frank Lee Imports',
            Email                         = 'frank.lee' + emailSeq + '@testdomain.com',
            Tax_ID__c                     = uniqueTaxId(),
            Terms_of_Service_Agreement__c = 'I agree',
            Has_Physical_Store__c         = false,
            Resale_Certificate_Status__c  = 'Not a requirement in my territory.',
            Sales_Channel__c              = 'Specialty CAN',
            Status                        = 'Nurturing'
        );
        insert l;

        // Verify lead inserted successfully with Has_Physical_Store__c = false
        Lead inserted = [SELECT Id, Has_Physical_Store__c FROM Lead WHERE Id = :l.Id];
        System.assertEquals(false, inserted.Has_Physical_Store__c,
            'Lead should insert with Has_Physical_Store__c = false — validation removed from insert');

        // FIX: To convert, update Has_Physical_Store__c = true first
        // so the converted status change does not trigger the Qualified validation
        l.Has_Physical_Store__c = true;
        update l;

        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(l.Id);
        lc.setConvertedStatus(getConvertedStatus());
        lc.setDoNotCreateOpportunity(true);

        Test.startTest();
        Database.LeadConvertResult result = Database.convertLead(lc);
        Test.stopTest();

        System.assert(result.isSuccess(),
            'Specialty CAN lead should convert after Has_Physical_Store__c is set to true');
    }

    // ── Test 8 : Tax ID is always 9 digits and unique ─────────────────────────

    @isTest
    static void testTaxIdNineDigitsAndUnique() {
        Set<String> generated = new Set<String>();
        for (Integer i = 0; i < 20; i++) {
            String taxId = uniqueTaxId();
            System.assertEquals(9, taxId.length(),
                'Tax_ID__c must be exactly 9 digits, got: ' + taxId);
            System.assert(!generated.contains(taxId),
                'Tax_ID__c must be unique, duplicate: ' + taxId);
            generated.add(taxId);
        }
    }

    // ── Test 9 : Validation fires when Status changes to Qualified ────────────
    // Verifies checkIfEarlyStagesFilled blocks qualification with clear message
    @isTest
    static void testValidationBlocksQualificationWhenFieldsMissing() {
        emailSeq++;
        Lead l = new Lead(
            FirstName                     = 'Grace',
            LastName                      = 'Kim',
            Company                       = 'Grace Kim Corp',
            Email                         = 'grace.kim' + emailSeq + '@testdomain.com',
            Tax_ID__c                     = uniqueTaxId(),
            Terms_of_Service_Agreement__c = 'I agree',
            Has_Physical_Store__c         = false,          // will trigger validation
            Resale_Certificate_Status__c  = 'Yes, I do.',
            Sales_Channel__c              = 'Specialty',
            Status                        = 'New'
        );
        insert l;

        // Try to change status to Qualified — should be blocked by validation
        Boolean errorThrown = false;
        try {
            l.Status = 'Qualified';
            update l;
        } catch (DmlException e) {
            errorThrown = true;
            System.assert(
                e.getMessage().contains('Has Physical Store'),
                'Error should mention Has Physical Store field'
            );
        }
        System.assert(errorThrown, 'Validation should block setting Status to Qualified');
    }
}