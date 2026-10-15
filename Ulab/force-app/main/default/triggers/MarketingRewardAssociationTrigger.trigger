trigger MarketingRewardAssociationTrigger
on Marketing_Reward_Association__c (before insert, before update) {

    if (Trigger.isBefore) {

        MarketingRewardAssociationHandler.handleBefore(
            Trigger.new,
            Trigger.isUpdate ? Trigger.oldMap : null
        );

        MRASendToBoomi.validate(
            Trigger.new,
            Trigger.isUpdate ? Trigger.oldMap : null
        );
    }
}