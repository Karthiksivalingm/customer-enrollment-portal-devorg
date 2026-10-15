@isTest
private class SharePointEventFilesControllerTest {

    // Helper to create an Event File Link + related SharePoint Event Files
    @TestSetup
    static void setupData() {

        // 1. Create Event WITHOUT manually setting Event_File_Link__c.
        // Automation (Flow/Trigger) on Event appears to auto-create and
        // assign its own Event_File_Link__c record on insert, so we let
        // that happen naturally instead of fighting it.
        Event evt = new Event(
            Subject       = 'Test Event With Files',
            StartDateTime = DateTime.now(),
            EndDateTime   = DateTime.now().addHours(1)
        );
        insert evt;

        // 2. Read back the Event to get the ACTUAL Event_File_Link__c
        // value that automation assigned (do not assume it's null or
        // reuse a manually created record - it will be overridden).
        evt = [SELECT Id, Event_File_Link__c FROM Event WHERE Id = :evt.Id LIMIT 1];

        // 3. Create an Event with NO Event File Link (to test empty-result branch)
        Event evtNoLink = new Event(
            Subject       = 'Test Event Without Link',
            StartDateTime = DateTime.now(),
            EndDateTime   = DateTime.now().addHours(1)
        );
        insert evtNoLink;

        // 4. Create SharePoint Event Files linked to the SAME Event File Link
        // that automation actually assigned to the Event above.
        // Mix of regular Agenda files (Minutesof_Meeting__c = false)
        // and Minutes of Meeting files (Minutesof_Meeting__c = true)
        // so both getFiles() and getMeetingMinutesFiles() can be verified
        // against the SAME Event File Link.
        List<SharePoint_Event_Files__c> sefList = new List<SharePoint_Event_Files__c>();
        sefList.add(new SharePoint_Event_Files__c(
            Event_File_Link__c = evt.Event_File_Link__c,
            File_Name__c = 'Agenda - Test.pdf',
            File_Path__c = 'https://example.sharepoint.com/sites/CPCRM/Documents/2026/Agenda-Test.pdf',
            Minutesof_Meeting__c = false
        ));
        sefList.add(new SharePoint_Event_Files__c(
            Event_File_Link__c = evt.Event_File_Link__c,
            File_Name__c = 'Presentation - Test.pdf',
            File_Path__c = 'https://example.sharepoint.com/sites/CPCRM/Documents/2026/Presentation-Test.pdf',
            Minutesof_Meeting__c = false
        ));
        sefList.add(new SharePoint_Event_Files__c(
            Event_File_Link__c = evt.Event_File_Link__c,
            File_Name__c = 'MoM - Test.docx',
            File_Path__c = 'https://example.sharepoint.com/sites/CPCRM/Documents/2026/MoM-Test.docx',
            Minutesof_Meeting__c = true
        ));
        insert sefList;
    }

    @isTest
    static void testGetFiles_WithRelatedFiles_ReturnsOnlyNonMinutesFiles() {
        Event evt = [
            SELECT Id, Event_File_Link__c
            FROM Event
            WHERE Subject = 'Test Event With Files'
            LIMIT 1
        ];

        System.assertNotEquals(null, evt.Event_File_Link__c,
            'Event_File_Link__c should not be null right after insert - if this fails, something (a Flow/Trigger/Process) is clearing or overriding this field on save.');

        Id eflId = evt.Event_File_Link__c;

        List<SharePoint_Event_Files__c> allSefRecords = [
            SELECT Id, Event_File_Link__c, File_Name__c, Minutesof_Meeting__c
            FROM SharePoint_Event_Files__c
        ];
        System.assertEquals(3, allSefRecords.size(),
            'Expected 3 SEF records to exist at all - if this fails, the insert in @TestSetup itself did not create/persist them as expected.');

        for (SharePoint_Event_Files__c sef : allSefRecords) {
            System.assertEquals(eflId, sef.Event_File_Link__c,
                'SEF record Event_File_Link__c (' + sef.Event_File_Link__c + ') does not match the Event Event_File_Link__c (' + eflId + ') - something is overriding one of these values on save, likely a Trigger or Flow.');
        }

        Test.startTest();
        List<SharePoint_Event_Files__c> results =
            SharePointEventFilesController.getFiles(evt.Id);
        Test.stopTest();

        System.assertEquals(2, results.size(),
            'Expected only the 2 non-Minutes-of-Meeting files to be returned by getFiles');

        Set<String> fileNames = new Set<String>();
        for (SharePoint_Event_Files__c sef : results) {
            fileNames.add(sef.File_Name__c);
            System.assert(sef.File_Path__c.startsWith('https://'),
                'File path should be a valid URL');
            System.assertEquals(false, sef.Minutesof_Meeting__c,
                'getFiles should never return a record flagged as Minutes of Meeting');
        }
        System.assert(fileNames.contains('Agenda - Test.pdf'));
        System.assert(fileNames.contains('Presentation - Test.pdf'));
        System.assert(!fileNames.contains('MoM - Test.docx'),
            'Minutes of Meeting file should be excluded from getFiles results');
    }

