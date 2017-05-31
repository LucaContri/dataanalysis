use salesforce;
create or replace view enlighten_scheduling_wip_sub as
select 
wi.Id, 
wi.Scheduling_Ownership__c, 
concat(wi.Service_Target_Year__c,'-',if(wi.Service_Target_Month__c<=9,concat('0',wi.Service_Target_Month__c),wi.Service_Target_Month__c), '-01') as 'Service_Target_date__c',
#wi.Service_Target_date__c, 
wi.work_item_Date__c, 
wi.Status__c, 
wi.Open_Sub_Status__c , 
wi.Scheduling_Complexity__c 
from work_item__c wi 
where wi.Scheduling_Ownership__c in ('AUS - Food', 'AUS - Product Services', 'AUS - Management Systems') 
and if(wi.Status__c in ('Open', 'Service change'),
		if(wi.Scheduling_Ownership__c = 'AUS - Management Systems',
			if(wi.Scheduling_Complexity__c = 'High', wi.Service_Target_date__c<=date_add(now(), INTERVAL 18 MONTH), if(wi.Scheduling_Complexity__c = 'Medium',wi.Service_Target_date__c<=date_add(now(), INTERVAL 9 MONTH),wi.Service_Target_date__c<=date_add(now(), INTERVAL 6 MONTH))),
			if(wi.Scheduling_Ownership__c = 'AUS - Food', 
				if(wi.Scheduling_Complexity__c = 'High', wi.Service_Target_date__c<=date_add(now(), INTERVAL 9 MONTH), if(wi.Scheduling_Complexity__c = 'Medium',wi.Service_Target_date__c<=date_add(now(), INTERVAL 9 MONTH),wi.Service_Target_date__c<=date_add(now(), INTERVAL 6 MONTH))),
				if(wi.Scheduling_Complexity__c = 'High', wi.Service_Target_date__c<=date_add(now(), INTERVAL 6 MONTH), if(wi.Scheduling_Complexity__c = 'Medium',wi.Service_Target_date__c<=date_add(now(), INTERVAL 6 MONTH),wi.Service_Target_date__c<=date_add(now(), INTERVAL 6 MONTH)))
			)
		),
        if(wi.Status__c in ('Scheduled'),
			wi.Work_Item_date__c<=date_add(now(), INTERVAL 3 MONTH),
            1 #Scheduled Offered
		)
	)
and wi.Status__c in ('Open', 'Scheduled', 'Scheduled - Offered', 'Service change');

create or replace view enlighten_scheduling_wip_old as
(select 
if(t.Scheduling_Ownership__c = 'AUS - Management Systems', 'Scheduling - MS', 'Scheduling - FP') as 'Team',
if((t.Status__c = 'Open' and t.Open_Sub_Status__c is null) or t.Status__c = 'Service change','Scheduled',
	if(t.Status__c = 'Open' and t.Open_Sub_Status__c is not null,'Open W Substatus',
	if (t.Status__c = 'Scheduled','Scheduled Offered','Confirmed'))) as 'Activity',
count(t.Id) as 'WIP',
date_format(now(), '%d/%m/%Y') as 'Date/Time'
from enlighten_scheduling_wip_sub t
group by `Team`, `Activity`) union (
select if (sc.Operational_Ownership__c like '%Food%', 'Scheduling - FP', if (Operational_Ownership__c like '%Product%', 'Scheduling - FP', 'Scheduling - MS')) as 'Team',
'Validate Lifecycle' as 'Activity',
count(distinct sc.Id) as 'WIP',
now() as 'Date/Time'
from certification__c sc 
inner join site_certification_standard_program__c scsp on scsp.Site_Certification__c = sc.Id 
where 
sc.IsDeleted = 0 
and scsp.IsDeleted = 0 
and scsp.Status__c not in ('Application Unpaid','Applicant','De-registered','Concluded','Transferred') 
and sc.Primary_Certification__c is not null 
and sc.Status__c = 'Active' 
and (sc.Mandatory_Site__c=1 or (sc.Mandatory_Site__c=0 and sc.FSample_Site__c like '%unchecked%')) 
and scsp.Administration_Ownership__c like 'AUS%' 
and sc.Lifecycle_Validated__c = 0
group by `Team`, `Activity`);

