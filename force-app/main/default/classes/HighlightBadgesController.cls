/************************************************************************
 * @description Controller for the highlightBadges lwc
 * 
 * @author SerkinSolutions
 * @date 2024
 ************************************************************************/
public with sharing class HighlightBadgesController {
    
    @AuraEnabled(cacheable=true)
    public static List<HighlightBadge> getBadges(
        String recordId, 
        String sObjectType, 
        String previewDefinitionId
    ) {
        try {
            HighlightBadgesService service = new HighlightBadgesService(recordId, sObjectType);

            List<HighlightBadge> lstBadges;
            if (previewDefinitionId != null && previewDefinitionId != '') {
                lstBadges = service.getBadges(previewDefinitionId);
            } else {
                lstBadges = service.getBadges();
            }
            return lstBadges;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static String runFlow(
        String flowName,
        String jsonInputVariables
    ) {
        try {
            Map<String, Object> inputVariables = (Map<String, Object>) JSON.deserializeUntyped(
                jsonInputVariables
            );
            Flow.Interview flowInt = Flow.Interview.createInterview(flowName, inputVariables);
            flowInt.start();
            return 'success';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

}