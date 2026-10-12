//DEPRECATED
public class ShopifyIntegrationService {
/*    
    private static final String ENDPOINT = 'https://sellgoodr-test-store.myshopify.com/admin/api/2023-10/graphql.json';
    private static final String ACCESS_TOKEN = getAccessToken();
    private static String newCustomerId;
    private static String newCompanyId;*/
    
    @InvocableMethod(label='Send Contact to Shopify')
    public static void sendContactToShopify(List<Id> contactId) {
         /*Contact selectedContact = [
            SELECT Id, FirstName, LastName, Email, Phone, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, 
             	   Account.Name, Account.ShippingStreet, Account.ShippingCity, Account.ShippingState, 
             	   Account.ShippingPostalCode, Account.ShippingCountry, HIC_ShopifySync__Shopify_Id__c, AccountId
            FROM Contact 
            WHERE Id = :contactId.get(0) 
            LIMIT 1
        ];
        Account selectedAccount = [SELECT Id, Shopify_Company_Id__c, HIC_ShopifySync__Shopify_Id__c 
                                   FROM Account WHERE Id = :selectedContact.AccountId LIMIT 1];

        String companyName = selectedContact.Account.Name;
    	String companyId = getShopifyCompanyIdByName(companyName);
        
        if (companyId == null) {
            createCompanyOnShopify(
            	companyName,
                selectedContact.FirstName,
                selectedContact.LastName,
                selectedContact.Email,
                selectedContact.Account.ShippingStreet,
                selectedContact.Account.ShippingCity,
                selectedContact.Account.ShippingState,
                selectedContact.Account.ShippingPostalCode,
                selectedContact.Account.ShippingCountry
            );
        } else {
            createCompanyContact(companyId, selectedContact.FirstName, selectedContact.LastName, selectedContact.Email);
        }
        if (newCustomerId != null) {
            selectedContact.Shopify_Customer_Id__c = newCustomerId;
            selectedContact.HIC_ShopifySync__Shopify_Id__c = newCustomerId;
            update selectedContact;
        }
        if (newCompanyId != null) {
            selectedAccount.Shopify_Company_Id__c = newCompanyId;
            selectedAccount.HIC_ShopifySync__Shopify_Id__c = newCompanyId;
            update selectedAccount;
        }*/
    }
    
