public inherited sharing class GitlabApi {
    public static Branch[] getBranches(String projectId) {
        String encodedProjectId = EncodingUtil.urlEncode(projectId, 'UTF-8');
        String branchBody = sendRequest(
            'GET',
            '/projects/' + encodedProjectId + '/repository/branches'
        );

        // Cannot parse properly because the response uses keyword 'protected' as key
        List<Object> branchesJson = (List<Object>) JSON.deserializeUntyped(
            branchBody
        );
        Map<String, Branch> branchesMap = new Map<String, Branch>();
        for (Object branchJson : branchesJson) {
            Map<String, Object> branchMap = (Map<String, Object>) branchJson;
            if ((Boolean) branchMap.get('protected')) {
                continue;
            }
            Branch branch = new Branch();
            branch.name = (String) branchMap.get('name');
            branchesMap.put(branch.name, branch);
        }

        String varBody = sendRequest(
            'GET',
            '/projects/' + encodedProjectId + '/variables'
        );
        List<Variable> vars = (List<Variable>) JSON.deserialize(
            varBody,
            List<Variable>.class
        );

        for (Variable var : vars) {
            if (
                !branchesMap.containsKey(var.environment_scope) ||
                var.key != Constants.CONFIG_VAR_NAME
            ) {
                continue;
            }
            Branch b = branchesMap.get(var.environment_scope);
            b.isClaimed = true;
            b.isThisOrg = var.value.containsIgnoreCase(
                Url.getOrgDomainUrl().toExternalForm()
            );
            if (b.isThisOrg) {
                b.apiVersion = var.value.substringAfter('"apiVersion":"')
                    .substringBefore('"');
            }
        }

        for (Branch b : branchesMap.values()) {
            if (b.isThisOrg == true) {
                continue;
            }
            b.isThisOrg = false;
            if (b.isClaimed == true) {
                continue;
            }
            b.isClaimed = false;
        }
        return branchesMap.values();
    }

    public static void createApexcovVar(
        String projectId,
        String envName,
        String apiVersion
    ) {
        ApexcovConfig config = new ApexcovConfig();
        config.apiVersion = apiVersion;
        config.clientId = Constants.CLIENT_ID;
        config.clientSecret = Constants.CLIENT_SECRET;
        config.baseUrl = Url.getOrgDomainUrl().toExternalForm();
        Variable var = new Variable();
        String encodedProjectId = EncodingUtil.urlEncode(projectId, 'UTF-8');
        var.id = encodedProjectId;
        var.variable_type = 'file';
        var.environment_scope = envName;
        var.key = Constants.CONFIG_VAR_NAME;
        var.value = JSON.serialize(config);
        sendRequest(
            'POST',
            '/projects/' + encodedProjectId + '/variables',
            var
        );
    }

    private static String sendRequest(String method, String relativeUrl) {
        return sendRequest(method, relativeUrl, null);
    }

    private static String sendRequest(
        String method,
        String relativeUrl,
        Object body
    ) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:' + Constants.NAMED_CREDENTIAL + relativeUrl);
        req.setMethod(method);
        if (body != null) {
            req.setBody(JSON.serialize(body));
            req.setHeader('Content-Type', 'application/json');
        }
        Http http = new Http();
        HttpResponse res = http.send(req);

        Integer statusCode = res.getStatusCode();
        String resBody = res.getBody();
        switch on statusCode {
            when 201 {
                return resBody;
            }
            when 200 {
                return resBody;
            }
            when 403 {
                throw new GitlabApiException(
                    'Calling ' + relativeUrl,
                    Status.Forbidden,
                    resBody
                );
            }
            when 404 {
                throw new GitlabApiException(
                    'Calling ' + relativeUrl,
                    Status.NotFound,
                    resBody
                );
            }
            when else {
                throw new GitlabApiException(
                    'Calling ' + relativeUrl,
                    Status.Unknown,
                    resBody
                );
            }
        }
    }

    public class GitlabApiException extends Exception {
        public Status status;
        public String body;

        public GitlabApiException(String message, Status status, String body) {
            this(message);
            this.status = status;
            this.body = body;
        }
    }

    public enum Status {
        NotFound,
        Forbidden,
        Unknown
    }

    public class Branch {
        public String name;
        public Boolean isClaimed;
        public Boolean isThisOrg;
        public String apiVersion;
    }

    private class Variable {
        String id;
        String key;
        String value;
        String environment_scope;
        String variable_type;
    }

    private class ApexcovConfig {
        String apiVersion;
        String baseUrl;
        String clientId;
        String clientSecret;
    }
}
