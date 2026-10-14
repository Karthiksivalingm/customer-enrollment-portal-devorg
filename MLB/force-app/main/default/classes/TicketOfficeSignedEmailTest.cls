@IsTest
private class TicketOfficeSignedEmailTest {

    private static Opportunity newOpp() {
        Id rt = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Ticket_Sales').getRecordTypeId();
        Opportunity o = new Opportunity(RecordTypeId = rt, Name = 'Signed Email Test', StageName = 'Qualification',
            CloseDate = Date.today(), Agreement_Type__c = 'Flex', Total_Flex_Membership__c = 6000,
            Opportunity_Owner_Manager__c = UserInfo.getUserId());
        insert o;
        return o;
    }

    private static echosign_dev1__SIGN_Agreement__c newAgreement(Id oppId) {
        echosign_dev1__SIGN_Agreement__c a = new echosign_dev1__SIGN_Agreement__c(
            Name = 'Flex Agreement', echosign_dev1__Opportunity__c = oppId, echosign_dev1__Status__c = 'Out for Signature');
        insert a;
        return a;
    }

    private static TicketOfficeSignedEmail.Request request(Id agreementId, Id oppId) {
        TicketOfficeSignedEmail.Request r = new TicketOfficeSignedEmail.Request();
        r.agreementId = agreementId;
        r.opportunityId = oppId;
        return r;
    }

    @IsTest
    static void sendsEmailWithSignedPdfAttached() {
        Opportunity o = newOpp();
        echosign_dev1__SIGN_Agreement__c a = newAgreement(o.Id);
        ContentVersion approved = new ContentVersion(Title = 'Flex Agreement - approved', PathOnClient = 'approved.pdf',
            VersionData = Blob.valueOf('approved'), FirstPublishLocationId = a.Id);
        ContentVersion signed = new ContentVersion(Title = 'Flex Agreement - signed', PathOnClient = 'signed.pdf',
            VersionData = Blob.valueOf('signed'), FirstPublishLocationId = a.Id);
        insert new List<ContentVersion>{ approved, signed };

        Test.startTest();
        TicketOfficeSignedEmail.send(new List<TicketOfficeSignedEmail.Request>{ request(a.Id, o.Id) });
        Test.stopTest();

        System.assertEquals(1, TicketOfficeSignedEmail.sentEmails.size());
        Messaging.SingleEmailMessage mail = TicketOfficeSignedEmail.sentEmails[0];
        System.assert(mail.getToAddresses().contains(System.Label.Ticket_Office_Email));
        System.assertEquals(2, mail.getToAddresses().size(), 'Ticket Office + Sales Manager');
        System.assertEquals(new List<Id>{ signed.Id }, mail.getEntityAttachments());
        System.assert(mail.getSubject().startsWith('Flex Details'));
    }

    @IsTest
    static void sendsWithoutAttachmentWhenNoSignedPdf() {
        Opportunity o = newOpp();
        echosign_dev1__SIGN_Agreement__c a = newAgreement(o.Id);

        Test.startTest();
        TicketOfficeSignedEmail.send(new List<TicketOfficeSignedEmail.Request>{ request(a.Id, o.Id), null });
        Test.stopTest();

        System.assertEquals(1, TicketOfficeSignedEmail.sentEmails.size());
        System.assert(TicketOfficeSignedEmail.sentEmails[0].getEntityAttachments() == null
            || TicketOfficeSignedEmail.sentEmails[0].getEntityAttachments().isEmpty());
    }

    @IsTest
    static void ignoresEmptyRequests() {
        Test.startTest();
        TicketOfficeSignedEmail.send(new List<TicketOfficeSignedEmail.Request>{ new TicketOfficeSignedEmail.Request() });
        Test.stopTest();
        System.assertEquals(0, TicketOfficeSignedEmail.sentEmails.size());
    }
}
