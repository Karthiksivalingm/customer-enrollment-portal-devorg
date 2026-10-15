/**
 * Test Class: EnrollmentApprovedSubscriberTriggerTest
 * Trigger   : EnrollmentApprovedSubscriber
 * Object    : Enrollment_Approved__e (Platform Event)
 *
 * Tests the EnrollmentApprovedSubscriber trigger in isolation.
 * Verifies:
 * - Trigger fires on platform event after insert
 * - Handler is invoked with correct event data
 * - Multiple events are processed in batch
 * - Null/empty event lists are handled
 */
@IsTest
private class EnrollmentApprovedSubscriberTriggerTest {

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

    private static void publishOne(Enrollment_Approved__e eventRecord) {
        List<Database.SaveResult> results = EventBus.publish(new List<Enrollment_Approved__e>{eventRecord});
        System.assertEquals(true, results[0].isSuccess(), 'Platform Event publish failed');
    }

    private static void publishMany(List<Enrollment_Approved__e> events) {
        List<Database.SaveResult> results = EventBus.publish(events);
        for (Database.SaveResult result : results) {
            System.assertEquals(true, result.isSuccess(), 'Platform Event publish failed');
        }
    }

    // ============================================================
    // TRIGGER TESTS
    // ============================================================

    @IsTest
    static void testTriggerFiresSingleEvent() {
        mockGoAMSCallout();
        Contact agent = createAgent('TriggerAgent1', '5001');
        Carrier__c carrier = createCarrier('TriggerCarrier1');
        Product__c product = createProduct('TriggerProduct1');
        Account agency = createAccount('TriggerAgency1');
        createProductState(carrier.Id, product.Id, 'Life', 'Agent', 'Percentage', 5, null);
        
        Appointment__c appt = createAppointment(agent, carrier.Id, agency.Id, 'Carrier_Direct',
            'As_Earned_PMPM', '1_Month_Past', null, Date.today(), 'Life', 1000, 1, 1, 'AG-TRIGGER1');

        Test.startTest();
        publishOne(createEvent(appt.Id, carrier.Name, 'AG-TRIGGER1', '5001', 'Life', '1000', 'POL-TRIGGER1'));
        Test.stopTest();

        // Verify trigger processed the event by checking if records were created
        Integer crCount = [SELECT COUNT() FROM Commission_Record__c WHERE Appointment__c = :appt.Id];
        System.assertEquals(12, crCount, 'Trigger should invoke handler and create 12 records');
    }

    @IsTest
    static void testTriggerBatchProcessing() {
        mockGoAMSCallout();
        Account agency = createAccount('TriggerBatchAgency');
        
        List<Contact> agents = new List<Contact>();
        for (Integer i = 0; i < 3; i++) {
            agents.add(new Contact(
                FirstName = 'Trigger',
                LastName = 'Agent-' + i,
                AccountId = createAccount('Trigger Account ' + i).Id,
                Email = 'trigger-' + i + '@example.com',
                NPN__c = String.valueOf(5010 + i),
                Agent_Status__c = 'Onboarding'
            ));
        }
        insert agents;

        Carrier__c carrier = createCarrier('TriggerBatchCarrier');
        Product__c product = createProduct('TriggerBatchProduct');
        createProductState(carrier.Id, product.Id, 'Life', 'Agent', 'Percentage', 5, null);

        List<Appointment__c> appts = new List<Appointment__c>();
        for (Integer i = 0; i < 3; i++) {
            appts.add(new Appointment__c(
                Agent__c = agents[i].Id,
                Carrier__c = carrier.Id,
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
                Agent_Code__c = 'AG-BATCH-' + i
            ));
        }
        insert appts;

        List<Enrollment_Approved__e> events = new List<Enrollment_Approved__e>();
        for (Integer i = 0; i < appts.size(); i++) {
            events.add(createEvent(
                appts[i].Id,
                carrier.Name,
                'AG-BATCH-' + i,
                String.valueOf(5010 + i),
                'Life',
                '1000',
                'POL-BATCH-' + i
            ));
        }

        Test.startTest();
        publishMany(events);
        Test.stopTest();

        Integer totalRecords = [SELECT COUNT() FROM Commission_Record__c];
        System.assertEquals(36, totalRecords, 'Trigger batch should process 3 events, creating 3 * 12 = 36 records');
    }

