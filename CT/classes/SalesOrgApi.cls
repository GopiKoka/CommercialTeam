/**
 *  REST API class : Its used to Receive data from MedicalOrg to CommecialOrg
 */

@RestResource(urlMapping='/salesorg/*')
global with sharing class SalesOrgApi {
    /*
        @Description : Receiving serialize data and then deserialize Data to perform DML Operations
        Input :  Serialized data
        output : Performing DML to objects
    */
    @HttpPost
    global static void doPost() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        List<Sobject> records = new List<Sobject>();
        //data from body
        String jsonBody = req.RequestBody.toString();
        if (!String.isBlank(jsonBody)) { 
            records = (List<Sobject>) Json.deserialize(jsonBody,List<Sobject>.class);
        }
        if(records != null && records.size() > 0){
            for(Sobject s:records){
                s.id = null;
            }
            Map<String,String> tokensMap = pathParams(req.requestURI);
            String sObjectName = tokensMap.get('salesorg');
            Schema.SObjectType objectType = Schema.getGlobalDescribe().get(sObjectName);
            Map<String, SObjectField> fieldMap = objectType.getDescribe().fields.getMap();
            Schema.SObjectField ftoken = fieldMap.get('Unique_ID__c');
            try{
                Database.upsert(records,ftoken,true);
            }catch(DMLexception e){
                res.responseBody = Blob.valueOf('Error : '+e);
                res.StatusCode= 401;
                ExceptionHandling.handleException(sObjectName,e);
            }
            res.responseBody = Blob.valueOf('Successfully sent to commercial team');
            res.StatusCode= 200;
        }
    }
    
    /*
        @Description : Reading URL Parameters
        Input : requestURI : String URL
        output : return URL parameters with key and data
    */
    private static Map<String,String> pathParams( String url ) {
        // https://SFURL/apexservices/salesorg/SobjectName
        List<String> tokens = url.split('/');
        Map<String,String> tokensMap = new Map<String,String>();
        for( integer i = 1 ; i < tokens.size() ; i++ ) {
            tokensMap.put( tokens.get( i ), tokens.get( ++i ) );
        }
        return tokensMap;
    } 
}