@isTest
public class AddressDuplicateServiceTest {
    
    @isTest
    static void testNormalizationAndIdentity() {
        String addr1 = '123 Main St';
        String addr2 = 'Main Street 123';
        Test.startTest();
        Boolean isIndentical = AddressDuplicateService.areAddressesIdentical(addr1, addr2);
        Test.stopTest();

        System.assertEquals(true, isIndentical, 'Addresses should be identical.');
    }

    @isTest
    static void testFullComparisonCoverageNonDuplicate() {
        String street1 = '10 Main St'; 
        String city1 = 'Test-City';
        String zip1 = '12345';

        String street2 = '11 Main Street'; 
        String city2 = 'Test-City';
        String zip2 = '123-45';

        Test.startTest();
        Decimal result = AddressDuplicateService.compareFullAddresses(
            street1, city1, zip1,
            street2, city2, zip2
        );
        Test.stopTest();

        System.assert(result > 70 && result < 100, 'Addresses should have high similarity score, but not 100%');
    }

    @isTest
    static void testFullComparisonCoverageDuplicate() {
        String street1 = '10 Main St'; 
        String city1 = 'Test-City';
        String zip1 = '12345';

        String street2 = 'Main Street, 10'; 
        String city2 = 'Test-City';
        String zip2 = '123-45';

        Test.startTest();
        Decimal result = AddressDuplicateService.compareFullAddresses(
            street1, city1, zip1,
            street2, city2, zip2
        );
        Test.stopTest();

        System.assert(result == 100, 'Addresses should have 100% similarity score');
    }
}