public class CountryToCountryCodeHelper {

    private static final Set<String> VALID_COUNTRY_CODES = new Set<String>{
        'US', 'CA'
    };
    
    private static final Map<String, String> COUNTRY_CODES = new Map<String, String>{
        'united states' => 'US',
        'canada' => 'CA'
    };
        
    public static String getCountryCode(String input) {
         if (String.isBlank(input)) {
                return null;
         }
    
         String trimmed = input.trim();
    
         if (VALID_COUNTRY_CODES.contains(trimmed.toUpperCase())) {
             return trimmed.toUpperCase();
         }

         String lowerCaseInput = trimmed.toLowerCase();
    
         if (COUNTRY_CODES.containsKey(lowerCaseInput)) {
             return COUNTRY_CODES.get(lowerCaseInput);
         }
    
         return null;
    }
}