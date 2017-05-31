#explain
(select t.*,
sum(if(ili.IsDeleted=0,ili.Total_Line_Amount__c,0)) as 'Invoiced',
group_concat(distinct if(ili.IsDeleted=0,ili.CurrencyIsoCode,null)) as 'Invoiced Currency',
group_concat(distinct if(ili.IsDeleted=0 and i.IsDeleted=0, i.Name, null)) as 'Invoice',
group_concat(distinct if(ili.IsDeleted=0 and i.IsDeleted=0, i.Id, null)) as 'Invoice Id'
from 
(select 
wi.Id as 'Work Item Id', 
wi.Name as 'Work Item', 
wi.Primary_Standard__c as 'Primary Standard', 
wi.Work_Item_Date__c as 'Work Item Date', 
wi.Work_Item_Stage__c as 'Work Item Type', 
wi.Status__c as 'Work Item Status', 
r.Name as 'Author', 
r.Reporting_Business_Units__c as 'Author Reporting Business Unit',
r.Resource_Type__c as 'Resource Type',
wi.Required_Duration__c as 'Work Item Required Duration',
sum(if(tsli.IsDeleted=0,tsli.Scheduled_Hours__c,0)) as 'TSLI Scheduled Duration', 
sum(if(tsli.IsDeleted=0, tsli.Actual_Hours__c,0)) as 'Total Actual Hours', 
sum(if(tsli.IsDeleted=0 and tsli.Billable__c='Pre-paid', tsli.Actual_Hours__c,0)) as 'Pre-paid Hours',
sum(if(tsli.IsDeleted=0 and tsli.Billable__c='Billable', tsli.Actual_Hours__c,0)) as 'Billable Hours',
sum(if(tsli.IsDeleted=0 and tsli.Billable__c='Non-Billable', tsli.Actual_Hours__c,0)) as 'Non-Billable Hours',
sum(if(tsli.IsDeleted=0 and tsli.Category__c='Audit', tsli.Actual_Hours__c,0)) as 'Audit Hours',
sum(if(tsli.IsDeleted=0 and tsli.Category__c='Travel', tsli.Actual_Hours__c,0)) as 'Travel Hours',
sum(if(tsli.IsDeleted=0 and tsli.Category__c='Report Writing', tsli.Actual_Hours__c,0)) as 'Report Writing Hours',
sum(if(tsli.IsDeleted=0 and tsli.Category__c='Client Management', tsli.Actual_Hours__c,0)) as 'Client Management Hours',
sum(if(tsli.IsDeleted=0 and tsli.Category__c not in ('Audit','Travel','Report Writing','Client Management'), tsli.Actual_Hours__c,0)) as 'Other Hours',
count(distinct tsli.Resource_Name__c) as '# Resources'
from salesforce.work_item__c wi
inner join salesforce.resource__c r on wi.RAudit_Report_Author__c = r.Id
left join salesforce.timesheet_line_item__c tsli on tsli.Work_Item__c = wi.Id
where 
wi.Primary_Standard__c like '%BRC%'
and r.Reporting_Business_Units__c like 'EMEA%'
and wi.Status__c not in ('Cancelled', 'Draft', 'Inititate Service') 
group by wi.Id) t
left join salesforce.invoice_line_item__c ili on ili.Work_Item__c = t.`Work Item Id`
left join salesforce.invoice__c i on ili.Invoice__c = i.Id
group by t.`Work Item Id`);

select * from salesforce.invoice_line_item__c where Invoice__c='a2Hd0000000MbM7EAK';