@IsTest
private class HighlightBadgesController_Test {
    
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
    static void testGetBadges() {
        Contact ct = [SELECT Id, (SELECT Id, CaseNumber FROM Cases WHERE IsClosed = false) FROM Contact LIMIT 1];
        Assert.isFalse(ct.Cases.isEmpty(), 'Test contact should have an open case');

        User u = TestDataFactory.createTestUser('Rey', 'Ordonez', 'Admin');
        Test.startTest();
        System.runAs(u) {
            List<HighlightBadge> lstBadges = HighlightBadgesController.getBadges(ct.Id, 'Contact', null);
            Test.stopTest();
            Assert.isFalse(lstBadges.isEmpty(), 'Should have received a badge');
            HighlightBadge openCaseBadge = new HighlightBadge();
            for (HighlightBadge badge : lstBadges) {
                if (badge.recordId == ct.Cases[0].Id) {
                    openCaseBadge = badge;
                }
            }
            Assert.isTrue(
                openCaseBadge.label.contains(ct.Cases[0].CaseNumber), 
                'The badge label should include the open case number'
            );
        }
    }

}