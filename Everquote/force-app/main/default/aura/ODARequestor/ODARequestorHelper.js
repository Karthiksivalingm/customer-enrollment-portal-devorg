({
  quoteFormatter: function (component, event, helper, raw_quotes) {
    function formatQuote(quote, faceAmount) {
      return {
        faceAmount: faceAmount,
        monthlyPremium: quote.premium / 12,
        annualPremium: quote.premium,
        quoteId: quote.quote_id,
        quoteError: quote.error
      };
    }

    var quotes = [];
    var errors = [];
    const faceAmountOptions = Object.keys(raw_quotes);

    for (const faceAmount of faceAmountOptions) {
      let quote = formatQuote(JSON.parse(raw_quotes[faceAmount]), faceAmount);
      quotes.push(quote);
      if (quote.quoteError) {
        errors.push(quote.quoteError);
      }
    }
    quotes.sort((a, b) => a.faceAmount - b.faceAmount);
    component.set("v.quotes", quotes);
    component.set("v.quoteAvailable", false);
    component.set("v.errorMessages", errors);
  }
});