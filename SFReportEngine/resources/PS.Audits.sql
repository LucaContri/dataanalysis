(select 
client.Id as 'Client Id',
client.Name as 'Client Name',
client.Client_Ownership__c as 'Client Ownership', 
#client.Business__c as 'Client Business',
site.Id as 'Site Id',
site.Name as 'Site Name',
site.Business__c as 'Site Business',
site.Business_City__c as 'Site City',
scs.Name as 'Site State',
ccs.Name as 'Site Country',
site.Business_Zip_Postal_Code__c as 'Site PostCode',
sc.Name as 'Site Cert.',
#sc.Operational_Ownership__c as 'Site Cert Operational Ownership', 
#sc.Revenue_Ownership__c as 'Site Cert Revenue Ownership', 
wp.Name as 'Work Package',
wp.Type__c as 'Work Package Type',
wi.Id as 'Work Item Id',
wi.Name as 'Work Item',
date_format(wi.work_item_date__c, '%Y %m') as 'Work Item Scheduled Period',
wi.Status__c as 'Work Item Status',
wi.Work_Item_Stage__c as 'Work Item Type',
wi.Revenue_Ownership__c as 'WI Revenue Ownership',
wi.Primary_Standard__c as 'Primary Standard',
sum(wird.Scheduled_Duration__c / 8) as 'Work Item Days',
group_concat(distinct r.Name) as 'Resources'
from work_item__c wi
inner join work_package__c wp on wi.Work_Package__c = wp.Id
inner join certification__c sc on wp.Site_Certification__c = sc.Id
inner join account site on sc.Primary_client__c = site.Id
inner join account client on site.ParentId = client.Id
inner join country_code_setup__c ccs on ccs.id = site.Business_Country2__c
inner join state_code_setup__c scs on scs.Id = site.Business_State__c
left join work_item_resource__c wir on wir.Work_Item__c = wi.id
left join resource__c r on wir.Resource__c = r.Id
LEFT JOIN work_item_resource_day__c wird ON wird.Work_Item_Resource__c = wir.Id 
LEFT JOIN recordtype rt ON wi.RecordTypeId = rt.Id 
WHERE 
rt.Name = 'Audit' 
and wi.Revenue_Ownership__c like '%Product%'
#sc.Operational_Ownership__c like '%Product%'
#client.Client_Ownership__c='Product Services'
and wi.IsDeleted = 0
and wi.Status__c not in ('Cancelled', 'Budget', 'Open', 'Service Change')
and wp.IsDeleted = 0
and wir.IsDeleted = 0
and sc.IsDeleted = 0
and sc.Status__c = 'Active'
and site.IsDeleted = 0
and client.IsDeleted = 0
AND wird.IsDeleted = 0 
AND wir.Work_Item_Type__c IN ('Audit' , 'Audit Planning', 'Client Management') 
AND wir.Role__c NOT IN ('Observer' , 'Verifying Auditor', 'Verifier') 
group by wi.Id
limit 1000000) 
UNION 
(select 
client.Id as 'Client Id',
client.Name as 'Client Name',
client.Client_Ownership__c as 'Client Ownership', 
#client.Business__c as 'Client Business',
site.Id as 'Site Id',
site.Name as 'Site Name',
site.Business__c as 'Site Business',
site.Business_City__c as 'Site City',
scs.Name as 'Site State',
ccs.Name as 'Site Country',
site.Business_Zip_Postal_Code__c as 'Site PostCode',
sc.Name as 'Site Cert.',
#sc.Operational_Ownership__c as 'Site Cert Operational Ownership', 
#sc.Revenue_Ownership__c as 'Site Cert Revenue Ownership', 
wp.Name as 'Work Package',
wp.Type__c as 'Work Package Type',
wi.Id as 'Work Item Id',
wi.Name as 'Work Item',
date_format(wi.work_item_date__c, '%Y %m') as 'Work Item Scheduled Period',
wi.Status__c as 'Work Item Status',
wi.Work_Item_Stage__c as 'Work Item Type',
wi.Revenue_Ownership__c as 'WI Revenue Ownership',
wi.Primary_Standard__c as 'Primary Standard',
wi.Required_Duration__c/8 as 'Work Item Days',
null as 'Resources'
from work_item__c wi
inner join work_package__c wp on wi.Work_Package__c = wp.Id
inner join certification__c sc on wp.Site_Certification__c = sc.Id
inner join account site on sc.Primary_client__c = site.Id
inner join account client on site.ParentId = client.Id
inner join country_code_setup__c ccs on ccs.id = site.Business_Country2__c
inner join state_code_setup__c scs on scs.Id = site.Business_State__c
where 
wi.Revenue_Ownership__c like '%Product%'
#sc.Operational_Ownership__c like '%Product%'
#client.Client_Ownership__c='Product Services'
and wi.IsDeleted = 0
and wi.Status__c in ('Open', 'Service Change')
and wp.IsDeleted = 0
and sc.IsDeleted = 0
and sc.Status__c = 'Active'
and site.IsDeleted = 0
and client.IsDeleted = 0
group by wi.Id
limit 1000000
) limit 1000000