    /*public static void createCompanyOnShopify(
        String companyName, String contactFirstName, String contactLastName, String contactEmail,
        String street, String city, String state, String zip, String country
    ) {
        
        String query = 'mutation CompanyCreate($input: CompanyCreateInput!) {' +
                       '  companyCreate(input: $input) {' +
                       '    company {' +
                       '      id' +
                       '      name' +
                       '      mainContact {' +
                       '        id' +
                       '        customer {' +
                       '          id' +
                       '          email' +
                       '        }' +
                       '      }' +
                       '    }' +
                       '    userErrors {' +
                       '      field' +
                       '      message' +
                       '      code' +
                       '    }' +
                       '  }' +
                       '}';
    
        Map<String, Object> variables = new Map<String, Object>{
            'input' => new Map<String, Object>{
                'company' => new Map<String, Object>{
                    'name' => companyName
                },
                'companyLocation' => new Map<String, Object>{
                    'name' => companyName + ' Location',
                    'shippingAddress' => new Map<String, Object>{
                        'firstName' => contactFirstName != null ? contactFirstName : '',
                        'lastName' => contactLastName != null ? contactLastName : '',
                        'address1' => street != null ? street : '',
                        'city' => city != null ? city : '',
                        'zoneCode' => state != null ? StateToStateCodeHelper.getStateCode(state) : '',//must be CODE not fullName
                        'zip' => zip != null ? zip : '',
                        'countryCode' => country != null ? country : 'US' //must be CODE not fullName
                    },
                    'billingSameAsShipping' => true
                },
                'companyContact' => new Map<String, Object>{
                    'firstName' => contactFirstName != null ? contactFirstName : '',
                    'lastName' => contactLastName != null ? contactLastName : '',
                    'email' => contactEmail != null ? contactEmail : ''
                }
            }
        };
    
        Map<String, Object> payload = new Map<String, Object>{
            'query' => query,
            'variables' => variables
        };
    
        HttpRequest req = new HttpRequest();
        req.setEndpoint(ENDPOINT);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('X-Shopify-Access-Token', ACCESS_TOKEN);
        req.setBody(JSON.serialize(payload));
        
        Http http = new Http();
        HttpResponse res;
        try {
            res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                Map<String, Object> data = (Map<String, Object>) response.get('data');
                Map<String, Object> companyCreate = (Map<String, Object>) data.get('companyCreate');
                Map<String, Object> company = (Map<String, Object>) companyCreate.get('company');
                
                if (company != null) {
                    Map<String, Object> mainContact = (Map<String, Object>) company.get('mainContact');
                    if (mainContact != null) {
                        Map<String, Object> customer = (Map<String, Object>) mainContact.get('customer');
                        if (customer != null) {
                            newCustomerId = extractLastIdPart((String) customer.get('id'));
                            newCompanyId = extractLastIdPart((String) company.get('id'));
                        }
                    }
                }
                System.debug('Company created: ' + res.getBody());
            } else {
                System.debug('Company creation failed: ' + res.getBody());
                throw new AuraHandledException('Failed to create company: ' + res.getStatus() + ' — ' + res.getBody());
            } 
        } catch (Exception ex) {
            APILogger.logCalloutError(
                'Shopify Company Creation - ShopifyIntegrationService.createCompanyOnShopify',
                res.getStatusCode(),
                req.getBody(),
                res.getBody(),
                ex.getStackTraceString(),
                null,
                'API Errors'
            );
            //throw new AuraHandledException('Unhandled error during callout: ' + ex.getMessage());
        }
    }
    
    public static void createCompanyContact(String companyId, String firstName, String lastName, String email) {
        String query = 'mutation CompanyContactCreate($companyId: ID!, $input: CompanyContactInput!) {' +
                       '  companyContactCreate(companyId: $companyId, input: $input) {' +
                       '    companyContact {' +
                       '      id' +
                       '      company { id name }' +
                       '      customer { id firstName lastName email }' +
                       '    }' +
                       '    userErrors { field message code }' +
                       '  }' +
                       '}';

        Map<String, Object> variables = new Map<String, Object>{
            'companyId' => companyId,
            'input' => new Map<String, Object>{
                'email' => email,
                'firstName' => firstName,
                'lastName' => lastName
            }
        };
    
        Map<String, Object> payload = new Map<String, Object>{
            'query' => query,
            'variables' => variables
        };
    
        HttpRequest req = new HttpRequest();
        req.setEndpoint(ENDPOINT);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('X-Shopify-Access-Token', ACCESS_TOKEN);
        req.setBody(JSON.serialize(payload));
    
        Http http = new Http();
        HttpResponse res;
        try {
            res = http.send(req);
        
            if (res.getStatusCode() == 200) {
                Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                Map<String, Object> data = (Map<String, Object>) parsed.get('data');
                Map<String, Object> contactCreate = (Map<String, Object>) data.get('companyContactCreate');
                Map<String, Object> companyContact = (Map<String, Object>) contactCreate.get('companyContact');
                Map<String, Object> customer = (Map<String, Object>) companyContact.get('customer');
                newCustomerId = extractLastIdPart((String) customer.get('id'));
                
                System.debug('Contact added to company: ' + res.getBody());
            } else {
                System.debug('Failed to add contact: ' + res.getBody());
                throw new AuraHandledException('Failed add contact to company: ' + res.getStatus() + ' — ' + res.getBody());
            }
        } catch (Exception ex) {
            APILogger.logCalloutError(
                    'Shopify Company Customer Creation - ShopifyIntegrationService.createCompanyContact',
                    res.getStatusCode(),
                    req.getBody(),
                    res.getBody(),
                    ex.getStackTraceString(),
                    null,
                    'API Errors'
                );
            //throw new AuraHandledException('Failed add contact to company: ' + res.getStatus() + ' — ' + res.getBody());
        }
    }
    
    private static String getAccessToken() {
        Shopify_Config__c config = Shopify_Config__c.getOrgDefaults();
        return config.Shopify_Access_Token__c;
    }
    
    public static String getShopifyCompanyIdByName(String name) {
        String query = 'query {' +
                       '  companies(first: 1, query: "name:\\"' + name + '\\"") {' +
                       '    edges {' +
                       '      node {' +
                       '        id' +
                       '        name' +
                       '      }' +
                       '    }' +
                       '  }' +
                       '}';

        HttpRequest req = new HttpRequest();
        req.setEndpoint(ENDPOINT);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('X-Shopify-Access-Token', ACCESS_TOKEN);
        req.setBody(JSON.serialize(new Map<String, Object>{ 'query' => query }));

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            List<Object> edges = (List<Object>) (((Map<String, Object>) ((Map<String, Object>) result.get('data')).get('companies')).get('edges'));
            if (!edges.isEmpty()) {
                Map<String, Object> node = (Map<String, Object>) ((Map<String, Object>) edges[0]).get('node');
                return (String) node.get('id');
            }
        }

        return null;
    }
    
    private static String extractLastIdPart(String fullGid) {
        if (String.isBlank(fullGid)) {
            return null;
        }
        
        String[] parts = fullGid.split('/');
        return parts.isEmpty() ? null : parts[parts.size() - 1];
    }*/
}