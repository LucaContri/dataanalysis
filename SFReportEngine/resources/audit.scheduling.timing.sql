#explain
(select 
	wi.Id, wi.Name as 'Work Item', 
    wi.Revenue_Ownership__c as 'Revenue Ownership',
    if(wi.Revenue_Ownership__c like 'AUS%', 'Australia', substring_index(wi.Revenue_Ownership__c, '-', 2)) as 'Region (from Rev. Own.)',
    if(wi.Revenue_Ownership__c like '%Food%', 'Food', if(wi.Revenue_Ownership__c like '%Product%', 'PS', 'MS')) as 'Stream',
    wi.Status__c as 'WI Status',
    wi.Service_Delivery_Type__c as 'Service Delivery Type',
    wi.Work_Item_Stage__c as 'WI Type',
    wi.Work_Item_Date__c as 'WI Start Date', 
    wi.Service_target_date__c as 'WI Target Date',
    a.Name as 'Audit Report Author',
    a.Reporting_Business_Units__c as 'Author Reporting Business Unit',
    wi.Primary_Standard__c as 'Primary Standard',
    scheduler.Name as 'Scheduler',
    group_concat(distinct if(wih.NewValue in ('Scheduled', 'Scheduled - Offered', 'Confirmed'), s.Name, null) order by s.Name) as 'Schedulers',
    count(distinct if(wih.NewValue in ('Scheduled', 'Scheduled - Offered', 'Confirmed'), s.Id, null) ) as 'Count Schedulers',
    min(if(wih.Field='Status__c' and wih.NewValue='Scheduled',  wih.createdDate, null)) as 'First Scheduled', 
    max(if(wih.Field='Status__c' and wih.NewValue='Scheduled',  wih.createdDate, null)) as 'Last Scheduled', 
    count(if(wih.Field='Status__c' and wih.NewValue='Scheduled',  wih.Id, null)) as 'Count of Scheduled',
    min(if(wih.Field='Status__c' and wih.NewValue='Scheduled - Offered',  wih.createdDate, null)) as 'First Scheduled Offered',
    max(if(wih.Field='Status__c' and wih.NewValue='Scheduled - Offered',  wih.createdDate, null)) as 'Last Scheduled Offered',
    count(if(wih.Field='Status__c' and wih.NewValue='Scheduled - Offered',  wih.Id, null)) as 'Count Scheduled Offered',
    min(if(wih.Field='Status__c' and wih.NewValue='Confirmed',  wih.createdDate, null)) as 'First Confirmed',
    max(if(wih.Field='Status__c' and wih.NewValue='Confirmed',  wih.createdDate, null)) as 'Last Confirmed',
    count(if(wih.Field='Status__c' and wih.NewValue='Confirmed',  wih.Id, null)) as 'Count Confirmed',
    ifnull(timestampdiff(day, 
		min(if(wih.Field='Status__c' and wih.NewValue='Scheduled',  wih.createdDate, null)) ,
        max(if(wih.Field='Status__c' and wih.NewValue='Confirmed',  wih.createdDate, null))), -99999) as 'First Scheduled to Confirmed',
	ifnull(timestampdiff(day, 
		min(if(wih.Field='Status__c' and wih.NewValue='Scheduled',  wih.createdDate, null)),
        wi.Service_target_date__c ), -99999) as 'First Scheduled to Target',
	ifnull(timestampdiff(day, 
        max(if(wih.Field='Status__c' and wih.NewValue='Confirmed',  wih.createdDate, null)),
        wi.Service_target_date__c), -99999) as 'Confirmed to Target',
	ifnull(timestampdiff(day, 
        max(if(wih.Field='Status__c' and wih.NewValue='Confirmed',  wih.createdDate, null)),
        wi.Work_Item_Date__c), -99999) as 'Confirmed to Audit',
	max(if(wih.Field='Status__c' and wih.NewValue='Confirmed',  wih.createdDate, null))>wi.Work_Item_Date__c as 'Backward Scheduled'
    
from salesforce.work_item__c wi
inner join salesforce.work_item__history wih on wih.ParentId = wi.Id
inner join salesforce.user s on wih.CreatedById = s.Id
inner join salesforce.work_package__c wp on wi.Work_Package__c = wp.Id
inner join salesforce.certification__c sc on wp.Site_Certification__c = sc.Id
left join salesforce.user scheduler on sc.Scheduler__c = scheduler.Id
inner join salesforce.resource__c a on wi.RAudit_Report_Author__c = a.Id
where 
wi.IsDeleted = 0
and wih.Field = 'Status__c'
and wi.Work_Item_Date__c>='2015-01-01'
and (wi.Revenue_Ownership__c like 'AUS%' or wi.Revenue_Ownership__c like 'Asia%')
group by wi.Id);

