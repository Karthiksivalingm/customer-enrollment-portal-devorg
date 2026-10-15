global class EventAttendeeStatusScheduler
implements Schedulable {

    global void execute(SchedulableContext sc) {

        List<EventRelation> relations = [
            SELECT Id,
                   EventId,
                   RelationId,
                   Status,
                   RespondedDate,
                   IsInvitee
            FROM EventRelation
            WHERE IsInvitee = true
        ];

        for(EventRelation er : relations){

            System.debug(
                'Status=' + er.Status +
                ' Responded=' + er.RespondedDate
            );
        }
    }
}