/************************************************************************
 * @description Supports the lookup lwc - a polymorphic lookup component
 *  Get the default record for a lookup
 *  Get search results for user input
 * 
 * @author SerkinSolutions
 * @date 2024
 ************************************************************************/
public with sharing class LookupController {
    
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
            String nameField = GlobalDescribeService.getSObjectNameField(sObjectType);
            String strQuery = 'SELECT Id, ' + nameField + ' FROM ' + sObjectType + ' WHERE Id = :defaultRecordId LIMIT 1';
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
     * @return List<LookupResult> Search results
     */
    @AuraEnabled(cacheable=true)
    public static List<LookupResult> search(
        String searchInput, 
        String sObjectType, 
        String filter
    ) {
        try {
            String querySearchInput = '%' + searchInput + '%';
            // Ensure LastViewedDate and Name fields exist before using them in query. Default to CreatedDate and Id
            String sortField = GlobalDescribeService.doesFieldExist(sObjectType, 'LastViewedDate') ? 'LastViewedDate' : 'CreatedDate';
            String nameField = GlobalDescribeService.getSObjectNameField(sObjectType);

            // Build query
            String strQuery = 'SELECT ' + nameField + ' FROM ' + sObjectType + ' WHERE ';
            if (searchInput == null || searchInput == '') {
                strQuery += sortField + ' != NULL';
            } else {
                strQuery += nameField + ' LIKE :querySearchInput';
            }

            // Apply additional filters if provided
            if (filter != null && filter != '') {
                strQuery += ' AND ' + filter;
            }
            strQuery += ' ORDER BY ' + sortField + ' LIMIT 5';

            // Return query results
            List<sObject> lstRecords = Database.query(String.escapeSingleQuotes(strQuery));

            List<LookupResult> lstResults = new List<LookupResult>();
            for (sObject obj : lstRecords) {
                LookupResult lr = new LookupResult();
                lr.id = (Id) obj.get('Id');
                lr.name = (String) obj.get(nameField);
                lstResults.add(lr);
            }
            return lstResults;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class LookupResult {
        @AuraEnabled
        public Id id {get;set;}
        @AuraEnabled
        public String name {get;set;}
    }

}