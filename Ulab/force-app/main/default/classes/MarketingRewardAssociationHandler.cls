public class MarketingRewardAssociationHandler {

    public static void handleBefore(
        List<Marketing_Reward_Association__c> newRecords,
        Map<Id, Marketing_Reward_Association__c> oldMap
    ) {

        Set<Id> companyIds = new Set<Id>();

        for (Marketing_Reward_Association__c rec : newRecords) {

            // Skip update if dates not changed
            if (oldMap != null && oldMap.containsKey(rec.Id)) {

                Marketing_Reward_Association__c oldRec = oldMap.get(rec.Id);

                if (
                    oldRec.Effective_Date__c == rec.Effective_Date__c &&
                    oldRec.End_Date__c == rec.End_Date__c
                ) {
                    continue;
                }
            }

            // Only process Futures promo records
            if (
                rec.Company__c != null &&
                rec.NetSuite_Promo_Code__c != null &&
                rec.NetSuite_Promo_Code__c.contains('Futures') &&
                rec.Effective_Date__c != null &&
                rec.End_Date__c != null
            ) {
                companyIds.add(rec.Company__c);
            }
        }

        if (companyIds.isEmpty()) {
            return;
        }

        // Existing records
        List<Marketing_Reward_Association__c> existingRecords = [
            SELECT Id,
                   Company__c,
                   Promo_Item__c,
                   Bundle_Types__c,
                   NetSuite_Promo_Code__c,
                   Effective_Date__c,
                   End_Date__c
            FROM Marketing_Reward_Association__c
            WHERE Company__c IN :companyIds
            AND NetSuite_Promo_Code__c LIKE '%Futures%'
            AND Effective_Date__c != null
            AND End_Date__c != null
        ];

        for (Marketing_Reward_Association__c newRec : newRecords) {

            // Skip invalid records
            if (
                newRec.Company__c == null ||
                newRec.NetSuite_Promo_Code__c == null ||
                !newRec.NetSuite_Promo_Code__c.contains('Futures') ||
                newRec.Effective_Date__c == null ||
                newRec.End_Date__c == null
            ) {
                continue;
            }

            Boolean hasOverlap = false;
            Date maxOverlappingEndDate = null;

            for (Marketing_Reward_Association__c existing : existingRecords) {

                // Skip same record during update
                if (existing.Id == newRec.Id) {
                    continue;
                }

                // Company must match
                if (existing.Company__c != newRec.Company__c) {
                    continue;
                }

                // Both records must contain Futures
                if (
                    existing.NetSuite_Promo_Code__c == null ||
                    !existing.NetSuite_Promo_Code__c.contains('Futures')
                ) {
                    continue;
                }

                // Date overlap check
                Boolean dateOverlaps =
                    newRec.Effective_Date__c <= existing.End_Date__c &&
                    newRec.End_Date__c >= existing.Effective_Date__c;

                if (!dateOverlaps) {
                    continue;
                }

                Boolean isMatch = false;

                // =====================================================
                // BUNDLE vs BUNDLE
                // =====================================================
                if (
                    newRec.Promo_Item__c == 'Bundle' &&
                    existing.Promo_Item__c == 'Bundle'
                ) {

                    String existingBundle =
                        existing.Bundle_Types__c != null
                        ? existing.Bundle_Types__c.trim().toLowerCase()
                        : '';

                    String newBundle =
                        newRec.Bundle_Types__c != null
                        ? newRec.Bundle_Types__c.trim().toLowerCase()
                        : '';

                    System.debug('Existing Bundle: ' + existingBundle);
                    System.debug('New Bundle: ' + newBundle);

                    // Both bundle types empty/null
                    if (
                        existingBundle == '' &&
                        newBundle == ''
                    ) {

                        System.debug(
                            'Both Bundle Types Empty -> MATCH'
                        );

                        isMatch = true;

                    } else {

                        // Match if bundle values overlap
                        isMatch =
                            existingBundle != '' &&
                            newBundle != '' &&
                            (
                                existingBundle.contains(newBundle) ||
                                newBundle.contains(existingBundle)
                            );
                    }

                    System.debug(
                        'Final Bundle Match Result: ' + isMatch
                    );
                }

                // =====================================================
                // NON-BUNDLE vs NON-BUNDLE ONLY
                // =====================================================
                else if (
                    newRec.Promo_Item__c != 'Bundle' &&
                    existing.Promo_Item__c != 'Bundle'
                ) {

                    isMatch = true;
                }

                // =====================================================
                // If match found
                // =====================================================
                if (isMatch) {

                    hasOverlap = true;

                    if (
                        maxOverlappingEndDate == null ||
                        existing.End_Date__c > maxOverlappingEndDate
                    ) {
                        maxOverlappingEndDate = existing.End_Date__c;
                    }
                }
            }

            // =====================================================
            // Adjust or throw error
            // =====================================================
            if (hasOverlap) {

                Date adjustedEffectiveDate =
                    maxOverlappingEndDate.addDays(1);

                if (adjustedEffectiveDate > newRec.End_Date__c) {

                    newRec.addError(
                        'There is already a similar promotion available for this Account ' +
                        'on the selected dates. Please change the dates and try again.'
                    );

                } else {

                    newRec.Effective_Date__c = adjustedEffectiveDate;
                }
            }
        }
    }
}