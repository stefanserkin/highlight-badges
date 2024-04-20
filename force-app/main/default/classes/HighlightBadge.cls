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
     * The record id of the highlight badge definition
     */
    @AuraEnabled
    public Id definitionId {get;set;}

    /**
     * The record id of the source record
     */
    @AuraEnabled
    public Id recordId {get;set;}

    /**
     * sObject type api name and label of the source record
     */
    @AuraEnabled
    public String sObjectType {get;set;}

    @AuraEnabled
    public String sObjectTypeLabel {get;set;}

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
     * Hexadecimal color code for background
     */
    @AuraEnabled
    public String backgroundColor {get;set;}

    /**
     * Hexadecimal color code for label and icon
     */
    @AuraEnabled
    public String labelColor {get;set;}

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

    @AuraEnabled
    public Boolean includeLabelInToast {get;set;}

    /**
     * Confetti settings
     */
    @AuraEnabled
    public Boolean hasConfetti {get;set;}

    @AuraEnabled
    public String confettiNumber {get;set;}
    
    @AuraEnabled
    public String confettiSize {get;set;}

    /**
     * Collection of child Actions (Highlight Badge Action wrappers)
     */
    @AuraEnabled
    public Action[] actions {get;set;}

    /**
     * A Highlight Badge Action wrapper
     */
    public class Action {
        /**
         * Id
         */
        @AuraEnabled
        public Id id {get;set;}

        /**
         * Lowest values first, nulls last
         */
        @AuraEnabled
        public Decimal sortOrder {get;set;}

        /**
         * Available values:
         *   - Flow
         *   - Navigation
         */
        @AuraEnabled
        public String recordTypeName {get;set;}

        /**
         * Navigation settings
         * Types:
         *   - View Source Record
         *   - Web Page
         */
        @AuraEnabled
        public String navigationType {get;set;}

        @AuraEnabled
        public String url {get;set;}

        /**
         * Flow settings
         * Types:
         *   - Autolaunched Flow
         *   - Screen Flow
         */
        @AuraEnabled
        public String flowType {get;set;}

        @AuraEnabled
        public String flowApiName {get;set;}

        @AuraEnabled
        public Boolean includeRecordId {get;set;}

        @AuraEnabled
        public Boolean includeDisplayRecordId {get;set;}

        /**
         * Button styles
         * https://developer.salesforce.com/docs/component-library/bundle/lightning-button/specification
         */
        @AuraEnabled
        public String label {get;set;}

        @AuraEnabled
        public String variant {get;set;}

        @AuraEnabled
        public String iconName {get;set;}

        @AuraEnabled
        public String iconPosition {get;set;}
    }

}