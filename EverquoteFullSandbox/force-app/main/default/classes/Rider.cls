public class Rider {
  @AuraEnabled
  public String product { get; set; }

  @AuraEnabled
  public Integer amount { get; set; }

  @AuraEnabled
  public Integer units { get; set; }
}