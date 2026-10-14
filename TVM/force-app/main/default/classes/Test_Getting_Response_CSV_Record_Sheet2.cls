// Test class from FND

@isTest
public class Test_Getting_Response_CSV_Record_Sheet2 
{
    
    private static String uniqueSuffix() {        
        Integer rnd = Math.abs(Math.mod(Math.abs(Crypto.getRandomInteger()), 1000000));
        return String.valueOf(rnd);
    }

    @isTest
    public static void EmailAttachmentTester()
    {
      
        String suf = uniqueSuffix();

        Account objAccount = new Account(
            Name = 'Test_' + suf,
            Quickbase_Record_ID__c = suf + 1
        );
        INSERT objAccount;
        
        Opportunity testOpp = new Opportunity(
            Name = objAccount.Name,
            StageName = 'Onboarding',
            CloseDate = Date.today(),
            AccountId = objAccount.Id
        );
        INSERT testOpp;
        
        Account accRecord2 = new Account(
            Name = 'Test Acc2 ' + suf,
            Quickbase_Record_ID__c = suf
        );
        insert accRecord2;
        
        Contact objContact1 = new Contact();
        objContact1.LastName = 'Test';
        objContact1.AccountId = accRecord2.Id;
        INSERT objContact1;
        
        // Create test data for Foundation_Onboarding__c records
        List<Foundation_Onboarding__c> testOnboardingList = new List<Foundation_Onboarding__c>();
        // Add test data for Business Intelligence Onboarding
        testOnboardingList.add(new Foundation_Onboarding__c(
            Opportunity__c = testOpp.Id,
            Account__c = objAccount.Id,
            Mutual_Client_with_VistaDash__c = true,
            Foundation_GA4_View__c = 'Test',
            GTM_Container_Updated_for_GA4__c = Date.today(),
            Vistadash_Conversions_Configuration_GA4__c = Date.today(),
            Custom_Definitions_Configurati__c  = Date.today(),
            BigQuery_is_linked_in_GA4__c = true,
            Vistadash_Event_Owner_Custom_Dimension_C__c = true,
            GA4_Notes__c = 'Test',
            Digital_Retail_Provider__c = 'Roadster',
            GA4_Measurement_ID__c = 'Test',
            GA4_Property_Name_from_this_sheet__c = 'Test',
            GA_Account_Shared__c = 'analytics@foundationdirect.com',
            GTM_ID_provided__c = 'Test',
            Google_Facebook_Pixel_script_added_to_GT__c = 'Facebook Pixel',
            GTM_on_Site__c = Date.today(),
            Website_Provider__c = 'ARI',
            Chat_Provider__c = 'Gubagoo',
            Chat_Start__c= 'Event tracked via tagged triggers',
            Click_to_Call__c = 'Event tracked via tagged triggers',
            DR_Start__c = 'Event tracked via tagged triggers',
            Finance_Start__c = 'Event tracked via tagged triggers',
            Lead_Form__c = 'Event tracked via tagged triggers'
        ));
        // Add test data for Digital Advertising Onboarding
        testOnboardingList.add(new Foundation_Onboarding__c(
            Opportunity__c = testOpp.Id,
            Account__c = accRecord2.Id,
            Foundation_GA4_View__c = 'Test',
            GTM_Container_Updated_for_GA4__c = Date.today(),
            Vistadash_Conversions_Configuration_GA4__c = Date.today(),
            Custom_Definitions_Configurati__c  = Date.today(),
            BigQuery_is_linked_in_GA4__c = false,
            Vistadash_Event_Owner_Custom_Dimension_C__c = false,
            GA4_Notes__c = 'Test',
            Digital_Retail_Provider__c = 'Roadster',
            GA4_Measurement_ID__c = 'Test'
        ));
        
        insert testOnboardingList;
        
        // Create test data for Contact records
        List<Contact> testContactList = new List<Contact>();
        testContactList.add(new Contact(
            AccountId = testOnboardingList[0].Account__c,
            LastName = 'Test'
        ));
        testContactList.add(new Contact(
            AccountId = testOnboardingList[1].Account__c,
            LastName = 'Test'
        ));
        
        insert testContactList;
        
        AccountContactRelation  accCon = new AccountContactRelation ();
        accCon.AccountId = accRecord2.id;
        accCon.ContactId = testContactList[0].Id;
        accCon.Roles = 'Onboarding';
        
        insert accCon;
        
        Foundation_Onboarding__c obj = new Foundation_Onboarding__c();
        obj.Mutual_Client_with_VistaDash__c = true;
        obj.Opportunity__c = testOpp.Id;
        
        testOpp.stageName = 'Onboarding';
        
        UPDATE testOpp;
        
         List<Foundation_Onboarding__c> listOnboardings = [SELECT Id, Name, Mutual_Client_with_VistaDash__c, Touchpoint_Master_ID__c, Account__c, Account__r.Name, Account__r.Parent.Name, Website_Provider__c,
                                               Website_URL__c, GA_Account_Shared__c, GTM_ID_provided__c, Google_Facebook_Pixel_script_added_to_GT__c, GTM_on_Site__c, GA4_Property_Name_from_this_sheet__c,
                                               GA4_Measurement_ID__c, Foundation_GA4_View__c, GTM_Container_Updated_for_GA4__c, Vistadash_Conversions_Configuration_GA4__c,
                                               Custom_Definitions_Configurati__c, Vistadash_Event_Owner_Custom_Dimension_C__c, GA4_Notes__c, Digital_Retail_Provider__c,
                                               Chat_Provider__c, Chat_Start__c, Click_to_Call__c, DR_Start__c, Finance_Start__c, Lead_Form__c,
                                               BigQuery_is_linked_in_GA4__c, Opportunity__r.Contract_Signed_Date__c
                                               FROM Foundation_Onboarding__c
                                               WHERE Opportunity__r.StageName = 'Onboarding'
                                               ORDER BY Opportunity__r.Contract_Signed_Date__c ASC
                                              ];
        
        If(!listOnboardings.isEmpty())
        {
            Map<String, List<Contact>> mapAccountContacts = new Map<String, List<Contact>>();
            
            For(Foundation_Onboarding__c objOnboarding : listOnboardings)
            {
                If(objOnboarding.Account__c != null && !mapAccountContacts.containsKey(objOnboarding.Account__c))
                {
                    List<Contact> listContacts = new List<Contact>();
                    mapAccountContacts.put(objOnboarding.Account__c, listContacts);
                }
            }
            
            List<AccountContactRelation> listAccountContactRelations = [SELECT Id, AccountId, ContactId, Roles 
                                                                        FROM AccountContactRelation
                                                                        WHERE AccountId IN : mapAccountContacts.keySet()
                                                                        AND Roles INCLUDES ('Analytics','Onboarding')
                                                                        AND ContactId != null
                                                                       ];
            
            Map<String, String> mapContactAndRoles = new Map<String, String>();
            
            If(!listAccountContactRelations.isEmpty())
            {
                For(AccountContactRelation objAccountContactRelation : listAccountContactRelations)
                {
                    mapContactAndRoles.put(objAccountContactRelation.ContactId, objAccountContactRelation.Roles);
                }
            }
            
            List<Contact> listContacts = [SELECT Name, Email, AccountId 
                                          FROM Contact 
                                          WHERE Id IN : mapContactAndRoles.keySet()
                                          AND AccountId != null
                                         ];
            
            If(!listContacts.isEmpty())
            {
                For(Contact objContact : listContacts)
                {
                    If(mapAccountContacts.containskey(objContact.AccountId) && mapAccountContacts.get(objContact.AccountId) != null)
                    {
                        mapAccountContacts.get(objContact.AccountId).add(objContact);
                    }
                }
            }
            
            String contactStr = '';
            Integer maxCountSize = 0;
            
            For(Foundation_Onboarding__c objOnboarding : listOnboardings)
            {
                //If Account field is not black.
                If(objOnboarding.Account__c != null && mapAccountContacts.containsKey(objOnboarding.Account__c))
                {
                    If(mapAccountContacts.get(objOnboarding.Account__c) != null)
                    {
                        Integer count = 0;
                        count = mapAccountContacts.get(objOnboarding.Account__c).size();
                        If(count > maxCountSize)
                        {
                            maxCountSize = count;
                        }
                    }
                }
            }
            
            For(Integer i = 1; i <= maxCountSize; i++)
            {
                If(i != maxCountSize)
                {
                    contactStr = contactStr + 'Contact Name ' + i + ', Contact Email ' + i + ', Contact Role ' + i + ',';
                }
                Else
                {
                    contactStr = contactStr + 'Contact Name ' + i + ', Contact Email ' + i + ', Contact Role ' + i;
                }
            }
            
            String finalstr = 'Mutual Client with Vistadash, Record Type (Business Intelligence or Digital Advertising), Account Name, Contract Signed Date (Old to New), Parent Account, Website URL, GA Account Access, GTM ID, Pixel script added to GTM Container, GTM on Site, GA4 Property Name, GA4 Measurement ID, GA4 Property ID, GTM Container Updated for GA4, Vistadash Conversions Configuration GA4, Custom Definitions Configuration GA4, Big Query is linked in GA4, Custom Dimension Configuration GA4, GA4 Notes, Website Provider, Digital Retail Provider, Chat Provider, Chat Start, Click to Call, DR Start, Finance Start, Lead Form, Id, Name,Touchpoint Master ID, '+ contactStr + ' \n';
            
            For(Foundation_Onboarding__c objOnboarding : listOnboardings)
            {
                //If Account field is not black.
                If(objOnboarding.Account__c != null && mapAccountContacts.containsKey(objOnboarding.Account__c))
                {
                    If(mapAccountContacts.get(objOnboarding.Account__c) != null)
                    {
                        String contactDetails = '';
                        Integer innerCount = 0;
                        Integer remainCount = 0;
                        
                        For(Contact objContact : mapAccountContacts.get(objOnboarding.Account__c))
                        {
                            innerCount = innerCount + 1;
                            contactDetails = contactDetails + objContact.Name + ',' + objContact.Email + ',' + mapContactAndRoles.get(objContact.Id) + ',';
                        }
                        
                        remainCount = maxCountSize - innerCount;
                        
                        If(remainCount > 0)
                        {
                            For(Integer j = 1; j <= remainCount; j++)
                            {
                                contactDetails = contactDetails + 'null,null,null,';
                            }
                        }
                        
                       // finalstr = finalstr + objOnboarding.Mutual_Client_with_VistaDash__c + ',';
                        
                      //  If(objOnboarding.recordTypeId == businessIntelligenceRecordTypeId)
                        {
                            finalstr = finalstr + 'Business Intelligence,';
                        }
                      //  If(objOnboarding.recordTypeId == digitalAdvertisingRecordTypeId)
                        {
                            finalstr = finalstr + 'Digital Advertising,';
                        }
                        
                      finalstr = finalstr + objOnboarding.Account__r.Name + ',' + objOnboarding.Opportunity__r.Contract_Signed_Date__c + ',' + objOnboarding.Account__r.Parent.Name + ',';
                        finalstr = finalstr + objOnboarding.Website_URL__c + ',' + objOnboarding.GA_Account_Shared__c + ',' + objOnboarding.GTM_ID_provided__c + ',';
                        finalstr = finalstr + '"[Facebook Pixel]",8/21/2023,' + objOnboarding.GA4_Property_Name_from_this_sheet__c + ',';
                        finalstr = finalstr + objOnboarding.GA4_Measurement_ID__c + ',' + objOnboarding.Foundation_GA4_View__c + ',8/21/2023,';
                        finalstr = finalstr + '8/21/2023,8/21/2023,' + objOnboarding.BigQuery_is_linked_in_GA4__c + ',' + objOnboarding.Vistadash_Event_Owner_Custom_Dimension_C__c + ',';
                        finalstr = finalstr + objOnboarding.GA4_Notes__c + ',' + objOnboarding.Website_Provider__c + ',' + objOnboarding.Digital_Retail_Provider__c + ',';// + objOnboarding.Service_Scheduler__c + ',';
                        finalstr = finalstr + objOnboarding.Chat_Provider__c + ',' + objOnboarding.Chat_Start__c + ',' + objOnboarding.Click_to_Call__c + ',';// + objOnboarding.Contact_Us__c + ',';
                        finalstr = finalstr + objOnboarding.DR_Start__c + ',' + objOnboarding.Finance_Start__c + ',' + objOnboarding.Lead_Form__c + ',';// + objOnboarding.Print_Service_Coupon__c + ',';
                        //finalstr = finalstr + objOnboarding.Schedule_Service__c + ',' + objOnboarding.Text_Start__c	 + ',' + objOnboarding.Trade_In_Start__c + ',' + objOnboarding.Id + ',' + objOnboarding.Name + ',' + objOnboarding.Touchpoint_Master_ID__c + ',' + contactDetails + ' \n';
                        finalstr = finalstr + objOnboarding.Id + ',' + objOnboarding.Name + ',' + objOnboarding.Touchpoint_Master_ID__c + ',' + contactDetails + ' \n';
                    }
                    Else
                    {
                        String contactDetails = '';
                        
                        For(Integer j = 1;j <= maxCountSize; j++)
                        {
                            contactDetails = contactDetails + 'null,null,null,';
                        }
                        
                    //    finalstr = finalstr + objOnboarding.Mutual_Client_with_VistaDash__c + ',';
                        
                    //    If(objOnboarding.recordTypeId == businessIntelligenceRecordTypeId)
                        {
                            finalstr = finalstr + 'Business Intelligence,';
                        }
                     //   If(objOnboarding.recordTypeId == digitalAdvertisingRecordTypeId)//
                        {
                            finalstr = finalstr + 'Digital Advertising,';
                        }
                        
                        finalstr = finalstr + objOnboarding.Account__r.Name + ',' + objOnboarding.Opportunity__r.Contract_Signed_Date__c + ',' + objOnboarding.Account__r.Parent.Name + ',';
                        finalstr = finalstr + objOnboarding.Website_URL__c + ',' + objOnboarding.GA_Account_Shared__c + ',' + objOnboarding.GTM_ID_provided__c + ',';
                        finalstr = finalstr + '"[Facebook Pixel]",8/21/2023,' + objOnboarding.GA4_Property_Name_from_this_sheet__c + ',';
                        finalstr = finalstr + objOnboarding.GA4_Measurement_ID__c + ',' + objOnboarding.Foundation_GA4_View__c + ',8/21/2023,';
                        finalstr = finalstr + '8/21/2023,8/21/2023,' + objOnboarding.BigQuery_is_linked_in_GA4__c + ',' + objOnboarding.Vistadash_Event_Owner_Custom_Dimension_C__c + ',';
                        finalstr = finalstr + objOnboarding.GA4_Notes__c + ',' + objOnboarding.Website_Provider__c + ',' + objOnboarding.Digital_Retail_Provider__c + ',';// + objOnboarding.Service_Scheduler__c + ',';
                        finalstr = finalstr + objOnboarding.Chat_Provider__c + ',' + objOnboarding.Chat_Start__c + ',' + objOnboarding.Click_to_Call__c + ',';// + objOnboarding.Contact_Us__c + ',';
                        finalstr = finalstr + objOnboarding.DR_Start__c + ',' + objOnboarding.Finance_Start__c + ',' + objOnboarding.Lead_Form__c + ',';// + objOnboarding.Print_Service_Coupon__c + ',';
                        //finalstr = finalstr + objOnboarding.Schedule_Service__c + ',' + objOnboarding.Text_Start__c	 + ',' + objOnboarding.Trade_In_Start__c + ',' + objOnboarding.Id + ',' + objOnboarding.Name + ',' + objOnboarding.Touchpoint_Master_ID__c + ',' +  contactDetails + ' \n';
                        finalstr = finalstr + objOnboarding.Id + ',' + objOnboarding.Name + ',' + objOnboarding.Touchpoint_Master_ID__c + ',' +  contactDetails + ' \n';
                    }
                }
                Else
                {
                    String contactDetails = '';
                    
                    For(Integer j = 1; j <= maxCountSize; j++)
                    {
                        contactDetails = contactDetails + 'null,null,null,';
                    }
                    
               //     finalstr = finalstr + objOnboarding.Mutual_Client_with_VistaDash__c + ',';
                    
                //    If(objOnboarding.recordTypeId == businessIntelligenceRecordTypeId)
                    {
                        finalstr = finalstr + 'Business Intelligence,';
                    }
               //     If(objOnboarding.recordTypeId == digitalAdvertisingRecordTypeId)
                    {
                        finalstr = finalstr + 'Digital Advertising,';
                    }
                    
                    finalstr = finalstr + 'null,' + objOnboarding.Opportunity__r.Contract_Signed_Date__c + ',' + 'null,';
                   finalstr = finalstr + objOnboarding.Website_URL__c + ',' + objOnboarding.GA_Account_Shared__c + ',' + objOnboarding.GTM_ID_provided__c + ',';
                    finalstr = finalstr + '"[Facebook Pixel]",8/21/2023,' + objOnboarding.GA4_Property_Name_from_this_sheet__c + ',';
                        finalstr = finalstr + objOnboarding.GA4_Measurement_ID__c + ',' + objOnboarding.Foundation_GA4_View__c + ',8/21/2023,';
                        finalstr = finalstr + '8/21/2023,8/21/2023,' + objOnboarding.BigQuery_is_linked_in_GA4__c + ',' + objOnboarding.Vistadash_Event_Owner_Custom_Dimension_C__c + ',';
                        finalstr = finalstr + objOnboarding.GA4_Notes__c + ',' + objOnboarding.Website_Provider__c + ',' + objOnboarding.Digital_Retail_Provider__c + ',';// + objOnboarding.Service_Scheduler__c + ',';
                    finalstr = finalstr + objOnboarding.Chat_Provider__c + ',' + objOnboarding.Chat_Start__c + ',' + objOnboarding.Click_to_Call__c + ',';// + objOnboarding.Contact_Us__c + ',';
                    finalstr = finalstr + objOnboarding.DR_Start__c + ',' + objOnboarding.Finance_Start__c + ',' + objOnboarding.Lead_Form__c + ',';// + objOnboarding.Print_Service_Coupon__c + ',';
                    //finalstr = finalstr + objOnboarding.Schedule_Service__c + ',' + objOnboarding.Text_Start__c	 + ',' + objOnboarding.Trade_In_Start__c + ',' + objOnboarding.Id + ',' + objOnboarding.Name + ',' + objOnboarding.Touchpoint_Master_ID__c + ',' +  contactDetails + ' \n';
                    finalstr = finalstr + objOnboarding.Id + ',' + objOnboarding.Name + ',' + objOnboarding.Touchpoint_Master_ID__c + ',' +  contactDetails + ' \n';
                }
                
            }
            
            
            String customLabelValue = System.Label.Onboarding_First_Sheet_Email;
            List<String> listEmails = new List<String>();
            
            If(customLabelValue.contains(','))
            {
                listEmails.addAll(customLabelValue.split(','));
            }
            Else
            {
                listEmails.add(customLabelValue);
            }
            
            String fullyFinalStr = finalstr.replace('null', '');
            system.debug('fullyFinalStr : ' + fullyFinalStr);
            
            Messaging.InboundEmail email = new Messaging.InboundEmail() ;
            Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
            
            // intialize the list string to store emails.
            List<string> emails = new List<string>{'testbandi@gmail.com','testbandi123@gmail.com'};
                
                email.subject = 'Create case';
            email.fromAddress = 'someaddress@email.com';
            
            //assigning the emails to toAddresses 
            email.toAddresses = emails;
            email.plainTextBody = 'email body';
            Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
            attachment.body = blob.valueOf(fullyFinalStr);
            attachment.fileName = 'ALL ACTIVE CUSTOMERS.csv';
            email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };
                
                Getting_Response_CSV_Record_Sheet2  testInbound = new Getting_Response_CSV_Record_Sheet2 ();
            testInbound.handleInboundEmail(email, env);
            
        }
    }
    
}