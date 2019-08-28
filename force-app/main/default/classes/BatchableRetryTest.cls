@IsTest
public with sharing class BatchableRetryTest {
    static Logger log = new Logger(BatchableRetryTest.class.getName());


    private static void insertSucceededJob(Retryable job) {
        insertJob(job, Retryable.Status.SUCCEEDED, 1);
    }

    private static void insertJob(Retryable job, Retryable.Status status, Integer count) {
        List<Retryable> jobs = new List<Retryable>{
                job
        };
        insertJobs(jobs, status, count);
    }

    private static void insertJobs(List<Retryable> jobs, Retryable.Status status, Integer count) {
        List<RetryableJob__c> jobsToInsert = new List<RetryableJob__c>();
        for (Retryable job : jobs) {
            String serializedJob = JSON.serialize(job);
            String className = String.valueOf(job).split(':')[0];
            RetryableJob__c failedJob = new RetryableJob__c(
                    count__c = count,
                    className__c = className,
                    serializedJob__c = serializedJob,
                    nextTry__c = job.getFirstExecution(),
                    firstTry__c = job.getFirstExecution(),
                    status__c = status.name()
            );
            jobsToInsert.add(failedJob);
        }

        insert jobsToInsert;
    }

    @IsTest
    static void no_jobs_waiting() {
        RetryableMock job = RetryableMock.newInstance(true);
        insertSucceededJob(job);
        Test.startTest();
        BatchableRetry batch = new BatchableRetry();
        Database.executeBatch(batch, 1);
        Test.stopTest();
        List<RetryableJob__c> failedCallouts = [
                SELECT Id, nextTry__c, status__c
                FROM RetryableJob__c
        ];
        System.assert(failedCallouts.size() == 1);
        System.assert(failedCallouts[0].status__c == Retryable.Status.SUCCEEDED.name());
    }


    @IsTest
    static void all_jobs_succeed() {
        Integer numberOfJobs = 200;
        List<Retryable> jobs = new List<Retryable>();
        for (Integer i = 0; i < numberOfJobs; i++) {
            RetryableMock job = RetryableMock.newInstance(true);
            jobs.add(job);
        }
        insertJobs(jobs, Retryable.Status.FAILED_RETRY, 0);
        Test.startTest();
        BatchableRetry batch = new BatchableRetry();
        Database.executeBatch(batch, numberOfJobs);
        Test.stopTest();
        List<RetryableJob__c> succeededJobs = [
                SELECT Id, nextTry__c, status__c, firstTry__c
                FROM RetryableJob__c
        ];
        System.assert(succeededJobs.size() == numberOfJobs);
        for (RetryableJob__c callout : succeededJobs) {
            System.assert(callout.status__c == Retryable.Status.SUCCEEDED.name());
        }
    }

    @IsTest
    static void all_jobs_fail() {
        Integer numberOfJobs = 100;
        List<Retryable> jobs = new List<Retryable>();
        for (Integer i = 0; i < numberOfJobs; i++) {
            RetryableMock job = RetryableMock.newInstance(false);
            jobs.add(job);
        }
        insertJobs(jobs, Retryable.Status.FAILED_RETRY, 1);
        Test.startTest();
        BatchableRetry batch = new BatchableRetry();
        Database.executeBatch(batch, 200);
        Test.stopTest();
        List<RetryableJob__c> failedJobs = [
                SELECT Id, nextTry__c, count__c, status__c, firstTry__c
                FROM RetryableJob__c
                WHERE status__c = :Retryable.Status.FAILED_RETRY.name()
        ];
        System.assertEquals( numberOfJobs, failedJobs.size());
        RetryableJob__c job = failedJobs[0];
        System.assertEquals(2, job.count__c);
        System.assertEquals(jobs[0].getFirstExecution().addMinutes(10), job.nextTry__c);
    }

    @IsTest
    static void callouts_returning_failed_retry_status() {
        Retryable.Status expectedStatus = Retryable.Status.FAILED_RETRY;
        Integer batchSize = 10;
        insertCallouts(batchSize, expectedStatus);
        Test.startTest();
        HttpCalloutMock mock = new HTTPMockFactory(501, 'NOK', '{"response":"A retryable error occurred"}', new Map<String, String>());
        Test.setMock(HttpCalloutMock.class, mock);
        BatchableRetry batch = new BatchableRetry();
        Database.executeBatch(batch, batchSize);
        Test.stopTest();
        List<RetryableJob__c> failedCallOuts = [
                SELECT Id, nextTry__c, count__c
                FROM RetryableJob__c
                WHERE status__c = :expectedStatus.name()
        ];
        System.assertEquals(batchSize, failedCallOuts.size());
    }

    @IsTest
    static void callouts_returning_action_required() {
        Retryable.Status expectedStatus = Retryable.Status.FAILED_ACTION_REQUIRED;
        Integer batchSize = 10;
        insertCallouts(batchSize, expectedStatus);
        Test.startTest();
        HttpCalloutMock mock = new HTTPMockFactory(401, 'NOK', '{"response":"Authorization required"}', new Map<String, String>());
        Test.setMock(HttpCalloutMock.class, mock);
        BatchableRetry batch = new BatchableRetry();
        Database.executeBatch(batch, batchSize);
        Test.stopTest();
        List<RetryableJob__c> failedCallOuts = [
                SELECT Id, nextTry__c, count__c
                FROM RetryableJob__c
                WHERE status__c = :expectedStatus.name()
        ];
        System.assertEquals(batchSize, failedCallOuts.size());
    }

    @IsTest
    static void callouts_returning_succeeded() {
        Retryable.Status expectedStatus = Retryable.Status.SUCCEEDED;
        Integer batchSize = 10;
        insertCallouts(batchSize, expectedStatus);
        Test.startTest();
        HttpCalloutMock mock = new HTTPMockFactory(201, 'OK', '{"response":"all done"}', new Map<String, String>());
        Test.setMock(HttpCalloutMock.class, mock);
        BatchableRetry batch = new BatchableRetry();
        Database.executeBatch(batch, batchSize);
        Test.stopTest();
        List<RetryableJob__c> failedCallOuts = [
                SELECT Id, nextTry__c, count__c
                FROM RetryableJob__c
                WHERE status__c = :expectedStatus.name()
        ];
        System.assertEquals(batchSize, failedCallOuts.size());
    }

    private static void insertCallouts(Integer count, Retryable.Status status) {
        List<Retryable> jobs = new List<Retryable>();
        for (Integer i = 0; i < count; i++) {
            Retryable job = new RetryableMockCallout();
            jobs.add(job);
        }
        insertJobs(jobs, Retryable.Status.FAILED_RETRY, 1);
    }
}
