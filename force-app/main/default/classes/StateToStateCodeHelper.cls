public class StateToStateCodeHelper {

    private static final Set<String> VALID_CODES = new Set<String>{
        // ── US States ─────────────────────────────────────────────────────────
        'AL','AK','AZ','AR','CA','CO','CT','DE','FL','GA',
        'HI','ID','IL','IN','IA','KS','KY','LA','ME','MD',
        'MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ',
        'NM','NY','NC','ND','OH','OK','OR','PA','RI','SC',
        'SD','TN','TX','UT','VT','VA','WA','WV','WI','WY',
        // ── US Territories ────────────────────────────────────────────────────
        'PR', // Puerto Rico
        'VI', // Virgin Islands
        'GU', // Guam
        'AS', // American Samoa
        'MP', // Northern Mariana Islands
        'DC', // District of Columbia
        // ── US Military ───────────────────────────────────────────────────────
        'AP', // Armed Forces Pacific
        'AE', // Armed Forces Europe / Middle East
        'AA', // Armed Forces Americas
        // ── Canadian Provinces ────────────────────────────────────────────────
        'AB','BC','MB','NB','NL','NS','NT','NU','ON','PE','QC','SK','YT'
    };

    private static final Map<String, String> STATE_CODES = new Map<String, String>{
        // ── US State full names ───────────────────────────────────────────────
        'alabama'              => 'AL',
        'alaska'               => 'AK',
        'arizona'              => 'AZ',
        'arkansas'             => 'AR',
        'california'           => 'CA',
        'colorado'             => 'CO',
        'connecticut'          => 'CT',
        'delaware'             => 'DE',
        'florida'              => 'FL',
        'georgia'              => 'GA',
        'hawaii'               => 'HI',
        'idaho'                => 'ID',
        'illinois'             => 'IL',
        'indiana'              => 'IN',
        'iowa'                 => 'IA',
        'kansas'               => 'KS',
        'kentucky'             => 'KY',
        'louisiana'            => 'LA',
        'maine'                => 'ME',
        'maryland'             => 'MD',
        'massachusetts'        => 'MA',
        'michigan'             => 'MI',
        'minnesota'            => 'MN',
        'mississippi'          => 'MS',
        'missouri'             => 'MO',
        'montana'              => 'MT',
        'nebraska'             => 'NE',
        'nevada'               => 'NV',
        'new hampshire'        => 'NH',
        'new jersey'           => 'NJ',
        'new mexico'           => 'NM',
        'new york'             => 'NY',
        'north carolina'       => 'NC',
        'north dakota'         => 'ND',
        'ohio'                 => 'OH',
        'oklahoma'             => 'OK',
        'oregon'               => 'OR',
        'pennsylvania'         => 'PA',
        'rhode island'         => 'RI',
        'south carolina'       => 'SC',
        'south dakota'         => 'SD',
        'tennessee'            => 'TN',
        'texas'                => 'TX',
        'utah'                 => 'UT',
        'vermont'              => 'VT',
        'virginia'             => 'VA',
        'washington'           => 'WA',
        'west virginia'        => 'WV',
        'wisconsin'            => 'WI',
        'wyoming'              => 'WY',
        // ── US Territories full names ─────────────────────────────────────────
        'puerto rico'                 => 'PR',
        'virgin islands'              => 'VI',
        'u.s. virgin islands'         => 'VI',
        'us virgin islands'           => 'VI',
        'guam'                        => 'GU',
        'american samoa'              => 'AS',
        'northern mariana islands'    => 'MP',
        'district of columbia'        => 'DC',
        'washington dc'               => 'DC',
        'washington d.c.'             => 'DC',
        // ── US Military full names ────────────────────────────────────────────
        'armed forces pacific'        => 'AP',
        'armed forces europe'         => 'AE',
        'armed forces middle east'    => 'AE',
        'armed forces americas'       => 'AA',
        'armed forces'                => 'AE',
        // ── Canadian province full names ──────────────────────────────────────
        'alberta'                     => 'AB',
        'british columbia'            => 'BC',
        'manitoba'                    => 'MB',
        'new brunswick'               => 'NB',
        'newfoundland and labrador'   => 'NL',
        'newfoundland'                => 'NL',
        'labrador'                    => 'NL',
        'nova scotia'                 => 'NS',
        'northwest territories'       => 'NT',
        'nunavut'                     => 'NU',
        'ontario'                     => 'ON',
        'prince edward island'        => 'PE',
        'quebec'                      => 'QC',
        'québec'                      => 'QC',
        'saskatchewan'                => 'SK',
        'yukon'                       => 'YT',
        'yukon territory'             => 'YT'
    };

    public static String getStateCode(String input) {
        if (String.isBlank(input)) {
            return null;
        }
        String trimmed = input.trim();
        // Strip Shopify prefix format "US-NY" → "NY", "CA-ON" → "ON"
        if (trimmed.contains('-')) {
            trimmed = trimmed.substringAfterLast('-').trim();
        }
        if (VALID_CODES.contains(trimmed.toUpperCase())) {
            return trimmed.toUpperCase();
        }
        String lowerCaseInput = trimmed.toLowerCase();
        if (STATE_CODES.containsKey(lowerCaseInput)) {
            return STATE_CODES.get(lowerCaseInput);
        }
        return null;
    }
}