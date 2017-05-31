# Auditors Metrics

# Auditors List
select r.Id, r.Name , r.Reporting_Business_Units__c, r.Email__c, r.Manager_Email__c, m.Email as 'ManagerEmail'
from salesforce.resource__c r
inner join salesforce.user u on r.User__c = u.Id
inner join salesforce.user m on u.ManagerId = m.Id
where 
r.Reporting_Business_Units__c like 'AUS%'
and r.Reporting_Business_Units__c not like 'AUS-Product%' 
and r.Resource_Type__c not in ('Client Services')
and r.Reporting_Business_Units__c not in ('AUS-CSC','AUS-MGT', 'AUS-OPS')
and r.Resource_Target_Days__c > 50
and r.Active_User__c = 'Yes'
and r.Resource_Type__c = 'Employee';

# Auditors SLA
select t2.`Auditor`, date_format(t2.`To`, '%Y-%m') as 'Period', count(t2.Id) as 'ARG Approved', round(sum(t2.`Within SLA`)/count(t2.Id)*100,2) as '% within SLA', round(avg(t2.`Processing Time`)/60/60/24,2) as 'Avg Submission Days', sum(t2.`Rejections`) as 'Rejections' from (
select
'Delivery' as 'Team', 
'ARG Submission' as 'Activity', 
t.RevenueOwnerships as 'Details', 
'ARG' as 'Id Type',
t.Id as 'Id',
t.`Auditor`,
sum(if(ah.Status__c = 'Rejected',1,0)) as 'Rejections',
'Audit End' as 'Aging Type',
t.`Audit End` as 'From',
t.`Auditors Time` as 'Processing Time',
date_add(t.`Audit End`, interval 5 day) as 'SLA Due',
date_format(date_add(t.`Audit End`, interval t.`Auditors Time` second ), '%Y-%m-%d') as 'To',
if(date_format(date_add(t.`Audit End`, interval t.`Auditors Time` second ), '%Y-%m-%d') > date_add(t.`Audit End`, interval 5 day), false, true) as 'Within SLA',
concat(t.`PrimaryStandards`, ';', if(t.`Standard Families` is null, '',t.`Standard Families`) ) as 'Tags'
from analytics.sla_arg t
inner join salesforce.approval_history__c ah on ah.RAudit_Report_Group__c = t.Id
where t.`Status` in ('Completed', 'Hold', 'Support')
and t.`First Submitted` >= '2015-01-01' 
and t.`First Submitted` <= '2015-05-31' 
and t.RevenueOwnerships like 'AUS%'
and t.Auditor in ('Rhonda Stevens', 'Tom Juergens')
group by t.Id) t2
group by t2.`Auditor`, `Period`;

use analytics;
DROP PROCEDURE GetAuditorMetricsForPeriod;

DELIMITER //
CREATE PROCEDURE GetAuditorMetricsForPeriod(in authorName varchar(255), in dateFrom datetime, in dateTo datetime)
 BEGIN
