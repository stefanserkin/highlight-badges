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
            strQuery = 'SELECT Id, Name FROM ' + sObjectType + ' WHERE Id = :defaultRecordId LIMIT 1';
            List<sObject> lstRecords = Database.query(String.escapeSingleQuotes(strQuery));
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
            String querySearchInput = '%' + searchInput + '%';

            String strQuery = 'SELECT Id, Name FROM ' + sObjectType + ' WHERE';
            if (searchInput == null || searchInput == '') {
                strQuery += ' LastViewedDate != NULL';
            } else {
                strQuery += ' Name LIKE :querySearchInput';
            }
            // Apply additional filter clause if provided
            if (filter != null && filter != '') {
                strQuery += ' AND ' + filter;
            }
            strQuery += ' ORDER BY LastViewedDate DESC LIMIT 5';

            // Return query results
            List<sObject> lstRecords = Database.query(String.escapeSingleQuotes(strQuery));
            return lstRecords;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

}