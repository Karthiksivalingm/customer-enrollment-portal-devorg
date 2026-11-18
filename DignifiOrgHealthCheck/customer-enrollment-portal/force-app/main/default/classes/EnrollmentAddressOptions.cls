/**
 * Country and state/province options from the org's State and Country Picklists
 * (Lead.CountryCode / Lead.StateCode), including which states belong to which
 * country. Used by the enrollment form, the conversion screen and server validation.
 */
public with sharing class EnrollmentAddressOptions {
  private static final String HEX_DIGITS = '0123456789abcdef';
  private static List<Option> cachedCountries;
  private static Map<String, Option> cachedByCode;

  public class Option {
    @AuraEnabled
    public String value;
    @AuraEnabled
    public String label;
    @AuraEnabled
    public List<Option> states;

    public Option(String value, String label) {
      this.value = value;
      this.label = label;
    }
  }

  public static List<Option> getCountries() {
    load();
    return cachedCountries;
  }

  public static Boolean isValidCountry(String countryCode) {
    load();
    return countryCode != null &&
      cachedByCode.containsKey(countryCode.toUpperCase());
  }

  public static Boolean isValidState(String countryCode, String stateCode) {
    load();
    if (countryCode == null || stateCode == null) {
      return false;
    }
    Option country = cachedByCode.get(countryCode.toUpperCase());
    if (country == null) {
      return false;
    }
    for (Option state : country.states) {
      if (state.value.equalsIgnoreCase(stateCode)) {
        return true;
      }
    }
    return false;
  }

  private static void load() {
    if (cachedCountries != null) {
      return;
    }
    cachedCountries = new List<Option>();
    cachedByCode = new Map<String, Option>();
    Map<Integer, Option> countryByIndex = new Map<Integer, Option>();

    List<Schema.PicklistEntry> countryEntries = Lead.CountryCode.getDescribe()
      .getPicklistValues();
    for (Integer i = 0; i < countryEntries.size(); i++) {
      Schema.PicklistEntry entry = countryEntries[i];
      if (!entry.isActive()) {
        continue;
      }
      Option country = new Option(entry.getValue(), entry.getLabel());
      country.states = new List<Option>();
      cachedCountries.add(country);
      cachedByCode.put(entry.getValue().toUpperCase(), country);
      countryByIndex.put(i, country);
    }

    // Each state entry's "validFor" is a base64 bitmap of the controlling
    // country indexes it belongs to (most significant bit first).
    for (
      Schema.PicklistEntry entry : Lead.StateCode.getDescribe()
        .getPicklistValues()
    ) {
      if (!entry.isActive()) {
        continue;
      }
      Map<String, Object> raw = (Map<String, Object>) JSON.deserializeUntyped(
        JSON.serialize(entry)
      );
      String validFor = (String) raw.get('validFor');
      if (String.isBlank(validFor)) {
        continue;
      }
      String hex = EncodingUtil.convertToHex(
        EncodingUtil.base64Decode(validFor)
      );
      for (Integer n = 0; n < hex.length(); n++) {
        Integer nibble = HEX_DIGITS.indexOf(hex.substring(n, n + 1));
        if (nibble <= 0) {
          continue;
        }
        for (Integer bit = 0; bit < 4; bit++) {
          if ((nibble & (8 >> bit)) != 0) {
            Option country = countryByIndex.get(n * 4 + bit);
            if (country != null) {
              country.states.add(
                new Option(entry.getValue(), entry.getLabel())
              );
            }
          }
        }
      }
    }
  }
}
