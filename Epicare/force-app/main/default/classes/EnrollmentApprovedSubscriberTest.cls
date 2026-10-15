@IsTest
private class EnrollmentApprovedSubscriberTest {

    private static Integer seq = 0;

    private class GoAMSCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setStatus('OK');
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"access_token":"mock-token","token_type":"Bearer","expires_in":3600}');
            return res;
        }
    }

    private static void mockGoAMSCallout() {
        Test.setMock(HttpCalloutMock.class, new GoAMSCalloutMock());
    }

    private static String uniqueValue(String prefix) {
        seq++;
        return prefix + '-' + seq;
    }

    private static Account createAccount(String name) {
        Account a = new Account(Name = name + '-' + uniqueValue('A'));
        insert a;
        return a;
    }

    private static Contact createAgent(String lastName, String npn) {
        Account a = createAccount('Agent Account');
        Contact c = new Contact(
            FirstName = 'Test',
            LastName = lastName,
            AccountId = a.Id,
            Email = uniqueValue('agent') + '@example.com',
            NPN__c = npn,
            Agent_Status__c = 'Onboarding'
        );
        insert c;
        return c;
    }

    private static Contact createAgentWithCode(String lastName, String npn, String agentCode) {
        Contact c = createAgent(lastName, npn);
        c.Agent_Code__c = agentCode;
        update c;
        return c;
    }

    private static Contact createAgentWithProfile(String lastName, String npn, String agentCode, String profileType) {
        Contact c = createAgentWithCode(lastName, npn, agentCode);
        c.Agent_Profile_Type__c = profileType;
        update c;
        return c;
    }

    private static Carrier__c createCarrier(String name) {
        Carrier__c carrier = new Carrier__c(
            Name = name + '-' + uniqueValue('C'),
            Carrier_Code__c = 'CODE-' + uniqueValue('CC'),
            Supported_Lines_of_Business__c = 'ACA;Life;Medicare'
        );
        insert carrier;
        return carrier;
    }

    private static Product__c createProduct(String name) {
        Product__c product = new Product__c(Name = name + '-' + uniqueValue('P'));
        insert product;
        return product;
    }

    private static Product_State__c createProductState(
        Id carrierId, Id productId, String lob, String level,
        String paymentType, Decimal year1Percentage, Decimal fixedRate
    ) {
        Product_State__c ps = new Product_State__c(
            Carrier__c = carrierId,
            Product__c = productId,
            Line_of_Business__c = lob,
            Levels__c = level,
            Commission_Level__c = '1',
            Payment_Type__c = paymentType,
            Year_1_Percentage__c = year1Percentage,
            Fixed_Rate__c = fixedRate
        );
        insert ps;
        return ps;
    }

    private static Product_State__c createProductStateWithState(
        Id carrierId, Id productId, String lob, String level,
        String paymentType, Decimal year1Percentage, Decimal fixedRate, String state
    ) {
        Product_State__c ps = new Product_State__c(
            Carrier__c = carrierId,
            Product__c = productId,
            Line_of_Business__c = lob,
            Levels__c = level,
            Commission_Level__c = '1',
            Payment_Type__c = paymentType,
            Year_1_Percentage__c = year1Percentage,
            Fixed_Rate__c = fixedRate,
            State__c = state
        );
        insert ps;
        return ps;
    }

    private static Renewal_Schedule__c createRenewalSchedule(
        Id productStateId, Decimal percentage, Decimal fixedRate,
        Decimal yearFrom, Decimal yearTo, Decimal sortOrder
    ) {
        Renewal_Schedule__c rs = new Renewal_Schedule__c(
            Product_State__c = productStateId,
            Percentage__c = percentage,
            Fixed_Rate__c = fixedRate,
            Year_From__c = yearFrom,
            Year_To__c = yearTo,
            Sort_Order__c = sortOrder,
            Schedule_Type__c = 'Renewal',
            Active__c = true
        );
        insert rs;
        return rs;
    }

    private static Agreement__c createAgreement(
        Id agencyId, Id agentId, String lob, String agreementType,
        String overrideType, Decimal overridePercentage, Decimal overrideAmount
    ) {
        Agreement__c agreement = new Agreement__c(
            Agency__c = agencyId,
            Agent__c = agentId,
            LOB__c = lob,
            Agreement_Type__c = agreementType,
            Override_Type__c = overrideType,
            Override_Percentage__c = overridePercentage,
            Override_Amount__c = overrideAmount,
            Status__c = 'Active'
        );
        insert agreement;
        return agreement;
    }

    private static Appointment__c createAppointment(
        Contact agent, Id carrierId, Id agencyId, String paymentFlow,
        String paymentModel, String commissionMonth, Decimal advanceThroughMonth,
        Date effectiveDate, String lob, Decimal premium, Decimal memberCount,
        Decimal commissionLevel, String agentCode
    ) {
        Appointment__c appt = new Appointment__c(
            Agent__c = agent == null ? null : agent.Id,
            Carrier__c = carrierId,
            Agency__c = agencyId,
            State_s__c = 'TX',
            Status__c = 'Requested',
            Payment_Flow__c = paymentFlow,
            Payment_Model__c = paymentModel,
            Commission_Month__c = commissionMonth,
            Advance_Through_Month__c = advanceThroughMonth,
            Effective_Date__c = effectiveDate,
            Line_of_Business__c = lob,
            Premium__c = premium,
            Member_Count__c = memberCount,
            Commission_Level__c = commissionLevel,
            Agent_Code__c = agentCode
        );
        insert appt;
        return appt;
    }

    private static Appointment__c createAppointmentWithState(
        Contact agent, Id carrierId, Id agencyId, String paymentFlow,
        String paymentModel, String commissionMonth, Decimal advanceThroughMonth,
        Date effectiveDate, String lob, Decimal premium, Decimal memberCount,
        Decimal commissionLevel, String agentCode, String state
    ) {
        Appointment__c appt = new Appointment__c(
            Agent__c = agent == null ? null : agent.Id,
            Carrier__c = carrierId,
            Agency__c = agencyId,
            State_s__c = state,
            Status__c = 'Requested',
            Payment_Flow__c = paymentFlow,
            Payment_Model__c = paymentModel,
            Commission_Month__c = commissionMonth,
            Advance_Through_Month__c = advanceThroughMonth,
            Effective_Date__c = effectiveDate,
            Line_of_Business__c = lob,
            Premium__c = premium,
            Member_Count__c = memberCount,
            Commission_Level__c = commissionLevel,
            Agent_Code__c = agentCode
        );
        insert appt;
        return appt;
    }

    private static Enrollment_Approved__e createEvent(
        Id appointmentId, String carrierName, String agentCode,
        String npn, String lob, String premium, String policyNumber
    ) {
        return new Enrollment_Approved__e(
            Appointment_ID__c = appointmentId == null ? null : String.valueOf(appointmentId),
            Carrier__c = carrierName,
            Agent_Code__c = agentCode,
            NPN__c = npn,
            LOB__c = lob,
            Premium__c = premium,
            Policy_Number__c = policyNumber
        );
    }

    private static Enrollment_Approved__e createEventWithReferral(
        Id appointmentId, String carrierName, String agentCode,
        String npn, String lob, String premium, String policyNumber, String referralPartnerId
    ) {
        Enrollment_Approved__e evt = createEvent(appointmentId, carrierName, agentCode, npn, lob, premium, policyNumber);
        evt.Referral_Partner_Id__c = referralPartnerId;
        return evt;
    }

    private static void publishOne(Enrollment_Approved__e eventRecord) {
        List<Database.SaveResult> results = EventBus.publish(new List<Enrollment_Approved__e>{eventRecord});
        System.assertEquals(true, results[0].isSuccess(), 'Platform Event publish failed');

        // Deliver the Platform Event so the subscriber trigger executes in the test.
        Test.getEventBus().deliver();
    }

    private static void publishMany(List<Enrollment_Approved__e> events) {
        List<Database.SaveResult> results = EventBus.publish(events);
        for (Database.SaveResult result : results) {
            System.assertEquals(true, result.isSuccess(), 'Platform Event publish failed');
        }

        // Deliver the Platform Events so the subscriber trigger executes in the test.
        Test.getEventBus().deliver();
    }

    // ============================================================
    // ORIGINAL 14 TESTS (PRESERVED)
    // ============================================================

    @IsTest
    static void testDirectAppointmentIdPercentage() {
        mockGoAMSCallout();
        Contact agent = createAgent('DirectAgent', '1000');
        Carrier__c carrier = createCarrier('Direct Carrier');
        Product__c product = createProduct('Direct Product');
        Account agency = createAccount('Direct Agency');
        createProductState(carrier.Id, product.Id, 'Life', 'Agent', 'Percentage', 5, null);
        
        Appointment__c appt = createAppointment(agent, carrier.Id, agency.Id, 'Carrier_Direct',
            'As_Earned_PMPM', '1_Month_Past', null, Date.today(), 'Life', 1000, 1, 1, 'AG-DIRECT');

        Test.startTest();
        publishOne(createEvent(appt.Id, carrier.Name, 'AG-DIRECT', '1000', 'Life', '1000', 'POL-DIRECT'));
        Test.stopTest();

        List<Commission_Record__c> records = [SELECT Id, Gross_Amount__c FROM Commission_Record__c WHERE Appointment__c = :appt.Id];
        System.assertEquals(12, records.size(), 'Expected 12 monthly records');
        System.assertEquals(50, records[0].Gross_Amount__c, '1000 * 5% = 50');
    }

    @IsTest
    static void testInvalidPayload() {
        mockGoAMSCallout();
        Enrollment_Approved__e eventRecord = new Enrollment_Approved__e(
            Agent_Code__c = 'AG-INVALID',
            NPN__c = null,
            Carrier__c = 'Unknown',
            LOB__c = 'Life',
            Premium__c = '1000',
            Policy_Number__c = 'POL-INVALID'
        );
        Test.startTest();
        publishOne(eventRecord);
        Test.stopTest();
        
        List<Commission_Exception__c> exceptions = [SELECT Exception_Type__c FROM Commission_Exception__c WHERE Exception_Type__c = 'Invalid_Payload'];
        System.assertEquals(1, exceptions.size(), 'Expected 1 Invalid_Payload exception');
    }

    @IsTest
    static void testUnresolvedAppointment() {
        mockGoAMSCallout();
        Contact agent = createAgent('UnresAgent', '1001');
        Carrier__c carrier = createCarrier('Unres Carrier');
        Account agency = createAccount('Unres Agency');
        
        Appointment__c appt = createAppointment(agent, carrier.Id, agency.Id, 'Carrier_Direct',
            'As_Earned_PMPM', '1_Month_Past', null, Date.today(), 'Life', 1000, 1, 1, 'AG-UNRES');

        Test.startTest();
        publishOne(createEvent(null, 'Unknown Carrier', 'AG-UNRES', '1001', 'Life', '1000', 'POL-UNRES'));
        Test.stopTest();

        List<Commission_Exception__c> exceptions = [SELECT Exception_Type__c FROM Commission_Exception__c WHERE Exception_Type__c = 'Unresolved_Appointment'];
        System.assertEquals(1, exceptions.size(), 'Expected Unresolved_Appointment exception');
    }

    @IsTest
    static void testAdvancedCommission9() {
        mockGoAMSCallout();
        Contact agent = createAgent('Adv9Agent', '1002');
        Carrier__c carrier = createCarrier('Adv9 Carrier');
        Product__c product = createProduct('Adv9 Product');
        Account agency = createAccount('Adv9 Agency');
        createProductState(carrier.Id, product.Id, 'Life', 'Agent', 'Percentage', 2, null);
        
        Appointment__c appt = createAppointment(agent, carrier.Id, agency.Id, 'Carrier_Direct',
            'Advanced_Commission_9', '1_Month_Past', null, Date.today(), 'Life', 1000, 1, 1, 'AG-ADV9');

        Test.startTest();
        publishOne(createEvent(appt.Id, carrier.Name, 'AG-ADV9', '1002', 'Life', '1000', 'POL-ADV9'));
        Test.stopTest();

        Integer crCount = [SELECT COUNT() FROM Commission_Record__c WHERE Appointment__c = :appt.Id];
        System.assertEquals(9, crCount, 'Advanced_Commission_9 should create 9 records');
    }

    @IsTest
    static void testManualPaymentModelCreatesNoRecords() {
        mockGoAMSCallout();
        Contact agent = createAgent('ManualAgent', '1003');
        Carrier__c carrier = createCarrier('Manual Carrier');
        Product__c product = createProduct('Manual Product');
        Account agency = createAccount('Manual Agency');
        createProductState(carrier.Id, product.Id, 'Life', 'Agent', 'Percentage', 5, null);
        
        Appointment__c appt = createAppointment(agent, carrier.Id, agency.Id, 'Carrier_Direct',
            'Manual', '1_Month_Past', null, Date.today(), 'Life', 1000, 1, 1, 'AG-MANUAL');

        Test.startTest();
        publishOne(createEvent(appt.Id, carrier.Name, 'AG-MANUAL', '1003', 'Life', '1000', 'POL-MANUAL'));
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Commission_Record__c], 'Manual should create 0 records');
    }

    @IsTest
    static void testRenewalSchedule() {
        mockGoAMSCallout();
        Contact agent = createAgent('RenewAgent', '1004');
        Carrier__c carrier = createCarrier('Renew Carrier');
        Product__c product = createProduct('Renew Product');
        Account agency = createAccount('Renew Agency');
        Product_State__c ps = createProductState(carrier.Id, product.Id, 'Life', 'Agent', 'Percentage', 5, null);
        createRenewalSchedule(ps.Id, 3, null, 2, null, 1);
        
        Appointment__c appt = createAppointment(agent, carrier.Id, agency.Id, 'Carrier_Direct',
            'As_Earned_PMPM', '1_Month_Past', null, Date.today().addYears(-1), 'Life', 1000, 1, 1, 'AG-RENEW');

        Test.startTest();
        publishOne(createEvent(appt.Id, carrier.Name, 'AG-RENEW', '1004', 'Life', '1000', 'POL-RENEW'));
        Test.stopTest();

        List<Commission_Record__c> records = [SELECT Gross_Amount__c FROM Commission_Record__c WHERE Appointment__c = :appt.Id];
        System.assertEquals(12, records.size(), 'Year 2 should create 12 records');
        System.assertEquals(30, records[0].Gross_Amount__c, 'Renewal rate 3% applied');
    }

    @IsTest
    static void testMissingRate() {
        mockGoAMSCallout();
        Contact agent = createAgent('MissingRateAgent', '1005');
        Carrier__c carrier = createCarrier('Missing Rate Carrier');
        Account agency = createAccount('Missing Rate Agency');
        
        Appointment__c appt = createAppointment(agent, carrier.Id, agency.Id, 'Carrier_Direct',
            'As_Earned_PMPM', '1_Month_Past', null, Date.today(), 'Life', 1000, 1, 1, 'AG-MISSING');

        Test.startTest();
        publishOne(createEvent(appt.Id, carrier.Name, 'AG-MISSING', '1005', 'Life', '1000', 'POL-MISSING'));
        Test.stopTest();

        List<Commission_Exception__c> exceptions = [SELECT Exception_Type__c FROM Commission_Exception__c WHERE Exception_Type__c = 'Missing_Rate'];
        System.assertEquals(1, exceptions.size(), 'Expected Missing_Rate exception');
    }

    @IsTest
    static void testAcaPassThroughCreatesRecords() {
        mockGoAMSCallout();
        Contact agent = createAgent('AcaAgent', '1006');
        Carrier__c carrier = createCarrier('ACA Carrier');
        Product__c product = createProduct('ACA Product');
        Account agency = createAccount('ACA Agency');
        createProductState(carrier.Id, product.Id, 'ACA', 'Agent', 'Percentage', null, null);
        
        Appointment__c appt = createAppointment(agent, carrier.Id, agency.Id, 'Carrier_Direct',
            'As_Earned_PMPM', '1_Month_Past', null, Date.today(), 'ACA', 1000, 1, 1, 'AG-ACA');

        Test.startTest();
        publishOne(createEvent(appt.Id, carrier.Name, 'AG-ACA', '1006', 'ACA', '1000', 'POL-ACA'));
        Test.stopTest();

        List<Commission_Record__c> records = [SELECT Gross_Amount__c FROM Commission_Record__c WHERE Appointment__c = :appt.Id];
        System.assertEquals(12, records.size(), 'ACA pass-through creates 12 records');
        System.assertEquals(0, records[0].Gross_Amount__c, 'Pass-through has 0 amount when rate is null');
    }

    @IsTest
    static void testOverrideFixedAmount() {
        mockGoAMSCallout();
        Contact agent = createAgent('OverrideAgent', '1007');
        Carrier__c carrier = createCarrier('Override Carrier');
        Product__c product = createProduct('Override Product');
        Account agency = createAccount('Override Agency');
        createProductState(carrier.Id, product.Id, 'Life', 'Agent', 'Percentage', 5, null);
        createAgreement(agency.Id, agent.Id, 'Life', 'Override_Fixed (MAPD/ACA)', 'Fixed Amount', null, 75);
        
        Appointment__c appt = createAppointment(agent, carrier.Id, agency.Id, 'Carrier_Direct',
            'As_Earned_PMPM', '1_Month_Past', null, Date.today(), 'Life', 1000, 1, 1, 'AG-OVERRIDE');

        Test.startTest();
        publishOne(createEvent(appt.Id, carrier.Name, 'AG-OVERRIDE', '1007', 'Life', '1000', 'POL-OVERRIDE'));
        Test.stopTest();

        Integer overrideCount = [SELECT COUNT() FROM Commission_Record__c WHERE Appointment__c = :appt.Id AND Compensation_Type__c = 'Override' AND Gross_Amount__c = 75];
        System.assert(overrideCount > 0, 'Should have override records with $75');
    }

    @IsTest
    static void testOverridePercentageOfCommission() {
        mockGoAMSCallout();
        Contact agent = createAgent('OverrideCommAgent', '1008');
        Carrier__c carrier = createCarrier('Override Comm Carrier');
        Product__c product = createProduct('Override Comm Product');
        Account agency = createAccount('Override Comm Agency');
        createProductState(carrier.Id, product.Id, 'Life', 'Agent', 'Percentage', 5, null);
        createAgreement(agency.Id, agent.Id, 'Life', 'Override_Percentage (Life/Supp)', 'Percentage Of Commission', 10, null);
        
        Appointment__c appt = createAppointment(agent, carrier.Id, agency.Id, 'Carrier_Direct',
            'As_Earned_PMPM', '1_Month_Past', null, Date.today(), 'Life', 1000, 1, 1, 'AG-OVR-COMM');

        Test.startTest();
        publishOne(createEvent(appt.Id, carrier.Name, 'AG-OVR-COMM', '1008', 'Life', '1000', 'POL-OVR-COMM'));
        Test.stopTest();

        Integer overrideCount = [SELECT COUNT() FROM Commission_Record__c WHERE Appointment__c = :appt.Id AND Compensation_Type__c = 'Override' AND Gross_Amount__c = 5];
        System.assert(overrideCount > 0, 'Should have override records with $5');
    }

    @IsTest
    static void testOverridePercentageOfPremium() {
        mockGoAMSCallout();
        Contact agent = createAgent('OverridePremAgent', '1009');
        Carrier__c carrier = createCarrier('Override Prem Carrier');
        Product__c product = createProduct('Override Prem Product');
        Account agency = createAccount('Override Prem Agency');
        createProductState(carrier.Id, product.Id, 'Life', 'Agent', 'Percentage', 5, null);
        createAgreement(agency.Id, agent.Id, 'Life', 'Override_Percentage (Life/Supp)', 'Percentage Of Premium', 2, null);
        
        Appointment__c appt = createAppointment(agent, carrier.Id, agency.Id, 'Carrier_Direct',
            'As_Earned_PMPM', '1_Month_Past', null, Date.today(), 'Life', 1000, 1, 1, 'AG-OVR-PREM');

        Test.startTest();
        publishOne(createEvent(appt.Id, carrier.Name, 'AG-OVR-PREM', '1009', 'Life', '1000', 'POL-OVR-PREM'));
        Test.stopTest();

        Integer overrideCount = [SELECT COUNT() FROM Commission_Record__c WHERE Appointment__c = :appt.Id AND Compensation_Type__c = 'Override' AND Gross_Amount__c = 20];
        System.assert(overrideCount > 0, 'Should have override records with $20');
    }

    @IsTest
    static void testReferralAgentCodeMismatchCreatesReferralRecord() {
        mockGoAMSCallout();
        Contact writingAgent = createAgentWithCode('WritingAgent', '1010', 'WRITING-AGENT');
        Contact referringAgent = createAgentWithCode('ReferringAgent', '1010B', 'REFERRING-AGENT');
        Carrier__c carrier = createCarrier('Referral Carrier');
        Product__c product = createProduct('Referral Product');
        Account agency = createAccount('Referral Agency');
        createProductState(carrier.Id, product.Id, 'Life', 'Agent', 'Percentage', 5, null);
        
        Appointment__c appt = createAppointment(writingAgent, carrier.Id, agency.Id, 'Carrier_Direct',
            'As_Earned_PMPM', '1_Month_Past', null, Date.today(), 'Life', 1000, 1, 1, 'WRITING-AGENT');

        Test.startTest();
        publishOne(createEvent(appt.Id, carrier.Name, 'REFERRING-AGENT', '1010', 'Life', '1000', 'POL-REFERRAL'));
        Test.stopTest();

        Integer refCount = [SELECT COUNT() FROM Referral_Record__c];
        System.assertEquals(1, refCount, 'Should create 1 referral record');
    }

    @IsTest
    static void testMatchingAgentCodeDoesNotCreateReferral() {
        mockGoAMSCallout();
        Contact agent = createAgentWithCode('NormalAgent', '1011', 'AG-NORMAL');
        Carrier__c carrier = createCarrier('Normal Carrier');
        Product__c product = createProduct('Normal Product');
        Account agency = createAccount('Normal Agency');
        createProductState(carrier.Id, product.Id, 'Life', 'Agent', 'Percentage', 5, null);
        
        Appointment__c appt = createAppointment(agent, carrier.Id, agency.Id, 'Carrier_Direct',
            'As_Earned_PMPM', '1_Month_Past', null, Date.today(), 'Life', 1000, 1, 1, 'AG-NORMAL');

        Test.startTest();
        publishOne(createEvent(appt.Id, carrier.Name, 'AG-NORMAL', '1011', 'Life', '1000', 'POL-NORMAL'));
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Referral_Record__c], 'Matching agent codes should not create referral');
    }

    @IsTest
    static void testBulkProcessing() {
        mockGoAMSCallout();
        Account agency = createAccount('Bulk Agency');
        
        List<Contact> agents = new List<Contact>();
        for (Integer i = 0; i < 5; i++) {
            agents.add(new Contact(
                FirstName = 'Bulk',
                LastName = 'Agent-' + i,
                AccountId = createAccount('Bulk Account ' + i).Id,
                Email = 'bulk-' + i + '@example.com',
                NPN__c = String.valueOf(2000 + i),
                Agent_Status__c = 'Onboarding'
            ));
        }
        insert agents;

        List<Carrier__c> carriers = new List<Carrier__c>();
        for (Integer i = 0; i < 3; i++) {
            carriers.add(new Carrier__c(
                Name = 'Bulk Carrier ' + i,
                Carrier_Code__c = 'BULKCODE-' + i,
                Supported_Lines_of_Business__c = 'ACA;Life'
            ));
        }
        insert carriers;

        List<Product__c> products = new List<Product__c>();
        for (Integer i = 0; i < 3; i++) {
            products.add(new Product__c(Name = 'Bulk Product ' + i));
        }
        insert products;

        List<Product_State__c> pStates = new List<Product_State__c>();
        for (Integer i = 0; i < 3; i++) {
            pStates.add(new Product_State__c(
                Carrier__c = carriers[i].Id,
                Product__c = products[i].Id,
                Line_of_Business__c = 'Life',
                Levels__c = 'Agent',
                Payment_Type__c = 'Percentage',
                Commission_Level__c = '1',
                Year_1_Percentage__c = 5
            ));
        }
        insert pStates;

        List<Appointment__c> appts = new List<Appointment__c>();
        for (Integer i = 0; i < 20; i++) {
            appts.add(new Appointment__c(
                Agent__c = agents[Math.mod(i, agents.size())].Id,
                Carrier__c = carriers[Math.mod(i, carriers.size())].Id,
                Agency__c = agency.Id,
                State_s__c = 'TX',
                Status__c = 'Requested',
                Payment_Flow__c = 'Carrier_Direct',
                Payment_Model__c = 'As_Earned_PMPM',
                Commission_Month__c = '1_Month_Past',
                Effective_Date__c = Date.today(),
                Line_of_Business__c = 'Life',
                Premium__c = 1000,
                Member_Count__c = 1,
                Commission_Level__c = 1,
                Agent_Code__c = 'AG-BULK-' + i
            ));
        }
        insert appts;

        List<Enrollment_Approved__e> events = new List<Enrollment_Approved__e>();
        for (Integer i = 0; i < appts.size(); i++) {
            events.add(createEvent(
                appts[i].Id,
                carriers[Math.mod(i, carriers.size())].Name,
                'AG-BULK-' + i,
                String.valueOf(2000 + Math.mod(i, agents.size())),
                'Life',
                '1000',
                'POL-BULK-' + i
            ));
        }

        Test.startTest();
        publishMany(events);
        Test.stopTest();

        Integer crCount = [SELECT COUNT() FROM Commission_Record__c];
        System.assert(crCount >= 200, 'Bulk processing should create 240+ records (20 * 12)');
    }

    // ============================================================
    // COVERAGE GAPS - FOCUSED TESTS
    // ============================================================

    @IsTest
    static void testFixedAmountPaymentType() {
        mockGoAMSCallout();
        Contact agent = createAgent('FixedAgent', '3001');
        Carrier__c carrier = createCarrier('FixedCarrier');
        Product__c product = createProduct('FixedProduct');
        Account agency = createAccount('FixedAgency');
        createProductState(carrier.Id, product.Id, 'Life', 'Agent', 'Fixed_Amount', null, 25);
        
        Appointment__c appt = createAppointment(agent, carrier.Id, agency.Id, 'Carrier_Direct',
            'As_Earned_PMPM', '1_Month_Past', null, Date.today(), 'Life', null, 10, 1, 'AG-FIXED');

        Test.startTest();
        publishOne(createEvent(appt.Id, carrier.Name, 'AG-FIXED', '3001', 'Life', '1000', 'POL-FIXED'));
        Test.stopTest();

        List<Commission_Record__c> records = [SELECT Gross_Amount__c FROM Commission_Record__c WHERE Appointment__c = :appt.Id];
        System.assertEquals(12, records.size());
        System.assertEquals(250, records[0].Gross_Amount__c, '25 * 10 members = 250');
    }

    @IsTest
    static void testAdvancedCommission6() {
        mockGoAMSCallout();
        Contact agent = createAgent('Adv6Agent', '3002');
        Carrier__c carrier = createCarrier('Adv6Carrier');
        Product__c product = createProduct('Adv6Product');
        Account agency = createAccount('Adv6Agency');
        createProductState(carrier.Id, product.Id, 'Life', 'Agent', 'Percentage', 3, null);
        
        Appointment__c appt = createAppointment(agent, carrier.Id, agency.Id, 'Carrier_Direct',
            'Advanced_Commission_6', 'Current_Month', null, Date.today(), 'Life', 1000, 1, 1, 'AG-ADV6');

        Test.startTest();
        publishOne(createEvent(appt.Id, carrier.Name, 'AG-ADV6', '3002', 'Life', '1000', 'POL-ADV6'));
        Test.stopTest();

        Integer crCount = [SELECT COUNT() FROM Commission_Record__c WHERE Appointment__c = :appt.Id];
        System.assertEquals(6, crCount, 'Advanced_Commission_6 = 6 records');
    }

    

    @IsTest
    static void testCurrentMonthCommission() {
        mockGoAMSCallout();
        Contact agent = createAgent('CurrentAgent', '3004');
        Carrier__c carrier = createCarrier('CurrentCarrier');
        Product__c product = createProduct('CurrentProduct');
        Account agency = createAccount('CurrentAgency');
        createProductState(carrier.Id, product.Id, 'Life', 'Agent', 'Percentage', 5, null);
        
        Appointment__c appt = createAppointment(agent, carrier.Id, agency.Id, 'Carrier_Direct',
            'As_Earned_PMPM', 'Current_Month', null, Date.today(), 'Life', 1000, 1, 1, 'AG-CURRENT');

        Test.startTest();
        publishOne(createEvent(appt.Id, carrier.Name, 'AG-CURRENT', '3004', 'Life', '1000', 'POL-CURRENT'));
        Test.stopTest();

        List<Commission_Record__c> records = [SELECT Payment_Period__c FROM Commission_Record__c WHERE Appointment__c = :appt.Id ORDER BY Payment_Period__c LIMIT 1];
        System.assertEquals(1, records.size());
        Integer expectedMonth = Date.today().month();
        String expected = Date.today().year() + '-' + (expectedMonth < 10 ? '0' + expectedMonth : String.valueOf(expectedMonth));
        System.assertEquals(expected, records[0].Payment_Period__c, 'Current_Month uses today');
    }

    @IsTest
    static void testInvalidPremiumValue() {
        mockGoAMSCallout();
        Contact agent = createAgent('InvalidPremAgent', '3005');
        Carrier__c carrier = createCarrier('InvalidPremCarrier');
        Product__c product = createProduct('InvalidPremProduct');
        Account agency = createAccount('InvalidPremAgency');
        createProductState(carrier.Id, product.Id, 'Life', 'Agent', 'Percentage', 5, null);
        
        Appointment__c appt = createAppointment(agent, carrier.Id, agency.Id, 'Carrier_Direct',
            'As_Earned_PMPM', '1_Month_Past', null, Date.today(), 'Life', 1000, 1, 1, 'AG-BADPREM');

        Test.startTest();
        publishOne(createEvent(appt.Id, carrier.Name, 'AG-BADPREM', '3005', 'Life', 'NOTANUMBER', 'POL-BADPREM'));
        Test.stopTest();

        List<Commission_Record__c> records = [SELECT Gross_Amount__c FROM Commission_Record__c WHERE Appointment__c = :appt.Id];
        System.assertEquals(12, records.size());
        System.assertEquals(0, records[0].Gross_Amount__c, 'Invalid premium results in 0');
    }

    @IsTest
    static void testStateSpecificProductState() {
        mockGoAMSCallout();
        Contact agent = createAgent('StateAgent', '3006');
        Carrier__c carrier = createCarrier('StateCarrier');
        Product__c product = createProduct('StateProduct');
        Account agency = createAccount('StateAgency');
        
        createProductStateWithState(carrier.Id, product.Id, 'Life', 'Agent', 'Percentage', 28, null, 'NY');
        createProductStateWithState(carrier.Id, product.Id, 'Life', 'Agent', 'Percentage', 30, null, 'NY;CA;TX');
        
        Appointment__c appt = createAppointmentWithState(agent, carrier.Id, agency.Id, 'Carrier_Direct',
            'As_Earned_PMPM', '1_Month_Past', null, Date.today(), 'Life', 1000, 1, 1, 'AG-STATE', 'NY');

        Test.startTest();
        publishOne(createEvent(appt.Id, carrier.Name, 'AG-STATE', '3006', 'Life', '1000', 'POL-STATE'));
        Test.stopTest();

        List<Commission_Record__c> records = [SELECT Gross_Amount__c FROM Commission_Record__c WHERE Appointment__c = :appt.Id];
        System.assertEquals(280, records[0].Gross_Amount__c, 'Most specific state (28%) wins over multi-state (30%)');
    }

    @IsTest
    static void testRenewalScheduleYearRange() {
        mockGoAMSCallout();
        Contact agent = createAgent('RenewRangeAgent', '3007');
        Carrier__c carrier = createCarrier('RenewRangeCarrier');
        Product__c product = createProduct('RenewRangeProduct');
        Account agency = createAccount('RenewRangeAgency');
        Product_State__c ps = createProductState(carrier.Id, product.Id, 'Life', 'Agent', 'Percentage', 5, null);
        
        createRenewalSchedule(ps.Id, 4, null, 5, null, 1);
        
        Appointment__c appt = createAppointment(agent, carrier.Id, agency.Id, 'Carrier_Direct',
            'As_Earned_PMPM', '1_Month_Past', null, Date.today().addYears(-5), 'Life', 1000, 1, 1, 'AG-NOUPPER');

        Test.startTest();
        publishOne(createEvent(appt.Id, carrier.Name, 'AG-NOUPPER', '3007', 'Life', '1000', 'POL-NOUPPER'));
        Test.stopTest();

        List<Commission_Record__c> records = [SELECT Gross_Amount__c FROM Commission_Record__c WHERE Appointment__c = :appt.Id];
        System.assertEquals(40, records[0].Gross_Amount__c, 'Year 6 matches Year_From 5 with null Year_To');
    }

    @IsTest
    static void testMedicarePassThrough() {
        mockGoAMSCallout();
        Contact agent = createAgent('MedicareAgent', '3008');
        Carrier__c carrier = createCarrier('MedicareCarrier');
        Product__c product = createProduct('MedicareProduct');
        Account agency = createAccount('MedicareAgency');
        createProductState(carrier.Id, product.Id, 'Medicare', 'Agent', 'Percentage', null, null);
        
        Appointment__c appt = createAppointment(agent, carrier.Id, agency.Id, 'Carrier_Direct',
            'As_Earned_PMPM', '1_Month_Past', null, Date.today(), 'Medicare', 1500, 50, 1, 'AG-MEDICARE');

        Test.startTest();
        publishOne(createEvent(appt.Id, carrier.Name, 'AG-MEDICARE', '3008', 'Medicare', '1500', 'POL-MEDICARE'));
        Test.stopTest();

        List<Commission_Record__c> records = [SELECT Gross_Amount__c FROM Commission_Record__c WHERE Appointment__c = :appt.Id];
        System.assertEquals(12, records.size());
        System.assertEquals(0, records[0].Gross_Amount__c, 'Medicare pass-through with null rate = 0');
    }

    @IsTest
    static void testAsEarnedPppm() {
        mockGoAMSCallout();
        Contact agent = createAgent('PppmAgent', '3009');
        Carrier__c carrier = createCarrier('PppmCarrier');
        Product__c product = createProduct('PppmProduct');
        Account agency = createAccount('PppmAgency');
        createProductState(carrier.Id, product.Id, 'Life', 'Agent', 'Percentage', 6, null);
        
        Appointment__c appt = createAppointment(agent, carrier.Id, agency.Id, 'Carrier_Direct',
            'As_Earned_PPPM', '1_Month_Past', null, Date.today(), 'Life', 1000, 1, 1, 'AG-PPPM');

        Test.startTest();
        publishOne(createEvent(appt.Id, carrier.Name, 'AG-PPPM', '3009', 'Life', '1000', 'POL-PPPM'));
        Test.stopTest();

        Integer crCount = [SELECT COUNT() FROM Commission_Record__c WHERE Appointment__c = :appt.Id];
        System.assertEquals(12, crCount, 'As_Earned_PPPM = 12 records');
    }

    @IsTest
    static void testMalformedAppointmentIdFallback() {
        mockGoAMSCallout();
        Contact agent = createAgent('FallbackAgent', '3010');
        Carrier__c carrier = createCarrier('FallbackCarrier');
        Product__c product = createProduct('FallbackProduct');
        Account agency = createAccount('FallbackAgency');
        createProductState(carrier.Id, product.Id, 'Life', 'Agent', 'Percentage', 5, null);
        
        Appointment__c appt = createAppointment(agent, carrier.Id, agency.Id, 'Carrier_Direct',
            'As_Earned_PMPM', '1_Month_Past', null, Date.today(), 'Life', 1000, 1, 1, 'AG-FALLBACK');

        Test.startTest();
        // Pass null or invalid UUID format - system should fall back to NPN resolution
        publishOne(createEvent(null, carrier.Name, 'AG-FALLBACK', '3010', 'Life', '1000', 'POL-FALLBACK'));
        Test.stopTest();

        List<Commission_Record__c> records = [SELECT Id FROM Commission_Record__c WHERE Appointment__c = :appt.Id];
        System.assertEquals(12, records.size(), 'Null appointment ID falls back to NPN resolution');
    }

    @IsTest
    static void testAgreementAllLob() {
        mockGoAMSCallout();
        Contact agent = createAgent('AllLobAgent', '3011');
        Carrier__c carrier = createCarrier('AllLobCarrier');
        Product__c product = createProduct('AllLobProduct');
        Account agency = createAccount('AllLobAgency');
        createProductState(carrier.Id, product.Id, 'Life', 'Agent', 'Percentage', 5, null);
        
        // Create agreement with specific 'Life' LOB matching the appointment
        createAgreement(agency.Id, agent.Id, 'Life', 'Override_Percentage (Life/Supp)', 'Percentage Of Commission', 5, null);
        
        Appointment__c appt = createAppointment(agent, carrier.Id, agency.Id, 'Carrier_Direct',
            'As_Earned_PMPM', '1_Month_Past', null, Date.today(), 'Life', 1000, 1, 1, 'AG-ALL');

        Test.startTest();
        publishOne(createEvent(appt.Id, carrier.Name, 'AG-ALL', '3011', 'Life', '1000', 'POL-ALL'));
        Test.stopTest();

        Integer overrideCount = [SELECT COUNT() FROM Commission_Record__c WHERE Appointment__c = :appt.Id AND Compensation_Type__c = 'Override'];
        System.assert(overrideCount > 0, 'Agreement with matching Life LOB should create override records');
    }

    @IsTest
    static void testReferralTypePartner() {
        mockGoAMSCallout();
        Contact writing = createAgentWithCode('PartnerWrite', '3012', 'WRITE-PARTNER');
        Contact referring = createAgentWithCode('PartnerRef', '3012B', 'REF-PARTNER');
        Carrier__c carrier = createCarrier('PartnerCarrier');
        Product__c product = createProduct('PartnerProduct');
        Account agency = createAccount('PartnerAgency');
        createProductState(carrier.Id, product.Id, 'Life', 'Agent', 'Percentage', 5, null);
        
        Appointment__c appt = createAppointment(writing, carrier.Id, agency.Id, 'Carrier_Direct',
            'As_Earned_PMPM', '1_Month_Past', null, Date.today(), 'Life', 1000, 1, 1, 'WRITE-PARTNER');

        Test.startTest();
        publishOne(createEventWithReferral(appt.Id, carrier.Name, 'REF-PARTNER', '3012', 'Life', '1000', 'POL-PARTNER', 'PARTNER-123'));
        Test.stopTest();

        List<Referral_Record__c> referrals = [SELECT Referral_Type__c, Supabase_Referral_Id__c FROM Referral_Record__c];
        System.assertEquals(1, referrals.size());
        System.assertEquals('Referral_Partner', referrals[0].Referral_Type__c);
        System.assertEquals('PARTNER-123', referrals[0].Supabase_Referral_Id__c);
    }

    @IsTest
    static void testReferralTypeAgentSale() {
        mockGoAMSCallout();
        Contact writing = createAgentWithCode('AgentSaleWrite', '3013', 'WRITE-AGENT');
        Contact referring = createAgentWithProfile('AgentSaleRef', '3013B', 'REF-AGENT', 'Referral_Agent');
        Carrier__c carrier = createCarrier('AgentSaleCarrier');
        Product__c product = createProduct('AgentSaleProduct');
        Account agency = createAccount('AgentSaleAgency');
        createProductState(carrier.Id, product.Id, 'Life', 'Agent', 'Percentage', 5, null);
        
        Appointment__c appt = createAppointment(writing, carrier.Id, agency.Id, 'Carrier_Direct',
            'As_Earned_PMPM', '1_Month_Past', null, Date.today(), 'Life', 1000, 1, 1, 'WRITE-AGENT');

        Test.startTest();
        publishOne(createEvent(appt.Id, carrier.Name, 'REF-AGENT', '3013', 'Life', '1000', 'POL-AGENT-SALE'));
        Test.stopTest();

        List<Referral_Record__c> referrals = [SELECT Referral_Type__c FROM Referral_Record__c];
        System.assertEquals(1, referrals.size());
        System.assertEquals('Referral_Agent_Sale', referrals[0].Referral_Type__c);
    }

    @IsTest
    static void testInvalidPayloadExceptionFields() {
        mockGoAMSCallout();
        Contact agent = createAgent('ExceptionAgent', '3014');
        Carrier__c carrier = createCarrier('ExceptionCarrier');
        
        Enrollment_Approved__e eventRecord = new Enrollment_Approved__e(
            Agent_Code__c = 'AG-EXCEP',
            NPN__c = '3014',
            Carrier__c = carrier.Name,
            LOB__c = 'Life',
            Premium__c = null,
            Policy_Number__c = 'POL-EXCEP'
        );

        Test.startTest();
        publishOne(eventRecord);
        Test.stopTest();

        List<Commission_Exception__c> exceptions = [SELECT Exception_Type__c, Carrier__c, Agent__c, Policy_Number__c, Payload__c FROM Commission_Exception__c WHERE Exception_Type__c = 'Invalid_Payload'];
        System.assertEquals(1, exceptions.size());
        System.assertEquals(carrier.Id, exceptions[0].Carrier__c);
        System.assertEquals(agent.Id, exceptions[0].Agent__c);
        System.assertEquals('POL-EXCEP', exceptions[0].Policy_Number__c);
        System.assert(String.isNotBlank(exceptions[0].Payload__c), 'Payload should be populated');
    }

    @IsTest
    static void testUpsertReferralRecordIdemotency() {
        mockGoAMSCallout();
        Contact writing = createAgentWithCode('UpsertWrite', '3015', 'WRITE-UPSERT');
        Contact referring = createAgentWithCode('UpsertRef', '3015B', 'REF-UPSERT');
        Carrier__c carrier = createCarrier('UpsertCarrier');
        Product__c product = createProduct('UpsertProduct');
        Account agency = createAccount('UpsertAgency');
        createProductState(carrier.Id, product.Id, 'Life', 'Agent', 'Percentage', 5, null);
        
        Appointment__c appt = createAppointment(writing, carrier.Id, agency.Id, 'Carrier_Direct',
            'As_Earned_PMPM', '1_Month_Past', null, Date.today(), 'Life', 1000, 1, 1, 'WRITE-UPSERT');

        Test.startTest();
        publishOne(createEvent(appt.Id, carrier.Name, 'REF-UPSERT', '3015', 'Life', '1000', 'POL-UPSERT'));
        publishOne(createEvent(appt.Id, carrier.Name, 'REF-UPSERT', '3015', 'Life', '1000', 'POL-UPSERT'));
        Test.stopTest();

        Integer refCount = [SELECT COUNT() FROM Referral_Record__c];
        System.assertEquals(1, refCount, 'Duplicate external ID should upsert, not insert new record');
    }

    @IsTest
    static void testCommissionRecordRev5Fields() {
        mockGoAMSCallout();
        Contact agent = createAgent('Rev5Agent', '3016');
        Carrier__c carrier = createCarrier('Rev5Carrier');
        Product__c product = createProduct('Rev5Product');
        Account agency = createAccount('Rev5Agency');
        createProductState(carrier.Id, product.Id, 'Life', 'Agent', 'Percentage', 5, null);
        
        Date effectiveDate = Date.newInstance(2026, 2, 1);
        Appointment__c appt = createAppointment(agent, carrier.Id, agency.Id, 'Carrier_Direct',
            'As_Earned_PMPM', '1_Month_Past', null, effectiveDate, 'Life', 1000, 50, 1, 'AG-REV5');

        Test.startTest();
        publishOne(createEvent(appt.Id, carrier.Name, 'AG-REV5', '3016', 'Life', '1000', 'POL-REV5'));
        Test.stopTest();

        List<Commission_Record__c> records = [SELECT Agency__c, Member_Count__c, Effective_Date__c FROM Commission_Record__c WHERE Appointment__c = :appt.Id];
        System.assertEquals(12, records.size());
        System.assertEquals(agency.Id, records[0].Agency__c, 'Agency should be populated');
        System.assertEquals(50, records[0].Member_Count__c, 'Member count should be populated');
        System.assertEquals(effectiveDate, records[0].Effective_Date__c, 'Effective date should be populated');
    }

    

    // ============================================================
    // NEW COVERAGE TESTS (+5%)
    // ============================================================

    @IsTest
    static void testAcaLob() {
        mockGoAMSCallout();
        Contact agent = createAgent('AcaLobbAgent', '4002');
        Carrier__c carrier = createCarrier('AcaLobbCarrier');
        Product__c product = createProduct('AcaLobbProduct');
        Account agency = createAccount('AcaLobbAgency');
        createProductState(carrier.Id, product.Id, 'ACA', 'Agent', 'Percentage', 2.5, null);
        
        Appointment__c appt = createAppointment(agent, carrier.Id, agency.Id, 'Carrier_Direct',
            'As_Earned_PMPM', '1_Month_Past', null, Date.today(), 'ACA', 2000, 1, 1, 'AG-ACALOB');

        Test.startTest();
        publishOne(createEvent(appt.Id, carrier.Name, 'AG-ACALOB', '4002', 'ACA', '2000', 'POL-ACALOB'));
        Test.stopTest();

        List<Commission_Record__c> records = [SELECT Gross_Amount__c FROM Commission_Record__c WHERE Appointment__c = :appt.Id];
        System.assertEquals(12, records.size());
        System.assertEquals(50, records[0].Gross_Amount__c, '2000 * 2.5% = 50');
    }

    @IsTest
    static void testMultipleMonthsCommissionMonth() {
        mockGoAMSCallout();
        Contact agent = createAgent('Month2Agent', '4003');
        Carrier__c carrier = createCarrier('Month2Carrier');
        Product__c product = createProduct('Month2Product');
        Account agency = createAccount('Month2Agency');
        createProductState(carrier.Id, product.Id, 'Life', 'Agent', 'Percentage', 5, null);
        
        Appointment__c appt = createAppointment(agent, carrier.Id, agency.Id, 'Carrier_Direct',
            'As_Earned_PMPM', '2_Months_Past', null, Date.today(), 'Life', 1000, 1, 1, 'AG-MONTH2');

        Test.startTest();
        publishOne(createEvent(appt.Id, carrier.Name, 'AG-MONTH2', '4003', 'Life', '1000', 'POL-MONTH2'));
        Test.stopTest();

        Integer crCount = [SELECT COUNT() FROM Commission_Record__c WHERE Appointment__c = :appt.Id];
        System.assertEquals(12, crCount, '2_Months_Past should create 12 records with correct offset');
    }

    @IsTest
    static void testThreeMonthsCommissionMonth() {
        mockGoAMSCallout();
        Contact agent = createAgent('Month3Agent', '4004');
        Carrier__c carrier = createCarrier('Month3Carrier');
        Product__c product = createProduct('Month3Product');
        Account agency = createAccount('Month3Agency');
        createProductState(carrier.Id, product.Id, 'Life', 'Agent', 'Percentage', 5, null);
        
        Appointment__c appt = createAppointment(agent, carrier.Id, agency.Id, 'Carrier_Direct',
            'As_Earned_PMPM', '3_Months_Past', null, Date.today(), 'Life', 1000, 1, 1, 'AG-MONTH3');

        Test.startTest();
        publishOne(createEvent(appt.Id, carrier.Name, 'AG-MONTH3', '4004', 'Life', '1000', 'POL-MONTH3'));
        Test.stopTest();

        Integer crCount = [SELECT COUNT() FROM Commission_Record__c WHERE Appointment__c = :appt.Id];
        System.assertEquals(12, crCount, '3_Months_Past offset should create 12 records');
    }

    @IsTest
    static void testFixedAmountWithZeroMembers() {
        mockGoAMSCallout();
        Contact agent = createAgent('FixedZeroAgent', '4005');
        Carrier__c carrier = createCarrier('FixedZeroCarrier');
        Product__c product = createProduct('FixedZeroProduct');
        Account agency = createAccount('FixedZeroAgency');
        createProductState(carrier.Id, product.Id, 'Life', 'Agent', 'Fixed_Amount', null, 50);
        
        Appointment__c appt = createAppointment(agent, carrier.Id, agency.Id, 'Carrier_Direct',
            'As_Earned_PMPM', '1_Month_Past', null, Date.today(), 'Life', 1000, 0, 1, 'AG-FIXEDZERO');

        Test.startTest();
        publishOne(createEvent(appt.Id, carrier.Name, 'AG-FIXEDZERO', '4005', 'Life', '1000', 'POL-FIXEDZERO'));
        Test.stopTest();

        List<Commission_Record__c> records = [SELECT Gross_Amount__c FROM Commission_Record__c WHERE Appointment__c = :appt.Id];
        System.assertEquals(12, records.size());
        System.assertEquals(0, records[0].Gross_Amount__c, 'Fixed amount with 0 members = 0');
    }

    @IsTest
    static void testLargeFixedAmount() {
        mockGoAMSCallout();
        Contact agent = createAgent('LargeFixedAgent', '4006');
        Carrier__c carrier = createCarrier('LargeFixedCarrier');
        Product__c product = createProduct('LargeFixedProduct');
        Account agency = createAccount('LargeFixedAgency');
        createProductState(carrier.Id, product.Id, 'Life', 'Agent', 'Fixed_Amount', null, 999);
        
        Appointment__c appt = createAppointment(agent, carrier.Id, agency.Id, 'Carrier_Direct',
            'As_Earned_PMPM', '1_Month_Past', null, Date.today(), 'Life', 10000, 100, 1, 'AG-LARGEFIXED');

        Test.startTest();
        publishOne(createEvent(appt.Id, carrier.Name, 'AG-LARGEFIXED', '4006', 'Life', '10000', 'POL-LARGEFIXED'));
        Test.stopTest();

        List<Commission_Record__c> records = [SELECT Gross_Amount__c FROM Commission_Record__c WHERE Appointment__c = :appt.Id];
        System.assertEquals(12, records.size());
        System.assertEquals(99900, records[0].Gross_Amount__c, '999 * 100 members = 99,900');
    }

    @IsTest
    static void testZeroPremiumWithPercentage() {
        mockGoAMSCallout();
        Contact agent = createAgent('ZeroPremAgent', '4007');
        Carrier__c carrier = createCarrier('ZeroPremCarrier');
        Product__c product = createProduct('ZeroPremProduct');
        Account agency = createAccount('ZeroPremAgency');
        createProductState(carrier.Id, product.Id, 'Life', 'Agent', 'Percentage', 5, null);
        
        Appointment__c appt = createAppointment(agent, carrier.Id, agency.Id, 'Carrier_Direct',
            'As_Earned_PMPM', '1_Month_Past', null, Date.today(), 'Life', 0, 1, 1, 'AG-ZEROPREM');

        Test.startTest();
        publishOne(createEvent(appt.Id, carrier.Name, 'AG-ZEROPREM', '4007', 'Life', '0', 'POL-ZEROPREM'));
        Test.stopTest();

        List<Commission_Record__c> records = [SELECT Gross_Amount__c FROM Commission_Record__c WHERE Appointment__c = :appt.Id];
        System.assertEquals(12, records.size());
        System.assertEquals(0, records[0].Gross_Amount__c, '0 * 5% = 0');
    }

    @IsTest
    static void testLargePremiumAmount() {
        mockGoAMSCallout();
        Contact agent = createAgent('LargePremAgent', '4008');
        Carrier__c carrier = createCarrier('LargePremCarrier');
        Product__c product = createProduct('LargePremProduct');
        Account agency = createAccount('LargePremAgency');
        createProductState(carrier.Id, product.Id, 'Life', 'Agent', 'Percentage', 5, null);
        
        Appointment__c appt = createAppointment(agent, carrier.Id, agency.Id, 'Carrier_Direct',
            'As_Earned_PMPM', '1_Month_Past', null, Date.today(), 'Life', 50000, 1, 1, 'AG-LARGEPREM');

        Test.startTest();
        publishOne(createEvent(appt.Id, carrier.Name, 'AG-LARGEPREM', '4008', 'Life', '50000', 'POL-LARGEPREM'));
        Test.stopTest();

        List<Commission_Record__c> records = [SELECT Gross_Amount__c FROM Commission_Record__c WHERE Appointment__c = :appt.Id];
        System.assertEquals(12, records.size());
        System.assertEquals(2500, records[0].Gross_Amount__c, '50000 * 5% = 2500');
    }

    @IsTest
    static void testCommissionLevelAgency() {
        mockGoAMSCallout();
        Contact agent = createAgent('AgencyLevelAgent', '4009');
        Carrier__c carrier = createCarrier('AgencyLevelCarrier');
        Product__c product = createProduct('AgencyLevelProduct');
        Account agency = createAccount('AgencyLevelAgency');
        // Levels must be 'Agent' - that's the only valid value, not 'Agency'
        createProductState(carrier.Id, product.Id, 'Life', 'Agent', 'Percentage', 8, null);
        
        // Commission_Level__c must be 1 to match the Product_State Commission_Level__c = '1'
        Appointment__c appt = createAppointment(agent, carrier.Id, agency.Id, 'Carrier_Direct',
            'As_Earned_PMPM', '1_Month_Past', null, Date.today(), 'Life', 1000, 1, 1, 'AG-AGENCYLEVEL');

        Test.startTest();
        publishOne(createEvent(appt.Id, carrier.Name, 'AG-AGENCYLEVEL', '4009', 'Life', '1000', 'POL-AGENCYLEVEL'));
        Test.stopTest();

        List<Commission_Record__c> records = [SELECT Gross_Amount__c FROM Commission_Record__c WHERE Appointment__c = :appt.Id];
        System.assertEquals(12, records.size(), 'Should create 12 records with 8% rate');
        System.assertEquals(80, records[0].Gross_Amount__c, '1000 * 8% = 80');
    }

    @IsTest
    static void testRenewalScheduleWithFixedRate() {
        mockGoAMSCallout();
        Contact agent = createAgent('RenewFixedAgent', '4010');
        Carrier__c carrier = createCarrier('RenewFixedCarrier');
        Product__c product = createProduct('RenewFixedProduct');
        Account agency = createAccount('RenewFixedAgency');
        Product_State__c ps = createProductState(carrier.Id, product.Id, 'Life', 'Agent', 'Percentage', 5, null);
        
        // Renewal schedule with percentage only (Product_State is Percentage type, so only populate Percentage)
        createRenewalSchedule(ps.Id, 3, null, 2, null, 1);
        
        Appointment__c appt = createAppointment(agent, carrier.Id, agency.Id, 'Carrier_Direct',
            'As_Earned_PMPM', '1_Month_Past', null, Date.today().addYears(-1), 'Life', 1000, 1, 1, 'AG-RENEWFIXED');

        Test.startTest();
        publishOne(createEvent(appt.Id, carrier.Name, 'AG-RENEWFIXED', '4010', 'Life', '1000', 'POL-RENEWFIXED'));
        Test.stopTest();

        List<Commission_Record__c> records = [SELECT Gross_Amount__c FROM Commission_Record__c WHERE Appointment__c = :appt.Id];
        System.assertEquals(12, records.size());
        System.assertEquals(30, records[0].Gross_Amount__c, 'Year 2 uses renewal percentage rate of 3%');
    }

    @IsTest
    static void testHighPercentageRate() {
        mockGoAMSCallout();
        Contact agent = createAgent('HighPercAgent', '4011');
        Carrier__c carrier = createCarrier('HighPercCarrier');
        Product__c product = createProduct('HighPercProduct');
        Account agency = createAccount('HighPercAgency');
        createProductState(carrier.Id, product.Id, 'Life', 'Agent', 'Percentage', 15, null);
        
        Appointment__c appt = createAppointment(agent, carrier.Id, agency.Id, 'Carrier_Direct',
            'As_Earned_PMPM', '1_Month_Past', null, Date.today(), 'Life', 1000, 1, 1, 'AG-HIGHPERC');

        Test.startTest();
        publishOne(createEvent(appt.Id, carrier.Name, 'AG-HIGHPERC', '4011', 'Life', '1000', 'POL-HIGHPERC'));
        Test.stopTest();

        List<Commission_Record__c> records = [SELECT Gross_Amount__c FROM Commission_Record__c WHERE Appointment__c = :appt.Id];
        System.assertEquals(12, records.size());
        System.assertEquals(150, records[0].Gross_Amount__c, '1000 * 15% = 150');
    }

}