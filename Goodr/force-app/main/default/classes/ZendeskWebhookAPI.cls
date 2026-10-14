@RestResource(urlMapping='/zendeskSfWebhook/*')
global with sharing class ZendeskWebhookAPI {

    @HttpPost
    global static void handleWebhook() {

        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        try {

            String body = req.requestBody.toString();
            System.debug('Webhook Payload: ' + body);

            Map<String,Object> data =
                (Map<String,Object>) JSON.deserializeUntyped(body);

            String subject = (String) data.get('subject');
            String description = (String) data.get('description');
            String priority = (String) data.get('priority');
            String requestorName = (String) data.get('RequestorName');
            String requestorEmail = (String) data.get('RequestorEmail');
            String brand = (String) data.get('BrandName');
            String requesttype = (String) data.get('RequestorType');

            System.debug('Incoming Request Type (Zendesk Tag): ' + requesttype);

            String zendeskId = data.get('ids') != null
                ? String.valueOf(data.get('ids'))
                : null;

            //  Find existing Contact
            Contact con;
            if(String.isNotBlank(requestorEmail)){
                List<Contact> conList = [
                    SELECT Id, Email
                    FROM Contact
                    WHERE Email = :requestorEmail
                    LIMIT 1
                ];

                if(!conList.isEmpty()){
                    con = conList[0];
                }
            }

           
         

            //  Create Case
            Case c = new Case();
            c.Subject = subject;
            c.Zendesk_Description__c = description;
            c.Origin = 'Zendesk';
            c.Zendesk_ID__c = zendeskId;
            c.Priority = String.isNotBlank(priority) ? priority : 'Medium';
            c.SuppliedEmail = requestorEmail;
            c.SuppliedName = requestorName;
            c.Description= requesttype;
            
            if((brand=='Global Support')&&(brand!=null)){
              Group g = [SELECT Id, Name, DeveloperName FROM Group WHERE Type = 'Queue' AND Name = 'Global'];
              c.OwnerId = g.Id;
            }
            else if((brand=='B2B Support (Specialty)')&&(brand!=null)){
               Group g = [ SELECT Id, Name, DeveloperName FROM Group WHERE Type = 'Queue'AND Name = 'Specialty Support'];
                c.OwnerId = g.Id;
            }
            else if((brand=='Key Accounts')&&(brand!=null)){
                 Group g = [SELECT Id, Name, DeveloperName FROM Group WHERE Type = 'Queue'AND Name = 'Retail Orders'];
                c.OwnerId = g.Id;
            }
            
            if(con != null){
                c.ContactId = con.Id;
            }

            insert c;

            res.statusCode = 200;
            res.responseBody = Blob.valueOf('Success');

        } catch(Exception e) {

            System.debug('Error: ' + e.getMessage());

            res.statusCode = 500;
            res.responseBody = Blob.valueOf(e.getMessage());
        }
    }
}