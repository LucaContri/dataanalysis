#Profiling De-Registrations

create or replace view deregistered_clients_sub as 
select 
client.Name as 'Client',
client.Id as 'ClientId',
site.Name as 'Site',
site.Id as 'SiteId',
client.Client_Segmentation__c as 'Client Segmentation',
sc.Revenue_Ownership__c as 'Revenue Ownership',
scsp.Id as 'SiteCertStandardId',
scsp.Name as 'SiteCertStandardName',
scsp.De_registered_Type__c as 'De-Registered Type',
scsp.Site_Certification_Status_Reason__c as 'De-Registered Reason', 
scsp.Withdrawn_Date__c as 'De-Registered Date',
date_format(scsp.Withdrawn_Date__c,'%Y %m')  as 'De-Registered Period',
scsp.Status_Hidden__c as 'Site Cert Standard Status',
s.Name as 'Standard',
p.Name as 'Program',
wi.Work_Item_Date__c as 'First Cancelled Work Item Date',
wi.Work_Item_Stage__c as 'First Cancelled Work Item Stage'
from site_certification_standard_program__c scsp
inner join work_item__c wi on wi.Site_Certification_Standard__c = scsp.Id
inner join certification__c sc on scsp.Site_Certification__c = sc.Id
inner join account site on sc.Primary_client__c = site.Id
inner join account client on site.ParentId = client.Id
inner join standard_program__c sp on scsp.Standard_Program__c = sp.Id
inner join standard__c s on sp.Standard__c = s.Id
inner join program__c p on sp.Program__c = p.Id
where 
scsp.De_registered_Type__c in ('Client Initiated')
and wi.Status__c = 'Cancelled'
group by scsp.Id, wi.Id
order by client.Id, site.Id, scsp.Id, wi.Work_Item_Date__c;

create or replace view deregistered_clients as
select * from deregistered_clients_sub t
group by t.SiteCertStandardId;

select dc.*, max(if (wi.Work_Item_Stage__c='Re-Certification' ,wi.Work_Item_Date__c,null)) as 'Last Re-Certification'
from deregistered_clients dc
left join work_item__c wi on wi.Site_Certification_Standard__c = dc.SiteCertStandardId
group by dc.SiteCertStandardId limit 100000;