@isTest
private class SwoogoQuestionMapServiceTest {

    @isTest
    static void testGetMapForEventBuildsMappingAndCaches() {
        Test.setMock(HttpCalloutMock.class, new SwoogoCalloutMock());
        Test.startTest();
        SwoogoQuestionMapService.EventQuestionMap qm1 =
            SwoogoQuestionMapService.getMapForEvent('1001');
        // Second call should hit the cache — no new callout, same result
        SwoogoQuestionMapService.EventQuestionMap qm2 =
            SwoogoQuestionMapService.getMapForEvent('1001');
        Test.stopTest();

        System.assertEquals('c_1002', qm1.inboundDateAttr);
        System.assertEquals('c_1003', qm1.inboundTimeAttr);
        System.assertEquals('c_1004', qm1.outboundDateAttr);
        System.assertEquals('c_1005', qm1.outboundTimeAttr);
        System.assertEquals('c_1001', qm1.simpleFieldMap.get('Hotel_Name__c'));
        System.assertEquals('c_1006', qm1.simpleFieldMap.get('Relationship_to__c'));
        System.assert(qm1.hasAnyMapping);
        System.assert(qm1 === qm2);
        System.debug(qm1.toString());
    }

    @isTest
    static void testApplyToGuestListSetsFields() {
        SwoogoQuestionMapService.EventQuestionMap qm = new SwoogoQuestionMapService.EventQuestionMap();
        qm.simpleFieldMap.put('Hotel_Name__c', 'c_1001');
        qm.inboundDateAttr = 'c_1002';
        qm.inboundTimeAttr = 'c_1003';
        qm.outboundDateAttr = 'c_1004';
        qm.outboundTimeAttr = null; // exercise default 00:00:00 branch
        qm.buildCustomFieldsList();

        Guest_List__c gl = new Guest_List__c();
        Map<String,Object> raw = new Map<String,Object>{
            'c_1001' => 'Hilton',
            'c_1002' => '2026-05-30', 'c_1003' => '14:00:00',
            'c_1004' => '2026-06-03'
        };

        Test.startTest();
        qm.applyToGuestList(gl, raw);
        Test.stopTest();

        System.assertEquals('Hilton', gl.Hotel_Name__c);
        System.assertNotEquals(null, gl.Inbound_Date_Time__c);
        System.assertNotEquals(null, gl.Outbound_Date_Time__c);
    }

    @isTest
    static void testApplyToGuestListHandlesBadDateGracefully() {
        SwoogoQuestionMapService.EventQuestionMap qm = new SwoogoQuestionMapService.EventQuestionMap();
        qm.inboundDateAttr = 'c_bad';
        qm.buildCustomFieldsList();

        Guest_List__c gl = new Guest_List__c();
        Map<String,Object> raw = new Map<String,Object>{ 'c_bad' => 'not-a-date' };

        Test.startTest();
        qm.applyToGuestList(gl, raw);
        Test.stopTest();

        System.assertEquals(null, gl.Inbound_Date_Time__c);
    }

    @isTest
    static void testHasAnyMappingFalseWhenEmpty() {
        SwoogoQuestionMapService.EventQuestionMap qm = new SwoogoQuestionMapService.EventQuestionMap();
        System.assertEquals(false, qm.hasAnyMapping);
    }
}