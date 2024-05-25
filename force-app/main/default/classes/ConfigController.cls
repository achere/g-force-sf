public with sharing class ConfigController {
    @AuraEnabled
    public static void reportConnectedAppToBeSetup() {
        Settings__c settings = Settings__c.getOrgDefaults();
        settings.IsConnectedAppReportedToBeSetUp__c = true;
        upsert settings;
    }

    @AuraEnabled
    public static String getData() {
        try {
            return JSON.serialize(generateSetupData());
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @TestVisible
    private class SetupData {
        @TestVisible
        Boolean isConnectedAppSetup;
        @TestVisible
        String namedCredId;
        @TestVisible
        String gitlabUrl;
        @TestVisible
        Boolean isNamedCredEnabled;
        @TestVisible
        Boolean isGitlabTokenSet;
    }

    @AuraEnabled
    public static void saveNamedCred(String url, String token) {
        try {
            NamedCreds.createExternalCred(token);
            NamedCreds.createNamedCredForUrl(url);
        } catch (ConnectApi.ConnectApiException e) {
            // Any unhandled Connect exceptions means named credentials and auth param already exist, so ignoring them
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String getProjectIdFromSettings() {
        Settings__c settings = Settings__c.getOrgDefaults();
        return String.isNotBlank(settings.GitlabProjectId__c)
            ? settings.GitlabProjectId__c
            : '';
    }

    @AuraEnabled
    public static String getBranches(String projectId) {
        try {
            return JSON.serialize(GitlabApi.getBranches(projectId));
        } catch (GitlabApi.GitlabApiException e) {
            switch on e.status {
                when NotFound {
                    throw new AuraHandledException('Project not found');
                }
                when Forbidden {
                    throw new AuraHandledException(
                        'Authorisation information incorrect'
                    );
                }
                when else {
                    throw new AuraHandledException('Unknown error occurred');
                }
            }
        }
    }

    @AuraEnabled
    public static void saveProjectId(String projectId) {
        Settings__c settings = Settings__c.getOrgDefaults();
        settings.GitlabProjectId__c = projectId;
        upsert settings;
    }

    @AuraEnabled
    public static void claimBranch(String branchName, String apiVersion) {
        String projectId = Settings__c.getOrgDefaults().GitlabProjectId__c;
        if (String.isBlank(projectId)) {
            throw new AuraHandledException(
                'Gitlab project ID has to be set to claim a branch'
            );
        }
        GitlabApi.createApexcovVar(projectId, branchName, apiVersion);
    }

    private static SetupData generateSetupData() {
        SetupData data = new SetupData();
        data.isConnectedAppSetup = checkIfConnectedAppUserIsSetup();
        if (!data.isConnectedAppSetup) {
            return data;
        }

        ConnectApi.NamedCredential cred = NamedCreds.getNamedCred();
        if (cred == null) {
            return data;
        }
        data.namedCredId = cred.id;
        data.isNamedCredEnabled =
            cred.calloutStatus == ConnectApi.CalloutStatus.Enabled;
        data.gitlabUrl = cred.calloutUrl;
        data.isGitlabTokenSet = NamedCreds.checkIfAuthParamExists();

        return data;
    }

    private static Boolean checkIfConnectedAppUserIsSetup() {
        Settings__c settings = Settings__c.getOrgDefaults();
        return settings.IsConnectedAppReportedToBeSetUp__c;
    }
}
