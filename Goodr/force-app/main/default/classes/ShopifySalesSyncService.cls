public with sharing class ShopifySalesSyncService {

    public static void syncStoreLocationSales(List<Account> accountsToSync, List<Api_Log__c> logs) {
        if (accountsToSync == null || accountsToSync.isEmpty()) {
            return;
        }

        Map<Id, Decimal> accToTotalSales  = new Map<Id, Decimal>();
        Map<Id, Integer> accToTotalOrders = new Map<Id, Integer>();
        Map<Id, Boolean> accToActive      = new Map<Id, Boolean>();

        // Shipping address maps
        Map<Id, String>  accToShippingStreet     = new Map<Id, String>();
        Map<Id, String>  accToShippingCity        = new Map<Id, String>();
        Map<Id, String>  accToShippingState       = new Map<Id, String>();
        Map<Id, String>  accToShippingPostalCode  = new Map<Id, String>();
        Map<Id, String>  accToShippingCountry     = new Map<Id, String>();

        // Billing address maps
        Map<Id, String>  accToBillingStreet      = new Map<Id, String>();
        Map<Id, String>  accToBillingCity         = new Map<Id, String>();
        Map<Id, String>  accToBillingState        = new Map<Id, String>();
        Map<Id, String>  accToBillingPostalCode   = new Map<Id, String>();
        Map<Id, String>  accToBillingCountry      = new Map<Id, String>();

        for (Account acc : accountsToSync) {
            // ── CHANGED: resolved from acc.ShippingCountryCode instead of Sales_Channel__c ──
            // ── NOTE: caller's SOQL must include ShippingCountryCode in its SELECT list, ──
            // ── otherwise this will always resolve to the default (US) config           ──
            Shopify_Configuration__c cfg;
            try {
                cfg = ShopifyConfigService.getConfigByCountry(acc.ShippingCountryCode);
            } catch (AuraHandledException e) {
                logs.add(new Api_Log__c(
                    Context__c           = 'Shopify Sync - Config Missing',
                    Response_Message__c  = 'No config found for country: ' + acc.ShippingCountryCode
                                            + ' | Account: ' + acc.Name,
                    Related_Record_Id__c = acc.Id,
                    Log_Type__c          = 'API Errors'
                ));
                continue;
            }

            if (cfg == null) {
                System.debug('No Shopify config found for country: ' + acc.ShippingCountryCode);
                logs.add(new Api_Log__c(
                    Context__c           = 'Shopify Sync - Config Missing',
                    Response_Message__c  = 'No config found for country: ' + acc.ShippingCountryCode
                                            + ' | Account: ' + acc.Name,
                    Related_Record_Id__c = acc.Id,
                    Log_Type__c          = 'API Errors'
                ));
                continue;
            }

            HttpRequest req = new HttpRequest();
            req.setEndpoint(cfg.Shopify_Endpoint__c);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('X-Shopify-Access-Token', cfg.Shopify_Access_Token__c);
            req.setTimeout(60000);

            // Added billingAddress to existing query — zero extra API calls
            String query = 'query companyLocation($id: ID!) {' +
                           '  companyLocation(id: $id) {' +
                           '    id' +
                           '    name' +
                           '    ordersCount { count }' +
                           '    totalSpent { amount currencyCode }' +
                           '    roleAssignments(first: 10) {' +
                           '      edges {' +
                           '        node {' +
                           '          id' +
                           '          role { id name }' +
                           '        }' +
                           '      }' +
                           '    }' +
                           '    shippingAddress {' +
                           '      address1' +
                           '      city' +
                           '      province' +
                           '      zip' +
                           '      countryCode' +
                           '    }' +
                           '    billingAddress {' +
                           '      address1' +
                           '      city' +
                           '      province' +
                           '      zip' +
                           '      countryCode' +
                           '    }' +
                           '  }' +
                           '}';

            Map<String, Object> variables = new Map<String, Object>{
                'id' => 'gid://shopify/CompanyLocation/' + acc.Shopify_Company_Id__c
            };

            req.setBody(JSON.serialize(new Map<String, Object>{
                'query'     => query,
                'variables' => variables
            }));

            HttpResponse res;
            try {
                res = new Http().send(req);
            } catch (Exception e) {
                logs.add(new Api_Log__c(
                    Context__c          = 'Shopify Sync - HTTP Exception',
                    Request_Message__c  = req.getBody(),
                    Response_Message__c = e.getMessage(),
                    Related_Record_Id__c = acc.Id,
                    Log_Type__c         = 'API Errors'
                ));
                continue;
            }

            if (res.getStatusCode() == 200) {
                Map<String, Object> response =
                    (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

                if (response.containsKey('errors')) {
                    logs.add(new Api_Log__c(
                        Context__c          = 'Shopify Sync - GraphQL Error',
                        Request_Message__c  = req.getBody(),
                        Response_Message__c = res.getBody(),
                        Stack_Trace__c      = JSON.serialize(response.get('errors')),
                        Related_Record_Id__c = acc.Id,
                        Log_Type__c         = 'API Errors'
                    ));
                    continue;
                }

                Map<String, Object> companyLocation =
                    (Map<String, Object>) ((Map<String, Object>) response.get('data'))
                    .get('companyLocation');

                if (companyLocation != null) {

                    // ── Sales ─────────────────────────────────────────────────
                    Decimal sales = 0;
                    if (companyLocation.get('totalSpent') != null) {
                        Map<String, Object> totalSpent =
                            (Map<String, Object>) companyLocation.get('totalSpent');
                        if (totalSpent.get('amount') != null) {
                            sales = Decimal.valueOf(
                                String.valueOf(totalSpent.get('amount')));
                        }
                    }

                    // ── Orders ────────────────────────────────────────────────
                    Integer orders = 0;
                    if (companyLocation.get('ordersCount') != null) {
                        Map<String, Object> ordersCount =
                            (Map<String, Object>) companyLocation.get('ordersCount');
                        if (ordersCount.get('count') != null) {
                            orders = Integer.valueOf(
                                String.valueOf(ordersCount.get('count')));
                        }
                    }

                    // ── Active ────────────────────────────────────────────────
                    Boolean isActive = false;
                    if (companyLocation.get('roleAssignments') != null) {
                        Map<String, Object> roleAssignments =
                            (Map<String, Object>) companyLocation.get('roleAssignments');
                        List<Object> edges =
                            (List<Object>) roleAssignments.get('edges');
                        isActive = (edges != null && !edges.isEmpty());
                    }

                    accToTotalSales.put(acc.Id, sales);
                    accToTotalOrders.put(acc.Id, orders);
                    accToActive.put(acc.Id, isActive);

                    // ── Shipping Address ──────────────────────────────────────
                    if (companyLocation.get('shippingAddress') != null) {
                        Map<String, Object> addr =
                            (Map<String, Object>) companyLocation.get('shippingAddress');

                        String street = addr.get('address1') != null
                            ? String.valueOf(addr.get('address1')) : null;
                        String city = addr.get('city') != null
                            ? String.valueOf(addr.get('city')) : null;
                        String postalCode = addr.get('zip') != null
                            ? String.valueOf(addr.get('zip')) : null;

                        String rawProvince = addr.get('province') != null
                            ? String.valueOf(addr.get('province')) : null;
                        String normalizedProvince = rawProvince;
                        if (String.isNotBlank(rawProvince) && rawProvince.contains('-')) {
                            normalizedProvince = rawProvince.substringAfterLast('-').trim();
                        }
                        String stateCode = StateToStateCodeHelper.getStateCode(normalizedProvince);

                        String rawCountry = addr.get('countryCode') != null
                            ? String.valueOf(addr.get('countryCode')) : null;
                        String countryCode =
                            CountryToCountryCodeHelper.getCountryCode(rawCountry);

                        System.debug('Shipping for ' + acc.Name +
                            ' | province: ' + rawProvince +
                            ' → stateCode: ' + stateCode +
                            ' | country: ' + rawCountry +
                            ' → countryCode: ' + countryCode);

                        if (String.isNotBlank(stateCode) &&
                            String.isNotBlank(countryCode)) {
                            accToShippingStreet.put(acc.Id, street);
                            accToShippingCity.put(acc.Id, city);
                            accToShippingState.put(acc.Id, stateCode);
                            accToShippingPostalCode.put(acc.Id, postalCode);
                            accToShippingCountry.put(acc.Id, countryCode);
                        } else {
                            System.debug('Shipping address skipped for ' + acc.Name +
                                ' — unresolved province: ' + rawProvince +
                                ' or country: ' + rawCountry);
                            logs.add(new Api_Log__c(
                                Context__c          = 'Shopify Sync - Shipping Address Skipped',
                                Request_Message__c  = req.getBody(),
                                Response_Message__c = 'province: ' + rawProvince +
                                                      ' | countryCode: ' + rawCountry,
                                Stack_Trace__c      = 'stateCode: ' + stateCode +
                                                      ' | countryCode: ' + countryCode +
                                                      ' — skipped to avoid FIELD_INTEGRITY_EXCEPTION',
                                Related_Record_Id__c = acc.Id,
                                Log_Type__c         = 'API Errors'
                            ));
                        }
                    }

                    // ── Billing Address ───────────────────────────────────────
                    // Only syncs when Shopify has a billingAddress set
                    // When billingAddress is null in Shopify, Salesforce BillingAddress is untouched
                    if (companyLocation.get('billingAddress') != null) {
                        Map<String, Object> billAddr =
                            (Map<String, Object>) companyLocation.get('billingAddress');

                        String billStreet = billAddr.get('address1') != null
                            ? String.valueOf(billAddr.get('address1')) : null;
                        String billCity = billAddr.get('city') != null
                            ? String.valueOf(billAddr.get('city')) : null;
                        String billPostalCode = billAddr.get('zip') != null
                            ? String.valueOf(billAddr.get('zip')) : null;

                        String rawBillProvince = billAddr.get('province') != null
                            ? String.valueOf(billAddr.get('province')) : null;
                        String normalizedBillProvince = rawBillProvince;
                        if (String.isNotBlank(rawBillProvince) && rawBillProvince.contains('-')) {
                            normalizedBillProvince = rawBillProvince.substringAfterLast('-').trim();
                        }
                        String billStateCode =
                            StateToStateCodeHelper.getStateCode(normalizedBillProvince);

                        String rawBillCountry = billAddr.get('countryCode') != null
                            ? String.valueOf(billAddr.get('countryCode')) : null;
                        String billCountryCode =
                            CountryToCountryCodeHelper.getCountryCode(rawBillCountry);

                        System.debug('Billing for ' + acc.Name +
                            ' | province: ' + rawBillProvince +
                            ' → stateCode: ' + billStateCode +
                            ' | country: ' + rawBillCountry +
                            ' → countryCode: ' + billCountryCode);

                        if (String.isNotBlank(billStateCode) &&
                            String.isNotBlank(billCountryCode)) {
                            accToBillingStreet.put(acc.Id, billStreet);
                            accToBillingCity.put(acc.Id, billCity);
                            accToBillingState.put(acc.Id, billStateCode);
                            accToBillingPostalCode.put(acc.Id, billPostalCode);
                            accToBillingCountry.put(acc.Id, billCountryCode);
                        } else {
                            System.debug('Billing address skipped for ' + acc.Name +
                                ' — unresolved province: ' + rawBillProvince +
                                ' or country: ' + rawBillCountry);
                            logs.add(new Api_Log__c(
                                Context__c          = 'Shopify Sync - Billing Address Skipped',
                                Request_Message__c  = req.getBody(),
                                Response_Message__c = 'province: ' + rawBillProvince +
                                                      ' | countryCode: ' + rawBillCountry,
                                Stack_Trace__c      = 'stateCode: ' + billStateCode +
                                                      ' | countryCode: ' + billCountryCode +
                                                      ' — skipped to avoid FIELD_INTEGRITY_EXCEPTION',
                                Related_Record_Id__c = acc.Id,
                                Log_Type__c         = 'API Errors'
                            ));
                        }
                    } else {
                        // billingAddress is null in Shopify
                        // Do NOT clear Salesforce BillingAddress — leave existing value
                        System.debug('Billing address null in Shopify for ' + acc.Name +
                            ' — Salesforce BillingAddress unchanged');
                    }

                    System.debug('Synced ' + acc.Name +
                        ' Sales=$' + sales +
                        ' Orders=' + orders +
                        ' Active=' + isActive);

                } else {
                    logs.add(new Api_Log__c(
                        Context__c          = 'Shopify Sync - Location Not Found',
                        Request_Message__c  = req.getBody(),
                        Response_Message__c = res.getBody(),
                        Stack_Trace__c      = 'No companyLocation in response',
                        Related_Record_Id__c = acc.Id,
                        Log_Type__c         = 'API Errors'
                    ));
                }

            } else {
                logs.add(new Api_Log__c(
                    Context__c          = 'Shopify Sync - HTTP Error',
                    Request_Message__c  = req.getBody(),
                    Response_Message__c = res.getBody(),
                    Stack_Trace__c      = 'HTTP ' + res.getStatusCode(),
                    Related_Record_Id__c = acc.Id,
                    Log_Type__c         = 'API Errors'
                ));
            }
        }

        if (!accToTotalSales.isEmpty()) {
            List<Account> updates = new List<Account>();

            for (Id accId : accToTotalSales.keySet()) {
                Account accUpdate = new Account(
                    Id              = accId,
                    Total_Sales__c  = accToTotalSales.get(accId),
                    Total_Orders__c = accToTotalOrders.get(accId),
                    Active__c       = accToActive.get(accId)
                );

                // Write shipping address only when resolved successfully
                if (accToShippingStreet.containsKey(accId)) {
                    accUpdate.ShippingStreet     = accToShippingStreet.get(accId);
                    accUpdate.ShippingCity       = accToShippingCity.get(accId);
                    accUpdate.ShippingState      = accToShippingState.get(accId);
                    accUpdate.ShippingPostalCode = accToShippingPostalCode.get(accId);
                    accUpdate.ShippingCountry    = accToShippingCountry.get(accId);
                }

                // Write billing address only when Shopify has one AND it resolved
                // If billingAddress was null in Shopify — not in map — existing SF value kept
                if (accToBillingStreet.containsKey(accId)) {
                    accUpdate.BillingStreet     = accToBillingStreet.get(accId);
                    accUpdate.BillingCity       = accToBillingCity.get(accId);
                    accUpdate.BillingState      = accToBillingState.get(accId);
                    accUpdate.BillingPostalCode = accToBillingPostalCode.get(accId);
                    accUpdate.BillingCountry    = accToBillingCountry.get(accId);
                }

                updates.add(accUpdate);
            }

            // ── ADDED: bypassAddressSync prevents the inbound batch DML from   ──
            // ── firing ShopifyAddressSyncQueueable back out to Shopify,         ──
            // ── which would cause an infinite SF → Shopify → SF loop           ──
            AccountTriggerHelper.bypassActiveStatusSync = true;
            AccountTriggerHelper.bypassAddressSync      = true;
            Database.SaveResult[] results = Database.update(updates, false);
            AccountTriggerHelper.bypassActiveStatusSync = false;
            AccountTriggerHelper.bypassAddressSync      = false;

            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    for (Database.Error err : results[i].getErrors()) {
                        System.debug('DML failed for ' + updates[i].Id +
                            ': ' + err.getMessage());
                        logs.add(new Api_Log__c(
                            Context__c          = 'Shopify Sync - DML Error',
                            Response_Message__c = err.getMessage(),
                            Stack_Trace__c      = 'Fields: ' +
                                String.valueOf(err.getFields()),
                            Related_Record_Id__c = updates[i].Id,
                            Log_Type__c         = 'API Errors'
                        ));
                    }
                }
            }
        }
    }
}