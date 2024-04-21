@IsTest
private class HighlightBadgeSetupController_Test {
    
    @IsTest
    static void testGetDisplayObjects() {
        List<HighlightBadgeSetupService.ObjectSelectOption> lstOptions;
        Test.startTest();
        lstOptions = HighlightBadgeSetupController.getDisplayObjects();
        Test.stopTest();
    }

    @IsTest
    static void testGetChildObjects() {
        List<HighlightBadgeSetupService.ObjectSelectOption> lstOptions;
        Test.startTest();
        lstOptions = HighlightBadgeSetupController.getChildObjects('Account');
        Test.stopTest();
    }

    @IsTest
    static void testGetChildObjectsWithException() {
        String invalidObjectName = 'NotAThing';
        Boolean hasException = false;
        List<HighlightBadgeSetupService.ObjectSelectOption> lstOptions;
        Test.startTest();
        try {
            lstOptions = HighlightBadgeSetupController.getChildObjects(invalidObjectName);
        } catch (Exception e) {
            hasException = true;
        }
        Test.stopTest();
        Assert.isTrue(hasException, 'Should have received an exception for the invalid object name');
    }

    @IsTest
    static void testGetCommonAncestorObjects() {
        List<HighlightBadgeSetupService.ObjectSelectOption> lstOptions;
        Test.startTest();
        lstOptions = HighlightBadgeSetupController.getCommonAncestorObjects(
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
        List<HighlightBadgeSetupService.AncestorRelationship> results;
        Test.startTest();
        results = HighlightBadgeSetupController.getPossibleAncestorPaths(
            'Contact',
            'Case',
            'Account'
        );
        Test.stopTest();
        Set<String> setPaths = new Set<String>();
        for (HighlightBadgeSetupService.AncestorRelationship ar : results) {
            for (String str : ar.relationships) {
                setPaths.add(str.toLowerCase());
            }
        }
        Assert.isTrue(setPaths.contains('accountid'), 'Should have found the path to the account');
    }

    @IsTest
    static void testGetObjectFields() {
        List<HighlightBadgeSetupService.FieldOption> results;
        Test.startTest();
        results = HighlightBadgeSetupController.getObjectFields('Case');
        Test.stopTest();
        Set<String> setFields = new Set<String>();
        for (HighlightBadgeSetupService.FieldOption fo : results) {
            setFields.add(fo.label);
        }
        Assert.isTrue(setFields.contains('Subject'), 'Should have received the Subject field for the Case object');
        Assert.isTrue(setFields.contains('Description'), 'Should have received the Description field for the Case object');
    }

    @IsTest
    static void testGetObjectFieldsWithException() {
        List<HighlightBadgeSetupService.FieldOption> results;
        Boolean hasException = false;
        Test.startTest();
        try {
            results = HighlightBadgeSetupController.getObjectFields('FakeObjectWontWork');
        } catch (Exception e) {
            hasException = true;
        }
        Test.stopTest();
        Assert.isTrue(hasException, 'Should have received an exception for the fake object');
    }

}