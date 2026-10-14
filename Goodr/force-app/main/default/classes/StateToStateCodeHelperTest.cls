@IsTest
public class StateToStateCodeHelperTest {

    @isTest
    static void testValidStateCodeInput() {
        String input = 'ca';
        String result = StateToStateCodeHelper.getStateCode(input);
        System.assertEquals('CA', result, 'Should return uppercase version of valid state code');
    }

    @isTest
    static void testValidStateNameInput() {
        String input = 'California';
        String result = StateToStateCodeHelper.getStateCode(input);
        System.assertEquals('CA', result, 'Should return state code for given state name');
    }

    @isTest
    static void testInvalidInput() {
        String input = 'Californi';
        String result = StateToStateCodeHelper.getStateCode(input);
        System.assertEquals(null, result, 'Should return null for invalid state name');
    }

    @isTest
    static void testNullInput() {
        String result = StateToStateCodeHelper.getStateCode(null);
        System.assertEquals(null, result, 'Should return null for null input');
    }

    @isTest
    static void testEmptyInput() {
        String result = StateToStateCodeHelper.getStateCode('');
        System.assertEquals(null, result, 'Should return null for empty input');
    }

    @isTest
    static void testWhitespaceInput() {
        String input = '  California  ';
        String result = StateToStateCodeHelper.getStateCode(input);
        System.assertEquals('CA', result, 'Should trim input and return correct state code');
    }

    @isTest
    static void testUpperCaseStateName() {
        String input = 'NEW YORK';
        String result = StateToStateCodeHelper.getStateCode(input);
        System.assertEquals('NY', result, 'Should handle uppercase full state name');
    }

    @isTest
    static void testCaseInsensitiveCodeInput() {
        String input = 'nY';
        String result = StateToStateCodeHelper.getStateCode(input);
        System.assertEquals('NY', result, 'Should handle case-insensitive code input');
    }
}