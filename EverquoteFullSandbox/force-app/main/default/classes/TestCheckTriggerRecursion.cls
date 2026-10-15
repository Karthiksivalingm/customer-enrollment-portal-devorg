@isTest
public class TestCheckTriggerRecursion {
  @testSetup
  static void testSetup() {
    // Reset checkTriggerRecursion
    checkTriggerRecursion.reset();
  }

  @isTest
  static void checkTriggerRecursion_canRun_firstCheck_shouldReturnTrue() {
    // Arrange
    String identifier = 'trigger_identifier';

    // Act
    boolean result = checkTriggerRecursion.canRun(identifier);

    // Assert
    System.assertEquals(true, result);
  }

  @isTest
  static void checkTriggerRecursion_canRun_secondCheck_shouldReturnFalse() {
    // Arrange
    String identifier = 'trigger_identifier';
    // first check
    checkTriggerRecursion.canRun(identifier);

    // Act
    // second check
    boolean result = checkTriggerRecursion.canRun(identifier);
    // Assert
    System.assertEquals(false, result);
  }

  @isTest
  static void checkTriggerRecursion_check_after_shouldReturnTrue() {
    // Arrange
    String identifier = 'trigger_identifier';
    // first check
    boolean firstResult = checkTriggerRecursion.canRun(identifier);
    System.assertEquals(true, firstResult);

    // second check
    boolean secondResult = checkTriggerRecursion.canRun(identifier);
    System.assertEquals(false, secondResult);

    // Act
    checkTriggerRecursion.reset();

    // Assert
    boolean resultAfterReset = checkTriggerRecursion.canRun(identifier);
    System.assertEquals(true, resultAfterReset);
  }
}