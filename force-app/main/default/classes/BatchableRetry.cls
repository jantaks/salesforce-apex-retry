public with sharing class BatchableRetry implements Database.Batchable<SObject>, Database.AllowsCallouts {

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator([
                SELECT className__c, count__c, serializedJob__c, nextTry__c, firstTry__c
                FROM RetryableJob__c
                WHERE nextTry__c < :System.now()
                AND status__c = :Retryable.Status.FAILED_RETRY.name()
        ]);
    }

    public void execute(Database.BatchableContext context, List<SObject> jobs) {
        List<RetryableJob__c> jobsToUpdate = new List<RetryableJob__c>();
        for (Sobject job : jobs) {
            RetryableJob__c storedJob = (RetryableJob__c) job;
            Type jobType = Type.forName(storedJob.className__c);
            Retryable currentJob = (Retryable) JSON.deserialize(storedJob.serializedJob__c, jobType);
            JobResult jobResult = currentJob.retry();
            storedJob.status__c = jobResult.status.name();
            storedJob.nextTry__c = jobResult.status == Retryable.Status.FAILED_RETRY?  currentJob.getNextTry() : null;
            storedJob.lastTry__c = System.now();
            storedJob.serializedJob__c = JSON.serialize(currentJob);
            storedJob.count__c = storedJob.count__c + 1;
            storedJob.nextTry__c = currentJob.getNextTry();
            storedJob.message__c = jobResult.message;
            storedJob.status__c = jobResult.status.name();
            jobsToUpdate.add(storedJob);
        }
        update jobsToUpdate;
    }

    public void finish(Database.BatchableContext param1) {
        RetryScheduler.schedule();
    }

}