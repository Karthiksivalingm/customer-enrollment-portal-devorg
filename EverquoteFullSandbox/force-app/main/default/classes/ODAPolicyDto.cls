public class ODAPolicyDto {
  @AuraEnabled
  public String id { get; set; }

  @AuraEnabled
  public String policyNumber { get; set; }

  @AuraEnabled
  public String carrier { get; set; }

  @AuraEnabled
  public String product { get; set; }

  @AuraEnabled
  public Integer coverageAmount { get; set; }

  @AuraEnabled
  public String quoteId { get; set; }

  @AuraEnabled
  public Boolean recordingWasPaused { get; set; }

  @AuraEnabled
  public Boolean cannotGetPolicyNumber { get; set; }

  @AuraEnabled
  public String riskClass { get; set; }
}