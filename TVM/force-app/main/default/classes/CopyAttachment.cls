public class CopyAttachment{
	@InvocableVariable(
    Label='Source Id' 
    Description='Id of an object with related Attachments'
    Required=true)
	public String sourceId;
    @InvocableVariable(
    Label='Destination Id' 
    Description='Id of an object that receives Attachments'
    Required=true)
	public String destId;

public CopyAttachment(){}
public CopyAttachment(String sourceId, String destId){
    this.sourceId = sourceId;
    this.destId = destId;
}
  
@InvocableMethod(label='Copy Attachment' description='Copy Attachment From Object A to Object B' category='Attachment')
  public static void createAttachments(List<CopyAttachment> mapping) {  
      for (CopyAttachment m : mapping) {
        system.debug('******SourceID Debug*******: '+m.sourceId);
        List <Attachment> attList = [select id, name, body from Attachment where ParentId = :m.sourceID];   
        for (Attachment a : attlist) {
             Attachment att = new Attachment(name = a.name, body = a.body, parentid = m.destID);
            Insert att;
        }
      }
  }
}