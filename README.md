### Salesforce APEX Retry framework

This is an easy-to-use, yet powerful framework to add retry logic to your classes. I wrote it specifically for webservice callouts but it can be used for other (distributed) jobs that have some chance of failing. 

A custom object provides the ability to monitor the state of your retryable jobs. For instance, you can quickly find the last result and the next scheduled retry. 

It is easy to implement your own retry schedule by overriding the provided base schedule. Schedules are set in minutes after the first execution. For example, if the first execution was at 8:00 and you have set your schedule to {1,5,10,30} the first retry will be close to 8:01, the second retry close to 8:05, the third close to 8:10 and so forth. 

The retries are selected in a batch job. The exact timing of the retries depends on how frequent the batch job is run. By default, the batch runs every 5 minutes. 

I would love to hear your feedback and suggestions for improvement.

### How to use

Simply extend the abstract class `Retryable` and implement `protected abstract JobResult startJob();`. If the status of JobResult is `FAILED_RETRY` the framework will retry the job at the specified interval. 

`Retryable` implement `Queueable` so your job should be run asynchronously. For the example below this means:
```apex
System.enqueueJob(new SomeCalloutRetryable('"Post":"This is my Post"'));
```
The project has 100% test coverage. For more implementation details see the Test classes. 

### Example implementation: 

```apex
public with sharing class SomeCalloutRetryable extends Retryable {

    private final String body;

    public SomeCalloutRetryable(String body) {
        this.body = body;
        retryScheduleInMinutes = new List<Integer>{1, 5, 25, 60, 2*60}; //OVERRIDE DEFAULT RETRY SCHEDULE
    }

    public override JobResult startJob() {
        log.d('Started MockCallout');
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:YOUR_SERVICE_ENDPOINT');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        request.setBody(this.body);
        HttpResponse response = http.send(request);
        Integer httpResponseCode = response.getStatusCode();
        switch on httpResponseCode{
            when 200,201{
                return JobResult.success(response.getBody());
            }
            when 401{
                return JobResult.actionRequired(response.getBody());
            }
            when else {
                return JobResult.retry(response.getBody());
            }
        }
    }
}

```
