@IsTest
private class UtilsTest {
    @IsTest
    static void testCronFromDateTime() {
        Datetime dt = Datetime.newInstance(2019, 8,19,10,55,3);
        String result = Utils.toCronExpression(dt);
        System.assert(result == '3 55 10 19 8 ? 2019');
    }
}