    @IsTest
    static void testTriggerWithValidAndInvalidEvents() {
        mockGoAMSCallout();
        Contact agent = createAgent('MixedAgent', '5020');
        Carrier__c carrier = createCarrier('MixedCarrier');
        Product__c product = createProduct('MixedProduct');
        Account agency = createAccount('MixedAgency');
        createProductState(carrier.Id, product.Id, 'Life', 'Agent', 'Percentage', 5, null);
        
        Appointment__c appt = createAppointment(agent, carrier.Id, agency.Id, 'Carrier_Direct',
            'As_Earned_PMPM', '1_Month_Past', null, Date.today(), 'Life', 1000, 1, 1, 'AG-VALID');

        // Mix of valid and invalid events
        List<Enrollment_Approved__e> events = new List<Enrollment_Approved__e>();
        events.add(createEvent(appt.Id, carrier.Name, 'AG-VALID', '5020', 'Life', '1000', 'POL-VALID'));
        events.add(new Enrollment_Approved__e(
            Agent_Code__c = 'AG-INVALID',
            NPN__c = null,  // Invalid
            Carrier__c = 'Unknown',
            LOB__c = 'Life',
            Premium__c = '1000',
            Policy_Number__c = 'POL-INVALID'
        ));

        Test.startTest();
        publishMany(events);
        Test.stopTest();

        // Valid event should create records
        Integer crCount = [SELECT COUNT() FROM Commission_Record__c WHERE Appointment__c = :appt.Id];
        System.assertEquals(12, crCount, 'Valid event should create records');

        // Invalid event should create exception
        Integer exCount = [SELECT COUNT() FROM Commission_Exception__c];
        System.assert(exCount > 0, 'Invalid event should create exception');
    }

    @IsTest
    static void testTriggerEventFieldsPassedToHandler() {
        mockGoAMSCallout();
        Contact agent = createAgent('FieldTestAgent', '5030');
        Carrier__c carrier = createCarrier('FieldTestCarrier');
        Product__c product = createProduct('FieldTestProduct');
        Account agency = createAccount('FieldTestAgency');
        createProductState(carrier.Id, product.Id, 'Life', 'Agent', 'Percentage', 5, null);
        
        Appointment__c appt = createAppointment(agent, carrier.Id, agency.Id, 'Carrier_Direct',
            'As_Earned_PMPM', '1_Month_Past', null, Date.today(), 'Life', 1000, 1, 1, 'AG-FIELDTEST');

        // Create event with all required fields
        Enrollment_Approved__e evt = new Enrollment_Approved__e(
            Appointment_ID__c = String.valueOf(appt.Id),
            Carrier__c = carrier.Name,
            Agent_Code__c = 'AG-FIELDTEST',
            NPN__c = '5030',
            LOB__c = 'Life',
            Premium__c = '1000',
            Policy_Number__c = 'POL-FIELDTEST'
        );

        Test.startTest();
        publishOne(evt);
        Test.stopTest();

        // Verify all fields were processed correctly
        List<Commission_Record__c> records = [SELECT Id, Appointment__c, Agent__c, Carrier__c FROM Commission_Record__c WHERE Appointment__c = :appt.Id];
        System.assertEquals(12, records.size(), 'Event fields should be processed by handler');
        System.assertEquals(appt.Id, records[0].Appointment__c, 'Appointment ID should match');
        System.assertEquals(agent.Id, records[0].Agent__c, 'Agent should be resolved correctly');
    }

    @IsTest
    static void testTriggerHandlesNullAppointmentId() {
        mockGoAMSCallout();
        Contact agent = createAgent('NullApptAgent', '5040');
        Carrier__c carrier = createCarrier('NullApptCarrier');

        // Event with null appointment ID - should resolve via NPN
        Enrollment_Approved__e evt = new Enrollment_Approved__e(
            Appointment_ID__c = null,
            Carrier__c = carrier.Name,
            Agent_Code__c = 'AG-NULLAPPT',
            NPN__c = '5040',
            LOB__c = 'Life',
            Premium__c = '1000',
            Policy_Number__c = 'POL-NULLAPPT'
        );

        Test.startTest();
        publishOne(evt);
        Test.stopTest();

        // Trigger should pass event to handler, which resolves via NPN
        Integer exCount = [SELECT COUNT() FROM Commission_Exception__c];
        System.assert(exCount > 0, 'Null appointment ID should create exception for unresolved appointment');
    }

