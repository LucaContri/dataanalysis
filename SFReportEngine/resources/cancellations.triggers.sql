use salesforce;
#select t.* from (
#explain
select 
scsp.Id as 'scsp.Id',
wp.Id as 'wp.Id',
wi.Id as 'wi.id',
wi.status__c,
wi.Open_Sub_Status__c,
scsp.De_registered_Type__c,
scsp.Site_Certification_Status_Reason__c,
if (scsp.Site_Certification_Status_Reason__c like 'Change to other%', 'Change To Other CB', scsp.Site_Certification_Status_Reason__c) as 'scsp.Site_Certification_Status_Reason__c2',
scsp.Withdrawn_Date__c,
wi.Cancellation_Reason__c,
wi.Sample_Site__c,
wi.Service_Change_Reason__c,
wi.Work_Item_Stage__c,
wi.Work_Item_Date__c,
wi.Primary_Standard__c,
wi.Required_Duration__c,
wi.Required_Duration__c/8 as 'Days',
wp.Type__c,
siteCert.Revenue_Ownership__c,
csp.Expires__c,
siteCert.Sample_Service__c,
min(if(wih.NewValue = 'Cancelled' or wih.NewValue like 'Pending%', wih.CreatedDate,null)) as 'Cancellation Date',
wi.CreatedDate as 'Create Date',
ig.Invoice_as_Lump_Sum__c,
ig.Last_Invoice_Date__c,
ig.Next_Invoice_Date__c,
ig.Recurring_Fee_Frequency__c
from work_item__c wi 
inner join work_item__history wih on wih.ParentId = wi.Id
inner join site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
left join certification__c siteCert on scsp.Site_Certification__c = siteCert.Id
left join Invoice_Group__c ig on siteCert.Invoice_Group_Registration__c = ig.Id
left join Certification_Standard_Program__c csp on scsp.Certification_Standard__c = csp.Id
left join work_package__c wp on wi.Work_Package__c = wp.Id
left join account site on site.Id = siteCert.Primary_client__c
left join account client on site.ParentId = client.Id
where wi.IsDeleted=0
and (wi.Status__c='Cancelled' or (wi.Status__c = 'Open' and wi.Open_Sub_Status__c like 'Pending%'))
and ((wih.Field = 'Status__c' and wih.NewValue = 'Cancelled') or (wih.Field = 'Open_Sub_Status__c' and wih.NewValue like 'Pending%'))
and (wi.Revenue_Ownership__c LIKE 'AUS-Food%' OR wi.Revenue_Ownership__c LIKE 'AUS-Global%' OR wi.Revenue_Ownership__c LIKE 'AUS-Managed%' OR wi.Revenue_Ownership__c LIKE 'AUS-Direct%')
group by wi.Id 
order by wp.Id, wi.Work_Item_Date__c limit 10000000;
# ) t
#group by t.`wp.Id` limit 100000;

#Registration fees


#explain
select t.Comments__c from (
select 
scsp.De_registered_Type__c,
scsp.Site_Certification_Status_Reason__c,
wi.Cancellation_Reason__c,
wi.Service_Change_Reason__c,
wi.Sample_Site__c,
wi.Id,
wi.Comments__c,
min(if(wih.NewValue = 'Cancelled', wih.CreatedDate,null)) as 'Cancellation Date',
min(if(wih.Field = 'created', wih.CreatedDate,null)) as 'Create Date',
abs(datediff(min(if(wih.NewValue = 'Cancelled', wih.CreatedDate,null)),min(if(wih.Field = 'created', wih.CreatedDate,null)))) as 'Create to Cancel Days',
if ((wi.Comments__c like '%wrong%' or wi.Comments__c like '%error%' or wi.Comments__c like '%incorrect%' or wi.Comments__c like '%duplicate%'), 1, 0) as 'IsError',
scsp.Withdrawn_Date__c as 'De-Registration Date'
from work_item__c wi 
inner join work_item__history wih on wih.ParentId = wi.Id
inner join site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
where wi.IsDeleted=0
and wi.Status__c='Cancelled'
and ((wih.Field = 'Status__c' and wih.NewValue = 'Cancelled') or (wih.Field = 'created'))
and (wi.Revenue_Ownership__c LIKE 'AUS-Food%' OR wi.Revenue_Ownership__c LIKE 'AUS-Global%' OR wi.Revenue_Ownership__c LIKE 'AUS-Managed%' OR wi.Revenue_Ownership__c LIKE 'AUS-Direct%')
group by wi.Id ) t
where 
#abs(datediff(t.`Create Date`, t.`Cancellation Date`))<3
#and t.De_registered_Type__c is null
#and t.Site_Certification_Status_Reason__c is null
#and t.Cancellation_Reason__c in ('Other')
#and t.Sample_Site__c in ('No')
t.`Create to Cancel Days` = 0;
#group by t.`IsError`;

select if(t.Comments__c is null, '', t.Comments__c)  as 'Comments__c' from (select scsp.De_registered_Type__c,scsp.Site_Certification_Status_Reason__c,wi.Cancellation_Reason__c,wi.Service_Change_Reason__c,wi.Sample_Site__c,wi.Id,wi.Comments__c,min(if(wih.NewValue = 'Cancelled', wih.CreatedDate,null)) as 'Cancellation Date',min(if(wih.Field = 'created', wih.CreatedDate,null)) as 'Create Date',abs(datediff(min(if(wih.NewValue = 'Cancelled', wih.CreatedDate,null)),min(if(wih.Field = 'created', wih.CreatedDate,null)))) as 'Create to Cancel Days', if ((wi.Comments__c like '%wrong%' or wi.Comments__c like '%error%' or wi.Comments__c like '%incorrect%' or wi.Comments__c like '%duplicate%'), 1, 0) as 'IsError',scsp.Withdrawn_Date__c as 'De-Registration Date' from work_item__c wi  inner join work_item__history wih on wih.ParentId = wi.Id inner join site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id where wi.IsDeleted=0 and wi.Status__c='Cancelled' and ((wih.Field = 'Status__c' and wih.NewValue = 'Cancelled') or (wih.Field = 'created')) and (wi.Revenue_Ownership__c LIKE 'AUS-Food%' OR wi.Revenue_Ownership__c LIKE 'AUS-Global%' OR wi.Revenue_Ownership__c LIKE 'AUS-Managed%' OR wi.Revenue_Ownership__c LIKE 'AUS-Direct%') group by wi.Id ) t where t.`Create to Cancel Days` = 0 	 	 	