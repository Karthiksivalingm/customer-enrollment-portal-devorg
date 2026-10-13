public class OdaQuoteRequestData {
  @AuraEnabled
  public Lead lead { get; set; }

  @AuraEnabled
  public String carrier { get; set; }

  @AuraEnabled
  public String product { get; set; }

  @AuraEnabled
  public Integer faceAmount { get; set; }

  @AuraEnabled
  public String riskClass { get; set; }

  @AuraEnabled
  public String termLength { get; set; }

  @AuraEnabled
  public List<Rider> riders { get; set; }
}