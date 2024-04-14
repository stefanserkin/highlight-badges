/************************************************************************
 * @description Supports the lookup lwc - a polymorphic lookup component
 *  Get the default record for a lookup
 *  Get search results for user input
 * 
 * @author SerkinSolutions
 * @date 2024
 ************************************************************************/
public with sharing class LookupController {

    // Cache the set of fields to retrieve available fields in repeated queries
    private static Set<String> setObjectFields;
    
    /**
     * Get the default, predefined record for a particular lookup
     * 
     * @param defaultRecordId The record id for the default record
     * @param sObjectType The sObject type of the default record
     * @return sObject The default record
     */
    @AuraEnabled(cacheable=true)
    public static sObject getDefault(
        String defaultRecordId,
        String sObjectType
    ) {
        try {
            String strQuery = '';
            strQuery = 'SELECT Id, Name FROM ' + sObjectType + ' WHERE Id = \'' + defaultRecordId + '\' LIMIT 1';
            List<sObject> lstRecords = Database.query(strQuery);
            return lstRecords[0];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Returns records from a particular object, custom setting, or custom metadata type
     * based on user input.
     * 
     * @param searchInput The user's current input
     * @param sObjectType The sObject type of the lookup
     * @param filter Any soql formatted filters that should be applied to the results
     * @return List<sObject> Search results
     */
    @AuraEnabled(cacheable=true)
    public static List<sObject> search(
        String searchInput, 
        String sObjectType, 
        String filter
    ) {
        try {
            String strName = sObjectType.right(3) == 'mdt' ? 'MasterLabel' : 'Name';
            String strQuery = 'SELECT Id, ';
            // If custom metadata, use MasterLabel instead of Name
            strQuery += strName + ' FROM ' + sObjectType + ' WHERE ';
            // Return most recent results prior to user input
            if (searchInput == null || searchInput == '') {
                strQuery += doesFieldExist(sObjectType, 'LastViewedDate') 
                    ? 'LastViewedDate != NULL ' 
                    : 'CreatedDate != NULL ';
            } else { // If user input is provided, filter on input
                strQuery += strName + ' LIKE \'%' + searchInput + '%\' ';
            }
            // Apply additional filter clause if provided
            if (filter != null && filter != '') {
                strQuery += ' AND ' + filter;
            }
            // Limit to top 5 results
            strQuery += ' LIMIT 5';

            // Return query results
            List<sObject> lstRecords = Database.query(strQuery);
            return lstRecords;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Verifies the existence of a particular field on an sobject type
     * 
     * @param sObjectType The sObject type to check for the field on
     * @param strFieldApiName The api name of the field to verify
     * @return Boolean A true result indicates the field exists
     */
    private static Boolean doesFieldExist(
        String sObjectType,
        String strFieldApiName
    ) {
        Boolean fieldExists = false;
        if (setObjectFields == null) {
            // DescribeSObjectResult objResult = Schema.getGlobalDescribe().get(sObjectType).getDescribe();
            DescribeSObjectResult objResult = GlobalDescribeService.getDescribe(sObjectType);
            setObjectFields = objResult.fields.getMap().keySet();
        }
        if (setObjectFields.contains( strFieldApiName.toLowerCase() )) {
            fieldExists = true;
        }
        return fieldExists;
    }

}