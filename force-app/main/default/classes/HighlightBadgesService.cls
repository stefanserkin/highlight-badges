/**
 * The HighlightBadgesService provides badges relevant to a particular user and record page
 * @date 2024
 */
public with sharing class HighlightBadgesService {

    public Id displayRecordId {get; private set;}
    public String displayObjectType {get; private set;}

    public HighlightBadgesService(String recordId, String sObjectType) {
        System.debug(':::: record id passed to service constructor --> ' + recordId);
        System.debug(':::: source sobject type passed to service constructor --> ' + sObjectType);
        this.displayRecordId = Id.valueOf( recordId );
        this.displayObjectType = sObjectType;
    }

    /****************************************************
     * Constants
     ****************************************************/
    private static final String DEFAULT_BACKGROUND_COLOR = '#D3D3D3';
    private static final String DEFAULT_LABEL_COLOR = '#000000';
    private static final String DEFAULT_ICON_NAME = 'utility:info';
    private static final String MERGE_FIELD_REGEX = '\\{!.+?\\}';
    private static final String DEFAULT_BADGE_FIELDSET = 'Name';

    private Map<String, Id> mapParentIds;

    /**
     * Get active highlight badges for the source record id
     */
    public List<HighlightBadge> getBadges() {
        List<Highlight_Badge_Definition__c> lstBadgeDefinitions = queryForBadgeDefinitions(displayObjectType);
        System.debug(':::: found ' + lstBadgeDefinitions.size() + ' active definitions');
        
        // Guard against empty list of definitions
        if (lstBadgeDefinitions.isEmpty()) {
            return new List<HighlightBadge>();
        }

        List<HighlightBadge> lstBadges = getBadgeWrappers(lstBadgeDefinitions);
        return lstBadges;
    }

    private List<HighlightBadge> getBadgeWrappers(
        List<Highlight_Badge_Definition__c> lstBadgeDefinitions
    ) {
        List<HighlightBadge> lstBadges = new List<HighlightBadge>();

        Map<String, Id> mapFieldNameToParentId = getParentIdMap(lstBadgeDefinitions);

        // For each badge definition, get relevant badges
        for (Highlight_Badge_Definition__c definition : lstBadgeDefinitions) {
            // Check query limit to ensure current query won't exceed it
            if (Limits.getQueries() == Limits.getLimitQueries()) {
                break;
            }

            String parentId = definition.Common_Parent_Object__c == definition.Display_Object__c 
                ? displayRecordId 
                : mapFieldNameToParentId.get(definition.Display_to_Parent_Path__c);
            HighlightBadgeQueryBuilder queryBuilder = new HighlightBadgeQueryBuilder(
                definition, 
                displayRecordId, 
                parentId
            );
            String strQuery = queryBuilder.getQueryString();

            List<SObject> queryResults;
            try {
                queryResults = Database.query(strQuery, AccessLevel.USER_MODE);
            } catch (System.QueryException ex) {
                // User does not have required object, FLS, or sharing access
                continue;
            }
            System.debug(':::: queryResults size --> ' + queryResults.size());

            // Create set to store label names to avoid duplicates
            Set<String> setLabelNames = new Set<String>();

            for (SObject obj : queryResults) {
                HighlightBadge badge = new HighlightBadge();
                badge.recordId = obj.Id;
                badge.sObjectType = definition.Source_Object__c;
                badge.label = getBadgeLabel(definition, obj);
                // Prevent duplicates
                if (setLabelNames.contains(badge.label)) {
                    continue;
                } else {
                    setLabelNames.add(badge.label);
                }
                badge.iconName = getBadgeIconName(definition);
                badge.colorStyle = getBadgeColorStyle(definition);
                badge.labelStyle = getBadgeLabelStyle(definition);
                badge.fieldSet = String.isBlank(definition.Source_Detail_Fields__c)
                    ? DEFAULT_BADGE_FIELDSET
                    : definition.Source_Detail_Fields__c.replaceAll('\\s+', '');
                
                lstBadges.add(badge);
            }
        }
        
        System.debug(':::: badges to return --> ' + lstBadges);
        return lstBadges;
    }

    /**
     * Map of badge definition ids to the parent object id
     * Find the parent record id from the Source to Parent Path
     */
    private Map<String, Id> getParentIdMap(
        List<Highlight_Badge_Definition__c> lstDefinitions
    ) {
        if (mapParentIds != null) {
            return mapParentIds;
        }
        
        mapParentIds = new Map<String, Id>();
        Set<String> setParentFields = new Set<String>();
        for (Highlight_Badge_Definition__c def : lstDefinitions) {
            if (def.Display_Object__c != def.Common_Parent_Object__c) {
                setParentFields.add(def.Display_to_Parent_Path__c);
            }
        }

        // No need to query if the only parent ids are the record id of the source record
        if (setParentFields.isEmpty()) {
            return mapParentIds;
        }

        List<String> lstParentFields = new List<String>();
        lstParentFields.addAll(setParentFields);
        System.debug('::: lstParentFields --> ' + lstParentFields);

        String strQuery = 'SELECT ' + String.join(lstParentFields, ', ') + 
            ' FROM ' + displayObjectType + 
            ' WHERE Id = \'' + displayRecordId + '\' LIMIT 1';
        System.debug('::::: strQuery --> ' + strQuery);

        List<SObject> lstObjs = Database.query(strQuery, AccessLevel.USER_MODE);
        System.debug('::::: query result size --> ' + lstObjs.size());
        for (String fieldName : setParentFields) {
            System.debug('::: checking field --> ' + fieldName);
            System.debug('::: obj has field value --> ' + lstObjs[0].get(fieldName));
            mapParentIds.put(fieldName, (Id) lstObjs[0].get(fieldName) );
        }
        System.debug(':::: mapParentIds --> ' + mapParentIds);
        return mapParentIds;
    }

    /****************************************************
     * Returns the badge label for a single definition
     * @param Highlight_Badge_Definition__c The definition record
     *     to construct a query for
     * @param SObject The api name of the sObject type being queried
     ****************************************************/
     public static String getBadgeLabel(
        Highlight_Badge_Definition__c definition, 
        SObject obj
    ) {
        String badgeLabel = definition.Label__c.contains('{!')
            ? replaceMergeFieldsWithValues(definition.Label__c, obj) 
            : definition.Label__c;
        return badgeLabel;
    }

    /****************************************************
     * Returns the badge alert message for a single definition
     * @param Highlight_Badge_Definition__c The definition record
     *     to construct a query for
     * @param SObject The api name of the sObject type
     ****************************************************/
    
     /*
    public static String getBadgeAlertMessage(
        Highlight_Badge_Definition__c definition, 
        SObject obj
    ) {
        String alertMessage;
        if (
            definition.Alert__c && 
            !String.isBlank(definition.Alert_Message__c) &&
            definition.Alert_Message__c.contains('{!')
        ) {
            alertMessage = replaceMergeFieldsWithValues(
                definition.Alert_Message__c, 
                obj
            );
        } else {
            alertMessage = definition.Alert_Message__c;
        }
        return alertMessage;
    }
    */

    /****************************************************
     * Returns a string that can be referenced in an html style attribute
     *     to display the badge's defined background color (or default)
     * @param Highlight_Badge_Definition__c The definition record
     *     to get the badge color for
     ****************************************************/
    public static String getBadgeColorStyle(
        Highlight_Badge_Definition__c definition
    ) {
        String hexColor = definition.Background_Color__c != null ? '#' + definition.Background_Color__c : DEFAULT_BACKGROUND_COLOR;
        String badgeColorStyle = '--sds-c-badge-color-background:' + hexColor + ';';
        return badgeColorStyle;
    }

    /****************************************************
     * Returns a string that can be referenced in an html style attribute
     *     to display the badge's defined label color (or default)
     * @param Highlight_Badge_Definition__c The definition record
     *     to get the label color for
     ****************************************************/
    public static String getBadgeLabelStyle(
        Highlight_Badge_Definition__c definition
    ) {
        String labelHexColor = definition.Label_Color__c != null ? '#' + definition.Label_Color__c : DEFAULT_LABEL_COLOR;
        String badgeLabelStyle = '--sds-c-badge-text-color:' + labelHexColor + ';--slds-c-badge-icon-color-foreground:' + labelHexColor;
        return badgeLabelStyle;
    }

    /****************************************************
     * Returns the name of the icon to display for this badge
     * @param Highlight_Badge_Definition__c The definition record
     *     to get the badge icon for
     ****************************************************/
    public static String getBadgeIconName(
        Highlight_Badge_Definition__c definition
    ) {
        String iconName = !String.isBlank(definition.Icon_Name__c) ? definition.Icon_Name__c : DEFAULT_ICON_NAME;
        return iconName;
    }

    /****************************************************
     * Returns the original string with merge fields substituted for their values
     * @param String String containing merge fields to be replaced
     * @param SObject The api name of the sObject type
     ****************************************************/
    @TestVisible
    private static String replaceMergeFieldsWithValues(
        String input,
        SObject obj
    ) {
        String result = input;
        Map<String,Object> mapObjFields = obj.getPopulatedFieldsAsMap();
        Pattern p = Pattern.compile(MERGE_FIELD_REGEX);
        Matcher m = p.matcher(result);
        while(m.find()) {
            String fieldApiName = m.group().substring(
                2, 
                m.group().length() - 1
            );
            result = mapObjFields.containsKey(fieldApiName)
                ? result.replace(m.group(0), String.valueOf(mapObjFields.get(fieldApiName)))
                : result.replace(m.group(0), '');
        }
        return result;
    }

    /****************************************************
     * Query for active badge definition records
     * @param The api name of the source object
     ****************************************************/
    private List<Highlight_Badge_Definition__c> queryForBadgeDefinitions(
        String sourceObject
    ) {
        return [
            SELECT Id, 
                   Name, 
                   Display_Object__c, 
                   Common_Parent_Object__c, 
                   Source_Object__c, 
                   Source_to_Parent_Path__c, 
                   Display_to_Parent_Path__c, 
                   Filter_Criteria__c, 
                   Source_Detail_Fields__c, 
                   Label__c, 
                   Icon_Name__c, 
                   Background_Color__c, 
                   Label_Color__c
              FROM Highlight_Badge_Definition__c
             WHERE Display_Object__c = :sourceObject
               AND Active__c = true
              WITH USER_MODE
             ORDER BY Sort_Order__c ASC
             LIMIT 100
        ];
    }

}
