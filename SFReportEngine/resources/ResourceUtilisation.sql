use salesforce;

select r.Reporting_Business_Units__c, r.Id, r.Name, r.Resource_Target_Days__c, r.Resource_Capacitiy__c, r.Resource_Type__c, r.Work_Type__c, rt.Name as 'Type', if (wir.Work_Item_Type__c is null, bop.Resource_Blackout_Type__c , wir.Work_Item_Type__c) as 'SubType', e.DurationInMinutes as 'DurationMin', e.DurationInMinutes/60/8 as 'DurationDays', e.ActivityDate, wi.Primary_Standard__c, wi.FStandard_FOS__c 
from resource__c r 
INNER JOIN user u on u.Id = r.User__C 
inner join event e on u.Id = e.OwnerId
INNER JOIN recordtype rt on e.RecordTypeId = rt.Id 
LEFT JOIN work_item_resource__c wir on wir.Id = e.WhatId 
left join work_item__c wi on wir.Work_Item__c = wi.Id
LEFT JOIN blackout_period__c bop on bop.Id = e.WhatId 
where r.Reporting_Business_Units__c like 'AUS%' 
and e.ActivityDate >= '2014-08-01' and e.ActivityDate <= '2014-08-31'
and Resource_Type__c not in ('Client Services')
and r.Reporting_Business_Units__c not in ('AUS-CSC','AUS-MGT', 'AUS-OPS')
and r.Active_User__c = 'Yes'
and e.IsDeleted=0
limit 1000000;

use salesforce;
#FTE/Contractors Days
select t.*, (t.FTEDays + t.ContractorDays) as 'Total Days', t.FTEDays/(t.FTEDays + t.ContractorDays) as 'FTEDays%', t.ContractorDays/(t.FTEDays + t.ContractorDays) as 'ContractorDays%' from (
select date_format(e.ActivityDate, '%Y %m') as 'Period',sum(if(r.Resource_Type__c='Employee', e.DurationInMinutes/60/8, null)) as 'FTEDays', sum(if(r.Resource_Type__c='Contractor', e.DurationInMinutes/60/8, null)) as 'ContractorDays'
from resource__c r 
INNER JOIN user u on u.Id = r.User__C 
inner join event e on u.Id = e.OwnerId
INNER JOIN recordtype rt on e.RecordTypeId = rt.Id 
INNER JOIN work_item_resource__c wir on wir.Id = e.WhatId 
where (r.Reporting_Business_Units__c like 'AUS%' or r.Reporting_Business_Units__c like 'ASS%')
and e.ActivityDate >= '2013-01-01' and e.ActivityDate <= '2014-12-31'
and Resource_Type__c not in ('Client Services')
and r.Reporting_Business_Units__c not in ('AUS-CSC','AUS-MGT', 'AUS-OPS')
and r.Reporting_Business_Units__c not like '%Product%'
#and r.Active_User__c = 'Yes'
and e.IsDeleted=0
and wir.Work_Item_Type__c = 'Audit'
and rt.Name = 'Work Item Resource'
group by `Period`) t;

#Gaps Count
SELECT  
date_format(i.date, '%Y %m') as 'Period', count(i.date) 
FROM 
(SELECT wd.date, r.Id 
FROM `sf_working_days` wd, resource__c r 
WHERE  
r.Id in (select r.Id from resource__c r where (r.Reporting_Business_Units__c like 'AUS%' or r.Reporting_Business_Units__c like 'ASS%') and r.Reporting_Business_Units__c not like 'AUS-Product%' and Resource_Type__c not in ('Client Services') and r.Reporting_Business_Units__c not in ('AUS-CSC','AUS-MGT', 'AUS-OPS') and r.Active_User__c = 'Yes' 
			and r.Resource_Target_Days__c > 50
		)
and wd.date >= '2013-01-01' 
AND wd.date <= '2014-10-31' ) i 
LEFT JOIN 
(SELECT r.Id, e.ActivityDate 
FROM `event` e 
INNER JOIN `resource__c` r ON r.User__c = e.OwnerId 
WHERE 
(r.Reporting_Business_Units__c like 'AUS%' or r.Reporting_Business_Units__c like 'ASS%') 
and r.Reporting_Business_Units__c not like 'AUS-Product%' 
and r.Resource_Type__c not in ('Client Services')
and r.Reporting_Business_Units__c not in ('AUS-CSC','AUS-MGT', 'AUS-OPS')
and r.Resource_Target_Days__c > 50
and r.Active_User__c = 'Yes'
and e.ActivityDate >= '2013-01-01' 
AND e.ActivityDate <= '2014-10-31') t ON t.ActivityDate = i.date AND t.id = i.Id 
WHERE  t.Id is NULL 
GROUP BY `Period`;

