public class NetSuiteProductSyncBatch implements Database.Batchable<NetSuiteProductWrapper>, Database.AllowsCallouts, Database.Stateful {

    private DateTime runStartTime;
    private Boolean hadFailure = false;
    private Id globalPricebookId;
    private Id usaPricebookId;
    private Id canPricebookId;
    private Id standardPricebookId;

    private List<Api_Log__c> pendingLogs = new List<Api_Log__c>();

    public Iterable<NetSuiteProductWrapper> start(Database.BatchableContext bc) {
        for (Pricebook2 pb : [SELECT Id, Name, IsStandard FROM Pricebook2 WHERE Name IN ('Global', 'USA', 'CAN') OR IsStandard = true]) {
            if (pb.IsStandard) standardPricebookId = pb.Id;
            if (pb.Name == 'Global') globalPricebookId = pb.Id;
            if (pb.Name == 'USA') usaPricebookId = pb.Id;
            if (pb.Name == 'CAN') canPricebookId = pb.Id;
        }

        // NEW: fetch OAuth 2.0 access token once, reused across the whole pagination loop
        String accessToken;
        try {
            accessToken = NetSuiteOAuth2HelperES256.getAccessToken();
        } catch (Exception ex) {
            logError('NetSuite Product Sync - OAuth2 Token Exception', null, null, ex.getMessage(), ex.getStackTraceString(), null);
            flushLogs();
            hadFailure = true;
            return new List<NetSuiteProductWrapper>();
        }

        List<NetSuiteProductWrapper> allProducts = new List<NetSuiteProductWrapper>();
        Integer offset = 0;
        Integer limitSize = 1000;
        Boolean hasMore = true;

        Set<String> seenIds = new Set<String>();

        Sync_Config__c config = Sync_Config__c.getOrgDefaults();
        DateTime lastSyncTime = (config != null && config.Last_Sync_DateTime__c != null)
            ? config.Last_Sync_DateTime__c
            : DateTime.newInstance(2000, 1, 1);

        runStartTime = System.now();
        String formattedDate = formatDateTimeForNetSuite(lastSyncTime);

        while (hasMore) {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:NetSuite_Sandbox/services/rest/query/v1/suiteql?limit=' + limitSize + '&offset=' + offset);
            req.setMethod('POST');
            req.setHeader('Authorization', 'Bearer ' + accessToken); // CHANGED: Bearer token replaces OAuth 1.0 signed header
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Prefer', 'transient');

            String query = 'SELECT item.id, item.itemid, item.displayname, item.description, ' +
                            'item.isinactive, item.upccode, pricing.unitprice, ' +
                            'item.custitem_goodrglobal_item, item.custitem_sellgoodr_item, item.custitemcustitem_sellgoodrcad_item, ' +
                            'item.custitemplm_product_stage, item.custitem5, item.custitem27, ' +
                            'item.custitemplm_merchandise_department, item.custitemplm_merchandise_class, ' +
                            'item.custitemplm_frame_color, item.custitemplm_frame_color_lightness, ' +
                            'item.custitemplm_lens_finish_color, item.custitemplm_lens_color_finish_lightnes, ' +
                            'item.custitem16, item.custitem7, item.custitemplm_launch_year, ' +
                            'item.custitem3, item.custitem_goodr_ip_length, item.custitem_good_ip_width, item.custitem_goodr_ip_height, ' +
                            'item.custitem1, item.custitem_goodr_hts_code_item, item.custitemplm_family ' +
                            'FROM item ' +
                            'LEFT JOIN pricing ON pricing.item = item.id AND pricing.pricelevel = 1 ' +
                            'WHERE item.itemtype IN (\'InvtPart\',\'NonInvtPart\',\'Assembly\',\'Kit\') ' +
                            'AND item.lastmodifieddate > TO_DATE(\'' + formattedDate + '\',\'MM/DD/YYYY HH24:MI\')';
            req.setBody(JSON.serialize(new Map<String, String>{ 'q' => query }));

            Http http = new Http();
            HttpResponse res;

            try {
                res = http.send(req);
            } catch (Exception ex) {
                logError('NetSuite Product Sync - Callout Exception', null, req.getBody(), ex.getMessage(), ex.getStackTraceString(), null);
                hasMore = false;
                hadFailure = true;
                break;
            }

            if (res.getStatusCode() == 200) {
                Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                List<Object> items = (List<Object>) parsed.get('items');

                for (Object o : items) {
                    Map<String, Object> item = (Map<String, Object>) o;
                    String itemId = (String) item.get('id');

                    if (seenIds.contains(itemId)) {
                        continue;
                    }
                    seenIds.add(itemId);

                    NetSuiteProductWrapper w = new NetSuiteProductWrapper();
                    w.id = itemId;
                    w.itemid = (String) item.get('itemid');
                    w.displayname = (String) item.get('displayname');
                    w.description = (String) item.get('description');
                    w.isinactive = (String) item.get('isinactive');
                    w.upc = (String) item.get('upccode');
                    w.unitprice = item.get('unitprice') != null ? String.valueOf(item.get('unitprice')) : null;

                    w.globalSku = (String) item.get('custitem_goodrglobal_item');
                    w.sellgoodrComSku = (String) item.get('custitem_sellgoodr_item');
                    w.sellgoodrCaSku = (String) item.get('custitemcustitem_sellgoodrcad_item');

                    w.productStage = (String) item.get('custitemplm_product_stage');
                    w.collection = (String) item.get('custitem5');
                    w.replen = (String) item.get('custitem27');
                    w.merchandiseDepartment = (String) item.get('custitemplm_merchandise_department');
                    w.merchandiseClass = (String) item.get('custitemplm_merchandise_class');
                    w.frameColor = (String) item.get('custitemplm_frame_color');
                    w.frameColorLightness = (String) item.get('custitemplm_frame_color_lightness');
                    w.lensFinishColor = (String) item.get('custitemplm_lens_finish_color');
                    w.lensColorFinishLightness = (String) item.get('custitemplm_lens_color_finish_lightnes');
                    w.b2bLaunchDate = (String) item.get('custitem16');
                    w.launchDate = (String) item.get('custitem7');
                    w.launchYear = (String) item.get('custitemplm_launch_year');
                    w.ipWeight = (String) item.get('custitem3');
                    w.ipLength = (String) item.get('custitem_goodr_ip_length');
                    w.ipWidth = (String) item.get('custitem_good_ip_width');
                    w.ipHeight = (String) item.get('custitem_goodr_ip_height');
                    w.countryOfOrigin = (String) item.get('custitem1');
                    w.htsCodeItem = (String) item.get('custitem_goodr_hts_code_item');
                    w.productType = (String) item.get('custitemplm_family');

                    allProducts.add(w);
                }

                hasMore = (Boolean) parsed.get('hasMore');
                offset += limitSize;
            } else {
                logError('NetSuite Product Sync - SuiteQL Callout', res.getStatusCode(), req.getBody(), res.getBody(), null, null);
                hasMore = false;
                hadFailure = true;
            }
        }

        flushLogs();
        return allProducts;
    }

