### Salesforce APEX Retry framework

This is a simple, yet powerful framework to add retry logic to your classes. I wrote it specifically for webservice callouts but it can be used for other (distributed) jobs that have some chance of failing. 

A custom object provides the ability to monitor the state of your retryable jobs. For instance, you can quickly find the last result and the next scheduled retry. 

It is easy to implement your own retry schedule, such as exponential backoff, by overriding the provided base schedule. Schedules are set in minutes after the first execution. For example, if the first execution was at 8:00 and you have set your schedule to {1,5,10,30} the first retry will be close to 8:01, the second retry close to 8:05, the third close to 8:10 and so forth. 

The retries are selected in a batch job. The exact timing of the retries depends on how frequent the batch job is run. By default, the batch runs every 5 minutes. 