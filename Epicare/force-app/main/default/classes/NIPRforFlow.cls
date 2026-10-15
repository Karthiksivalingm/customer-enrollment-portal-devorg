public class NIPRforFlow {

@InvocableMethod(label='Invoke Apex')
public static List<FlowOutputs> invokeThisMethod(List<FlowInputs> Inputs) {
    
FlowOutputs flows;
List<FlowOutputs> lstout = new List<FlowOutputs>();
FlowOutputs flowOut = new FlowOutputs();    
        String SsnFlowValue ;
        String lastNameFlowValue ;
        String FirstNameFlowValue;
        String recordIdFlowValue;
        String recordTypeFlowValue;
        Id ContactId;
        String emailFlowValue;
        String phoneFlowValue;
        String NpnValue;
        String residencyState;
        string company_name;
        string Npn;  
        string state_co_id;
        string domicile;
        string first_name;
        string last_name;
        string middle_name;
        date DOB;
        string ssn;
        string transactionType;
        String stateName;
        String branchID;
        Contact ConSSn;
        
        List < String > states = new List < String > ();
        List<loa_details> lstLoa = new List<loa_details>();
        List<loa__c> lstLoaInfo = new List<loa__c>();  
        List < Contact_infos > lstConInfo = new List < Contact_infos > ();
        List < Producer_Licensing > lstProLicense = new List < Producer_Licensing > ();
        List < DOI__c > lstDoi = new List < DOI__c > ();
        List < Address > lstAddress = new List < Address > ();
        List < biographic > lstBio = new List < biographic > ();
    
        String username = label.Nipr_username;
        String password = label.Nipr_password; 
        String AgentRecordType = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Agent').getRecordTypeId();
        String AgencyDirectorRecordType = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Agency Director').getRecordTypeId();
        String AgentDOIRecordType = Schema.SObjectType.DOI__c.getRecordTypeInfosByName().get('Agent License').getRecordTypeId();
 try {
        for(FlowInputs flowInput : Inputs){
            
            SsnFlowValue = flowInput.ssn;
            lastNameFlowValue = flowInput.Lastname;
            FirstNameFlowValue = flowInput.Firstname;
            recordIdFlowValue = flowInput.recordId;
            recordTypeFlowValue = flowInput.recordType;
            emailFlowValue = flowInput.email;
            phoneFlowValue = flowInput.phone;
        }
 }
     catch (Exception e) {
         
     }
        try {
            ConSSn = [Select id, NPN__c from Contact where SSN__c =: SsnFlowValue]; 
            }
        catch (system.QueryException e) {}
        if(ConSSn!=null){
        flowOut.Status = 400;
        flowOut.Message = 'SSN already exist in record ' + ConSSn.Id ;
        }
        if(ConSSn == Null){
            
        String lname = lastNameFlowValue.replace( ' ', '%20' );
        Http H1 = new Http();
        HttpRequest req1 = new HttpRequest();
        req1.setEndpoint(label.SSN_URL+lname+'&ssn='+SsnFlowValue);
        Blob headerValue = Blob.valueOf(username + ':' + password);
        String authorizationHeader = 'Basic ' +EncodingUtil.base64Encode(headerValue);
        system.debug(authorizationHeader);
        req1.setHeader('Authorization', authorizationHeader);
        req1.setMethod('GET');        
        HttpResponse res1=h1.send(req1);
        string response = res1.getbody();  
        system.debug(req1);
        system.debug(response);
            
        DOM.Document doc = res1.getBodyDocument();
        
        for(Dom.XmlNode fluxNode: doc.getRootElement().getChildElements()) {   
        string currentnodeSsn = fluxNode.getname();
        system.debug(currentnodeSsn);

        if(fluxNode.getName() == 'INDIVIDUAL') {
        
        NpnValue = fluxNode.getChildElement('NPN',null).getText();
        
        }
        if(currentnodeSsn == 'ERROR') {
        
        flowOut.Message= 'Looks like the SSN and Last Name combination is not valid. Please verify your information and try again';
        flowOut.status= 400;
            
        }
      }
   
         
   }
   /*   contact con1 = [select testclass__c from contact  limit 1];
            system.debug(con1.testclass__c);
            if(con1.testclass__c == 32){
                NpnValue='17524533';
            }*/
   if(NpnValue != null){
    system.debug(NpnValue);            
    Http H2 = new Http();
    HttpRequest req2 = new HttpRequest();
    req2.setEndpoint(label.NPN_URL+ NpnValue);
    Blob NPNheaderValue = Blob.valueOf(username + ':' + password);
    String NPNauthorizationHeader = 'Basic ' + EncodingUtil.base64Encode(NPNheaderValue);
    system.debug(NPNauthorizationHeader);
    req2.setHeader('Authorization', NPNauthorizationHeader);
    req2.setMethod('GET');

    HttpResponse res2 = h2.send(req2);
    string response2 = res2.getbody();
      system.debug(req2);
    system.debug(response2);
       
   /* Parsing the XML data*/    
       
    DOM.Document Npndoc = res2.getBodyDocument();

    for (Dom.XmlNode PdbNode: Npndoc.getRootElement().getChildElements()) {

      String CurrentNode = PdbNode.getName();
      if (CurrentNode == 'ERROR') {
          flowOut.Message = 'Looks like the SSN and Last Name combination is not valid. Please verify your information and try again';
          flowOut.Status = 400;
      }
      if (CurrentNode == 'TRANSACTION_TYPE') {

        for (Dom.XmlNode TypeNode: PdbNode.getChildElements()) {

          currentnode = TypeNode.getName();
         
          transactionType = PdbNode.getChildElement('TYPE', null).getText();
          
        }
      }
      if (CurrentNode == 'PRODUCER') {

        for (Dom.XmlNode ProducerNode: PdbNode.getChildElements()) {

          currentnode = ProducerNode.getname();
          //   if (currentnode == 'FIRM') 
          {

            for (Dom.XmlNode FirmNode: ProducerNode.getChildElements()) {

              currentnode = FirmNode.getname();
              if (currentnode == 'ENTITY_BIOGRAPHIC') {

                for (Dom.XmlNode EntityBioNode: FirmNode.getChildElements()) {

                  currentnode = EntityBioNode.getname();
                  
                  if (currentnode == 'BIOGRAPHIC') {

                    for (Dom.XmlNode BiographichNode: EntityBioNode.getChildElements()) {

                      currentNode = BiographichNode.getName();
                             
                      Biographic bio = new Biographic();

                      if (transactionType == 'INDIVIDUAL') {

                        if (EntityBioNode.getChildElement('ID_SSN', null).getText()!=null) {
                          bio.ssn_Id = EntityBioNode.getChildElement('ID_SSN', null).getText();
                            ssn = EntityBioNode.getChildElement('ID_SSN', null).getText();
                        }
                        if (EntityBioNode.getChildElement('NAME_LAST', null).getText()!=null) {
                          bio.last_name = EntityBioNode.getChildElement('NAME_LAST', null).getText();
                            last_name = EntityBioNode.getChildElement('NAME_LAST', null).getText();
                        }
                        if (EntityBioNode.getChildElement('NAME_FIRST', null).getText()!=null) {
                          bio.first_name = EntityBioNode.getChildElement('NAME_FIRST', null).getText();
                            first_name = EntityBioNode.getChildElement('NAME_FIRST', null).getText();
                        }
                        if (EntityBioNode.getChildElement('NAME_MIDDLE', null).getText()!=null) {
                          bio.middle_name = EntityBioNode.getChildElement('NAME_MIDDLE', null).getText();
                            middle_name = EntityBioNode.getChildElement('NAME_MIDDLE', null).getText();
                        }
                        if (EntityBioNode.getChildElement('DATE_BIRTH', null).getText()!=null) {
                                                    bio.dob = convertdate(EntityBioNode.getChildElement('DATE_BIRTH', null).getText());
                                                    dob = convertdate(EntityBioNode.getChildElement('DATE_BIRTH', null).getText());
                                                }
                        if (EntityBioNode.getChildElement('NPN', null).getText()!=null) {
                          bio.npn = EntityBioNode.getChildElement('NPN', null).getText();
                            Npn = EntityBioNode.getChildElement('NPN', null).getText();
                        }
                      }
                      if (lstBio.isEmpty() && bio != null) {
                        lstBio.add(bio);
                      }

                      currentnode = BiographichNode.getname();

                      if (currentnode == 'OTHER_NAME') {

                        for (Dom.XmlNode OtherNameNode: BiographichNode.getChildElements()) {

                          Biographic biograph = new Biographic();

                          currentnode = OtherNameNode.getName();
                          
                          stateName = OtherNameNode.getAttribute('name', null);
                          branchId =  OtherNameNode.getAttribute('branch_id', null); 
                            
                          if (biograph.state_domicile != null) {
                            lstBio.add(biograph);
                          }
                        }
                      }
                    }
                  }

                  if (currentnode == 'CONTACT_INFOS') {
                    
                    for (Dom.XmlNode ConInfosNode: EntityBioNode.getChildElements()) {

                      Contact_Infos info = new Contact_Infos();

                      stateName = ConInfosNode.getAttribute('name', null);

                      Info.State = stateName;

                      currentnode = ConInfosNode.getname();
                      if (stateName != null) {
                        if (currentnode == 'STATE') {
                          
                          for (Dom.XmlNode StateNode: ConInfosNode.getChildElements()) {
                            currentnode = StateNode.getname();
                            
                            if (currentnode == 'CONTACT_INFO') {

                              branchID = StateNode.getAttribute('branch_id', null);
                             
                              for (Dom.XmlNode contactInfoNode: StateNode.getChildElements()) {

                                currentNode = contactInfoNode.getname();
                               
                                Info.branch_id = branchId;

                                if (currentNode == 'BUSINESS_PHONE') {
                                  String BUSINESS_PHONE = StateNode.getChildElement('BUSINESS_PHONE', null).getText();
                                  Info.Business_phone = BUSINESS_PHONE;
                                }
                                if (currentNode == 'BUSINESS_EMAIL') {
                                  Info.Business_email = StateNode.getChildElement('BUSINESS_EMAIL', null).getText();
                                }
                                lstConInfo.add(Info);

                              }
                            }
                          }
                        }
                      }
                    }
                  }
                  if (currentnode == 'ADDRESSES') {
                    
                    for (Dom.XmlNode AddressesNode: EntityBioNode.getChildElements()) {
                      Address addres = new Address();
                      stateName = AddressesNode.getAttribute('name', null);
                      
                      if (stateName != null) {
                        currentnode = AddressesNode.getname();

                        if (currentnode == 'STATE') {
                         
                          for (Dom.XmlNode AddressStateNode: AddressesNode.getChildElements()) {
                            currentnode = AddressStateNode.getname();
                            
                            if (currentnode == 'ADDRESS') {
                              
                              branchID = AddressStateNode.getAttribute('branch_id', null);
                              
                              for (Dom.XmlNode AddressNode: AddressStateNode.getChildElements()) {

                                currentNode = AddressNode.getName();
                                
                                addres.branchId = branchID;

                                if (AddressStateNode.getChildElement('ADDR_TYPE', null).getText() == 'Business') {

                                  addres.State = stateName;
                                  if (currentNode == 'DATE_UPDATED') {
                                      try{
                                                                            addres.dateUpdated = convertdate(AddressStateNode.getChildElement('DATE_UPDATED', null).getText());
                                                                        }
                                      catch(Exception e)
                                                                {
                                                                    
                                                                }
                                                                    }
                                  if (currentNode == 'ADDR_TYPE') {
                                    addres.addressType = AddressStateNode.getChildElement('ADDR_TYPE', null).getText();
                                  }
                                  if (currentNode == 'ADDR_LINE_1') {
                                    addres.line1 = AddressStateNode.getChildElement('ADDR_LINE_1', null).getText();
                                  }
                                  if (currentNode == 'ADDR_LINE_2') {
                                    addres.line2 = AddressStateNode.getChildElement('ADDR_LINE_2', null).getText();
                                  }
                                  if (currentNode == 'ADDR_LINE_3') {
                                    addres.line3 = AddressStateNode.getChildElement('ADDR_LINE_3', null).getText();
                                  }
                                  if (currentNode == 'NAME_CITY') {
                                    addres.addressCity = AddressStateNode.getChildElement('NAME_CITY', null).getText();
                                  }
                                  if (currentNode == 'NAME_STATE') {
                                    addres.addressState = AddressStateNode.getChildElement('NAME_STATE', null).getText();
                                  }
                                  if (currentNode == 'COUNTRY') {
                                    addres.addressCountry = AddressStateNode.getChildElement('COUNTRY', null).getText();
                                  }
                                  if (currentNode == 'ZIP') {
                                    addres.addressZip = AddressStateNode.getChildElement('ZIP', null).getText();
                                  }
                                }

                                if (AddressStateNode.getChildElement('ADDR_TYPE', null).getText() == 'Mailing') {

                                  addres.State = stateName;
                                  if (currentNode == 'DATE_UPDATED') {
                                    
                                       try{
                                                                            addres.maildateUpdated = convertdate(AddressStateNode.getChildElement('DATE_UPDATED', null).getText());
                                                                       }
                                      catch(Exception e)
                                                                {
                                                                    
                                                                }
                                  }
                                  if (currentNode == 'ADDR_TYPE') {
                                    addres.mailaddressType = AddressStateNode.getChildElement('ADDR_TYPE', null).getText();
                                  }
                                  if (currentNode == 'ADDR_LINE_1') {
                                    addres.mailline1 = AddressStateNode.getChildElement('ADDR_LINE_1', null).getText();
                                  }
                                  if (currentNode == 'ADDR_LINE_2') {
                                    addres.mailline2 = AddressStateNode.getChildElement('ADDR_LINE_2', null).getText();
                                  }
                                  if (currentNode == 'ADDR_LINE_3') {
                                    addres.mailline3 = AddressStateNode.getChildElement('ADDR_LINE_3', null).getText();
                                  }
                                  if (currentNode == 'NAME_CITY') {
                                    addres.mailaddressCity = AddressStateNode.getChildElement('NAME_CITY', null).getText();
                                  }
                                  if (currentNode == 'NAME_STATE') {
                                    addres.mailaddressState = AddressStateNode.getChildElement('NAME_STATE', null).getText();
                                  }
                                  if (currentNode == 'COUNTRY') {
                                    addres.mailaddressCountry = AddressStateNode.getChildElement('COUNTRY', null).getText();
                                  }
                                  if (currentNode == 'ZIP') {
                                    addres.mailaddressZip = AddressStateNode.getChildElement('ZIP', null).getText();
                                  }
                                }
                                if (AddressStateNode.getChildElement('ADDR_TYPE', null).getText() == 'Residence') {

                                  addres.State = stateName;
                                  if (currentNode == 'DATE_UPDATED') {
                              try{
                                    addres.residentdateUpdated = convertdate(AddressStateNode.getChildElement('DATE_UPDATED', null).getText());
                                  }
                                      catch(Exception e)
                                                                {
                                                                    
                                                                }
                                  }
                                  if (currentNode == 'ADDR_TYPE') {
                                    addres.residentaddressType = AddressStateNode.getChildElement('ADDR_TYPE', null).getText();
                                  }
                                  if (currentNode == 'ADDR_LINE_1') {
                                    addres.residentline1 = AddressStateNode.getChildElement('ADDR_LINE_1', null).getText();
                                  }
                                  if (currentNode == 'ADDR_LINE_2') {
                                    addres.residentline2 = AddressStateNode.getChildElement('ADDR_LINE_2', null).getText();
                                  }
                                  if (currentNode == 'ADDR_LINE_3') {
                                    addres.residentline3 = AddressStateNode.getChildElement('ADDR_LINE_3', null).getText();
                                  }
                                  if (currentNode == 'NAME_CITY') {
                                    addres.residentaddressCity = AddressStateNode.getChildElement('NAME_CITY', null).getText();
                                  }
                                  if (currentNode == 'NAME_STATE') {
                                    addres.residentaddressState = AddressStateNode.getChildElement('NAME_STATE', null).getText();
                                  }
                                  if (currentNode == 'COUNTRY') {
                                    addres.residentaddressCountry = AddressStateNode.getChildElement('COUNTRY', null).getText();
                                  }
                                  if (currentNode == 'ZIP') {
                                    addres.residentaddressZip = AddressStateNode.getChildElement('ZIP', null).getText();
                                  }
                                }
                              }
                            }
                          }
                        }
                      }
                      lstAddress.add(addres);
                    }
                  }
                }
              }

              if (currentnode == 'PRODUCER_LICENSING') {    

                for (Dom.XmlNode ProducerLicenseNode: FirmNode.getChildElements()) {

                  currentnode = ProducerLicenseNode.getName();

                  if (currentnode == 'LICENSE_INFORMATION') {
                    
                    for (Dom.XmlNode LicenseInfoNode: ProducerLicenseNode.getChildElements()) {

                      stateName = LicenseInfoNode.getAttribute('name', null);

                      //      if(stateName!=null)
                      {

                        states.add(statename);

                        for (Dom.XmlNode StateNode: LicenseInfoNode.getChildElements()) {

                          currentNode = StateNode.getName();
                          
                          if (currentNode == 'LICENSE') {

                            branchID = StateNode.getAttribute('branch_id', null);
                            
                            Producer_Licensing proLicense = new Producer_Licensing();
                              
                            for (Dom.XmlNode LicenseNode: StateNode.getChildElements()) {
                                
                              currentNode = LicenseNode.getName();
                                
                                 proLicense.branchId = branchID;
                                 proLicense.state = stateName;
                                
                              if (currentNode == 'LICENSE_NUM') {
                                proLicense.license_number = LicenseNode.getText();
                              }
                              if (currentNode == 'DATE_ISSUE_LICENSE_ORIG') {
                                   try{
                                proLicense.DATE_ISSUE_LICENSE_ORIG = convertdate(LicenseNode.getText());
                                       }
                                      catch(Exception e)
                                                                {
                                                                    
                                                                }
                              }
                              if (currentNode == 'DATE_EXPIRE_LICENSE') {
                                   try{
                                proLicense.license_expiration_date = convertdate(LicenseNode.getText());
                                       }
                                      catch(Exception e)
                                                                {
                                                                    
                                                                }
                              }
                              if (currentNode == 'DATE_UPDATED') {
                                   try{
                                proLicense.LicenseDateUpdated = convertdate(LicenseNode.getText());
                                       }
                                      catch(Exception e)
                                                                {
                                                                    
                                                                }
                              }
                              if (currentNode == 'RESIDENCY_STATUS') {
                                ProLicense.residency_status = LicenseNode.getText();
                              }
                              if (currentNode == 'ACTIVE') {
                                ProLicense.Active = LicenseNode.getText();
                              }
                              if (currentNode == 'LICENSE_CLASS') {
                                ProLicense.License_class = LicenseNode.getText();
                              }
                              if (currentNode == 'LICENSE_CLASS_CODE') {
                                ProLicense.License_class_code =LicenseNode.getText();
                              }  
    
                            }
                               lstProLicense.add(proLicense);    
                          }    
                            
                        }
                          
                   for (Dom.XmlNode StateNode2: LicenseInfoNode.getChildElements()) {
                       
                       currentNode = StateNode2.getName();
                       
                                   if (currentNode == 'LICENSE') {
 
                                for (Dom.XmlNode LicenseNode: StateNode2.getChildElements()) {
                           
                                  currentNode = LicenseNode.getName();  
                                    
                                     if(currentNode == 'DETAILS'){
                                    
                                    for(Dom.XmlNode DetailsNode: LicenseNode.getChildElements()){
                                        
                                         loa_details loaDetail = new loa_details();
                                         try{
                                         loaDetail.licenseIssueDate = convertdate(StateNode2.getChildElement('DATE_ISSUE_LICENSE_ORIG', null).getText());
                                         }
                                      catch(Exception e)
                                                                {
                                                                    
                                                                }
                                        loaDetail.state = statename;
                                         loaDetail.license_number = StateNode2.getChildElement('LICENSE_NUM', null).getText();
                                         loaDetail.license_class_code = StateNode2.getChildElement('LICENSE_CLASS_CODE', null).getText();
                                        
                                        CurrentNode = DetailsNode.getName();
                                      
                                        if(currentNode == 'DETAIL'){
                                            
                                            for(Dom.XmlNode DetailNode: DetailsNode.getChildElements()){
                                                 
                                                CurrentNode = DetailNode.getName();
                                                
                                                if(currentNode == 'LOA'){
                                                   
                                                  loaDetail.Loa =   DetailNode.getText();
   
                                                }
                                                if(currentNode == 'LOA_CODE'){
                                                   
                                                    loaDetail.Loa_code =   DetailNode.getText();
   
                                                }
                                                if(currentNode == 'AUTHORITY_ISSUE_DATE'){
                                                    try{
                                                    loaDetail.Authority_issue_date =   convertdate(DetailNode.getText());
   }
                                      catch(Exception e)
                                                                {
                                                                    
                                                                }
                                                }
                                                if(currentNode == 'STATUS'){
                                                   
                                                    loaDetail.status =   DetailNode.getText();
   
                                                }
                                                if(currentNode == 'STATUS_REASON'){
                                                   
                                                    loaDetail.status_reason =   DetailNode.getText();
   
                                                }
                                                if(currentNode == 'STATUS_REASON_DATE'){
                                                    try{
                                                    loaDetail.status_reasonDate =   convertdate(DetailNode.getText());
   }
                                      catch(Exception e)
                                                                {
                                                                    
                                                                }
                                                }
                                                if(currentNode == 'CE_COMPLIANCE'){
                                                   
                                                    loaDetail.CE_compliance =   DetailNode.getText();
   
                                                }
                                                if(currentNode == 'CE_RENEWAL_DATE'){
                                                    try{
                                                    loaDetail.CE_renewaldate =   convertdate(DetailNode.getText());
                                                    }
   catch(Exception e)
                                                                {
                                                                    
                                                                }
                                                }
                                                if(currentNode == 'CE_CREDITS_NEEDED'){
                                                   
                                                    loaDetail.CE_creditsNeeded =   DetailNode.getText();
   
                                                }    
                                         }   
                                             
                                     }
                                         lstLoa.add(loaDetail);
                                }      
                              }    
                            }   
                          }
                        }
                      }  
                    }
                  }
                }
              }
            }
          }
        }
      }
    } 
 }
       //End of Parsing
       
       Contact contact2Add = new Contact();
          System.debug(transactionType);
          System.debug(last_name);
    System.debug(NpnValue);
     //System.debug(recordTypeFlowValue);
    if((transactionType == 'INDIVIDUAL' && last_name !=null && NpnValue !=null) || (transactionType == 'INDIVIDUAL' && last_name !=null && NpnValue !=null)){
          
           if(recordIdFlowValue != null && recordIdFlowValue != ''){
            contact2Add.AccountId = recordIdFlowValue;   
            } 
          contact2Add.lastname = last_name;
          contact2Add.firstname = first_name;
          contact2Add.middlename = middle_name;
          contact2Add.NPN__c = Npn;
          contact2Add.SSN__c = SsnFlowValue;
          contact2Add.email =  emailFlowValue;
          contact2Add.phone =  phoneFlowValue;
          contact2Add.NIPR_LastUpdated_Date__c = date.today();
           if(recordTypeFlowValue =='Agency Director'){
           contact2Add.recordTypeId =  AgencyDirectorRecordType;
        }
        if(recordTypeFlowValue =='Agent'){
           contact2Add.recordTypeId =  AgentRecordType;
        }
          if(contact2Add.email == null){
              for(Contact_infos ci : lstConInfo){
                  if(ci.business_email != null){
                      contact2Add.email = ci.business_email;
                      break;
                  }
              }
          }
          contact2Add.Bypass_VR__c = true;
          
          if(contact2Add!=null){
          TriggerHandler.isFirstTime = False;
              try{
          Insert contact2Add;
                  flowout.ContactId = contact2Add.Id;
              }catch(System.DmlException e){
                 flowOut.Message = e.getMessage() ;
                 flowOut.Status = 400; 
              }
          }
      }
       if(contact2Add.Id !=null ){     
       for (Producer_Licensing purch: lstProLicense) {
    
          DOI__c DoiInfo = new DOI__c();
           
          DoiInfo.Contact__c = contact2Add.Id;
          DoiInfo.RecordTypeId = AgentDOIRecordType;    

          DoiInfo.state__c = purch.state;
          DoiInfo.name__c = purch.license_number +'- '+ purch.License_class+'_'+purch.License_class_code+'_'+ purch.state;
           
          if(purch.DATE_ISSUE_LICENSE_ORIG!=null && purch.DATE_ISSUE_LICENSE_ORIG!=null && purch.DATE_ISSUE_LICENSE_ORIG!=null){
          DoiInfo.name__c = purch.license_number +'- '+ purch.License_class+'_'+purch.License_class_code+'_'+ purch.state +' '+purch.DATE_ISSUE_LICENSE_ORIG;
          }
           
          DoiInfo.name = purch.license_number;
            
          if (purch.branchID != null) {
            DoiInfo.branch_Id__c = purch.branchID;
          }
          if (purch.license_number != null) {
            DoiInfo.License_Number__c = purch.license_number;
          }
          if (purch.License_class != null) {
            DoiInfo.LICENSE_CLASS__c = purch.License_class;
          }
          if (purch.License_class_code != null) {
            DoiInfo.License_Calss_Code__c = purch.License_class_code;
          }
          if (purch.license_expiration_date != null) {
            DoiInfo.License_ExpireDate__c = purch.license_expiration_date;
          }
          if (purch.DATE_ISSUE_LICENSE_ORIG != null) {
            DoiInfo.License_Orig_IssuseDate__c = purch.DATE_ISSUE_LICENSE_ORIG;
          }
          if (purch.LicenseDateUpdated != null) {
            DoiInfo.License_Updatedate__c = purch.LicenseDateUpdated;
          }
          if (purch.residency_status != null) {
            DoiInfo.ResidencyStatus__c = purch.residency_status;
          }

          if (purch.Active != null) {

            if (purch.Active == 'Yes') {
              DoiInfo.ACTIVE__c = True;
            } else {
              DoiInfo.ACTIVE__c = False;
            }
          }
    
          lstDoi.add(DoiInfo);
    }
      for (DOI__c DoiInfo: lstDoi) {
      for (Address add: lstAddress) {
        if (add.State == DoiInfo.State__c) {

          if (add.addressType == 'Business') {
            
            if (add.dateUpdated != null) {
              DoiInfo.Business_UpdatedDate__c = add.dateUpdated;
            }
            if (add.line1 != null) {
              DoiInfo.Business_Street_1__c = add.line1;
            }
            if (add.line2 != null) {
              DoiInfo.Business_Street_2__c = add.line2;
            }
            if (add.line3 != null) {
              DoiInfo.Business_Street_3__c = add.line3;
            }
            if (add.addressCity != null) {
              DoiInfo.Business_City__c = add.addressCity;
            }
            if (add.addressState != null) {
              DoiInfo.Business_State__c = add.addressState;
            }
            if (add.addressCountry != null) {
              DoiInfo.Business_Country__c = add.addressCountry;
            }
            if (add.addressZip != null) {
              DoiInfo.Business_Zip_PostalCode__c = add.addressZip;
            }
          }
          if (add.mailaddressType == 'Mailing') {
            
            if (add.maildateUpdated != null) {
              DoiInfo.Mailling_Updatedate__c = add.maildateUpdated;
                if(add.state == residencyState){
                
                }
            }
            if (add.mailline1 != null) {
              DoiInfo.Mailing_Street_1__c = add.mailline1;
            }
            if (add.mailline2 != null) {
              DoiInfo.Mailing_Street_2__c = add.mailline2;
            }
            if (add.mailline3 != null) {
              DoiInfo.Mailing_Street_3__c = add.mailline3;
            }
            if (add.mailaddressCity != null) {
              DoiInfo.Mailing_City__c = add.mailaddressCity;
            }
            if (add.mailaddressState != null) {
              DoiInfo.Mailing_State__c = add.mailaddressState;
            }
            if (add.mailaddressCountry != null) {
              DoiInfo.Mailing_Country__c = add.mailaddressCountry;
            }
            if (add.mailaddressZip != null) {
              DoiInfo.Mailing_Zip_PostalCode__c = add.mailaddressZip;
            }

          }
          if (add.residentaddressType == 'Residence') {
           
            if (add.residentdateUpdated != null) {
              DoiInfo.Residential_UpdatedDate__c = add.residentdateUpdated;
            }
            if (add.residentline1 != null) {
              DoiInfo.Residential_Street_1__c = add.residentline1;
            }
            if (add.residentline2 != null) {
              DoiInfo.Residential_Street_2__c = add.residentline2;
            }
            if (add.residentline3 != null) {
              DoiInfo.Residential_Street_3__c = add.residentline3;
            }
            if (add.residentaddressCity != null) {
              DoiInfo.Residential_City__c = add.residentaddressCity;
            }
            if (add.residentaddressState != null) {
              DoiInfo.Residential_State__c = add.residentaddressState;
            }
            if (add.residentaddressCountry != null) {
              DoiInfo.Residential_Country__c = add.residentaddressCountry;
            }
            if (add.residentaddressZip != null) {
              DoiInfo.Residential_Zip_PostalCode__c = add.residentaddressZip;
            }
          }
        }
      }
    }
    for (DOI__c doiInfo: lstDoi) {
      for (Contact_infos con: lstConInfo) {

        if (doiInfo.state__c == con.state) {
          
          if (con.business_email != null) {
            DoiInfo.BusinessEmail__c = con.business_email;
          }
          if (con.business_phone != null) {
            DoiInfo.BusinessPhone__c = con.business_phone;
          }
        }
      }
    }
    for (DOI__c Doi: lstDOI) {
      for (Biographic bio: lstBio) {
        if (transactionType == 'INDIVIDUAL') {

          DOI.Lastname__c = bio.last_name;
          DOI.Firstname__c = bio.first_name;
          DOI.Middlename__c = bio.middle_name;
          DOI.dob__c = bio.dob;
          DOI.NPN_Number__c = bio.npn;
          DOI.SSN__c = bio.ssn_Id;

        }
      }
    }
    system.debug((lstDOI));
    system.debug(lstBio);
    system.debug(lstAddress.size());  
    System.debug((lstLoa).size());  
    system.debug((lstProLicense).size());

      if (lstDOI != null) {
        TriggerHandler.isFirstTime = False;
          try{
        Map<String, DOI__c> uniqueMap = new Map<String, DOI__c>();
		for(DOI__c rec : lstDOI){
    	if(!uniqueMap.containsKey(rec.Name__c)){
        uniqueMap.put(rec.Name__c, rec);
    	}
		}
		List<DOI__c> uniqueDOIList = new List<DOI__c>(uniqueMap.values());
        insert uniqueDOIList;
          }catch(system.DmlException e){
            flowOut.Message = e.getMessage() ;
                 flowOut.Status = 400;   
          }
    
    }
      for(DOI__c doiDetail : lstDOI){
          for(loa_Details loa : lstLoa){ 
              if(doiDetail.State__c == loa.state && doiDetail.License_Orig_IssuseDate__c == loa.licenseIssueDate && doiDetail.License_Number__c == loa.License_number && doiDetail.License_Calss_Code__c == loa.license_class_code && doiDetail.id!=null)
              {
                  
                  Loa__c loaInfo = new Loa__c();
                  
                  loaInfo.DOI__c = doiDetail.id;
                  loaInfo.State__c = loa.state;
                  loaInfo.LOA_Code__c = loa.Loa_code;
                  loaInfo.Name = loa.Loa;
                  loaInfo.Authority_IssueDatenew__c = loa.Authority_issue_date;
                  loaInfo.Status__c = loa.status;
                  loaInfo.License_Number__c = loa.License_number;
                  loaInfo.License_class_code__c = loa.license_class_code;
                  loaInfo.Status_Reason__c = loa.status_reason;
                  loaInfo.Status_ReasonDatenew__c = loa.status_reasonDate;
                  loaInfo.CE_Compliance__c = loa.CE_compliance;
                  loaInfo.CE_RenewalDate__c = loa.CE_renewaldate;
                  loaInfo.CE_Credits_Needed__c = loa.CE_creditsNeeded;   
                  
                  lstLoaInfo.add(loaInfo);
              }  
          }    
      }
                
      if(lstLoaInfo!=null){
          system.debug(lstLoaInfo.size());
          Insert lstLoaInfo;  
          } 
        }
      
    
    for(DOI__c DOI : lstDOI){
         system.debug(DOI.Id);
        if(DOI.ResidencyStatus__c == 'R' &&  DOI.Id != null){
           
            flowOut.DOIId = DOI.Id;
            flowOut.MailingStreet1 = DOI.Mailing_Street_1__c;
            flowOut.MailingStreet2 = DOI.Mailing_Street_2__c;
            flowOut.MailingStreet3 = DOI.Mailing_Street_3__c;
            flowOut.Mailingcity = DOI.Mailing_city__c;
            flowOut.MailingCountry = DOI.Mailing_country__c;
            flowOut.MailingState = DOI.Mailing_State__c;
            flowOut.MailingPostalcode = DOI.Mailing_Zip_PostalCode__c;
            flowOut.Status = 200;
        } 
        
    }
    Contact con;
    if(transactionType != 'INDIVIDUAL' && NpnValue == null && recordTypeFlowValue == 'Agency Director' && conSSn==null){
        con = new Contact();
        
        con.Lastname = lastNameFlowValue;
        con.FirstName = firstnameFlowValue;
        con.ssn__c = SsnFlowValue;
        con.email = emailFlowValue;
        con.phone = phoneFlowValue;
        if(recordTypeFlowValue =='Agency Director'){
           con.recordTypeId =  AgencyDirectorRecordType;
        }
        if(recordIdFlowValue != null && recordIdFlowValue != ''){
        con.AccountId = recordIdFlowValue;
        }
        con.Bypass_VR__c = true;
        try{
            Insert Con;
            flowout.ContactId = con.Id;
            flowOut.Status = 201;
        }Catch(System.DmlException e){
            
           flowOut.Message = e.getMessage();
           flowOut.Status = 400; 
            
        }
        
    }
    if(flowOut.Status !=400){
        if(flowOut.Status == 200){ 
       flowOut.Message = 'SSN and NPN found';
       flowOut.Status = 200; 
        }
        if(flowOut.Status == 201){ 
       flowOut.Message = 'Contact has been created but '+flowOut.Message;
       flowOut.Status = 201; 
        }
    }
    lstOut.add(flowOut);
    System.debug(lstout);
    return lstout;
    
}        
    public static date convertdate(String dateofit) {
        String apiDate = dateofit;
        Integer month,day,year;       
        if (String.isNotBlank(apiDate)) {
            List<String> parts = apiDate.split('/');
            month = Integer.valueOf(parts[0]);
            day   = Integer.valueOf(parts[1]);
            year  = Integer.valueOf(parts[2]);    
        }
        return Date.newInstance(year, month, day);
        
    }
public class FlowInputs{
        @InvocableVariable public string ssn;
        @InvocableVariable public string Firstname;
        @InvocableVariable public string email;
        @InvocableVariable public string phone;
        @InvocableVariable public string Lastname;
        @InvocableVariable public string recordId;
        @InvocableVariable public string recordType;
    }
    public class FlowOutputs{
        @InvocableVariable public String Message;
        @InvocableVariable public String MailingStreet1;
        @InvocableVariable public String MailingStreet2;
        @InvocableVariable public String MailingStreet3;
        @InvocableVariable public String MailingState;
        @InvocableVariable public String MailingCountry;
        @InvocableVariable public String MailingCity;
        @InvocableVariable public String MailingPostalCode;
        @InvocableVariable public id Doiid;
        @InvocableVariable public id ContactId;
        @InvocableVariable public Integer Status;
    }    
    public class Contact_infos {
    public String State;
    public String branch_id;
    public String business_phone;
    public string business_email;
  }
  public class Producer_Licensing {

    public string state;
    public string branchId;
    public string license_number;
    public date DATE_ISSUE_LICENSE_ORIG;
    public date license_expiration_date;
    public string residency_status;
    public date LicenseDateUpdated;
    public string Active;
    public string License_class;
    public string License_class_code;
    
  }
    public class loa_details{
    
    public string license_class_code;    
    public string license_number; 
    public string state;    
    public string Loa;
    public date licenseIssueDate;    
    public string Loa_code;
    public date Authority_issue_date;
    public string status;
    public string status_reason;
    public date status_reasonDate;
    public string CE_compliance;
    public date CE_renewaldate;
    public string CE_creditsNeeded;
        
    }

  public class biographic {
      
    public string branchId;
    public string company_name;
    public string state_co_id;
    public string state_domicile;
    public string ssn_Id;
    public string last_name;
    public string first_name;
    public string middle_name;
    public date dob;
    public string npn;

  }

  public class address {

    public string state;
    public string branchId;
    public date dateUpdated;
    public string addressType;
    public string line1;
    public string line2;
    public string line3;
    public string addressCity;
    public string addressState;
    public string addressCountry;
    public string addressZip;
    public date maildateUpdated;
    public string mailaddressType;
    public string mailline1;
    public string mailline2;
    public string mailline3;
    public string mailaddressCity;
    public string mailaddressState;
    public string mailaddressCountry;
    public string mailaddressZip;
    public date residentdateUpdated;
    public string residentaddressType;
    public string residentline1;
    public string residentline2;
    public string residentline3;
    public string residentaddressCity;
    public string residentaddressState;
    public string residentaddressCountry;
    public string residentaddressZip;
  }
}