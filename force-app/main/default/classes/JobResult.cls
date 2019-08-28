public class JobResult{

    public Retryable.Status status {get; set;}
    public String message {get; set;}

    public JobResult(Retryable.Status status, String message){
        this.status = status;
        this.message = message;
    }

    public static JobResult retry(String message){
        return new JobResult(Retryable.Status.FAILED_RETRY, message.abbreviate(255));
    }

    public static JobResult success(String message){
        return new JobResult(Retryable.Status.SUCCEEDED, message.abbreviate(255));
    }

    public static JobResult maximumRetries(String message){
        return new JobResult(Retryable.Status.MAX_RETRIES, message.abbreviate(255));
    }

    public static JobResult actionRequired(String message){
        return new JobResult(Retryable.Status.FAILED_ACTION_REQUIRED, message.abbreviate(255));
    }


}