#explain
(select 
	wi.Id, wi.Name as 'Work Item', 
    wi.Revenue_Ownership__c as 'Revenue Ownership',
    if(wi.Revenue_Ownership__c like 'AUS%', 'Australia', substring_index(wi.Revenue_Ownership__c, '-', 2)) as 'Region (from Rev. Own.)',
    if(wi.Revenue_Ownership__c like '%Food%', 'Food', if(wi.Revenue_Ownership__c like '%Product%', 'PS', 'MS')) as 'Stream',
    wi.Status__c as 'WI Status',
    wi.Service_Delivery_Type__c as 'Service Delivery Type',
    wi.Work_Item_Stage__c as 'WI Type',
    wi.Work_Item_Date__c as 'WI Start Date', 
    wi.Service_target_date__c as 'WI Target Date',
    wi.Primary_Standard__c as 'Primary Standard',
    wih.*
from salesforce.work_item__c wi
inner join salesforce.work_item__history wih on wih.ParentId = wi.Id

where 
wi.IsDeleted = 0
and wih.Field = 'Open_Sub_Status__c'
and wi.Work_Item_Date__c>='2014-01-01'
and (wi.Revenue_Ownership__c like '%AUS%'));

(select
	wi.Id as 'WI Id',
    arg.Id as 'ARG Id',
    if (wi.Revenue_Ownership__c like 'AUS%', 'Australia', substring_index(wi.Revenue_Ownership__c, '-', 2)) as 'Region',
    if (wi.Revenue_Ownership__c like '%Food%', 'Food', if(wi.Revenue_Ownership__c like '%Product%', 'PS', 'MS')) as 'Stream',
    wi.Primary_Standard__c as 'Primary Standard',
	date_format(wi.Work_Item_Date__c, '%Y-%m') as 'Period',
    count(distinct wi.Id) as '# WI', 
    count(distinct arg.Id) as '# ARG'
from salesforce.work_item__c wi
inner join salesforce.arg_work_item__c argwi on argwi.RWork_Item__c = wi.Id
inner join salesforce.audit_report_group__c arg on argwi.RAudit_Report_Group__c = arg.Id
where wi.IsDeleted = 0
and argwi.IsDeleted = 0
and arg.IsDeleted = 0
#and wi.Revenue_Ownership__c like 'AUS%'
and wi.Status__c in ('Submitted','Under Review','Support', 'Completed', 'Under Review - Rejected', 'Complete')
and wi.Work_Item_Stage__c not in ('Follow Up')
and wi.Work_Item_Date__c between '2014-08-01' and '2015-08-31'
group by `Region`, `Stream`, wi.Primary_Standard__c, `Period`);

select wi.Status__c, date_format(wi.Work_Item_Date__c, '%Y-%m') as 'Period', count(wi.Id) as '# WI', sum(wi.Required_Duration__c/8) as 'Days'
from salesforce.work_item__c wi
where wi.Revenue_Ownership__c like '%China%'
and wi.Status__c not in ('Budget', 'Draft', 'Inititate Service')
and wi.IsDeleted = 0
and wi.Work_Item_Date__c is not null
group by wi.Status__c, `Period`