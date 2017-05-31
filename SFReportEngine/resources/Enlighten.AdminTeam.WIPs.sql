# Enlighten Admin Team WIPs
use salesforce;
select 
t.Id as 'ARG_Id',
t.Name as 'ARG_Name',
t.Work_Item_Stages__c as 'WorkItem_Stages',
t.Audit_Report_Standards__c as 'Standards',
t.Family_Standards as 'Family_Standards',
t.Client_Segmentation__c as 'Client_Segmentation',
if(t.Client_Segmentation__c = 'Managed Plus', 'High Complexity', 'High Transactional') as 'Client_Segmentation_2',
t.Change_Requests_no as 'Change_Requests_no',
if (t.`Family_Standards` like '%Woolworths%' or t.Audit_Report_Standards__c like '%Woolworths%', if(t.Work_Item_Stages__c='Follow Up', 'Woolworths Audit (subsequent)', 'Woolworths Audit (initial)'),
if (t.Change_Requests_no>0 or t.Work_Item_Stages__c in ('Certification', 'Re-Certification'),if(t.Client_Segmentation__c = 'Managed Plus','ARG High Complexity','ARG High Transactional'),'ARG - No Action Required')) as 'Enlighten_WIP_1',
if (t.Change_Requests_no>0 or t.Work_Item_Stages__c in ('Certification', 'Re-Certification'),'Upload Documents to GBP',null) as 'Enlighten_WIP_2',
if (t.`Family_Standards` like '%SQF%' or t.`Family_Standards` like '%BRC%' or t.Audit_Report_Standards__c like '%BRC%' or t.Audit_Report_Standards__c like '%SQF%','External Database Update',null) as 'Enlighten_WIP_3'

 from (
select arg.*, 
group_concat(distinct s.Name) as 'Family_Standards',
count(distinct cr.Id) as 'Change_Requests_no'
from audit_report_group__c arg 
inner join arg_work_item__c argwi on argwi.RAudit_Report_Group__c = arg.id
inner join work_item__c wi on argwi.RWork_Item__c = wi.Id
inner join site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.id
left join change_request2__c cr on cr.Work_Item__c = wi.Id
left join site_certification_standard_family__c scsf on scsf.Site_Certification_Standard__c = scsp.Id
left join standard_program__c sp on sp.Id = scsf.Standard_Program__c
left join standard__c s on sp.Standard__c = s.Id
where arg.Audit_Report_Status__c='Support'
and arg.Client_Ownership__c in ('Australia', 'Product Services')
group by arg.Id ) t;
#where t.`Family_Standards` like '%Wool%' or t.Audit_Report_Standards__c like '%Wool%'
#and arg.Audit_Report_Standards__c like '%WQA%'

select * from change_request2__c limit 1000;

update sf_tables set MinSecondsBetweenSyncs=3600 where Id IN (17,51,106)
