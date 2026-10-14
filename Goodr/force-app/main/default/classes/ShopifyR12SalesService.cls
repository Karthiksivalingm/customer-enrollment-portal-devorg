public class ShopifyR12SalesService {

    // ══════════════════════════════════════════════════════════════
    // FOUR MEASURES, TWO PURPOSES
    //
    // R12 pair — ACCOUNT SCORING ONLY, does not drive the flag
    //   Current_Rolling_12_Month_Sales__c
    //       trailing 365 days:        today-364 → today
    //   Prior_Rolling_12_Month_Sales__c
    //       the 365 days before that: today-729 → today-365
    //   R12_Sales_Decline_Ratio__c       = curr R12 / prior R12
    //   R12_Sales_Performance_Percent__c = that ratio x 100
    //
    //   Both windows are exactly 365 days and do not overlap.
    //
    // YTD pair — DRIVES THE AT-RISK FLAG
    //   Current_YTD_Sales__c       1 Jan this year → today
    //   Prior_YTD_Sales__c         1 Jan last year → same day last yr
    //   YTD_Performance_Percent__c = curr YTD / prior YTD x 100
    //   Shopify_Sales_At_Risk__c   = TRUE when that is below 50
    //
    // Mirrors the client's Tableau logic:
    //   IIF([2026 Revenue YTD] < [2025 Revenue YTD] * 0.5, "Yes","No")
    //
    // Where Prior YTD is $0 the comparison is SKIPPED entirely: the
    // percent is left blank and the store is not flagged. A blank
    // reads as "nothing to compare against", which 100% would not.
    //
    // Store Location grain, Order Effective Date, Shopify Order
    // Amount. Rolled up to the parent Company after the stores.
    //
    // Runs weekly, Sunday 11 PM.
    // ══════════════════════════════════════════════════════════════
    public static void calculateR12(List<Id> accountIds) {

        if (accountIds == null || accountIds.isEmpty()) return;

        Date today = Date.today();

        // ── R12 windows: two equal, consecutive 365-day periods ───
        // addDays(-364) with an inclusive end gives exactly 365 days.
        Date r12CurrStart  = today.addDays(-364);
        Date r12CurrEnd    = today;
        Date r12PriorStart = today.addDays(-729);
        Date r12PriorEnd   = today.addDays(-365);

        // ── YTD windows: same calendar period, two years ──────────
        Date ytdCurrStart  = Date.newInstance(today.year(), 1, 1);
        Date ytdCurrEnd    = today;
        Date ytdPriorStart = Date.newInstance(today.year() - 1, 1, 1);
        Date ytdPriorEnd   = today.addYears(-1);

        System.debug(
            'R12 curr : ' + r12CurrStart + ' → ' + r12CurrEnd +
            ' | R12 prior : ' + r12PriorStart + ' → ' + r12PriorEnd
        );
        System.debug(
            'YTD curr : ' + ytdCurrStart + ' → ' + ytdCurrEnd +
            ' | YTD prior : ' + ytdPriorStart + ' → ' + ytdPriorEnd
        );

        // ── Four aggregates ───────────────────────────────────────
        Map<Id, Decimal> r12CurrMap  =
            sumOrders(accountIds, r12CurrStart,  r12CurrEnd);
        Map<Id, Decimal> r12PriorMap =
            sumOrders(accountIds, r12PriorStart, r12PriorEnd);
        Map<Id, Decimal> ytdCurrMap  =
            sumOrders(accountIds, ytdCurrStart,  ytdCurrEnd);
        Map<Id, Decimal> ytdPriorMap =
            sumOrders(accountIds, ytdPriorStart, ytdPriorEnd);

        DateTime      calcTime  = DateTime.now();
        List<Account> toUpdate  = new List<Account>();
        Integer       flagCount = 0;

        // ── Company rollup accumulators ───────────────────────────
        Map<Id, Decimal> compR12Curr  = new Map<Id, Decimal>();
        Map<Id, Decimal> compR12Prior = new Map<Id, Decimal>();
        Map<Id, Decimal> compYtdCurr  = new Map<Id, Decimal>();
        Map<Id, Decimal> compYtdPrior = new Map<Id, Decimal>();

        Map<Id, Id> storeToCompanyMap = new Map<Id, Id>();
        for (Account a : [
            SELECT Id, ParentId
            FROM Account
            WHERE Id     IN :accountIds
            AND ParentId != null
        ]) {
            storeToCompanyMap.put(a.Id, a.ParentId);
        }

        for (Id accId : accountIds) {

            Decimal r12Curr  = valueFor(r12CurrMap,  accId);
            Decimal r12Prior = valueFor(r12PriorMap, accId);
            Decimal ytdCurr  = valueFor(ytdCurrMap,  accId);
            Decimal ytdPrior = valueFor(ytdPriorMap, accId);

            // ── R12: scoring metrics, no flag ─────────────────────
            Decimal r12Ratio   = ratioOf(r12Curr,   r12Prior);
            Decimal r12Percent = percentOf(r12Curr, r12Prior);

            // ── YTD: this is what drives the flag ─────────────────
            // Blank when there is no prior year to compare against.
            Decimal ytdPercent = ytdPercentOf(ytdCurr, ytdPrior);

            Boolean flag = (ytdPrior > 0) && (ytdPercent < 50);

            if (flag) flagCount++;

            toUpdate.add(new Account(
                Id                                = accId,
                Current_Rolling_12_Month_Sales__c = r12Curr,
                Prior_Rolling_12_Month_Sales__c   = r12Prior,
                R12_Sales_Decline_Ratio__c        = r12Ratio,
                R12_Sales_Performance_Percent__c  = r12Percent,
                Current_YTD_Sales__c              = ytdCurr,
                Prior_YTD_Sales__c                = ytdPrior,
                YTD_Performance_Percent__c        = ytdPercent,
                Shopify_Sales_At_Risk__c          = flag,
                R12_Calculation_Last_Run__c       = calcTime
            ));

            System.debug(
                (flag ? 'AT RISK' : 'HEALTHY') +
                ' | R12 ' + r12Curr + ' vs ' + r12Prior +
                ' = '     + r12Percent + '%' +
                ' || YTD ' + ytdCurr + ' vs ' + ytdPrior +
                ' = '     + ytdPercent + '%'
            );

            // ── Accumulate for the company rollup ─────────────────
            if (storeToCompanyMap.containsKey(accId)) {
                Id cId = storeToCompanyMap.get(accId);
                compR12Curr.put(cId,
                    valueFor(compR12Curr,  cId) + r12Curr);
                compR12Prior.put(cId,
                    valueFor(compR12Prior, cId) + r12Prior);
                compYtdCurr.put(cId,
                    valueFor(compYtdCurr,  cId) + ytdCurr);
                compYtdPrior.put(cId,
                    valueFor(compYtdPrior, cId) + ytdPrior);
            }
        }

        // ── Bulk update Store Location accounts ───────────────────
        if (!toUpdate.isEmpty()) {
            Integer ok = 0, fail = 0;
            for (Database.SaveResult r :
                    Database.update(toUpdate, false)) {
                if (r.isSuccess()) {
                    ok++;
                } else {
                    fail++;
                    System.debug(
                        'Store update failed: ' +
                        r.getErrors()[0].getMessage()
                    );
                }
            }
            System.debug(
                'Stores updated — OK: ' + ok +
                ' | Failed: '           + fail +
                ' | Flagged at risk: '  + flagCount
            );
        }

        // ── Roll up to Company Accounts ───────────────────────────
        if (!compR12Curr.isEmpty()) {
            List<Account> companyUpdates = new List<Account>();

            for (Id cId : compR12Curr.keySet()) {

                Decimal r12Curr  = valueFor(compR12Curr,  cId);
                Decimal r12Prior = valueFor(compR12Prior, cId);
                Decimal ytdCurr  = valueFor(compYtdCurr,  cId);
                Decimal ytdPrior = valueFor(compYtdPrior, cId);

                Decimal ytdPercent = ytdPercentOf(ytdCurr, ytdPrior);
                Boolean compFlag   =
                    (ytdPrior > 0) && (ytdPercent < 50);

                companyUpdates.add(new Account(
                    Id                                = cId,
                    Current_Rolling_12_Month_Sales__c = r12Curr,
                    Prior_Rolling_12_Month_Sales__c   = r12Prior,
                    R12_Sales_Decline_Ratio__c        =
                        ratioOf(r12Curr, r12Prior),
                    R12_Sales_Performance_Percent__c  =
                        percentOf(r12Curr, r12Prior),
                    Current_YTD_Sales__c              = ytdCurr,
                    Prior_YTD_Sales__c                = ytdPrior,
                    YTD_Performance_Percent__c        = ytdPercent,
                    Shopify_Sales_At_Risk__c          = compFlag,
                    R12_Calculation_Last_Run__c       = calcTime
                ));

                System.debug(
                    'Company rollup | YTD ' + ytdCurr +
                    ' vs ' + ytdPrior + ' = ' + ytdPercent + '%' +
                    ' | Flag: ' + compFlag
                );
            }

            Integer compOk = 0, compFail = 0;
            for (Database.SaveResult r :
                    Database.update(companyUpdates, false)) {
                if (r.isSuccess()) {
                    compOk++;
                } else {
                    compFail++;
                    System.debug(
                        'Company rollup failed: ' +
                        r.getErrors()[0].getMessage()
                    );
                }
            }
            System.debug(
                'Company rollup — OK: ' + compOk +
                ' | Failed: '           + compFail
            );
        }
    }

    // ══════════════════════════════════════════════════════════════
    // HELPERS
    // ══════════════════════════════════════════════════════════════

    // ── Sum Shopify order revenue per account for one window ──────
    private static Map<Id, Decimal> sumOrders(
        List<Id> accountIds,
        Date windowStart,
        Date windowEnd
    ) {
        Map<Id, Decimal> result = new Map<Id, Decimal>();
        for (AggregateResult ar : [
            SELECT AccountId accId,
                   SUM(Shopify_Order_Amount__c) total
            FROM Order
            WHERE Shopify_Order_Id__c != null
            AND EffectiveDate         >= :windowStart
            AND EffectiveDate         <= :windowEnd
            AND AccountId             IN :accountIds
            GROUP BY AccountId
        ]) {
            Decimal v = ar.get('total') != null
                ? (Decimal) ar.get('total') : 0;
            result.put((Id) ar.get('accId'), v);
        }
        return result;
    }

    private static Decimal valueFor(Map<Id, Decimal> m, Id key) {
        return m.containsKey(key) ? m.get(key) : 0;
    }

    // ── R12 ratio — scoring metric, always populated ──────────────
    private static Decimal ratioOf(Decimal curr, Decimal prior) {
        if (prior > 0)               return (curr / prior).setScale(4);
        if (prior == 0 && curr == 0) return 0;
        return 1;                    // sales now, none before
    }

    // ── R12 percent — scoring metric, always populated ────────────
    private static Decimal percentOf(Decimal curr, Decimal prior) {
        if (prior > 0)  return (curr / prior * 100).setScale(2);
        if (curr == 0)  return 0;
        return 100.00;               // sales now, none before
    }

    // ── YTD percent — blank when there is nothing to compare ──────
    // The client's rule is to SKIP the comparison when Prior YTD is
    // zero. Returning null leaves the field empty on the record,
    // which is honest. Returning 100 would imply parity with a
    // prior year that never existed.
    private static Decimal ytdPercentOf(Decimal curr, Decimal prior) {
        if (prior > 0) return (curr / prior * 100).setScale(2);
        return null;
    }
}