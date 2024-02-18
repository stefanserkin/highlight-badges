@IsTest
public class TestDataFactory {
    
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
                Common_Parent_Object__c = 'Contact', 
                Source_to_Parent_Path__c = 'ContactId', 
                Display_to_Parent_Path__c = 'Id', 
                Filter_Criteria__c = 'IsClosed = false', 
                Source_Detail_Fields__c = 'CaseNumber, Subject, Status, Origin', 
                Label__c = 'Open Case #{!CaseNumber}', 
                Icon_Name__c = 'utility:case', 
                Sort_Order__c = 5.00
            )
        );

        // Open opportunity for parent account of contact
        lstDefinitions.add(
            new Highlight_Badge_Definition__c(
                Active__c = true, 
                Display_Object__c = 'Contact', 
                Source_Object__c = 'Opportunity', 
                Common_Parent_Object__c = 'Account', 
                Source_to_Parent_Path__c = 'AccountId', 
                Display_to_Parent_Path__c = 'AccountId', 
                Filter_Criteria__c = 'Amount > 1000', 
                Source_Detail_Fields__c = 'Name, StageName, Amount', 
                Label__c = 'Big Opp'
            )
        );

        return lstDefinitions;
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

}