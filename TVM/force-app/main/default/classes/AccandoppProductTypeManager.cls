public class AccandoppProductTypeManager {
    
    
    public class UpdateProductTypeRequest {
        @InvocableVariable(label='Account Id' description='The Account ID to update' required=true)
        public Id accountId;
        
        @InvocableVariable(label='Opportunity Id' description='(Optional) The Opportunity ID that triggered the update' required=false)
        public Id opportunityId;
        
        @InvocableVariable(label='Prior Value' description='(Optional) The previous Product_Status__c value' required=false)
        public String priorValue;
        
        @InvocableVariable(label='New Value' description='(Optional) The new Product_Status__c value' required=false)
        public String newValue;
    }
    

    public class UpdateProductTypeResult {
        @InvocableVariable(label='Success' description='Was update successful')
        public Boolean success;
        
        @InvocableVariable(label='Message' description='Status message')
        public String message;
        
        @InvocableVariable(label='Product Type' description='Updated value')
        public String productType;
        
        @InvocableVariable(label='Account Id' description='Account updated')
        public Id accountId;
        
        @InvocableVariable(label='Change Summary' description='Details of the change')
        public String changeSummary;
    }
    
   
    @InvocableMethod(
        label='Update Account Product Type'
        description='Rebuilds Account Product_Type__c from related opportunities - All scenarios'
    )
    public static List<UpdateProductTypeResult> updateAccountProductType(
        List<UpdateProductTypeRequest> requests
    ) {
        System.debug('');
        System.debug('╔════════════════════════════════════════════════════════════╗');
        System.debug('║  AccandoppProductTypeManager v2.2');
        System.debug('║  Enhanced Scenario 5 Logging');
        System.debug('╚════════════════════════════════════════════════════════════╝');
        System.debug('');
        
        List<UpdateProductTypeResult> results = new List<UpdateProductTypeResult>();
        
        if (requests == null || requests.isEmpty()) {
            System.debug('❌ ERROR: No requests provided');
            UpdateProductTypeResult errorResult = new UpdateProductTypeResult();
            errorResult.success = false;
            errorResult.message = 'No requests provided';
            errorResult.accountId = null;
            errorResult.productType = '';
            errorResult.changeSummary = '';
            results.add(errorResult);
            return results;
        }
        
        UpdateProductTypeRequest request = requests[0];
        UpdateProductTypeResult result = new UpdateProductTypeResult();
        
        try {
            // ═══════════════════════════════════════════════════════════
            // STEP 1: CLEAN INPUT PARAMETERS
            // ═══════════════════════════════════════════════════════════
            System.debug('📥 STEP 1: Cleaning Input Parameters');
            
            if (request.accountId == null) {
                System.debug('❌ ERROR: Account ID is null');
                result.success = false;
                result.message = 'Account ID is null';
                result.accountId = null;
                result.productType = '';
                result.changeSummary = '';
                results.add(result);
                return results;
            }
            System.debug('   ✓ Account ID: ' + request.accountId);
            
            Id cleanOpportunityId = null;
            if (request.opportunityId != null) {
                cleanOpportunityId = request.opportunityId;
                System.debug('   ✓ Opportunity ID: ' + cleanOpportunityId);
            } else {
                System.debug('   ✓ Opportunity ID: (not provided)');
            }
            
            String cleanPriorValue = String.isBlank(request.priorValue) ? null : request.priorValue.trim();
            System.debug('   ✓ Prior Value: ' + (cleanPriorValue != null ? '"' + cleanPriorValue + '"' : '(not provided)'));
            
            String cleanNewValue = String.isBlank(request.newValue) ? null : request.newValue.trim();
            System.debug('   ✓ New Value: ' + (cleanNewValue != null ? '"' + cleanNewValue + '"' : '(not provided)'));
            System.debug('');
            
            
            System.debug('STEP 2: Fetching Account Record');
            Account account = [
                SELECT Id, Name, Product_Type__c
                FROM Account
                WHERE Id = :request.accountId
                LIMIT 1
            ];
            
            String accountCurrentValue = account.Product_Type__c;
            System.debug('   ✓ Account ID: ' + account.Id);
            System.debug('   ✓ Account Name: ' + account.Name);
            System.debug('   ✓ Current Product_Type__c: ' + 
                (String.isBlank(accountCurrentValue) ? '(EMPTY/NULL)' : '"' + accountCurrentValue + '"'));
            System.debug('');
            
           
            System.debug('STEP 3: Fetching All Related Opportunities (Including ALL for analysis)');
            List<Opportunity> allOpportunities = [
                SELECT 
                    Id, 
                    Name, 
                    Product_Status__c, 
                    StageName, 
                    CreatedDate,
                    AccountId
                FROM Opportunity
                WHERE AccountId = :request.accountId
                ORDER BY CreatedDate ASC
            ];
            
            System.debug('   Total opportunities on account: ' + allOpportunities.size());
            System.debug('');
            
            // ═══════════════════════════════════════════════════════════
            // STEP 3B: ANALYZE - SHOW WHICH ARE INCLUDED/EXCLUDED
            // ═══════════════════════════════════════════════════════════
            System.debug('STEP 3B: Analyzing Opportunities (Scenario 5 Clarity)');
            System.debug('   Checking which opportunities QUALIFY for inclusion:');
            System.debug('   Criteria: StageName = "Live" OR "Onboarding" AND Product_Status__c has value');
            System.debug('');
            
            for (Integer i = 0; i < allOpportunities.size(); i++) {
                Opportunity opp = allOpportunities[i];
                Boolean isLiveOrOnboarding = (opp.StageName == 'Live' || opp.StageName == 'Onboarding');
                Boolean hasProductValue = !String.isBlank(opp.Product_Status__c);
                Boolean willBeIncluded = isLiveOrOnboarding && hasProductValue;
                
                String marker = '';
                if (cleanOpportunityId != null && opp.Id == cleanOpportunityId) {
                    marker = ' ⭐ [TRIGGER - THIS ONE WAS UPDATED]';
                }
                
                String status = willBeIncluded ? '✓ INCLUDED' : '✗ EXCLUDED';
                String reason = '';
                
                if (!isLiveOrOnboarding) {
                    reason = '(Stage is ' + opp.StageName + ', not Live/Onboarding)';
                } else if (!hasProductValue) {
                    reason = '(No Product_Status__c value)';
                } else {
                    reason = '(Stage: ' + opp.StageName + ', Value: "' + opp.Product_Status__c + '")';
                }
                
                System.debug('   [' + (i + 1) + '] ' + opp.Name + ' → ' + status + ' ' + reason + marker);
            }
            System.debug('');
            
            
            System.debug('STEP 4: Filtering Opportunities (Keep only Live/Onboarding with values)');
            List<Opportunity> qualifyingOpportunities = new List<Opportunity>();
            
            for (Opportunity opp : allOpportunities) {
                if ((opp.StageName == 'Live' || opp.StageName == 'Onboarding') && 
                    !String.isBlank(opp.Product_Status__c)) {
                    qualifyingOpportunities.add(opp);
                }
            }
            
            System.debug('   Qualifying opportunities: ' + qualifyingOpportunities.size() + ' of ' + allOpportunities.size());
            System.debug('');
            
            
            if (qualifyingOpportunities.isEmpty()) {
                System.debug('   ⚠️  WARNING: No opportunities found with Live/Onboarding stage');
                System.debug('   Clearing Account.Product_Type__c field');
                System.debug('');
                
                String oldValue = account.Product_Type__c;
                account.Product_Type__c = '';
                update account;
                
                result.success = true;
                result.message = 'No opportunities found - field cleared';
                result.accountId = request.accountId;
                result.productType = '';
                result.changeSummary = 'Cleared Product_Type__c (was: "' + oldValue + '")';
                results.add(result);
                return results;
            }
            
            // ═══════════════════════════════════════════════════════════
            // STEP 6: BUILD PRODUCT TYPE STRING (Core Logic)
            // ═══════════════════════════════════════════════════════════
            System.debug('STEP 6: Building Product Type String from QUALIFYING opportunities');
            String newProductType = buildProductTypeString(qualifyingOpportunities, cleanOpportunityId);
            System.debug('   ✓ Result: "' + newProductType + '"');
            System.debug('   ✓ Delimiter: semicolon (;)');
            System.debug('');
            
            // ═══════════════════════════════════════════════════════════
            // STEP 7: CREATE CHANGE SUMMARY
            // ═══════════════════════════════════════════════════════════
            System.debug('STEP 7: Creating Change Summary');
            String changeSummary = createChangeSummary(
                cleanOpportunityId,
                cleanPriorValue,
                cleanNewValue,
                accountCurrentValue,
                newProductType
            );
            System.debug('   ✓ Summary: ' + changeSummary);
            System.debug('');
            
            // ═══════════════════════════════════════════════════════════
            // STEP 8: UPDATE ACCOUNT FIELD
            // ═══════════════════════════════════════════════════════════
            System.debug('STEP 8: Updating Account Field');
            String displayBefore = String.isBlank(accountCurrentValue) ? '(EMPTY/NULL)' : '"' + accountCurrentValue + '"';
            System.debug('   Before: ' + displayBefore);
            System.debug('   After:  "' + newProductType + '"');
            
            Boolean fieldChanged = !safeStringEquals(accountCurrentValue, newProductType);
            System.debug('   Status: ' + (fieldChanged ? '✓ FIELD WILL CHANGE' : '(No change needed)'));
            System.debug('');
            
            account.Product_Type__c = newProductType;
            update account;
            
            System.debug('   ✓ Account.Product_Type__c updated successfully');
            System.debug('');
            
            // ═══════════════════════════════════════════════════════════
            // STEP 9: RETURN RESULT
            // ═══════════════════════════════════════════════════════════
            result.success = true;
            result.message = 'Account Product_Type__c updated successfully';
            result.accountId = request.accountId;
            result.productType = newProductType;
            result.changeSummary = changeSummary;
            
            System.debug('✅ FINAL RESULT: SUCCESS');
            System.debug('   Success: ' + result.success);
            System.debug('   Message: ' + result.message);
            System.debug('   Product Type (Output): "' + result.productType + '"');
            System.debug('   Account ID (Output): ' + result.accountId);
            System.debug('   Change Summary (Output): ' + result.changeSummary);
            System.debug('');
            
        } catch (QueryException qe) {
            System.debug('');
            System.debug('❌ ERROR - QueryException: ' + qe.getMessage());
            System.debug('Stack Trace: ' + qe.getStackTraceString());
            result.success = false;
            result.message = 'Query error: ' + qe.getMessage();
            result.accountId = request.accountId;
            result.productType = '';
            result.changeSummary = 'Error occurred';
            
        } catch (DmlException de) {
            System.debug('');
            System.debug('❌ ERROR - DmlException: ' + de.getMessage());
            System.debug('Error Code: ' + de.getDmlType(0));
            System.debug('Stack Trace: ' + de.getStackTraceString());
            result.success = false;
            result.message = 'Update error: ' + de.getMessage();
            result.accountId = request.accountId;
            result.productType = '';
            result.changeSummary = 'Error occurred';
            
        } catch (Exception e) {
            System.debug('');
            System.debug('❌ ERROR - Exception: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
            result.success = false;
            result.message = 'Error: ' + e.getMessage();
            result.accountId = request.accountId;
            result.productType = '';
            result.changeSummary = 'Error occurred';
        }
        
        System.debug('╔════════════════════════════════════════════════════════════╗');
        System.debug('║  End updateAccountProductType');
        System.debug('╚════════════════════════════════════════════════════════════╝');
        System.debug('');
        
        results.add(result);
        return results;
    }
    
    /**
     * BUILD PRODUCT TYPE STRING
     * 
     * Builds semicolon-delimited string from qualifying opportunities
     * 
     * @param opportunities List of opportunities already filtered by stage/value
     * @param triggerOppId The opportunity that triggered this update
     * @return String Semicolon-delimited unique product types
     */
    private static String buildProductTypeString(List<Opportunity> opportunities, Id triggerOppId) {
        System.debug('   → buildProductTypeString()');
        
        Set<String> uniqueProducts = new Set<String>();
        List<String> productList = new List<String>();
        
        Integer processedCount = 0;
        Integer duplicateCount = 0;
        Integer emptyCount = 0;
        
        for (Opportunity opp : opportunities) {
            String productStatus = opp.Product_Status__c;
            
            if (productStatus != null) {
                productStatus = productStatus.trim();
            }
            
            if (String.isBlank(productStatus)) {
                emptyCount++;
                continue;
            }
            
            if (!uniqueProducts.contains(productStatus)) {
                uniqueProducts.add(productStatus);
                productList.add(productStatus);
                processedCount++;
                
                String marker = '';
                if (triggerOppId != null && opp.Id == triggerOppId) {
                    marker = ' ⭐';
                }
                System.debug('      [' + opp.Name + '] ✓ ADDED: "' + productStatus + '"' + marker);
            } else {
                duplicateCount++;
                System.debug('      [' + opp.Name + '] SKIPPED (DUPLICATE): "' + productStatus + '"');
            }
        }
        
        String result = String.join(productList, ';');
        
        System.debug('');
        System.debug('   Processing Summary:');
        System.debug('      Total processed: ' + processedCount + ' products');
        System.debug('      Duplicates removed: ' + duplicateCount);
        System.debug('      Empty/Null skipped: ' + emptyCount);
        System.debug('      Final unique count: ' + productList.size());
        System.debug('      Final string: "' + result + '"');
        System.debug('   ← buildProductTypeString() complete');
        System.debug('');
        
        return result;
    }
    
    /**
     * CREATE CHANGE SUMMARY
     */
    private static String createChangeSummary(
        Id opportunityId,
        String priorValue,
        String newValue,
        String accountBefore,
        String accountAfter
    ) {
        System.debug('   → createChangeSummary()');
        
        String summary = '';
        
        if (opportunityId != null) {
            String oppIdStr = String.valueOf(opportunityId);
            if (String.isNotBlank(oppIdStr) && oppIdStr.length() >= 15) {
                String oppIdShort = oppIdStr.substring(0, 15);
                summary += 'Opp: ' + oppIdShort + ' | ';
                System.debug('      Trigger Opp: ' + oppIdShort);
            }
        }
        
        if (priorValue != null && newValue != null) {
            summary += 'Opp changed: "' + priorValue + '" → "' + newValue + '" | ';
            System.debug('      Opp change: "' + priorValue + '" → "' + newValue + '"');
        }
        
        String accountBeforeDisplay = String.isBlank(accountBefore) ? '(EMPTY/NULL)' : '"' + accountBefore + '"';
        String accountAfterDisplay = '"' + accountAfter + '"';
        
        if (!safeStringEquals(accountBefore, accountAfter)) {
            summary += 'Account: ' + accountBeforeDisplay + ' → ' + accountAfterDisplay;
            System.debug('      Account change: ' + accountBeforeDisplay + ' → ' + accountAfterDisplay);
        } else {
            summary += 'Account: No change (field already correct)';
            System.debug('      Account: No change');
        }
        
        System.debug('   ← createChangeSummary() complete');
        System.debug('      Full Summary: ' + summary);
        
        return summary;
    }
    
    /**
     * SAFE STRING EQUALS - NULL-SAFE COMPARISON
     */
    private static Boolean safeStringEquals(String str1, String str2) {
        if (str1 == null && str2 == null) return true;
        if (String.isBlank(str1) && String.isBlank(str2)) return true;
        if (str1 == null || str2 == null) return false;
        return str1.equals(str2);
    }
}