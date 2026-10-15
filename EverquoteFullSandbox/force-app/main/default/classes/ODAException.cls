public with sharing class ODAException extends Exception {
  public String initialMessage;

  public ODAException(String message, String initialMessage) {
    this(message);
    this.initialMessage = initialMessage;
  }
}