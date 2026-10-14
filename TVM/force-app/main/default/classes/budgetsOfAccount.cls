global with sharing class budgetsOfAccount {
global String accountId { get; set; }

global Account account {
    get {
        account = [
            SELECT Id, Name, FNDN_Billed_Through_TVM__c, Touchpoint_Master_ID__c,Foundation_Account__c 
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];
        return account;
    }
    set;
}
     
global List<Monthly_Budget__c> Opps {
    get {  
        List<Monthly_Budget__c> posToDisplay = new List<Monthly_Budget__c>();
        
        DateTime dt = Datetime.now();
        String Month = dt.format('MMM');
        String Year = String.valueOf(dt.format('YYYY'));
        
        Account acc = this.account;
        List<Account> accList;
        
        if (acc != null && acc.FNDN_Billed_Through_TVM__c == false) {
            accList = [
                SELECT Id, Name,
                       (SELECT Id,
                               PPC_Budget_Sales__c,
                               PPC_Budget_Service__c,
                               PPC_Budget_DISC__c,
                               Video_Budget_Sales__c,
                               Video_Budget_Preowned__c,
                               Display_Budget_Sales__c,
                               Display_Budget_Preowned__c,
                               SMA_Budget_Sales__c,
                               SMA_Budget_Service__c,
                               SMA_Budget_Preowned__c,
                               PPC_Budget_VLA_New__c,
                               PPC_Budget_VLA_Used__c,
                               Performance_Max_New_Budget__c,
                               Performance_Max_Used_Budget__c,
                               OTT_Premium_Custom_Budget__c,
                               Custom_Dynamic_Pre_Roll_Production_Budge__c
                        FROM Monthly_Budgets__r
                        WHERE Budget_Month__c = :Month
                          AND Budget_Year__c = :Year
                        LIMIT 1)
                FROM Account
                WHERE Id = :accountId
                  //AND FNDN_Billed_Through_TVM__c = FALSE
            ];
        } else if (acc != null && acc.FNDN_Billed_Through_TVM__c == true) {
            accList = [
                SELECT Id, Name,
                       (SELECT Id,
                               PPC_Budget_Sales__c,
                               PPC_Budget_Service__c,
                               PPC_Budget_DISC__c,
                               Video_Budget_Sales__c,
                               Video_Budget_Preowned__c,
                               Display_Budget_Sales__c,
                               Display_Budget_Preowned__c,
                               SMA_Budget_Sales__c,
                               SMA_Budget_Service__c,
                               SMA_Budget_Preowned__c,
                               PPC_Budget_VLA_New__c,
                               PPC_Budget_VLA_Used__c,
                               Performance_Max_New_Budget__c,
                               Performance_Max_Used_Budget__c,
                               OTT_Premium_Custom_Budget__c,
                               Custom_Dynamic_Pre_Roll_Production_Budge__c
                        FROM Monthly_Budgets__r
                        WHERE Budget_Month__c = :Month
                          AND Budget_Year__c = :Year
                        LIMIT 1)
                FROM Account
                WHERE Foundation_Account__c = :acc.Touchpoint_Master_ID__c
            ];
        } 
        /*else {
            accList = new List<Account>();
        }*/

        for (Account p : accList) {
            for (Monthly_Budget__c m : p.Monthly_Budgets__r) {
                posToDisplay.add(m);
            }
        }
        return posToDisplay;
    }
    set;
}

global List<Monthly_Budget__c> newOpps {
    get {
        List<Monthly_Budget__c> posToDisplay = new List<Monthly_Budget__c>();
        DateTime dt = Datetime.now().addMonths(1);
        String Month = dt.format('MMM');
        String Year = String.valueOf(dt.format('YYYY'));
        
        Account acc = this.account;
        List<Account> accList;
        System.debug('test');
        if (acc != null && acc.FNDN_Billed_Through_TVM__c == false) {
            System.debug('test2');
            accList = [
                SELECT Id, Name,
                       (SELECT Id,
                               PPC_Budget_Sales__c,
                               PPC_Budget_Service__c,
                               PPC_Budget_DISC__c,
                               Video_Budget_Sales__c,
                               Video_Budget_Preowned__c,
                               Display_Budget_Sales__c,
                               Display_Budget_Preowned__c,
                               SMA_Budget_Sales__c,
                               SMA_Budget_Service__c,
                               SMA_Budget_Preowned__c,
                               PPC_Budget_VLA_New__c,
                               PPC_Budget_VLA_Used__c,
                               Performance_Max_New_Budget__c,
                               Performance_Max_Used_Budget__c,
                               OTT_Premium_Custom_Budget__c,
                               Custom_Dynamic_Pre_Roll_Production_Budge__c
                        FROM Monthly_Budgets__r
                        WHERE Budget_Month__c = :Month
                          AND Budget_Year__c = :Year
                        LIMIT 1)
                FROM Account
                WHERE Id = :accountId
                  //AND FNDN_Billed_Through_TVM__c = FALSE
            ];
           
        } 
         
        else if (acc != null && acc.FNDN_Billed_Through_TVM__c == true) {
            System.debug('test3');
            accList = [
                SELECT Id, Name,
                       (SELECT Id,
                               PPC_Budget_Sales__c,
                               PPC_Budget_Service__c,
                               PPC_Budget_DISC__c,
                               Video_Budget_Sales__c,
                               Video_Budget_Preowned__c,
                               Display_Budget_Sales__c,
                               Display_Budget_Preowned__c,
                               SMA_Budget_Sales__c,
                               SMA_Budget_Service__c,
                               SMA_Budget_Preowned__c,
                               PPC_Budget_VLA_New__c,
                               PPC_Budget_VLA_Used__c,
                               Performance_Max_New_Budget__c,
                               Performance_Max_Used_Budget__c,
                               OTT_Premium_Custom_Budget__c,
                               Custom_Dynamic_Pre_Roll_Production_Budge__c
                        FROM Monthly_Budgets__r
                        WHERE Budget_Month__c = :Month
                          AND Budget_Year__c = :Year
                        LIMIT 1)
                FROM Account
                WHERE Foundation_Account__c = :acc.Touchpoint_Master_ID__c
            ];
        } 
        /*else {
            accList = new List<Account>();
        }*/
        
        for (Account p : accList) {
            for (Monthly_Budget__c m : p.Monthly_Budgets__r) {
                posToDisplay.add(m);
            }
        }
        System.debug('posToDisplay' + posToDisplay );
        return posToDisplay;
        
    }
    set;
}

global String NewLine {
    get { return '\r\n'; }
    set;
}
}