select t3.* from (
(select
t.`Auditor`,
'ARG Submitted & Approved' as 'Type',
t.`Name` as 'Name',
t.Id as 'Id',
t.`Status` as 'Status',
date_format(t.`Audit End`, '%Y-%m-%d') as 'Audit End Date',
round(t.`Auditors Time`/60/60/24,2) as 'Processing Days',
date_format(date_add(t.`Audit End`, interval t.`Auditors Time` second ), '%Y-%m-%d') as 'Audit End + Submission',
date_format(date_add(t.`Audit End`, interval t.`Auditors Time` second ), '%Y-%m') as 'Period',
sum(if(ah.Status__c = 'Rejected',1,0)) as 'Rejections',
if(date_format(date_add(t.`Audit End`, interval t.`Auditors Time` second ), '%Y-%m-%d') > date_add(t.`Audit End`, interval 5 day), false, true) as 'Within SLA'
#concat(t.`PrimaryStandards`, ';', if(t.`Standard Families` is null, '',t.`Standard Families`) ) as 'Tags'
from analytics.sla_arg t
inner join salesforce.approval_history__c ah on ah.RAudit_Report_Group__c = t.Id
where t.`Status` in ('Completed', 'Hold', 'Support')
and t.`First Submitted` >= dateFrom
and t.`First Submitted` <= dateTo
and t.Auditor = authorName
group by t.Id)
# ARGs
union
(select t.* from (
select author.Name as 'Author', 'ARG To Be Submitted' as 'Type', arg.Name as 'Name',  arg.Id as 'Id',arg.Audit_Report_Status__c as 'Status', 
date_format(arg.End_Date__c, '%Y-%m-%d') as 'Audit End Date',
0 as 'Processing Days',
date_format(arg.End_Date__c, '%Y-%m-%d') as 'Audit End + Processing',
date_format(arg.End_Date__c, '%Y-%m') as 'Period',
sum(if(ah.Status__c = 'Rejected',1,0)) as 'Rejections',
if(date_add(arg.End_Date__c, interval 5 day)<date_format(now(), '%Y-%m-%d'),0,1) as 'Within SLA'
from salesforce.audit_report_group__c arg
inner join salesforce.resource__c author on arg.RAudit_Report_Author__c = author.Id
inner join salesforce.`arg_work_item__c` argwi on argwi.RAudit_Report_Group__c = arg.Id 
inner join salesforce.`work_item__c` wi on wi.id = argwi.RWork_Item__c 
left join salesforce.approval_history__c ah on arg.Id = ah.RAudit_Report_Group__c
where arg.IsDeleted = 0
and arg.Audit_Report_Status__c in ('Pending', 'Under Review - Rejected')
group by arg.ID) t
where t.`Author` = authorName
and t.`Audit End Date`<date_format(now(), '%Y-%m-%d'))
union
#Work Items
(select r.Name as 'Author', 'Work Item To Be Submitted' as 'Type', wi.Name as 'Name', wi.Id as 'Id', wi.Status__c as 'Status', 
date_format(wi.End_Service_Date__c, '%Y-%m-%d') as 'Audit End Date',
0 as 'Processing Days',
date_format(wi.End_Service_Date__c, '%Y-%m-%d') as 'Audit End + Processing',
date_format(wi.End_Service_Date__c, '%Y-%m') as 'Period',
0 as 'Rejections',
if(date_add(wi.End_Service_Date__c, interval 5 day)<date_format(now(), '%Y-%m-%d'),0,1) as 'Within SLA'
from salesforce.work_item__c wi
inner join salesforce.resource__c r on r.Id = wi.Work_Item_Owner__c
where wi.IsDeleted = 0
and wi.Status__c in ('In Progress')
and wi.End_Service_Date__c < date_format(now(), '%Y-%m-%d')
and r.Name = authorName)
union
(select r.Name as 'Author', 'Work Item Submitted - No ARG' as 'Type', wi.Name as 'Name', wi.Id as 'Id', wi.Status__c as 'Status', 
date_format(wi.End_Service_Date__c, '%Y-%m-%d') as 'Audit End Date', 
0 as 'Processing Days',
date_format(wi.End_Service_Date__c, '%Y-%m-%d') as 'Audit End + Processing',
date_format(wi.End_Service_Date__c, '%Y-%m') as 'Period',
0 as 'Rejections',
if(date_add(wi.End_Service_Date__c, interval 5 day)<date_format(now(), '%Y-%m-%d'),0,1) as 'Within SLA'
from salesforce.work_item__c wi
inner join salesforce.resource__c r on r.Id = wi.Work_Item_Owner__c
left join salesforce.arg_work_item__c argwi on argwi.RWork_Item__c = wi.Id
where wi.IsDeleted = 0
and wi.Status__c in ('Submitted')
and wi.End_Service_Date__c < date_format(now(), '%Y-%m-%d')
and r.Name = authorName
and argwi.Id is null)) t3 
inner join salesforce.resource__c r on t3.Auditor = r.Name;
 END //
DELIMITER ;

call GetAuditorMetricsForPeriod('Tom Juergens', '2014-12-01', '2015-06-30');
call GetAuditorMetricsForPeriod('Boon Ong', '2014-12-01', '2015-06-30');
call GetAuditorMetricsForPeriod('Ana Lagrimas', '2015-01-01', '2015-05-31');

select t.* from (
select author.Name as 'Author', 'ARG To Be Submitted' as 'Type', arg.Name as 'Name',  arg.Id as 'Id',arg.Audit_Report_Status__c as 'Status', 
date_format(arg.End_Date__c, '%d/%m/%Y') as 'Audit End Date',
0 as 'Processing Days',
date_format(arg.End_Date__c, '%d/%m/%Y') as 'Audit End + Processing',
date_format(arg.End_Date__c, '%Y-%m') as 'Period',
sum(if(ah.Status__c = 'Rejected',1,0)) as 'Rejections',
if(date_add(arg.End_Date__c, interval 5 day)<date_format(now(), '%Y-%m-%d'),0,1) as 'Within SLA'
from salesforce.audit_report_group__c arg
inner join salesforce.resource__c author on arg.RAudit_Report_Author__c = author.Id
inner join salesforce.`arg_work_item__c` argwi on argwi.RAudit_Report_Group__c = arg.Id 
inner join salesforce.`work_item__c` wi on wi.id = argwi.RWork_Item__c 
left join salesforce.approval_history__c ah on arg.Id = ah.RAudit_Report_Group__c
where arg.IsDeleted = 0
and arg.Audit_Report_Status__c in ('Pending', 'Under Review - Rejected')
group by arg.ID) t
where t.`Author` = 'Tom Juergens'
and t.`Audit End Date`<date_format(now(), '%Y-%m-%d')