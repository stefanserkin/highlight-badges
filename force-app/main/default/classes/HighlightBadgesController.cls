/**
 * Controller for the highlightBadges lwc
 * @date 2024
 */
public with sharing class HighlightBadgesController {
    
    @AuraEnabled(cacheable=true)
    public static List<HighlightBadge> getBadges(String recordId, String sObjectType) {
        try {
            HighlightBadgesService service = new HighlightBadgesService(recordId, sObjectType);
            return service.getBadges();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

}