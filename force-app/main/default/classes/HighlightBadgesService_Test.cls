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
    static void testGetCommonAncestorBadge() {
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
                'Should have received a badge for opportunities over $100 from the ancestor account'
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
                        Common_Ancestor_Object__c = 'Account', 
                        Source_to_Ancestor_Path__c = 'AccountId', 
                        Display_to_Ancestor_Path__c = 'AccountId', 
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

    @IsTest
    static void testNoFieldSet() {
        Contact ct = [SELECT Id FROM Contact LIMIT 1];
        User u = TestDataFactory.createTestUser('Rey', 'Ordonez', 'Admin');

        List<HighlightBadge> lstBadges;
        Test.startTest();
        System.runas(u) {
            List<Highlight_Badge_Definition__c> lstDefinitions = [SELECT Id, Source_Detail_Fields__c FROM Highlight_Badge_Definition__c];
            for (Highlight_Badge_Definition__c hbd : lstDefinitions) {
                hbd.Source_Detail_Fields__c = '';
            }
            update lstDefinitions;

            HighlightBadgesService service = new HighlightBadgesService(
                ct.Id, 
                'Contact'
            );
            lstBadges = service.getBadges();
        }
        Test.stopTest();

        for (HighlightBadge badge : lstBadges) {
            if (badge.sObjectType == HighlightBadgesService.SOBJECT_CASE) {
                Assert.areEqual('CaseNumber', badge.fieldSet, 'Should have received default case field set');
            } else {
                Assert.areEqual('Name', badge.fieldSet, 'Should have received default field set');
            }
        }
    }

    @IsTest
    static void testNoDefinitions() {
        User u = TestDataFactory.createTestUser('Rey', 'Ordonez', 'Admin');
        Contact ct = [SELECT Id FROM Contact LIMIT 1];
        List<HighlightBadge> lstBadges;
        Test.startTest();
        System.runAs(u) {
            delete [SELECT Id FROM Highlight_Badge_Definition__c];
            HighlightBadgesService service = new HighlightBadgesService(
                ct.Id, 
                'Contact'
            );
            lstBadges = service.getBadges();
        }
        Test.stopTest();
        Assert.isTrue(lstBadges.isEmpty(), 'Should not have received any badges');
    }

    @IsTest 
    static void testComplexFieldPath() {
        User u = TestDataFactory.createTestUser('Rey', 'Ordonez', 'Admin');

        // Get contacts with child cases and opportunities
        Contact ct = [
            SELECT Id, AccountId,
                   (SELECT Id FROM Cases),
                   (SELECT Id FROM Opportunities)
              FROM Contact 
             LIMIT 1
        ];

        List<HighlightBadge> lstBadges;
        Test.startTest();
        System.runAs(u) {
            HighlightBadgesService service = new HighlightBadgesService(
                ct.Cases[0].Id,
                'Case'
            );
            lstBadges = service.getBadges();
        }
        Test.stopTest();

        Assert.isFalse(lstBadges.isEmpty(), 'List of badges should not be empty');
        Assert.areEqual('Opportunity', lstBadges[0].sObjectType, 'Should have received the opportunity badge with the shared account');
    }

    @IsTest
    static void testOncePerSessionAlert() {
        Contact ct = [SELECT Id, (SELECT Id FROM Opportunities WHERE Amount > 100) FROM Contact LIMIT 1];

        User u = TestDataFactory.createTestUser('Rey', 'Ordonez', 'Admin');

        HighlightBadge badge;
        HighlightBadge refreshedBadge;
        Test.startTest();
        System.runAs(u) {
            HighlightBadgesService service = new HighlightBadgesService(
                ct.Id,
                'Contact'
            );
            List<HighlightBadge> lstBadges = service.getBadges();
            for (HighlightBadge bdg : lstBadges) {
                if (bdg.recordId == ct.Opportunities[0].Id) {
                    badge = bdg;
                }
            }

            // Call a second time to confirm token is in platform cache
            List<HighlightBadge> lstRefreshedBadges = service.getBadges();
            for (HighlightBadge bdg : lstRefreshedBadges) {
                if (bdg.recordId == ct.Opportunities[0].Id) {
                    refreshedBadge = bdg;
                }
            }
        }
        Test.stopTest();

        Assert.isTrue(badge.hasAlert, 'The first request should have an alert');
        Assert.isFalse(refreshedBadge.hasAlert, 'The second request should not have an alert');
    }

    @IsTest
    static void testToastAlert() {
        
    }

    @IsTest
    static void testModalAlert() {
        
    }

}