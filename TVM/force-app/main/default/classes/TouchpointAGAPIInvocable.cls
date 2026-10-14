//Apex from FND
public class TouchpointAGAPIInvocable {
  @InvocableMethod(label='TouchpointAGAPI' description='Sends API To TP, Format: "ID-RID{FID||Value}{FID||Value}" ex. "59109-RID-{7618||somevalue}{7619||othervalue}"')
   public static void invokeapexcallout(list<String> inputtext) {
     TouchpointAGAPI.TPAPI(inputtext);
   }
}