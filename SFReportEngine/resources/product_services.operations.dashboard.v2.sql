
create or replace view ps_ops_metrics_sub11 as 
(SELECT r.Id, r.Name, r.Resource_Target_Days__c, r.Resource_Capacitiy__c, r.Resource_Type__c, r.Work_Type__c, r.Reporting_Business_Units__c, m.Name as 'Manager', rt.Name AS 'Type', IF(wir.Work_Item_Type__c IS NULL, bop.Resource_Blackout_Type__c, wir.Work_Item_Type__c) AS 'SubType', e.DurationInMinutes AS 'DurationMin', e.DurationInMinutes / 60 / 8 AS 'DurationDays', e.ActivityDate 
	FROM salesforce.resource__c r     
	INNER JOIN salesforce.user u ON u.Id = r.User__c     
	inner join salesforce.user m on u.ManagerId = m.Id     
	INNER JOIN salesforce.event e ON u.Id = e.OwnerId     
	INNER JOIN salesforce.recordtype rt ON e.RecordTypeId = rt.Id     
	LEFT JOIN salesforce.work_item_resource__c wir ON wir.Id = e.WhatId     
	LEFT JOIN salesforce.blackout_period__c bop ON bop.Id = e.WhatId     
	WHERE         
	((DATE_FORMAT(e.ActivityDate, '%Y %m') >= '2015 07' and DATE_FORMAT(e.ActivityDate, '%Y %m') <= '2016 06')  OR e.Id IS NULL)             
	AND Resource_Type__c NOT IN ('Client Services')             
	AND r.Reporting_Business_Units__c LIKE '%Product%'
    AND r.Reporting_Business_Units__c NOT IN ('AUS-CSC' , 'AUS-MGT', 'AUS-OPS')
	AND r.Active_User__c = 'Yes'             
	AND r.Resource_Type__c = 'Employee'             
	AND r.Resource_Capacitiy__c IS NOT NULL             
	AND r.Resource_Capacitiy__c >= 30             
	AND (e.IsDeleted = 0 OR e.Id IS NULL));
                
create or replace view ps_ops_metrics_sub1 as 
(SELECT                       
t.Id, t.Name, t.Resource_Capacitiy__c as 'Resource Capacitiy (%)', t.Reporting_Business_Units__c as 'Business Unit', t.Manager, DATE_FORMAT(t.ActivityDate, '%Y %m') AS 'Period', SUM(IF(t.SubType = 'Audit', t.DurationDays, 0)) AS 'Audit Days', SUM(IF(t.SubType = 'Travel', t.DurationDays, 0)) AS 'Travel Days', SUM(IF(t.SubType = 'Public Holiday', t.DurationDays, 0)) AS 'Holiday Days', SUM(IF(t.SubType LIKE 'Leave%', t.DurationDays, 0)) AS 'Leave Days', SUM(IF(t.SubType not like 'Leave%' and t.Subtype not in ('Audit','Travel','Public Holiday'), t.DurationDays,0)) as 'Other BOPs',GROUP_CONCAT(DISTINCT IF(t.SubType not like 'Leave%' and t.Subtype not in ('Audit','Travel','Public Holiday'), t.Subtype ,null)) as 'Other BOP Types'     
FROM apac_ops_metrics_sub11 t     
GROUP BY `Period` , t.Id);

