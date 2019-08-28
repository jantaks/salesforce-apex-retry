@IsTest
public class RetryableTest {

    @IsTest
    static void job_fails_and_is_retryable() {
        RetryableMock job = RetryableMock.newInstance(false);
        job.execute(null);
        RetryableJob__c failedJob = [
                SELECT Id, firstTry__c, className__c, serializedJob__c, count__c, nextTry__c, message__c, status__c, lastTry__c
                FROM RetryableJob__c
                LIMIT 1
        ];
        System.assert(failedJob != null);
        System.assert(failedJob.firstTry__c > System.now().addMinutes(-1));
        System.assert(failedJob.className__c == RetryableMock.class.getName());
        System.assert(failedJob.serializedJob__c.contains('jobName'));
        System.assert(failedJob.count__c == 1);
        System.assert(failedJob.nextTry__c > System.now().addMinutes(4));
        System.assert(failedJob.message__c == 'Mock Job Failed');
        System.assert(failedJob.status__c == Retryable.Status.FAILED_RETRY.name());
        System.assert(failedJob.lastTry__c <= System.now());
    }

    @IsTest
    static void job_fails_and_action_is_required() {
        Retryable.Status expectedStatus = Retryable.Status.FAILED_ACTION_REQUIRED;
        RetryableMock job = RetryableMock.newInstance(expectedStatus);
        job.execute(null);
        RetryableJob__c failedJob = [
                SELECT Id, firstTry__c, className__c, serializedJob__c, count__c, nextTry__c, message__c, status__c, lastTry__c
                FROM RetryableJob__c
                LIMIT 1
        ];
        System.assert(failedJob != null);
        System.assert(failedJob.nextTry__c == null);
        System.assert(failedJob.status__c == expectedStatus.name());
    }

    @IsTest
    static void maximum_retries_exceeded() {
        RetryableMock job = RetryableMock.newInstance(false);
        JobResult result;
        while (!job.isLastTry()){
            result =  job.retry();
        }
        System.assert(result.status == Retryable.Status.MAX_RETRIES);
        System.assert(job.isLastTry() == true);
        System.assert(job.getNextTry() == null);
    }

    @IsTest
    static void next_retry() {
        RetryableMock job = RetryableMock.newInstance(false);
        System.assert(job.getNextTry() == null);
        job.retry();
        System.assert(job.getNextTry() == job.getFirstExecution().addMinutes(10));
        job.retry();
        System.assert(job.getNextTry() == job.getFirstExecution().addMinutes(30));
    }

}