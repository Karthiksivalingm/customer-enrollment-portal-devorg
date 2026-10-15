//Test Scenarios
//https://apis.qa.aligneroem.com/shared/v1/org/199040/patients/64822/txplans/616614/messages
//https://apis.qa.aligneroem.com/shared/v1/org/199040/patients/64782/txplans/616575/messages
//https://ulab--staging.sandbox.lightning.force.com/lightning/r/uLab_Order__c/a0FRK000002dVKX2A2/view
//https://ulab--staging.sandbox.lightning.force.com/lightning/r/uLab_Order__c/a0FRK000002vl2f2AA/view
//
global class Showme 
{
    
    @AuraEnabled
    public static list<mymessages> getmessagesfromapi(id recordide)
    {
        
        //Get Record id and other details
        string ab;
        string bc;
        string ab1;
        string dc;
        string dg;
        string dh;
        string dff;
        String JobID;
        JobID =  recordide;
        uLab_Order__c getdata;
        uLab_Case__c getcase;
        Patient__c getpatient;
        Integer patientid;
        Integer caseid;
        Integer Accid;
        Integer kkid;
        Integer mmid;
        Integer kmid;
        Integer mmid1;
        Integer mmid2;
        Integer mmid3;
        
        list<mymessages> getall = new list<mymessages>();
        integer size;
        integer sizeavatar;
        integer i;
        integer j;
        integer k;
        integer userid;
        String title;
        boolean flag = false;
        String planname;
        String containall;
        String plan;
        String content;
        String subject;
        String contentplan;
        String subjectplan;
        String none;
        String subjectcontent;
        try{
            getdata = [Select id,uLab_Acct_Number__c,uLab_Case__c,test__c from uLab_Order__c where id=:JobID limit 1];
            getcase = [Select id,Name,Patient_ID__c from uLab_Case__c where id=:getdata.uLab_Case__c limit 1];
            getpatient = [Select id,Name from Patient__c where id=:getcase.Patient_ID__c limit 1];
        
            if((getpatient !=null)&& (getpatient.Name != null))
            {
                patientid = Integer.valueof((getpatient.Name).replace('PID-', ''));
            }
            if((getcase !=null)&& (getcase.name != null))
            {
                caseid = Integer.valueof(getcase.name);
            }
            if((getdata !=null)&& (getdata.uLab_Acct_Number__c != null))
            {
                Accid = Integer.valueof(getdata.uLab_Acct_Number__c);
            }
            //Get Access token
            HttpRequest req = new HttpRequest(); 
            req.setEndpoint(System.Label.tokenapi); 
            req.setMethod('POST'); 
            req.setHeader('Authorization', System.Label.Authkey);
            req.setHeader('Cache-Control', 'no-cache');
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            req.setBody('grant_type=client_credentials&scope=m2m');
            Http http = new Http(); 
            HTTPResponse res; 
            res = http.send(req);                 
            String Response = res.getBody();
            
            //get messages through api
            tokenWrapper Wrapper =(tokenWrapper) System.JSON.deserialize(Response, tokenWrapper.class);
            String token = Wrapper.access_token;
            HttpRequest req1 = new HttpRequest(); 
            req1.setEndpoint('https://apis.qa.aligneroem.com/shared/v1/org/'+Accid+'/patients/'+patientid+'/txplans/'+caseid+'/messages');
            req1.setMethod('GET'); 
            req1.setHeader('Authorization', 'Bearer '+token);
            Http http1 = new Http(); 
            HTTPResponse res1; 
            res1 = http1.send(req1);                 
            String Response1 = res1.getBody(); 
             system.debug('Response1'+Response1);
        fromJSON Wrapper1;
        string json23;
        if(getdata.test__c=='test123'){        
         json23='{"results":{"current_thread":[{"id":338,"created_at":"2022-10-05T19:47:06Z","updated_at":"2022-10-05T19:47:06Z","created_by":2651,"updated_by":0,"is_active":1,"org_id":2019,"user_id":2651,"unread":1,"type_id":565771,"body":"message","request_round":0,"message_type":"MESSAGE","plan_name":"Standard Plan"},{"id":338,"created_at":"2022-10-05T19:47:06Z","updated_at":"2022-10-05T19:47:06Z","created_by":2651,"updated_by":0,"is_active":1,"org_id":2019,"user_id":111,"unread":1,"type_id":565771,"body":"message","request_round":0,"message_type":"MESSAGE","plan_name":"Standard Plan"}],"users_avatar":[{"id":2651,"first_name":"uLabSQA","last_name":"uAssist1","avatar_colour":"#16AADC","avatar_link":"-","title_name":{"id":394,"type_id":59,"type_name":"uAssist User","kind_id":"USER_SYST_TYPE"}},{"id":111,"first_name":"uLabSQA","last_name":"uAssist1","avatar_colour":"#16AADC","avatar_link":"-","title_name":{"id":394,"type_id":59,"type_name":"ortho","kind_id":"USER_SYST_TYPE"}}]},"message":{"content":"It has been designed.","subject":"Please review the case"}}';       
     //string   responsew = json23.serializePretty(json23.deserializeUntyped(json23));
       Wrapper1 =(fromJSON) System.JSON.deserialize(json23, fromJSON.class);
            size = (Wrapper1.results.current_thread).size();
        }
        else {
          Wrapper1 =(fromJSON) System.JSON.deserialize(Response1, fromJSON.class);
            size = (Wrapper1.results.current_thread).size();
        }
            sizeavatar = (Wrapper1.results.users_avatar).size();
           
            for(i=0;i<size;i++)
            {
                flag = false;  
                message Wrapper2;
                string json12;
                String jsonString;
                if(getdata.test__c=='test123'){
                json12='{\"sender\": {\"title\": \"uAssist User\", \"user_id\": 2651, \"lastname\": \"uAssist\", \"firstname\": \"uLabSQA\", \"avatar_link\": \"-\", \"avatar_color\": \"#16AADC\"}, \"content\": \"It has been designed.\", \"subject\": \"Please review the case\"}';
                 Wrapper2=(message) System.JSON.deserialize(json12, message.class);
                   jsonString = json12;
               }
                else{
                 Wrapper2 =(message) System.JSON.deserialize(Wrapper1.results.current_thread[i].body, message.class);
                 jsonString = Wrapper1.results.current_thread[i].body;
                }
                
				Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
				System.debug('Subject: ' + parsed.get('subject'));
                mymessages aks = new mymessages();
                userid = Wrapper1.results.current_thread[i].user_id;
                for(j=0;j<sizeavatar;j++)
                {
                    if((Wrapper1.results.users_avatar[j].id) == userid)
                    {
                        title = Wrapper1.results.users_avatar[j].title_name.type_name;
                        aks.firstname = Wrapper1.results.users_avatar[j].first_name+' ';
                        aks.lastname = Wrapper1.results.users_avatar[j].last_name;
                        aks.initials = ((aks.firstname).left(1)) +((aks.lastname).left(1));
                        aks.initials =  (aks.initials).toUpperCase(); 
                        if(Wrapper1.results.current_thread[i].plan_name != null && Wrapper1.results.current_thread[i].plan_name !='')
                        {
                        aks.planname =  Wrapper1.results.current_thread[i].plan_name;   
                        }
                        String dt = (Wrapper1.results.current_thread[i].created_at);
                        Datetime GMTDate = Datetime.newInstanceGmt(integer.valueOf(dt.substring(0,4)),integer.valueOf(dt.substring(5,7)),integer.valueOf(dt.substring(8,10)),integer.valueOf(dt.substring(11,13)),integer.valueOf(dt.substring(14,16)),integer.valueOf(dt.substring(17,19)));
                        String myDate = GMTDate.format('MM/dd/yyyy, h:mm a');
                        aks.createddate = myDate;
                        if((Wrapper1.results.users_avatar[j].id) == 1 || (Wrapper1.results.users_avatar[j].id) == 59 || ((Wrapper1.results.users_avatar[j].title_name.type_name).contains('uAssist')))
                        {
                            flag = true;
                            aks.firstname = title +' '+'|'+' '+Wrapper1.results.users_avatar[j].first_name+' ';
                            
                        }
                        else
                        {
                           aks.lastname = Wrapper1.results.users_avatar[j].last_name +' '+'|'+' '+title; 
                            if(Wrapper1.results.users_avatar[j].avatar_colour !=null && Wrapper1.results.users_avatar[j].avatar_colour !='')
                        {
                            aks.color = 'background-color: '+Wrapper1.results.users_avatar[j].avatar_colour+'!important;';
                        }
                        else
                        {
                            aks.color = 'background-color: #739EFF !important;';   
                        }
                        }
                    }
                }
                if(flag == true)
                {
                    if((Wrapper2.Subject != null && Wrapper2.Subject != '') && (Wrapper2.content != null && Wrapper2.content != ''))
                    {
                        aks.messageuser =  Wrapper2.Subject +'. '+ Wrapper2.content+'.';
                    }
                    if((Wrapper2.Subject != null && Wrapper2.Subject != '') && (Wrapper2.content == null || Wrapper2.content == ''))
                    {
                        aks.messageuser =  Wrapper2.Subject+'.';
                    }
                    if((Wrapper2.Subject == null || Wrapper2.Subject == '') && (Wrapper2.content != null && Wrapper2.content != ''))
                    {
                        aks.messageuser =  Wrapper2.content+'.';
                        
                    }
                    if(Wrapper2.Subject != null && Wrapper2.Subject != '')
                    {
                        aks.messagesubjectuser =  Wrapper2.Subject+'. ';
                    }
                    if(Wrapper2.content != null && Wrapper2.content != '')
                    {
                        aks.messagecontentuser =  Wrapper2.content+'.';
                    }
                    if(aks.messagesubjectuser !='' && aks.messagesubjectuser != null && aks.messagecontentuser !='' && aks.messagecontentuser !=null && aks.planname != '' && aks.planname !=null)
                    {
                        aks.containall = 'true';
                    }
                    if((aks.messagesubjectuser =='' || aks.messagesubjectuser == null) && aks.messagecontentuser !='' && aks.messagecontentuser !=null && aks.planname != '' && aks.planname !=null)
                    {
                        aks.contentplan = 'true';
                    }
                    if(aks.messagesubjectuser !='' && aks.messagesubjectuser != null && (aks.messagecontentuser =='' || aks.messagecontentuser ==null) && aks.planname != '' && aks.planname !=null)
                    {
                        aks.subjectplan = 'true';
                    }
                    if(aks.messagesubjectuser !='' && aks.messagesubjectuser != null && aks.messagecontentuser !='' && aks.messagecontentuser !=null && (aks.planname == '' || aks.planname ==null))
                     {
                        aks.subjectcontent = 'true';
                    }
                    if((aks.messagesubjectuser =='' || aks.messagesubjectuser == null) && (aks.messagecontentuser =='' || aks.messagecontentuser ==null) && aks.planname != '' && aks.planname !=null)
                    {
                        aks.plan = 'true';
                    }
                    if((aks.messagesubjectuser =='' || aks.messagesubjectuser == null) && aks.messagecontentuser !='' && aks.messagecontentuser !=null && (aks.planname == '' || aks.planname ==null))
                    {
                        aks.content = 'true';
                    }
                    if(aks.messagesubjectuser !='' && aks.messagesubjectuser != null && (aks.messagecontentuser =='' || aks.messagecontentuser ==null) && (aks.planname == '' || aks.planname ==null))
                    {
                        aks.subject = 'true';
                    }
                    if((aks.messagesubjectuser =='' || aks.messagesubjectuser == null) && (aks.messagecontentuser =='' || aks.messagecontentuser ==null) && (aks.planname == '' || aks.planname ==null))
                    {
                        aks.none = 'true';
                    }
                }
                if(flag == false)
                {
                    if((Wrapper2.Subject != null && Wrapper2.Subject != '') && (Wrapper2.content != null && Wrapper2.content != ''))
                    {
                        aks.messagecustomer =  Wrapper2.Subject +'. '+ Wrapper2.content+'.';
                    }
                    if((Wrapper2.Subject != null && Wrapper2.Subject != '') && (Wrapper2.content == null || Wrapper2.content == ''))
                    {
                        aks.messagecustomer =  Wrapper2.Subject+'.';
                    }
                    if((Wrapper2.Subject == null || Wrapper2.Subject == '') && (Wrapper2.content != null && Wrapper2.content != ''))
                    {
                        aks.messagecustomer =  Wrapper2.content+'.';      
                    }
                    if(Wrapper2.Subject != null && Wrapper2.Subject != '')
                    {
                        aks.messagesubjectcustomer =  Wrapper2.Subject+'. ';
                    }
                    if(Wrapper2.content != null && Wrapper2.content != '')
                    {
                        aks.messagecontentcustomer =  Wrapper2.content+'.';
                    }
                    
                    if(aks.messagesubjectcustomer !='' && aks.messagesubjectcustomer != null && aks.messagecontentcustomer !='' && aks.messagecontentcustomer !=null && aks.planname != '' && aks.planname !=null)
                    {
                        aks.containall = 'true';
                    }
                    if((aks.messagesubjectcustomer =='' || aks.messagesubjectcustomer == null) && aks.messagecontentcustomer !='' && aks.messagecontentcustomer !=null && aks.planname != '' && aks.planname !=null)
                    {
                        aks.contentplan = 'true';
                    }
                    if(aks.messagesubjectcustomer !='' && aks.messagesubjectcustomer != null && (aks.messagecontentcustomer =='' || aks.messagecontentcustomer ==null) && aks.planname != '' && aks.planname !=null)
                    {
                        aks.subjectplan = 'true';
                    }
                    if(aks.messagesubjectcustomer !='' && aks.messagesubjectcustomer != null && aks.messagecontentcustomer !='' && aks.messagecontentcustomer !=null && (aks.planname == '' || aks.planname ==null))
                     {
                        aks.subjectcontent = 'true';
                    }
                    if((aks.messagesubjectcustomer =='' || aks.messagesubjectcustomer == null) && (aks.messagecontentcustomer =='' || aks.messagecontentcustomer ==null) && aks.planname != '' && aks.planname !=null)
                    {
                        aks.plan = 'true';
                    }
                    if((aks.messagesubjectcustomer =='' || aks.messagesubjectcustomer == null) && aks.messagecontentcustomer !='' && aks.messagecontentcustomer !=null && (aks.planname == '' || aks.planname ==null))
                    {
                        aks.content = 'true';
                    }
                    if(aks.messagesubjectcustomer !='' && aks.messagesubjectcustomer != null && (aks.messagecontentcustomer =='' || aks.messagecontentcustomer ==null) && (aks.planname == '' || aks.planname ==null))
                    {
                        aks.subject = 'true';
                    }
                    if((aks.messagesubjectcustomer =='' || aks.messagesubjectcustomer == null) && (aks.messagecontentcustomer =='' || aks.messagecontentcustomer ==null) && (aks.planname == '' || aks.planname ==null))
                    {
                        aks.none = 'true';
                    }
                }
                getall.add(aks);
            } 
        }
        catch(Exception e)
        {
            
        }
        return getall;
    }
    // Wrapper class
    public class tokenWrapper{
        public String access_token{get;set;}
       }
    
    public class fromJSON{
        public cls_results results;
    }
    class cls_results {
        public cls_current_thread[] current_thread;
        public cls_users_avatar[] users_avatar;
    }
    class cls_current_thread {
        public Integer id;	//338
        public String created_at;	//2022-10-05T19:47:06Z
        public String updated_at;	//2022-10-05T19:47:06Z
        public Integer created_by;	//2651
        public Integer updated_by;	//0
        public Integer is_active;	//1
        public Integer org_id;	//2019
        public Integer user_id;	//2651
        public Integer unread;	//1
        public Integer type_id;	//565771
        public String body;	//{"sender": {"title": "uAssist User", "user_id": 2651, "lastname": "uAssist", "firstname": "uLabSQA", "avatar_link": "-", "avatar_color": "-"}, "content": "It has been designed.", "subject": "Please review the case"}
        public Integer request_round;	//0
        public String message_type;	//MESSAGE
        public String plan_name;	//
    }
    
    class cls_users_avatar {
        public Integer id;	//2651
        public String first_name;	//uLabSQA
        public String last_name;	//uAssist1
        public String avatar_colour;	//#16AADC
        public String avatar_link;	//-
        public cls_title_name title_name;
    }
    class cls_title_name {
        public Integer id;	//394
        public Integer type_id;	//59
        public String type_name;	//uAssist User
        public String kind_id;	//USER_SYST_TYPE
    }
    public class message{
        public String content;	//It has been designed.
        public String subject;	//
    }
    
    public class mymessages{
        @AuraEnabled public  String createddate;
        @AuraEnabled public  String messagesubjectcustomer;
        @AuraEnabled public  String messagecontentcustomer;
        @AuraEnabled public  String messagecustomer;
        @AuraEnabled public String messagesubjectuser;
        @AuraEnabled public String messagecontentuser;
        @AuraEnabled public String messageuser;
        @AuraEnabled public String firstname;
        @AuraEnabled public String lastname;
        @AuraEnabled public String initials;
        @AuraEnabled public String color;
        @AuraEnabled public String containall;
        @AuraEnabled public String plan;
        @AuraEnabled public String content;
        @AuraEnabled public String subject;
        @AuraEnabled public String contentplan;
        @AuraEnabled public String subjectplan;
        @AuraEnabled public String none;
        @AuraEnabled public String subjectcontent;
        @AuraEnabled public String planname;
    }
}