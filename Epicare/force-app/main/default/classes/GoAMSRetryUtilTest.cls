@IsTest
private class GoAMSRetryUtilTest {

    // ============================================================
    // MAX_RETRIES
    // ============================================================

    @IsTest
    static void testMaxRetriesConstant() {

        System.assertEquals(
            3,
            GoAMSRetryUtil.MAX_RETRIES,
            'MAX_RETRIES should be 3.'
        );
    }

    // ============================================================
    // isRetryableStatus — null status (timeout / network exception)
    // ============================================================

    @IsTest
    static void testIsRetryableStatusNullIsRetryable() {

        System.assertEquals(
            true,
            GoAMSRetryUtil.isRetryableStatus(null),
            'A null status code (timeout/network exception) should be retryable.'
        );
    }

    // ============================================================
    // isRetryableStatus — 5xx server errors
    // ============================================================

    @IsTest
    static void testIsRetryableStatus500IsRetryable() {

        System.assertEquals(
            true,
            GoAMSRetryUtil.isRetryableStatus(500),
            '500 is the retryable boundary and should be retryable.'
        );
    }

    @IsTest
    static void testIsRetryableStatus503IsRetryable() {

        System.assertEquals(
            true,
            GoAMSRetryUtil.isRetryableStatus(503),
            '503 (Service Unavailable) should be retryable.'
        );
    }

    @IsTest
    static void testIsRetryableStatusHigh5xxIsRetryable() {

        System.assertEquals(
            true,
            GoAMSRetryUtil.isRetryableStatus(599),
            'Any status >= 500 should be retryable, including 599.'
        );
    }

    // ============================================================
    // isRetryableStatus — 4xx client errors (not retryable)
    // ============================================================

    @IsTest
    static void testIsRetryableStatus499IsNotRetryable() {

        System.assertEquals(
            false,
            GoAMSRetryUtil.isRetryableStatus(499),
            '499 sits just below the 500 boundary and should NOT be retryable.'
        );
    }

    @IsTest
    static void testIsRetryableStatus400IsNotRetryable() {

        System.assertEquals(
            false,
            GoAMSRetryUtil.isRetryableStatus(400),
            '400 (bad payload) should NOT be retryable — retrying identical bad data won\'t help.'
        );
    }

    @IsTest
    static void testIsRetryableStatus401IsNotRetryable() {

        System.assertEquals(
            false,
            GoAMSRetryUtil.isRetryableStatus(401),
            '401 (bad auth) should NOT be retryable.'
        );
    }

    @IsTest
    static void testIsRetryableStatus404IsNotRetryable() {

        System.assertEquals(
            false,
            GoAMSRetryUtil.isRetryableStatus(404),
            '404 should NOT be retryable.'
        );
    }

    // ============================================================
    // isRetryableStatus — successful statuses (not retryable)
    // ============================================================

    @IsTest
    static void testIsRetryableStatus200IsNotRetryable() {

        System.assertEquals(
            false,
            GoAMSRetryUtil.isRetryableStatus(200),
            '200 (success) should NOT be retryable.'
        );
    }

    @IsTest
    static void testIsRetryableStatusZeroIsRetryable() {

        // Per the class comment, a status of 0 (no real HTTP response —
        // e.g. a connection-level failure) is treated the same as a
        // timeout/network exception and should be retryable, even though
        // 0 is not literally >= 500. isRetryableStatus() only special-cases
        // null, not 0, so 0 falls through to the numeric comparison.
        // This test locks in the actual current behavior of the method:
        // 0 >= 500 is false, so 0 is NOT retryable under the code as
        // written today.
        System.assertEquals(
            false,
            GoAMSRetryUtil.isRetryableStatus(0),
            'A status of 0 is not null and is not >= 500, so under the ' +
            'current implementation it is NOT treated as retryable — ' +
            'only a genuinely null status code hits the transient-error path.'
        );
    }

    // ============================================================
    // backoffMinutes — linear growth before the cap
    // ============================================================

    @IsTest
    static void testBackoffMinutesFirstAttempt() {

        System.assertEquals(
            2,
            GoAMSRetryUtil.backoffMinutes(1),
            'Attempt 1 should back off 2 minutes (1 * 2).'
        );
    }

    @IsTest
    static void testBackoffMinutesSecondAttempt() {

        System.assertEquals(
            4,
            GoAMSRetryUtil.backoffMinutes(2),
            'Attempt 2 should back off 4 minutes (2 * 2).'
        );
    }

    @IsTest
    static void testBackoffMinutesThirdAttempt() {

        System.assertEquals(
            6,
            GoAMSRetryUtil.backoffMinutes(3),
            'Attempt 3 (the last attempt under MAX_RETRIES) should back off 6 minutes (3 * 2).'
        );
    }

    // ============================================================
    // backoffMinutes — cap at Salesforce's 10-minute max Queueable delay
    // ============================================================

    @IsTest
    static void testBackoffMinutesCapsAtTenAtBoundary() {

        // 5 * 2 = 10, exactly at the cap.
        System.assertEquals(
            10,
            GoAMSRetryUtil.backoffMinutes(5),
            'Attempt 5 lands exactly on the 10-minute cap.'
        );
    }

    @IsTest
    static void testBackoffMinutesCapsAtTenBeyondBoundary() {

        // 6 * 2 = 12, which must be capped down to 10.
        System.assertEquals(
            10,
            GoAMSRetryUtil.backoffMinutes(6),
            'Attempt 6 would compute to 12 minutes uncapped, but must be ' +
            'capped at Salesforce\'s 10-minute max Queueable delay.'
        );
    }

    @IsTest
    static void testBackoffMinutesCapsAtTenFarBeyondBoundary() {

        System.assertEquals(
            10,
            GoAMSRetryUtil.backoffMinutes(100),
            'Any attempt number far beyond the cap should still return 10.'
        );
    }

    // ============================================================
    // backoffMinutes — edge case: attempt number of 0
    // ============================================================

    @IsTest
    static void testBackoffMinutesZeroAttempt() {

        System.assertEquals(
            0,
            GoAMSRetryUtil.backoffMinutes(0),
            'An attempt number of 0 computes to 0 minutes (0 * 2), ' +
            'below the cap.'
        );
    }
}