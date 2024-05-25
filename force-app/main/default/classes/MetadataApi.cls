// This worked in a dev scratch org but in a subscriber org returns an unknown exception
public inherited sharing class MetadataApi {
    public static String queryMetadataApi(String body) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(
            Url.getOrgDomainUrl().toExternalForm() + '/services/Soap/m/60.0'
        );
        req.setMethod('POST');
        req.setHeader('Content-Type', 'text/xml');
        req.setHeader('SOAPAction', '""');
        req.setBody(body);
        HttpResponse r = new Http().send(req);
        return r.getBody().toString();
    }

    public static String genGetConnectedAppXml() {
        return '<?xml version="1.0" encoding="UTF-8"?>' +
            '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns="http://soap.sforce.com/2006/04/metadata">' +
            '   <soapenv:Header>' +
            '      <SessionHeader>' +
            '         <sessionId>' +
            getSessionId() +
            '</sessionId>' +
            '      </SessionHeader>' +
            '   </soapenv:Header>' +
            '   <soapenv:Body>' +
            '      <readMetadata>' +
            '         <type>ConnectedApp</type>' +
            '         <fullNames>gfrc__G_Force</fullNames>' +
            '      </readMetadata>' +
            '   </soapenv:Body>' +
            '</soapenv:Envelope>';
    }

    private static String getSessionId() {
        String content = Page.gfrc__SessionID.getContent().toString();
        Integer s = content.indexOf('###start###') + '###start###'.length();
        Integer e = content.indexOf('###end###');
        return content.substring(s, e);
    }

    // Potentially, an automated way to set the user for the connected app with client credentials enabled. Sadly, at
    // the moment of testing returned an unexpected error
    private static String genUpdateUserXml() {
        return '<?xml version="1.0" encoding="UTF-8"?>' +
            '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:met="http://soap.sforce.com/2006/04/metadata">' +
            '   <soapenv:Header>' +
            '      <SessionHeader>' +
            '         <sessionId>' +
            getSessionId() +
            '</sessionId>' +
            '      </SessionHeader>' +
            '   </soapenv:Header>' +
            '   <soapenv:Body xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' +
            '      <updateMetadata>' +
            '         <metadata xsi:type="ConnectedApp">' +
            '            <fullName>gfrc__G_Force</fullName>' +
            '            <label>G-Force</label>' +
            '            <contactEmail>chethelesser+gforce@gmail.com</contactEmail>' +
            '            <oauthConfig>' +
            '               <scopes>Full</scopes>' +
            '               <scopes>RefreshToken</scopes>' +
            '               <isClientCredentialEnabled>true</isClientCredentialEnabled>' +
            '               <oauthClientCredentialUser>' +
            UserInfo.getUserName() +
            '</oauthClientCredentialUser>' +
            '            </oauthConfig>' +
            '         </metadata>' +
            '      </updateMetadata>' +
            '   </soapenv:Body>' +
            '</soapenv:Envelope>';
    }
}
