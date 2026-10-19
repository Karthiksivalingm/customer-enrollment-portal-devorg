/**
    @Name               :	EmailServiceToFindMatchingCase
    @Date               :   05 Jan, 2016
    @Description        :   Email service apex class to assign the emails to matching Case.
    						Using Apex classes that implement the Messaging.InboundEmailHandler interface to handle an inbound email message.
    @TestClass			:	TestEmailServiceToFindMatchingCase
*/
global with sharing class EmailServiceToFindMatchingCase implements Messaging.InboundEmailHandler {
	
	/*
		@Name           :   handleInboundEmail
		@Description    :   Using the handleInboundEmail method, you can access an InboundEmail object to retrieve the contents, headers, and attachments of inbound email messages, as well as perform many functions.
	*/
	global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
		
		// Create an InboundEmailResult object for returning the result of the Apex Email Service
		Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
		List<Case> lstMatchedCase = new List<Case>();
		
		//subject if it is present.
		if(email.subject != null) {
			
			//If ref id is present on email subject then find the matching case.
			lstMatchedCase = extractRefAndFindCase(email.subject);
			
			if(!lstMatchedCase.isEmpty()) 
				assignEmailToCase(email, lstMatchedCase[0]);
			
			//Get the case number from the subject if it is present.
			else {
				
				String caseNumber = extractCaseNoAndFindCase(email.subject);
				
				//If case number found on the subject then get the matching case.
				if(caseNumber != null) {
					
					Integer intCaseNumber = Integer.valueOf(caseNumber);
					//String caseNumberStr = '%' + String.valueOf(intCaseNumber);
	 
					lstMatchedCase = [ 	SELECT Id 
										FROM Case 
										WHERE Zendesk_ID__c = :intCaseNumber
										LIMIT 1
									];
		
					//If matching case is found then assign the email to this case
					if(!lstMatchedCase.isEmpty()) 
						assignEmailToCase(email, lstMatchedCase[0]);
					
					//If no matching case found and case no. is present then create a new case and send an error email.
					else {
							
						//Create new Case.
						Case objNewErrorCase = createNewCase(email);
						assignEmailToCase(email, objNewErrorCase);
						//Send error message to the user in custom setting.
						Messaging.SingleEmailMessage errorEmail = new Messaging.SingleEmailMessage();
						
						String userEmail =  [ 	SELECT Email 
												FROM User 
												WHERE Id = :Email_to_Case_Error_User__c.getInstance('User ID').User_ID_who_should_get_email__c 
											].Email;
						
						
						List<String> sendTo = new List<String>();
						sendTo.add(userEmail);
						errorEmail.setToAddresses(sendTo);
						errorEmail.setSubject('New error Case has been created');
						
						//Get the org instance url.
						String salesforceInstanceURL = System.URL.getSalesforceBaseURL().getHost();
						
						//Create email body.
						String body = 'An email was received with a legacy Zendesk ID but no matching record could be found. Due to this a new case has been created: ';
						body += '<br/><br/>';
						body += '<a href="https://'+salesforceInstanceURL+'/'+objNewErrorCase.Id+'">https://'+salesforceInstanceURL+'/'+objNewErrorCase.Id+'</a>';
						
						errorEmail.setHtmlBody(body);
						
						Messaging.sendEmail(new Messaging.SingleEmailMessage[] { errorEmail });
					}			
				//If case number is not found, then create a new Case and attach the email to it.
				} else {
					
					Case objNewCase = createNewCase(email);
					assignEmailToCase(email, objNewCase);
				}
			}
		} 
		
		return result;
	}
	
	/*
		@Name           :   extractRefAndFindCase
		@Description    :   Get the case id from the ref id of the email subject and find the matching case.
	*/
	private List<Case> extractRefAndFindCase(String emailSubject) {
		
		List<Case> lstMatchedCase = new List<Case>();
		
		if(emailSubject.contains('[ ref:') && emailSubject.contains(':ref ]')) {
		
			String caseId = emailSubject.substringAfter('[ ref:');
			caseId = caseId.substringBefore(':ref ]');
			Id matchId = Cases.getCaseIdFromEmailThreadId(caseId);
			
			lstMatchedCase = [	SELECT CaseNumber 
								FROM Case 
								WHERE Id = :matchId
							];
		}
		
		return lstMatchedCase;
	}
	
	/*
		@Name           :   extractCaseNoAndFindCase
		@Description    :   Get the case number from the email subject and find the matching case.
	*/
	private String extractCaseNoAndFindCase(String emailSubject) {
		
		List<Case> lstMatchedCase = new List<Case>();
		
		//Split the subject.
		List<String> lstSubStr = emailSubject.split(' ');
		
		//Get the last string in the subject.
		String caseNumber = lstSubStr[lstSubStr.size()-1];
		
		//If the last string is a number then consider it as the legacy case number.
		if(caseNumber.isNumeric())
			return caseNumber;
		else
			return null;
	}
	
	/*
		@Name           :   assignEmailToCase
		@Description    :   Assign the email to the given case.
	*/
	private void assignEmailToCase(Messaging.InboundEmail email, Case matchedCase) {
		
		String value;
		EmailMessage theEmail = new EmailMessage();
		theEmail.ParentId = matchedCase.Id;
		theEmail.Incoming = true;
		theEmail.Subject = limitLength(email.Subject, EmailMessage.Subject.getDescribe().getLength()); //3000
		theEmail.MessageDate = datetime.now();
		theEmail.HtmlBody = limitLength(email.htmlBody, EmailMessage.HtmlBody.getDescribe().getLength()); //32000
		theEmail.TextBody = limitLength(email.plainTextBody, EmailMessage.TextBody.getDescribe().getLength()); //32000
		
		/* To */
		value = '';
		 
		if(email.toAddresses != null) {
		  
			Boolean seenOne= false;
		  
			for(String to : email.toAddresses) {
			  	
				if(seenOne)
					value += ';\n';
			  
				value += to;
				seenOne = true;
			}	
		}
		 
		theEmail.ToAddress = limitLength(value, EmailMessage.ToAddress.getDescribe().getLength());
		
		/* From */
		theEmail.FromName = email.fromName;
		theEmail.FromAddress = email.fromAddress;
		
		/* CC */
		value = '';
		
		if(email.ccAddresses != null) {
			
			Boolean seenOne= false;
			
			for(String cc : email.ccAddresses) {
				
				if(seenOne)
					value += ';\n';
					
				value += cc;
				seenOne = true;
			}
		}
		
 		theEmail.CcAddress = limitLength(value,EmailMessage.CcAddress.getDescribe().getLength());
 		
 		insertSObject(theEmail);
 		
 		handleAttachments(email, theEmail, matchedCase);
	}
	
	/*
		@Name           :   handleAttachments
		@Description    :   Save attachments, if any on the email.
	*/
	private void handleAttachments(Messaging.InboundEmail email, EmailMessage newEmail, Case theCase) {
		
		//Text attachment.
		if(email.textAttachments != null && email.textAttachments.size() > 0) {
			
			for(Messaging.Inboundemail.TextAttachment tAttachment : email.textAttachments) {
				
				Attachment attachment = new Attachment();  
				attachment.Name = tAttachment.fileName;
				attachment.Body = Blob.valueOf(tAttachment.body);
				attachment.ParentId = newEmail.Id;
				insertSObject(attachment);
			}
		}
		
		//Binary attachment.
		if(email.binaryAttachments != null && email.binaryAttachments.size() > 0) {
			
			for(Messaging.Inboundemail.BinaryAttachment bAttachment : email.binaryAttachments) {
				
				Attachment attachment = new Attachment();
				attachment.Name = bAttachment.fileName;
				attachment.Body = bAttachment.body;
				attachment.ParentId = newEmail.Id;
				insertSObject(attachment);
			}
		} 
	}
	
	/*
		@Name           :   createNewCase
		@Description    :   create a case for the email if no matching case found.
	*/
	private Case createNewCase(Messaging.InboundEmail email) {
		
		Case objNewCase = new Case();
		objNewCase.SuppliedEmail = email.fromAddress;
		objNewCase.SuppliedName = email.fromName;
		objNewCase.Status = 'New';
		objNewCase.Priority = 'Medium';
		objNewCase.Origin = 'Email';
		objNewCase.Subject = email.Subject;
		objNewCase.Description = email.plainTextBody;
		objNewCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Customer Support').getRecordTypeId();
		
		List<Contact> lstContacts = [	SELECT AccountId 
										FROM Contact 
										WHERE Email =: email.fromAddress
									];
		
		//Fetching the assignment rules on case
		List<AssignmentRule> caseAR = new List<AssignmentRule>([SELECT Id FROM AssignmentRule WHERE SobjectType = 'Case' AND Active = true LIMIT 1]);
		
		if(!caseAR.isEmpty()) {
			
			//Creating the DMLOptions for "Assign using active assignment rules" checkbox
			Database.DMLOptions dmlOpts = new Database.DMLOptions();
			dmlOpts.assignmentRuleHeader.assignmentRuleId= caseAR[0].id;
			
			//Setting the DMLOption on Case instance
			objNewCase.setOptions(dmlOpts);
		}
		
		if(lstContacts.size() > 0) {
			
			objNewCase.ContactId = lstContacts[0].Id;
			
			if(lstContacts[0].AccountId != null)
				objNewCase.AccountId = lstContacts[0].AccountId;
			
			if(lstContacts.size() > 1)
    			objNewCase.Description = 'Note: There is more than one Contact with this email address.'+'\n'+objNewCase.Description;
		}
		
		insertSObject(objNewCase);
		
		return objNewCase;
	}
	
	/*
		@Name           :   limitLength
		@Description    :   limit the length of the email subject and body to the max length allowed.
	*/
	private String limitLength(String input, Integer maxLength) {
	 
		String results;
		
		if(input != null && input.length() > maxLength)
			results = input.substring(0,maxLength);
		else 
			results = input;
			
		return results;
	}
	
	/*
		@Name           :   insertSObject
		@Description    :   Insert the specified object.
	*/
	private void insertSObject(sObject obj) {
		
 		try {
 			insert obj;
 		} catch (System.DmlException e) {
 			system.debug(e.getMessage());
 		}
	}
}