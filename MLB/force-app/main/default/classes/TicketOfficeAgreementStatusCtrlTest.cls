@IsTest
private class TicketOfficeAgreementStatusCtrlTest {

    private static Opportunity newOpp(String agreementType) {
        Id rt = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Ticket_Sales').getRecordTypeId();
        return new Opportunity(RecordTypeId = rt, Name = 'Ticket Office Test ' + agreementType, StageName = 'Qualification',
            CloseDate = Date.today(), Agreement_Type__c = agreementType);
    }

    private static TicketOfficeAgreementStatusCtrl ctrlFor(Id oppId) {
        TicketOfficeAgreementStatusCtrl ctrl = new TicketOfficeAgreementStatusCtrl();
        ctrl.opportunityId = oppId;
        return ctrl;
    }

    @IsTest
    static void returnsStatusPresentationForEachAdobeStatus() {
        Opportunity opp = newOpp('Flex');
        insert opp;
        echosign_dev1__SIGN_Agreement__c agr = new echosign_dev1__SIGN_Agreement__c(
            Name = 'Test Agreement', echosign_dev1__Opportunity__c = opp.Id, echosign_dev1__Status__c = 'Out for Approval');
        insert agr;

        Map<String, String> expected = new Map<String, String>{
            'Out for Approval' => 'Sent for Sales Manager approval',
            'Out for Signature' => 'Approved by Sales Manager',
            'Signed' => 'Signed by customer',
            'Cancelled / Declined' => 'Agreement declined',
            'Draft' => 'Draft'
        };

        Test.startTest();
        for (String status : expected.keySet()) {
            agr.echosign_dev1__Status__c = status;
            update agr;
            TicketOfficeAgreementStatusCtrl ctrl = ctrlFor(opp.Id);
            System.assertEquals(status, ctrl.getAdobeStatus());
            System.assertEquals(expected.get(status), ctrl.getStatusLabel());
            System.assertEquals('Test Agreement', ctrl.getAgreementName());
            System.assert(String.isNotBlank(ctrl.getStatusNote()));
            System.assert(String.isNotBlank(ctrl.getStatusIcon()));
            System.assert(ctrl.getStatusColor().startsWith('#'));
            System.assert(ctrl.getStatusTint().startsWith('#'));
        }
        Test.stopTest();
    }

    @IsTest
    static void handlesOpportunityWithoutAgreement() {
        TicketOfficeAgreementStatusCtrl ctrl = new TicketOfficeAgreementStatusCtrl();
        System.assertEquals('Unknown', ctrl.getAdobeStatus());
        System.assertEquals('Unknown', ctrl.getStatusLabel());
        System.assertEquals('', ctrl.getAgreementName());
        System.assertEquals(0, ctrl.getSummaryColumns().size());
    }

    @IsTest
    static void buildsMembershipSummaryWithSeatAndParkingTotals() {
        Opportunity opp = newOpp('Membership');
        insert opp;
        String planType = Membership_Agreement__c.Plan_Type__c.getDescribe().getPicklistValues()[0].getValue();
        String parkingType = Membership_Agreement__c.Plan_Type_Parking__c.getDescribe().getPicklistValues()[0].getValue();
        insert new List<Membership_Agreement__c>{
            new Membership_Agreement__c(Opportunity_LUR__c = opp.Id, Plan_Type__c = planType, Qty_Seats__c = 2,
                Plan_Type_Parking__c = parkingType, Qty_Parking__c = 2),
            new Membership_Agreement__c(Opportunity_LUR__c = opp.Id, Plan_Type__c = planType, Qty_Seats__c = 3)
        };

        List<TicketOfficeAgreementStatusCtrl.SummaryColumn> cols = ctrlFor(opp.Id).getSummaryColumns();
        System.assertEquals(4, cols.size());
        System.assertEquals('AGREEMENT VALUE', cols[0].label);
        System.assert(cols[0].primary);
        System.assertEquals('5', cols[2].value);
        System.assertEquals('2', cols[3].value);
    }

    @IsTest
    static void buildsSummaryForOtherAgreementTypes() {
        Opportunity suite = newOpp('Suite Lease');
        suite.This_Season_Total_Amount__c = 33120;
        Opportunity multi = newOpp('Multi-Product');
        multi.Amount_allocated_to_Flex__c = 7500;
        multi.Amount_allocated_to_Suites__c = 15000;
        multi.Amount_allocated_to_Groups__c = 5000;
        Opportunity flex = newOpp('Flex');
        flex.Total_Flex_Membership__c = 6000;
        insert new List<Opportunity>{ suite, multi, flex };

        List<TicketOfficeAgreementStatusCtrl.SummaryColumn> suiteCols = ctrlFor(suite.Id).getSummaryColumns();
        System.assertEquals(4, suiteCols.size());
        System.assertEquals('$33,120.00', suiteCols[0].value);

        List<TicketOfficeAgreementStatusCtrl.SummaryColumn> multiCols = ctrlFor(multi.Id).getSummaryColumns();
        System.assertEquals(4, multiCols.size());
        System.assertEquals('$7,500.00', multiCols[1].value);
        System.assertEquals('$15,000.00', multiCols[2].value);

        List<TicketOfficeAgreementStatusCtrl.SummaryColumn> flexCols = ctrlFor(flex.Id).getSummaryColumns();
        System.assertEquals(2, flexCols.size());
        System.assertEquals('$6,000.00', flexCols[0].value);
        System.assertEquals('—', flexCols[1].value);
    }

    @IsTest
    static void formatsMoneyAndResolvesLogo() {
        System.assertEquals(null, TicketOfficeAgreementStatusCtrl.money(null));
        System.assertEquals('$0.00', TicketOfficeAgreementStatusCtrl.money(0));
        System.assertEquals('$999.50', TicketOfficeAgreementStatusCtrl.money(999.5));
        System.assertEquals('$1,234,567.89', TicketOfficeAgreementStatusCtrl.money(1234567.891));
        System.assertEquals('-$1,000.00', TicketOfficeAgreementStatusCtrl.money(-1000));
        String logo = new TicketOfficeAgreementStatusCtrl().getLogoUrl();
        System.assert(logo == '' || logo.contains('servlet.ImageServer'));
    }
}
