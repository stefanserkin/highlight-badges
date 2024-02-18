@IsTest
private class HighlightBadgesService_Test {

    @TestSetup
    static void makeData() {
        List<Account> lstAccounts = TestDataFactory.createAccounts(1);
        insert lstAccounts;

        List<Contact> lstContacts = TestDataFactory.createContacts(lstAccounts, 1);
        insert lstContacts;

        List<Case> lstCases = TestDataFactory.createCases(lstContacts, 1);
        insert lstCases;

        List<Opportunity> lstOpps = TestDataFactory.createOpportunities(lstContacts, 1);
        insert lstOpps;

        insert TestDataFactory.getTestDefinitions();
    }

    @IsTest
    static void testConstructor() {
        String objType = 'Account';
        Account acc = TestDataFactory.createAccounts(1).get(0);
        insert acc;
        Test.startTest();
        HighlightBadgesService serv = new HighlightBadgesService(acc.Id, objType);
        Test.stopTest();
        Assert.areEqual(acc.Id, serv.displayRecordId, 'Should have set the display record id in the constructor');
        Assert.areEqual(objType, serv.displayObjectType, 'Should have set the display object type in the constructor');
    }

    @IsTest
    static void testGetChildBadge() {
        Contact ct = [SELECT Id, (SELECT Id, CaseNumber FROM Cases WHERE IsClosed = false) FROM Contact LIMIT 1];
        Assert.isFalse(ct.Cases.isEmpty(), 'Test contact should have an open case');

        User u = TestDataFactory.createTestUser('Rey', 'Ordonez', 'Admin');
        Test.startTest();
        System.runAs(u) {
            HighlightBadgesService serv = new HighlightBadgesService(ct.Id, 'Contact');
            List<HighlightBadge> lstBadges = serv.getBadges();

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
        Test.stopTest();
    }

    @IsTest
    static void testGetSourceBadge() {
        
    }

    @IsTest
    static void testGetCommonParentBadge() {
        Contact ct = [SELECT Id, (SELECT Id FROM Opportunities WHERE Amount > 100) FROM Contact LIMIT 1];
        Assert.isFalse(ct.Opportunities.isEmpty(), 'Test contact should have an eligible opportunity');

        User u = TestDataFactory.createTestUser('Rey', 'Ordonez', 'Admin');
        Test.startTest();
        System.runAs(u) {
            HighlightBadgesService serv = new HighlightBadgesService(ct.Id, 'Contact');
            List<HighlightBadge> lstBadges = serv.getBadges();
            Test.stopTest();
            Boolean hasOppBadge = false;
            for (HighlightBadge badge : lstBadges) {
                if (badge.recordId == ct.Opportunities[0].Id) {
                    hasOppBadge = true;
                }
            }
            Assert.isTrue(
                hasOppBadge, 
                'Should have received a badge for opportunities over $100 from the parent account'
            );
        }
    }

    @IsTest
    static void testNoBadgesForRecord() {
        
    }

    @IsTest
    static void testSOQLLimitHandling() {
        User u = TestDataFactory.createTestUser('Rey', 'Ordonez', 'Admin');

        Contact ct = [SELECT Id, (SELECT Id FROM Opportunities WHERE Amount > 100) FROM Contact LIMIT 1];
        Assert.isFalse(ct.Opportunities.isEmpty(), 'Test contact should have an eligible opportunity');

        Test.startTest();
        System.runas(u) {
            List<Highlight_Badge_Definition__c> lstDefinitions = new List<Highlight_Badge_Definition__c>();
            for (Integer i = 0; i < 101; i++) {
                lstDefinitions.add(
                    new Highlight_Badge_Definition__c(
                        Active__c = true, 
                        Name = 'Opp Over ' + String.valueOf(i), 
                        Display_Object__c = 'Contact', 
                        Source_Object__c = 'Opportunity', 
                        Common_Parent_Object__c = 'Account', 
                        Source_to_Parent_Path__c = 'AccountId', 
                        Display_to_Parent_Path__c = 'AccountId', 
                        Filter_Criteria__c = 'Amount > ' + String.valueOf(i), 
                        Source_Detail_Fields__c = 'Name, StageName, Amount', 
                        Label__c = 'Big Opp'
                    )
                );
            }
            insert lstDefinitions;

            HighlightBadgesService serv = new HighlightBadgesService(ct.Id, 'Contact');
            List<HighlightBadge> lstBadges = serv.getBadges();

            Assert.isFalse(lstBadges.isEmpty(), 'Should have received partial collection of badges');
        }
        Test.stopTest();
    }

}