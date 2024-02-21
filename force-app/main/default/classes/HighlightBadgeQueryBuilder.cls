/**
 * Used to construct queries from Highlight Badge Definition configuration
 * @date 2024
 */
public with sharing class HighlightBadgeQueryBuilder {

    /****************************************************
     * Constants
     ****************************************************/
    private static final String DEFAULT_BACKGROUND_COLOR = '#D3D3D3';
    private static final String DEFAULT_LABEL_COLOR = '#000000';
    private static final String DEFAULT_ICON_NAME = 'utility:info';
    private static final String MERGE_FIELD_REGEX = '\\{!.+?\\}';

    private Highlight_Badge_Definition__c definition;
    private Id recordId;
    private Id parentId;

    public HighlightBadgeQueryBuilder(
        Highlight_Badge_Definition__c definition, 
        Id recordId, 
        Id parentId
    ) {
        this.definition = definition;
        this.recordId = recordId;
        this.parentId = parentId;
    }

    public String getQueryString() {
        String queryString = getQueryFromDefinition();
        return queryString;
    }

    /****************************************************
     * Returns a soql query string, constructed from highlight badge definition properties
     * @param Highlight_Badge_Definition__c The definition record to construct a query for
     ****************************************************/
    private String getQueryFromDefinition() {
        // SELECT
        String query = 'SELECT Id ';
        Set<String> setDetailFields = getFieldsForSelector(definition);
        for (String field : setDetailFields) {
            query += ', ' + field + ' ';
        }

        // FROM
        query += 'FROM ' + definition.Source_Object__c + ' ';

        // WHERE
        query += 'WHERE ' + definition.Source_to_Parent_Path__c + ' = :parentId ';
        if (!String.isBlank(definition.Filter_Criteria__c)) {
            query += 'AND ' + definition.Filter_Criteria__c + ' ';
        }
        
        // ORDER BY
        if (!String.isBlank(definition.Order_By__c)) {
            query += 'ORDER BY ' + definition.Order_By__c;
        }
        
        System.debug(':::: query --> ' + query);
        return query;
    }

    /****************************************************
     * Returns a set of strings with each of the field names to include
     *     in the SELECT statement of the query
     * @param Contact_Badge_Definition__mdt The definition record
     *     to get selector fields for
     ****************************************************/
     private Set<String> getFieldsForSelector(
        Highlight_Badge_Definition__c definition
    ) {
        Set<String> fieldsForSelector = new Set<String>();
        // If displaying a label with merge fields, add the fields to the query
        if (
            !String.isBlank(definition.Label__c) && 
            definition.Label__c.contains('{!')
        ) {
            fieldsForSelector.addAll(
                getMergeFieldsFromString(definition.Label__c)
            );
        }
        // If displaying an alert, check for merge fields to add to query
        if (
            definition.Alert__c && 
            !String.isBlank(definition.Alert_Message__c) &&
            definition.Alert_Message__c.contains('{!')
        ) {
            fieldsForSelector.addAll(
                getMergeFieldsFromString(definition.Alert_Message__c)
            );
        }
        
        // Add all additional fields for the modal
        if (!String.isBlank(definition.Source_Detail_Fields__c)) {
            fieldsForSelector.addAll(definition.Source_Detail_Fields__c.replaceAll('\\s+', '').split(','));
        } else {
            fieldsForSelector.add('Name');
        }
        System.debug('::::: got fields for selector --> ' + fieldsForSelector);
        return fieldsForSelector;
    }

    /****************************************************
     * Returns a set of strings with each of the merge fields contained in the original string
     * @param String String containing merge fields
     ****************************************************/

     private Set<String> getMergeFieldsFromString(
        String input
    ) {
        Set<String> setMergeFields = new Set<String>();
        Pattern p = Pattern.compile(MERGE_FIELD_REGEX);
        Matcher m = p.matcher(input);
        while(m.find()) {
            String mergeFieldApiName = m.group().substring(
                2, 
                m.group().length() - 1
            );
            setMergeFields.add(mergeFieldApiName);
        }
        return setMergeFields;
    }


}