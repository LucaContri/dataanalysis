DELIMITER $$
CREATE FUNCTION `getTargetARGEmea`(Metric VARCHAR(64)) RETURNS int(11)
BEGIN
	DECLARE target INTEGER DEFAULT null;
    SET target = (SELECT 
		if(Metric in ('ARG Process Time (BRC)'), 30,
		if(Metric in ('ARG Process Time (Other)'), 15,
		if(Metric in ('ARG Completion/Hold'), 5,
		if(Metric in ('ARG Revision - Resubmission'), 2,
		if(Metric in ('ARG Revision - First'), 5,
		if(Metric in ('ARG Submission - Resubmission'), 2,
		if(Metric in ('ARG Submission - First'), 5,
		if(Metric in ('ARG Submission - Unsubmitted WI'), 5,
		if(Metric in ('ARG Submission - Submitted WI No ARG'), 5, null))))))))));
        
    RETURN target;
 END$$
DELIMITER ;

create or replace view emea_ops_metrics_sub2 as                 
(SELECT DATE_FORMAT(wd.date, '%Y %m') AS 'Period', COUNT(wd.date) AS 'Working Days' 
				FROM salesforce.`sf_working_days` wd 
                WHERE
					DATE_FORMAT(wd.date, '%Y %m') >= '2015 07' AND DATE_FORMAT(wd.date, '%Y %m') <= '2016 06'
				GROUP BY `Period`);

create or replace view emea_ops_metrics_sub11 as 
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
	AND r.Reporting_Business_Units__c LIKE 'EMEA%'
    AND r.Active_User__c = 'Yes'             
	AND r.Resource_Type__c = 'Employee'             
	AND r.Resource_Capacitiy__c IS NOT NULL             
	AND r.Resource_Capacitiy__c >= 30             
	AND (e.IsDeleted = 0 OR e.Id IS NULL));
                
create or replace view emea_ops_metrics_sub1 as 
(SELECT                       
t.Id, t.Name, t.Resource_Capacitiy__c as 'Resource Capacitiy (%)', t.Reporting_Business_Units__c as 'Business Unit', t.Manager, DATE_FORMAT(t.ActivityDate, '%Y %m') AS 'Period', SUM(IF(t.SubType = 'Audit', t.DurationDays, 0)) AS 'Audit Days', SUM(IF(t.SubType = 'Travel', t.DurationDays, 0)) AS 'Travel Days', SUM(IF(t.SubType = 'Public Holiday', t.DurationDays, 0)) AS 'Holiday Days', SUM(IF(t.SubType LIKE 'Leave%', t.DurationDays, 0)) AS 'Leave Days', SUM(IF(t.SubType not like 'Leave%' and t.Subtype not in ('Audit','Travel','Public Holiday'), t.DurationDays,0)) as 'Other BOPs',GROUP_CONCAT(DISTINCT IF(t.SubType not like 'Leave%' and t.Subtype not in ('Audit','Travel','Public Holiday'), t.Subtype ,null)) as 'Other BOP Types'     
FROM emea_ops_metrics_sub11 t     
GROUP BY `Period` , t.Id);

