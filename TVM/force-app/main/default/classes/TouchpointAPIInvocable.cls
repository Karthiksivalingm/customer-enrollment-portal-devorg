//Apex from FND
public class TouchpointAPIInvocable {
  @InvocableMethod(label='TouchpointAPI' description='Sends API To TP, Format: "ID-RID{FID||Value}{FID||Value}" ex. "59109-RID-{7618||somevalue}{7619||othervalue}"')
   public static void invokeapexcallout(list<String> inputtext) {
     TouchpointAPI.TPAPI(inputtext);
   }
}