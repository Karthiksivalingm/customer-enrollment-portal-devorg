@isTest
public class RichTextStripTest {
    @isTest
    private static void validateRichTextStrip() {
        List<String> testtext = new List<String>();
        testtext.add('<p>test</p>');
        
        Test.startTest();
        RichTextStrip.stripText(testtext);
        Test.stopTest();
    }
}