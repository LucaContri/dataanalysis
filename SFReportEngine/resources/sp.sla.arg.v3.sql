(select t.RAudit_Report_Group__c, count(t.RAudit_Report_Group__c) from (
select ah.RAudit_Report_Group__c, ah.Status__c, ah.Assigned_To__c
from salesforce.approval_history__c ah 
where ah.Status__c = 'Requested Technical Review'
or ah.Assigned_To__c = 'Technical Review') t
group by t.RAudit_Report_Group__c);

select * from analytics.sla_arg_v2 where Id='a1Wd0000000ORYnEAO';

select ah.Id, ah.RAudit_Report_Group__c 
from salesforce.approval_history__c ah
inner join salesforce.audit_report_group__c arg on ah.RAudit_Report_Group__c = arg.Id
where ah.Status__c='Rejected' and arg.Assigned_TR__c is not null;

select ah.* from salesforce.approval_history__c ah where ah.Id in ('a1ld0000000N4efAAC', 'a1ld00000008oQVAAY');

# ARG CA
(select 
'ARG - CA' as 'Metric',
null as 'SLA Target (Business Days)',
'ARG' as 'Type',
t2.RAudit_Report_Group__c as 'Id',
t2.Name as 'Name',
t2.Revenue_Ownership__c as 'Region',
t2.Owner as 'Owner',
t2.Time_Zone__c as 'TimeZone',
if (ABS(TIME_TO_SEC(TIMEDIFF(t2.`Submission Date`,t2.First_Submitted__c)))<60 or t2.`Submission Date` is null, t2.First_Submitted__c, t2.`Submission Date`) as 'From',
t2.createdDate as 'To',
null as 'SLA Due',
t2.`Standards`,
t2.`Standard Families`,
t2.`Tags`
from (
select t.RAudit_Report_Group__c, t.First_Submitted__c, t.Name, t.`Owner`, t.Revenue_Ownership__c, t.createdDate,t.Assigned_To__c ,t.Status__c, t.Comments__C, t.Work_Item_Date__c, t.Time_Zone__c,
(select max(ah.CreatedDate) as 'Submission Date'
from salesforce.approval_history__c ah
where ah.RAudit_Report_Group__c = t.RAudit_Report_Group__c
and ((ah.Status__c = 'Submitted')
	or (ah.Status__c = 'Approved' and ah.Assigned_to__c = 'Certification Approver'))
and ah.CreatedDate < t.createdDate) as 'Submission Date',
group_concat(distinct t.`Standards` order by t.`Standards`) as 'Standards',
group_concat(distinct t.`Standard Families`) as 'Standard Families',
group_concat(distinct t.`Tags`) as 'Tags'
from (
select argwi.RAudit_Report_Group__c, arg.First_Submitted__c, arg.Name, ca.Name as 'Owner', sc.Revenue_Ownership__c, ah.createdDate,ah.Assigned_To__c ,ah.Status__c, ah.Comments__C, wi.Work_Item_Date__c, s.Time_Zone__c,
group_concat(distinct scsp.Standard_Service_Type_Name__c order by scsp.Standard_Service_Type_Name__c) as 'Standards',
group_concat(distinct if(scspf.IsDeleted or spf.isDeleted, null,spf.Standard_Service_Type_Name__c) separator ',') as 'Standard Families',
getARGProcessTags(
			group_concat(distinct wi.Client_Ownership__c),
            group_concat(distinct p.Business_Line__c),
            group_concat(distinct p.Name),
			group_concat(DISTINCT wi.Primary_Standard__c), 
            group_concat(distinct if(scspf.IsDeleted or spf.isDeleted, null,spf.Standard_Service_Type_Name__c) separator ','),
            ca.Reporting_Business_Units__c,
            group_concat(distinct wi.Work_Item_Stage__c)) as 'Tags'
from salesforce.approval_history__c ah 
inner join salesforce.audit_report_group__c arg on ah.RAudit_Report_Group__c = arg.Id
left join salesforce.resource__c ca on arg.Assigned_CA__c = ca.Id
inner join salesforce.arg_work_item__c argwi on argwi.RAudit_Report_Group__c = ah.RAudit_Report_Group__c
inner join salesforce.work_item__c wi on argwi.RWork_Item__c = wi.Id
inner join salesforce.work_package__c wp on wi.Work_Package__c = wp.Id
inner join salesforce.certification__c sc on wp.Site_Certification__c = sc.Id
inner join salesforce.account s on sc.Primary_client__c = s.Id
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
inner join salesforce.program__c p on sp.Program__c = p.Id
left join salesforce.site_certification_standard_family__c scspf on scspf.Site_Certification_Standard__c = scsp.Id
left join salesforce.standard_program__c spf on scspf.Standard_Program__c = spf.Id
where 
arg.Id='a1Wd0000000ORYnEAO'
and arg.IsDeleted = 0
and (ah.Status__c in ('Rejected') 
	or (ah.Status__c = 'Approved' and ah.Assigned_to__c = 'Client Administration')
    or (ah.Status__c = 'Requested Technical Review' and ah.Assigned_to__c = 'Technical Review'))
group by arg.Id, wi.Id, ah.Id
order by argwi.RAudit_Report_Group__c, wi.Work_Item_Date__c desc) t
group by t.RAudit_Report_Group__c, t.Status__c, t.createdDate) t2);

