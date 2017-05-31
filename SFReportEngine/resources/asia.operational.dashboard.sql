select distinct Metric from analytics.sla_arg_v2;
#ARG rejection rate
select
'Performance' as 'Type', 
'ARG rejection rate' as 'Metric',
sp.Program_Business_Line__c as 'Stream',
if(r.Reporting_Business_Units__c like 'AUS%', 'Australia', substring_index(r.Reporting_Business_Units__c,'-',-1)) as 'Country',
r.Name as 'Owner',
p.Name as 'Program',
arg.Audit_Report_Standards__c as 'Standards',
date_format(arg.CA_Approved__c, '%Y %m')  as 'Period',
count(distinct arg.Id) as 'Volume',
count(distinct if(ah.Status__c='Rejected', ah.Id, null))/count(distinct arg.Id)  as 'Avg Value',
count(distinct if(ah.Status__c='Rejected', ah.Id, null)) as 'Sum Value',
0.08 as 'Target',
#sum(if(sched.`SLA Due` < sched.`To`,0,1)) as 'Count Within SLA',
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
and (r.Reporting_Business_Units__c like 'Asia%' or r.Reporting_Business_Units__c like 'AUS%') 
and r.Reporting_Business_Units__c not like '%Product%'
group by `Type`, `Metric`, `Country`, `Owner`, `Standards`, `Period`
union
# ARG Performance and Backlog
select 
if(arg.`To` is null, 'Backlog', 'Performance') as 'Type',
if(arg.`Metric` in ('ARG Process Time (BRC)', 'ARG Process Time (Other)'), 'ARG Cycle (Business Days)',
	if(arg.`Metric` in ('ARG Completion/Hold'), 'Admin Completion (Business Days)',
		if(arg.`Metric` in ('ARG Revision - Resubmission'), 'Technical Review - Resubmission (Business Days)',
			if(arg.`Metric` in ('ARG Revision - First'), 'Technical Review - First (Business Days)',
				if(arg.`Metric` in ('ARG Submission - Resubmission'), 'Auditor Re-Submission (Business Days)',
					if(arg.`Metric` in ('ARG Submission - First'), 'Auditor First Submission (Business Days)',
						arg.`Metric`
					)
				)
            )
        )
    )
) as 'Metric',
if(arg.`Tags` like 'MS;%', 'Management Systems', if(arg.`Tags` like 'Food;%', 'Agri-Food', if(arg.`Tags` like 'PS;%', 'Product Services', '?'))) as 'Stream',
if(r.Reporting_Business_Units__c like 'AUS%', 'Australia', substring_index(r.Reporting_Business_Units__c,'-',-1)) as 'Country',
arg.`Owner` as 'Owner',
p.Name as 'Program',
arg.`Standards` as `Standards`,
date_format(arg.`To`, '%Y %m')  as 'Period',
count(arg.Id) as 'Volume',
avg(analytics.getBusinessDays(arg.`From`, ifnull(arg.`To`, utc_timestamp()), arg.`TimeZone`))  as 'Avg Value',
sum(analytics.getBusinessDays(arg.`From`, ifnull(arg.`To`, utc_timestamp()), arg.`TimeZone`)) as 'Sum Value',
if(arg.`Metric` in ('ARG Process Time (BRC)'), 30,
	if(arg.`Metric` in ('ARG Process Time (Other)'), 15,
		if(arg.`Metric` in ('ARG Completion/Hold'), 5,
			if(arg.`Metric` in ('ARG Revision - Resubmission'), 2,
				if(arg.`Metric` in ('ARG Revision - First'), 5,
					if(arg.`Metric` in ('ARG Submission - Resubmission'), 2,
						if(arg.`Metric` in ('ARG Submission - First'), 5,
							if(arg.`Metric` in ('ARG Submission - Unsubmitted WI'), 5,
								if(arg.`Metric` in ('ARG Submission - Submitted WI No ARG'), 5,
									null
								)
                            )
						)
					)
				)
			)
		)
	)
) as 'Target',
#sum(if(arg.`SLA Due` < arg.`To`,0,1)) as 'Count Within SLA',
group_concat(distinct arg.Name) as 'Items'
from analytics.sla_arg_v2 arg 
left join salesforce.Resource__c r on arg.`Owner` = r.Name
left join salesforce.standard__c s on s.Name = substring_index(arg.`Standards`, ',',1)
left join salesforce.program__c p on s.Program__c = p.Id
where
(date_format(arg.`To`, '%Y-%m') >= '2015-07' or arg.`To` is null)
and (r.Reporting_Business_Units__c like 'Asia%' or r.Reporting_Business_Units__c like 'AUS%')
and r.Reporting_Business_Units__c not like '%Product%'
group by `Type`, `Metric`, `Country`, `Owner`, `Standards`, `Target`, `Period`
union
#Auditor utilisation
SELECT 
'Performance' as 'Type',
'Resource Utilisation' as 'Metric',
'n/a' as 'Stream',
substring_index(i.`Business Unit`,'-',-1) as 'Country',
i.`Name` as 'Owner',
null as 'Program',
null as 'Standards',
i.`Period` as 'Period',
j.`Working Days`-(i.`Holiday Days`+i.`Leave Days`) as 'Volume',
if(j.`Working Days`-(i.`Holiday Days`+i.`Leave Days`)=0,null, (i.`Audit Days`+i.`Travel Days`)/((j.`Working Days`-(i.`Holiday Days`+i.`Leave Days`))*i.`Resource Capacitiy (%)`/100)) as 'Avg Value',
i.`Audit Days`+i.`Travel Days` as 'Sum Value',
0.8 as 'Target',
#if(j.`Working Days`-(i.`Holiday Days`+i.`Leave Days`)>0 and (i.`Audit Days`+i.`Travel Days`)/((j.`Working Days`-(i.`Holiday Days`+i.`Leave Days`))*i.`Resource Capacitiy (%)`/100)>=0.8,1,0) as 'Count Within SLA',
null as 'Items'    
FROM         
	(SELECT                       
		t.Id, t.Name, t.Resource_Capacitiy__c as 'Resource Capacitiy (%)', t.Reporting_Business_Units__c as 'Business Unit', t.Manager, DATE_FORMAT(t.ActivityDate, '%Y %m') AS 'Period', SUM(IF(t.SubType = 'Audit', t.DurationDays, 0)) AS 'Audit Days', SUM(IF(t.SubType = 'Travel', t.DurationDays, 0)) AS 'Travel Days', SUM(IF(t.SubType = 'Public Holiday', t.DurationDays, 0)) AS 'Holiday Days', SUM(IF(t.SubType LIKE 'Leave%', t.DurationDays, 0)) AS 'Leave Days', SUM(IF(t.SubType not like 'Leave%' and t.Subtype not in ('Audit','Travel','Public Holiday'), t.DurationDays,0)) as 'Other BOPs',GROUP_CONCAT(DISTINCT IF(t.SubType not like 'Leave%' and t.Subtype not in ('Audit','Travel','Public Holiday'), t.Subtype ,null)) as 'Other BOP Types'     
        FROM 
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
                AND r.Reporting_Business_Units__c LIKE 'AUS%'  
                AND r.Active_User__c = 'Yes'             
                AND r.Resource_Type__c = 'Employee'             
                AND r.Resource_Capacitiy__c IS NOT NULL             
                AND r.Resource_Capacitiy__c >= 30             
                AND (e.IsDeleted = 0 OR e.Id IS NULL)) t     
                GROUP BY `Period` , t.Id) i     
			INNER JOIN 
				(SELECT DATE_FORMAT(wd.date, '%Y %m') AS 'Period', COUNT(wd.date) AS 'Working Days' 
				FROM salesforce.`sf_working_days` wd 
                WHERE
					DATE_FORMAT(wd.date, '%Y %m') >= '2015 07' AND DATE_FORMAT(wd.date, '%Y %m') <= '2016 06'
				GROUP BY `Period`) j ON i.Period = j.Period     
			group by Id, i.Period;
                

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
