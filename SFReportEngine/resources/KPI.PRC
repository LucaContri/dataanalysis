# PRC KPI
# 1) Review Pack turn-around
select
t.*,
date_format(`t`.`First Submitted`, '%Y %m') as 'First Submitted Period',
#5 * (DATEDIFF(`t`.`First Submitted`, `t`.`First Taken`) DIV 7) + MID('0123444401233334012222340111123400001234000123440', 7 * WEEKDAY(`t`.`First Submitted`) + WEEKDAY(`t`.`First Taken`) + 1, 1) as 'Submitted to Taken Turnaround (wd)',
datediff(`t`.`First Taken`, `t`.`First Submitted`) as 'Submitted to Taken Turnaround',
#5 * (DATEDIFF(`t`.`First Taken`, `t`.`First Rejected or Approved`) DIV 7) + MID('0123444401233334012222340111123400001234000123440', 7 * WEEKDAY(`t`.`First Taken`) + WEEKDAY(`t`.`First Rejected or Approved`) + 1, 1) as 'Taken to Reviewed Turnaround (wd)',
datediff(`t`.`First Rejected or Approved`, `t`.`First Taken`) as 'Taken to Reviewed Turnaround'
from (
select 
#arg.Name, 
ah.RAudit_Report_Group__c as 'ARG Id',
ah.Approver_Name__c,
ah.Assigned_To__c,
u.Name,
m.Name as 'Modified By',
min(if(ah.Status__c='Submitted', Timestamp__c, null)) as 'First Submitted',
min(if(ah.Status__c='Taken', Timestamp__c, null)) as 'First Taken',
min(if(ah.Assigned_To__c='Client Administration' and ah.Status__c='Approved', Timestamp__c, null)) as 'First Approved for Client Admin',
min(if(ah.Status__c='Rejected', Timestamp__c, null)) as 'First Rejected',
min(if(ah.Status__c='Rejected' or (ah.Assigned_To__c='Client Administration' and ah.Status__c='Approved'), Timestamp__c, null)) as 'First Rejected or Approved'
from approval_history__c ah
inner join audit_report_group__c arg on arg.Id = ah.RAudit_Report_Group__c
inner join User u on ah.CreatedById = u.Id
inner join User m on ah.LastModifiedById = m.Id
where ah.RAudit_Report_Group__c is not null
and arg.Client_Ownership__c in ('Australia')
#inner join audit_report_group__c arg on arg.Id = ah.RAudit_Report_Group__c
#inner join User o on o.Id = ah.OwnerId
#where ah.RAudit_Report_Group__c='a1Wd00000002ujLEAQ'
group by ah.RAudit_Report_Group__c) t limit 100000;

select ah.RAudit_Report_Group__c, sum(if (ah.Status__c='Approved',1,0)) 
from approval_history__c ah
where ah.Assigned_To__c='Client Administration'
group by ah.RAudit_Report_Group__c limit 100000;

# 2) Auditor Mentoring Program
# No of Rejected ARG completed by auditors trained by trainee.

#explain
select wi.Name, wi.Id, wir.Id, r.Id, r.Name, t.* from (
select 
ah.RAudit_Report_Group__c as 'arg_id',
ah.Assigned_To__c as 'assigned_to',
count(ah.Id) as 'count_rejected',
date_format(ah.timestamp__c, '%Y %m') as 'period_rejected'
from approval_history__c ah
where ah.Status__c='Rejected'
and ah.IsDeleted = 0
and date_format(ah.timestamp__c, '%Y %m') = '2014 05'
group by ah.RAudit_Report_Group__c, ah.Assigned_To__c) t
inner join arg_work_item__c argwi on argwi.RAudit_Report_Group__c = t.arg_id
inner join work_item__c wi on argwi.RWork_Item__c = wi.Id
inner join work_item_resource__c wir on wir.Work_Item__c = wi.Id
inner join resource__c r on r.Id = wir.Resource__c
group by t.arg_id, r.Name
limit 100000;

select t.* from (
select 
    ah.RAudit_Report_Group__c as 'ARG_Id',
	ah
    min(if(ah.Status__c = 'Submitted',
        Timestamp__c,
        null)) as 'First_Submitted',
    min(if(ah.Status__c = 'Taken',
        Timestamp__c,
        null)) as 'First_Taken',
    min(if(ah.Status__c = 'Rejected'
            or (ah.Assigned_To__c = 'Client Administration'
            and ah.Status__c = 'Approved'),
        Timestamp__c,
        null)) as 'First_Reviewed'
from approval_history__c ah
inner join audit_report_group__c arg on arg.Id = ah.RAudit_Report_Group__c
inner join User u on u.Id = ah.Assigned_To__c
where ah.RAudit_Report_Group__c is not null
and arg.Client_Ownership__c in ('Australia')
group by ah.RAudit_Report_Group__c ) t
where t.First_Taken >= '2014-06-01' or t.First_Reviewed >= '2014-06-01';