public with sharing class HighlightBadgeDefinitionSelector {

    private String displayObject;
    private Set<Id> additionalDefinitionIds;

    public HighlightBadgeDefinitionSelector(String displayObjectApiName) {
        this.displayObject = displayObjectApiName;
        this.additionalDefinitionIds = new Set<Id>();
    }

    public void setAdditionalDefinitions(Set<Id> definitionIds) {
        this.additionalDefinitionIds = definitionIds;
    }

    public List<Highlight_Badge_Definition__c> execute() {
        return queryForBadgeDefinitions();
    }
    
    /****************************************************
     * Query for active badge definition records
     ****************************************************/
    private List<Highlight_Badge_Definition__c> queryForBadgeDefinitions() {
        return [
            SELECT Id,
                   Name,
                   Display_Object__c,
                   Common_Ancestor_Object__c,
                   Source_Object__c,
                   Source_to_Ancestor_Path__c,
                   Display_to_Ancestor_Path__c,
                   Filter_Criteria__c,
                   Order_By__c,
                   Limit__c,
                   Source_Detail_Fields__c,
                   Label__c,
                   Icon_Name__c,
                   Background_Color__c,
                   Label_Color__c,
                   Alert__c,
                   Alert_Message__c,
                   Alert_Type__c,
                   Toast_Variant__c,
                   Toast_Mode__c,
                   Alert_Frequency__c,
                   Include_Label_in_Toast__c,
                   Confetti__c,
                   Confetti_Volume__c,
                   Confetti_Size__c,
                   (SELECT Id,
                           Sort_Order__c,
                           RecordType.Name,
                           Navigation_Type__c,
                           URL__c,
                           Open_in_New_Tab__c,
                           Flow_Type__c,
                           Flow_API_Name__c,
                           Include_Source_Record_ID__c,
                           Include_Display_Record_ID__c,
                           Label__c,
                           Variant__c,
                           Icon_Name__c,
                           Icon_Position__c
                      FROM Highlight_Badge_Actions__r
                     WHERE Active__c = true
                     ORDER BY Sort_Order__c ASC NULLS LAST)
              FROM Highlight_Badge_Definition__c
             WHERE Display_Object__c = :displayObject
               AND (Active__c = true OR Id IN :additionalDefinitionIds)
              WITH USER_MODE
             ORDER BY Sort_Order__c ASC NULLS LAST
             LIMIT 100
        ];
    }

}