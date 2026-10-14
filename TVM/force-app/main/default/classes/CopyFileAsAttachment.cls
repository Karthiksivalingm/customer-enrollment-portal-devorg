public class CopyFileAsAttachment {
@InvocableMethod(label='Copy File as Attachment' description='Copy File as Attachment For Forwarding' category='ContentDocumentLink')
  public static void createAttachments(List<List<ContentDocumentLink>> ids) {  
    String input;
   	
    for (ContentDocumentLink cdl : ids[0]) {
        ContentDocument cDoc = [SELECT LatestPublishedVersionId FROM ContentDocument WHERE Id=:cdl.ContentDocumentId];
        ContentVersion cVersion = [SELECT Id, PathOnClient, OwnerId, Title, VersionData From ContentVersion WHERE Id=:cDoc.LatestPublishedVersionId];
        Attachment attach = new Attachment();
         
        //Insert ContentVersion
        attach.Name = cVersion.PathOnClient;//File name with extention
        attach.OwnerId = cVersion.OwnerId;//Owner of the file
        attach.Name = cVersion.Title;//Name of the file
        attach.Body = cVersion.VersionData;//File content
        attach.ParentId = cdl.LinkedEntityId; //Parent
        Insert attach;
    }
  }
}