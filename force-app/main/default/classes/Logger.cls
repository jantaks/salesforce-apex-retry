public with sharing class Logger {
    private String loggingObject;

    public Logger(Object loggingObject){
        this.loggingObject = String.valueOf(loggingObject).split(':')[0];
    }

    public void d(String message) {
        System.debug(String.valueOf(loggingObject).split(':')[0] + ': ' + message);
    }
}