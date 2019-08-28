public with sharing class RetryScheduler {

    private static final String JOB_PREFIX = 'RetryBatch@';
    private static final Integer MAX_CALLOUTS_IN_SINGLE_TRANSACTION = 100;
    private static final Integer MINUTES_FROM_NOW = 5;
    private static final Logger LOG = new Logger(RetryScheduler.class.getName());

    public static String schedule(Integer minutesFromNow) {
        List<CronTrigger> cronTriggers = [
                SELECT Id, NextFireTime, CronJobDetail.Name
                FROM CronTrigger
                WHERE CronJobDetail.Name LIKE :'%' + JOB_PREFIX + '%' AND NextFireTime != NULL
        ];
        return cronTriggers.isEmpty()
                ? scheduleNewBatch(minutesFromNow)
                : cronTriggers[0].Id;
    }

    private static String scheduleNewBatch(Integer minutesFromNow) {
        LOG.d('SCHEDULING NEW JOB');
        BatchableRetry batchJob = new BatchableRetry();
        String jobDescription = JOB_PREFIX + System.now();
        return System.scheduleBatch(batchJob, jobDescription, minutesFromNow, MAX_CALLOUTS_IN_SINGLE_TRANSACTION);
    }

    public static String schedule() {
        return schedule(MINUTES_FROM_NOW);
    }
}