    public void execute(Database.BatchableContext bc, List<NetSuiteProductWrapper> scope) {
        Map<String, Product2> productsToUpsert = new Map<String, Product2>();

        for (NetSuiteProductWrapper nsProd : scope) {
            Product2 p = new Product2();
            p.NetSuite_Internal_Id__c = nsProd.id;
            p.Name = String.isNotBlank(nsProd.displayname) ? nsProd.displayname : nsProd.itemid;
            p.ProductCode = nsProd.itemid;
            p.Description = nsProd.description;
            p.IsActive = (nsProd.isinactive == 'F');
            p.NetSuite_Status__c = (nsProd.isinactive == 'F') ? 'Active' : 'Inactive';

            p.put('UPC__c', nsProd.upc);

            p.put('Product_Stage__c', nsProd.productStage);
            p.put('GOODR_Collection__c', nsProd.collection);
            p.put('Merchandise_Department__c', nsProd.merchandiseDepartment);
            p.put('Merchandise_Class__c', nsProd.merchandiseClass);
            p.put('Frame_Color__c', nsProd.frameColor);
            p.put('Frame_Color_Lightness__c', nsProd.frameColorLightness);
            p.put('Lens_Finish_Color__c', nsProd.lensFinishColor);
            p.put('Lens_Color_Finish_Lightness__c', nsProd.lensColorFinishLightness);
            p.put('GOODR_COUNTRY_OF_ORIGIN__c', nsProd.countryOfOrigin);
            p.put('GOODR_HTS_Code_Item__c', nsProd.htsCodeItem);
            p.put('Goodr_Product_Type__c', nsProd.productType);

            p.put('Replen__c', nsProd.replen == 'T');

            if (String.isNotBlank(nsProd.b2bLaunchDate)) {
                try {
                    p.put('B2B_Launch_Date__c', parseNetSuiteDate(nsProd.b2bLaunchDate));
                } catch (Exception ex) {
                    logError('Date Parse Warning', null, null, 'B2B Launch Date parse failed: ' + nsProd.b2bLaunchDate, null, nsProd.id);
                }
            }
            if (String.isNotBlank(nsProd.launchDate)) {
                try {
                    p.put('Launch_Date__c', parseNetSuiteDate(nsProd.launchDate));
                } catch (Exception ex) {
                    logError('Date Parse Warning', null, null, 'Launch Date parse failed: ' + nsProd.launchDate, null, nsProd.id);
                }
            }

            if (String.isNotBlank(nsProd.launchYear)) {
                try {
                    p.put('Launch_Year__c', Integer.valueOf(nsProd.launchYear));
                } catch (Exception ex) {
                    logError('Number Parse Warning', null, null, 'Launch Year parse failed: ' + nsProd.launchYear, null, nsProd.id);
                }
            }

            if (String.isNotBlank(nsProd.ipWeight)) {
                try {
                    p.put('GOODR_IP_Weight__c', Decimal.valueOf(nsProd.ipWeight));
                } catch (Exception ex) {
                    logError('Number Parse Warning', null, null, 'IP Weight parse failed: ' + nsProd.ipWeight, null, nsProd.id);
                }
            }
            if (String.isNotBlank(nsProd.ipLength)) {
                try {
                    p.put('Goodr_IP_Length__c', Decimal.valueOf(nsProd.ipLength));
                } catch (Exception ex) {
                    logError('Number Parse Warning', null, null, 'IP Length parse failed: ' + nsProd.ipLength, null, nsProd.id);
                }
            }
            if (String.isNotBlank(nsProd.ipWidth)) {
                try {
                    p.put('Goodr_IP_Width__c', Decimal.valueOf(nsProd.ipWidth));
                } catch (Exception ex) {
                    logError('Number Parse Warning', null, null, 'IP Width parse failed: ' + nsProd.ipWidth, null, nsProd.id);
                }
            }
            if (String.isNotBlank(nsProd.ipHeight)) {
                try {
                    p.put('Goodr_IP_Height__c', Decimal.valueOf(nsProd.ipHeight));
                } catch (Exception ex) {
                    logError('Number Parse Warning', null, null, 'IP Height parse failed: ' + nsProd.ipHeight, null, nsProd.id);
                }
            }

            productsToUpsert.put(nsProd.id, p);
        }

        if (productsToUpsert.isEmpty()) {
            flushLogs();
            return;
        }

        Map<String, Id> netSuiteIdToProductId = new Map<String, Id>();

        try {
            List<Product2> productList = productsToUpsert.values();
            Database.UpsertResult[] results = Database.upsert(
                productList, Product2.Fields.NetSuite_Internal_Id__c, false
            );

            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) {
                    netSuiteIdToProductId.put(productList[i].NetSuite_Internal_Id__c, results[i].getId());
                } else {
                    String errMsgs = '';
                    for (Database.Error e : results[i].getErrors()) {
                        errMsgs += e.getMessage() + '; ';
                    }
                    logError('Product Upsert', 400, JSON.serialize(productList[i]), errMsgs, null, productList[i].NetSuite_Internal_Id__c);
                }
            }
        } catch (Exception ex) {
            logError('Product Upsert Exception', null, null, ex.getMessage(), ex.getStackTraceString(), null);
            hadFailure = true;
            flushLogs();
            return;
        }

        Map<String, PricebookEntry> entriesToUpsert = new Map<String, PricebookEntry>();

        for (NetSuiteProductWrapper nsProd : scope) {
            Id productId = netSuiteIdToProductId.get(nsProd.id);
            if (productId == null || nsProd.unitprice == null) {
                continue;
            }

            Decimal price;
            try {
                price = Decimal.valueOf(nsProd.unitprice);
            } catch (Exception ex) {
                logError('Price Parse Error', null, null, 'Could not parse price: ' + nsProd.unitprice, null, nsProd.id);
                continue;
            }

            List<Id> matchingPricebooks = new List<Id>();
            if (standardPricebookId != null) matchingPricebooks.add(standardPricebookId);
            if (nsProd.globalSku == 'T' && globalPricebookId != null) matchingPricebooks.add(globalPricebookId);
            if (nsProd.sellgoodrComSku == 'T' && usaPricebookId != null) matchingPricebooks.add(usaPricebookId);
            if (nsProd.sellgoodrCaSku == 'T' && canPricebookId != null) matchingPricebooks.add(canPricebookId);

            for (Id pbId : matchingPricebooks) {
                String compositeKey = nsProd.id + '-' + pbId;
                PricebookEntry pbe = new PricebookEntry();
                pbe.NetSuite_Pricebook_Entry_Key__c = compositeKey;
                pbe.Product2Id = productId;
                pbe.Pricebook2Id = pbId;
                pbe.UnitPrice = price;
                pbe.IsActive = true;
                entriesToUpsert.put(compositeKey, pbe);
            }
        }

        if (!entriesToUpsert.isEmpty()) {
            try {
                List<PricebookEntry> entryList = entriesToUpsert.values();
                Database.UpsertResult[] pbeResults = Database.upsert(
                    entryList, PricebookEntry.Fields.NetSuite_Pricebook_Entry_Key__c, false
                );

                for (Integer i = 0; i < pbeResults.size(); i++) {
                    if (!pbeResults[i].isSuccess()) {
                        String errMsgs = '';
                        for (Database.Error e : pbeResults[i].getErrors()) {
                            errMsgs += e.getMessage() + '; ';
                        }
                        logError('PricebookEntry Upsert', 400, JSON.serialize(entryList[i]), errMsgs, null, entryList[i].NetSuite_Pricebook_Entry_Key__c);
                    }
                }
            } catch (Exception ex) {
                logError('PricebookEntry Upsert Exception', null, null, ex.getMessage(), ex.getStackTraceString(), null);
            }
        }

        flushLogs();
    }

    public void finish(Database.BatchableContext bc) {
        if (hadFailure) {
            System.debug('Sync had a failure — Last_Sync_DateTime__c NOT advanced.');
            return;
        }

        Sync_Config__c config = Sync_Config__c.getOrgDefaults();
        if (config.Id == null) {
            config = new Sync_Config__c();
        }
        Date runDate = runStartTime.date();
        config.Last_Sync_DateTime__c = DateTime.newInstance(runDate.addDays(-1), Time.newInstance(0, 0, 0, 0));
        upsert config;
        System.debug('NetSuite product sync completed. Last sync time updated to: ' + config.Last_Sync_DateTime__c);
    }

    private String formatDateTimeForNetSuite(DateTime dt) {
        TimeZone nsTimeZone = TimeZone.getTimeZone('America/Los_Angeles');
        Integer offsetMillis = nsTimeZone.getOffset(dt);
        DateTime adjusted = dt.addSeconds(offsetMillis / 1000);
        return adjusted.formatGmt('MM/dd/yyyy HH:mm');
    }

    private static Date parseNetSuiteDate(String rawDate) {
        List<String> parts = rawDate.split('/');
        if (parts.size() != 3) {
            throw new StringException('Unexpected date format: ' + rawDate);
        }
        Integer month = Integer.valueOf(parts[0]);
        Integer day = Integer.valueOf(parts[1]);
        Integer year = Integer.valueOf(parts[2]);
        return Date.newInstance(year, month, day);
    }

    private void logError(String context, Integer statusCode, String requestBody, String responseBody, String stackTrace, String relatedId) {
        Api_Log__c log = new Api_Log__c();
        log.Context__c = context;
        log.Status_Code__c = statusCode;
        log.Request_Message__c = requestBody;
        log.Response_Message__c = responseBody;
        log.Stack_Trace__c = stackTrace;
        log.Related_Record_Id__c = relatedId;
        pendingLogs.add(log);
    }

    private void flushLogs() {
        if (!pendingLogs.isEmpty()) {
            insert pendingLogs;
            pendingLogs.clear();
        }
    }
}