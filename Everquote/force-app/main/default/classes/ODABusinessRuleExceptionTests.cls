@isTest
public class ODABusinessRuleExceptionTests {
  @isTest
  static void odaBusinessRuleExceptionTest() {
    Test.startTest();
    try {
      throw new ODABusinessRuleException('Test', 'code');
    } catch (ODABusinessRuleException ex) {
      System.assertEquals('Test', ex.getMessage());
      System.assertEquals('code', ex.code);
    }
    Test.stopTest();
  }
}