    @isTest
    static void testGetFiles_NoEventFileLink_ReturnsEmptyList() {
        Event evtNoLink = [
            SELECT Id
            FROM Event
            WHERE Subject = 'Test Event Without Link'
            LIMIT 1
        ];

        Test.startTest();
        List<SharePoint_Event_Files__c> results =
            SharePointEventFilesController.getFiles(evtNoLink.Id);
        Test.stopTest();

        System.assertEquals(0, results.size(),
            'Expected empty list when Event has no Event File Link');
    }

    @isTest
    static void testGetFiles_EventFileLinkWithNoFiles_ReturnsEmptyList() {
        // Automation auto-creates a fresh Event_File_Link__c on insert,
        // and no SharePoint_Event_Files__c records are linked to it yet.
        Event evt = new Event(
            Subject       = 'Test Event Empty Link',
            StartDateTime = DateTime.now(),
            EndDateTime   = DateTime.now().addHours(1)
        );
        insert evt;

        Test.startTest();
        List<SharePoint_Event_Files__c> results =
            SharePointEventFilesController.getFiles(evt.Id);
        Test.stopTest();

        System.assertEquals(0, results.size(),
            'Expected empty list when Event File Link has no related files');
    }

    @isTest
    static void testGetMeetingMinutesFiles_WithRelatedFiles_ReturnsOnlyMinutesFiles() {
        Event evt = [
            SELECT Id, Event_File_Link__c
            FROM Event
            WHERE Subject = 'Test Event With Files'
            LIMIT 1
        ];

        System.assertNotEquals(null, evt.Event_File_Link__c,
            'Event_File_Link__c should not be null right after insert');

        Test.startTest();
        List<SharePoint_Event_Files__c> results =
            SharePointEventFilesController.getMeetingMinutesFiles(evt.Id);
        Test.stopTest();

        System.assertEquals(1, results.size(),
            'Expected only the 1 Minutes-of-Meeting file to be returned');
        System.assertEquals('MoM - Test.docx', results[0].File_Name__c);
        System.assertEquals(true, results[0].Minutesof_Meeting__c,
            'getMeetingMinutesFiles should only return records flagged as Minutes of Meeting');
        System.assert(results[0].File_Path__c.startsWith('https://'),
            'File path should be a valid URL');
    }

    @isTest
    static void testGetMeetingMinutesFiles_NoEventFileLink_ReturnsEmptyList() {
        Event evtNoLink = [
            SELECT Id
            FROM Event
            WHERE Subject = 'Test Event Without Link'
            LIMIT 1
        ];

        Test.startTest();
        List<SharePoint_Event_Files__c> results =
            SharePointEventFilesController.getMeetingMinutesFiles(evtNoLink.Id);
        Test.stopTest();

        System.assertEquals(0, results.size(),
            'Expected empty list when Event has no Event File Link');
    }

    @isTest
    static void testGetMeetingMinutesFiles_EventFileLinkWithNoFiles_ReturnsEmptyList() {
        Event evt = new Event(
            Subject       = 'Test Event Empty Link MoM',
            StartDateTime = DateTime.now(),
            EndDateTime   = DateTime.now().addHours(1)
        );
        insert evt;

        Test.startTest();
        List<SharePoint_Event_Files__c> results =
            SharePointEventFilesController.getMeetingMinutesFiles(evt.Id);
        Test.stopTest();

        System.assertEquals(0, results.size(),
            'Expected empty list when Event File Link has no related files');
    }
}