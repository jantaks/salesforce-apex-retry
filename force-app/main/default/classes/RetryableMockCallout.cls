public with sharing class RetryableMockCallout extends Retryable {
    private Logger log = new Logger(RetryableMockCallout.class.getName());

    public RetryableMockCallout() {
        firstExecution = Datetime.newInstance(2019, 1, 1, 8, 0, 0);
        retryScheduleInMinutes = new List<Integer>{
                5, 10, 30
        };
    }

    public override JobResult startJob() {
        log.d('Started MockCallout');
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:YOUR_SERVICE_ENDPOINT');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        request.setBody('{"Content": "Your Content"}');
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
