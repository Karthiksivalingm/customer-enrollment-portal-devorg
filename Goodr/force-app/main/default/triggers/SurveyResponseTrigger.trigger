trigger SurveyResponseTrigger on
    SurveyResponse (after insert) {

    // ✅ InvitationId confirmed from log
    // ✅ InviteExpiryDateTime confirmed from log
    // ✅ Fires after survey is submitted
    // ✅ Expires link immediately

    // Step 1 - Get invitation IDs
    // from submitted responses
    Set<Id> invitationIds = new Set<Id>();

    for (SurveyResponse sr : Trigger.new) {
        if (sr.InvitationId != null) {
            invitationIds.add(sr.InvitationId);
        }
    }

    if (invitationIds.isEmpty()) {
        System.debug(
            '>>> No invitations to expire'
        );
        return;
    }

    System.debug(
        '>>> Survey responses captured: ' +
        Trigger.new.size() +
        ' | Invitations to expire: ' +
        invitationIds.size()
    );

    // Step 2 - Query invitations
    List<SurveyInvitation> toExpire = [
        SELECT Id,
               Name,
               InviteExpiryDateTime,
               ResponseStatus
        FROM SurveyInvitation
        WHERE Id IN :invitationIds
    ];

    if (toExpire.isEmpty()) {
        System.debug(
            '>>> No invitations found'
        );
        return;
    }

    // Step 3 - Set expiry to past
    // Response captured = link expires now
    for (SurveyInvitation si : toExpire) {
        System.debug(
            '>>> Expiring: ' + si.Name +
            ' | Before: ' +
            si.InviteExpiryDateTime +
            ' | Status: ' +
            si.ResponseStatus
        );
        // 1 year in past = immediately expired
        si.InviteExpiryDateTime =
            DateTime.now().addYears(-1);
    }

    // Step 4 - Update with partial success
    // false = dont throw on single failure
    Database.SaveResult[] results =
        Database.update(toExpire, false);

    Integer success = 0;
    Integer failed  = 0;

    for (Integer i = 0;
         i < results.size(); i++) {
        if (results[i].isSuccess()) {
            success++;
            System.debug(
                '>>> Expired: ' +
                toExpire[i].Name
            );
        } else {
            failed++;
            System.debug(
                '>>> Failed: ' +
                toExpire[i].Name +
                ' | Error: ' +
                results[i].getErrors()[0]
                .getMessage()
            );
        }
    }

    System.debug(
        '>>> Complete' +
        ' | Expired: ' + success +
        ' | Failed: '  + failed
    );
}