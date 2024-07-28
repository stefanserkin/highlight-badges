/************************************************************************
 * @description Controller for the highlightBadgeActionsManager LWC
 * 
 * @author SerkinSolutions
 * @date 2024
 ************************************************************************/
public with sharing class HighlightBadgeActionsMgrController {

    private static final String FLOW_PROCESS_TYPE = 'Flow';
    
    @AuraEnabled(cacheable=true)
    public static List<Highlight_Badge_Action__c> getActions(String recordId) {
        try {
            return getRelatedActions(recordId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<FlowOption> getFlowOptions() {
        try {
            List<FlowDefinitionView> fdvs = getActiveFlows();
            return createFlowOptionsFromDefinitionViews(fdvs);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static List<FlowOption> createFlowOptionsFromDefinitionViews(List<FlowDefinitionView> fdvs) {
        List<FlowOption> flowOptions = new List<FlowOption>();
        for (FlowDefinitionView fdv : fdvs) {
            FlowOption option = new FlowOption();
            option.label = fdv.Label;
            option.value = getQualifiedApiName(fdv);
        }
        return flowOptions;
    }

    private static String getQualifiedApiName(
        FlowDefinitionView fdv
    ) {
        return String.isEmpty(fdv.NamespacePrefix) 
            ? fdv.ApiName 
            : fdv.NamespacePrefix + '__' + fdv.ApiName;
    }

    private static List<FlowDefinitionView> getActiveFlows() {
        return [
            SELECT ApiName, Label, NamespacePrefix
              FROM FlowDefinitionView
             WHERE IsActive = true
               AND ProcessType = :FLOW_PROCESS_TYPE
              WITH SYSTEM_MODE
             ORDER BY Label ASC
        ];
    }

    private static List<Highlight_Badge_Action__c> getRelatedActions(String recordId) {
        return [
            SELECT Id,
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
             LIMIT 10000
        ];
    }

    public class FlowOption {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String value;
    }

}