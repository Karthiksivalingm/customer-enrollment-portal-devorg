public class MeetingRequestController {
    public String meetingRequestId { get; set; }
    public Meeting_Request__c meetingRequest { get; set; }
    public List<AttendeeWrapper> attendees { get; set; }

    public MeetingRequestController() {
        meetingRequest = new Meeting_Request__c();
        attendees = new List<AttendeeWrapper>();
    }

    public void generateTextBoxes() {
        attendees.clear();
        Integer numAttendees = (meetingRequest.List_of_Attendeess__c != null) ? Integer.valueOf(meetingRequest.List_of_Attendeess__c) : 0;
        for (Integer i = 0; i < numAttendees; i++) {
            attendees.add(new AttendeeWrapper(i, ''));
        }
    }

    public PageReference saveMeetingRequest() {
        // Save the meeting request with the attendees list as JSON
        List<String> attendeeNames = new List<String>();
        for (AttendeeWrapper wrapper : attendees) {
            attendeeNames.add(wrapper.name);
        }
        meetingRequest.Attendees_List__c = JSON.serialize(attendeeNames);
        
        // Save the meeting request record
        if (meetingRequestId != null && !String.isBlank(meetingRequestId)) {
            meetingRequest.Id = meetingRequestId;
        }
        upsert meetingRequest;
        
        // Optionally, navigate to a success page or display a message
        return null;
    }

    public class AttendeeWrapper {
        public Integer index { get; set; }
        public String name { get; set; }

        public AttendeeWrapper(Integer index, String name) {
            this.index = index;
            this.name = name;
        }
    }
}