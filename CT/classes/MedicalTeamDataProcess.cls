/**
 *  Queueable class : Its used to send data from CommercialTeam to MedicalTeam with couple of objects
 *  Objects : Its Dynamic class used to send Sobject data
 *  prerequisite : 
 *  - Create Fieldset for Sobject
 *  - Create Unique_Id__c,Sent_to_CommercialTeam__c on Sobject to integrate
 *  - Call MedicalTeamDataProcess Queueable class when needed (Example : Check CaseHandler class how to call)
 *  - Create NamedCredentials to integrate
 */
public class MedicalTeamDataProcess implements Queueable, Database.AllowsCallouts {
    private List<String> externalIds = new List<String>();
    private string objectName;
    private list<Sobject> sendSobjectToMT = new list<Sobject>();
    public MedicalTeamDataProcess(set<String> externalId,String objectName){
        this.externalIds.addAll(externalId);
        this.objectName = objectName;
    }
    public void execute(QueueableContext context) {
        if(!externalIds.isEmpty()){
            sendInformationToMT();
        }
    }
    
    /*
        - Input : Integrate/Send sobject information to other environment
        - Output : Updating reponse from other environment
    */
    private void sendInformationToMT(){
        try{
            String dynamicSOQL = 'SELECT id ';
            for(Schema.FieldSetMember fld :readFieldSet(this.objectName+'FieldSet',this.objectName)) {
                dynamicSOQL += ', ' + fld.getFieldPath();
            }
            /*
            Issue : Hardcoded query need to be avoided
            TBD : Need to create custom object to maintain parentfields to send data
            */
            if(this.objectName == 'Case'){
                dynamicSOQL += ',Account.Unique_ID__c,FDA_Approved_Product__r.Unique_ID__c';
            }
            dynamicSOQL += ' FROM '+this.objectName+' WHERE Unique_Id__c IN : externalIds';
            List<SObject> sObj = Database.query(dynamicSOQL);
            String response = sendSobjectDatatoMT(sObj);
            if(response == 'OK'){
                for(Sobject obj:sObj){
                    obj.put('Sent_to_MedicalTeam__c','SENT');
                }
                update sObj;
            }
        }catch(Exception e){
            ExceptionHandling.handleException(this.objectName,e);
        }
    }
    
    /*
        - Input : Sobject FieldSetName and Sobject
        - Output : Return all fields added in fieldset
    */
    private List<Schema.FieldSetMember> readFieldSet(String fieldSetName, String ObjectName){
        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(ObjectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
        return fieldSetObj.getFields(); 
    }  
    
    /*
    - To send Sobject data from MedicalTeam to CommercialTeam
    - Named Credentials as endpoint
    */
    private String sendSobjectDatatoMT(List<Sobject> rBody){
        List<Sobject> caseRecords = new List<Sobject>();
        /*
        Issue : Hardcoded condition need to be avoided
        TBD : Avoid to send recordIDs from salesforce
        */
        if(objectName == 'case'){
            caseRecords = processCaseAttributes(rBody);
        }else{
            caseRecords.addAll(rBody);
        }
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint('callout:MedicalTeamLogins/services/apexrest/MTorg/'+objectName);  
        req.setHeader('content-type', 'application/json');
        req.setBody(JSON.serialize(caseRecords));
        Http http = new Http();
        HTTPResponse response = http.send(req);
        return response.getStatus();
    }
    
    /*
    Issue : Hardcoded condition need to be avoided
    TBD : Need to remove this function to avoid field mapping
    */
    
    private List<Sobject> processCaseAttributes(List<Sobject> rBody){
        List<Sobject> caseRecords = new List<Sobject>();
        for(Sobject s:rBody){
            Case c = (Case)s;
            Case tempCase = new Case();
            tempCase.Physician_Question__c = c.Physician_Question__c;
            tempCase.Answered_to_Physician__c = c.Answered_to_Physician__c ;
            tempCase.Unique_Id__c = c.Unique_Id__c;
            tempCase.Account = new Account();
            tempCase.Account.Unique_Id__c = c.Account.Unique_Id__c;
            tempCase.FDA_Approved_Product__r = new product2();
            tempCase.FDA_Approved_Product__r.Unique_Id__c = c.FDA_Approved_Product__r.Unique_Id__c;
            caseRecords.add(tempCase);
        }
        return caseRecords;
    }
}