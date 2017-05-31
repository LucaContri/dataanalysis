SELECT 
    wi.Name,
    DATE_FORMAT(wi.Service_target_date__c, '%Y %m') AS 'Period',
    wi.Required_Duration__c,
    wi.Primary_Standard__c,
    wi.Status__c,
    wi.Revenue_Ownership__c,
    r.Name,
    r.Resource_Type__c,
    tsli.Name,
    tsli.Billable__c,
    tsli.Category__c,
    tsli.scheduled_Hours__c,
    tsli.Actual_Hours__c
FROM
    salesforce.work_item__c wi
        INNER JOIN
    salesforce.recordtype rt ON wi.RecordTypeId = rt.Id
        inner join
    salesforce.timesheet_line_item__c tsli ON wi.Id = tsli.Work_Item__c
        inner join
    salesforce.resource__c r ON tsli.Resource_Name__c = r.Name
WHERE
    rt.Name = 'Audit'
        AND wi.Revenue_Ownership__c like 'AUS%'
        AND tsli.IsDeleted = 0
LIMIT 100000;