create or replace view ps_ops_metric_arg_end_to_end_1 as 
(select 
	arg.Id,
	if(arg.`Metric` in ('ARG Submission - First','ARG Submission - Resubmission'), 'Delivery (Days)', 
		if(arg.`Metric` in ('ARG Revision - First', 'ARG Revision - Resubmission'),'Technical (Days)',
			if(arg.`Metric` in ('ARG Completion/Hold'), 'Admin (Days)', 'Hold (Days)'))) as '_Metric', 
p.business_line__c as 'Business Line',
arg_orig.Client_Ownership__c as 'Country',
p.Name as 'Program',
arg.`Standards` as `Standards`,
date_format((select max(`To`) from analytics.sla_arg_v2 where Id=arg_orig.Id), '%Y %m')  as 'Period',
if((select count(`Id`) from analytics.sla_arg_v2 where Id=arg_orig.Id)=2,TRUE,FALSE)  as 'Auto-Approved',
if((select count(t3.`Id`) from analytics.sla_arg_v2 t3 where t3.Id=arg_orig.Id and t3.`Metric`='ARG Hold')=1,TRUE,FALSE)  as 'With Hold',
count(distinct arg.Id) as 'Volume',
sum(timestampdiff(second, arg.`From`, arg.`To`)/3600/24) as 'Sum Value',
group_concat(distinct arg_orig.Name) as 'Items'
from salesforce.audit_report_group__c arg_orig 
left join analytics.sla_arg_v2 arg on arg_orig.Id = arg.Id
left join salesforce.standard__c s on s.Name = substring_index(arg.`Standards`, ',',1) and s.Parent_Standard__c is not null
left join salesforce.program__c p on s.Program__c = p.Id
where
arg_orig.Audit_Report_Status__c = 'Completed'
and arg.`Metric` in ('ARG Submission - First','ARG Submission - Resubmission', 'ARG Revision - First', 'ARG Revision - Resubmission','ARG Completion/Hold', 'ARG Hold')
and p.Business_Line__c like '%Product%'
group by arg_orig.Id, `_Metric`);

create or replace view ps_ops_metric_arg_end_to_end_2 as
(select 
	arg_completed.Id as 'Id',
	p.business_line__c as 'Business Line',
	arg_completed.Client_Ownership__c as 'Country',
	null as 'Owner',
	p.Name as 'Program',
	arg.`Standards` as `Standards`,
	date_format(max(arg.`To`), '%Y %m')  as 'Period',
	count(distinct arg.Id) as 'Volume',
    if(group_concat(arg.`Metric`) like '%ARG Hold%', TRUE, FALSE) as 'With Hold',
	sum(timestampdiff(second, arg.`From`, arg.`To`)/3600/24) as 'Sum Value',
	if(count(arg.Id)=1,1, 0) as 'Auto-Approved',
    group_concat(distinct arg_completed.Name) as 'Items'
from salesforce.audit_report_group__c arg_completed
left join analytics.sla_arg_v2 arg on arg_completed.Id = arg.Id
left join salesforce.standard__c s on s.Name = substring_index(arg.`Standards`, ',',1) and s.Parent_Standard__c is not null
left join salesforce.program__c p on s.Program__c = p.Id
where
arg_completed.IsDeleted = 0
and arg_completed.Audit_Report_Status__c in ('Completed') 
and arg.`Metric` in ('ARG Submission - First','ARG Submission - Resubmission', 'ARG Revision - First', 'ARG Revision - Resubmission','ARG Completion/Hold', 'ARG Hold')
and p.Business_Line__c like '%Product%'
group by arg_completed.Id);

create or replace view ps_ops_metrics_rejections_sub as
(select
	'Performance' as '_Type', 
	'ARG rejection rate' as '_Metric',
	sp.Program_Business_Line__c as 'Business Line',
    if (r.Reporting_Business_Units__c like 'AUS%' or r.Reporting_Business_Units__c like 'Asia%' or r.Reporting_Business_Units__c like 'ASS%' or r.Reporting_Business_Units__c like 'MS%' or r.Reporting_Business_Units__c like 'AMERICA%', 'APAC', 'EMEA') as 'Region',
    r.Reporting_Business_Units__c,
	if(r.Reporting_Business_Units__c like 'AUS%' or r.Reporting_Business_Units__c like 'ASS%' or r.Reporting_Business_Units__c like 'MS%' or r.Reporting_Business_Units__c like 'AMERICA%', 'Australia', substring_index(r.Reporting_Business_Units__c,'-',-1)) as 'Country',
	r.Name as 'Owner',
	p.Name as 'Program',
	sp.Standard_Service_Type_Name__c as 'Standards',
	date_format(arg.CA_Approved__c, '%Y %m')  as 'Period',
	count(distinct arg.Id) as 'Volume',
	count(distinct if(ah.Status__c='Rejected', ah.Id, null)) as 'Sum Value', #distinct ah.Id means I am counting each rejection
	if(sp.Standard_Service_Type_Name__c like '%16949%',0.1,if(sp.Program_Business_Line__c like '%Food%', 0.1,0.08))as 'Target',
	ifnull(group_concat(distinct if(ah.Status__c='Rejected', arg.Name, null)) ,'') as 'Items'
from salesforce.approval_history__c ah 
inner join salesforce.audit_report_group__c arg on arg.Id = ah.RAudit_Report_Group__c
inner join salesforce.resource__c r on arg.RAudit_Report_Author__c = r.Id
inner join salesforce.arg_work_item__c argwi on argwi.RAudit_Report_Group__c = arg.Id
inner join salesforce.work_item__c wi on argwi.RWork_Item__c = wi.Id
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
inner join salesforce.program__c p on sp.Program__c = p.Id
where 
arg.IsDeleted = 0
and ah.IsDeleted = 0
and date_format(arg.CA_Approved__c, '%Y-%m') >= '2015-07'
and (r.Reporting_Business_Units__c like '%Product%'
	or sp.Program_Business_Line__c like '%Product%')
group by arg.Id);

