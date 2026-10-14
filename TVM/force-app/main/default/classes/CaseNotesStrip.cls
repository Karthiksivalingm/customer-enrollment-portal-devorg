public class CaseNotesStrip {
  @InvocableMethod(label='Strip Rich Text' description='Removes HTML from Rich Text' category='Case')
  public static void stripText(List<Case> ids) {
    String input;
    String backlash = '\n';
	String backlashReplacement = '---n';

    for (Case cs : ids) {
        input = cs.Internal_Notes_Rich__c;
        if(input!=null){
            input = input.stripHtmlTags();
			//input = input.replaceAll('<[/a-zAZ0-9]*>','');
            //input = input.unescapeHtml4();
        	cs.internal_Notes__c = input;
        }
        
        input = cs.External_Notes_Rich__c;
        if(input!=null){
            input = input.stripHtmlTags();
			//input = input.replaceAll('<[/a-zAZ0-9]*>','');
            //input = input.unescapeHtml4();
        	cs.External_Notes__c = input;
        }
        update cs;
    }
  }
}