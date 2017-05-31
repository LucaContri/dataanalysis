select
	wi.Id as 'WorkItemId', 
	wi.Name as 'WorkItem',
	wi.work_package__c,
	wi.Work_Package_Type__c, 
	wi.Work_Item_Stage__c, 
    wi.Client_Name_No_Hyperlink__c,
	if (wi.Revenue_Ownership__c like '%Food%', 'Food',if(wi.Revenue_Ownership__c like '%Product%','PS','MS')) as 'Stream',
	wi.Revenue_Ownership__c,
    scsp.De_registered_Type__c, 
	scsp.Site_Certification_Status_Reason__c, 
	wi.Cancellation_Reason__c, 
	wi.Service_Change_Reason__c,
	wi.Work_Item_Date__c,
	wi.Required_Duration__c as 'RequiredDuration',
    wih.OldValue,
    wih.NewValue,
	max(wih.CreatedDate) as 'Change Date',
    date_format(max(wih.CreatedDate),'%Y-%m') as 'Change Period',
	wi.Sample_Site__c
from work_item__c wi
inner join work_item__history wih on wih.ParentId = wi.Id
inner join site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join certification__c sc on scsp.Site_Certification__c = sc.Id
where 
wih.Field='Open_Sub_Status__c'
#and date_format(wih.CreatedDate, '%Y-%m') in ('2014-12')
and wi.Revenue_Ownership__c like 'AUS%'
#and wi.Status__c = 'Open'
group by wi.Id limit 10000000;


select
	wi.Id as 'WorkItemId', 
	wi.Name as 'WorkItem',
	wi.work_package__c,
	wi.Work_Package_Type__c, 
	wi.Work_Item_Stage__c, 
    wi.Client_Name_No_Hyperlink__c,
	if (wi.Revenue_Ownership__c like '%Food%', 'Food',if(wi.Revenue_Ownership__c like '%Product%','PS','MS')) as 'Stream',
	wi.Revenue_Ownership__c,
    scsp.De_registered_Type__c, 
	scsp.Site_Certification_Status_Reason__c, 
	wi.Cancellation_Reason__c, 
	wi.Service_Change_Reason__c,
	wi.Work_Item_Date__c,
    date_format(wi.Work_Item_Date__c, '%Y-%m') as 'Scheduled Period',
	wi.Required_Duration__c as 'RequiredDuration',
    wi.Sample_Site__c
from work_item__c wi
inner join site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join certification__c sc on scsp.Site_Certification__c = sc.Id
where 
wi.Revenue_Ownership__c like 'AUS%'
group by wi.Id limit 10000000