truncate analytics.sla_arg_v2;
call analytics.SlaUpdateArgV2();
#drop table `analytics`.`sla_arg_v2`;
CREATE TABLE `analytics`.`sla_arg_v2` (
  `Metric` varchar(64) DEFAULT NULL,
  `SLA Target (Business Days)` bigint(20) NOT NULL DEFAULT '0',
  `Type` varchar(3) NOT NULL DEFAULT '',
  `Id` varchar(18) DEFAULT NULL,
  `Name` text NOT NULL,
  `Region` text,
  `Owner` text,
  `TimeZone` text,
  `From` text,
  `To` datetime DEFAULT NULL,
  `SLA Due` datetime DEFAULT NULL,
  `Standards` text DEFAULT NULL,
  `Standard Families` text DEFAULT NULL,
  `Tags` text DEFAULT NULL,
  KEY `sla_arg_v2_index` (`Id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

drop FUNCTION analytics.getARGProcessTags;
DELIMITER //
CREATE FUNCTION analytics.getARGProcessTags(ClientOwnership TEXT, BusinessLine TEXT, Program TEXT, Standards TEXT, StandardFamily TEXT, BusinessUnit TEXT, WorkItemTypes TEXT) RETURNS TEXT
BEGIN
	DECLARE tag TEXT DEFAULT '';
    SET tag = (SELECT CONCAT(tag, IF(BusinessLine like '%Food%', 'Food;',IF(BusinessLine like '%Product%', 'PS;', 'MS;'))));
    SET tag = (SELECT CONCAT(tag, IF(Standards like '%Woolworths%' or Standards like '%WQA%' or StandardFamily like '%Woolworths%' or StandardFamily like '%WQA%', 'Woolworths;','')));
    SET tag = (SELECT CONCAT(tag, IF(Standards not like '%Woolworths%' and Standards not like '%WQA%' and (StandardFamily not like '%Woolworths%' or StandardFamily is null) and (StandardFamily not like '%WQA%' or StandardFamily is null), 'Not Woolworths;','')));
    SET tag = (SELECT CONCAT(tag, WorkItemTypes));
	RETURN tag;
 END //
DELIMITER ;

drop procedure analytics.SlaUpdateArgV2;
DELIMITER //
CREATE PROCEDURE analytics.SlaUpdateArgV2()
 BEGIN
declare start_time datetime;
declare lastUpdate_arg_submission datetime;
declare lastUpdate_arg_revision datetime;
declare lastUpdate_arg_completion datetime;
declare lastUpdate_arg_hold datetime;
declare lastUpdate_arg_process datetime;
set start_time = utc_timestamp();
set lastUpdate_arg_submission = '1970-01-01'; #(select if(max(slaarg.`To`) is null, '1970-01-01',max(slaarg.`To`)) from analytics.sla_arg_v2 slaarg where `Metric` in ('ARG Submission - First','ARG Submission - Resubmission') );
set lastUpdate_arg_revision = '1970-01-01'; #(select if(max(slaarg.`To`) is null, '1970-01-01',max(slaarg.`To`)) from analytics.sla_arg_v2 slaarg where `Metric` in ('ARG Revision - First','ARG Revision - Resubmission') and slaarg.`To` is not null );
set lastUpdate_arg_completion = '1970-01-01'; #(select if(max(slaarg.`To`) is null, '1970-01-01',max(slaarg.`To`)) from analytics.sla_arg_v2 slaarg where `Metric` in ('ARG Completion/Hold') );
set lastUpdate_arg_hold = '1970-01-01'; #(select if(max(slaarg.`To`) is null, '1970-01-01',max(slaarg.`To`)) from analytics.sla_arg_v2 slaarg where `Metric` in ('ARG Hold') );
set lastUpdate_arg_process = '1970-01-01'; #(select if(max(slaarg.`To`) is null, '1970-01-01',max(slaarg.`To`)) from analytics.sla_arg_v2 slaarg where `Metric` in ('ARG Process Time (BRC)', 'ARG Process Time (Other)') );

# Delete backlog as it is re-calculated every time
SET SQL_SAFE_UPDATES = 0;

# Auditor SLA - Performance
drop temporary table if exists analytics.sla_arg_perf;
create temporary table sla_arg_perf as
# First Submission (For projects the From date is the project start date.  It excludes projects with null start date)
(select 
'ARG Submission - First' as 'Metric',
analytics.getTarget('arg_submission_first',null,null) as 'SLA Target (Business Days)',
'ARG' as 'Type',
t2.RAudit_Report_Group__c as 'Id',
t2.Name as 'Name',
t2.Revenue_Ownership__c as 'Region',
t2.Owner as 'Owner',
t2.Time_Zone__c as 'TimeZone',
convert_tz(date_format(if(t2.Work_Item_Stage__c in ('Initial Project','Product Update', 'Standard Change'), t2.Project_Start_Date__c, t2.End_Service_Date__c), '%Y-%m-%d 17:00:00'),t2.Time_Zone__c, 'UTC') as 'From',
#t2.First_Submitted__c as 'To',
if(t2.Waiting_Client__c is null, t2.First_Submitted__c, greatest(t2.Waiting_Client__c, convert_tz(date_format(if(t2.Work_Item_Stage__c in ('Initial Project','Product Update', 'Standard Change'), t2.Project_Start_Date__c, t2.End_Service_Date__c), '%Y-%m-%d 17:00:00'),t2.Time_Zone__c, 'UTC'))) as 'To',
#if(t2.First_Submitted__c<ifnull(t2.Waiting_Client__c,'9999'), t2.First_Submitted__c, greatest(ifnull(t2.Waiting_Client__c,0), convert_tz(date_format(if(t2.Work_Item_Stage__c in ('Initial Project','Product Update', 'Standard Change'), t2.Project_Start_Date__c, t2.End_Service_Date__c), '%Y-%m-%d 17:00:00'),t2.Time_Zone__c, 'UTC'))) as `To`,
#analytics.getSLADueUTCTimestamp(convert_tz(date_format(t2.End_Service_Date__c, '%Y-%m-%d 17:00:00'),t2.Time_Zone__c, 'UTC'), t2.Time_Zone__c, analytics.getTarget('arg_submission_first',null,null))  as 'SLA Due',
analytics.getSLADueUTCTimestamp(convert_tz(date_format(if(t2.Work_Item_Stage__c in ('Initial Project','Product Update', 'Standard Change'), t2.Project_Start_Date__c, t2.End_Service_Date__c), '%Y-%m-%d 17:00:00'),t2.Time_Zone__c, 'UTC'), t2.Time_Zone__c, analytics.getTarget('arg_submission_first',null,null))  as 'SLA Due',
t2.`Standards`,
t2.`Standard Families`,
t2.`Tags`,
t2.`Business Line`, t2.`Pathway`, t2.`Program`, t2.`Client`, t2.`WI Type`
from (
select t.RAudit_Report_Group__c, t.Name, t.Revenue_Ownership__c, t.`Owner`, t.First_Submitted__c, t.Waiting_Client__c, t.Work_Item_Date__c, t.End_Service_Date__c, t.Time_Zone__c, t.Project_Start_Date__c, t.Work_Item_Stage__c,
group_concat(distinct t.`Standards` order by t.`Standards`) as 'Standards',
group_concat(distinct t.`Standard Families`) as 'Standard Families',
group_concat(distinct t.`Tags`) as 'Tags',
t.`Business Line`, t.`Pathway`, t.`Program`, t.`Client`, t.`WI Type` from (
select argwi.RAudit_Report_Group__c, arg.Name, sc.Revenue_Ownership__c, author.name as 'Owner', wi.Work_Item_Date__c, wi.End_Service_Date__c, s.Time_Zone__c, arg.Waiting_Client__c,
arg.First_Submitted__c, wi.Project_Start_Date__c, wi.Work_Item_Stage__c,
group_concat(distinct scsp.Standard_Service_Type_Name__c order by scsp.Standard_Service_Type_Name__c) as 'Standards',
group_concat(distinct if(scspf.IsDeleted or spf.isDeleted, null,spf.Standard_Service_Type_Name__c) separator ',') as 'Standard Families',
getARGProcessTags(
			group_concat(distinct wi.Client_Ownership__c),
            group_concat(distinct p.Business_Line__c),
            group_concat(distinct p.Name),
			group_concat(DISTINCT wi.Primary_Standard__c), 
            group_concat(distinct if(scspf.IsDeleted or spf.isDeleted, null,spf.Standard_Service_Type_Name__c) separator ','),
            author.Reporting_Business_Units__c,
            group_concat(distinct wi.Work_Item_Stage__c)) as 'Tags',
            (select count(Id) from analytics.sla_arg_v2 sla_arg where sla_arg.Id=arg.Id and sla_arg.`Metric`='ARG Submission - First') as 'Already measured first submission',
            p.Business_Line__c as 'Business Line',
            p.Pathway__c as 'Pathway',
            p.Name as 'Program',
            wi.Client_Name_No_Hyperlink__c as 'Client',
            wi.Work_Item_Stage__c as 'WI Type'
from salesforce.audit_report_group__c arg 
left join salesforce.resource__c author on arg.RAudit_Report_Author__c = author.Id
inner join salesforce.arg_work_item__c argwi on argwi.RAudit_Report_Group__c = arg.Id and argwi.IsDeleted = 0
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
(arg.First_Submitted__c > lastUpdate_arg_submission or date_add(arg.Waiting_Client__c, interval 1 day) > lastUpdate_arg_submission)
and arg.IsDeleted = 0
group by arg.Id, wi.Id
order by argwi.RAudit_Report_Group__c, wi.End_Service_Date__c desc) t
where t.`Already measured first submission`=0
group by t.RAudit_Report_Group__c) t2
where (t2.Project_Start_Date__c is not null or t2.End_Service_Date__c is not null))
# Waiting for client
union
(select 
'ARG Submission - Waiting On Client' as 'Metric',
analytics.getTargetARGGlobal('ARG Submission - Waiting On Client',null) as 'SLA Target (Business Days)',
'ARG' as 'Type',
t2.RAudit_Report_Group__c as 'Id',
t2.Name as 'Name',
t2.Revenue_Ownership__c as 'Region',
t2.Owner as 'Owner',
t2.Time_Zone__c as 'TimeZone',
greatest(t2.Waiting_Client__c, convert_tz(date_format(if(t2.Work_Item_Stage__c in ('Initial Project','Product Update', 'Standard Change'), t2.Project_Start_Date__c, t2.End_Service_Date__c), '%Y-%m-%d 17:00:00'),t2.Time_Zone__c, 'UTC')) as 'From',
t2.First_Submitted__c as `To`,
analytics.getSLADueUTCTimestamp(greatest(t2.Waiting_Client__c, convert_tz(date_format(t2.End_Service_Date__c, '%Y-%m-%d 17:00:00'),t2.Time_Zone__c, 'UTC')), t2.Time_Zone__c, analytics.getTargetARGGlobal('ARG Submission - Waiting On Client',null))  as 'SLA Due',
t2.`Standards`,
t2.`Standard Families`,
t2.`Tags`,
t2.`Business Line`, t2.`Pathway`, t2.`Program`, t2.`Client`, t2.`WI Type`
from (
select t.RAudit_Report_Group__c, t.Name, t.Revenue_Ownership__c, t.`Owner`, t.First_Submitted__c, t.Waiting_Client__c, t.Work_Item_Date__c, t.End_Service_Date__c, t.Time_Zone__c, t.Project_Start_Date__c, t.Work_Item_Stage__c,
group_concat(distinct t.`Standards` order by t.`Standards`) as 'Standards',
group_concat(distinct t.`Standard Families`) as 'Standard Families',
group_concat(distinct t.`Tags`) as 'Tags',
t.`Business Line`, t.`Pathway`, t.`Program`, t.`Client`, t.`WI Type` from (
select argwi.RAudit_Report_Group__c, arg.Name, sc.Revenue_Ownership__c, author.name as 'Owner', wi.Work_Item_Date__c, wi.End_Service_Date__c, s.Time_Zone__c,
arg.First_Submitted__c, arg.Waiting_Client__c, wi.Project_Start_Date__c, wi.Work_Item_Stage__c,
group_concat(distinct scsp.Standard_Service_Type_Name__c order by scsp.Standard_Service_Type_Name__c) as 'Standards',
group_concat(distinct if(scspf.IsDeleted or spf.isDeleted, null,spf.Standard_Service_Type_Name__c) separator ',') as 'Standard Families',
getARGProcessTags(
			group_concat(distinct wi.Client_Ownership__c),
            group_concat(distinct p.Business_Line__c),
            group_concat(distinct p.Name),
			group_concat(DISTINCT wi.Primary_Standard__c), 
            group_concat(distinct if(scspf.IsDeleted or spf.isDeleted, null,spf.Standard_Service_Type_Name__c) separator ','),
            author.Reporting_Business_Units__c,
            group_concat(distinct wi.Work_Item_Stage__c)) as 'Tags',
            p.Business_Line__c as 'Business Line',
            p.Pathway__c as 'Pathway',
            p.Name as 'Program',
            wi.Client_Name_No_Hyperlink__c as 'Client',
            wi.Work_Item_Stage__c as 'WI Type'
from salesforce.audit_report_group__c arg 
left join salesforce.resource__c author on arg.RAudit_Report_Author__c = author.Id
inner join salesforce.arg_work_item__c argwi on argwi.RAudit_Report_Group__c = arg.Id and argwi.IsDeleted = 0
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
arg.First_Submitted__c > lastUpdate_arg_submission
and arg.waiting_Client__c is not null
and arg.IsDeleted = 0
group by arg.Id, wi.Id
order by argwi.RAudit_Report_Group__c, wi.Work_Item_Date__c desc) t
group by t.RAudit_Report_Group__c) t2
where (t2.Project_Start_Date__c is not null or t2.End_Service_Date__c is not null))

# Resubmissions
union
(select 
'ARG Submission - Resubmission' as 'Metric',
analytics.getTarget('arg_submission_resubmission',null,null) as 'SLA Target (Business Days)',
'ARG' as 'Type',
t2.RAudit_Report_Group__c as 'Id',
t2.Name as 'Name',
t2.Revenue_Ownership__c as 'Region',
t2.Owner as 'Owner',
t2.Time_Zone__c as 'TimeZone',
t2.`Rejection Date` as 'From',
t2.createdDate as 'To',
analytics.getSLADueUTCTimestamp(t2.`Rejection Date`, t2.Time_Zone__c, analytics.getTarget('arg_submission_resubmission',null,null)) as 'SLA Due',
t2.`Standards`,
t2.`Standard Families`,
t2.`Tags`,
t2.`Business Line`, t2.`Pathway`, t2.`Program`, t2.`Client`, t2.`WI Type`
from (
select t.RAudit_Report_Group__c, t.Name, t.Revenue_Ownership__c, t.`Owner`, t.createdDate,t.Assigned_To__c ,t.Status__c, t.Comments__C, t.Work_Item_Date__c, t.End_Service_Date__c, t.Time_Zone__c,
(select max(ah.CreatedDate) as 'Rejection Date'
from salesforce.approval_history__c ah
where ah.RAudit_Report_Group__c = t.RAudit_Report_Group__c
and ah.Status__c = 'Rejected'
and ah.CreatedDate < t.createdDate) as 'Rejection Date',
group_concat(distinct t.`Standards` order by t.`Standards`) as 'Standards',
group_concat(distinct t.`Standard Families`) as 'Standard Families',
group_concat(distinct t.`Tags`) as 'Tags',
t.`Business Line`, t.`Pathway`, t.`Program`, t.`Client`, t.`WI Type` from (
select argwi.RAudit_Report_Group__c, arg.Name, sc.Revenue_Ownership__c, author.name as 'Owner', ah.createdDate,ah.Assigned_To__c ,ah.Status__c, ah.Comments__C, wi.Work_Item_Date__c, wi.End_Service_Date__c, s.Time_Zone__c,
group_concat(distinct scsp.Standard_Service_Type_Name__c order by scsp.Standard_Service_Type_Name__c) as 'Standards',
group_concat(distinct if(scspf.IsDeleted or spf.isDeleted, null,spf.Standard_Service_Type_Name__c) separator ',') as 'Standard Families',
getARGProcessTags(
			group_concat(distinct wi.Client_Ownership__c),
            group_concat(distinct p.Business_Line__c),
            group_concat(distinct p.Name),
			group_concat(DISTINCT wi.Primary_Standard__c), 
            group_concat(distinct if(scspf.IsDeleted or spf.isDeleted, null,spf.Standard_Service_Type_Name__c) separator ','),
            author.Reporting_Business_Units__c,
            group_concat(distinct wi.Work_Item_Stage__c)) as 'Tags',
            p.Business_Line__c as 'Business Line',
            p.Pathway__c as 'Pathway',
            p.Name as 'Program',
            wi.Client_Name_No_Hyperlink__c as 'Client',
            wi.Work_Item_Stage__c as 'WI Type'
from salesforce.approval_history__c ah 
inner join salesforce.audit_report_group__c arg on ah.RAudit_Report_Group__c = arg.Id
left join salesforce.resource__c author on arg.RAudit_Report_Author__c = author.Id
inner join salesforce.arg_work_item__c argwi on argwi.RAudit_Report_Group__c = ah.RAudit_Report_Group__c and argwi.IsDeleted = 0
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
ah.createdDate > lastUpdate_arg_submission
and ah.Status__c = 'Submitted'
and arg.IsDeleted = 0
#and (arg.Work_Item_Stages__c not like '%Initial Project%' and arg.Work_Item_Stages__c not like '%Product Update%' and arg.Work_Item_Stages__c not like '%Standard Change%')
group by arg.Id, wi.Id, ah.Id
order by argwi.RAudit_Report_Group__c, wi.Work_Item_Date__c desc) t
group by t.RAudit_Report_Group__c, t.Status__c, t.createdDate) t2
where t2.`Rejection Date` is not null)

#union
# Auto Approved
#(select 
#'ARG Submission - First' as 'Metric',
#analytics.getTarget('arg_submission_first',null,null) as 'SLA Target (Business Days)',
#'ARG' as 'Type',
#t2.RAudit_Report_Group__c as 'Id',
#t2.Name as 'Name',
#t2.Revenue_Ownership__c as 'Region',
#t2.Owner as 'Owner',
#t2.Time_Zone__c as 'TimeZone',
#convert_tz(date_format(t2.End_Service_Date__c, '%Y-%m-%d 17:00:00'),t2.Time_Zone__c, 'UTC') as 'From',
#t2.createdDate as 'To',
#analytics.getSLADueUTCTimestamp(convert_tz(date_format(t2.End_Service_Date__c, '%Y-%m-%d 17:00:00'),t2.Time_Zone__c, 'UTC'), t2.Time_Zone__c, analytics.getTarget('arg_submission_first',null,null)) as 'SLA Due',
#t2.`Standards`,
#t2.`Standard Families`,
#concat(t2.`Tags`, ',Auto-Approved')
#from (
#select t.RAudit_Report_Group__c, t.Name, t.Revenue_Ownership__c, t.`Owner`, t.createdDate,t.Assigned_To__c ,t.Status__c, t.Comments__C, t.Work_Item_Date__c, t.End_Service_Date__c, t.Time_Zone__c,
#group_concat(distinct t.`Standards`) as 'Standards',
#group_concat(distinct t.`Standard Families`) as 'Standard Families',
#group_concat(distinct t.`Tags`) as 'Tags' from (
#select argwi.RAudit_Report_Group__c, arg.Name, sc.Revenue_Ownership__c, author.name as 'Owner', ah.createdDate,ah.Assigned_To__c ,ah.Status__c, ah.Comments__C, wi.Work_Item_Date__c, wi.End_Service_Date__c, s.Time_Zone__c,
#group_concat(distinct scsp.Standard_Service_Type_Name__c) as 'Standards',
#group_concat(distinct if(scspf.IsDeleted or spf.isDeleted, null,spf.Standard_Service_Type_Name__c) separator ',') as 'Standard Families',
#getARGProcessTags(
#			group_concat(distinct wi.Client_Ownership__c),
#            group_concat(distinct p.Business_Line__c),
#            group_concat(distinct p.Name),
#			group_concat(DISTINCT wi.Primary_Standard__c), 
#            group_concat(distinct if(scspf.IsDeleted or spf.isDeleted, null,spf.Standard_Service_Type_Name__c) separator ','),
#            author.Reporting_Business_Units__c,
#            group_concat(distinct wi.Work_Item_Stage__c)) as 'Tags'
#from salesforce.approval_history__c ah 
#inner join salesforce.audit_report_group__c arg on ah.RAudit_Report_Group__c = arg.Id
#left join salesforce.resource__c author on arg.RAudit_Report_Author__c = author.Id
#inner join salesforce.arg_work_item__c argwi on argwi.RAudit_Report_Group__c = ah.RAudit_Report_Group__c
#inner join salesforce.work_item__c wi on argwi.RWork_Item__c = wi.Id
#inner join salesforce.work_package__c wp on wi.Work_Package__c = wp.Id
#inner join salesforce.certification__c sc on wp.Site_Certification__c = sc.Id
#inner join salesforce.account s on sc.Primary_client__c = s.Id
#inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
#inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
#inner join salesforce.program__c p on sp.Program__c = p.Id
#left join salesforce.site_certification_standard_family__c scspf on scspf.Site_Certification_Standard__c = scsp.Id
#left join salesforce.standard_program__c spf on scspf.Standard_Program__c = spf.Id
#where 
#ah.createdDate > lastUpdate_arg_submission
#and ah.Status__c = 'Completed' 
#and (ah.Comments__c like '%Auto Approved%' or ah.Comments__c like '%Auto-Approved%')
#group by arg.Id, wi.Id, ah.Id
#order by argwi.RAudit_Report_Group__c, wi.Work_Item_Date__c desc) t
#group by t.RAudit_Report_Group__c) t2)
union
# PRC SLA - Performance
(select 
if (ABS(TIME_TO_SEC(TIMEDIFF(t2.`Submission Date`,t2.First_Submitted__c)))<60 or t2.`Submission Date` is null,'ARG Revision - First','ARG Revision - Resubmission') as 'Metric',
if (ABS(TIME_TO_SEC(TIMEDIFF(t2.`Submission Date`,t2.First_Submitted__c)))<60 or t2.`Submission Date` is null,analytics.getTarget('arg_revision_first',null,null),analytics.getTarget('arg_revision_resubmission',null,null)) as 'SLA Target (Business Days)',
'ARG' as 'Type',
t2.RAudit_Report_Group__c as 'Id',
t2.Name as 'Name',
t2.Revenue_Ownership__c as 'Region',
t2.Owner as 'Owner',
t2.Time_Zone__c as 'TimeZone',
if (ABS(TIME_TO_SEC(TIMEDIFF(t2.`Submission Date`,t2.First_Submitted__c)))<60 or t2.`Submission Date` is null, t2.First_Submitted__c, t2.`Submission Date`) as 'From',
t2.createdDate as 'To',
if (ABS(TIME_TO_SEC(TIMEDIFF(t2.`Submission Date`,t2.First_Submitted__c)))<60 or t2.`Submission Date` is null,
	analytics.getSLADueUTCTimestamp(t2.First_Submitted__c, t2.Time_Zone__c, analytics.getTarget('arg_revision_first',null,null)),
	analytics.getSLADueUTCTimestamp(t2.`Submission Date`, t2.Time_Zone__c, analytics.getTarget('arg_revision_resubmission',null,null))) as 'SLA Due',
t2.`Standards`,
t2.`Standard Families`,
t2.`Tags`,
t2.`Business Line`, t2.`Pathway`, t2.`Program`, t2.`Client`, t2.`WI Type`
from (
select t.RAudit_Report_Group__c, t.First_Submitted__c, t.Name, t.`Owner`, t.Revenue_Ownership__c, t.createdDate,t.Assigned_To__c ,t.Status__c, t.Comments__C, t.Work_Item_Date__c, t.Time_Zone__c,
(select max(ah.CreatedDate) as 'Submission Date'
from salesforce.approval_history__c ah
where ah.RAudit_Report_Group__c = t.RAudit_Report_Group__c
and (ah.Status__c = 'Submitted')
and ah.CreatedDate < t.createdDate) as 'Submission Date',
group_concat(distinct t.`Standards` order by t.`Standards`) as 'Standards',
group_concat(distinct t.`Standard Families`) as 'Standard Families',
group_concat(distinct t.`Tags`) as 'Tags',
t.`Business Line`, t.`Pathway`, t.`Program`, t.`Client`, t.`WI Type`
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
            group_concat(distinct wi.Work_Item_Stage__c)) as 'Tags',
            p.Business_Line__c as 'Business Line',
            p.Pathway__c as 'Pathway',
            p.Name as 'Program',
            wi.Client_Name_No_Hyperlink__c as 'Client',
            wi.Work_Item_Stage__c as 'WI Type'
from salesforce.approval_history__c ah 
inner join salesforce.audit_report_group__c arg on ah.RAudit_Report_Group__c = arg.Id
left join salesforce.resource__c ca on arg.Assigned_CA__c = ca.Id
inner join salesforce.arg_work_item__c argwi on argwi.RAudit_Report_Group__c = ah.RAudit_Report_Group__c and argwi.IsDeleted = 0
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
ah.createdDate > lastUpdate_arg_revision
and arg.IsDeleted = 0
and (ah.Status__c in ('Rejected') or (ah.Status__c = 'Approved' and ah.Assigned_to__c = 'Client Administration'))
#and (arg.Work_Item_Stages__c not like '%Initial Project%' and arg.Work_Item_Stages__c not like '%Product Update%' and arg.Work_Item_Stages__c not like '%Standard Change%')
group by arg.Id, wi.Id, ah.Id
order by argwi.RAudit_Report_Group__c, wi.Work_Item_Date__c desc) t
group by t.RAudit_Report_Group__c, t.Status__c, t.createdDate) t2)
union
# Technical Performance - Split between CA and TR
(select t.* from
(select 
if(ah.Assigned_To__c = 'Certification Approver', 'CA Revision',
if(ah.Assigned_To__c in ('Technical Review', 'Technical Reviewer'), 'TR Revision',null)) as 'Metric',
0 as 'Target',
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
            group_concat(distinct wi.Work_Item_Stage__c)) as 'Tags',
            p.Business_Line__c as 'Business Line',
            p.Pathway__c as 'Pathway',
            p.Name as 'Program',
            wi.Client_Name_No_Hyperlink__c as 'Client',
            wi.Work_Item_Stage__c as 'WI Type'
from salesforce.approval_history__c ah 
inner join salesforce.audit_report_group__c arg on ah.RAudit_Report_Group__c = arg.Id
left join salesforce.resource__c ca on arg.Assigned_CA__c = ca.Id
left join salesforce.resource__c tr on arg.Assigned_TR__c = tr.Id
inner join salesforce.arg_work_item__c argwi on argwi.RAudit_Report_Group__c = ah.RAudit_Report_Group__c and argwi.IsDeleted = 0
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
ah.LastModifiedDate > lastUpdate_arg_completion
and arg.IsDeleted = 0
and ah.Assigned_To__c in ('Technical Review', 'Technical Reviewer', 'Certification Approver')
and ah.Status__c not in ('Taken', 'Assigned', 'Returned', 'Completed') # These are operations to/from public queues.  We are not interested from metrics perspective yet.
group by ah.Id
order by argwi.RAudit_Report_Group__c, ah.CreatedDate) t
where t.`To` is not null)
union
# Admin SLA - Performance (from ARG Approved to first of Hold or Completed)
(select 
'ARG Completion/Hold' as 'Metric',
analytics.getTarget('arg_completion',null,null) as 'SLA Target (Business Days)',
'ARG' as 'Type',
t2.RAudit_Report_Group__c as 'Id',
t2.Name as 'Name',
t2.Revenue_Ownership__c as 'Region',
t2.`Owner` as 'Owner',
t2.Time_Zone__c as 'TimeZone',
if(t2.`Approval Date` is null, t2.First_Submitted__c, t2.`Approval Date`) as 'From',
t2.createdDate as 'To',
analytics.getSLADueUTCTimestamp(if(t2.`Approval Date` is null, t2.First_Submitted__c, t2.`Approval Date`), t2.Time_Zone__c, analytics.getTarget('arg_completion',null,null)) as 'SLA Due',
t2.`Standards`,
t2.`Standard Families`,
t2.`Tags`,
t2.`Business Line`, t2.`Pathway`, t2.`Program`, t2.`Client`, t2.`WI Type`
from (
select t.RAudit_Report_Group__c, t.First_Submitted__c, t.Name, t.`Owner`, t.Revenue_Ownership__c, t.createdDate ,t.Assigned_To__c ,t.Status__c, t.Comments__C, t.Work_Item_Date__c, t.Time_Zone__c, 
(select max(ah.CreatedDate) as 'Approval Date'
from salesforce.approval_history__c ah
where ah.RAudit_Report_Group__c = t.RAudit_Report_Group__c
and (ah.Status__c = 'Approved' and ah.Assigned_To__c = 'Client Administration')
and ah.CreatedDate < t.createdDate) as 'Approval Date',
group_concat(distinct t.`Standards` order by t.`Standards`) as 'Standards',
group_concat(distinct t.`Standard Families`) as 'Standard Families',
group_concat(distinct t.`Tags`) as 'Tags',
t.`Business Line`, t.`Pathway`, t.`Program`, t.`Client`, t.`WI Type`
from (
select argwi.RAudit_Report_Group__c, arg.First_Submitted__c, arg.Name, admin.Name as 'Owner', sc.Revenue_Ownership__c, ah.createdDate,ah.Assigned_To__c ,ah.Status__c, ah.Comments__C, wi.Work_Item_Date__c, s.Time_Zone__c,
group_concat(distinct scsp.Standard_Service_Type_Name__c order by scsp.Standard_Service_Type_Name__c) as 'Standards',
group_concat(distinct if(scspf.IsDeleted or spf.isDeleted, null,spf.Standard_Service_Type_Name__c) separator ',') as 'Standard Families',
getARGProcessTags(
			group_concat(distinct wi.Client_Ownership__c),
            group_concat(distinct p.Business_Line__c),
            group_concat(distinct p.Name),
			group_concat(DISTINCT wi.Primary_Standard__c), 
            group_concat(distinct if(scspf.IsDeleted or spf.isDeleted, null,spf.Standard_Service_Type_Name__c) separator ','),
            admin.Reporting_Business_Units__c,
            group_concat(distinct wi.Work_Item_Stage__c)) as 'Tags',
            p.Business_Line__c as 'Business Line',
            p.Pathway__c as 'Pathway',
            p.Name as 'Program',
            wi.Client_Name_No_Hyperlink__c as 'Client',
            wi.Work_Item_Stage__c as 'WI Type',
(select count(Id) from analytics.sla_arg_v2 sla_arg where sla_arg.Id=arg.Id and sla_arg.`Metric`='ARG Completion/Hold') as 'Already measured hold'
from salesforce.approval_history__c ah 
inner join salesforce.audit_report_group__c arg on ah.RAudit_Report_Group__c = arg.Id
left join salesforce.resource__c admin on arg.Assigned_Admin__c = admin.Id
inner join salesforce.arg_work_item__c argwi on argwi.RAudit_Report_Group__c = ah.RAudit_Report_Group__c and argwi.IsDeleted = 0
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
ah.LastModifiedDate > lastUpdate_arg_completion
and ah.Status__c in ('Completed','Hold')
and arg.IsDeleted = 0
and ((ah.Comments__c not like '%Auto Approved%' and ah.Comments__c not like '%Auto-Approved%' and ah.Comments__c not like '%Forced to Completed%') or ah.Comments__c  is null)
group by arg.Id, ah.Id
order by argwi.RAudit_Report_Group__c, ah.CreatedDate asc) t
where t.`Already measured hold`=0
group by t.RAudit_Report_Group__c) t2)
union
# ARG Admin Performance form Hold to Completed
(select 
'ARG Hold' as 'Metric',
analytics.getTarget('arg_completion',null,null) as 'SLA Target (Business Days)',
'ARG' as 'Type',
t2.RAudit_Report_Group__c as 'Id',
t2.Name as 'Name',
t2.Revenue_Ownership__c as 'Region',
t2.`Owner` as 'Owner',
t2.Time_Zone__c as 'TimeZone',
t2.`Hold Date` as 'From',
t2.createdDate as 'To',
analytics.getSLADueUTCTimestamp(t2.`Hold Date`, t2.Time_Zone__c, analytics.getTarget('arg_hold',null,null)) as 'SLA Due',
t2.`Standards`,
t2.`Standard Families`,
t2.`Tags`,
t2.`Business Line`, t2.`Pathway`, t2.`Program`, t2.`Client`, t2.`WI Type`
from (
select t.RAudit_Report_Group__c, t.First_Submitted__c, t.Name, t.`Owner`, t.Revenue_Ownership__c, t.createdDate,t.Assigned_To__c ,t.Status__c, t.Comments__C, t.Work_Item_Date__c, t.Time_Zone__c, 
(select min(ah.CreatedDate) as 'Hold Date'
from salesforce.approval_history__c ah
where ah.RAudit_Report_Group__c = t.RAudit_Report_Group__c
and (ah.Status__c = 'Hold' and ah.Assigned_To__c = 'Client Administration')
and ah.CreatedDate < t.createdDate) as 'Hold Date',
group_concat(distinct t.`Standards` order by t.`Standards`) as 'Standards',
group_concat(distinct t.`Standard Families`) as 'Standard Families',
group_concat(distinct t.`Tags`) as 'Tags',
t.`Business Line`, t.`Pathway`, t.`Program`, t.`Client`, t.`WI Type`
from (
select argwi.RAudit_Report_Group__c, arg.First_Submitted__c, arg.Name, admin.Name as 'Owner', sc.Revenue_Ownership__c, ah.createdDate,ah.Assigned_To__c ,ah.Status__c, ah.Comments__C, wi.Work_Item_Date__c, s.Time_Zone__c,
group_concat(distinct scsp.Standard_Service_Type_Name__c order by scsp.Standard_Service_Type_Name__c) as 'Standards',
group_concat(distinct if(scspf.IsDeleted or spf.isDeleted, null,spf.Standard_Service_Type_Name__c) separator ',') as 'Standard Families',
getARGProcessTags(
			group_concat(distinct wi.Client_Ownership__c),
            group_concat(distinct p.Business_Line__c),
            group_concat(distinct p.Name),
			group_concat(DISTINCT wi.Primary_Standard__c), 
            group_concat(distinct if(scspf.IsDeleted or spf.isDeleted, null,spf.Standard_Service_Type_Name__c) separator ','),
            admin.Reporting_Business_Units__c,
            group_concat(distinct wi.Work_Item_Stage__c)) as 'Tags',
            p.Business_Line__c as 'Business Line',
            p.Pathway__c as 'Pathway',
            p.Name as 'Program',
            wi.Client_Name_No_Hyperlink__c as 'Client',
            wi.Work_Item_Stage__c as 'WI Type'
from salesforce.approval_history__c ah 
inner join salesforce.audit_report_group__c arg on ah.RAudit_Report_Group__c = arg.Id
left join salesforce.resource__c admin on arg.Assigned_Admin__c = admin.Id
inner join salesforce.arg_work_item__c argwi on argwi.RAudit_Report_Group__c = ah.RAudit_Report_Group__c and argwi.IsDeleted = 0
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
ah.LastModifiedDate > lastUpdate_arg_hold
and ah.Status__c in ('Completed')
and arg.IsDeleted = 0
group by arg.Id, wi.Id, ah.Id
order by argwi.RAudit_Report_Group__c, ah.CreatedDate asc) t
group by t.RAudit_Report_Group__c) t2
where t2.`Hold Date` is not null)
union
# ARG Process - From Audit End to Admin Completed
(select 
if(t2.Audit_Report_Standards__c like '%BRC%', 'ARG Process Time (BRC)', 'ARG Process Time (Other)') as 'Metric',
if(t2.Audit_Report_Standards__c like '%BRC%', analytics.getTarget('arg_process_brc',null,null), analytics.getTarget('arg_process_other',null,null)) as 'SLA Target (Business Days)',
'ARG' as 'Type',
t2.RAudit_Report_Group__c as 'Id',
t2.Name as 'Name',
t2.Revenue_Ownership__c as 'Region',
t2.`Owner` as 'Owner',
t2.Time_Zone__c as 'TimeZone',
convert_tz(date_format(t2.End_Service_Date__c, '%Y-%m-%d 17:00:00'),t2.Time_Zone__c, 'UTC') as 'From',
t2.`Completed/Hold Date` as 'To',
analytics.getSLADueUTCTimestamp(convert_tz(date_format(t2.End_Service_Date__c, '%Y-%m-%d 17:00:00'),t2.Time_Zone__c, 'UTC'), t2.Time_Zone__c, if(t2.Audit_Report_Standards__c like '%BRC%', analytics.getTarget('arg_process_brc',null,null), analytics.getTarget('arg_process_other',null,null))) as 'SLA Due',
t2.`Standards`,
t2.`Standard Families`,
t2.`Tags`,
t2.`Business Line`, t2.`Pathway`, t2.`Program`, t2.`Client`, t2.`WI Type`
from (
select t.RAudit_Report_Group__c, t.First_Submitted__c, t.Audit_Report_Standards__c, t.Name, t.`Owner`, t.Revenue_Ownership__c, t.`Completed/Hold Date`,t.Assigned_To__c ,t.Status__c, t.Comments__C, t.Work_Item_Date__c, t.End_Service_Date__c, t.Time_Zone__c, t.Work_Item_Stage__c, 
group_concat(distinct t.`Standards` order by t.`Standards`) as 'Standards',
group_concat(distinct t.`Standard Families`) as 'Standard Families',
group_concat(distinct t.`Tags`) as 'Tags',
t.`Business Line`, t.`Pathway`, t.`Program`, t.`Client`, t.`WI Type`
from (
select argwi.RAudit_Report_Group__c, arg.First_Submitted__c, arg.Audit_Report_Standards__c, arg.Name, admin.Name as 'Owner', sc.Revenue_Ownership__c, ah.createdDate as 'Completed/Hold Date',ah.Assigned_To__c ,ah.Status__c, ah.Comments__C, wi.Work_Item_Date__c, wi.End_Service_Date__c, s.Time_Zone__c, wi.Work_Item_Stage__c,
group_concat(distinct scsp.Standard_Service_Type_Name__c order by scsp.Standard_Service_Type_Name__c) as 'Standards',
group_concat(distinct if(scspf.IsDeleted or spf.isDeleted, null,spf.Standard_Service_Type_Name__c) separator ',') as 'Standard Families',
getARGProcessTags(
			group_concat(distinct wi.Client_Ownership__c),
            group_concat(distinct p.Business_Line__c),
            group_concat(distinct p.Name),
			group_concat(DISTINCT wi.Primary_Standard__c), 
            group_concat(distinct if(scspf.IsDeleted or spf.isDeleted, null,spf.Standard_Service_Type_Name__c) separator ','),
            admin.Reporting_Business_Units__c,
            group_concat(distinct wi.Work_Item_Stage__c)) as 'Tags',
            p.Business_Line__c as 'Business Line',
            p.Pathway__c as 'Pathway',
            p.Name as 'Program',
            wi.Client_Name_No_Hyperlink__c as 'Client',
            wi.Work_Item_Stage__c as 'WI Type',
            (select count(Id) from analytics.sla_arg_v2 sla_arg where sla_arg.Id=arg.Id and sla_arg.`Metric` in ('ARG Process Time (BRC)', 'ARG Process Time (Other)')) as 'Already measured'
from salesforce.approval_history__c ah 
inner join salesforce.audit_report_group__c arg on ah.RAudit_Report_Group__c = arg.Id
left join salesforce.resource__c admin on arg.Assigned_Admin__c = admin.Id
inner join salesforce.arg_work_item__c argwi on argwi.RAudit_Report_Group__c = ah.RAudit_Report_Group__c and argwi.IsDeleted = 0
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
ah.LastModifiedDate > lastUpdate_arg_process
and ah.Status__c in ('Completed','Hold')
and arg.IsDeleted = 0
#and if(arg.Audit_Report_Standards__c like '%BRC%', wi.Work_Item_Stage__c not like '%Follow Up%', true)
#and (arg.Work_Item_Stages__c not like '%Initial Project%' and arg.Work_Item_Stages__c not like '%Product Update%' and arg.Work_Item_Stages__c not like '%Standard Change%')
group by arg.Id, wi.Id, ah.Id
order by argwi.RAudit_Report_Group__c, ah.CreatedDate asc) t
where t.`Already measured`=0
group by t.RAudit_Report_Group__c) t2);

drop temporary table if exists analytics.sla_arg_backlog;
create temporary table sla_arg_backlog as 
# Auditor SLA - Backlog (For projects the From date is the project start date.  It excludes projects with null start date)
(select 
if(t.Audit_Report_Status__c = 'Pending', 
	#'ARG Submission - First', 
    if(t.Waiting_Client__c is null, 'ARG Submission - First', 'ARG Submission - Waiting On Client'),
    'ARG Submission - Resubmission') as 'Metric',
analytics.getTargetARGGlobal(if(t.Audit_Report_Status__c = 'Pending', if(t.Waiting_Client__c is null, 'ARG Submission - First', 'ARG Submission - Waiting On Client'), 'ARG Submission - Resubmission'),null) as 'SLA Target (Business Days)',
'ARG' as 'Type',
t.RAudit_Report_Group__c as 'Id',
t.`Name` as 'Name',
t.Revenue_Ownership__c as 'Region',
t.`Owner` as 'Owner',
t.Time_Zone__c as 'TimeZone',
if(t.Audit_Report_Status__c = 'Pending',
	if(t.Waiting_Client__c is null,
		convert_tz(date_format(if(t.Work_Item_Stage__c in ('Initial Project', 'Product Update', 'Standard Change'), t.Project_Start_Date__c, t.End_Service_Date__c), '%Y-%m-%d 17:00:00'),t.Time_Zone__c, 'UTC'), 
		t.Waiting_Client__c ),
	#convert_tz(date_format(if(t.Work_Item_Stage__c in ('Initial Project', 'Product Update', 'Standard Change'), t.Project_Start_Date__c, t.End_Service_Date__c), '%Y-%m-%d 17:00:00'),t.Time_Zone__c, 'UTC'), 
	(select max(ah.CreatedDate) as 'Rejection Date'
		from salesforce.approval_history__c ah
		where ah.RAudit_Report_Group__c = t.RAudit_Report_Group__c
		and ah.Status__c = 'Rejected')
) as 'From',
null as 'To',
analytics.getSLADueUTCTimestamp(
	if(t.Audit_Report_Status__c = 'Pending',
		if(t.Waiting_Client__c is null,
			convert_tz(date_format(if(t.Work_Item_Stage__c in ('Initial Project', 'Product Update', 'Standard Change'), t.Project_Start_Date__c, t.End_Service_Date__c), '%Y-%m-%d 17:00:00'),t.Time_Zone__c, 'UTC'), 
			t.Waiting_Client__c ),			
		(select max(ah.CreatedDate) as 'Rejection Date'
				from salesforce.approval_history__c ah
				where ah.RAudit_Report_Group__c = t.RAudit_Report_Group__c
				and ah.Status__c = 'Rejected')),
    t.Time_Zone__c, 
    analytics.getTargetARGGlobal(if(t.Audit_Report_Status__c = 'Pending', if(t.Waiting_Client__c is null, 'ARG Submission - First', 'ARG Submission - Waiting On Client'), 'ARG Submission - Resubmission'),null)
) as 'SLA Due',
group_concat(distinct t.`Standards` order by t.`Standards`) as 'Standards',
group_concat(distinct t.`Standard Families`) as 'Standard Families',
group_concat(distinct t.`Tags`) as 'Tags',
t.`Business Line`, t.`Pathway`, t.`Program`, t.`Client`, t.`WI Type`
from (
select argwi.RAudit_Report_Group__c, arg.Name, author.Name as 'Owner', arg.Audit_Report_Status__c, sc.Revenue_Ownership__c, wi.Work_Item_Date__c, wi.End_Service_Date__c, wi.Status__c as 'Work_Item_Status', s.Time_Zone__c, arg.Waiting_Client__c,
group_concat(distinct scsp.Standard_Service_Type_Name__c order by scsp.Standard_Service_Type_Name__c) as 'Standards',
group_concat(distinct if(scspf.IsDeleted or spf.isDeleted, null,spf.Standard_Service_Type_Name__c) separator ',') as 'Standard Families',
getARGProcessTags(
			group_concat(distinct wi.Client_Ownership__c),
            group_concat(distinct p.Business_Line__c),
            group_concat(distinct p.Name),
			group_concat(DISTINCT wi.Primary_Standard__c), 
            group_concat(distinct if(scspf.IsDeleted or spf.isDeleted, null,spf.Standard_Service_Type_Name__c) separator ','),
            author.Reporting_Business_Units__c,
            group_concat(distinct wi.Work_Item_Stage__c)) as 'Tags', wi.Project_Start_Date__c, wi.Work_Item_Stage__c,
            p.Business_Line__c as 'Business Line',
            p.Pathway__c as 'Pathway',
            p.Name as 'Program',
            wi.Client_Name_No_Hyperlink__c as 'Client',
            wi.Work_Item_Stage__c as 'WI Type'
from salesforce.audit_report_group__c arg
left join salesforce.resource__c author on arg.RAudit_Report_Author__c = author.Id
inner join salesforce.arg_work_item__c argwi on argwi.RAudit_Report_Group__c = arg.Id and argwi.IsDeleted = 0
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
arg.Audit_Report_Status__c in ('Under Review - Rejected', 'Pending') 
and wi.Status__c not in ('In Progress')
and arg.IsDeleted = 0
#and (arg.Work_Item_Stages__c not like '%Initial Project%' and arg.Work_Item_Stages__c not like '%Product Update%' and arg.Work_Item_Stages__c not like '%Standard Change%')
group by arg.Id, wi.Id
order by arg.Id, wi.Work_Item_Date__c desc) t
where t.Project_Start_Date__c is not null or t.End_Service_Date__c is not null
group by t.RAudit_Report_Group__c, t.Audit_Report_Status__c)
union
(select 'ARG Submission - Unsubmitted WI' as 'Metric', 
analytics.getTarget('arg_submission_first',null,null) as 'SLA Target (Business Days)',
'WI' as 'Type', wi.Id as 'Id', wi.Name as 'Name', 
sc.Revenue_Ownership__c as 'Region', 
auditor.Name as 'Owner',
s.Time_Zone__c as 'TimeZone',
#convert_tz(date_format(wi.Work_Item_Date__c, '%Y-%m-%d 17:00:00'),s.Time_Zone__c, 'UTC') as 'from', 
convert_tz(date_format(if(wi.Work_Item_Stage__c in ('Initial Project','Product Update', 'Standard Change'), wi.Project_Start_Date__c, wi.End_Service_Date__c), '%Y-%m-%d 17:00:00'),s.Time_Zone__c, 'UTC') as 'From',
null as 'To',
#analytics.getSLADueUTCTimestamp(convert_tz(date_format(wi.Work_Item_Date__c, '%Y-%m-%d 17:00:00'),s.Time_Zone__c, 'UTC'), s.Time_Zone__c, analytics.getTarget('arg_submission_first',null,null)) as 'SLA Due',
analytics.getSLADueUTCTimestamp(convert_tz(date_format(if(wi.Work_Item_Stage__c in ('Initial Project','Product Update', 'Standard Change'), wi.Project_Start_Date__c, wi.End_Service_Date__c), '%Y-%m-%d 17:00:00'),s.Time_Zone__c, 'UTC'), s.Time_Zone__c, analytics.getTarget('arg_submission_first',null,null))  as 'SLA Due',
group_concat(distinct scsp.Standard_Service_Type_Name__c order by scsp.Standard_Service_Type_Name__c) as 'Standards',
group_concat(distinct if(scspf.IsDeleted or spf.isDeleted, null,spf.Standard_Service_Type_Name__c) separator ',') as 'Standard Families',
 getARGProcessTags(
			group_concat(distinct wi.Client_Ownership__c),
            group_concat(distinct p.Business_Line__c),
            group_concat(distinct p.Name),
			group_concat(DISTINCT wi.Primary_Standard__c), 
            group_concat(distinct if(scspf.IsDeleted or spf.isDeleted, null,spf.Standard_Service_Type_Name__c) separator ','),
            auditor.Reporting_Business_Units__c,
            group_concat(distinct wi.Work_Item_Stage__c)) as 'Tags',
            p.Business_Line__c as 'Business Line',
            p.Pathway__c as 'Pathway',
            p.Name as 'Program',
            wi.Client_Name_No_Hyperlink__c as 'Client',
            wi.Work_Item_Stage__c as 'WI Type'
from salesforce.work_item__c wi
left join salesforce.resource__c auditor on wi.Work_Item_Owner__c = auditor.Id
inner join salesforce.work_package__c wp on wi.Work_Package__c = wp.Id
inner join salesforce.certification__c sc on wp.Site_Certification__c = sc.Id
inner join salesforce.account s on sc.Primary_client__c = s.Id
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
inner join salesforce.program__c p on sp.Program__c = p.Id
left join salesforce.site_certification_standard_family__c scspf on scspf.Site_Certification_Standard__c = scsp.Id
left join salesforce.standard_program__c spf on scspf.Standard_Program__c = spf.Id
where 
wi.Status__c in ('In Progress')
and wi.IsDeleted = 0
#and convert_tz(date_format(wi.Work_Item_Date__c, '%Y-%m-%d 17:00:00'),s.Time_Zone__c, 'UTC') < utc_timestamp()
and convert_tz(date_format(if(wi.Work_Item_Stage__c in ('Initial Project','Product Update', 'Standard Change'), wi.Project_Start_Date__c, wi.End_Service_Date__c), '%Y-%m-%d 17:00:00'),s.Time_Zone__c, 'UTC') < utc_timestamp()
#and wi.Work_Item_Stage__c not in ('Initial Project', 'Product Update', 'Standard Change')
group by wi.Id)
union
(select 'ARG Submission - Submitted WI No ARG' as 'Metric', 
analytics.getTarget('arg_submission_first',null,null) as 'SLA Target (Business Days)',
'WI' as 'Type', wi.Id as 'Id', wi.Name as 'Name', 
sc.Revenue_Ownership__c as 'Region', 
auditor.Name as 'Owner',
s.Time_Zone__c as 'TimeZone',
#convert_tz(date_format(wi.Work_Item_Date__c, '%Y-%m-%d 17:00:00'),s.Time_Zone__c, 'UTC') as 'from', 
convert_tz(date_format(if(wi.Work_Item_Stage__c in ('Initial Project','Product Update', 'Standard Change'), wi.Project_Start_Date__c, wi.End_Service_Date__c), '%Y-%m-%d 17:00:00'),s.Time_Zone__c, 'UTC') as 'From',
null as 'To',
analytics.getSLADueUTCTimestamp(convert_tz(date_format(if(wi.Work_Item_Stage__c in ('Initial Project','Product Update', 'Standard Change'), wi.Project_Start_Date__c, wi.End_Service_Date__c), '%Y-%m-%d 17:00:00'),s.Time_Zone__c, 'UTC'), s.Time_Zone__c, analytics.getTarget('arg_submission_first',null,null))  as 'SLA Due',
#analytics.getSLADueUTCTimestamp(convert_tz(date_format(wi.Work_Item_Date__c, '%Y-%m-%d 17:00:00'),s.Time_Zone__c, 'UTC'), s.Time_Zone__c, analytics.getTarget('arg_submission_first',null,null)) as 'SLA Due',
group_concat(distinct scsp.Standard_Service_Type_Name__c order by scsp.Standard_Service_Type_Name__c) as 'Standards',
group_concat(distinct if(scspf.IsDeleted or spf.isDeleted, null,spf.Standard_Service_Type_Name__c) separator ',') as 'Standard Families',
 getARGProcessTags(
			group_concat(distinct wi.Client_Ownership__c),
            group_concat(distinct p.Business_Line__c),
            group_concat(distinct p.Name),
			group_concat(DISTINCT wi.Primary_Standard__c), 
            group_concat(distinct if(scspf.IsDeleted or spf.isDeleted, null,spf.Standard_Service_Type_Name__c) separator ','),
            auditor.Reporting_Business_Units__c,
            group_concat(distinct wi.Work_Item_Stage__c)) as 'Tags',
            p.Business_Line__c as 'Business Line',
            p.Pathway__c as 'Pathway',
            p.Name as 'Program',
            wi.Client_Name_No_Hyperlink__c as 'Client',
            wi.Work_Item_Stage__c as 'WI Type'
from salesforce.work_item__c wi
left join salesforce.arg_work_item__c argwi on argwi.RWork_Item__c = wi.Id and argwi.IsDeleted = 0
left join salesforce.resource__c auditor on wi.Work_Item_Owner__c = auditor.Id
inner join salesforce.work_package__c wp on wi.Work_Package__c = wp.Id
inner join salesforce.certification__c sc on wp.Site_Certification__c = sc.Id
inner join salesforce.account s on sc.Primary_client__c = s.Id
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
inner join salesforce.program__c p on sp.Program__c = p.Id
left join salesforce.site_certification_standard_family__c scspf on scspf.Site_Certification_Standard__c = scsp.Id
left join salesforce.standard_program__c spf on scspf.Standard_Program__c = spf.Id
where 
wi.Status__c in ('Submitted')
and wi.IsDeleted = 0
and argwi.Id is null
#and wi.Work_Item_Stage__c not in ('Initial Project', 'Product Update', 'Standard Change')
group by wi.Id)
union
# PRC SLA - Backlog
(select 
concat('ARG Revision - ', if(ABS(TIME_TO_SEC(TIMEDIFF(t.`Submission Date`,t.First_Submitted__c)))<60 or t.`Submission Date` is null, 'First', 'Resubmission')) as 'Metric',
if(ABS(TIME_TO_SEC(TIMEDIFF(t.`Submission Date`,t.First_Submitted__c)))<60 or t.`Submission Date` is null, analytics.getTarget('arg_revision_first',null,null), analytics.getTarget('arg_revision_resubmission',null,null)) as 'SLA Target (Business Days)',
'ARG' as 'Type',
t.RAudit_Report_Group__c as 'Id',
t.`Name` as 'Name',
t.Revenue_Ownership__c as 'Region',
t.`Owner` as 'Owner',
t.Time_Zone__c as 'TimeZone',
if (ABS(TIME_TO_SEC(TIMEDIFF(t.`Submission Date`,t.First_Submitted__c)))<60 or t.`Submission Date` is null,
	t.First_Submitted__c,
	t.`Submission Date`) as 'From', 
null as 'To',
if (ABS(TIME_TO_SEC(TIMEDIFF(t.`Submission Date`,t.First_Submitted__c)))<60 or t.`Submission Date` is null,
	analytics.getSLADueUTCTimestamp(t.First_Submitted__c, t.Time_Zone__c, analytics.getTarget('arg_revision_first',null,null)),
	analytics.getSLADueUTCTimestamp(t.`Submission Date`, t.Time_Zone__c, analytics.getTarget('arg_revision_resubmission',null,null))) as 'SLA Due',
group_concat(distinct t.`Standards` order by t.`Standards`) as 'Standards',
group_concat(distinct t.`Standard Families`) as 'Standard Families',
group_concat(distinct t.`Tags`) as 'Tags',
t.`Business Line`, t.`Pathway`, t.`Program`, t.`Client`, t.`WI Type`
from (
select argwi.RAudit_Report_Group__c, arg.First_Submitted__c, arg.Name, arg.Audit_Report_Status__c, ca.Name as 'Owner', sc.Revenue_Ownership__c, wi.Work_Item_Date__c, wi.Status__c as 'Work_Item_Status', s.Time_Zone__c, 
(select max(ah.CreatedDate) as 'Submission Date'
		from salesforce.approval_history__c ah
		where ah.RAudit_Report_Group__c = arg.Id
		and ah.Status__c = 'Submitted') as 'Submission Date',
group_concat(distinct scsp.Standard_Service_Type_Name__c order by scsp.Standard_Service_Type_Name__c) as 'Standards',
group_concat(distinct if(scspf.IsDeleted or spf.isDeleted, null,spf.Standard_Service_Type_Name__c) separator ',') as 'Standard Families',
 getARGProcessTags(
			group_concat(distinct wi.Client_Ownership__c),
            group_concat(distinct p.Business_Line__c),
            group_concat(distinct p.Name),
			group_concat(DISTINCT wi.Primary_Standard__c), 
            group_concat(distinct if(scspf.IsDeleted or spf.isDeleted, null,spf.Standard_Service_Type_Name__c) separator ','),
            ca.Reporting_Business_Units__c,
            group_concat(distinct wi.Work_Item_Stage__c)) as 'Tags',
            p.Business_Line__c as 'Business Line',
            p.Pathway__c as 'Pathway',
            p.Name as 'Program',
            wi.Client_Name_No_Hyperlink__c as 'Client',
            wi.Work_Item_Stage__c as 'WI Type'
from salesforce.audit_report_group__c arg
left join salesforce.resource__c ca on arg.Assigned_CA__c = ca.Id
inner join salesforce.arg_work_item__c argwi on argwi.RAudit_Report_Group__c = arg.Id and argwi.IsDeleted = 0
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
arg.Audit_Report_Status__c in ('Under Review')
and arg.IsDeleted = 0
#and (arg.Work_Item_Stages__c not like '%Initial Project%' and arg.Work_Item_Stages__c not like '%Product Update%' and arg.Work_Item_Stages__c not like '%Standard Change%')
group by arg.Id, wi.Id
order by arg.Id, wi.Work_Item_Date__c desc) t
group by t.RAudit_Report_Group__c)
union
# Admin SLA - Backlog
(select 
'ARG Completion/Hold' as 'Metric',
analytics.getTarget('arg_completion',null,null) as 'SLA Target (Business Days)',
'ARG' as 'Type',
t.RAudit_Report_Group__c as 'Id',
t.`Name` as 'Name',
t.Revenue_Ownership__c as 'Region',
t.`Owner` as 'Owner',
t.Time_Zone__c as 'TimeZone', 
t.CA_Approved__c as 'From',
null as 'To',
analytics.getSLADueUTCTimestamp(t.CA_Approved__c, t.Time_Zone__c, analytics.getTarget('arg_completion',null,null)) as 'SLA Due',
group_concat(distinct t.`Standards` order by t.`Standards`) as 'Standards',
group_concat(distinct t.`Standard Families`) as 'Standard Families',
group_concat(distinct t.`Tags`) as 'Tags',
t.`Business Line`, t.`Pathway`, t.`Program`, t.`Client`, t.`WI Type`
from (
select argwi.RAudit_Report_Group__c, arg.First_Submitted__c, arg.Name, arg.Audit_Report_Status__c, admin.Name as 'Owner', sc.Revenue_Ownership__c, wi.Work_Item_Date__c, wi.Status__c as 'Work_Item_Status', s.Time_Zone__c, 
arg.CA_Approved__c,
group_concat(distinct scsp.Standard_Service_Type_Name__c order by scsp.Standard_Service_Type_Name__c) as 'Standards',
group_concat(distinct if(scspf.IsDeleted or spf.isDeleted, null,spf.Standard_Service_Type_Name__c) separator ',') as 'Standard Families',
 getARGProcessTags(
			group_concat(distinct wi.Client_Ownership__c),
            group_concat(distinct p.Business_Line__c),
            group_concat(distinct p.Name),
			group_concat(DISTINCT wi.Primary_Standard__c), 
            group_concat(distinct if(scspf.IsDeleted or spf.isDeleted, null,spf.Standard_Service_Type_Name__c) separator ','),
            admin.Reporting_Business_Units__c,
            group_concat(distinct wi.Work_Item_Stage__c)) as 'Tags',
            p.Business_Line__c as 'Business Line',
            p.Pathway__c as 'Pathway',
            p.Name as 'Program',
            wi.Client_Name_No_Hyperlink__c as 'Client',
            wi.Work_Item_Stage__c as 'WI Type'
from salesforce.audit_report_group__c arg
left join salesforce.resource__c admin on arg.Assigned_Admin__c = admin.Id
inner join salesforce.arg_work_item__c argwi on argwi.RAudit_Report_Group__c = arg.Id and argwi.IsDeleted = 0
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
arg.Audit_Report_Status__c in ('Support')
and arg.IsDeleted = 0
#and (arg.Work_Item_Stages__c not like '%Initial Project%' and arg.Work_Item_Stages__c not like '%Product Update%' and arg.Work_Item_Stages__c not like '%Standard Change%')
group by arg.Id, wi.Id
order by arg.Id, wi.Work_Item_Date__c desc) t
group by t.RAudit_Report_Group__c)
union
(select 
'ARG Hold' as 'Metric',
analytics.getTarget('arg_completion',null,null) as 'SLA Target (Business Days)',
'ARG' as 'Type',
t.RAudit_Report_Group__c as 'Id',
t.`Name` as 'Name',
t.Revenue_Ownership__c as 'Region',
t.`Owner` as 'Owner',
t.Time_Zone__c as 'TimeZone', 
t.`Hold Date` as 'From',
null as 'To',
analytics.getSLADueUTCTimestamp(t.CA_Approved__c, t.Time_Zone__c, analytics.getTarget('arg_completion',null,null)) as 'SLA Due',
group_concat(distinct t.`Standards` order by t.`Standards`) as 'Standards',
group_concat(distinct t.`Standard Families`) as 'Standard Families',
group_concat(distinct t.`Tags`) as 'Tags',
t.`Business Line`, t.`Pathway`, t.`Program`, t.`Client`, t.`WI Type`
from (
select argwi.RAudit_Report_Group__c, arg.First_Submitted__c, arg.Name, arg.Audit_Report_Status__c, admin.Name as 'Owner', sc.Revenue_Ownership__c, wi.Work_Item_Date__c, wi.Status__c as 'Work_Item_Status', s.Time_Zone__c, 
arg.CA_Approved__c,
(select max(ah.CreatedDate) as 'Hold Date'
		from salesforce.approval_history__c ah
		where ah.RAudit_Report_Group__c = arg.Id
		and ah.Status__c = 'Hold') as 'Hold Date',
group_concat(distinct scsp.Standard_Service_Type_Name__c order by scsp.Standard_Service_Type_Name__c) as 'Standards',
group_concat(distinct if(scspf.IsDeleted or spf.isDeleted, null,spf.Standard_Service_Type_Name__c) separator ',') as 'Standard Families',
 getARGProcessTags(
			group_concat(distinct wi.Client_Ownership__c),
            group_concat(distinct p.Business_Line__c),
            group_concat(distinct p.Name),
			group_concat(DISTINCT wi.Primary_Standard__c), 
            group_concat(distinct if(scspf.IsDeleted or spf.isDeleted, null,spf.Standard_Service_Type_Name__c) separator ','),
            admin.Reporting_Business_Units__c,
            group_concat(distinct wi.Work_Item_Stage__c)) as 'Tags',
            p.Business_Line__c as 'Business Line',
            p.Pathway__c as 'Pathway',
            p.Name as 'Program',
            wi.Client_Name_No_Hyperlink__c as 'Client',
            wi.Work_Item_Stage__c as 'WI Type'
from salesforce.audit_report_group__c arg
left join salesforce.resource__c admin on arg.Assigned_Admin__c = admin.Id
inner join salesforce.arg_work_item__c argwi on argwi.RAudit_Report_Group__c = arg.Id and argwi.IsDeleted = 0
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
arg.Audit_Report_Status__c in ('Hold')
and arg.IsDeleted = 0
#and (arg.Work_Item_Stages__c not like '%Initial Project%' and arg.Work_Item_Stages__c not like '%Product Update%' and arg.Work_Item_Stages__c not like '%Standard Change%')
group by arg.Id, wi.Id
order by arg.Id, wi.Work_Item_Date__c desc) t
group by t.RAudit_Report_Group__c);


truncate analytics.sla_arg_v2;
insert into analytics.sla_arg_v2 
	select * from analytics.sla_arg_backlog 
		union all 
    select * from analytics.sla_arg_perf;

insert into analytics.sp_log VALUES(null,'SlaUpdateArgV2',utc_timestamp(), timestampdiff(MICROSECOND, start_time, utc_timestamp()));

 END //
DELIMITER ;

select count(*) from analytics.sla_arg_v2;
truncate analytics.sla_arg_v2;
call SlaUpdateArgV2();

drop event SlaUpdateEventArgV2;
CREATE EVENT SlaUpdateEventArgV2
    ON SCHEDULE EVERY 10 minute DO 
		call SlaUpdateArgV2();
use analytics;
select *, exec_microseconds/1000000 from analytics.sp_log where sp_name='SlaUpdateArgV2' order by exec_time desc limit 10;

select count(*) from analytics.sla_arg_v2 ;

select distinct Metric from analytics.sla_arg_v2;