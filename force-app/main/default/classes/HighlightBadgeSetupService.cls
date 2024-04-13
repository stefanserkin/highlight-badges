/************************************************************************
 * @description Service class provides schema information for highlight badge definition configuration
 * 
 * @author SerkinSolutions
 * @date 2024
 ************************************************************************/
public with sharing class HighlightBadgeSetupService {

    private static Set<String> setSObjectTypes;

    /**
     * Retrieves a list of display objects available for configuration.
     * Each object is represented by an ObjectSelectOption which includes
     * the object's API name and label.
     * 
     * @return List<ObjectSelectOption> List of display object options.
     */
    public static List<ObjectSelectOption> getDisplayObjects() {
        List<ObjectSelectOption> lstOptions = new List<ObjectSelectOption>();

        for (String objName : filterSObjectTypes()) {
            ObjectSelectOption oso = new ObjectSelectOption();
            oso.name = objName;
            oso.label = GlobalDescribeService.getDescribe(objName).getLabel();
            lstOptions.add(oso);
        }

        return lstOptions;
    }

    /**
     * Retrieves the child objects of a given object.
     * Child objects are filtered by their relationship with the parent and must have
     * a direct, queryable relationship.
     * 
     * @param objName The API name of the parent object.
     * @return List<ObjectSelectOption> List of child object options.
     */
    public static List<ObjectSelectOption> getChildObjects(String objName) {
        List<ObjectSelectOption> lstOptions = new List<ObjectSelectOption>();
        List<Schema.ChildRelationship> childRelationships = GlobalDescribeService.getDescribe(objName).getChildRelationships();
        for (Schema.ChildRelationship cr : childRelationships) {
            Schema.SObjectType childSObjectType = cr.getChildSObject();
            Schema.DescribeSObjectResult childDescribe = childSObjectType.getDescribe();
            String childObjectApiName = childDescribe.getName();

            // Check that cr is a supported object and has a direct, queryable relationship
            if (cr.getRelationshipName() != null && isValidSObjectType(childDescribe)) {
                // Add wrapper for child object to list to return
                ObjectSelectOption oso = new ObjectSelectOption();
                oso.name = childObjectApiName;
                oso.label = childDescribe.getLabel();
                oso.childRelationshipName = cr.getRelationshipName();
                lstOptions.add(oso);
            }
        }
        return lstOptions;
    }

    /**
     * Determines common ancestor objects for a given pair of objects.
     * This method helps in identifying possible paths for relationship-based configurations.
     * 
     * @param displayObject API name of the display object.
     * @param sourceObject API name of the source object.
     * @return List<ObjectSelectOption> List of common ancestor objects.
     */
    public static List<ObjectSelectOption> getCommonAncestorObjects(
        String displayObject,
        String sourceObject
    ) {
        List<ObjectSelectOption> lstOptions = new List<ObjectSelectOption>();
        Set<Schema.SObjectType> setDisplayRelationships = new Set<Schema.SObjectType>();
        Map<String, Schema.SObjectField> mapDisplayFields = GlobalDescribeService.getDescribe(displayObject).fields.getMap();

        for (Schema.SObjectField field : mapDisplayFields.values()) {
            Schema.DescribeFieldResult dfr = field.getDescribe();
            if (dfr.getType() == Schema.DisplayType.REFERENCE) {
                List<Schema.SObjectType> lstReferences = dfr.getReferenceTo();
                setDisplayRelationships.addAll(lstReferences);
            }
        }

        Set<Schema.SObjectType> setSourceRelationships = new Set<Schema.SObjectType>();
        Map<String, Schema.SObjectField> mapSourceFields = GlobalDescribeService.getDescribe(sourceObject).fields.getMap();

        for (Schema.SObjectField field : mapSourceFields.values()) {
            Schema.DescribeFieldResult dfr = field.getDescribe();
            if (dfr.getType() == Schema.DisplayType.REFERENCE) {
                List<Schema.SObjectType> lstReferences = dfr.getReferenceTo();
                setSourceRelationships.addAll(lstReferences);
            }
        }
        
        for (Schema.SObjectType sObjType : setDisplayRelationships) {
            if (setSourceRelationships.contains(sObjType)) {
                ObjectSelectOption oso = new ObjectSelectOption();
                oso.name = sObjType.getDescribe().getName();
                oso.label = sObjType.getDescribe().getLabel();
                lstOptions.add(oso);
            }
        }

        return lstOptions;
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
    public static String findInverseRelationshipField(
        String ancestorObjectName, 
        String childObjectName, 
        String relationshipName
    ) {
        Map<String, Schema.SObjectType> gd = GlobalDescribeService.getGlobalDescribe();
        Schema.SObjectType childType = gd.get(childObjectName);
        Schema.SObjectType ancestorType = gd.get(ancestorObjectName);

        Schema.DescribeSObjectResult childDescribe = GlobalDescribeService.getDescribe(childObjectName);
        Map<String, Schema.SObjectField> fields = childDescribe.fields.getMap();
        
        for (Schema.SObjectField field : fields.values()) {
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
            
            if (fieldDescribe.getType() == Schema.DisplayType.REFERENCE) {
                // Get child relationships for the field
                List<Schema.SObjectType> referenceToTypes = fieldDescribe.getReferenceTo();
                
                for (Schema.SObjectType refType : referenceToTypes) {
                    if (refType == ancestorType) {
                        Schema.DescribeSObjectResult refDescribe = refType.getDescribe();
                        List<Schema.ChildRelationship> childRelationships = refDescribe.getChildRelationships();
                        
                        for (Schema.ChildRelationship childRel : childRelationships) {
                            if (relationshipName.equalsIgnoreCase(childRel.getRelationshipName()) && childRel.getChildSObject() == childType) {
                                return fieldDescribe.getName();
                            }
                        }
                    }
                }
            }
        }

        // No matching field was found
        return null;
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
    public static List<AncestorRelationship> getPossibleAncestorPaths(
        String displayObjectApiName, 
        String sourceObjectApiName, 
        String commonAncestorApiName
    ) {
        List<AncestorRelationship> lstRelationships = new List<AncestorRelationship>();

        AncestorRelationship displayWrapper = new AncestorRelationship();
        displayWrapper.childObject = displayObjectApiName;
        displayWrapper.ancestorObject = commonAncestorApiName;
        displayWrapper.type = 'display';
        displayWrapper.relationships = findRelationshipFields(displayObjectApiName, commonAncestorApiName);
        lstRelationships.add(displayWrapper);

        AncestorRelationship sourceWrapper = new AncestorRelationship();
        sourceWrapper.childObject = sourceObjectApiName;
        sourceWrapper.ancestorObject = commonAncestorApiName;
        sourceWrapper.type = 'source';
        sourceWrapper.relationships = findRelationshipFields(sourceObjectApiName, commonAncestorApiName);
        lstRelationships.add(sourceWrapper);

        return lstRelationships;
    }
    
    /**
     * Retrieves the fields of a specified object that are accessible to the current user.
     * This method is used to provide field options for configuration of Highlight Badge Definitions.
     * 
     * @param objectApiName API name of the object to retrieve fields for.
     * @return List<FieldOption> List of field options including field names and labels.
     */
    public static List<FieldOption> getObjectFields(
        String objectApiName
    ) {
        Map<String, Schema.SObjectField> mapFields = GlobalDescribeService.getDescribe(objectApiName).fields.getMap();
        List<FieldOption> lstResults = new List<FieldOption>();
        for (String fieldName : mapFields.keySet()) {
            Schema.DescribeFieldResult fieldResult = mapFields.get(fieldName).getDescribe();
            if (fieldResult.isAccessible()) {
                FieldOption fo = new FieldOption();
                fo.label = fieldResult.getLabel();
                fo.name = fieldResult.getName();
                lstResults.add(fo);
            }
        }
        return lstResults;
    }

    /**
     * Finds relationship fields between two objects. This helper method is used to support
     * relationship-based configuration by identifying reference fields that link objects.
     * 
     * @param fromObjectApiName API name of the object from which the relationship starts.
     * @param toObjectApiName API name of the object to which the relationship points.
     * @return List<String> List of field API names that establish the relationship.
     */
    private static List<String> findRelationshipFields(
        String fromObjectApiName, 
        String toObjectApiName
    ) {
        Set<String> setResults = new Set<String>();
        Map<String, Schema.SObjectField> fields = GlobalDescribeService.getDescribe(fromObjectApiName).fields.getMap();

        for (String fieldName : fields.keySet()) {
            Schema.DescribeFieldResult fieldDescribe = fields.get(fieldName).getDescribe();
            if (fieldDescribe.getType() == Schema.DisplayType.REFERENCE) {
                List<Schema.SObjectType> referenceToTypes = fieldDescribe.getReferenceTo();
                for (Schema.SObjectType refType : referenceToTypes) {
                    if (refType.getDescribe().getName() == toObjectApiName) {
                        setResults.add(fieldDescribe.getName());
                    }
                }
            }
        }
        return new List<String>(setResults);
    }

    /**
     * Filters out SObject types based on predefined criteria such as custom settings,
     * system objects, and accessibility. This method ensures only relevant SObject types
     * are considered for UI configurations.
     * 
     * @return Set<String> Set of SObject API names that meet the filter criteria.
     */
    private static Set<String> filterSObjectTypes() {
        if (setSObjectTypes == null) {
            setSObjectTypes = new Set<String>();
            for (Schema.SObjectType objType : GlobalDescribeService.getGlobalDescribe().values()) {
                Schema.DescribeSObjectResult sObjDescribe = objType.getDescribe();
                String name = sObjDescribe.getName();
                String lcName = name.toLowerCase();
                // Filter out custom settings and system objects
                if (
                    !lcName.endsWith('history') && !lcName.endsWith('tag') &&
                    !lcName.endsWith('share') && !lcName.endsWith('feed') && 
                    !lcName.endsWith('group') && !lcName.endsWith('public') &&
                    !sObjDescribe.isCustomSetting() && sObjDescribe.isCreateable() &&
                    sObjDescribe.getRecordTypeInfos().size() > 0
                ) {
                    setSObjectTypes.add(name);
                }
            }
        }
        return setSObjectTypes;
    }

    /**
     * Holds the specific logic for sobject type inclusion
     * 
     * @param sObjDescribe Describe result for the sobject type to validate
     * @return Boolean
     */
    private static Boolean isValidSObjectType(
        Schema.DescribeSObjectResult sObjDescribe
    ) {
        String name = sObjDescribe.getName();
        String lcName = name.toLowerCase();
        Boolean isValid = false;
        // Filter out custom settings and system objects
        if (
            !lcName.endsWith('history') && !lcName.endsWith('tag') &&
            !lcName.endsWith('share') && !lcName.endsWith('feed') && 
            !lcName.endsWith('group') && !lcName.endsWith('public') &&
            !sObjDescribe.isCustomSetting() && sObjDescribe.isCreateable() &&
            sObjDescribe.getRecordTypeInfos().size() > 0
        ) {
            isValid = true;
        }
        return isValid;
    }

    public class ObjectSelectOption {
        @AuraEnabled
        public String name {get;set;}
        @AuraEnabled
        public String label {get;set;}
        @AuraEnabled
        public String childRelationshipName {get;set;}
    }

    public class AncestorRelationship {
        @AuraEnabled
        public String childObject {get;set;}
        @AuraEnabled
        public String ancestorObject {get;set;}
        @AuraEnabled
        public String type {get;set;}
        @AuraEnabled
        public List<String> relationships {get;set;}
    }

    public class FieldOption {
        @AuraEnabled
        public String label {get;set;}
        @AuraEnabled
        public String name {get;set;}
    }

}