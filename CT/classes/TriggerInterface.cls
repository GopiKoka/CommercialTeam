public interface TriggerInterface {
    /**
     * This method is called prior to execution of a BEFORE trigger. Use this to cache
     * any data required into maps prior execution of the trigger.
     */
    void bulkBefore();
 
    /**
     * This method is called prior to execution of an AFTER trigger. Use this to cache
     * any data required into maps prior execution of the trigger.
     */
    void bulkAfter();
 
    /**
     * This method is called iteratively for each record to be inserted during a BEFORE
     * trigger. Never execute any SOQL/SOSL etc in this and other iterative methods.
     */
    void beforeInsert(SObject so);
 
    /**
     * This method is called iteratively for each record to be updated during a BEFORE
     * trigger.
     */
    void beforeUpdate(SObject oldSo, SObject so);
 
    /**
     * This method is called iteratively for each record to be deleted during a BEFORE
     * trigger.
     */
    void beforeDelete(SObject so);
 
    /**
     * This method is called iteratively for each record inserted during an AFTER
     * trigger. Always put field validation in the 'After' methods in case another trigger
     * has modified any values. The record is 'read only' by this point.
     */
    void afterInsert(SObject so);
 
    /**
     * This method is called iteratively for each record updated during an AFTER
     * trigger.
     */
    void afterUpdate(SObject oldSo, SObject so);
 
    /**
     * This method is called iteratively for each record deleted during an AFTER
     * trigger.
     */
    void afterDelete(SObject so);
 
    /**
     * This method is called once all records have been processed by the trigger. Use this
     * method to accomplish any final operations such as creation or updates of other records.
     */
    void andFinally();
    
}