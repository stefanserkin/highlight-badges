/************************************************************************
 * @description Data wrapper to represent an individual highlight badge
 * 
 * @author SerkinSolutions
 * @date 2024
 ************************************************************************/
public with sharing class HighlightBadge {

    /**
     * A unique id for this data wrapper object
     * Not a Salesforce object record id
     */
    @AuraEnabled
    public String id {get;private set;}

    public HighlightBadge() {
        this.id = UUID.randomUUID().toString();
    }

    /**
     * The record id of the source record
     */
    @AuraEnabled
    public Id recordId {get;set;}

    /**
     * sObject Type of the source record
     */
    @AuraEnabled
    public String sObjectType {get;set;}

    /**
     * The label of the badge - can include merge fields (e.g. {!FirstName})
     */
    @AuraEnabled
    public String label {get;set;}

    /**
     * A valid icon name from SLDS library
     */
    @AuraEnabled
    public String iconName {get;set;}

    /**
     * Comma-separated string of fields to display when this badge is selected/clicked
     */
    @AuraEnabled
    public String fieldSet {get;set;}

    /**
     * CSS string for badge background, icon, and label colors
     */
    @AuraEnabled
    public String styles {get;set;}

    /**
     * If true, an alert will be displayed when this badge is returned for a record
     */
    @AuraEnabled
    public Boolean hasAlert {get;set;}

    /**
     * The alert message to display - can include merge fields (e.g. {!FirstName})
     */
    @AuraEnabled
    public String alertMessage {get;set;}

    /**
     * 'Modal' or 'Toast'
     */
    @AuraEnabled
    public String alertType {get;set;}

    /**
     * Toast settings
     */
    @AuraEnabled
    public String toastVariant {get;set;}
    @AuraEnabled
    public String toastMode {get;set;}

}