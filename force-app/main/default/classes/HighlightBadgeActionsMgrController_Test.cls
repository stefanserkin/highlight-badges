@IsTest
private class HighlightBadgeActionsMgrController_Test {

    @TestSetup
    static void makeData() {
        List<Highlight_Badge_Definition__c> lstDefinitions = TestDataFactory.getTestDefinitions();
        insert lstDefinitions;

        insert TestDataFactory.getTestActions(lstDefinitions);
    }

    @IsTest 
    static void testGetActions() {
        Highlight_Badge_Definition__c definitionWithActions = [
            SELECT Id, (SELECT Id FROM Highlight_Badge_Actions__r)
              FROM Highlight_Badge_Definition__c
             LIMIT 1
        ];

        User u = TestDataFactory.createTestUser('Rey', 'Ordonez', 'Admin');

        List<Highlight_Badge_Action__c> returnedActions;
        Test.startTest();
        System.runAs(u) {
            returnedActions = HighlightBadgeActionsMgrController.getActions(
                definitionWithActions.Id
            );
        }
        Test.stopTest();

        Assert.areEqual(
            definitionWithActions.Highlight_Badge_Actions__r.size(), 
            returnedActions.size(), 
            'Should have received all the actions for the provided definition'
        );
    }

}