create or replace view emea_ops_metrics as
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
from global_ops_metrics_rejections_sub t
where t.`Region` = 'EMEA'
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
#if(arg.`Tags` like 'MS;%', 'Management Systems', if(arg.`Tags` like 'Food;%', 'Agri-Food', if(arg.`Tags` like 'PS;%', 'Product Services', '?'))) as 'Stream',
p.business_line__c as 'Business Line',
if(r.Reporting_Business_Units__c is null,
	if(arg.Region like '%Product%', 'Product Services', if(arg.Region like 'AUS%', 'Australia', substring_index(substring_index(arg.Region,'-',2),'-',-1))) ,
	if(r.Reporting_Business_Units__c like '%Product%', 'Product Services', if(r.Reporting_Business_Units__c like 'AUS%', 'Australia', substring_index(r.Reporting_Business_Units__c,'-',-1))) 
) as 'Country',
arg.`Owner` as '_Owner',
p.Name as 'Program',
arg.`Standards` as `Standards`,
date_format(arg.`To`, '%Y %m')  as 'Period',
count(arg.Id) as 'Volume',
sum(analytics.getBusinessDays(arg.`From`, ifnull(arg.`To`, utc_timestamp()), arg.`TimeZone`)) as 'Sum Value',
#sum(timestampdiff(second, arg.`From`, ifnull(arg.`To`, utc_timestamp())))/3600/24 as 'Sum Value',
sum(if(analytics.getBusinessDays(arg.`From`, ifnull(arg.`To`, utc_timestamp()), arg.`TimeZone`)<=getTargetARGApac(arg.`Metric`),1,0)) as 'Volume within SLA',
#sum(if(timestampdiff(second, arg.`From`, ifnull(arg.`To`, utc_timestamp()))/3600/24<=getTargetARGApac(arg.`Metric`),1,0)) as 'Volume within SLA',
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
and r.Reporting_Business_Units__c like 'Emea%'
and (r.Reporting_Business_Units__c like 'Emea%' or (r.Reporting_Business_Units__c is null and arg.Region like 'Emea%'))
and p.business_line__c not like '%Product%'
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
from apac_ops_metric_arg_end_to_end_1 t
where t.`Period` >= '2015 07'
and t.`Country` like 'Emea%'
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
from apac_ops_metric_arg_end_to_end_2 t
where t.`Period` >= '2015 07'
and t.`Country` like 'Emea%'
group by `_Type`, `_Metric`, `_Country`, `_Owner`, `Standards`, `Target`, `Period`, `Auto-Approved`, `With Hold`)

union
#Auditor utilisation
(SELECT 
'Performance' as '_Type',
'Resource Utilisation' as '_Metric',
'n/a' as 'Business Line',
substring_index(i.`Business Unit`,'-',-1) as 'Country',
i.`Name` as 'Owner',
null as 'Program',
null as 'Standards',
i.`Period` as 'Period',
j.`Working Days`-(i.`Holiday Days`+i.`Leave Days`) as 'Volume',
i.`Audit Days`+i.`Travel Days` as 'Sum Value',
if((i.`Audit Days`+i.`Travel Days`)/((j.`Working Days`-(i.`Holiday Days`+i.`Leave Days`))*i.`Resource Capacitiy (%)`/100)>=0.8,1,0) as 'Volume within SLA',
0.8 as 'Target',
null as 'Items',
null as 'Auto-Approved',
null as 'With-Hold'
FROM analytics.emea_ops_metrics_sub1 i     
INNER JOIN analytics.emea_ops_metrics_sub2 j ON i.Period = j.Period
WHERE j.`Working Days`> (i.`Holiday Days`+i.`Leave Days`)
group by Id, i.Period)

union
# Contractors vs FTEs 
(select 
'Performance' as '_Type', 
'Contractor Usage' as '_Metric',
sp.Program_Business_Line__c as 'Business Line',
substring_index(substring_index(wi.Revenue_Ownership__c,'-',2),'-',-1) as 'Country',
null as 'Owner',
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
and wi.Revenue_Ownership__c like 'Emea%'
and sp.Program_Business_Line__c not like '%Product%'
and wi.Work_Item_Date__c >= '2015-07-01'
and wi.Work_Item_Date__c < '2016-07-01'
group by `_Type`, `_Metric`, `Country`, `Owner`, `Standards`, `Target`, `Period`)

union
# Change Requests Backlog
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
crb.Region like 'Emea%'
group by `_Type`, `_Metric`, `Country`, `_Owner`, `Standards`, `Target`, `Period`)
union
# Change Requests - Performance
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
and crc.Region like 'Emea%'
group by `_Type`, `_Metric`, `Country`, `_Owner`, `Standards`, `Target`, `Period`);

(select * from emea_ops_metrics);

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