create or replace view ps_ops_metrics as
#ARG rejection rate
(select
	t.`_Type`, 
	t.`_Metric`,
	t.`Business Line`,
	t.`Country`,
	t.`Owner`,
	t.`Program`,
	t.`Standards`,
	t.`Period`,
	sum(t.`Volume`) as 'Volume',
	sum(t.`Sum Value`) as 'Sum Value', #distinct ah.Id means I am counting each rejection
	(sum(t.`Volume`) - sum(t.`Sum Value`)) as 'Volume within SLA',
	t.`Target`,
	ifnull(group_concat(t.`Items`),'') as 'Items',
	null as 'Auto-Approved',
	null as 'With-Hold'
from ps_ops_metrics_rejections_sub t
group by `_Type`, `_Metric`, `Country`, `Owner`, `Standards`, `Period`)

union
# ARG Performance and Backlog
(select 
if(arg.`To` is null, 'Backlog', 'Performance') as '_Type',
if(arg.`Metric` in ('ARG Process Time (BRC)', 'ARG Process Time (Other)'), 'ARG Cycle (Days)',
	if(arg.`Metric` in ('ARG Completion/Hold'), 'Admin Completion (Days)',
		if(arg.`Metric` in ('ARG Revision - Resubmission'), 'Technical Review - Resubmission (Days)',
			if(arg.`Metric` in ('ARG Revision - First'), 'Technical Review - First (Days)',
				if(arg.`Metric` in ('ARG Submission - Resubmission'), 'Auditor Re-Submission (Days)',
					if(arg.`Metric` in ('ARG Submission - First'), 'Auditor First Submission (Days)',
						arg.`Metric`
					)
				)
            )
        )
    )
) as '_Metric',
p.business_line__c as 'Business Line',
if(r.Reporting_Business_Units__c like 'AUS%', 'Australia', substring_index(r.Reporting_Business_Units__c,'-',-1)) as 'Country',
arg.`Owner` as '_Owner',
p.Name as 'Program',
arg.`Standards` as `Standards`,
date_format(arg.`To`, '%Y %m')  as 'Period',
count(arg.Id) as 'Volume',
sum(analytics.getBusinessDays(arg.`From`, ifnull(arg.`To`, utc_timestamp()), arg.`TimeZone`)) as 'Sum Value',
sum(if(analytics.getBusinessDays(arg.`From`, ifnull(arg.`To`, utc_timestamp()), arg.`TimeZone`)<=getTargetARGApac(arg.`Metric`),1,0)) as 'Volume within SLA',
getTargetARGApac(arg.`Metric`) as 'Target',
group_concat(distinct arg.Name) as 'Items',
null as 'Auto-Approved',
null as 'With-Hold'
from analytics.sla_arg_v2 arg 
left join salesforce.Resource__c r on arg.`Owner` = r.Name
left join salesforce.standard__c s on s.Name = substring_index(arg.`Standards`, ',',1) and s.Parent_Standard__c is not null
left join salesforce.program__c p on s.Program__c = p.Id
where
(date_format(arg.`To`, '%Y-%m') >= '2015-07' or arg.`To` is null)
and (r.Reporting_Business_Units__c like '%Product%'
	or p.business_line__c like '%Product%')
and if(arg.Tags like '%Product Update' or arg.Tags like '%Initial Project' and arg.`Metric` in ('ARG Submission - First'),0,1)
and arg.`Metric` not in ('ARG Process Time (BRC)', 'ARG Process Time (Other)')
group by `_Type`, `_Metric`, `Country`, `_Owner`, `Standards`, `Target`, `Period`)
union

