public inherited sharing class NamedCreds {
    public static ConnectApi.NamedCredential getNamedCred() {
        try {
            return ConnectApi.NamedCredentials.getNamedCredential(
                Constants.NAMED_CREDENTIAL
            );
        } catch (ConnectApi.ConnectApiException e) {
            return null;
        }
    }

    public static Boolean checkIfAuthParamExists() {
        ConnectApi.Credential cred = ConnectApi.NamedCredentials.getCredential(
            Constants.EXTERNAL_CREDENTIAL,
            Constants.PRINCIPAL,
            ConnectApi.CredentialPrincipalType.NamedPrincipal
        );

        return cred.credentials.containsKey(Constants.TOKEN_KEY);
    }

    public static void createExternalCred(String token) {
        ConnectApi.ExternalCredentialInput externalCredentialInput = new ConnectApi.ExternalCredentialInput();
        externalCredentialInput.developerName = Constants.EXTERNAL_CREDENTIAL;
        externalCredentialInput.masterLabel = 'Gitlab API';
        externalCredentialInput.authenticationProtocol = ConnectApi.CredentialAuthenticationProtocol.Custom;

        ConnectApi.ExternalCredentialPrincipalInput principalInput = new ConnectApi.ExternalCredentialPrincipalInput();
        principalInput.principalName = Constants.PRINCIPAL;
        principalInput.principalType = ConnectApi.CredentialPrincipalType.NamedPrincipal;
        principalInput.sequenceNumber = 1;
        externalCredentialInput.principals = new List<ConnectApi.ExternalCredentialPrincipalInput>{
            principalInput
        };
        ConnectApi.NamedCredentials.createExternalCredential(
            externalCredentialInput
        );

        if (!Test.isRunningTest()) {
            List<ConnectApi.ExternalCredentialPrincipal> principals = ConnectApi.NamedCredentials.getExternalCredential(
                    Constants.EXTERNAL_CREDENTIAL
                )
                .principals;

            PermissionSet permissionSet = [
                SELECT Id
                FROM PermissionSet
                WHERE ProfileId = :UserInfo.getProfileId()
                LIMIT 1
            ];

            if (permissionSet != null) {
                insert new SetupEntityAccess(
                    ParentId = permissionSet.Id,
                    SetupEntityId = principals[0].id
                );
            }
        }

        addAuthParam(token);
    }

    // TODO: do this synchronously from the perspective of the component
    @Future
    private static void addAuthParam(String token) {
        ConnectApi.CredentialValueInput cvi = new ConnectApi.CredentialValueInput();
        cvi.encrypted = false;
        cvi.value = token;

        ConnectApi.CredentialInput input = new ConnectApi.CredentialInput();
        input.externalCredential = Constants.EXTERNAL_CREDENTIAL;
        input.authenticationProtocol = ConnectApi.CredentialAuthenticationProtocol.Custom;
        input.principalType = ConnectApi.CredentialPrincipalType.NamedPrincipal;
        input.principalName = Constants.PRINCIPAL;
        input.credentials = new Map<String, ConnectApi.CredentialValueInput>{
            Constants.TOKEN_KEY => cvi
        };

        ConnectApi.NamedCredentials.createCredential(input);
    }

    public static String createNamedCredForUrl(String gitlabUrl) {
        List<ConnectApi.ExternalCredentialInput> externalCredentials = new List<ConnectApi.ExternalCredentialInput>();
        ConnectApi.ExternalCredentialInput externalCredentialInput = new ConnectApi.ExternalCredentialInput();
        externalCredentialInput.developerName = Constants.EXTERNAL_CREDENTIAL;
        externalCredentials.add(externalCredentialInput);

        ConnectApi.NamedCredentialInput namedCredentialInput = new ConnectApi.NamedCredentialInput();
        namedCredentialInput.developerName = Constants.NAMED_CREDENTIAL;
        namedCredentialInput.masterLabel = 'GitLab API';
        namedCredentialInput.type = ConnectApi.NamedCredentialType.SecuredEndpoint;
        namedCredentialInput.calloutUrl = gitlabUrl + '/api/v4';
        namedCredentialInput.externalCredentials = externalCredentials;

        ConnectApi.NamedCredentialCalloutOptionsInput calloutOptions = new ConnectApi.NamedCredentialCalloutOptionsInput();
        calloutOptions.generateAuthorizationHeader = false;
        calloutOptions.allowMergeFieldsInHeader = true;
        calloutOptions.allowMergeFieldsInBody = false;
        namedCredentialInput.calloutOptions = calloutOptions;

        ConnectApi.CredentialCustomHeaderInput headerInput = new ConnectApi.CredentialCustomHeaderInput();
        headerInput.headerName = 'Authorization';
        headerInput.sequenceNumber = 1;
        headerInput.headerValue =
            '{!\'Bearer \' & $Credential.' +
            Constants.EXTERNAL_CREDENTIAL +
            '.' +
            Constants.TOKEN_KEY +
            '}';

        ConnectApi.NamedCredentialParameterInput parameterInput = new ConnectApi.NamedCredentialParameterInput();
        parameterInput.parameterName = 'Namespace';
        parameterInput.parameterType = ConnectApi.NamedCredentialParameterType.AllowedManagedPackageNamespaces;
        parameterInput.parameterValue = Constants.NAMESPACE;
        namedCredentialInput.parameters = new List<ConnectApi.NamedCredentialParameterInput>{
            parameterInput
        };
        namedCredentialInput.customHeaders = new List<ConnectApi.CredentialCustomHeaderInput>{
            headerInput
        };

        ConnectApi.NamedCredential namedCredential = ConnectApi.NamedCredentials.createNamedCredential(
            namedCredentialInput
        );
        return Url.getOrgDomainUrl().toExternalForm() +
            '/lightning/setup/NamedCredential/' +
            namedCredential.id +
            '/view';
    }
}
