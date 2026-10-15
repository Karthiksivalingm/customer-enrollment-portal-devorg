public with sharing class ODABusinessRuleException extends Exception {
  public String code;

  public ODABusinessRuleException(String message, String code) {
    this(message);
    this.code = code;
  }
}