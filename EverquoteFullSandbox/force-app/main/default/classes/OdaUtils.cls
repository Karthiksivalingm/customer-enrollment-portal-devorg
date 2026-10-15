public class OdaUtils {
  public static String formatBirthDate(Date birthDate) {
    return datetime.newInstance(birthDate.year(), birthDate.month(), birthDate.day())
      .format('MM/dd/yyyy');
  }

  public static String getCurrentAgentId() {
    return [SELECT LumicoID__c FROM User WHERE Id = :UserInfo.getUserId()][0].LumicoID__c;
  }

  public static String getCurrentOdieAgentId() {
    Decimal odieAgentId = [SELECT Odie_Agent_ID__c FROM User WHERE Id = :UserInfo.getUserId()][0]
    .Odie_Agent_ID__c;

    return String.valueOf(odieAgentId);
  }

  public static String getLink(String objectToFetch) {
    List<NamedCredential> namedCredentials = [
      SELECT DeveloperName, Endpoint
      FROM NamedCredential
      WHERE DeveloperName = :objectToFetch
    ];
    if (namedCredentials.size() == 0){
        throw new ODAException('NameCredentials not found for key: ' + objectToFetch);
    }
    String value = namedCredentials[0].Endpoint;

    return value;
  }


}