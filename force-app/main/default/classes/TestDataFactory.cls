@IsTest
public class TestDataFactory {
    
    private static final String ALERT_FREQUENCY_ALWAYS = 'Always';
    private static final String ALERT_FREQUENCY_ONCE_PER_SESSION = 'Once Per Session';
    private static final String DEFAULT_CASE_STATUS = 'New';
    private static final String DEFAULT_CASE_ORIGIN = 'Phone';
    private static final String DEFAULT_OPP_STAGE = 'Prospecting';
    private static final String SYSTEM_ADMIN_PROFILE_NAME = 'System Administrator';

    public static List<Account> createAccounts(
        Integer numberOfRecords
    ) {
        List<Account> lstAccounts = new List<Account>();
        for (Integer i = 0; i < numberOfRecords; i++) {
            lstAccounts.add(
                new Account(Name = 'Test Account ' + String.valueOf(i))
            );
        }
        return lstAccounts;
    }

    public static List<Contact> createContacts(
        List<Account> lstAccounts, 
        Integer numberOfRecords
    ) {
        List<Contact> lstContacts = new List<Contact>();
        for (Account acc : lstAccounts) {
            for (Integer i = 0; i < numberOfRecords; i++) {
                lstContacts.add(
                    new Contact(
                        FirstName = 'Test Account ' + String.valueOf(i), 
                        LastName = 'Tester', 
                        AccountId = acc.Id
                    )
                );
            }
        }
        return lstContacts;
    }

    public static List<Case> createCases(
        List<Contact> lstContacts,
        Integer numberOfRecords
    ) {
        List<Case> lstCases = new List<Case>();
        for (Contact ct : lstContacts) {
            for (Integer i = 0; i < numberOfRecords; i++) {
                lstCases.add(
                    new Case(
                        ContactId = ct.Id, 
                        AccountId = ct.AccountId, 
                        Subject = 'Test Case ' + String.valueOf(i), 
                        Status = DEFAULT_CASE_STATUS, 
                        Origin = DEFAULT_CASE_ORIGIN
                    )
                );
            }
        }
        return lstCases;
    }

    public static List<Opportunity> createOpportunities(
        List<Contact> lstContacts,
        Integer numberOfRecords
    ) {
        List<Opportunity> lstOpps = new List<Opportunity>();
        for (Contact ct : lstContacts) {
            for (Integer i = 0; i < numberOfRecords; i++) {
                lstOpps.add(
                    new Opportunity(
                        ContactId = ct.Id, 
                        AccountId = ct.AccountId, 
                        Name = 'Test Opp ' + String.valueOf(i), 
                        StageName = DEFAULT_OPP_STAGE, 
                        CloseDate = Date.today(), 
                        Amount = 10000
                    )
                );
            }
        }
        return lstOpps;
    }

    public static List<Highlight_Badge_Definition__c> getTestDefinitions() {
        List<Highlight_Badge_Definition__c> lstDefinitions = new List<Highlight_Badge_Definition__c>();

        // Open case for contact
        lstDefinitions.add(
            new Highlight_Badge_Definition__c(
                Active__c = true, 
                Display_Object__c = 'Contact', 
                Source_Object__c = 'Case', 
                Common_Ancestor_Object__c = 'Contact', 
                Source_to_Ancestor_Path__c = 'ContactId', 
                Display_to_Ancestor_Path__c = 'Id', 
                Filter_Criteria__c = 'IsClosed = false', 
                Source_Detail_Fields__c = 'CaseNumber, Subject, Status, Origin', 
                Label__c = 'Open Case #{!CaseNumber}', 
                Icon_Name__c = 'utility:case', 
                Sort_Order__c = 5.00, 
                Order_By__c = 'CaseNumber ASC', 
                Limit__c = 3, 
                Alert__c = true, 
                Alert_Type__c = 'Modal', 
                Alert_Message__c = 'Test important case alert',
                Alert_Frequency__c = ALERT_FREQUENCY_ALWAYS
            )
        );

        // Open opportunity for parent account of contact
        lstDefinitions.add(
            new Highlight_Badge_Definition__c(
                Active__c = true, 
                Display_Object__c = 'Contact', 
                Source_Object__c = 'Opportunity', 
                Common_Ancestor_Object__c = 'Account', 
                Source_to_Ancestor_Path__c = 'AccountId', 
                Display_to_Ancestor_Path__c = 'AccountId', 
                Filter_Criteria__c = 'Amount > 1000', 
                Source_Detail_Fields__c = 'Name, StageName, Amount', 
                Label__c = 'Big Opp', 
                Alert__c = true, 
                Alert_Type__c = 'Toast', 
                Alert_Message__c = 'Test important opp alert for {!Name}', 
                Alert_Frequency__c = ALERT_FREQUENCY_ONCE_PER_SESSION, 
                Toast_Variant__c = 'success', 
                Toast_Mode__c = 'sticky',
                Confetti__c = true,
                Confetti_Size__c = 'Large',
                Confetti_Volume__c = 'Plenty'
            )
        );

        // Complex field path - cases with opportunities from shared contact.account
        lstDefinitions.add(
            new Highlight_Badge_Definition__c(
                Active__c = true, 
                Name = 'Cases with Opps from Shared Account', 
                Display_Object__c = 'Case', 
                Source_Object__c = 'Opportunity', 
                Common_Ancestor_Object__c = 'Account', 
                Source_to_Ancestor_Path__c = 'AccountId', 
                Display_to_Ancestor_Path__c = 'Contact.AccountId', 
                Filter_Criteria__c = '', 
                Source_Detail_Fields__c = 'StageName, AccountId, Amount', 
                Label__c = 'Account has an open opportunity'
            )
        );

        return lstDefinitions;
    }

