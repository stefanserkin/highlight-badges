@IsTest
private class GlobalDescribeService_Test {

    @IsTest
    static void testGetGlobalDescribe() {
        Map<String, Schema.SObjectType> gd;
        Test.startTest();
        gd = GlobalDescribeService.getGlobalDescribe();
        Test.stopTest();
        Map<String, Schema.SObjectType> expectedResult = Schema.getGlobalDescribe();
        Assert.areEqual(expectedResult, gd, 'Should have received the describe result for the account object');
    }

    @IsTest
    static void testGetGlobalDescribeFromCache() {
        Map<String, Schema.SObjectType> gd = GlobalDescribeService.getGlobalDescribe();
        Test.startTest();
        Map<String, Schema.SObjectType> refreshedDescribe = GlobalDescribeService.getGlobalDescribe();
        Test.stopTest();
        Map<String, Schema.SObjectType> expectedResult = Schema.getGlobalDescribe();
        Assert.areEqual(gd, refreshedDescribe, 'Should have received the describe result for the account object');
        Assert.areEqual(expectedResult, gd, 'Should have received the describe result for the account object');
    }

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

    @IsTest
    static void testDoesFieldExist() {
        Test.startTest();
        Boolean fieldExists = GlobalDescribeService.doesFieldExist('Account', 'Name');
        Test.stopTest();
        Assert.isTrue(fieldExists, 'Should have verified account name field');
    }

    @IsTest
    static void testDoesFieldExistNegative() {
        Test.startTest();
        Boolean fieldExists = GlobalDescribeService.doesFieldExist('Account', 'phonybalogny');
        Test.stopTest();
        Assert.isFalse(fieldExists, 'Should not have verified phonybalogny field');
    }

    @IsTest
    static void testGetSObjectNameField() {
        Test.startTest();
        String caseField = GlobalDescribeService.getSObjectNameField('Case');
        String taskField = GlobalDescribeService.getSObjectNameField('Task');
        String eventField = GlobalDescribeService.getSObjectNameField('Event');
        String oliField = GlobalDescribeService.getSObjectNameField('OpportunityLineItem');
        Test.stopTest();
        Assert.areEqual('CaseNumber', caseField, 'Received unexpected field name');
        Assert.areEqual('Subject', taskField, 'Received unexpected field name');
        Assert.areEqual('Subject', eventField, 'Received unexpected field name');
        Assert.areEqual('Name', oliField, 'Received unexpected field name');
    }

}