# ARG end-to-end process
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
from ps_ops_metric_arg_end_to_end_1 t
where t.`Period` >= '2015 07'
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
from ps_ops_metric_arg_end_to_end_2 t
where t.`Period` >= '2015 07'
group by `_Type`, `_Metric`, `_Country`, `_Owner`, `Standards`, `Target`, `Period`, `Auto-Approved`, `With Hold`)

union
#Auditor utilisation
(SELECT 
'Performance' as '_Type',
'Resource Utilisation' as '_Metric',
'n/a' as 'Business Line',
if(i.`Business Unit` like 'AUS%', 'Australia', substring_index(i.`Business Unit`,'-',-1)) as 'Country',
i.`Name` as 'Owner',
null as 'Program',
null as 'Standards',
i.`Period` as 'Period',
(j.`Working Days`-(i.`Holiday Days`+i.`Leave Days`))*i.`Resource Capacitiy (%)`/100 as 'Volume',
i.`Audit Days`+i.`Travel Days` as 'Sum Value',
if((i.`Audit Days`+i.`Travel Days`)/((j.`Working Days`-(i.`Holiday Days`+i.`Leave Days`))*i.`Resource Capacitiy (%)`/100)>=0.8,1,0) as 'Volume within SLA',
0.8 as 'Target',
null as 'Items'    ,
null as 'Auto-Approved',
null as 'With-Hold'
FROM analytics.ps_ops_metrics_sub1 i     
INNER JOIN analytics.apac_ops_metrics_sub2 j ON i.Period = j.Period
WHERE j.`Working Days`> (i.`Holiday Days`+i.`Leave Days`)
group by Id, i.Period)