CREATE OR REPLACE VIEW `salesforce`.`enlighten_scheduling_wip` AS
    SELECT 
        `analytics`.`sla_scheduling_backlog`.`Team` AS `Team`,
        '' AS `User`,
        `analytics`.`sla_scheduling_backlog`.`Activity` AS `Activity`,
        COUNT(0) AS `WIP`,
        DATE_FORMAT(NOW(), '%Y-%m-%d') AS `Date/Time`
    FROM
        `analytics`.`sla_scheduling_backlog`
	WHERE `analytics`.`sla_scheduling_backlog`.`Region` in ('AUS - Food', 'AUS - Product Services', 'AUS - Management Systems') 
    GROUP BY `analytics`.`sla_scheduling_backlog`.`Team` , `analytics`.`sla_scheduling_backlog`.`Activity`;

    
select * from salesforce.enlighten_scheduling_wip;
    SELECT `Team`, '' AS `User`, `Activity`, COUNT(*) AS `WIP`, DATE_FORMAT(NOW(), '%Y-%m-%d') AS `Date/Time`
    FROM `sla_scheduling_backlog`
	WHERE `Region` like 'EMEA%'
    GROUP BY `Team`, `Activity`;
    
    (SELECT *, date_add(`From`, interval 3 month) as 'Target'
    FROM `sla_scheduling_backlog`
	WHERE `Region` like 'EMEA%');
    
(SELECT sla.*, wi.Work_Item_Date__c,if(sla.Region like 'AUS%', 'Australia', substring_index(sla.Region, ' - ',-1)) as 'Country', if(sla.Region like 'AUS%', 'APAC', substring_index(sla.Region, ' - ',1)) as 'Region2'
    FROM
        `analytics`.`sla_scheduling_backlog` sla
        inner join salesforce.work_item__c wi on sla.Id = wi.Id);
	WHERE sla.`Region` like 'EMEA%');

select * from salesforce.enlighten_scheduling_emea_wip;


#enlighten_scheduling_activity
#Team	User	Activity	Completed	Date/Time
create or replace view enlighten_scheduling_activity_sub as
select 
wi.Id,
u.Name, 
wi.Scheduling_Ownership__c,
DATE_ADD(wih.CreatedDate, INTERVAL 11 HOUR) as 'EditDate', 
wih.Field , 
wih.OldValue, 
if (wih.Field='created','Open',wih.NewValue) as 'NewValue'
from work_item__history wih 
inner join user u on wih.CreatedById = u.Id 
inner join work_item__c wi on wi.Id = wih.ParentId 
where wih.Field in ('Status__c', 'created', 'Open_Sub_Status__c') 
and wi.Scheduling_Ownership__c in ('AUS - Food', 'AUS - Product Services', 'AUS - Management Systems')
#and date_format(DATE_ADD(wih.CreatedDate, INTERVAL 11 HOUR), '%Y-%m-%d')=date_format(now(), '%Y-%m-%d')
and wih.CreatedDate<=utc_timestamp()
and wih.CreatedDate>date_add(utc_timestamp(), interval -1 day);

# Update Resource Calendar
select 'Scheduling' as 'Team',
cb.Name as 'User', 
'Calendar Update' as 'Activity', 
bop.Name,
count(distinct e.WhatId) as 'Completed',
count(distinct e.CreatedDate),
e.CreatedDate,
e.LastModifiedDate,
date_Add(e.LastModifiedDate, interval 9 hour) 'EditDate'
from `event` e 
inner join user cb on e.LastModifiedById = cb.Id
inner join recordtype rt on e.RecordTypeId = rt.Id
inner join blackout_period__c bop on bop.Id = e.WhatId
where date_format(date_add(e.LastModifiedDate, interval 9 hour), '%Y') = '2014'
and rt.Name = 'Blackout Period Resource'
group by `Team`, `User`, `Activity`;

