set @batchId='Australia Food Capcity Planning - 6 months';
set @subBatchId = (select max(SubBatchId) from salesforce.allocator_schedule_batch where BatchId=@batchId);
set @startDate = (select startDate from salesforce.allocator_schedule_batch where BatchId=@batchId and SubBatchId=@subBatchId);
set @endDate = (select endDate from salesforce.allocator_schedule_batch where BatchId=@batchId and SubBatchId=@subBatchId);

select @batchId, @subBatchId;
select t.Id,t.Name,t.Work_Item_Date__c, t.`Status__c` as 'Work Item Status', t.Scheduling_Ownership__c, t.Source, t.`Scheduling Type`, t.Status, t.`Duration Audit (Hrs)`, t.`Duration Travel (Hrs)`, t.`Auditor Reporting Business Unit`, t.`Resource_Type__c` as 'Reource Type', t.`Auditor Name`, t.`Auditor Id`, t.Role__c, t.Comments__c, sp.Standard_Service_Type_Name__c as 'Primary Standard', group_concat(distinct spf.Standard_Service_Type_Name__c) as 'FoS', group_concat(distinct code.Name) as 'Codes' from
(select wi.Site_Certification_Standard__c, wi.Id, wi.Name, wi.Work_Item_Date__c, wi.Status__c, wi.Scheduling_Ownership__c, 'COMPASS_WORK_ITEM' as 'Source', 'ACTUAL' as 'Scheduling Type', 'ALLOCATED' as 'Status', 
sum(wir.Total_Duration__c) as 'Duration Audit (Hrs)', 0 as 'Duration Travel (Hrs)', r.Name as 'Auditor Name', r.Id as 'Auditor Id', wir.Role__c, wi.Comments__c, r.Reporting_Business_Units__c as 'Auditor Reporting Business Unit', r.Resource_Type__c
from salesforce.work_item__c wi 
inner join salesforce.work_item_resource__c wir on wir.Work_Item__c = wi.Id and wir.IsDeleted = 0
inner join salesforce.resource__c r on wir.Resource__c = r.Id
where wi.Work_Item_Date__c between @startDate and @endDate
and wi.Status__c not in ('Cancelled', 'Open', 'Service Change', 'Initiate Service', 'Draft')
and wi.Revenue_Ownership__c like 'AUS-Food%'
group by wi.Id, r.Id) t
inner join salesforce.site_certification_standard_program__c scsp on t.Site_Certification_Standard__c = scsp.Id
inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
left join salesforce.site_certification_standard_family__c scspf on scspf.Site_Certification_Standard__c = scsp.Id and scspf.IsDeleted = 0
left join salesforce.standard_program__c spf on scspf.Standard_Program__c = spf.Id
left join salesforce.site_cert_standard_program_code__c scspc on scspc.Site_Certification_Standard_Program__c = scsp.Id and scspc.IsDeleted = 0
left join salesforce.code__c code on scspc.Code__c = code.Id
group by t.`Id`, t.`Auditor Id`
union all
select t.Id,t.Name,t.Work_Item_Date__c, t.`Status__c` as 'Work Item Status', t.Scheduling_Ownership__c, t.Source, t.`Scheduling Type`, t.Status, t.`Duration Audit (Hrs)`, t.`Duration Travel (Hrs)`, t.`Auditor Reporting Business Unit`, t.`Resource_Type__c` as 'Reource Type', t.`Auditor Name`, t.`Auditor Id`, '', t.Notes, sp.Standard_Service_Type_Name__c as 'Primary Standard', group_concat(distinct spf.Standard_Service_Type_Name__c) as 'FoS', group_concat(distinct code.Name) as 'Codes' from
(select wi.Site_Certification_Standard__c, wi.Id, wi.Name, wi.Work_Item_Date__c, wi.Status__c, wi.Scheduling_Ownership__c, 'COMPASS_WORK_ITEM' as 'Source', 'ALLOCATOR' as 'Scheduling Type', s.`Status`, sum(if(s.`Type`='AUDIT', s.`Duration`,0)) as 'Duration Audit (Hrs)', sum(if(s.`Type`='TRAVEL', s.`Duration`,0)) as 'Duration Travel (Hrs)', s.`ResourceName` as 'Auditor Name', s.`ResourceId` as 'Auditor Id', '', s.`Notes`, r.Reporting_Business_Units__c as 'Auditor Reporting Business Unit', r.Resource_Type__c
from salesforce.work_item__c wi 
left join salesforce.allocator_schedule s on wi.Id = s.`WorkItemId` and s.BatchId=@batchId and s.SubBatchId=@subBatchId
left join salesforce.resource__c r on s.`ResourceId` = r.Id
where wi.Work_Item_Date__c between @startDate and @endDate
and wi.Status__c in ('Open', 'Service Change', 'Initiate Service', 'Draft')
and wi.Revenue_Ownership__c like 'AUS-Food%'
and wi.Work_Item_Stage__c not in ('Follow Up')
group by wi.Id) t
inner join salesforce.site_certification_standard_program__c scsp on t.Site_Certification_Standard__c = scsp.Id
inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
left join salesforce.site_certification_standard_family__c scspf on scspf.Site_Certification_Standard__c = scsp.Id and scspf.IsDeleted = 0
left join salesforce.standard_program__c spf on scspf.Standard_Program__c = spf.Id
left join salesforce.site_cert_standard_program_code__c scspc on scspc.Site_Certification_Standard_Program__c = scsp.Id and scspc.IsDeleted = 0
left join salesforce.code__c code on scspc.Code__c = code.Id
group by t.`Id`, t.`Auditor Id`
union all
select s.WorkItemId, s.WorkItemName, s.`StartDate`, 'Pipeline' as 'Status', 'n/a' as 'Scheduling Ownership', 'COMPASS_PIPELINE' as 'Source', 'ALLOCATOR' as 'Scheduling Type', s.`Status`, sum(if(s.`Type`='AUDIT', s.`Duration`,0)) as 'Duration Audit (Hrs)', sum(if(s.`Type`='TRAVEL', s.`Duration`,0)) as 'Duration Travel (Hrs)', r.Reporting_Business_Units__c, r.Resource_Type__c, s.`ResourceName` as 'Auditor Name', s.`ResourceId` as 'Auditor Id', '', s.`Notes`, s.`PrimaryStandard`, null as 'FoS', s.`Competencies` as 'Codes'
from salesforce.allocator_schedule s 
left join salesforce.resource__c r on s.`ResourceId` = r.Id
where 
s.BatchId=@batchId
and s.SubBatchId=@subBatchId
and s.`WorkItemSource` = 'COMPASS_PIPELINE'
group by s.WorkItemId;

select Id, Name from salesforce.resource__c where Name like '%kanan%'