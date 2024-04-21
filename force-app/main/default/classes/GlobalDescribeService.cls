/************************************************************************
 * @description Caches global describe results
 * 
 * @author SerkinSolutions
 * @date 2024
 ************************************************************************/
public with sharing class GlobalDescribeService {
    
    private static Map<String, Schema.SObjectType> globalDescribe;
    private static Map<String, Schema.DescribeSObjectResult> describeCache = new Map<String, Schema.DescribeSObjectResult>();

    /****************************************************
     * Ensures global describe is only invoked once
     * 
     * @return Map<String, Schema.SObjectType> global describe
     ****************************************************/
    public static Map<String, Schema.SObjectType> getGlobalDescribe() {
        if (globalDescribe == null) {
            globalDescribe = Schema.getGlobalDescribe();
        }
        return globalDescribe;
    }

    /****************************************************
     * Returns the DescribeSObjectResult for a given SObjectType API name
     * 
     * @param sObjectApiName Api name of the sobject type
     * @return Schema.DescribeSObjectResult describe result for the sobject type
     ****************************************************/
    public static Schema.DescribeSObjectResult getDescribe(
        String sObjectApiName
    ) {
        if (!describeCache.containsKey(sObjectApiName)) {
            Schema.SObjectType sObjectType = getGlobalDescribe().get(sObjectApiName);
            if (sObjectType != null) {
                Schema.DescribeSObjectResult describeResult = sObjectType.getDescribe();
                describeCache.put(sObjectApiName, describeResult);
            }
        }
        return describeCache.get(sObjectApiName);
    }

    /****************************************************
     * Verifies the existence of a particular field on an sobject type
     * 
     * @param sObjectType The sObject type to check for the field on
     * @param strFieldApiName The api name of the field to verify
     * @return Boolean A true result indicates the field exists
     ***************************************************/
    public static Boolean doesFieldExist(
        String sObjectType,
        String strFieldApiName
    ) {
        Boolean fieldExists = false;
        DescribeSObjectResult objResult = getDescribe(sObjectType);
        Set<String> setObjectFields = objResult.fields.getMap().keySet();

        if (setObjectFields.contains( strFieldApiName.toLowerCase() )) {
            fieldExists = true;
        }
        return fieldExists;
    }

    /****************************************************
     * Returns a valid name equivalent for sobjects without a name field.
     * If the provided sobject type is unhandled, returns 'Id'.
     * 
     * @param String The api name of the sObject type
     * @return String A comma-separated string of default fields
     ****************************************************/
    public static String getSObjectNameField(
        String sObjectType
    ) {
        String fieldName;
        if (doesFieldExist(sObjectType, 'Name')) {
            return 'Name';
        }

        switch on sObjectType {
            when 'Case' {
                fieldName = 'CaseNumber';
            }
            when 'Task', 'Event' {
                fieldName = 'Subject';
            }
            when else {
                fieldName = 'Id';
            }
        }
        return fieldName;
    }

}