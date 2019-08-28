public abstract class Retryable implements Queueable, Database.AllowsCallouts {

    public enum Status {
        MAX_RETRIES, FAILED_RETRY, SUCCEEDED, FAILED_ACTION_REQUIRED
    }
    protected List<Integer> retryScheduleInMinutes = new List<Integer>{
            1, 5, 10, 30, 60, 2 * 60, 4 * 60, 8 * 60, 16 * 60, 24 * 60
    };
    protected Datetime firstExecution;
    protected Integer retryCount = 0;
    private Datetime nextRetry;

    public void execute(QueueableContext context) {
        firstExecution = System.now();
        JobResult result = startJob();
        RetryScheduler.schedule();
        insertJob(result);
    }

    public JobResult retry() {
        retryCount++;
        nextRetry = isLastTry()
                ? null
                : firstExecution.addMinutes(retryScheduleInMinutes.get(retryCount));
        return isLastTry()
                ? JobResult.maximumRetries(startJob().message)
                : startJob();
    }

    protected abstract JobResult startJob();

    private void insertJob(JobResult result) {
        insert new RetryableJob__c(
                serializedJob__c = JSON.serialize(this),
                className__c = String.valueOf(this).split(':')[0],
                firstTry__c = System.now(),
                lastTry__c = System.now(),
                count__c = 1,
                nextTry__c = result.status == Retryable.Status.FAILED_RETRY
                        ? System.now().addMinutes(retryScheduleInMinutes.get(0))
                        : null,
                message__c = result.message,
                status__c = result.status.name()
        );
    }

    public Datetime getFirstExecution() {
        return firstExecution;
    }

    public Datetime getNextTry() {
        return nextRetry;
    }

    public Boolean isLastTry() {
        return retryCount >= retryScheduleInMinutes.size();
    }
}