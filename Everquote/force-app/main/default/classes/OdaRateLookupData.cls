public class OdaRateLookupData {
  @AuraEnabled
  public Lead lead { get; set; }

  @AuraEnabled
  public String carrier { get; set; }

  @AuraEnabled
  public String product { get; set; }

  @AuraEnabled
  public String riskClass { get; set; }

  @AuraEnabled
  public List<Integer> amounts { get; set; }
}