# Utilsation by Period and Resource
select k.*, k.AuditPlusTravelDays/(k.`Working Days`*k.`Resource_Target_Days__c`/180-k.`LeavePlusHolidayPlusTrainingDays`) as 'Utilization' from
(select i.*, j.`Working Days` from
(select date_format(t.ActivityDate, '%Y %m') as 'Period', t.Id, t.Name, t.Resource_Target_Days__c, 
sum(if(t.SubType = 'Audit' or t.SubType = 'Travel', t.DurationDays,0)) as 'AuditPlusTravelDays', 
sum(if(t.SubType like 'Leave%' or t.SubType like 'Training%' or t.SubType='Public Holiday', t.DurationDays,0)) as 'LeavePlusHolidayPlusTrainingDays'
from (
select r.Id, r.Name, r.Resource_Target_Days__c, r.Resource_Capacitiy__c, r.Resource_Type__c, r.Work_Type__c, rt.Name as 'Type', if (wir.Work_Item_Type__c is null, bop.Resource_Blackout_Type__c , wir.Work_Item_Type__c) as 'SubType', e.DurationInMinutes as 'DurationMin', e.DurationInMinutes/60/8 as 'DurationDays', e.ActivityDate
from resource__c r 
INNER JOIN user u on u.Id = r.User__C 
left join event e on u.Id = e.OwnerId
left JOIN recordtype rt on e.RecordTypeId = rt.Id 
LEFT JOIN work_item_resource__c wir on wir.Id = e.WhatId 
LEFT JOIN blackout_period__c bop on bop.Id = e.WhatId 
where (r.Reporting_Business_Units__c like 'AUS%' or r.Reporting_Business_Units__c like 'ASS%') 
and ((e.ActivityDate >= '2014-08-01' and e.ActivityDate <= '2014-08-31') or e.Id is null)
and Resource_Type__c not in ('Client Services')
and r.Reporting_Business_Units__c not in ('AUS-CSC','AUS-MGT', 'AUS-OPS')
and r.Reporting_Business_Units__c not like 'AUS-Product%'
and r.Active_User__c = 'Yes'
and r.Resource_Type__c = 'Employee'
and (e.IsDeleted=0 or e.Id is null)) t
group by `Period`, t.Id) i
inner join (SELECT date_format(wd.date, '%Y %m') as 'Period', count(wd.date) as 'Working Days'
FROM `sf_working_days` wd
WHERE  
wd.date >= '2014-08-01' 
AND wd.date <= '2014-08-31'
group by `Period`) j on i.Period = j.Period) k;

