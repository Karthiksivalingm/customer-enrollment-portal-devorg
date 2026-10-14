public with sharing class ShopifyOrderSyncService {

    // ══════════════════════════════════════════════════════════════
    // MAIN METHOD
    // fullSync    = true  → all historical orders (no date filter)
    // fullSync    = false → orders updated >= syncFromDate
    // syncFromDate = Date.today()           → today only (daily job)
    // syncFromDate = Date.today().addDays(-10) → last 10 days
    // ══════════════════════════════════════════════════════════════
    public static void syncOrders(
        List<Account> accountsToSync,
        List<Api_Log__c> logs,
        Boolean fullSync,
        Date    syncFromDate
    ) {
        if (accountsToSync == null || accountsToSync.isEmpty()) return;

        // ── Get standard pricebook ─────────────────────────────────
        Id pricebookId;
        try {
            pricebookId = [
                SELECT Id FROM Pricebook2
                WHERE IsStandard = true LIMIT 1
            ].Id;
        } catch (Exception e) {
            logs.add(new Api_Log__c(
                Context__c          = 'Order Sync - Pricebook Error',
                Response_Message__c = e.getMessage(),
                Log_Type__c         = 'API Errors'
            ));
            return;
        }

        // ── Build Shopify ID → SF Account ID map ───────────────────
        // Store Location: key = Shopify location ID
        // Company:        key = Shopify company ID
        Map<String, Id> shopifyIdToAccountId = new Map<String, Id>();
        for (Account acc : accountsToSync) {
            if (String.isNotBlank(acc.Shopify_Company_Id__c)) {
                shopifyIdToAccountId.put(
                    acc.Shopify_Company_Id__c, acc.Id
                );
            }
        }

        // ── Date filter string ─────────────────────────────────────
        // fullSync = true  → null (no filter, all orders ever)
        // fullSync = false → syncFromDate at midnight UTC
        String dateFilterStr = null;
        if (!fullSync && syncFromDate != null) {
            dateFilterStr =
                String.valueOf(syncFromDate) + 'T00:00:00Z';
        }

        List<Order> allOrdersToUpsert        = new List<Order>();
        Set<String> processedOrderIds        = new Set<String>();
        Set<Id>     successfullyCalledAccIds = new Set<Id>();

        for (Account acc : accountsToSync) {

            // ════════════════════════════════════════════════════
            // Store Location = has Parent.Shopify_Company_Id__c
            // Company account = no parent company ID
            // ════════════════════════════════════════════════════
            Boolean isStoreLocation =
                acc.Parent != null &&
                String.isNotBlank(acc.Parent.Shopify_Company_Id__c);

            // ── CHANGED: resolved from country instead of Sales_Channel__c ──
            // ── Store Location routes by its own ShippingCountryCode;    ──
            // ── Company account routes by its BillingCountryCode          ──
            // ── NOTE: caller's SOQL must include ShippingCountryCode,    ──
            // ── BillingCountryCode, and Parent.ShippingCountryCode /     ──
            // ── Parent.BillingCountryCode in its SELECT list             ──
            String resolvedCountryCode = isStoreLocation
                ? acc.ShippingCountryCode
                : acc.BillingCountryCode;

            Shopify_Configuration__c cfg = null;
            try {
                cfg = ShopifyConfigService.getConfigByCountry(
                    resolvedCountryCode
                );
            } catch (AuraHandledException e) {
                logs.add(new Api_Log__c(
                    Context__c          = 'Order Sync - Config Missing',
                    Response_Message__c =
                        'No config for country: ' + resolvedCountryCode +
                        ' | ' + acc.Name,
                    Related_Record_Id__c = acc.Id,
                    Log_Type__c          = 'API Errors'
                ));
                continue;
            } catch (Exception e) {
                logs.add(new Api_Log__c(
                    Context__c          = 'Order Sync - Config Error',
                    Response_Message__c =
                        e.getMessage() + ' | ' + acc.Name,
                    Related_Record_Id__c = acc.Id,
                    Log_Type__c          = 'API Errors'
                ));
                continue;
            }

            if (cfg == null) {
                System.debug('No config: ' + acc.Name);
                logs.add(new Api_Log__c(
                    Context__c          = 'Order Sync - Config Missing',
                    Response_Message__c =
                        'No config for country: ' + resolvedCountryCode +
                        ' | ' + acc.Name,
                    Related_Record_Id__c = acc.Id,
                    Log_Type__c          = 'API Errors'
                ));
                continue;
            }

            // ── Validate account has Shopify ID ────────────────────
            if (String.isBlank(acc.Shopify_Company_Id__c)) {
                System.debug('No Shopify ID: ' + acc.Name);
                continue;
            }

            // ════════════════════════════════════════════════════
            // KEY FIX 1: Use purchasing_company_location_id
            //
            // OLD: company_id:4425187506
            //   → Returns ALL 5,002 orders for whole company
            //   → Must scan 100+ pages to find 9 Blue Ridge orders
            //   → CPU limit exceeded after page 23
            //
            // NEW: purchasing_company_location_id:4835770546
            //   → Returns ONLY orders for this specific store
            //   → 9 orders, 1 page, done in seconds
            // ════════════════════════════════════════════════════
            String baseQueryFilter = isStoreLocation
                ? 'purchasing_company_location_id:' +
                  acc.Shopify_Company_Id__c
                : 'company_id:' +
                  acc.Shopify_Company_Id__c;

            // Append date filter for non-full syncs
            String queryFilter = baseQueryFilter;
            if (!fullSync && String.isNotBlank(dateFilterStr)) {
                queryFilter += ' updated_at:>=' + dateFilterStr;
            }

            System.debug(
                'Syncing: ' + acc.Name +
                ' | Filter: ' + queryFilter
            );

            String  cursor       = null;
            Boolean hasMore      = true;
            Integer pageNum      = 0;
            Boolean apiSucceeded = false;

            while (hasMore) {
                pageNum++;

                // ════════════════════════════════════════════════
                // KEY FIX 2: Cursor via GraphQL variable
                //
                // OLD: string concat inside query
                //   ', after: \\"' + cursor + '\\"'
                //   → double escaping → GraphQL syntax error
                //   → pages 2+ never work
                //
                // NEW: cursor passed as GraphQL variable $cursor
                //   → no escaping issue
                //   → all pages work correctly
                // ════════════════════════════════════════════════
                String gqlQuery;
                Map<String, Object> variables =
                    new Map<String, Object>();
                variables.put('queryStr', queryFilter);

                if (String.isNotBlank(cursor)) {
                    // Pages 2+ — include cursor variable
                    gqlQuery =
                        'query GetOrders(' +
                        '  $queryStr: String!, ' +
                        '  $cursor: String!' +
                        ') {' +
                        '  orders(' +
                        '    first: 50, ' +
                        '    after: $cursor, ' +
                        '    query: $queryStr' +
                        '  ) {' +
                        '    pageInfo { hasNextPage endCursor }' +
                        '    edges { node {' +
                        '      id name createdAt updatedAt' +
                        '      displayFinancialStatus' +
                        '      displayFulfillmentStatus' +
                        '      totalPriceSet {' +
                        '        shopMoney { amount currencyCode }' +
                        '      }' +
                        '      subtotalPriceSet {' +
                        '        shopMoney { amount currencyCode }' +
                        '      }' +
                        '      totalTaxSet {' +
                        '        shopMoney { amount currencyCode }' +
                        '      }' +
                        '      totalShippingPriceSet {' +
                        '        shopMoney { amount currencyCode }' +
                        '      }' +
                        '      shippingAddress {' +
                        '        address1 city province zip countryCode' +
                        '      }' +
                        '      billingAddress {' +
                        '        address1 city province zip countryCode' +
                        '      }' +
                        '      customer {' +
                        '        id email firstName lastName' +
                        '      }' +
                        '      purchasingEntity {' +
                        '        ... on PurchasingCompany {' +
                        '          company { id name }' +
                        '          location { id name }' +
                        '        }' +
                        '      }' +
                        '    } }' +
                        '  }' +
                        '}';
                    variables.put('cursor', cursor);
                } else {
                    // Page 1 — no cursor
                    gqlQuery =
                        'query GetOrders(' +
                        '  $queryStr: String!' +
                        ') {' +
                        '  orders(' +
                        '    first: 50, ' +
                        '    query: $queryStr' +
                        '  ) {' +
                        '    pageInfo { hasNextPage endCursor }' +
                        '    edges { node {' +
                        '      id name createdAt updatedAt' +
                        '      displayFinancialStatus' +
                        '      displayFulfillmentStatus' +
                        '      totalPriceSet {' +
                        '        shopMoney { amount currencyCode }' +
                        '      }' +
                        '      subtotalPriceSet {' +
                        '        shopMoney { amount currencyCode }' +
                        '      }' +
                        '      totalTaxSet {' +
                        '        shopMoney { amount currencyCode }' +
                        '      }' +
                        '      totalShippingPriceSet {' +
                        '        shopMoney { amount currencyCode }' +
                        '      }' +
                        '      shippingAddress {' +
                        '        address1 city province zip countryCode' +
                        '      }' +
                        '      billingAddress {' +
                        '        address1 city province zip countryCode' +
                        '      }' +
                        '      customer {' +
                        '        id email firstName lastName' +
                        '      }' +
                        '      purchasingEntity {' +
                        '        ... on PurchasingCompany {' +
                        '          company { id name }' +
                        '          location { id name }' +
                        '        }' +
                        '      }' +
                        '    } }' +
                        '  }' +
                        '}';
                }

                HttpRequest req = new HttpRequest();
                req.setEndpoint(cfg.Shopify_Endpoint__c);
                req.setMethod('POST');
                req.setHeader('Content-Type', 'application/json');
                req.setHeader('X-Shopify-Access-Token',
                    cfg.Shopify_Access_Token__c);
                req.setTimeout(60000);
                req.setBody(JSON.serialize(new Map<String, Object>{
                    'query'     => gqlQuery,
                    'variables' => variables
                }));

                HttpResponse res;
                try {
                    res = new Http().send(req);
                } catch (Exception e) {
                    logs.add(new Api_Log__c(
                        Context__c          =
                            'Order Sync - HTTP Exception',
                        Request_Message__c  = req.getBody(),
                        Response_Message__c = e.getMessage(),
                        Related_Record_Id__c = acc.Id,
                        Log_Type__c         = 'API Errors'
                    ));
                    break;
                }

                if (res.getStatusCode() != 200) {
                    logs.add(new Api_Log__c(
                        Context__c          = 'Order Sync - HTTP Error',
                        Request_Message__c  = req.getBody(),
                        Response_Message__c = res.getBody(),
                        Stack_Trace__c      =
                            'HTTP ' + res.getStatusCode(),
                        Related_Record_Id__c = acc.Id,
                        Log_Type__c         = 'API Errors'
                    ));
                    break;
                }

                apiSucceeded = true;

                Map<String, Object> response =
                    (Map<String, Object>)
                    JSON.deserializeUntyped(res.getBody());

                if (response.containsKey('errors')) {
                    logs.add(new Api_Log__c(
                        Context__c          =
                            'Order Sync - GraphQL Error',
                        Request_Message__c  = req.getBody(),
                        Response_Message__c = res.getBody(),
                        Related_Record_Id__c = acc.Id,
                        Log_Type__c         = 'API Errors'
                    ));
                    break;
                }

                Map<String, Object> data =
                    (Map<String, Object>) response.get('data');
                Map<String, Object> ordersNode =
                    (Map<String, Object>) data.get('orders');
                Map<String, Object> pageInfo =
                    (Map<String, Object>) ordersNode.get('pageInfo');
                List<Object> edges =
                    (List<Object>) ordersNode.get('edges');

                hasMore = (Boolean) pageInfo.get('hasNextPage');
                cursor  = pageInfo.get('endCursor') != null
                    ? String.valueOf(pageInfo.get('endCursor'))
                    : null;

                if (edges == null || edges.isEmpty()) {
                    System.debug('No orders: ' + acc.Name);
                    break;
                }

                System.debug(
                    'Page ' + pageNum + ': ' +
                    edges.size() + ' orders — ' + acc.Name
                );

                for (Object edge : edges) {
                    Map<String, Object> node =
                        (Map<String, Object>)
                        ((Map<String, Object>) edge).get('node');

                    String shopifyOrderId =
                        String.valueOf(node.get('id'));
                    if (processedOrderIds.contains(shopifyOrderId))
                        continue;

                    // ════════════════════════════════════════════
                    // ACCOUNT RESOLUTION
                    //
                    // Level 1: purchasingEntity.location.id
                    //   substringAfterLast('/') = location ID
                    //   → match shopifyIdToAccountId
                    //   → Store Location account ✓
                    //
                    // Level 2: purchasingEntity.company.id
                    //   substringAfterLast('/') = company ID
                    //   → match shopifyIdToAccountId
                    //   → Company account ✓
                    //
                    // No match → SKIP
                    //   Order belongs to different store location
                    //   that will be processed in its own batch run
                    //   Never assign to wrong account
                    //   Never create order without account
                    // ════════════════════════════════════════════
                    Id     resolvedAccountId = null;
                    String orderLocationId   = null;
                    String orderCompanyId    = null;
                    String matchMethod       = null;

                    Map<String, Object> purchasingEntity =
                        (Map<String, Object>)
                        node.get('purchasingEntity');

                    if (purchasingEntity != null) {

                        // Level 1: location.id → Store Location
                        if (purchasingEntity.containsKey('location')
                            && purchasingEntity.get('location') != null)
                        {
                            Map<String, Object> loc =
                                (Map<String, Object>)
                                purchasingEntity.get('location');
                            if (loc.get('id') != null) {
                                orderLocationId =
                                    String.valueOf(loc.get('id'))
                                    .substringAfterLast('/');
                                resolvedAccountId =
                                    shopifyIdToAccountId.get(
                                        orderLocationId
                                    );
                                if (resolvedAccountId != null) {
                                    matchMethod =
                                        'Location: ' + orderLocationId;
                                }
                            }
                        }

                        // Level 2: company.id → Company account
                        if (resolvedAccountId == null &&
                            purchasingEntity.containsKey('company') &&
                            purchasingEntity.get('company') != null)
                        {
                            Map<String, Object> co =
                                (Map<String, Object>)
                                purchasingEntity.get('company');
                            if (co.get('id') != null) {
                                orderCompanyId =
                                    String.valueOf(co.get('id'))
                                    .substringAfterLast('/');
                                resolvedAccountId =
                                    shopifyIdToAccountId.get(
                                        orderCompanyId
                                    );
                                if (resolvedAccountId != null) {
                                    matchMethod =
                                        'Company: ' + orderCompanyId;
                                }
                            }
                        }
                    }

                    // No match → skip this order
                    if (resolvedAccountId == null) {
                        System.debug(
                            'SKIPPED: ' +
                            String.valueOf(node.get('name')) +
                            ' | LocId: ' + orderLocationId +
                            ' | CoId: '  + orderCompanyId
                        );
                        continue;
                    }

                    processedOrderIds.add(shopifyOrderId);

                    String orderName =
                        String.valueOf(node.get('name'))
                        .replace('#', '');
                    String createdAt =
                        String.valueOf(node.get('createdAt'))
                        .substring(0, 10);
                    String paymentStatus =
                        String.valueOf(
                            node.get('displayFinancialStatus')
                        );
                    String fulfillmentStatus =
                        String.valueOf(
                            node.get('displayFulfillmentStatus')
                        );

                    Decimal totalAmount =
                        parseAmount(node, 'totalPriceSet');
                    Decimal subtotal =
                        parseAmount(node, 'subtotalPriceSet');
                    Decimal totalTax =
                        parseAmount(node, 'totalTaxSet');
                    Decimal totalShipping =
                        parseAmount(node, 'totalShippingPriceSet');

                    String customerEmail = null;
                    String customerId    = null;
                    if (node.get('customer') != null) {
                        Map<String, Object> cust =
                            (Map<String, Object>) node.get('customer');
                        customerEmail = cust.get('email') != null
                            ? String.valueOf(cust.get('email')) : null;
                        if (cust.get('id') != null) {
                            customerId =
                                String.valueOf(cust.get('id'))
                                .substringAfterLast('/');
                        }
                    }

                    Order ord = new Order(
                        AccountId                     = resolvedAccountId,
                        Pricebook2Id                  = pricebookId,
                        EffectiveDate                 = Date.valueOf(createdAt),
                        Status                        = 'Draft',
                        Name                          = orderName,
                        Shopify_Order_Id__c           = shopifyOrderId,
                        Shopify_Order_Number__c       = orderName,
                        Shopify_Payment_Status__c     = paymentStatus,
                        Shopify_Fulfillment_Status__c = fulfillmentStatus,
                        Shopify_Order_Amount__c       = totalAmount,
                        Shopify_Subtotal__c           = subtotal,
                        Shopify_Tax__c                = totalTax,
                        Shopify_Shipping__c           = totalShipping,
                        Shopify_Customer_Email__c     = customerEmail,
                        Shopify_Customer_Id__c        = customerId
                    );

                    if (node.get('shippingAddress') != null) {
                        Map<String, Object> ship =
                            (Map<String, Object>)
                            node.get('shippingAddress');
                        ord.ShippingStreet =
                            ship.get('address1') != null
                            ? String.valueOf(ship.get('address1'))
                            : null;
                        ord.ShippingCity =
                            ship.get('city') != null
                            ? String.valueOf(ship.get('city'))
                            : null;
                        ord.ShippingPostalCode =
                            ship.get('zip') != null
                            ? String.valueOf(ship.get('zip'))
                            : null;
                        ord.ShippingCountry =
                            ship.get('countryCode') != null
                            ? String.valueOf(ship.get('countryCode'))
                            : null;
                        String rawProv =
                            ship.get('province') != null
                            ? String.valueOf(ship.get('province'))
                            : null;
                        if (String.isNotBlank(rawProv)) {
                            String norm = rawProv.contains('-')
                                ? rawProv.substringAfterLast('-').trim()
                                : rawProv;
                            String sc =
                                StateToStateCodeHelper.getStateCode(norm);
                            if (String.isNotBlank(sc))
                                ord.ShippingState = sc;
                        }
                    }

                    if (node.get('billingAddress') != null) {
                        Map<String, Object> bill =
                            (Map<String, Object>)
                            node.get('billingAddress');
                        ord.BillingStreet =
                            bill.get('address1') != null
                            ? String.valueOf(bill.get('address1'))
                            : null;
                        ord.BillingCity =
                            bill.get('city') != null
                            ? String.valueOf(bill.get('city'))
                            : null;
                        ord.BillingPostalCode =
                            bill.get('zip') != null
                            ? String.valueOf(bill.get('zip'))
                            : null;
                        ord.BillingCountry =
                            bill.get('countryCode') != null
                            ? String.valueOf(bill.get('countryCode'))
                            : null;
                        String rawBillProv =
                            bill.get('province') != null
                            ? String.valueOf(bill.get('province'))
                            : null;
                        if (String.isNotBlank(rawBillProv)) {
                            String norm = rawBillProv.contains('-')
                                ? rawBillProv.substringAfterLast('-')
                                  .trim()
                                : rawBillProv;
                            String sc =
                                StateToStateCodeHelper.getStateCode(norm);
                            if (String.isNotBlank(sc))
                                ord.BillingState = sc;
                        }
                    }

                    allOrdersToUpsert.add(ord);
                    System.debug(
                        'Queued: '  + orderName +
                        ' | $'      + totalAmount +
                        ' | '       + paymentStatus +
                        ' | via: '  + matchMethod
                    );
                }

                if (!hasMore || String.isBlank(cursor)) break;
            }

            if (apiSucceeded) {
                successfullyCalledAccIds.add(acc.Id);
            }
        }

        // ── Phase 2: Bulk upsert all orders ───────────────────────
        if (!allOrdersToUpsert.isEmpty()) {
            System.debug(
                'Upserting: ' + allOrdersToUpsert.size() + ' orders'
            );
            Database.UpsertResult[] results = Database.upsert(
                allOrdersToUpsert,
                Order.Shopify_Order_Id__c,
                false
            );
            Integer created = 0, updated = 0, failed = 0;
            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) {
                    if (results[i].isCreated()) created++;
                    else updated++;
                } else {
                    failed++;
                    for (Database.Error err : results[i].getErrors()) {
                        logs.add(new Api_Log__c(
                            Context__c =
                                'Order Sync - Upsert Error',
                            Response_Message__c =
                                err.getMessage(),
                            Stack_Trace__c =
                                'Order: ' +
                                allOrdersToUpsert[i]
                                .Shopify_Order_Number__c,
                            Log_Type__c = 'API Errors'
                        ));
                    }
                }
            }
            System.debug(
                'Inserted: ' + created +
                ' | Updated: ' + updated +
                ' | Failed: '  + failed
            );
        } else {
            System.debug('No orders to upsert.');
        }

        // ══════════════════════════════════════════════════════════
        // Phase 3: Stamp the sync watermark AND the true last order
        //          date
        //
        // Last_Shopify_Order_Sync_Date__c
        //   = today, set after every successful API call. This is a
        //     system field about the sync itself, and it is what the
        //     90-day daily sync filter reads.
        //
        // Last_Shopify_Order_Date__c
        //   = the newest Shopify order actually on the account, read
        //     back from Salesforce after the upsert so it reflects
        //     every order on file, not only those returned in this
        //     sync window.
        //
        //     PREVIOUSLY this field was also set to Date.today(),
        //     which made it a second copy of the sync date rather
        //     than a record of customer activity. Any process that
        //     measures inactivity depends on this being correct.
        //
        //     An account with no Shopify orders gets null, which is
        //     the honest value and is what identifies a store that
        //     has never ordered.
        // ══════════════════════════════════════════════════════════
        if (!successfullyCalledAccIds.isEmpty()) {

            Map<Id, Date> lastOrderByAcc = new Map<Id, Date>();
            for (AggregateResult ar : [
                SELECT AccountId accId, MAX(EffectiveDate) maxDate
                FROM Order
                WHERE Shopify_Order_Id__c != null
                AND   AccountId IN :successfullyCalledAccIds
                GROUP BY AccountId
            ]) {
                lastOrderByAcc.put(
                    (Id) ar.get('accId'), (Date) ar.get('maxDate')
                );
            }

            List<Account> accUpdates = new List<Account>();
            for (Id accId : successfullyCalledAccIds) {
                // get() returns null where the account has no orders,
                // which correctly clears the field rather than
                // leaving a stale date in place.
                accUpdates.add(new Account(
                    Id                              = accId,
                    Last_Shopify_Order_Sync_Date__c = Date.today(),
                    Last_Shopify_Order_Date__c      =
                        lastOrderByAcc.get(accId)
                ));
            }

            Database.SaveResult[] accResults =
                Database.update(accUpdates, false);
            Integer accOk = 0, accFail = 0;
            for (Integer i = 0; i < accResults.size(); i++) {
                if (accResults[i].isSuccess()) {
                    accOk++;
                } else {
                    accFail++;
                    logs.add(new Api_Log__c(
                        Context__c =
                            'Order Sync - Account Date Update Error',
                        Response_Message__c =
                            accResults[i].getErrors()[0].getMessage(),
                        Related_Record_Id__c = accUpdates[i].Id,
                        Log_Type__c          = 'API Errors'
                    ));
                }
            }
            System.debug(
                'Dates updated: ' + accOk +
                ' | Failed: '    + accFail
            );
        }
    }

    // ── Overload: fullSync with today as date ──────────────────────
    public static void syncOrders(
        List<Account> accountsToSync,
        List<Api_Log__c> logs,
        Boolean fullSync
    ) {
        syncOrders(accountsToSync, logs, fullSync, Date.today());
    }

    // ── Overload: daily sync (default) ────────────────────────────
    public static void syncOrders(
        List<Account> accountsToSync,
        List<Api_Log__c> logs
    ) {
        syncOrders(accountsToSync, logs, false, Date.today());
    }

    private static Decimal parseAmount(
        Map<String, Object> node, String field
    ) {
        try {
            if (node.get(field) == null) return 0;
            Map<String, Object> ps =
                (Map<String, Object>) node.get(field);
            if (ps.get('shopMoney') == null) return 0;
            Map<String, Object> sm =
                (Map<String, Object>) ps.get('shopMoney');
            if (sm.get('amount') == null) return 0;
            return Decimal.valueOf(
                String.valueOf(sm.get('amount'))
            );
        } catch (Exception e) {
            return 0;
        }
    }
}