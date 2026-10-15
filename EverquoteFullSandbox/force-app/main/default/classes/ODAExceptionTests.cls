@isTest
public with sharing class ODAExceptionTests {
  @isTest
  static void odaExceptionTest() {
    Test.startTest();
    try {
      throw new ODAException('Test', 'Initial Message');
    } catch (ODAException ex) {
      System.assertEquals('Test', ex.getMessage());
      System.assertEquals('Initial Message', ex.initialMessage);
    }
    Test.stopTest();
  }
}