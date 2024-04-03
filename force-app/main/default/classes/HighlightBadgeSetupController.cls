public with sharing class HighlightBadgeSetupController {

    private static final Set<String> ALLOWED_STANDARD_OBJECTS = new Set<String>{
        'Account', 
        'Contact', 
        'Case', 
        'Opportunity', 
        'Campaign', 
        'Lead', 
        'Task', 
        'Event'
    };

    private static Map<String, String> mapObjects;
    private static Map<String, Schema.SObjectType> mapObjectTypes;

    @AuraEnabled(cacheable=true)
    public static List<ObjectSelectOption> getDisplayObjects() {
        try {
            List<ObjectSelectOption> lstOptions = new List<ObjectSelectOption>();

            for (String objName : getObjectMap().keySet()) {
                ObjectSelectOption oso = new ObjectSelectOption();
                oso.name = objName;
                oso.label = getObjectMap().get(objName);
                lstOptions.add(oso);
            }

            return lstOptions;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<ObjectSelectOption> getChildObjects(String objName) {
        try {
            List<ObjectSelectOption> lstOptions = new List<ObjectSelectOption>();
            Schema.SObjectType displayObjType = getObjectTypeMap().get(objName);
            List<Schema.ChildRelationship> childRelationships = displayObjType.getDescribe().getChildRelationships();
            for (Schema.ChildRelationship cr : childRelationships) {
                Schema.SObjectType childSObjectType = cr.getChildSObject();
                String childObjectApiName = childSObjectType.getDescribe().getName();

                // Check that cr is a supported object and has a direct, queryable relationship
                if (
                    cr.getRelationshipName() != null && 
                    (childSObjectType.getDescribe().isCustom() || 
                    ALLOWED_STANDARD_OBJECTS.contains(childObjectApiName))
                ) {
                    // Add wrapper for child object to list to return
                    ObjectSelectOption oso = new ObjectSelectOption();
                    oso.name = childObjectApiName;
                    oso.label = getObjectMap().get(childObjectApiName);
                    oso.childRelationshipName = cr.getRelationshipName();
                    lstOptions.add(oso);
                }
            }
            return lstOptions;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<ObjectSelectOption> getCommonAncestorObjects(
        String displayObject,
        String sourceObject
    ) {
        try {
            List<ObjectSelectOption> lstOptions = new List<ObjectSelectOption>();
            Set<Schema.SObjectType> setDisplayRelationships = new Set<Schema.SObjectType>();

            Map<String, Schema.SObjectField> mapDisplayFields = getObjectTypeMap().get(
                displayObject
            )
            .getDescribe()
            .fields.getMap();

            for (Schema.SObjectField field : mapDisplayFields.values()) {
                Schema.DescribeFieldResult dfr = field.getDescribe();
                if (dfr.getType() == Schema.DisplayType.REFERENCE) {
                    List<Schema.SObjectType> lstReferences = dfr.getReferenceTo();
                    setDisplayRelationships.addAll(lstReferences);
                }
            }

            Set<Schema.SObjectType> setSourceRelationships = new Set<Schema.SObjectType>();
            // Check if source object has any common relationships
            Map<String, Schema.SObjectField> mapSourceFields = getObjectTypeMap().get(
                sourceObject
            )
            .getDescribe()
            .fields.getMap();

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
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static String findInverseRelationshipField(
        String ancestorObjectName, 
        String childObjectName, 
        String relationshipName
    ) {
        Schema.SObjectType childType = getObjectTypeMap().get(childObjectName);
        Schema.SObjectType ancestorType = getObjectTypeMap().get(ancestorObjectName);

        Schema.DescribeSObjectResult childDescribe = childType.getDescribe();
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
        
        return null; // No matching field found
    }

    @AuraEnabled(cacheable=true)
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

    @AuraEnabled(cacheable=true)
    public static List<FieldOption> getObjectFields(
        String objectApiName
    ) {
        try {
            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
            Map<String, Schema.SObjectField> mapFields = gd.get(objectApiName).getDescribe().fields.getMap();
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
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static List<String> findRelationshipFields(
        String fromObjectApiName, 
        String toObjectApiName
    ) {
        Set<String> setResults = new Set<String>();
        Schema.DescribeSObjectResult describeResult = getObjectTypeMap().get(fromObjectApiName).getDescribe();
        Map<String, Schema.SObjectField> fields = describeResult.fields.getMap();

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

    private static Map<String, String> getObjectMap() {
        if (mapObjects == null) {
            loadObjectMaps();
        }
        return mapObjects;
    }

    private static Map<String, Schema.SObjectType> getObjectTypeMap() {
        if (mapObjectTypes == null) {
            loadObjectMaps();
        }
        return mapObjectTypes;
    }

    private static void loadObjectMaps() {
        mapObjects = new Map<String, String>();
        mapObjectTypes = new Map<String, Schema.SObjectType>();
        for (Schema.SObjectType objType : Schema.getGlobalDescribe().values()) {
            String name = objType.getDescribe().getName();
            String label = objType.getDescribe().getLabel();
            if (
                name.right(3) != 'mdt' && 
                (objType.getDescribe().isCustom() || 
                ALLOWED_STANDARD_OBJECTS.contains(name))
            ) {
                mapObjects.put(name, label);
                mapObjectTypes.put(name, objType);
            }

            /*
            if (
                !name.containsIgnoreCase('history') && !name.containsIgnoreCase('tag') &&
                !name.containsIgnoreCase('share') && !name.containsIgnoreCase('feed') && 
                !name.containsIgnoreCase('group') && !name.containsIgnoreCase('public') &&
                !objType.getDescribe().isCustomSetting() && objType.getDescribe().isCreateable() &&
                objType.getDescribe().getRecordTypeInfos().size() > 0
            ) {      
                mapObjects.put(name, label);
            }
            */
        }
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