public class JsonParseFamiliarNames {
	public List<String> colleagues {get;}
    public List<String> familiar_names {get;}
    public Integer distance {get;}

	public static JsonParseFamiliarNames parse(String json) {
		return (JsonParseFamiliarNames) System.JSON.deserialize(json, JsonParseFamiliarNames.class);
	}
}