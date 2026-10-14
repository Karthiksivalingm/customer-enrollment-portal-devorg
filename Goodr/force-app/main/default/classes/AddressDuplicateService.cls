public class AddressDuplicateService {
    
    private static final Map<String, String> ABBREVIATION_MAP = new Map<String, String>{
        'st' => 'street',
        'str' => 'street',
        'rd' => 'road',
        'ave' => 'avenue',
        'av' => 'avenue',
        'blvd' => 'boulevard',
        'dr' => 'drive',
        'ln' => 'lane',
        'ct' => 'court',
        'cir' => 'circle',
        'pl' => 'place',
        'ter' => 'terrace',
        'pkwy' => 'parkway',
        'apt' => 'apartment',
        'bldg' => 'building',
        'fl' => 'floor',
        'ste' => 'suite'
    };

    public static String normalizeAddress(String address) {
        if (String.isBlank(address)) {
            return '';
        }
        
        String normalized = address.toLowerCase().trim();
        normalized = normalized.replaceAll('[^a-z0-9\\s]', ' ');
        normalized = normalized.replaceAll('\\s+', ' ').trim();
        
        List<String> words = normalized.split(' ');
        List<String> numbers = new List<String>();
        List<String> letters = new List<String>();
        
        for (String word : words) {
            if (word.isNumeric() || word.replaceAll('[^0-9]', '').length() > 0) {
                numbers.add(word);
            } else {
                if (ABBREVIATION_MAP.containsKey(word)) {
                    letters.add(ABBREVIATION_MAP.get(word));
                } else {
                    letters.add(word);
                }
            }
        }
        numbers.sort();
        letters.sort();
        List<String> combined = new List<String>();
        combined.addAll(numbers);
        combined.addAll(letters);

        return String.join(combined, '');
    }

    public static Boolean areAddressesIdentical(String address1, String address2) {
        String norm1 = normalizeAddress(address1);
        String norm2 = normalizeAddress(address2);
        return norm1 == norm2;
    }

    public static Decimal calculateSimilarity(String address1, String address2) {
        if (String.isBlank(address1) && String.isBlank(address2)) {
            return 100;
        }
        if (String.isBlank(address1) || String.isBlank(address2)) {
            return 0;
        }
        
        if (areAddressesIdentical(address1, address2)) {
            return 100;
        }

        String simple1 = normalizeAddress(address1);
        String simple2 = normalizeAddress(address2);
        Integer distance = levenshteinDistance(simple1, simple2);
        Integer maxLength = Math.max(simple1.length(), simple2.length());
        
        if (maxLength == 0) {
            return 100;
        }
        
        Decimal similarity = (1 - (Decimal.valueOf(distance) / maxLength)) * 100;
        return similarity.setScale(2);
    }

    public static Decimal compareFullAddresses(
        String street1, String city1, String zip1,
        String street2, String city2, String zip2
    ) {
        String normZip1 = normalizeZipCode(zip1);
        String normZip2 = normalizeZipCode(zip2);
        
        if (String.isNotBlank(normZip1) && String.isNotBlank(normZip2) && normZip1 != normZip2) {
            return 0;
        }
        
        Boolean streetIdentical = areAddressesIdentical(street1, street2);
        Boolean cityIdentical = areAddressesIdentical(city1, city2);
        
        if (streetIdentical && cityIdentical) {
            return 100;
        }
        
        Decimal streetSimilarity = calculateSimilarity(street1, street2);
        Decimal citySimilarity = calculateSimilarity(city1, city2);
        
        Decimal weightedSimilarity = 
            (streetSimilarity * 0.6) + 
            (citySimilarity * 0.2) + 
            (normZip1 == normZip2 ? 20 : 0);
        
        return weightedSimilarity.setScale(2);
    }

    private static String normalizeZipCode(String zipCode) {
        if (String.isBlank(zipCode)) {
            return '';
        }
        return zipCode.replaceAll('[^0-9]', '');
    }

    private static Integer levenshteinDistance(String s1, String s2) {
        Integer len1 = s1.length();
        Integer len2 = s2.length();
        
        if (len1 == 0) return len2;
        if (len2 == 0) return len1;
        
        List<List<Integer>> matrix = new List<List<Integer>>();
        
        for (Integer i = 0; i <= len1; i++) {
            List<Integer> row = new List<Integer>();
            for (Integer j = 0; j <= len2; j++) {
                row.add(0);
            }
            matrix.add(row);
        }
        
        for (Integer i = 0; i <= len1; i++) {
            matrix[i][0] = i;
        }
        for (Integer j = 0; j <= len2; j++) {
            matrix[0][j] = j;
        }
        
        for (Integer i = 1; i <= len1; i++) {
            for (Integer j = 1; j <= len2; j++) {
                Integer cost = (s1.substring(i-1, i) == s2.substring(j-1, j)) ? 0 : 1;
                
                matrix[i][j] = Math.min(
                    Math.min(
                        matrix[i-1][j] + 1,
                        matrix[i][j-1] + 1
                    ),
                    matrix[i-1][j-1] + cost
                );
            }
        }
        
        return matrix[len1][len2];
    }
}