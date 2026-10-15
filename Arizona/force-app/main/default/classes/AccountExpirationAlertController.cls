public with sharing class AccountExpirationAlertController {

    private static final Integer CRITICAL_WINDOW_DAYS = 2;
    private static final Integer WARNING_WINDOW_DAYS = 60;

    @AuraEnabled(cacheable=true)
    public static List<ExpirationAlert> getExpirationAlerts(Id accountId) {
        return buildAlerts(accountId);
    }

    public class ExpirationAlert implements Comparable {

        @AuraEnabled
        public String label;

        @AuraEnabled
        public String groupName;

        @AuraEnabled
        public String fieldApiName;

        @AuraEnabled
        public Date expirationDate;

        @AuraEnabled
        public Integer daysRemaining;

        @AuraEnabled
        public String severity;

        @AuraEnabled
        public String message;

        @AuraEnabled
        public String service;

        @AuraEnabled
        public Decimal serviceDays;

        @AuraEnabled
        public Decimal serviceWeeks;

        public ExpirationAlert(
            String label,
            String groupName,
            String fieldApiName,
            Date expirationDate,
            Integer daysRemaining,
            String severity,
            String message,
            String service,
            Decimal serviceDays,
            Decimal serviceWeeks
        ){

            this.label = label;
            this.groupName = groupName;
            this.fieldApiName = fieldApiName;
            this.expirationDate = expirationDate;
            this.daysRemaining = daysRemaining;
            this.severity = severity;
            this.message = message;
            this.service = service;
            this.serviceDays = serviceDays;
            this.serviceWeeks = serviceWeeks;
        }

        private Integer severityRank(){

            if(severity == 'critical'){
                return 0;
            }

            if(severity == 'warning'){
                return 1;
            }

            return 2;
        }

        public Integer compareTo(Object obj){

            ExpirationAlert other =
                (ExpirationAlert)obj;

            Integer result =
                severityRank() -
                other.severityRank();

            if(result != 0){
                return result;
            }

            return daysRemaining -
                other.daysRemaining;
        }
    }
    private static List<ExpirationAlert> buildAlerts(Id accountId){

        List<ExpirationAlert> alerts =
            new List<ExpirationAlert>();

        if(accountId == null){
            return alerts;
        }

        try{

            Account acc = [

                SELECT
                    End_Date__c,
                    Service__c,
                    Service_Days__c,
                    Service_Weeks__c,
                    Date_of_Next_Meeting__c

                FROM Account

                WHERE Id = :accountId

                LIMIT 1

            ];

            Date today = Date.today();

            /**********************************************
             * AUTHORIZATION
             **********************************************/

            if(acc.End_Date__c != null){

                Integer daysRemaining =
                    today.daysBetween(acc.End_Date__c);

                if(daysRemaining >= 0 &&
                   daysRemaining <= WARNING_WINDOW_DAYS){

                    String severity =
                        (daysRemaining <= CRITICAL_WINDOW_DAYS)
                        ? 'critical'
                        : 'warning';

                    List<String> services =
                        String.isBlank(acc.Service__c)
                        ? new List<String>{'Authorization'}
                        : acc.Service__c.split(';');

                    for(String svc : services){

                        String serviceName =
                            svc.trim();

                        if(String.isBlank(serviceName)){
                            continue;
                        }

                        String message;

                        if(daysRemaining == 0){

                            message =
                                serviceName +
                                ' service expires today.';

                        }
                        else if(daysRemaining == 1){

                            message =
                                serviceName +
                                ' service expires tomorrow.';

                        }
                        else{

                            message =
                                serviceName +
                                ' service expires in ' +
                                daysRemaining +
                                ' days.';

                        }

                        alerts.add(

                            new ExpirationAlert(

                                serviceName,

                                'Authorizations',

                                'End_Date__c',

                                acc.End_Date__c,

                                daysRemaining,

                                severity,

                                message,

                                serviceName,

                                acc.Service_Days__c,

                                acc.Service_Weeks__c

                            )

                        );

                    }

                }

            }

            /**********************************************
             * PCSP
             **********************************************/

            if(acc.Date_of_Next_Meeting__c != null){

                Integer daysRemaining =
                    today.daysBetween(
                        acc.Date_of_Next_Meeting__c
                    );

                if(daysRemaining >= 0 &&
                   daysRemaining <= WARNING_WINDOW_DAYS){

                    String severity =
                        (daysRemaining <= CRITICAL_WINDOW_DAYS)
                        ? 'critical'
                        : 'warning';

                    String message;

                    if(daysRemaining == 0){

                        message =
                            'Next PCSP meeting is today.';

                    }
                    else if(daysRemaining == 1){

                        message =
                            'Next PCSP meeting is tomorrow.';

                    }
                    else{

                        message =
                            'Next PCSP meeting is in ' +
                            daysRemaining +
                            ' days.';

                    }

                    alerts.add(

                        new ExpirationAlert(

                            'PCSP',

                            'PCSP',

                            'Date_of_Next_Meeting__c',

                            acc.Date_of_Next_Meeting__c,

                            daysRemaining,

                            severity,

                            message,

                            null,

                            null,

                            null

                        )

                    );

                }

            }

            alerts.sort();

            return alerts;

        }
        catch(Exception e){

            throw new AuraHandledException(
                e.getMessage()
            );

        }

    }
}