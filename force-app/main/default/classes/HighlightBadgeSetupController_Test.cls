@IsTest
private class HighlightBadgeSetupController_Test {
    
    @IsTest
    static void testGetDisplayObjects() {
        List<HighlightBadgeSetupController.ObjectSelectOption> lstOptions;
        Test.startTest();
        lstOptions = HighlightBadgeSetupController.getDisplayObjects();
        Test.stopTest();
    }

    @IsTest
    static void testGetChildObjects() {
        List<HighlightBadgeSetupController.ObjectSelectOption> lstOptions;
        Test.startTest();
        lstOptions = HighlightBadgeSetupController.getChildObjects('Account');
        Test.stopTest();
    }

    @IsTest
    static void testGetCommonParentObjects() {
        List<HighlightBadgeSetupController.ObjectSelectOption> lstOptions;
        Test.startTest();
        lstOptions = HighlightBadgeSetupController.getCommonParentObjects(
            'Contact',
            'Case'
        );
        Test.stopTest();
    }

    @IsTest
    static void testFindInverseRelationshipField() {
        Test.startTest();
        String result = HighlightBadgeSetupController.findInverseRelationshipField(
            'Contact',
            'Case',
            'Cases'
        );
        Test.stopTest();
        Assert.areEqual('contactid', result.toLowerCase(), 'Should have received the contact path from the case object');
    }

    @IsTest
    static void testGetPossibleAncestorPaths() {
        List<HighlightBadgeSetupController.AncestorRelationship> results;
        Test.startTest();
        results = HighlightBadgeSetupController.getPossibleAncestorPaths(
            'Contact',
            'Case',
            'Account'
        );
        Test.stopTest();
        Set<String> setPaths = new Set<String>();
        for (HighlightBadgeSetupController.AncestorRelationship ar : results) {
            for (String str : ar.relationships) {
                setPaths.add(str.toLowerCase());
            }
        }
        Assert.isTrue(setPaths.contains('accountid'), 'Should have found the path to the account');
    }

}