# Utilsation by Period
select k.Period, 
sum(k.AuditPlusTravelDays)/(sum(k.`Working Days`*k.`Resource_Target_Days__c`/180)-sum(k.`LeavePlusHolidayDays`)) as 'Utilization_All',
sum(if(k.`Resource_Target_Days__c`=180,k.AuditPlusTravelDays,0))/(sum(if(k.`Resource_Target_Days__c`=180,k.`Working Days`*k.`Resource_Target_Days__c`/180,0))-sum(if(k.`Resource_Target_Days__c`=180,k.`LeavePlusHolidayDays`,0))) as 'Utilization_180',
sum(k.AuditPlusTravelDays)/(sum(k.`Working Days`)-sum(k.`LeavePlusHolidayDays`)) as 'Utilization_All_Disregard_Target',
sum(if(k.`Resource_Target_Days__c`>140,k.AuditPlusTravelDays,0))/(sum(if(k.`Resource_Target_Days__c`>140,k.`Working Days`,0))-sum(if(k.`Resource_Target_Days__c`>140,k.`LeavePlusHolidayDays`,0))) as 'Utilization_Target_Gr_140_Full_Time',
sum(if(k.`Resource_Target_Days__c`>100,k.AuditPlusTravelDays,0))/(sum(if(k.`Resource_Target_Days__c`>100,k.`Working Days`,0))-sum(if(k.`Resource_Target_Days__c`>100,k.`LeavePlusHolidayDays`,0))) as 'Utilization_Target_Gr_100_Full_Time',
sum(if(k.`Resource_Target_Days__c`>100,k.AuditPlusTravelDays,0))/(sum(if(k.`Resource_Target_Days__c`>100,k.`Working Days`*k.`Resource_Target_Days__c`/180,0))-sum(if(k.`Resource_Target_Days__c`>100,k.`LeavePlusHolidayDays`,0))) as 'Utilization_Target_Gr_100_Using_Target',
sum(if(k.`Resource_Target_Days__c`>50,k.AuditPlusTravelDays,0))/(sum(if(k.`Resource_Target_Days__c`>50,k.`Working Days`*k.`Resource_Target_Days__c`/180,0))-sum(if(k.`Resource_Target_Days__c`>50,k.`LeavePlusHolidayDays`,0))) as 'Utilization_Target_Gr_50_Using_Target'
from
(select i.*, j.`Working Days` from
(select date_format(t.ActivityDate, '%Y %m') as 'Period', t.Id, t.Name, t.Resource_Target_Days__c, 
sum(if(t.SubType = 'Audit' or t.SubType = 'Travel', t.DurationDays,0)) as 'AuditPlusTravelDays', 
sum(if(t.SubType like 'Leave%' or t.SubType like 'Training%' or t.SubType='Public Holiday', t.DurationDays,0)) as 'LeavePlusHolidayPlusTrainingDays',
sum(if(t.SubType like 'Leave%' or t.SubType='Public Holiday', t.DurationDays,0)) as 'LeavePlusHolidayDays'
from (
select r.Id, r.Name, r.Resource_Target_Days__c, r.Resource_Capacitiy__c, r.Resource_Type__c, r.Work_Type__c, rt.Name as 'Type', if (wir.Work_Item_Type__c is null, bop.Resource_Blackout_Type__c , wir.Work_Item_Type__c) as 'SubType', e.DurationInMinutes as 'DurationMin', e.DurationInMinutes/60/8 as 'DurationDays', e.ActivityDate
from resource__c r 
INNER JOIN user u on u.Id = r.User__C 
inner join event e on u.Id = e.OwnerId
INNER JOIN recordtype rt on e.RecordTypeId = rt.Id 
LEFT JOIN work_item_resource__c wir on wir.Id = e.WhatId 
LEFT JOIN blackout_period__c bop on bop.Id = e.WhatId 
where (r.Reporting_Business_Units__c like 'AUS%' or r.Reporting_Business_Units__c like 'ASS%')
and ((e.ActivityDate >= '2014-01-01' and e.ActivityDate <= '2014-08-31') or e.Id is null)
and Resource_Type__c not in ('Client Services')
and r.Reporting_Business_Units__c not in ('AUS-CSC','AUS-MGT', 'AUS-OPS')
and r.Reporting_Business_Units__c not like 'AUS-Product%'
and r.Active_User__c = 'Yes'
and r.Resource_Type__c = 'Employee'
and r.Resource_Target_Days__c is not null
and r.Resource_Target_Days__c > 0
and (e.IsDeleted=0 or e.Id is null)) t
group by `Period`, t.Id) i
inner join (SELECT date_format(wd.date, '%Y %m') as 'Period', count(wd.date) as 'Working Days'
FROM `sf_working_days` wd
WHERE  
wd.date >= '2014-01-01' 
AND wd.date <= '2014-08-31'
group by `Period`) j on i.Period = j.Period) k
group by `Period`;

#Inserts in history
describe sf_report_history;

