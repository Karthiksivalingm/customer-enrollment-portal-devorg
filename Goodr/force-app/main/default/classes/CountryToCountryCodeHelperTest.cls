@isTest
public class CountryToCountryCodeHelperTest {

    @isTest
    static void testGetCountryCode_AllScenarios() {
        System.assertEquals(null, CountryToCountryCodeHelper.getCountryCode(null), 'Null should return null');
        System.assertEquals(null, CountryToCountryCodeHelper.getCountryCode('   '), 'Blank string should return null');
        
        System.assertEquals('US', CountryToCountryCodeHelper.getCountryCode('US'));
        System.assertEquals('CA', CountryToCountryCodeHelper.getCountryCode('ca'));
        System.assertEquals('US', CountryToCountryCodeHelper.getCountryCode(' us '));
        
        System.assertEquals('US', CountryToCountryCodeHelper.getCountryCode('united states'));
        System.assertEquals('CA', CountryToCountryCodeHelper.getCountryCode('Canada'));
        
        System.assertEquals(null, CountryToCountryCodeHelper.getCountryCode('Mexico'), 'Unknown country should return null');
    }
}