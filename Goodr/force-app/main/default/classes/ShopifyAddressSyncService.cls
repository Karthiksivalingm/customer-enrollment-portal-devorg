public inherited sharing class ShopifyAddressSyncService {

    public static void syncAddressToShopify(List<Account> locations) {
        if (locations == null || locations.isEmpty()) return;

        List<Api_Log__c> logs = new List<Api_Log__c>();

        Set<Id> locationIds = new Set<Id>();
        for (Account loc : locations) locationIds.add(loc.Id);

        // ── CHANGED: added ShippingCountryCode ──
        List<Account> storeLocations = [
            SELECT Id, Name, Shopify_Company_Id__c, Sales_Channel__c, ShippingCountryCode,
                   ShippingStreet, ShippingCity, ShippingState,
                   ShippingPostalCode, ShippingCountry,
                   BillingStreet, BillingCity, BillingState,
                   BillingPostalCode, BillingCountry
            FROM Account
            WHERE Id IN :locationIds
        ];

        for (Account loc : storeLocations) {
            if (String.isBlank(loc.Shopify_Company_Id__c)) {
                System.debug('Skipping ' + loc.Id + ' — no Shopify_Company_Id__c');
                continue;
            }

            // ── CHANGED: resolved from loc.ShippingCountryCode instead of Sales_Channel__c ──
            Shopify_Configuration__c cfg =
                ShopifyConfigService.getConfigByCountry(loc.ShippingCountryCode);
            if (cfg == null) {
                System.debug('No config for country: ' + loc.ShippingCountryCode);
                continue;
            }

            // ── Shipping address ──────────────────────────────────────────────
            if (hasAddress(loc.ShippingStreet, loc.ShippingCity,
                           loc.ShippingState,  loc.ShippingCountry)) {
                assignAddress(
                    loc,
                    'SHIPPING',
                    loc.ShippingStreet, loc.ShippingCity,
                    loc.ShippingState,  loc.ShippingPostalCode,
                    loc.ShippingCountry,
                    cfg, logs
                );
            }

            // ── Billing address ───────────────────────────────────────────────
            if (hasAddress(loc.BillingStreet, loc.BillingCity,
                           loc.BillingState,  loc.BillingCountry)) {
                assignAddress(
                    loc,
                    'BILLING',
                    loc.BillingStreet, loc.BillingCity,
                    loc.BillingState,  loc.BillingPostalCode,
                    loc.BillingCountry,
                    cfg, logs
                );
            }
        }

        if (!logs.isEmpty()) insert logs;
    }

    private static Boolean hasAddress(
        String street, String city, String state, String country
    ) {
        return String.isNotBlank(street)
            && String.isNotBlank(city)
            && String.isNotBlank(state)
            && String.isNotBlank(country);
    }

    private static void assignAddress(
        Account loc,
        String  addressType,
        String  street,
        String  city,
        String  stateCode,
        String  postalCode,
        String  countryCode,
        Shopify_Configuration__c cfg,
        List<Api_Log__c> logs
    ) {
        String mutation =
            'mutation companyLocationAssignAddress(' +
            '  $locationId: ID!,' +
            '  $address: CompanyAddressInput!,' +
            '  $addressTypes: [CompanyAddressType!]!) {' +
            '  companyLocationAssignAddress(' +
            '    locationId: $locationId,' +
            '    address: $address,' +
            '    addressTypes: $addressTypes) {' +
            '    addresses { id }' +
            '    userErrors { field message }' +
            '  }' +
            '}';

        Map<String, Object> addressInput = new Map<String, Object>{
            'address1'    => street,
            'city'        => city,
            'zoneCode'    => stateCode,
            'zip'         => postalCode,
            'countryCode' => countryCode
        };

        HttpRequest req = new HttpRequest();
        req.setEndpoint(cfg.Shopify_Endpoint__c);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('X-Shopify-Access-Token', cfg.Shopify_Access_Token__c);
        req.setTimeout(60000);
        req.setBody(JSON.serialize(new Map<String, Object>{
            'query'     => mutation,
            'variables' => new Map<String, Object>{
                'locationId'   =>
                    'gid://shopify/CompanyLocation/' + loc.Shopify_Company_Id__c,
                'address'      => addressInput,
                'addressTypes' => new List<String>{ addressType }
            }
        }));

        HttpResponse res;
        try {
            res = new Http().send(req);
        } catch (Exception e) {
            logs.add(new Api_Log__c(
                Context__c           = 'Shopify Address Sync - HTTP Exception (' + addressType + ')',
                Request_Message__c   = req.getBody(),
                Response_Message__c  = e.getMessage(),
                Related_Record_Id__c = loc.Id,
                Log_Type__c          = 'API Errors'
            ));
            return;
        }

        if (res.getStatusCode() == 200) {
            Map<String, Object> body =
                (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

            if (body.containsKey('errors')) {
                logs.add(new Api_Log__c(
                    Context__c           = 'Shopify Address Sync - GraphQL Error (' + addressType + ')',
                    Request_Message__c   = req.getBody(),
                    Response_Message__c  = res.getBody(),
                    Stack_Trace__c       = JSON.serialize(body.get('errors')),
                    Related_Record_Id__c = loc.Id,
                    Log_Type__c          = 'API Errors'
                ));
                return;
            }

            Map<String, Object> data   = (Map<String, Object>) body.get('data');
            Map<String, Object> result =
                (Map<String, Object>) data.get('companyLocationAssignAddress');

            List<Object> userErrors = (List<Object>) result.get('userErrors');
            if (userErrors != null && !userErrors.isEmpty()) {
                String errorMsg = '';
                for (Object e : userErrors) {
                    Map<String, Object> err = (Map<String, Object>) e;
                    errorMsg += err.get('field') + ': ' + err.get('message') + ' ';
                }
                logs.add(new Api_Log__c(
                    Context__c           = 'Shopify Address Sync - userErrors (' + addressType + ')',
                    Request_Message__c   = req.getBody(),
                    Response_Message__c  = res.getBody(),
                    Stack_Trace__c       = errorMsg.trim(),
                    Related_Record_Id__c = loc.Id,
                    Log_Type__c          = 'API Errors'
                ));
                return;
            }

            System.debug('Address synced to Shopify — '
                + loc.Name + ' | type: ' + addressType);

        } else {
            logs.add(new Api_Log__c(
                Context__c           = 'Shopify Address Sync - HTTP Error (' + addressType + ')',
                Request_Message__c   = req.getBody(),
                Response_Message__c  = res.getBody(),
                Stack_Trace__c       = 'HTTP ' + res.getStatusCode(),
                Related_Record_Id__c = loc.Id,
                Log_Type__c          = 'API Errors'
            ));
        }
    }
}