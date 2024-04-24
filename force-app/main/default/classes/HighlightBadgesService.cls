/************************************************************************
 * @description The HighlightBadgesService provides badges relevant to a particular user and record page
 * 
 * @author SerkinSolutions
 * @date 2024
 ************************************************************************/
public with sharing class HighlightBadgesService {

    public Id displayRecordId {get; private set;}
    public String displayObjectType {get; private set;}

    public HighlightBadgesService(String recordId, String sObjectType) {
        this.displayRecordId = Id.valueOf( recordId );
        this.displayObjectType = sObjectType;
    }

    /****************************************************
     * Constants
     ****************************************************/
    // Platform cache
    private static final String CACHE_KEY_PREFIX = 'bdgs';
    private static final String CACHE_PARTITION_NAME = 'HighlightBadges';

    // Alerts
    private static final String ALERT_FREQUENCY_ALWAYS = 'Always';
    private static final String ALERT_TYPE_TOAST = 'Toast';

    // Badge styles and display
    private static final String DEFAULT_BACKGROUND_COLOR = '#D3D3D3';
    private static final String DEFAULT_LABEL_COLOR = '#000000';
    private static final String DEFAULT_ICON_NAME = 'utility:info';
    private static final String DEFAULT_BADGE_FIELDSET = 'Name';
    private static final String MERGE_FIELD_REGEX = '\\{!.+?\\}';

    /**
     * Platform Cache - Session partition
     */
    private static Cache.SessionPartition sessionCachePartition;

    /**
     * User id of running user
     * Allows for :userId to be used in badge definition queries
     */
    private static Id userId = UserInfo.getUserId();

    /**
     * A map of field names to their common ancestor id
     * The field name is the api path from source to ancestor object
     * The ancestor id is the record id at the end of it
     */
    private Map<String, Id> mapAncestorIds;

    /****************************************************
     * Get active highlight badges for the display record id
     ****************************************************/
    public List<HighlightBadge> getBadges() {
        List<Highlight_Badge_Definition__c> lstBadgeDefinitions = queryForBadgeDefinitions(
            displayObjectType, null
        );
        List<HighlightBadge> lstBadges = getBadgeWrappers(lstBadgeDefinitions);
        return lstBadges;
    }

    /****************************************************
     * Get a previewed, inactive badge, along with all active 
     * badges for the display record id.
     ****************************************************/
    public List<HighlightBadge> getBadges(Id previewDefinitionId) {
        List<Highlight_Badge_Definition__c> lstBadgeDefinitions = queryForBadgeDefinitions(
            displayObjectType, new Set<Id>{ previewDefinitionId }
        );
        List<HighlightBadge> lstBadges = getBadgeWrappers(lstBadgeDefinitions);
        return lstBadges;
    }

    /****************************************************
     * Get a list of HighlightBadge data wrappers.
     ****************************************************/
    private List<HighlightBadge> getBadgeWrappers(
        List<Highlight_Badge_Definition__c> lstBadgeDefinitions
    ) {
        List<HighlightBadge> lstBadges = new List<HighlightBadge>();
        Map<String, Id> mapFieldNameToAncestorId = getAncestorIdMap(lstBadgeDefinitions);

        // For each badge definition, get relevant badges
        for (Highlight_Badge_Definition__c definition : lstBadgeDefinitions) {
            // Check query limit to ensure current query won't exceed it
            if (Limits.getQueries() == Limits.getLimitQueries()) {
                break;
            }

            String ancestorId = definition.Common_Ancestor_Object__c == definition.Display_Object__c 
                ? displayRecordId 
                : mapFieldNameToAncestorId.get(definition.Display_to_Ancestor_Path__c);
            HighlightBadgeQueryBuilder queryBuilder = new HighlightBadgeQueryBuilder(
                definition, 
                displayRecordId, 
                ancestorId
            );
            String strQuery = queryBuilder.getQueryString();

            List<SObject> queryResults;
            try {
                queryResults = Database.query(strQuery, AccessLevel.USER_MODE);
            } catch (System.QueryException ex) {
                // User does not have required object, FLS, or sharing access
                continue;
            }

            lstBadges.addAll( 
                constructHighlightBadges(queryResults, definition) 
            );
        }
        
        return lstBadges;
    }

    /****************************************************
     * Builds and returns a HighlightBadge object from the SObject and definition
     ****************************************************/
    private List<HighlightBadge> constructHighlightBadges(
        List<SObject> objs, 
        Highlight_Badge_Definition__c definition
    ) {
        List<HighlightBadge> lstBadges = new List<HighlightBadge>();

        // Create set to store label names to avoid duplicates
        Set<String> setLabelNames = new Set<String>();

        for (SObject obj : objs) {
            HighlightBadge badge = new HighlightBadge();
            badge.definitionId = definition.Id;
            badge.recordId = obj.Id;
            badge.sObjectType = definition.Source_Object__c;
            badge.sObjectTypeLabel = GlobalDescribeService.getDescribe(badge.sObjectType).getLabel();
            badge.label = getBadgeLabel(definition, obj);
            // Prevent duplicates
            if (setLabelNames.contains(badge.label)) {
                continue;
            } else {
                setLabelNames.add(badge.label);
            }
            badge.iconName = getBadgeIconName(definition);
            badge.styles = getBadgeColorStyle(definition) + getBadgeLabelStyle(definition);
            badge.backgroundColor = definition.Background_Color__c ?? DEFAULT_BACKGROUND_COLOR;
            badge.labelColor = definition.Label_Color__c ?? DEFAULT_LABEL_COLOR;
            badge.fieldSet = String.isBlank(definition.Source_Detail_Fields__c)
                ? getDefaultFieldSet(definition.Source_Object__c)
                : definition.Source_Detail_Fields__c.replaceAll('\\s+', '');

            // Badge has alert if alerts are enabled and either set to show every time, 
            // or this is the first user visit
            if (
                definition.Alert__c && 
                (definition.Alert_Frequency__c == ALERT_FREQUENCY_ALWAYS || verifyFirstBadgeView(badge.recordId))
            ) {
                badge.hasAlert = true;
                badge.alertMessage = getBadgeAlertMessage(definition, obj);
                badge.alertType = definition.Alert_Type__c ?? null;
                if (badge.alertType == ALERT_TYPE_TOAST) {
                    badge.toastVariant = definition.Toast_Variant__c;
                    badge.toastMode = definition.Toast_Mode__c;
                    badge.includeLabelInToast = definition.Include_Label_in_Toast__c;
                }

                // Confetti settings
                if (definition.Confetti__c) {
                    badge.hasConfetti = true;
                    badge.confettiNumber = definition.Confetti_Volume__c ?? 'normal';
                    badge.confettiSize = definition.Confetti_Size__c ?? 'medium';
                }
            }

            // Add actions to badge
            badge.actions = constructBadgeActions(definition, obj);
            
            lstBadges.add(badge);
        }

        return lstBadges;
    }

    /****************************************************
     * Wrap child Highlight_Badge_Actions__r as HighlightBadge.Action objects
     ****************************************************/
    private List<HighlightBadge.Action> constructBadgeActions(
        Highlight_Badge_Definition__c definition,
        SObject record
    ) {
        List<HighlightBadge.Action> lstActions = new List<HighlightBadge.Action>();
        for (Highlight_Badge_Action__c hba : definition.Highlight_Badge_Actions__r) {
            HighlightBadge.Action a = new HighlightBadge.Action();
            a.id = hba.Id;
            a.sortOrder = hba.Sort_Order__c;
            a.recordTypeName = hba.RecordType.Name;
            a.navigationType = hba.Navigation_Type__c;
            a.url = hba.Navigation_Type__c == 'View Source Record' ? '/' + record.Id : hba.URL__c;
            a.flowType = hba.Flow_Type__c;
            a.flowApiName = hba.Flow_API_Name__c;
            a.includeRecordId = hba.Include_Record_ID__c;
            a.includeDisplayRecordId = hba.Include_Display_Record_ID__c;
            a.label = hba.Label__c;
            a.variant = hba.Variant__c;
            a.iconName = hba.Icon_Name__c;
            a.iconPosition = hba.Icon_Position__c;
            lstActions.add(a);
        }
        return lstActions;
    }

    /****************************************************
     * Map of api paths to ancestor object id
     * Find the ancestor record id from the Source to Ancestor Path
     ****************************************************/
    private Map<String, Id> getAncestorIdMap(
        List<Highlight_Badge_Definition__c> lstDefinitions
    ) {
        if (mapAncestorIds != null) {
            return mapAncestorIds;
        }
        
        mapAncestorIds = new Map<String, Id>();
        Set<String> setAncestorFields = new Set<String>();
        for (Highlight_Badge_Definition__c def : lstDefinitions) {
            if (def.Display_Object__c != def.Common_Ancestor_Object__c) {
                setAncestorFields.add(def.Display_to_Ancestor_Path__c);
            }
        }

        // No need to query if the only ancestor id is the record id of the display record
        if (setAncestorFields.isEmpty()) {
            return mapAncestorIds;
        }

        List<String> lstAncestorFields = new List<String>();
        lstAncestorFields.addAll(setAncestorFields);

        String strQuery = 'SELECT ' + String.join(lstAncestorFields, ', ') + 
            ' FROM ' + displayObjectType + 
            ' WHERE Id = \'' + displayRecordId + '\' LIMIT 1';

        List<SObject> lstObjs = Database.query(strQuery, AccessLevel.USER_MODE);
        for (String fieldName : setAncestorFields) {
            // If the field path traverses objects, we have to do some more work to find the record id
            if (fieldName.contains('.')) {
                // Resolve field path that uses dot notation
                mapAncestorIds.put(fieldName, resolveFieldPath(lstObjs[0], fieldName));
            } else {
                // Direct field access
                mapAncestorIds.put(fieldName, (Id) lstObjs[0].get(fieldName) );
            }
        }
        return mapAncestorIds;
    }

    /****************************************************
     * Returns the value for a given sObject and field path
     * @param sObject The base object
     * @param String The field path for the value to return
     ****************************************************/
    private static Id resolveFieldPath(
        sObject record,
        String fieldPath
    ) {
        List<String> pathParts = fieldPath.split('\\.');
        sObject currentRecord = record;

        for (Integer i = 0; i < pathParts.size() - 1; i++) {
            String part = pathParts[i];
            currentRecord = (sObject) currentRecord.getSObject(part);

            if (currentRecord == null) {
                // Early exit if the relationship does not exist or is null
                return null;
            }
        }

        // Get final part of string to find value from the top level object
        String finalPart = pathParts[pathParts.size() - 1];
        return (Id) currentRecord.get(finalPart);
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

    /****************************************************
     * Returns a string that can be referenced in an html style attribute
     *     to display the badge's defined background color (or default)
     * @param Highlight_Badge_Definition__c The definition record
     *     to get the badge color for
     ****************************************************/
    public static String getBadgeColorStyle(
        Highlight_Badge_Definition__c definition
    ) {
        String hexColor = definition.Background_Color__c != null ? definition.Background_Color__c : DEFAULT_BACKGROUND_COLOR;
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
        String labelHexColor = definition.Label_Color__c != null ? definition.Label_Color__c : DEFAULT_LABEL_COLOR;
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
     * Returns true if this is the running user's first visit to this
     *     record page in the current session and caches the current
     *     visit. Returns false if a visit is found in the session cache
     * @param String Record Id
     ****************************************************/
    private static Boolean verifyFirstBadgeView(
        String badgeId
    ) {
        Boolean isFirstView = true;
        // Create cache key out of user and badge ids
        String userId = UserInfo.getUserId();
        String cacheBadgeKey = CACHE_KEY_PREFIX + userId + badgeId;
        // Create instance of session partition
        Cache.SessionPartition part = getSessionCachePartition( Util.prefixCacheNamespace(CACHE_PARTITION_NAME) );
        if (part.contains(cacheBadgeKey)) {
            isFirstView = false;
        } else {
            part.put(cacheBadgeKey, Datetime.now());
        }
        return isFirstView;
    }

    /****************************************************
     * Ensures session cache partition is only retrieved a single time
     * @param String Session cache partition name
     ****************************************************/
    private static Cache.SessionPartition getSessionCachePartition(
        String cachePartitionName
    ) {
        if (sessionCachePartition == null) {
            sessionCachePartition = Cache.Session.getPartition(cachePartitionName);
        }
        return sessionCachePartition;
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
        Map<String, Schema.SObjectField> fieldMap = obj.getSObjectType().getDescribe().fields.getMap();
        Map<String,Object> mapObjFields = obj.getPopulatedFieldsAsMap();

        Pattern p = Pattern.compile(MERGE_FIELD_REGEX);
        Matcher m = p.matcher(result);

        while(m.find()) {
            String fieldApiName = m.group().substring(2, m.group().length() - 1);
            if (mapObjFields.containsKey(fieldApiName)) {
                Object fieldValue = mapObjFields.get(fieldApiName);
                Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldApiName).getDescribe();
                String formattedValue = formatFieldValue(fieldValue, fieldDescribe);
                result = result.replace(m.group(0), formattedValue);
            } else {
                result = result.replace(m.group(0), '');
            }
        }
        return result;
    }

    /****************************************************
     * Format field values based on data type
     * @param Object The field value
     * @param Schema.DescribeFieldResult field describe for the provided field
     * @return String Formatted field value
     ****************************************************/
    @TestVisible
    private static String formatFieldValue(
        Object fieldValue, 
        Schema.DescribeFieldResult fieldDescribe
    ) {
        if (fieldValue == null) return '';

        Schema.DisplayType fieldType = fieldDescribe.getType();

        if (fieldType == Schema.DisplayType.DATE) {
            Date dateValue = (Date) fieldValue;
            return dateValue.format();
        } else if (fieldType == Schema.DisplayType.DATETIME) {
            Datetime datetimeValue = (Datetime) fieldValue;
            return datetimeValue.format();
        } else if (fieldType == Schema.DisplayType.CURRENCY) {
            Decimal currencyValue = (Decimal) fieldValue;
            return '$' + currencyValue.format();
        } else {
            return String.valueOf(fieldValue);
        }
    }

    /****************************************************
     * Returns a valid, default field set for any sobject type
     * @param String The api name of the sObject type
     * @return String A comma-separated string of default fields
     ****************************************************/
    public static String getDefaultFieldSet(String sObjectType) {
        return GlobalDescribeService.getSObjectNameField(sObjectType);
    }

    /****************************************************
     * Query for active badge definition records
     * @param displayObject The api name of the source object
     * @param additionalDefinitionIds Optionally, include additional ids
     ****************************************************/
    private List<Highlight_Badge_Definition__c> queryForBadgeDefinitions(
        String displayObject,
        Set<Id> additionalDefinitionIds
    ) {
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
                           Flow_Type__c,
                           Flow_API_Name__c,
                           Include_Record_ID__c,
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
