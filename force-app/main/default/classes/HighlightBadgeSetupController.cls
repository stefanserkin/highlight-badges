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
     * @return List<ObjectSelectOption> List of display object options.
     */
    @AuraEnabled(cacheable=true)
    public static List<HighlightBadgeSetupService.ObjectSelectOption> getDisplayObjects() {
        try {
            return HighlightBadgeSetupService.getDisplayObjects();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Retrieves the child objects of a given object.
     * Child objects are filtered by their relationship with the parent and must have
     * a direct, queryable relationship.
     * 
     * @param objName The API name of the parent object.
     * @return List<ObjectSelectOption> List of child object options.
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
     * Determines common ancestor objects for a given pair of objects.
     * This method helps in identifying possible paths for relationship-based configurations.
     * 
     * @param displayObject API name of the display object.
     * @param sourceObject API name of the source object.
     * @return List<ObjectSelectOption> List of common ancestor objects.
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
     * This is useful for complex configuration scenarios involving multiple related objects.
     * 
     * @param displayObjectApiName API name of the display object.
     * @param sourceObjectApiName API name of the source object.
     * @param commonAncestorApiName API name of the common ancestor object.
     * @return List<AncestorRelationship> List of all possible ancestor relationships.
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
     * Finds the inverse relationship field between a child and ancestor object based on the
     * specified relationship name. Useful for configuring bidirectional relationships.
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
     * This method is used to provide field options for configuration of Highlight Badge Definitions.
     * 
     * @param objectApiName API name of the object to retrieve fields for.
     * @return List<FieldOption> List of field options including field names and labels.
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