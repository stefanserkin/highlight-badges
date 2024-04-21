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

    @IsTest
    static void testGetBadgesForPreview() {
        Contact ct = [SELECT Id, (SELECT Id, CaseNumber FROM Cases WHERE IsClosed = false) FROM Contact LIMIT 1];
        Assert.isFalse(ct.Cases.isEmpty(), 'Test contact should have an open case');

        String caseBadgeLabel = 'Open Case #{!CaseNumber}';
        Highlight_Badge_Definition__c hbd = [
            SELECT Id 
              FROM Highlight_Badge_Definition__c 
             WHERE Label__c = :caseBadgeLabel
             LIMIT 1
        ];

        User u = TestDataFactory.createTestUser('Rey', 'Ordonez', 'Admin');
        Test.startTest();
        System.runAs(u) {
            List<HighlightBadge> lstBadges = HighlightBadgesController.getBadges(ct.Id, 'Contact', hbd.Id);
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

    @IsTest
    static void testGetBadgesWithException() {
        Contact ct = [SELECT Id, (SELECT Id, CaseNumber FROM Cases WHERE IsClosed = false) FROM Contact LIMIT 1];
        String badDefinitionId = 'notAnId';

        Boolean hasException = false;

        User u = TestDataFactory.createTestUser('Rey', 'Ordonez', 'Admin');
        Test.startTest();
        System.runAs(u) {
            try {
                List<HighlightBadge> lstBadges = HighlightBadgesController.getBadges(ct.Id, 'Contact', badDefinitionId);
            } catch (Exception e) {
                hasException = true;
            }
        }
        Test.stopTest();

        Assert.isTrue(hasException, 'Should have received an exception for the invalid record id');
    }

    @IsTest
    static void testRunFlowWithException() {
        // Set flow api name to null
        String flowApiName = null;
        Map<String, Object> inputVars = new Map<String, Object>{'recordId' => TestDataFactory.getFakeId(Account.SObjectType)};
        String jsonInputVariables = JSON.serialize(inputVars);

        Boolean hasException = false;
        
        Test.startTest();
        try {
            HighlightBadgesController.runFlow(flowApiName, jsonInputVariables);
            System.assert(false, 'Method should not succeed with missing flow API name');
        } catch (Exception e) {
            hasException = true;
        }
        Test.stopTest();

        Assert.isTrue(hasException, 'Should have received an exception for the missing parameter');
    }

}