INSERT INTO sf_report_history (
select * from (
select 
null as 'Id',
'Scheduling Auditors Metrics' as 'Report Name',
now() as 'Date',
'Australia' as 'Region',
'Food-FTEDays%' as 'RowName',
t.Period as 'ColumnName', 
t.FTEDays/(t.FTEDays + t.ContractorDays) as 'Value' from (
select date_format(e.ActivityDate, '%Y %m') as 'Period',sum(if(r.Resource_Type__c='Employee', e.DurationInMinutes/60/8, null)) as 'FTEDays', sum(if(r.Resource_Type__c='Contractor', e.DurationInMinutes/60/8, null)) as 'ContractorDays'
from resource__c r 
INNER JOIN user u on u.Id = r.User__C 
inner join event e on u.Id = e.OwnerId
INNER JOIN recordtype rt on e.RecordTypeId = rt.Id 
INNER JOIN work_item_resource__c wir on wir.Id = e.WhatId 
where (r.Reporting_Business_Units__c like 'AUS%' or r.Reporting_Business_Units__c like 'ASS%')
and date_format(e.ActivityDate, '%Y %m') <= date_format(date_add(now(), interval -1 month), '%Y %m')
and Resource_Type__c not in ('Client Services')
and r.Reporting_Business_Units__c not in ('AUS-CSC','AUS-MGT', 'AUS-OPS')
and r.Reporting_Business_Units__c not like '%Product%'
and r.Reporting_Business_Units__c like '%AUS-Food%'
#and r.Active_User__c = 'Yes'
and e.IsDeleted=0
and wir.Work_Item_Type__c = 'Audit'
and rt.Name = 'Work Item Resource'
group by `Period`) t
union
(select 
null as 'Id',
'Scheduling Auditors Metrics' as 'Report Name',
now() as 'Date',
'Australia' as 'Region',
'Food-BlankDaysCount' as 'RowName',
date_format(i.date, '%Y %m') as 'ColumnName', 
count(i.date) as 'Value'
FROM 
(SELECT wd.date, r.Id 
FROM `sf_working_days` wd, resource__c r 
WHERE  
r.Id in (select r.Id from resource__c r where (r.Reporting_Business_Units__c like 'AUS%' or r.Reporting_Business_Units__c like 'ASS%') and r.Reporting_Business_Units__c not like 'AUS-Product%' and Resource_Type__c not in ('Client Services') and r.Reporting_Business_Units__c not in ('AUS-CSC','AUS-MGT', 'AUS-OPS') and r.Active_User__c = 'Yes' 
			and r.Reporting_Business_Units__c like '%AUS-Food%'
			and r.Resource_Target_Days__c > 50
		)
and date_format(wd.date, '%Y %m') <= date_format(date_add(now(), interval -1 month), '%Y %m')) i 
LEFT JOIN 
(SELECT r.Id, e.ActivityDate 
FROM `event` e 
INNER JOIN `resource__c` r ON r.User__c = e.OwnerId 
WHERE 
(r.Reporting_Business_Units__c like 'AUS%' or r.Reporting_Business_Units__c like 'ASS%') 
and r.Reporting_Business_Units__c not like 'AUS-Product%' 
and r.Reporting_Business_Units__c like '%AUS-Food%'
and r.Resource_Type__c not in ('Client Services')
and r.Reporting_Business_Units__c not in ('AUS-CSC','AUS-MGT', 'AUS-OPS')
and r.Resource_Target_Days__c > 50
and r.Active_User__c = 'Yes'
and date_format(e.ActivityDate, '%Y %m') <= date_format(date_add(now(), interval -1 month), '%Y %m') ) t ON t.ActivityDate = i.date AND t.id = i.Id 
WHERE  t.Id is NULL 
GROUP BY `ColumnName`)
union
(select 
null as 'Id',
'Scheduling Auditors Metrics' as 'Report Name',
now() as 'Date',
'Australia' as 'Region',
'Food-Utilisation' as 'RowName',
k.Period as 'ColumnName', 
#sum(k.AuditPlusTravelDays)/(sum(k.`Working Days`*k.`Resource_Target_Days__c`/180)-sum(k.`LeavePlusHolidayPlusTrainingDays`)) as 'Utilization_All',
#sum(if(k.`Resource_Target_Days__c`=180,k.AuditPlusTravelDays,0))/(sum(if(k.`Resource_Target_Days__c`=180,k.`Working Days`*k.`Resource_Target_Days__c`/180,0))-sum(if(k.`Resource_Target_Days__c`=180,k.`LeavePlusHolidayPlusTrainingDays`,0))) as 'Utilization_180',
#sum(k.AuditPlusTravelDays)/(sum(k.`Working Days`)-sum(k.`LeavePlusHolidayPlusTrainingDays`)) as 'Utilization_All_Disregard_Target',
#sum(if(k.`Resource_Target_Days__c`>140,k.AuditPlusTravelDays,0))/(sum(if(k.`Resource_Target_Days__c`>140,k.`Working Days`,0))-sum(if(k.`Resource_Target_Days__c`>140,k.`LeavePlusHolidayDays`,0))) as 'Value' #'Utilization_Target_Gr_140'
sum(if(k.`Resource_Target_Days__c`>50,k.AuditPlusTravelDays,0))/(sum(if(k.`Resource_Target_Days__c`>50,k.`Working Days`*k.`Resource_Target_Days__c`/180,0))-sum(if(k.`Resource_Target_Days__c`>50,k.`LeavePlusHolidayDays`,0))) as 'Value'
from
(select i.*, j.`Working Days` from
(select date_format(t.ActivityDate, '%Y %m') as 'Period', t.Id, t.Name, t.Resource_Target_Days__c, 
sum(if(t.SubType = 'Audit' or t.SubType = 'Travel', t.DurationDays,0)) as 'AuditPlusTravelDays', 
sum(if(t.SubType like 'Leave%' or t.SubType like 'Training%' or t.SubType='Public Holiday', t.DurationDays,0)) as 'LeavePlusHolidayPlusTrainingDays',
sum(if(t.SubType like 'Leave%' or t.SubType='Public Holiday', t.DurationDays,0)) as 'LeavePlusHolidayDays'
from (
select r.Id, r.Name, r.Resource_Target_Days__c, r.Resource_Capacitiy__c, r.Resource_Type__c, r.Work_Type__c, rt.Name as 'Type', if (wir.Work_Item_Type__c is null, bop.Resource_Blackout_Type__c , wir.Work_Item_Type__c) as 'SubType', e.DurationInMinutes as 'DurationMin', e.DurationInMinutes/60/8 as 'DurationDays', e.ActivityDate
from resource__c r 
INNER JOIN user u on u.Id = r.User__C 
inner join event e on u.Id = e.OwnerId
INNER JOIN recordtype rt on e.RecordTypeId = rt.Id 
LEFT JOIN work_item_resource__c wir on wir.Id = e.WhatId 
LEFT JOIN blackout_period__c bop on bop.Id = e.WhatId 
where (r.Reporting_Business_Units__c like 'AUS%' or r.Reporting_Business_Units__c like 'ASS%')
and ((date_format(e.ActivityDate, '%Y %m') <= date_format(date_add(now(), interval -1 month), '%Y %m')) or e.Id is null)
and Resource_Type__c not in ('Client Services')
and r.Reporting_Business_Units__c not in ('AUS-CSC','AUS-MGT', 'AUS-OPS')
and r.Reporting_Business_Units__c not like 'AUS-Product%'
and r.Reporting_Business_Units__c like '%AUS-Food%'
and r.Active_User__c = 'Yes'
and r.Resource_Type__c = 'Employee'
and r.Resource_Target_Days__c is not null
and r.Resource_Target_Days__c > 0
and (e.IsDeleted=0 or e.Id is null)) t
group by `Period`, t.Id) i
inner join (SELECT date_format(wd.date, '%Y %m') as 'Period', count(wd.date) as 'Working Days'
FROM `sf_working_days` wd
WHERE  
date_format(wd.date, '%Y %m') <= date_format(date_add(now(), interval -1 month), '%Y %m')
group by `Period`) j on i.Period = j.Period) k
group by `ColumnName`)) f);

select max(t2.Date) from (
select t.*
from (
select * from sf_report_history 
where ReportName='Scheduling Auditors Metrics'
and ColumnName >= '2014 06'
and ColumnName <= '2014 11'
order by Date desc) t
group by t.Region,t.ColumnName, RowName) t2;

select t.*
from (
select * from sf_report_history 
where ReportName='Scheduling Auditors Metrics'
and RowName like 'Food%'
and ColumnName >= '2014 06'
and ColumnName <= '2014 11'
order by Date desc) t
group by Region,ColumnName, RowName;



 