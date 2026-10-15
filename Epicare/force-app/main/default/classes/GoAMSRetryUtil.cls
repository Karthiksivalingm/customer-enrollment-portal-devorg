public class GoAMSRetryUtil {

    public static final Integer MAX_RETRIES = 3;

    // HTTP 5xx and null/0 status (timeouts, network exceptions) are treated
    // as transient and get retried. HTTP 4xx means GoAMS rejected the
    // payload itself (bad data, bad auth) — retrying the identical payload
    // won't help, so those are dead-lettered immediately instead.
    public static Boolean isRetryableStatus(Integer statusCode) {
        return statusCode == null || statusCode >= 500;
    }

    // Linear backoff, capped at Salesforce's 10-minute max delay for a
    // Queueable job enqueued with System.enqueueJob(job, delayInMinutes).
    public static Integer backoffMinutes(Integer nextAttemptNumber) {
        return Math.min(nextAttemptNumber * 2, 10);
    }
}