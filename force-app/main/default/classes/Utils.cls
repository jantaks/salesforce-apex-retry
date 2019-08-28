public with sharing class Utils {

    public static String toCronExpression(Datetime d){
        return  d.second() + ' ' +
                d.minute() + ' ' +
                d.hour() + ' ' +
                d.day() + ' ' +
                d.month() + ' ' +
                '?' + ' ' +
                d.year();
    }
}