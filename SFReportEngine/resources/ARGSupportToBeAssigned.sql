use Salesforce;
create or replace view ARG_Support_To_Be_Assigned as
select 
arg.Id as 'ARG Id', 
arg.Name as 'ARG', 
arg.Audit_Report_Status__c as 'Status',  
if (parent.Name is null, '', parent.Name) as 'Coorporate',
client.Name as 'Client', 
group_concat(distinct s.Name order by s.Name) as 'Primary Standards', 
group_concat(distinct if(scsf.IsDeleted or fsp.isDeleted or fs.IsDeleted, null,fs.Name) order by fs.Name) as 'Family Standards',
group_concat(distinct wi.Work_item_stage__c order by wi.Work_item_stage__c) as 'ARG WI Types',
group_concat(distinct p.Business_Line__c) as 'Business Lines',
author.name as 'ARG Author',
arg.Authors_Reporting_Business_Unit__c as 'Authors Reporting Business Units',
arg.Client_Segmentation__c as 'Client Segmentation',
client.Client_Ownership__c as 'Client Ownership',
lm.Name as 'Last Modified By',
date_format(arg.LastModifiedDate, '%d/%m/%Y') as 'Last Modified Date',
arg.Assigned_Admin__c as 'Assigned Admin'
from Audit_Report_Group__c arg
inner join account client on arg.Client__c = client.Id
left join account parent on client.ParentId = parent.Id
inner join ARG_Work_Item__c argwi on argwi.RAudit_Report_Group__c = arg.id
inner join work_item__c wi on wi.id = argwi.RWork_Item__c
inner join site_certification_standard_program__c scsp on scsp.Id = wi.Site_Certification_Standard__c
inner join resource__c author on arg.RAudit_Report_Author__c = author.id
inner join user lm on arg.LastModifiedById = lm.Id
left join standard_program__c sp on sp.Id = scsp.Standard_Program__c
left join standard__c s on sp.Standard__c = s.Id
left join program__c p on s.Program__c = p.Id
left join site_certification_standard_family__c scsf on scsf.Site_Certification_Standard__c = scsp.Id
left join standard_program__c fsp on scsf.Standard_Program__c = fsp.Id
left join standard__c fs on fsp.Standard__c = fs.Id
where 
client.Client_Ownership__c in ('Australia', 'Product Services')
and arg.Assigned_Admin__c is null
and arg.Audit_Report_Status__c = 'Support'
group by arg.Id;

select * from ARG_Support_To_Be_Assigned;