public with sharing class RenewalScheduleMigrationValidationBatch
        implements Database.Batchable<SObject> {

    // ── Constants ─────────────────────────────────────────────────────────────
    private static final Decimal TOLERANCE             = 0.0001;
    private static final Integer YEAR_MIN              = 2;
    private static final Integer YEAR_MAX              = 50;

    private static final String TYPE_RENEWAL           = 'Renewal';
    private static final String TYPE_SERVICE_FEE       = 'Service_Fee';
    private static final String TYPE_EXTENDED_RENEWAL  = 'Extended_Renewal';

    private static final String DT_VALUE_MISMATCH      = 'Value_Mismatch';
    private static final String DT_MISSING_NEW         = 'Missing_New_Record';
    private static final String DT_EXTRA_NEW           = 'Extra_New_Record';
    private static final String DT_OVERLAP             = 'Overlapping_Range';
    private static final String DT_INVALID_YEAR_FROM   = 'Invalid_Year_From';
    private static final String DT_INVALID_YEAR_TO     = 'Invalid_Year_To';
    private static final String DT_COUNT_MISMATCH      = 'Count_Mismatch';

    // ── START ─────────────────────────────────────────────────────────────────

    public Database.QueryLocator start(
        Database.BatchableContext bc
    ) {

        return Database.getQueryLocator([

            SELECT Id,
                   Renewal_Yrs_2__c,
                   Renewal_Yrs_2_5__c,
                   Renewal_Yrs_6_10__c,
                   Renewal_Yrs_11_30__c,
                   Service_Fees_Yrs_11__c,
                   Extended_Renewal_Percentage__c

            FROM Product_State__c
        ]);
    }

    // ── EXECUTE ───────────────────────────────────────────────────────────────

    public void execute(
        Database.BatchableContext bc,
        List<Product_State__c> psRecords
    ) {

        Set<Id> psIds =
            new Map<Id, Product_State__c>(
                psRecords
            ).keySet();

        // ── Fetch Renewal Schedules ───────────────────────────────────

        Map<String, List<Renewal_Schedule__c>>
            schedulesByKey =
                new Map<String,
                    List<Renewal_Schedule__c>>();

        for (Renewal_Schedule__c rs : [

            SELECT Id,
                   Product_State__c,
                   Schedule_Type__c,
                   Percentage__c,
                   Year_From__c,
                   Year_To__c,
                   Sort_Order__c,
                   Active__c

            FROM Renewal_Schedule__c

            WHERE Product_State__c IN :psIds

            ORDER BY Product_State__c,
                     Schedule_Type__c,
                     Sort_Order__c ASC
        ]) {

            String key =
                rs.Product_State__c +
                '|' +
                rs.Schedule_Type__c;

            if (!schedulesByKey.containsKey(key)) {

                schedulesByKey.put(
                    key,
                    new List<Renewal_Schedule__c>()
                );
            }

            schedulesByKey.get(key).add(rs);
        }

        // ── Store logs only for current chunk ─────────────────────────

        List<Commission_Import_Log__c> allLogs =
            new List<Commission_Import_Log__c>();

        // ── Process Product States ────────────────────────────────────

        for (Product_State__c ps : psRecords) {

            Boolean hasLegacy =
                hasAnyLegacyField(ps);

            Boolean hasSchedule =
                hasAnySchedule(
                    ps.Id,
                    schedulesByKey
                );

            Integer totalLegacyFieldsPopulated =
                countPopulatedLegacyFields(ps);

            Integer totalRenewalScheduleRecords =
                countSchedulesForPs(
                    ps.Id,
                    schedulesByKey
                );

            // Validation 1 — Functional equivalence

            allLogs.addAll(
                runFunctionalEquivalence(
                    ps,
                    schedulesByKey
                )
            );

            // Validation 2 — Structural rules

            allLogs.addAll(
                runStructuralValidation(
                    ps,
                    schedulesByKey,
                    hasLegacy
                )
            );

            // Validation 3 — Count checks

            if (
                hasLegacy != hasSchedule
            ) {

                allLogs.add(
                    makeLog(
                        ps.Id,
                        'STRUCTURAL',
                        'All',
                        null,
                        null,
                        DT_COUNT_MISMATCH,
                        'Legacy/Schedule existence mismatch'
                    )
                );
            }

            if (
                totalLegacyFieldsPopulated !=
                totalRenewalScheduleRecords
            ) {

                allLogs.add(
                    makeLog(
                        ps.Id,
                        'STRUCTURAL',
                        'All',
                        Decimal.valueOf(
                            totalLegacyFieldsPopulated
                        ),
                        Decimal.valueOf(
                            totalRenewalScheduleRecords
                        ),
                        DT_COUNT_MISMATCH,
                        'Legacy field count does not match schedule count'
                    )
                );
            }
        }

        // ── Insert logs immediately for this chunk only ───────────────

        if (!allLogs.isEmpty()) {

            insert allLogs;
        }
    }

    // ── FINISH ────────────────────────────────────────────────────────────────

    public void finish(
        Database.BatchableContext bc
    ) {

        System.debug(
            'RenewalScheduleMigrationValidationBatch COMPLETED SUCCESSFULLY'
        );
    }

    // ══════════════════════════════════════════════════════════════════════════
    // VALIDATION 1 — Functional equivalence
    // ══════════════════════════════════════════════════════════════════════════

    private List<Commission_Import_Log__c>
        runFunctionalEquivalence(

        Product_State__c ps,

        Map<String,
            List<Renewal_Schedule__c>>
                schedulesByKey
    ) {

        List<Commission_Import_Log__c>
            results =
                new List<Commission_Import_Log__c>();

        for (
            Integer year = YEAR_MIN;
            year <= YEAR_MAX;
            year++
        ) {

            for (
                String schedType :
                getScheduleTypesForYear(year)
            ) {

                Decimal oldVal =
                    getOldValue(
                        ps,
                        year,
                        schedType
                    );

                Decimal newVal =
                    getNewValue(
                        ps.Id,
                        year,
                        schedType,
                        schedulesByKey
                    );

                if (
                    oldVal != null &&
                    newVal != null
                ) {

                    if (
                        (oldVal - newVal).abs()
                        > TOLERANCE
                    ) {

                        results.add(
                            makeLog(
                                ps.Id,
                                String.valueOf(year),
                                schedType,
                                oldVal,
                                newVal,
                                DT_VALUE_MISMATCH,
                                'Difference exceeds tolerance'
                            )
                        );
                    }
                }

                else if (
                    oldVal != null &&
                    newVal == null
                ) {

                    results.add(
                        makeLog(
                            ps.Id,
                            String.valueOf(year),
                            schedType,
                            oldVal,
                            null,
                            DT_MISSING_NEW,
                            'Legacy value exists but schedule missing'
                        )
                    );
                }

                else if (
                    oldVal == null &&
                    newVal != null
                ) {

                    results.add(
                        makeLog(
                            ps.Id,
                            String.valueOf(year),
                            schedType,
                            null,
                            newVal,
                            DT_EXTRA_NEW,
                            'Schedule exists but legacy value blank'
                        )
                    );
                }
            }
        }

        return results;
    }

    // ══════════════════════════════════════════════════════════════════════════
    // VALIDATION 2 — Structural validation
    // ══════════════════════════════════════════════════════════════════════════

    private List<Commission_Import_Log__c>
        runStructuralValidation(

        Product_State__c ps,

        Map<String,
            List<Renewal_Schedule__c>>
                schedulesByKey,

        Boolean hasLegacy
    ) {

        List<Commission_Import_Log__c>
            results =
                new List<Commission_Import_Log__c>();

        for (
            String schedType :
            new List<String>{
                TYPE_RENEWAL,
                TYPE_SERVICE_FEE,
                TYPE_EXTENDED_RENEWAL
            }
        ) {

            String key =
                ps.Id + '|' + schedType;

            List<Renewal_Schedule__c>
                schedules =
                    schedulesByKey.containsKey(key)
                    ? schedulesByKey.get(key)
                    : new List<Renewal_Schedule__c>();

            for (
                Renewal_Schedule__c rs :
                schedules
            ) {

                if (
                    rs.Year_From__c != null &&
                    rs.Year_From__c < 2
                ) {

                    results.add(
                        makeLog(
                            ps.Id,
                            'STRUCTURAL',
                            schedType,
                            rs.Year_From__c,
                            null,
                            DT_INVALID_YEAR_FROM,
                            'Year_From must be >= 2'
                        )
                    );
                }

                if (
                    rs.Year_To__c != null &&
                    rs.Year_From__c != null &&
                    rs.Year_To__c <
                    rs.Year_From__c
                ) {

                    results.add(
                        makeLog(
                            ps.Id,
                            'STRUCTURAL',
                            schedType,
                            rs.Year_From__c,
                            rs.Year_To__c,
                            DT_INVALID_YEAR_TO,
                            'Year_To less than Year_From'
                        )
                    );
                }
            }

            results.addAll(
                detectOverlaps(
                    ps.Id,
                    schedType,
                    schedules
                )
            );

            if (
                hasLegacy &&
                schedules.isEmpty() &&
                legacyFieldPopulatedForType(
                    ps,
                    schedType
                )
            ) {

                results.add(
                    makeLog(
                        ps.Id,
                        'STRUCTURAL',
                        schedType,
                        null,
                        null,
                        DT_MISSING_NEW,
                        'Legacy field populated but no child schedule exists'
                    )
                );
            }
        }

        return results;
    }

    // ══════════════════════════════════════════════════════════════════════════
    // OVERLAP VALIDATION
    // ══════════════════════════════════════════════════════════════════════════

    private List<Commission_Import_Log__c>
        detectOverlaps(

        Id psId,
        String schedType,
        List<Renewal_Schedule__c> schedules
    ) {

        List<Commission_Import_Log__c>
            results =
                new List<Commission_Import_Log__c>();

        List<Renewal_Schedule__c>
            active =
                new List<Renewal_Schedule__c>();

        for (
            Renewal_Schedule__c rs :
            schedules
        ) {

            if (rs.Active__c) {

                active.add(rs);
            }
        }

        for (
            Integer i = 0;
            i < active.size();
            i++
        ) {

            for (
                Integer j = i + 1;
                j < active.size();
                j++
            ) {

                Renewal_Schedule__c a =
                    active[i];

                Renewal_Schedule__c b =
                    active[j];

                Decimal aFrom =
                    a.Year_From__c;

                Decimal aTo =
                    a.Year_To__c != null
                    ? a.Year_To__c
                    : 9999;

                Decimal bFrom =
                    b.Year_From__c;

                Decimal bTo =
                    b.Year_To__c != null
                    ? b.Year_To__c
                    : 9999;

                if (
                    aFrom <= bTo &&
                    bFrom <= aTo
                ) {

                    results.add(
                        makeLog(
                            psId,
                            'STRUCTURAL',
                            schedType,
                            null,
                            null,
                            DT_OVERLAP,
                            'Overlapping active ranges found'
                        )
                    );
                }
            }
        }

        return results;
    }

    // ══════════════════════════════════════════════════════════════════════════
    // OLD VALUE LOGIC
    // ══════════════════════════════════════════════════════════════════════════

    private Decimal getOldValue(
        Product_State__c ps,
        Integer year,
        String schedType
    ) {

        if (schedType == TYPE_RENEWAL) {

            if (year == 2) {

                return ps.Renewal_Yrs_2__c != null
                    ? ps.Renewal_Yrs_2__c
                    : ps.Renewal_Yrs_2_5__c;
            }

            if (
                year >= 3 &&
                year <= 5
            ) {

                return ps.Renewal_Yrs_2_5__c;
            }

            if (
                year >= 6 &&
                year <= 10
            ) {

                return ps.Renewal_Yrs_6_10__c;
            }

            if (
                year >= 11 &&
                year <= 30
            ) {

                return ps.Renewal_Yrs_11_30__c;
            }

            if (
                year >= 31 &&
                year <= 50
            ) {

                return ps.Extended_Renewal_Percentage__c;
            }
        }

        else if (
            schedType ==
            TYPE_SERVICE_FEE
        ) {

            if (
                year >= 11 &&
                year <= 50
            ) {

                return ps.Service_Fees_Yrs_11__c;
            }
        }

        else if (
            schedType ==
            TYPE_EXTENDED_RENEWAL
        ) {

            if (
                year >= 31 &&
                year <= 50
            ) {

                return ps.Extended_Renewal_Percentage__c;
            }
        }

        return null;
    }

    // ══════════════════════════════════════════════════════════════════════════
    // NEW VALUE LOGIC
    // ══════════════════════════════════════════════════════════════════════════

    private Decimal getNewValue(

        Id psId,
        Integer policyYear,
        String schedType,

        Map<String,
            List<Renewal_Schedule__c>>
                schedulesByKey
    ) {

        String key =
            psId + '|' + schedType;

        List<Renewal_Schedule__c>
            schedules =
                schedulesByKey.containsKey(key)
                ? schedulesByKey.get(key)
                : new List<Renewal_Schedule__c>();

        for (
            Renewal_Schedule__c rs :
            schedules
        ) {

            if (!rs.Active__c) {
                continue;
            }

            if (
                rs.Year_From__c == null ||
                rs.Year_From__c >
                policyYear
            ) {
                continue;
            }

            if (
                rs.Year_To__c != null &&
                rs.Year_To__c <
                policyYear
            ) {
                continue;
            }

            return rs.Percentage__c;
        }

        return null;
    }

    // ══════════════════════════════════════════════════════════════════════════
    // LOG BUILDER
    // ══════════════════════════════════════════════════════════════════════════

    private Commission_Import_Log__c makeLog(

        Id psId,
        String policyYear,
        String scheduleType,
        Decimal oldValue,
        Decimal newValue,
        String discrepancyType,
        String notes
    ) {

        String errorDetail =
            'Product_State: ' + psId +
            ' | Policy Year: ' + policyYear +
            ' | Schedule Type: ' + scheduleType +
            ' | Discrepancy: ' + discrepancyType +
            ' | Old Value: ' + oldValue +
            ' | New Value: ' + newValue;

        return new Commission_Import_Log__c(

            Source_Type__c       = 'Manual',
            Filename__c          = scheduleType,
            Processing_Status__c = 'Failed',
            Import_Date__c       = System.now(),
            Error_Details__c     = errorDetail,
            Notes__c             = notes
        );
    }

    // ══════════════════════════════════════════════════════════════════════════
    // HELPERS
    // ══════════════════════════════════════════════════════════════════════════

    private List<String>
        getScheduleTypesForYear(
            Integer year
    ) {

        if (
            year >= 2 &&
            year <= 10
        ) {

            return new List<String>{
                TYPE_RENEWAL
            };
        }

        if (
            year >= 11 &&
            year <= 30
        ) {

            return new List<String>{
                TYPE_RENEWAL,
                TYPE_SERVICE_FEE
            };
        }

        if (
            year >= 31 &&
            year <= 50
        ) {

            return new List<String>{
                TYPE_RENEWAL,
                TYPE_SERVICE_FEE,
                TYPE_EXTENDED_RENEWAL
            };
        }

        return new List<String>();
    }

    private Boolean hasAnyLegacyField(
        Product_State__c ps
    ) {

        return
            ps.Renewal_Yrs_2__c != null
            ||
            ps.Renewal_Yrs_2_5__c != null
            ||
            ps.Renewal_Yrs_6_10__c != null
            ||
            ps.Renewal_Yrs_11_30__c != null
            ||
            ps.Service_Fees_Yrs_11__c != null
            ||
            ps.Extended_Renewal_Percentage__c != null;
    }

    private Boolean hasAnySchedule(

        Id psId,

        Map<String,
            List<Renewal_Schedule__c>>
                schedulesByKey
    ) {

        for (
            String schedType :
            new List<String>{
                TYPE_RENEWAL,
                TYPE_SERVICE_FEE,
                TYPE_EXTENDED_RENEWAL
            }
        ) {

            String key =
                psId + '|' + schedType;

            if (
                schedulesByKey.containsKey(key)
                &&
                !schedulesByKey.get(key).isEmpty()
            ) {

                return true;
            }
        }

        return false;
    }

    private Boolean legacyFieldPopulatedForType(
        Product_State__c ps,
        String schedType
    ) {

        if (
            schedType ==
            TYPE_RENEWAL
        ) {

            return
                ps.Renewal_Yrs_2__c != null
                ||
                ps.Renewal_Yrs_2_5__c != null
                ||
                ps.Renewal_Yrs_6_10__c != null
                ||
                ps.Renewal_Yrs_11_30__c != null;
        }

        if (
            schedType ==
            TYPE_SERVICE_FEE
        ) {

            return
                ps.Service_Fees_Yrs_11__c != null;
        }

        if (
            schedType ==
            TYPE_EXTENDED_RENEWAL
        ) {

            return
                ps.Extended_Renewal_Percentage__c != null;
        }

        return false;
    }

    private Integer countPopulatedLegacyFields(
        Product_State__c ps
    ) {

        Integer count = 0;

        if (ps.Renewal_Yrs_2__c != null) count++;
        if (ps.Renewal_Yrs_2_5__c != null) count++;
        if (ps.Renewal_Yrs_6_10__c != null) count++;
        if (ps.Renewal_Yrs_11_30__c != null) count++;
        if (ps.Service_Fees_Yrs_11__c != null) count++;
        if (ps.Extended_Renewal_Percentage__c != null) count++;

        return count;
    }

    private Integer countSchedulesForPs(

        Id psId,

        Map<String,
            List<Renewal_Schedule__c>>
                schedulesByKey
    ) {

        Integer count = 0;

        for (
            String schedType :
            new List<String>{
                TYPE_RENEWAL,
                TYPE_SERVICE_FEE,
                TYPE_EXTENDED_RENEWAL
            }
        ) {

            String key =
                psId + '|' + schedType;

            if (
                schedulesByKey.containsKey(key)
            ) {

                count +=
                    schedulesByKey
                        .get(key)
                        .size();
            }
        }

        return count;
    }
}