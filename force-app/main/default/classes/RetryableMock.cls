public virtual class RetryableMock extends Retryable {
    private Logger log = new Logger(RetryableMock.class.getName());
    private final Boolean succeeds;
    private final String jobName;
    private final Retryable.Status resultStatus;

    static Integer jobCount = 0;

    public static RetryableMock newInstance(Boolean succeeds) {
        jobCount++;
        return new RetryableMock(succeeds, 'Job ' + jobCount);
    }

    public static RetryableMock newInstance(Retryable.Status expectedStatus) {
        jobCount++;
        return new RetryableMock(expectedStatus, 'Job ' + jobCount);
    }

    protected RetryableMock(Retryable.Status status, String jobName) {
        this.jobName = jobName;
        this.resultStatus = status;
        firstExecution = Datetime.newInstance(2019, 1, 1, 8, 0, 0);
        retryScheduleInMinutes = new List<Integer>{5,10,30};
    }

    protected RetryableMock(Boolean succeeds, String jobName) {
        this.succeeds = succeeds;
        this.jobName = jobName;
        firstExecution = Datetime.newInstance(2019, 1, 1, 8, 0, 0);
        retryScheduleInMinutes = new List<Integer>{5,10,30};
    }

    protected virtual override JobResult startJob() {
        log.d(jobName + ' STARTED!');
        if (resultStatus != null){
            return new JobResult(resultStatus, 'Mock result');
        }
        return succeeds
                ? JobResult.success('Mock Job Success')
                : JobResult.retry('Mock Job Failed');
    }


}