    public static List<Highlight_Badge_Action__c> getTestActions(
        List<Highlight_Badge_Definition__c> lstDefinitions
    ) {
        Id recTypeId = Schema.SObjectType.Highlight_Badge_Action__c.getRecordTypeInfosByDeveloperName().get('Navigation').getRecordTypeId();
        List<Highlight_Badge_Action__c> lstActions = new List<Highlight_Badge_Action__c>();
        for (Highlight_Badge_Definition__c hbd : lstDefinitions) {
            Highlight_Badge_Action__c act = new Highlight_Badge_Action__c();
            act.Highlight_Badge_Definition__c = hbd.Id;
            act.Name = 'Really Helpful Website';
            act.Description__c = 'My action description';
            act.Label__c = 'Really Helpful Website';
            act.RecordTypeId = recTypeId;
            act.Navigation_Type__c = 'Web Page';
            act.URL__c = 'https://www.mets.com';
            act.Active__c = true;
            act.Sort_Order__c = 1.00;
            act.Variant__c = 'brand';
            act.Icon_Name__c = 'action:web_link';
            act.Icon_Position__c = 'Left';
            lstActions.add(act);
        }
        return lstActions;
    }

    public static User createTestUser(
        String firstName, 
        String lastName, 
        String permissionLevel
    ) {
        String orgId      = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ', '').replace(':', '').replace('-', '');
        Integer randomInt = Integer.valueOf(Math.rint(Math.random() * 1000000));
        String uniqueName = orgId + dateString + randomInt;

        Profile profile = [SELECT Id FROM Profile WHERE Name = :SYSTEM_ADMIN_PROFILE_NAME LIMIT 1];

        User u = new User();
        u.IsActive          = true;
        u.TimeZoneSidKey    = UserInfo.getTimeZone().toString();
        u.LocaleSidKey      = UserInfo.getLocale();
        u.LanguageLocaleKey = UserInfo.getLocale();
        u.EmailEncodingKey  = 'ISO-8859-1';
        u.Username          = uniqueName + '@test' + orgId + '.org';
        u.Email             = uniqueName + '@test' + orgId + '.org';
        u.FirstName         = firstName;
        u.LastName          = lastName;
        u.Alias             = uniqueName.substring(18, 23);
        u.ProfileId         = profile.Id;
        insert u;

        // Assign permission set
        if (permissionLevel != null) {
            String permSetName = 'Highlight_Badges_' + permissionLevel;
            PermissionSet permSet = [SELECT Id FROM PermissionSet WHERE Name = :permSetName LIMIT 1];
            insert new PermissionSetAssignment(
                AssigneeId = u.Id,
                PermissionSetId = permSet.Id
            );
        }
        return u;
    }

    private static Integer fakeIdNumber = 1;

    /**
     * Get fake id for sobject type
     * @param Schema.SObjectType - SObject type for the fake id
     * @return Id - Random id with the key prefix of the provided SObject type
     */
    public static Id getFakeId(Schema.SObjectType sObjectType) {
		String result = String.valueOf(fakeIdNumber++);
		return (Id) (sObjectType.getDescribe().getKeyPrefix() +
            '0'.repeat(12 - result.length()) +
            result);
	}

}