select * from blackout_period__c bop where bop.S;
# Validate Audit Lifecycle
select 
sc.Id, sc.Name, u.Name as 'User', sch.OldValue, sch.NewValue
from certification__c sc                 
inner join certification__history sch on sch.ParentId = sc.Id
inner join user u on sch.CreatedById = u.Id
where date_format(date_add(sch.CreatedDate, interval 9 hour), '%Y-%m-%d') = '2015-01-16'
and sch.Field = 'Lifecycle_Validated__c';
#and sch.NewValue = 'true';

create or replace view enlighten_scheduling_activity_old as
(select 
#if(t.Scheduling_Ownership__c = 'AUS - Management Systems', 'Scheduling - MS', 'Scheduling - FP') as 'Team',
'Scheduling' as 'Team',
t.Name as 'User',
if (t.Field = 'Open_Sub_Status__c', 
	if( t.NewValue in ('Pending Suspension','Pending Cancellation'), 'Cancelled', 'Unable To Schedule'),
	if(t.OldValue is null and t.NewValue='Open', 'Create Work Item',
		if(t.NewValue = 'Scheduled', 'Scheduled',
			if(t.NewValue = 'Scheduled - Offered', 'Scheduled Offered',
				if(t.NewValue = 'Confirmed', 'Confirmed',
					if(t.NewValue = 'Cancelled', 'Cancelled','?')
				)
			)
		)
	)
) as 'Activity',
count(distinct t.Id) as 'Completed',
t.EditDate
from enlighten_scheduling_activity_sub t
where 
if(t.OldValue is null and t.NewValue='Open', 1,
	if (t.Field = 'Status__c',
		if(t.NewValue in ('Scheduled', 'Scheduled - Offered', 'Confirmed', 'Cancelled'),1,0),
        1
	)
)
group by `User`, `Activity`)
union
(select 'Scheduling' as 'Team',
cb.Name as 'User', 
'Calendar Update' as 'Activity', 
#count(distinct e.WhatId) as 'Completed',
count(distinct e.LastModifiedDate) as 'Completed',
date_Add(e.LastModifiedDate, interval 9 hour) 'EditDate'
from `event` e 
inner join user cb on e.LastModifiedById = cb.Id
inner join recordtype rt on e.RecordTypeId = rt.Id
where 
#date_format(date_add(e.LastModifiedDate, interval 9 hour), '%Y-%m-%d') = date_format(now(), '%Y-%m-%d')
e.LastModifiedDate<=utc_timestamp()
and e.LastModifiedDate>date_add(utc_timestamp(), interval -1 day)
and rt.Name = 'Blackout Period Resource'
group by `Team`, `User`, `Activity`);
#union (
#select 
#'Scheduling' as 'Team',
#u.Name as 'User', 
#'Validate Lifecycle' as 'Activity',
#count(sc.Id) as 'Completed',
#date_add(sch.CreatedDate, interval 9 hour) as 'EditDate'
#from certification__c sc                 
#inner join certification__history sch on sch.ParentId = sc.Id
#inner join user u on sch.CreatedById = u.Id
#where date_format(date_add(sch.CreatedDate, interval 9 hour), '%Y-%m-%d')  = date_format(now(), '%Y-%m-%d')
#and sch.Field = 'Lifecycle_Validated__c'
#and sch.NewValue = 'true'
#group by `Team`, `User`, `Activity`);

