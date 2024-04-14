/************************************************************************
 * @description Controller for the highlightBadges lwc
 * 
 * @author SerkinSolutions
 * @date 2024
 ************************************************************************/
public with sharing class HighlightBadgesController {
    
    @AuraEnabled(cacheable=true)
    public static List<HighlightBadge> getBadges(String recordId, String sObjectType, String previewDefinitionId) {
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

}