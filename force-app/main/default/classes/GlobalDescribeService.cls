/************************************************************************
 * @description Caches global describe results
 * 
 * @author SerkinSolutions
 * @date 2024
 ************************************************************************/
public with sharing class GlobalDescribeService {
    
    private static Map<String, Schema.SObjectType> globalDescribe;
    private static Map<String, Schema.DescribeSObjectResult> describeCache = new Map<String, Schema.DescribeSObjectResult>();

    /****************************************************
     * Ensures global describe is only invoked once
     * @return Map<String, Schema.SObjectType> global describe
     ****************************************************/
    public static Map<String, Schema.SObjectType> getGlobalDescribe() {
        if (globalDescribe == null) {
            globalDescribe = Schema.getGlobalDescribe();
        }
        return globalDescribe;
    }

    /****************************************************
     * Returns the DescribeSObjectResult for a given SObjectType API name
     * @return Schema.DescribeSObjectResult describe result for the sobject type
     ****************************************************/
    public static Schema.DescribeSObjectResult getDescribe(
        String sObjectApiName
    ) {
        if (!describeCache.containsKey(sObjectApiName)) {
            Schema.SObjectType sObjectType = getGlobalDescribe().get(sObjectApiName);
            if (sObjectType != null) {
                Schema.DescribeSObjectResult describeResult = sObjectType.getDescribe();
                describeCache.put(sObjectApiName, describeResult);
            }
        }
        return describeCache.get(sObjectApiName);
    }

}