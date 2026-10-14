public class RichTextStrip {
  @InvocableMethod(label='RichTextStrip' description='Removes HTML from Rich Text')
  public static List<String> stripText(List<String> inputtext) {
    List <String> output = new List<String>();    
        for(string s : inputtext){
            if(s!=null){
                output.add(s.stripHtmlTags());
            }
        }
    return output;
  }
}