// CHANGE 1: Added `inherited sharing` to class declaration
public inherited sharing class ShopifyConfigService {
    private static final Map<String, Shopify_Configuration__c> CONFIG_BY_CHANNEL;
    static {
        CONFIG_BY_CHANNEL = new Map<String, Shopify_Configuration__c>();
        for (Shopify_Configuration__c cfg : [
            SELECT Name, Shopify_Access_Token__c, Shopify_Endpoint__c
            FROM Shopify_Configuration__c
        ]) {
            CONFIG_BY_CHANNEL.put(cfg.Name, cfg);
        }
    }
    public static Shopify_Configuration__c getConfig(String channel) {
        if (String.isBlank(channel)) {
            throw new AuraHandledException('Sales_Channel__c is missing');
        }
        Shopify_Configuration__c cfg = CONFIG_BY_CHANNEL.get(channel);
        if (cfg == null) {
            throw new AuraHandledException('No Shopify config found for channel: ' + channel);
        }
        return cfg;
    }

    // ── NEW: Country-based config lookup for Shopify store routing ──
    // ── Maps a country code/name to the existing 'Specialty' (US) or  ──
    // ── 'Specialty CAN' (Canada) config records via getConfig() above ──
    // ── No new config records needed, no change to CONFIG_BY_CHANNEL  ──
    public static Shopify_Configuration__c getConfigByCountry(String country) {
        String channelName;
        if (String.isBlank(country)) {
            channelName = 'Specialty';
        } else {
            String normalized = country.trim().toUpperCase();
            if (normalized == 'CA' || normalized == 'CAN' || normalized == 'CANADA') {
                channelName = 'Specialty CAN';
            } else {
                channelName = 'Specialty';
            }
        }
        return getConfig(channelName);
    }
}