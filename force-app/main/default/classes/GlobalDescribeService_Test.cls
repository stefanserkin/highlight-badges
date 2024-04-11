@IsTest
private class GlobalDescribeService_Test {

    @IsTest
    static void testGetSObjectDescribe() {
        String sObjectApiName = 'Account';
        Test.startTest();
        Schema.DescribeSObjectResult result = GlobalDescribeService.getDescribe(sObjectApiName);
        Test.stopTest();
        Schema.DescribeSObjectResult expectedResult = Schema.getGlobalDescribe().get(sObjectApiName).getDescribe();
        Assert.areEqual(expectedResult, result, 'Should have received the describe result for the account object');
    }

    @IsTest
    static void testGetSObjectDescribeFromCache() {
        String sObjectApiName = 'Account';
        Schema.DescribeSObjectResult firstResult = GlobalDescribeService.getDescribe(sObjectApiName);
        Test.startTest();
        Schema.DescribeSObjectResult secondResult = GlobalDescribeService.getDescribe(sObjectApiName);
        Test.stopTest();
        Schema.DescribeSObjectResult expectedResult = Schema.getGlobalDescribe().get(sObjectApiName).getDescribe();
        Assert.areEqual(firstResult, secondResult, 'Should have received the describe result for the account object');
        Assert.areEqual(expectedResult, secondResult, 'Should have received the describe result for the account object');
    }

}