union
# Contractors vs FTEs 
(select 
'Performance' as '_Type', 
'Contractor Usage' as '_Metric',
sp.Program_Business_Line__c as 'Business Line',
if(wi.Revenue_Ownership__c like 'AUS%', 'Australia', substring_index(substring_index(wi.Revenue_Ownership__c,'-',2),'-',-1)) as 'Country',
null as '_Owner',
p.Name as 'Program',
sp.Standard_Service_Type_Name__c as 'Standards',
date_format(wi.work_item_Date__c, '%Y %m') as 'Period',
sum(wi.Required_Duration__c/8) as 'Volume',
sum(if(r.Resource_Type__c='Contractor', wi.Required_Duration__c/8, 0)) as 'Sum Value',
null as 'Volume within SLA',
0.2 as 'Target',
ifnull(group_concat(distinct if(r.Resource_Type__c='Contractor', wi.Name, null)) ,'') as 'Items',
null as 'Auto-Approved',
null as 'With-Hold'
from salesforce.work_item__c wi
inner join salesforce.resource__c r on wi.RAudit_Report_Author__c = r.Id
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
inner join salesforce.program__c p on sp.Program__c = p.Id
where
wi.IsDeleted = 0
and wi.Status__c not in ('Cancelled', 'Draft', 'Initiate Service', 'Budget')
and (wi.Revenue_Ownership__c like '%Product%'
 or sp.Program_Business_Line__c not like '%Product%')
and wi.Work_Item_Date__c >= '2015-07-01'
and wi.Work_Item_Date__c < '2016-07-01'
group by `_Type`, `_Metric`, `Country`, `_Owner`, `Standards`, `Target`, `Period`)
union
(select 
	'Backlog' as '_Type', 
	'Change Request' as '_Metric',
	p.Business_Line__c as 'Business Line',
	if(crb.Region like 'AUS%','Australia', substring_index(crb.Region ,'-',-1)) as 'Country',
    null as '_Owner',
	p.Name as 'Program',
	s.Name as 'Standards',
	null as 'Period',
	count(distinct crb.Id) as 'Volume',
	sum(getBusinessDays(crb.`From`, utc_timestamp(), 'UTC')) as 'Sum Value', # Total Aging
	count(distinct if(getBusinessDays(crb.`From`, utc_timestamp(), 'UTC')<=getTargetARGApac('Change Request'),crb.Id,null)) as 'Volume within SLA',
	getTargetARGApac('Change Request') as 'Target',
	ifnull(group_concat(distinct crb.Name) ,'') as 'Items',
	null as 'Auto-Approved',
	null as 'With-Hold'
from analytics.change_request_backlog_sub crb
inner join salesforce.change_request2__c cr on crb.Id = cr.Id
inner join salesforce.work_item__c wi on cr.Work_Item__c = wi.Id
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
inner join salesforce.standard__c s on sp.Standard__c = s.Id
inner join salesforce.program__c p on sp.Program__c = p.Id
where 
(crb.Region like '%Product%' or p.Business_Line__c like '%Product%')

group by `_Type`, `_Metric`, `Country`, `_Owner`, `Standards`, `Target`, `Period`)
union
(select 
	'Performance' as '_Type', 
	'Change Request' as '_Metric',
	p.Business_Line__c as 'Business Line',
	if(crc.Region like 'AUS%','Australia', substring_index(crc.Region ,'-',-1)) as 'Country',
    crc.Owner as '_Owner',
	p.Name as 'Program',
	s.Name as 'Standards',
	date_format(crc.`To`, '%Y %m') as 'Period',
	count(distinct crc.Id) as 'Volume',
	sum(getBusinessDays(crc.`From`, crc.`To`, 'UTC')) as 'Sum Value', # Total Processing Business Days
	count(distinct if(getBusinessDays(crc.`From`, crc.`To`, 'UTC')<=getTargetARGApac('Change Request'),crc.Id,null)) as 'Volume within SLA',
	getTargetARGApac('Change Request') as 'Target',
	ifnull(group_concat(distinct crc.Name) ,'') as 'Items',
	null as 'Auto-Approved',
	null as 'With-Hold' 
from analytics.change_request_completed_sub crc
inner join salesforce.change_request2__c cr on crc.Id = cr.Id
inner join salesforce.work_item__c wi on cr.Work_Item__c = wi.Id
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
inner join salesforce.standard__c s on sp.Standard__c = s.Id
inner join salesforce.program__c p on sp.Program__c = p.Id
where crc.`To` >= '2015-07-01'
and (crc.Region like '%Product%' or p.Business_Line__c like '%Product%')
group by `_Type`, `_Metric`, `Country`, `_Owner`, `Standards`, `Target`, `Period`);

(select * from ps_ops_metrics);

#Witness audits overdue
#% auditor handbacks
#ARG signed off vs SLA

select * from analytics.sla_scheduling_completed where Id in ('a3Id0000000Ibc4EAC','a3Id0000000IwlZEAS');

# Scheduling Performance
select 
'Performance' as 'Type',
concat(`Activity`, ' (Calendar Days)') as 'Metric',
sp.Program_Business_Line__c as 'Stream',
substring_index(sched.`Region`,' - ',-1) as 'Country',
sched.`Owner` as 'Owner',
sched.`Tags` as `Standards`,
date_format(sched.`To`, '%Y %m') as 'Period',
count(distinct sched.`Id`) as 'Volume',
avg(timestampdiff(day, sched.`From`, sched.`To`))  as 'Avg Value',
sum(timestampdiff(day, sched.`From`, sched.`To`))as 'Sum Value',
if(sched.`Activity` in ('Scheduled', 'Scheduled Offered'), 365/4, 28) as 'Target',
sum(if(sched.`SLA Due` < sched.`To`,0,1)) as 'Count Within SLA',
group_concat(sched.Id) as 'Items'
from analytics.sla_scheduling_completed sched
inner join salesforce.work_item__c wi on sched.`Id` = wi.Id
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
where date_format(sched.`To`,'%Y-%m') > date_format(date_add(utc_timestamp(), interval -1 month), '%Y-%m') 
and sched.`Region` like 'EMEA%'
and sched.`Activity` in ('Scheduled','Scheduled Offered','Confirmed')
group by `Metric`, `Country`, `Owner`, `Standards`, `Target`, `Period`;