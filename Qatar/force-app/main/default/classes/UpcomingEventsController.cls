public with sharing class UpcomingEventsController {
    @AuraEnabled(cacheable=true)
    public static List<Event> getUpcomingEvents(String filter) {
        DateTime startRange = DateTime.now();
        DateTime endRange;

        if (filter == 'this_week') {
            endRange = DateTime.now().addDays(7);
        } else if (filter == 'this_month') {
            endRange = DateTime.now().addDays(30);
        } else if (filter == 'next_30') {
            endRange = DateTime.now().addDays(30);
        } else {
            endRange = DateTime.now().addDays(365);
        }

        return [
            SELECT Id, Subject, StartDateTime, EndDateTime, OwnerId
            FROM Event
            WHERE StartDateTime >= :startRange
            AND StartDateTime <= :endRange
            AND IsChild = false
            ORDER BY StartDateTime ASC
            LIMIT 50
        ];
    }
}