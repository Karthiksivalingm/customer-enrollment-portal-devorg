//Foundation Apex class
public with sharing class CreateCaseCommentHandler {
   
    private static final String STRIP_HTML_REGEX = '<style>[^<]*<\\/style>|<\\/?\\w*\\b[^>]*>';
    
    public static void handleAfterInsert(List<FeedItem> newFeedItems) {
        if (newFeedItems == null || newFeedItems.isEmpty()) {
            return;
        }        
   
        Set<Id> caseParentIds = new Set<Id>();
        for (FeedItem fi : newFeedItems) {
            if (fi.ParentId == null) continue;
   
            try {
                if (fi.ParentId.getSObjectType() == Case.sObjectType) {
                    caseParentIds.add(fi.ParentId);
                }
            } catch (Exception e) {   
                continue;
            }
        }
        if (caseParentIds.isEmpty()) {
            return;
        }
        
        Map<Id, Case> foundationCases = new Map<Id, Case>();
        for (Case c : [SELECT Id, Foundation_Case__c FROM Case WHERE Id IN :caseParentIds AND Foundation_Case__c = true]) {
            foundationCases.put(c.Id, c);
        }
        if (foundationCases.isEmpty()) {
            return;
        }
        
        List<CaseComment> commentsToInsert = new List<CaseComment>();
        Pattern tagPattern = Pattern.compile(STRIP_HTML_REGEX);
        
        for (FeedItem fi : newFeedItems) {
            if (fi.ParentId == null) continue;
            if (!foundationCases.containsKey(fi.ParentId)) continue;
            if (fi.Body == null) continue;
            
        
            String plainTextBody = tagPattern.matcher(fi.Body).replaceAll('');        
            if (plainTextBody == null) plainTextBody = '';
            plainTextBody = plainTextBody.trim();
            
            if (plainTextBody.length() == 0) continue;
            
            CaseComment cc = new CaseComment();
            cc.ParentId = fi.ParentId;
            cc.CommentBody = plainTextBody;
            commentsToInsert.add(cc);
        }
        
        if (!commentsToInsert.isEmpty()) {
            try {
                insert commentsToInsert;
            } catch (DmlException dmle) {
                throw dmle;
            }
        }
    }
}