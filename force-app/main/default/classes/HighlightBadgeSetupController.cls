/************************************************************************
 * @description Controller for highlight badge definition configuration
 * 
 * @author SerkinSolutions
 * @date 2024
 ************************************************************************/
public with sharing class HighlightBadgeSetupController {

    /**
     * Retrieves a list of display objects available for configuration.
     * Each object is represented by an ObjectSelectOption which includes
     * the object's API name and label.
     * 
     * @return List<HighlightBadgeSetupService.ObjectSelectOption> List of display object options.
     */
    @AuraEnabled(cacheable=true)
    public static List<HighlightBadgeSetupService.ObjectSelectOption> getDisplayObjects() {
        return HighlightBadgeSetupService.getDisplayObjects();
    }

    /**
     * Retrieves valid child objects for a given object.
     * 
     * @param objName The API name of the parent object.
     * @return List<HighlightBadgeSetupService.ObjectSelectOption> List of child object options.
     */
    @AuraEnabled(cacheable=true)
    public static List<HighlightBadgeSetupService.ObjectSelectOption> getChildObjects(
        String objName
    ) {
        try {
            return HighlightBadgeSetupService.getChildObjects(objName);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Retrieves common ancestor objects for a given pair of objects.
     * 
     * @param displayObject API name of the display object.
     * @param sourceObject API name of the source object.
     * @return List<HighlightBadgeSetupService.ObjectSelectOption> List of common ancestor objects.
     */
    @AuraEnabled(cacheable=true)
    public static List<HighlightBadgeSetupService.ObjectSelectOption> getCommonAncestorObjects(
        String displayObject,
        String sourceObject
    ) {
        try {
            return HighlightBadgeSetupService.getCommonAncestorObjects(
                displayObject, 
                sourceObject
            );
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Retrieves possible paths for ancestor relationships between display and source objects.
     * 
     * @param displayObjectApiName API name of the display object.
     * @param sourceObjectApiName API name of the source object.
     * @param commonAncestorApiName API name of the common ancestor object.
     * @return List<HighlightBadgeSetupService.AncestorRelationship> List of all possible ancestor relationships.
     */
    @AuraEnabled(cacheable=true)
    public static List<HighlightBadgeSetupService.AncestorRelationship> getPossibleAncestorPaths(
        String displayObjectApiName, 
        String sourceObjectApiName, 
        String commonAncestorApiName
    ) {
        return HighlightBadgeSetupService.getPossibleAncestorPaths(
            displayObjectApiName, 
            sourceObjectApiName, 
            commonAncestorApiName
        );
    }

    /**
     * Returns the inverse relationship field between a child and ancestor object based on the
     * specified relationship name. Useful for determining how to traverse to the ancestor objects.
     * 
     * @param ancestorObjectName API name of the ancestor object.
     * @param childObjectName API name of the child object.
     * @param relationshipName Name of the relationship.
     * @return String API name of the inverse relationship field.
     */
    @AuraEnabled(cacheable=true)
    public static String findInverseRelationshipField(
        String ancestorObjectName, 
        String childObjectName, 
        String relationshipName
    ) {
        return HighlightBadgeSetupService.findInverseRelationshipField(
            ancestorObjectName, 
            childObjectName, 
            relationshipName
        );
    }
    
    /**
     * Retrieves the fields of a specified object that are accessible to the current user.
     * 
     * @param objectApiName API name of the object to retrieve fields for.
     * @return List<HighlightBadgeSetupService.FieldOption> List of field options including field names and labels.
     */
    @AuraEnabled(cacheable=true)
    public static List<HighlightBadgeSetupService.FieldOption> getObjectFields(
        String objectApiName
    ) {
        try {
            return HighlightBadgeSetupService.getObjectFields(objectApiName);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

}