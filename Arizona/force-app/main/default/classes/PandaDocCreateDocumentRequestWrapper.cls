/**
 * Request wrapper for PandaDoc API
 * https://api.pandadoc.com/public/v1/documents
 */
public class PandaDocCreateDocumentRequestWrapper {
    public String name;
    public String template_uuid;
    public String folder_uuid;
    public List<String> tags;
    public List<RecipientWrapper> recipients;
    public List<TokenWrapper> tokens;
    public Map<String, Map<String, Object>> fields;
    public Map<String, Object> metadata;
    public List<PricingTableWrapper> pricing_tables;
    public List<ImageWrapper> images;

    public class RecipientWrapper {
        public String email;
        public String first_name;
        public String last_name;
        public String role;
        public Integer signing_order;
    }

    public class TokenWrapper {
        public String name;
        public String value;
    }

    public class PricingTableWrapper {
        public String name;
        public Boolean data_merge;
        public Map<String, Object> options;
        public List<SectionWrapper> sections;
    }

    public class SectionWrapper {
        public String title;
        public Boolean default_x;
        public List<RowWrapper> rows;
    }

    public class RowWrapper {
        public Map<String, Object> options;
        public Map<String, Object> data;
        public Map<String, Object> custom_fields;
    }

    public class ImageWrapper {
        public String name;
        public List<String> urls;
    }
}