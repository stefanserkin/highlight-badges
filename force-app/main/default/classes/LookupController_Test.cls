@IsTest
private class LookupController_Test {

    @TestSetup
    static void makeData() {
        List<Account> lstAccounts = TestDataFactory.createAccounts(1);
        insert lstAccounts;

        List<Contact> lstContacts = TestDataFactory.createContacts(lstAccounts, 1);
        insert lstContacts;

        List<Case> lstCases = TestDataFactory.createCases(lstContacts, 1);
        insert lstCases;

        insert TestDataFactory.getTestDefinitions();
    }

    @IsTest
    static void testGetDefault() {
        Case cs = [SELECT Id, CaseNumber FROM Case LIMIT 1];
        Test.startTest();
        Case caseObj = (Case) LookupController.getDefault(cs.Id, 'Case');
        Test.stopTest();
        Assert.areEqual(cs.Id, caseObj.Id, 'Received incorrect case id');
        Assert.areEqual(cs.CaseNumber, caseObj.CaseNumber, 'Received incorrect case number');
    }

    @IsTest
    static void testGetDefaultWithException() {
        String invalidCaseId = 'IAmNotAnId';
        Boolean hasException = false;
        Test.startTest();
        try {
            Case caseObj = (Case) LookupController.getDefault(invalidCaseId, 'Case');
        } catch (Exception e) {
            hasException = true;
        }
        Test.stopTest();
        Assert.isTrue(hasException, 'Should have received an exception for the invalid case id');
    }

    @IsTest
    static void testSearch() {
        Account acc = [SELECT Id, Name FROM Account LIMIT 1];
        List<LookupController.LookupResult> lstResults;
        Test.startTest();
        lstResults = LookupController.search(acc.Name.left(5), 'Account', null);
        Test.stopTest();
        Assert.areEqual(acc.Id, lstResults[0].id, 'Did not receive the correct account record');
    }

    @IsTest
    static void testSearchWithoutNameField() {
        Case cs = [SELECT Id, CaseNumber FROM Case LIMIT 1];
        List<LookupController.LookupResult> lstResults;
        Test.startTest();
        lstResults = LookupController.search(cs.CaseNumber, 'Case', 'CaseNumber != NULL');
        Test.stopTest();
        Assert.areEqual(cs.Id, lstResults[0].id, 'Did not receive the correct case record');
    }

    @IsTest
    static void testSearchWithEmptyInput() {
        List<LookupController.LookupResult> lstResults;
        Test.startTest();
        lstResults = LookupController.search('', 'Account', null);
        Test.stopTest();
    }

    @IsTest
    static void testSearchWithException() {
        String invalidObject = 'NotAThing';
        Boolean hasException = false;
        Test.startTest();
        try {
            List<LookupController.LookupResult> lstResults = LookupController.search('', invalidObject, null);
            Assert.fail('Should have received an exception for the invalid object name');
        } catch (Exception e) {
            hasException = true;
        }
        Test.stopTest();
        Assert.isTrue(hasException, 'Should have received an exception');
    }

}