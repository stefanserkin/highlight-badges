/**
 * Data wrapper to represent an individual highlight badge
 * @date 2024
 */
public with sharing class HighlightBadge {

    @AuraEnabled
    public String id {get;private set;}

    public HighlightBadge() {
        this.id = UUID.randomUUID().toString();
    }

    @AuraEnabled
    public Id recordId {get;set;}

    @AuraEnabled
    public String sObjectType {get;set;}

    @AuraEnabled
    public String label {get;set;}

    @AuraEnabled
    public String iconName {get;set;}

    @AuraEnabled
    public String fieldSet {get;set;}

    @AuraEnabled
    public String colorStyle {get;set;}

    @AuraEnabled
    public String labelStyle {get;set;}

    @AuraEnabled
    public Boolean hasAlert {get;set;}

    @AuraEnabled
    public String alertMessage {get;set;}

    @AuraEnabled
    public String alertType {get;set;}

}