(select 
'Auditor Submission' as 'Metric',
analytics.getTarget('arg_submission_first',null,null) as 'SLA Target (Business Days)',
'ARG' as 'Type',
arg.Id as 'Id',
arg.Name as 'Name',
sc.Revenue_Ownership__c as 'Region',
author.name as 'Owner',
s.Time_Zone__c as 'TimeZone',
convert_tz(date_format(if(wi.Work_Item_Stage__c in ('Initial Project','Product Update', 'Standard Change'), max(wi.Project_Start_Date__c), max(wi.End_Service_Date__c)), '%Y-%m-%d 17:00:00'),s.Time_Zone__c, 'UTC') as 'From',
arg.First_Submitted__c as 'To',
analytics.getSLADueUTCTimestamp(convert_tz(date_format(if(wi.Work_Item_Stage__c in ('Initial Project','Product Update', 'Standard Change'), max(wi.Project_Start_Date__c), max(wi.End_Service_Date__c)), '%Y-%m-%d 17:00:00'),s.Time_Zone__c, 'UTC'), s.Time_Zone__c, analytics.getTarget('arg_submission_first',null,null))  as 'SLA Due',
group_concat(distinct scsp.Standard_Service_Type_Name__c order by scsp.Standard_Service_Type_Name__c) as 'Standards',
group_concat(distinct if(scspf.IsDeleted or spf.isDeleted, null,spf.Standard_Service_Type_Name__c) separator ',') as 'Standard Families',
getARGProcessTags(
			group_concat(distinct wi.Client_Ownership__c),
            group_concat(distinct p.Business_Line__c),
            group_concat(distinct p.Name),
			group_concat(DISTINCT wi.Primary_Standard__c), 
            group_concat(distinct if(scspf.IsDeleted or spf.isDeleted, null,spf.Standard_Service_Type_Name__c) separator ','),
            author.Reporting_Business_Units__c,
            group_concat(distinct wi.Work_Item_Stage__c)) as 'Tags'
from salesforce.audit_report_group__c arg 
left join salesforce.resource__c author on arg.RAudit_Report_Author__c = author.Id
inner join salesforce.arg_work_item__c argwi on argwi.RAudit_Report_Group__c = arg.Id
inner join salesforce.work_item__c wi on argwi.RWork_Item__c = wi.Id
inner join salesforce.work_package__c wp on wi.Work_Package__c = wp.Id
inner join salesforce.certification__c sc on wp.Site_Certification__c = sc.Id
inner join salesforce.account s on sc.Primary_client__c = s.Id
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
inner join salesforce.program__c p on sp.Program__c = p.Id
left join salesforce.site_certification_standard_family__c scspf on scspf.Site_Certification_Standard__c = scsp.Id
left join salesforce.standard_program__c spf on scspf.Standard_Program__c = spf.Id
where 
#arg.First_Submitted__c > lastUpdate_arg_submission
#arg.Id='a1Wd00000004OQ0EAM'
arg.Name='ARG-287433'
and arg.IsDeleted = 0
and (wi.Project_Start_Date__c is not null or wi.End_Service_Date__c is not null)
group by arg.Id
order by arg.Id);
#union

