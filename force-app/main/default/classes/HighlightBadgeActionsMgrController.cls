/************************************************************************
 * @description Controller for the highlightBadgeActionsManager LWC
 * 
 * @author SerkinSolutions
 * @date 2024
 ************************************************************************/
public with sharing class HighlightBadgeActionsMgrController {
    
    @AuraEnabled(cacheable=true)
    public static List<Highlight_Badge_Action__c> getActions(String recordId) {
        try {
            return queryForActions(recordId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static List<Highlight_Badge_Action__c> queryForActions(String recordId) {
        return [
            SELECT Id,
                   Active__c,
                   Sort_Order__c,
                   RecordType.Name,
                   Navigation_Type__c,
                   URL__c,
                   Flow_Type__c,
                   Flow_API_Name__c,
                   Include_Source_Record_ID__c,
                   Include_Display_Record_ID__c,
                   Label__c,
                   Variant__c,
                   Icon_Name__c,
                   Icon_Position__c
              FROM Highlight_Badge_Action__c 
             WHERE Highlight_Badge_Definition__c = :recordId
              WITH USER_MODE
             ORDER BY Sort_Order__c ASC
             LIMIT 10000
        ];
    }

}