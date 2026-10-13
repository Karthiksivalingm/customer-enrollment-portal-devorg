public class JsonParseMarketplaceStats {
    public Consumers consumers {get;}
    public Consumers unsold_consumers {get;}
    public Double share_rate {get;}
    public Integer unsold_leads {get;}
    
    public class Consumers {
        public Integer premium {get;}
        public Integer preferred {get;}
        public Integer standard {get;}
        public Integer non_standard {get;}
    }

	public static JsonParseMarketplaceStats parse(String json) {
		return (JsonParseMarketplaceStats) System.JSON.deserialize(json, JsonParseMarketplaceStats.class);
	}
}