create or replace view enlighten_scheduling_activity_validate_lifecycle as(
select u.Name as 'User', scl.Site_Certification__c
from salesforce.site_certification_lifecycle__c scl
inner join salesforce.site_certification_lifecycle__history sclh on sclh.ParentId = scl.Id
inner join user u on sclh.CreatedById = u.Id
where 
sclh.CreatedDate > date_add(utc_timestamp(), interval -1 day)
and scl.isDeleted=0
group by scl.Site_Certification__c)
union
(select u.Name as 'User', scl.Site_Certification__c
from salesforce.site_certification_lifecycle__c scl
inner join salesforce.user u on scl.LastModifiedById = u.Id
where 
scl.LastModifiedDate > date_add(utc_timestamp(), interval -1 day)
and scl.isDeleted=1)
union
(select 
u.Name as 'User', sc.Id as 'Site_Certification__c'
from salesforce.certification__c sc                 
inner join salesforce.certification__history sch on sch.ParentId = sc.Id
inner join salesforce.user u on sch.CreatedById = u.Id
where sch.CreatedDate > date_add(utc_timestamp(), interval -1 day)
and sch.Field = 'Lifecycle_Validated__c');

create or replace view enlighten_scheduling_activity_old as
(select 'Scheduling' as 'Team', `Owner` as 'User', `Activity`, count(*) as 'Completed', date_format(now(), '%Y-%m-%d') as 'Date/Time', group_concat(distinct Id) as 'Notes'
from analytics.sla_scheduling_completed
where `To` > date_add(utc_timestamp(), interval -1 day)
and `Activity` not in ('Validate Lifecycle')
group by `User`, `Activity`)
union (
select 'Scheduling' as 'Team', t.User as 'User', 'Validate Lifecycle' as 'Activity', count(distinct t.Site_Certification__c) as 'Completed', date_format(now(), '%Y-%m-%d') as 'Date/Time', group_concat(distinct t.Site_Certification__c) as 'Notes' 
from enlighten_scheduling_activity_validate_lifecycle t
group by `User`);

create or replace view salesforce.enlighten_scheduling_activity as
(select 'Scheduling' as 'Team', `Owner` as 'User', `Activity`, count(*) as 'Completed', date_format(now(), '%Y-%m-%d') as 'Date/Time', group_concat(distinct Id) as 'Notes'
from analytics.sla_scheduling_completed
where `To` > date_add(utc_timestamp(), interval -1 day)
and (Region like 'AUS%' or Region like 'ASS%' or (Region is null and Activity='Calendar Update'))
group by `User`, `Activity`);

select * from salesforce.enlighten_scheduling_activity;

(select 'Scheduling' as 'Team', `Owner` as 'User', `Activity`, count(*) as 'Completed', date_format(now(), '%Y-%m-%d') as 'Date/Time', group_concat(distinct Id) as 'Notes'
from analytics.sla_scheduling_completed
where `To` > date_add(utc_timestamp(), interval -1 day)
and Region like 'EMEA%'
group by `User`, `Activity`);

select * from enlighten_scheduling_activity;

select t.* from (
select v2.*, v1.Completed as 'Completed (old)' from enlighten_scheduling_activity v2
left join enlighten_scheduling_activity_old v1 on v1.User = v2.User and v1.Activity = v2.Activity) t
where t.`Completed (old)` is null or t.`Completed (old)` != t.`Completed`;

create or replace view enlighten_scheduling_wip as
select `Team`, '' as 'User', `Activity`, count(*) as 'WIP', date_format(now(), '%Y-%m-%d') as 'Date/Time'
from analytics.sla_scheduling_backlog
group by `Team`,`Activity`;

select t.* from (
select v2.*, v1.WIP as 'WIP (old)' from enlighten_scheduling_wip v2
left join enlighten_scheduling_wip_old v1 on v1.Team = v2.Team and v1.Activity = v2.Activity) t
where t.`WIP (old)` is null or abs(t.`WIP`-t.`WIP (old)`)/t.`WIP (old)`*100 > 5;
select * from enlighten_scheduling_wip;