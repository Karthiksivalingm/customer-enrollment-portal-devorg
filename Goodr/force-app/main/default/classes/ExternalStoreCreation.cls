public class ExternalStoreCreation {

    private static final String TYPEFORM_CANADA_ID = 'ZpuPvJtA';
    private static final String TYPEFORM_US_ID = 'S0t1jVLc';

    private static final List<List<String>> STORE_REFS_CA = new List<List<String>>{
            // Store 10
            new List<String>{
                'f0a0bef3-7b91-477f-8708-e81cb18d9ec3', // street
                'c85d1078-90e3-4148-93cb-bfd0c1f4e6e4', // city
                '1a9aa36a-10a7-4ed8-85e2-81c04869bd01', // state (province)
                'db349cd0-d5ab-4dc8-9fa3-89f6bf74d47b', // zip
                '759d3a08-2f34-4c6b-9e58-b7e294315605'  // area
            },
            // Store 9
            new List<String>{
                '12b36757-6d55-455f-b1f2-1ea38945535c', // street
                'dd3ace7b-60e9-450a-9298-8845ea84792c', // city
                '7b75eb00-8059-4a12-bba5-d8983f732ad6', // state (province)
                'ed25238b-b0fc-4f14-852e-829468f58f15', // zip
                '536d0fb3-1402-45f1-a915-2a0ebda99e07'  // area
            },
            // Store 8
            new List<String>{
                '2124146c-5787-4098-ad8f-9218cf3436af', // street
                '7a58c696-fcce-45a3-9a08-924289c34458', // city
                '9ea42ab7-ded6-4bc4-ac59-dc0aaba2a28d', // state (province)
                'e724b63f-eef3-4443-9e99-d5413dc82096', // zip
                'fb41af7d-9eee-4d64-af6a-98dc9ad1aa7d'  // area
            },
            // Store 7
            new List<String>{
                '292b5743-ea28-45d3-941c-ba0d4edca690', // street
                'ca06561d-6ad6-4936-b8f8-3cae5c911264', // city
                '24ed5307-fbf0-46d9-ba08-a6980917b4e3', // state (province)
                'cfd5581a-7f71-4e6f-bb53-61745943db9c', // zip
                '1635b441-3617-4f67-a9fa-43ddf370d8f8'  // area
            },
            // Store 6
            new List<String>{
                'f12779b5-70d1-41c5-bc19-3e5c007e2c56', // street
                '0cae5d57-d72a-4cbf-bee9-7826ed9f657e', // city
                '0e070f72-7331-4aa4-ac78-7b23c06c98f7', // state (province)
                '8882a1e3-e2ce-4a48-a769-45906e7297b8', // zip
                '2d4806f0-321d-4baf-b7fa-4cd73609bb59'  // area
            },
            // Store 5
            new List<String>{
                '82091ac4-6e2d-4a1d-a570-aa66621d25c2', // street
                '7a82400a-a681-4439-9456-f0a43eb3b6ac', // city
                '8ed3d123-995e-496e-8880-fcce05445c93', // state (province)
                'a801720d-37cf-4fc9-a77c-07ba7c28ac7d', // zip
                '93633676-4cfd-4da2-ba18-45b7412497c0'  // area
            },
            // Store 4
            new List<String>{
                'f0b0a32d-2926-4fa8-bcb6-ac47002e949a', // street
                '4e2c5691-ce1d-4a87-9535-3ee9bd5eb37c', // city
                'cf6e3d12-4051-45f0-944e-bcbe1b7cb5d1', // state (province)
                'b5f151e6-468f-4917-8cec-7bc96180ce9c', // zip
                '2d533da4-c95f-4fc9-9419-319b18e8b97c'  // area
            },
            // Store 3
            new List<String>{
                '35188228-7945-4e8e-bb2b-543a54cf152f', // street
                '0708afe5-9703-44f1-9188-d6626075aad6', // city
                '991a590e-44b2-4d5c-8743-1aac9527e3bc', // state (province)
                '2cb174a8-ee21-4c5a-b7dd-2fed37b5ce24', // zip
                'e5a5a3b9-768b-4a4a-a009-5781e48eb12f'  // area
            },
            // Store 2
            new List<String>{
                'e89e2fe3-fc4a-4c9e-bf56-d28175e9c5d5', // street
                'ab0d2ea9-f0c9-44a0-a0c7-76ac2bf59873', // city
                'b4df4b6f-e81c-4ae8-a2d5-995253286f5d', // state (province)
                '51d21cad-0fa4-4213-92af-1848f89a299a', // zip
                '94de4b9b-456e-4302-bca9-228e478e08e5'  // area
            },
            // Store 1
            new List<String>{
                'eb6485c5-d80f-4a64-a533-8c2e12918c43', // street
                '4d72c5b2-88a7-4266-b484-f644d2e0fa3e', // city
                '9a5c04e4-3d8c-491d-9e6a-ed1cd0b1c97c', // state (province)
                '0c05c1c8-009c-4a26-bb06-ddd474ed68d2', // zip
                '57726c09-8f3b-4928-a366-60ba10bf790a'  // area
            }
        };
   
    private static final List<List<String>> STORE_REFS_US = new List<List<String>>{
            // Store 10
            new List<String>{
                '638fe573-1acb-477b-ace9-f0fb9fc6e1fe', // street
                '10065097-d56e-41ab-9e03-5ff0c9b381a4', // city
                'aae6b704-76e4-4c45-92a7-5e89bb563cc0', // state
                'f034fdc2-0e03-48c8-8511-eb9d9733c12d', // zip
                '759d3a08-2f34-4c6b-9e58-b7e294315605'  // area
            },
            // Store 9
            new List<String>{
                'db715733-915f-4722-8b01-69e907086410', // street
                '6fa011da-80c9-486d-837d-023c9e0f23a8', // city
                'ccce48cc-67d8-4c9d-b8a9-b004bdebc792', // state
                '1ebe3ad2-4840-47ac-b85d-00c845074bfe', // zip
                '536d0fb3-1402-45f1-a915-2a0ebda99e07'  // area
            },
            // Store 8
            new List<String>{
                '53cda37e-72db-4558-8461-2c714fb5e055', // street
                'edeaa99d-84f1-4ffb-a20d-c4eb2e1d157c', // city
                '3f1d6e39-7991-4f24-8c05-c437c569d0ce', // state
                '6384660b-9975-478b-b6a9-36c8150d9392', // zip
                'fb41af7d-9eee-4d64-af6a-98dc9ad1aa7d'  // area
            },
            // Store 7
            new List<String>{
                '7522e5a9-f700-43b0-9f4d-0bb622bff5a3', // street
                'f1ade853-3b3f-4656-b3c0-b61b53fd06aa', // city
                'e7e28363-4251-48bd-b9b3-39293b9d07c2', // state
                '90bb29db-5413-4c54-bf48-673393658b16', // zip
                '1635b441-3617-4f67-a9fa-43ddf370d8f8'  // area
            },
            // Store 6
            new List<String>{
                '9a12a99e-e77d-4aca-944f-3fbf1f660b6b', // street
                'bc0e77e8-a9b5-453f-8a9c-7935f524de9b', // city
                '9877a0ff-1b40-4a14-9098-27cfc7aeebd7', // state
                '4afe91e9-fb1d-4ca1-87fc-74be53bb7c44', // zip
                '2d4806f0-321d-4baf-b7fa-4cd73609bb59'  // area
            },
            // Store 5
            new List<String>{
                '15240551-c3c0-499e-a9e1-db9cf3d592da', // street
                '677005c8-4ddc-49cf-8a8a-eed6c76ffa96', // city
                '8b555553-35d7-48c3-a53a-6cd69004a9c2', // state
                '01be0fdd-9332-48ba-92ff-42d1019d6b78', // zip
                '93633676-4cfd-4da2-ba18-45b7412497c0'  // area
            },
            // Store 4
            new List<String>{
                'f0e0d739-58ed-4959-bcbc-bdbced9b6bdf', // street
                'ce82b760-0255-4774-b5be-3820b4a4c737', // city
                'a3278dd5-33f8-4447-83c7-e42ea5b3f2b7', // state
                '564abca4-ca9e-488d-9a4b-12fa8d266a1b', // zip
                '2d533da4-c95f-4fc9-9419-319b18e8b97c'  // area
            },
            // Store 3
            new List<String>{
                'bc1a27d5-964f-4c50-a9e5-205a8fa30d4f', // street
                '7b7ed4b3-7d4e-475e-ac39-c2a5ba0644e5', // city
                '487be297-33e0-4242-b817-22553a3b0f61', // state
                '4dafe551-fae9-47f4-83e9-a21a10cc241d', // zip
                'e5a5a3b9-768b-4a4a-a009-5781e48eb12f'  // area
            },
            // Store 2
            new List<String>{
                '81a6a3c4-f77d-4971-9b4f-0c25ea4a310c', // street
                'ccf198b0-f8dc-45cb-9748-36b8bc8948cd', // city
                '7902609b-e66e-47fe-a83b-6b691d9f204b', // state
                'a7264b28-e9f0-4480-bd1c-134956813146', // zip
                '94de4b9b-456e-4302-bca9-228e478e08e5'  // area
            },
            // Store 1
            new List<String>{
                '3ee1fca4-7fc5-4df1-892e-f536b5cc9b69', // street
                'd40dc5ac-fe3a-4f32-82e7-14b4694258b1', // city
                'e1498e1d-1263-458c-9e8a-c5b1da2a951d', // state
                '55ecf75f-fd9a-4363-9c06-d3985466a2a4', // zip
                '82f6d6d7-0699-4b8a-9274-d8c5fb14ce3a'  // area
            }
        };

    
    public static void createStoresFromTypeformResponse(Map<String, Object> latestResponse, String leadId, List<Store__c> storesToInsert, String formId) {
        List<Object> answers = (List<Object>) latestResponse.get('answers');
        if (answers == null || answers.isEmpty())  {
            return;
        }

        extractStoresFromAnswers(answers, leadId, storesToInsert, formId);
    }

    private static void extractStoresFromAnswers(List<Object> answers, String leadId, List<Store__c> storesToInsert, String formId) {
        Map<String, Object> refToAnswer = new Map<String, Object>();
        for (Object ansObj : answers) {
            Map<String, Object> ans = (Map<String, Object>) ansObj;
            if (ans.containsKey('field')) {
                Map<String, Object> field = (Map<String, Object>) ans.get('field');
                String ref = (String) field.get('ref');
                refToAnswer.put(ref, ansObj);
            }
        }
        
        List<List<String>> storeRefGroups = getStoreRefsByForm(formId);
    	String countryCode = determineCountryByFormId(formId);

        for (List<String> refs : storeRefGroups) {
            String street = getTextFromAnswer(refToAnswer.get(refs[0]));
            String city = getTextFromAnswer(refToAnswer.get(refs[1]));
            String state = getTextFromAnswer(refToAnswer.get(refs[2]));
            String zip = getTextFromAnswer(refToAnswer.get(refs[3]));
            String country = countryCode;
            Integer area = getNumberFromAnswer(refToAnswer.get(refs[4]));

            if (street != null && city != null) {
                Store__c store = new Store__c();
                store.Lead__c = leadId;
                store.Address__c = street + ', ' + city + ', ' + state + ', ' + zip + ', ' + country;
                store.Store_Square_Footage__c = area;
                storesToInsert.add(store);
            }
        }
    }
    
    private static String getTextFromAnswer(Object answerObj) {
        if (answerObj == null) return null;
        Map<String, Object> answer = (Map<String, Object>) answerObj;
        return (String) answer.get('text');
    }
    
    private static Integer getNumberFromAnswer(Object answerObj) {
        if (answerObj == null) return null;
        Map<String, Object> answer = (Map<String, Object>) answerObj;
        if (answer.containsKey('number')) {
            Object numberValue = answer.get('number');
            if (numberValue instanceof Decimal) {
                return ((Decimal) numberValue).intValue();
            } else if (numberValue instanceof Integer) {
                return (Integer) numberValue;
            }
        }
        return null;
    }

    private static String determineCountryByFormId(String formId) {
        if (formId == TYPEFORM_CANADA_ID) {
            return 'CA';
        } else if (formId == TYPEFORM_US_ID) {
            return 'US';
        }
        return 'US';
    }

    private static List<List<String>> getStoreRefsByForm(String formId) {
        if (formId == TYPEFORM_CANADA_ID) {
            return STORE_REFS_CA;
        } else if (formId == TYPEFORM_US_ID) {
            return STORE_REFS_US;
        }
        throw new AuraHandledException('Unknown form ID: ' + formId);
    }
}