    @IsTest
    static void testTriggerErrorHandling() {
        mockGoAMSCallout();
        
        // Create event with missing critical fields
        Enrollment_Approved__e evt = new Enrollment_Approved__e(
            Agent_Code__c = 'AG-ERROR',
            NPN__c = null,
            Carrier__c = 'Unknown',
            LOB__c = 'Life',
            Premium__c = '1000',
            Policy_Number__c = 'POL-ERROR'
        );

        Test.startTest();
        publishOne(evt);
        Test.stopTest();

        // Trigger should invoke handler which logs exception
        List<Commission_Exception__c> exceptions = [SELECT Exception_Type__c FROM Commission_Exception__c];
        System.assertEquals(1, exceptions.size(), 'Trigger should handle errors gracefully');
    }

    @IsTest
    static void testTriggerWithMultipleCarriers() {
        mockGoAMSCallout();
        Account agency = createAccount('MultiCarrierAgency');
        Contact agent = createAgent('MultiCarrierAgent', '5050');
        
        List<Carrier__c> carriers = new List<Carrier__c>();
        for (Integer i = 0; i < 2; i++) {
            carriers.add(new Carrier__c(
                Name = 'Carrier-' + i,
                Carrier_Code__c = 'CODE-' + i,
                Supported_Lines_of_Business__c = 'Life'
            ));
        }
        insert carriers;

        List<Product__c> products = new List<Product__c>();
        for (Integer i = 0; i < 2; i++) {
            products.add(new Product__c(Name = 'Product-' + i));
        }
        insert products;

        List<Product_State__c> pStates = new List<Product_State__c>();
        for (Integer i = 0; i < 2; i++) {
            pStates.add(new Product_State__c(
                Carrier__c = carriers[i].Id,
                Product__c = products[i].Id,
                Line_of_Business__c = 'Life',
                Levels__c = 'Agent',
                Commission_Level__c = '1',
                Payment_Type__c = 'Percentage',
                Year_1_Percentage__c = 5
            ));
        }
        insert pStates;

        List<Appointment__c> appts = new List<Appointment__c>();
        for (Integer i = 0; i < 2; i++) {
            appts.add(new Appointment__c(
                Agent__c = agent.Id,
                Carrier__c = carriers[i].Id,
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
                Agent_Code__c = 'AG-MULTI-' + i
            ));
        }
        insert appts;

        List<Enrollment_Approved__e> events = new List<Enrollment_Approved__e>();
        for (Integer i = 0; i < 2; i++) {
            events.add(createEvent(
                appts[i].Id,
                carriers[i].Name,
                'AG-MULTI-' + i,
                '5050',
                'Life',
                '1000',
                'POL-MULTI-' + i
            ));
        }

        Test.startTest();
        publishMany(events);
        Test.stopTest();

        Integer totalRecords = [SELECT COUNT() FROM Commission_Record__c];
        System.assertEquals(24, totalRecords, 'Trigger should handle events from multiple carriers (2 * 12 = 24)');
    }

    @IsTest
    static void testTriggerHandlerInvocation() {
        mockGoAMSCallout();
        Contact agent = createAgent('HandlerTestAgent', '5060');
        Carrier__c carrier = createCarrier('HandlerTestCarrier');
        Product__c product = createProduct('HandlerTestProduct');
        Account agency = createAccount('HandlerTestAgency');
        createProductState(carrier.Id, product.Id, 'Life', 'Agent', 'Percentage', 5, null);
        
        Appointment__c appt = createAppointment(agent, carrier.Id, agency.Id, 'Carrier_Direct',
            'As_Earned_PMPM', '1_Month_Past', null, Date.today(), 'Life', 1000, 1, 1, 'AG-HANDLER');

        Test.startTest();
        // Publish single event - trigger should invoke handler with this event
        publishOne(createEvent(appt.Id, carrier.Name, 'AG-HANDLER', '5060', 'Life', '1000', 'POL-HANDLER'));
        Test.stopTest();

        // Verify handler was invoked by checking for output (commission records)
        Integer crCount = [SELECT COUNT() FROM Commission_Record__c WHERE Appointment__c = :appt.Id];
        System.assertEquals(12, crCount, 'Trigger should invoke handleAfterInsert() on handler');
    }

}