drop temporary table sla_arg_tmp;
create temporary table sla_arg_tmp (
  `Metric` varchar(64) DEFAULT NULL,
  `SLA Target (Business Days)` bigint(20) NULL DEFAULT '0',
  `Type` varchar(3) NOT NULL DEFAULT '',
  `Id` varchar(18) DEFAULT NULL,
  `Name` text NOT NULL,
  `Region` text,
  `Owner` text,
  `TimeZone` text,
  `From` text,
  `To` datetime DEFAULT NULL,
  `SLA Due` datetime DEFAULT NULL,
  `Standards` text,
  `Standard Families` text,
  `Tags` text,
  KEY `sla_arg_v2_index` (`Id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

(select 
if(ah.Assigned_To__c = 'Certification Approver', 'CA Revision',
if(ah.Assigned_To__c in ('Technical Review', 'Technical Reviewer'), 'TR Revision',null)) as 'Metric',
null as 'Target',
'ARG' as 'Type',
arg.Id as 'Id',
arg.Name as 'Name',
sc.Revenue_Ownership__c as 'Region',
if(ah.Assigned_To__c = 'Certification Approver', ca.Name,
if(ah.Assigned_To__c in ('Technical Review', 'Technical Reviewer'), tr.Name, null)) as 'Owner', 
s.Time_Zone__c as 'TimeZone',
ah.createdDate as 'From', 
(select min(ah2.CreatedDate) from salesforce.approval_history__c ah2 
	where ah2.RAudit_Report_Group__c = ah.RAudit_Report_Group__c 
	and (ah2.Assigned_To__c is null or ah2.Assigned_To__c not in (ah.Assigned_To__c) or ah2.Status__c='Hold')
	and ah2.CreatedDate > ah.createdDate) as 'To', 
null as 'SLA Due',
group_concat(distinct scsp.Standard_Service_Type_Name__c order by scsp.Standard_Service_Type_Name__c) as 'Standards',
group_concat(distinct if(scspf.IsDeleted or spf.isDeleted, null,spf.Standard_Service_Type_Name__c) separator ',') as 'Standard Families',
getARGProcessTags(
			group_concat(distinct wi.Client_Ownership__c),
            group_concat(distinct p.Business_Line__c),
            group_concat(distinct p.Name),
			group_concat(DISTINCT wi.Primary_Standard__c), 
            group_concat(distinct if(scspf.IsDeleted or spf.isDeleted, null,spf.Standard_Service_Type_Name__c) separator ','),
            ca.Reporting_Business_Units__c,
            group_concat(distinct wi.Work_Item_Stage__c)) as 'Tags'
from salesforce.approval_history__c ah 
inner join salesforce.audit_report_group__c arg on ah.RAudit_Report_Group__c = arg.Id
left join salesforce.resource__c ca on arg.Assigned_CA__c = ca.Id
left join salesforce.resource__c tr on arg.Assigned_TR__c = tr.Id
inner join salesforce.arg_work_item__c argwi on argwi.RAudit_Report_Group__c = ah.RAudit_Report_Group__c
inner join salesforce.work_item__c wi on argwi.RWork_Item__c = wi.Id
inner join salesforce.work_package__c wp on wi.Work_Package__c = wp.Id
inner join salesforce.certification__c sc on wp.Site_Certification__c = sc.Id
inner join salesforce.account s on sc.Primary_client__c = s.Id
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
inner join salesforce.program__c p on sp.Program__c = p.Id
left join salesforce.site_certification_standard_family__c scspf on scspf.Site_Certification_Standard__c = scsp.Id
left join salesforce.standard_program__c spf on scspf.Standard_Program__c = spf.Id
where 
arg.IsDeleted = 0
and ah.Assigned_To__c in ('Technical Review', 'Technical Reviewer', 'Certification Approver')
and ah.Status__c not in ('Taken', 'Assigned', 'Returned', 'Completed') # These are operations to/from public queues.  We are not interested from metrics perspective yet.
group by ah.Id
order by argwi.RAudit_Report_Group__c, ah.CreatedDate);

(select 
	arg.Id,
	if(arg.`Metric` in ('ARG Submission - First','ARG Submission - Resubmission'), 'Delivery (Days)', 
		if(arg.`Metric` in ('CA Revision'),'Technical CA (Days)',
			if(arg.`Metric` in ('TR Revision'),'Technical TR (Days)',
				if(arg.`Metric` in ('ARG Completion/Hold'), 'Admin (Days)', 'Hold (Days)')))) as '_Metric', 
arg_orig.Client_Ownership__c as 'Country',
date_format((select max(`To`) from analytics.sla_arg_v2 where Id=arg_orig.Id), '%Y %m')  as 'Period',
if((select count(`Id`) from analytics.sla_arg_v2 where Id=arg_orig.Id)=2,TRUE,FALSE)  as 'Auto-Approved',
if((select count(t3.`Id`) from analytics.sla_arg_v2 t3 where t3.Id=arg_orig.Id and t3.`Metric`='ARG Hold')=1,TRUE,FALSE)  as 'With Hold',
count(distinct arg.Id) as 'Volume',
sum(timestampdiff(second, arg.`From`, arg.`To`)/3600/24) as 'Sum Value',
group_concat(distinct arg_orig.Name) as 'Items'
from salesforce.audit_report_group__c arg_orig 
inner join analytics.sla_arg_v2 arg on arg_orig.Id = arg.Id
where
arg_orig.Audit_Report_Status__c = 'Completed'
and arg_orig.Work_Item_Stages__c not like ('%Product Update%')
and arg_orig.Work_Item_Stages__c not like ('%Initial Project%')
and arg.`Metric` in ('ARG Submission - First','ARG Submission - Resubmission','ARG Completion/Hold', 'ARG Hold')
group by arg_orig.Id, `_Metric`)
union
(select 
	arg.Id,
	if(arg.`Metric` in ('ARG Submission - First','ARG Submission - Resubmission'), 'Delivery (Days)', 
		if(arg.`Metric` in ('CA Revision'),'Technical CA (Days)',
			if(arg.`Metric` in ('TR Revision'),'Technical TR (Days)',
				if(arg.`Metric` in ('ARG Completion/Hold'), 'Admin (Days)', 'Hold (Days)')))) as '_Metric', 
arg_orig.Client_Ownership__c as 'Country',
date_format((select max(`To`) from analytics.sla_arg_v2 where Id=arg_orig.Id), '%Y %m')  as 'Period',
if((select count(`Id`) from analytics.sla_arg_v2 where Id=arg_orig.Id)=2,TRUE,FALSE)  as 'Auto-Approved',
if((select count(t3.`Id`) from analytics.sla_arg_v2 t3 where t3.Id=arg_orig.Id and t3.`Metric`='ARG Hold')=1,TRUE,FALSE)  as 'With Hold',
count(distinct arg.Id) as 'Volume',
sum(timestampdiff(second, arg.`From`, arg.`To`)/3600/24) as 'Sum Value',
group_concat(distinct arg_orig.Name) as 'Items'
from salesforce.audit_report_group__c arg_orig 
inner join analytics.sla_arg_tmp arg on arg_orig.Id = arg.Id
where
arg_orig.Audit_Report_Status__c = 'Completed'
and arg_orig.Work_Item_Stages__c not like ('%Product Update%')
and arg_orig.Work_Item_Stages__c not like ('%Initial Project%')
and arg.`Metric` in ('CA Revision', 'TR Revision')
group by arg_orig.Id, `_Metric`);

(select 
	'Performance' as '_Type',
	t.`_Metric`, 
	t.`Business Line`,
	substring_index(t.`Country`, ' - ',-1) as '_Country',
	null as 'Owner',
	t.`Program`,
	t.`Standards`,
	t.`Period`,
	sum(t.`Volume`) as 'Volume',
	sum(`Sum Value`) as 'Sum Value',
	null as 'Volume within SLA',
	null as 'Target',
	group_concat(t.`Items`) as 'Items',
    t.`Auto-Approved`,
	t.`With Hold`
from apac_ops_metric_arg_end_to_end_1_v3_2 t
where t.`Period` >= '2015 07'
and (t.`Country` like 'Australia' or t.`Country` like 'Asia%' or t.`Country` like '%Product%')
group by `_Type`, t.`_Metric`, `_Country`, `Owner`, `Standards`, `Target`, `Period`, `Auto-Approved`, `With Hold`)
union
(select 
	'Performance' as '_Type',
	'ARG End-to-End'as '_Metric', 
	t.`Business Line`,
	substring_index(t.`Country`, ' - ',-1) as '_Country',
	null as '_Owner',
	t.`Program`,
	t.`Standards`,
	t.`Period`,
    sum(t.`Volume`) as 'Volume',
	sum(t.`Sum Value`) as 'Sum Value',
	sum(if(t.`Sum Value`<=if(t.`Auto-Approved`,7,21),1,0)) as 'Volume within SLA',
	if(t.`Auto-Approved`,7,21) as 'Target',
    group_concat(distinct t.`Items`) as 'Items',
    t.`Auto-Approved`,
    t.`With Hold`
from apac_ops_metric_arg_end_to_end_2_v3_2 t
where t.`Period` >= '2015 07'
and (t.`Country` like 'Australia' or t.`Country` like 'Asia%' or t.`Country` like '%Product%')
group by `_Type`, `_Metric`, `_Country`, `_Owner`, `Standards`, `Target`, `Period`, `Auto-Approved`, `With Hold`);

lock tables sla_arg_v2 WRITE, apac_ops_metrics_v3 WRITE;
(select * from apac_ops_metrics_v3);
unlock tables;

(select 
	arg.Id,
	if(arg.`Metric` in ('ARG Submission - First','ARG Submission - Resubmission'), 'Delivery (Days)', 
		if(arg.`Metric` in ('CA Revision'),'Technical CA (Days)',
			if(arg.`Metric` in ('TR Revision'),'Technical TR (Days)',
				if(arg.`Metric` in ('ARG Completion/Hold'), 'Admin (Days)', 'Hold (Days)')))) as '_Metric', 
arg_orig.Client_Ownership__c as 'Country',
date_format((select max(`To`) from analytics.sla_arg_v2 where Id=arg_orig.Id), '%Y %m')  as 'Period',
if((select count(`Id`) from analytics.sla_arg_v2 where Id=arg_orig.Id)=2,TRUE,FALSE)  as 'Auto-Approved',
if((select count(t3.`Id`) from analytics.sla_arg_v2 t3 where t3.Id=arg_orig.Id and t3.`Metric`='ARG Hold')=1,TRUE,FALSE)  as 'With Hold',
if((select count(t3.`Id`) from analytics.sla_arg_v2 t3 where t3.Id=arg_orig.Id and t3.`Metric`='TR Revision')>0,TRUE,FALSE)  as 'With TR',
count(distinct arg.Id) as 'Volume',
sum(timestampdiff(second, arg.`From`, arg.`To`)/3600/24) as 'Sum Value',
group_concat(distinct arg_orig.Name) as 'Items'
from salesforce.audit_report_group__c arg_orig 
left join analytics.sla_arg_v2 arg on arg_orig.Id = arg.Id
where
arg_orig.Audit_Report_Status__c = 'Completed'
and arg_orig.Work_Item_Stages__c not like ('%Product Update%')
and arg_orig.Work_Item_Stages__c not like ('%Initial Project%')
and arg.`Metric` in ('TR Revision')
and arg_orig.Name ='ARG-184612'
group by arg_orig.Id, `_Metric`);

select * 
from analytics.sla_arg_v2 t3 
where t3.Id='a1Wd00000003N8hEAE';
