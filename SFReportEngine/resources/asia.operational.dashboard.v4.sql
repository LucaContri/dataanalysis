set @start_period = '2015 07';
set @end_period = '2016 06';

create or replace view apac_ops_metrics_v4 as
#ARG rejection rate
(select
	t.`_Type`, 
	t.`_Metric`,
	t.`Business Line`,
	t.`Country`,
	t.`Owner` as '_Owner', #t.`Owner`,
	t.`Program`,
	t.`Standards` as '_Standards', #t.`Standards`,
	t.`Period`,
	sum(t.`Volume`) as 'Volume',
	sum(t.`Sum Value`) as 'Sum Value', #distinct ah.Id means I am counting each rejection
	(sum(t.`Volume`) - sum(t.`Sum Value`)) as 'Volume within SLA',
	t.`Target`,
	ifnull(group_concat(t.`Items`),'') as 'Items', #ifnull(group_concat(t.`Items`),'') as 'Items',
	'' as 'Auto-Approved',
	'' as 'With-Hold',
    '' as 'With TR',
    '' as 'With Waiting Client',
    '' as 'Open_Sub_Status',
    getGlobalAccount(`t`.`Standards`, '') AS 'Global Account'
from global_ops_metrics_rejections_sub_v3 t
where t.`Region` = 'APAC'
and t.`Period` >= date_format(date_add(now(), interval -11 month), '%Y %m')
group by `_Type`, `_Metric`, `Country`, `_Owner`, `Business Line`, `Program`, `_Standards`, `Period`, `Global Account`)
union all
# ARG Performance and Backlog
(select 
	t.`_Type`, 
	t.`_Metric`, 
	t.`Business Line`,
	t.`Country`,
	t.`_Owner` as '__Owner', # t.`_Owner`,
	t.`Program`,
	t.`Standards` as '_Standards', #t.`Standards`,
	t.`Period`, 
    sum(t.`Volume`) as 'Volume',
    sum(t.`Sum Value`) as 'Sum Value',
    sum(t.`Volume within SLA`) as 'Volume within SLA',
    t.`Target`,
    group_concat(t.`Items`) as 'Items', # group_concat(t.`Items`) as 'Items',
    '' as 'Auto-Approved',
    '' as 'With-Hold',
    '' as 'With TR',
    '' as 'With Waiting Client',
    '' as 'Open_Sub_Status',
    getGlobalAccount(`t`.`Standards`, '') AS 'Global Account'
from global_ops_arg_performance t
where t.`Region` = 'APAC' 
and t.`Standards` is not null
and (t.`Period` >= date_format(date_add(now(), interval -11 month), '%Y %m') or t.`Period` is null)
group by t.`_Type`, t.`_Metric`, t.`Country`, `__Owner`, t.`Business Line`, t.`Program`, `_Standards`, t.`Target`, t.`Period`, `Global Account`
)
union all
# ARG end-to-end process
(select 
	'Performance' as '_Type',
	t.`_Metric`, 
	t.`Business Line`,
	substring_index(t.`Country`, ' - ',-1) as '_Country',
	'' as '_Owner',
	t.`Program`,
	'' as '_Standards', #t.`Standards`,
	t.`Period`,
	sum(t.`Volume`) as 'Volume',
	sum(`Sum Value`) as 'Sum Value',
	null as 'Volume within SLA',
	null as 'Target',
	'' as 'Items', #group_concat(t.`Items`) as 'Items',
    t.`Auto-Approved`,
	t.`With Hold`,
    t.`With TR`,
    t.`With Waiting Client`,
    '' as 'Open_Sub_Status',
    getGlobalAccount(`t`.`Standards`, '') AS 'Global Account'
from global_ops_metric_arg_end_to_end_1_v3_2 t
where t.`Region` = 'APAC'
and t.`Period` >= date_format(date_add(now(), interval -11 month), '%Y %m')
and (t.`Country` like 'Australia' or t.`Country` like 'Asia%' or t.`Country` like '%Product%')
group by `_Type`, t.`_Metric`, `_Country`, `_Owner`, `Business Line`, `Program`, `_Standards`, `Target`, `Period`, `Auto-Approved`, `With Hold`, `With TR`, `Global Account`)
union all
(select 
	'Performance' as '_Type',
	'ARG End-to-End'as '_Metric', 
	t.`Business Line`,
	substring_index(t.`Country`, ' - ',-1) as '_Country',
	'' as '_Owner',
	t.`Program`,
	'' as '_Standards', #t.`Standards`,
	t.`Period`,
    sum(t.`Volume`) as 'Volume',
	sum(t.`Sum Value`) as 'Sum Value',
	sum(if(t.`Sum Value`<=if(t.`Auto-Approved`,7,21),1,0)) as 'Volume within SLA',
	if(t.`Auto-Approved`,7,21) as 'Target',
    '' as 'Items', # group_concat(distinct t.`Items`) as 'Items',
    t.`Auto-Approved`,
    t.`With Hold`,
    t.`With TR`,
    t.`With Waiting Client`,
    '' as 'Open_Sub_Status',
    getGlobalAccount(`t`.`Standards`, '') AS 'Global Account'
from global_ops_metric_arg_end_to_end_2_v3_2 t
where t.`Region` = 'APAC'
and t.`Period` >= date_format(date_add(now(), interval -11 month), '%Y %m')
and (t.`Country` like 'Australia' or t.`Country` like 'Asia%' or t.`Country` like '%Product%')
group by `_Type`, `_Metric`, `_Country`, `_Owner`, `Business Line`, `Program`, `_Standards`, `Target`, `Period`, `Auto-Approved`, `With Hold`, `With TR`, `Global Account`)
union all
#Auditor utilisation
(SELECT 
	'Performance' as '_Type',
	'Resource Utilisation' as '_Metric',
	'n/a' as 'Business Line',
	i.`Country`,
    #if(i.`Business Unit` like '%Product%', 'Product Services', if(i.`Business Unit` like 'AUS%', 'Australia', substring_index(i.`Business Unit`,'-',-1))) as 'Country',
	i.`Name` as '_Owner',
	'' as 'Program',
	'' as '_Standards',
	i.`Period` as 'Period',
	(j.`Working Days`-(i.`Holiday Days`+i.`Leave Days`))*i.`Resource Capacitiy (%)`/100 as 'Volume',
	i.`Audit Days`+i.`Travel Days` as 'Sum Value',
	if((i.`Audit Days`+i.`Travel Days`)/((j.`Working Days`-(i.`Holiday Days`+i.`Leave Days`))*i.`Resource Capacitiy (%)`/100)>=0.8,1,0) as 'Volume within SLA',
	0.8 as 'Target',
	'' as 'Items'    ,
	'' as 'Auto-Approved',
	'' as 'With-Hold',
    '' as 'With TR',
    '' as 'With Waiting Client',
    '' as 'Open_Sub_Status',
    '' as 'Global Account'
FROM analytics.global_ops_metrics_sub1_v3 i     
INNER JOIN analytics.global_ops_metrics_sub2 j ON i.Period = j.Period
WHERE j.`Working Days`> (i.`Holiday Days`+i.`Leave Days`)
and i.`Period` >= date_format(date_add(now(), interval -5 month), '%Y %m')
and i.`Period` <= date_format(date_add(now(), interval 6 month), '%Y %m')
and i.Region = 'APAC'
group by Id, i.Period)
union all
# Contractors vs FTEs 
(select 
	'Performance' as '_Type', 
	'Contractor Usage' as '_Metric',
	sp.Program_Business_Line__c as 'Business Line',
	if(wi.Revenue_Ownership__c like '%Product%', 'Product Services', if(wi.Revenue_Ownership__c like 'AUS%', 'Australia', substring_index(substring_index(wi.Revenue_Ownership__c,'-',2),'-',-1))) as 'Country',
	'' as '_Owner',
	p.Name as 'Program',
	'' as '_Standards', #sp.Standard_Service_Type_Name__c as 'Standards',
	date_format(wi.work_item_Date__c, '%Y %m') as 'Period',
	sum(wi.Required_Duration__c/8) as 'Volume',
	sum(if(r.Resource_Type__c='Contractor', wi.Required_Duration__c/8, 0)) as 'Sum Value',
	null as 'Volume within SLA',
	0.2 as 'Target',
	'' as 'Items', #ifnull(group_concat(distinct if(r.Resource_Type__c='Contractor', wi.Name, null)) ,'') as 'Items',
	'' as 'Auto-Approved',
	'' as 'With-Hold',
    '' as 'With TR',
    '' as 'With Waiting Client',
    '' as 'Open_Sub_Status',
    getGlobalAccount(sp.Standard_Service_Type_Name__c, '') AS 'Global Account'
from salesforce.work_item__c wi
inner join salesforce.resource__c r on wi.RAudit_Report_Author__c = r.Id
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
inner join salesforce.program__c p on sp.Program__c = p.Id
where
wi.IsDeleted = 0
and wi.Status__c not in ('Cancelled', 'Draft', 'Initiate Service', 'Budget')
and (wi.Revenue_Ownership__c like 'AUS%' or wi.Revenue_Ownership__c like 'Asia%')
and wi.Work_Item_Stage__c not in ('Product Update', 'Initial Project')
and wi.Work_Item_Date__c >= date_format(date_add(now(), interval -5 month), '%Y-%m-01')
and wi.Work_Item_Date__c < date_format(date_add(now(), interval 7 month), '%Y-%m-01')
group by `_Type`, `_Metric`, `Country`, `_Owner`, `Business Line`, `Program`, `_Standards`, `Target`, `Period`, `Global Account`)
union all
(select 
	'Backlog' as '_Type', 
	'Change Request' as '_Metric',
	p.Business_Line__c as 'Business Line',
	if(crb.Region like '%Product%','Product Services',if(crb.Region like 'AUS%','Australia', substring_index(crb.Region ,'-',-1))) as 'Country',
    '' as '_Owner',
	p.Name as 'Program',
	'' as '_Standards', #s.Name as 'Standards',
	'' as 'Period',
	count(distinct crb.Id) as 'Volume',
	sum(getBusinessDays(crb.`From`, utc_timestamp(), 'UTC')) as 'Sum Value', # Total Aging
	count(distinct if(getBusinessDays(crb.`From`, utc_timestamp(), 'UTC')<=getTargetARGApac('Change Request'),crb.Id,null)) as 'Volume within SLA',
	getTargetARGApac('Change Request') as 'Target',
	'' as 'Items', #ifnull(group_concat(distinct crb.Name) ,'') as 'Items',
	'' as 'Auto-Approved',
	'' as 'With-Hold',
    '' as 'With TR',
    '' as 'With Waiting Client',
    '' as 'Open_Sub_Status',
    getGlobalAccount(s.Name, '') AS 'Global Account'
from analytics.change_request_backlog_sub crb
inner join salesforce.change_request2__c cr on crb.Id = cr.Id
inner join salesforce.work_item__c wi on cr.Work_Item__c = wi.Id
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
inner join salesforce.standard__c s on sp.Standard__c = s.Id
inner join salesforce.program__c p on sp.Program__c = p.Id
where 
(crb.Region like 'AUS%' or crb.Region like 'Asia%')
group by `_Type`, `_Metric`, `Country`, `_Owner`, `Business Line`, `Program`, `_Standards`, `Target`, `Period`, `Global Account`)
union all
(select 
	'Performance' as '_Type', 
	'Change Request' as '_Metric',
	p.Business_Line__c as 'Business Line',
	if(crc.Region like '%Product%','Product Services', if(crc.Region like 'AUS%','Australia', substring_index(crc.Region ,'-',-1))) as 'Country',
    '' as '_Owner', #crc.Owner as '_Owner',
	p.Name as 'Program',
	'' as '_Standards', #s.Name as 'Standards',
	date_format(crc.`To`, '%Y %m') as 'Period',
	count(distinct crc.Id) as 'Volume',
	sum(getBusinessDays(crc.`From`, crc.`To`, 'UTC')) as 'Sum Value', # Total Processing Business Days
	count(distinct if(getBusinessDays(crc.`From`, crc.`To`, 'UTC')<=getTargetARGApac('Change Request'),crc.Id,null)) as 'Volume within SLA',
	getTargetARGApac('Change Request') as 'Target',
	'' as 'Items', #ifnull(group_concat(distinct crc.Name) ,'') as 'Items',
	'' as 'Auto-Approved',
	'' as 'With-Hold' ,
    '' as 'With TR',
    '' as 'With Waiting Client',
    '' as 'Open_Sub_Status',
    getGlobalAccount(s.Name, '') AS 'Global Account'
from analytics.change_request_completed_sub crc
inner join salesforce.change_request2__c cr on crc.Id = cr.Id
inner join salesforce.work_item__c wi on cr.Work_Item__c = wi.Id
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
inner join salesforce.standard__c s on sp.Standard__c = s.Id
inner join salesforce.program__c p on sp.Program__c = p.Id
where crc.`To` >= date_format(date_add(now(), interval -5 month), '%Y-%m-01')
and crc.`To` < date_format(date_add(now(), interval 7 month), '%Y-%m-01')
and (crc.Region like 'AUS%' or crc.Region like 'Asia%')
group by `_Type`, `_Metric`, `Country`, `_Owner`, `Business Line`, `Program`,`_Standards`, `Target`, `Period`, `Global Account`)
union all
(select 
	t.`Type` as '_Type', 
	t.`Metric` as '_Metric',
	t.`Business Line`,
	t.`Country`,
    '' as '_Owner',
	t.`Program`,
	'' as '_Standards',#t.`Standards`,
	t.`Period`,
	sum(t.`Volume`) as 'Volume',
	null as 'Sum Value', 
	sum(t.`Volume within SLA`) as 'Volume within SLA',
	null as 'Target',
	group_concat(t.`Items`) as 'Items',
	'' as 'Auto-Approved',
	'' as 'With-Hold' ,
    '' as 'With Waiting Client',
    '' as 'With TR',
    t.`Open_Sub_Status`,
    getGlobalAccount(`t`.`Standard`, '') AS 'Global Account'
from global_ops_scheduling_backlog t
where t.`Region` = 'APAC'
group by `_Type`, `_Metric`, `Country`, `_Owner`, `Business Line`, `Program`,`_Standards`, `Target`, `Period`, t.`Open_Sub_Status`, `Global Account`)
union all
# Confirmed by Confirmation Period
(select 
	t.`Type` as '_Type', 
	t.`Metric` as '_Metric',
	t.`Business Line`,
	t.`Country`,
    '' as '_Owner',
	t.`Program`,
	'' as '_Standards',#t.`Standards`,
	t.`Period`, # First Time WI is Confimred
	sum(t.`Volume`) as 'Volume', # WI Confirmed
	sum(t.`Sum Value`) as 'Sum Value', # Sum of Days from WI First Confirmed to WI Start Date
	sum(t.`Volume within SLA`) as 'Volume within SLA', # First Confirmations done 28 days or more before WI start date
	getTargetARGApac('Confirmed WI') as 'Target',
	'' as 'Items', # group_concat(t.`Items`) as 'Items',
	'' as 'Auto-Approved',
	'' as 'With-Hold' ,
    '' as 'With TR',
    '' as 'With Waiting Client',
    '' as 'Open_Sub_Status',
    getGlobalAccount(`t`.`Standard`, '') AS 'Global Account'
from global_ops_scheduling_performance_by_confirmed_period t
where t.`Region` = 'APAC'
and t.`Period` >= date_format(date_add(now(), interval -11 month), '%Y %m')
group by `_Type`, `_Metric`, `Country`, `_Owner`, `Business Line`, `Program`,`_Standards`, `Target`, `Period`, `Global Account`)
# Confirmed by Audit Period
union all
(select 
	t.`Type` as '_Type', 
	t.`Metric` as '_Metric',
	t.`Business Line`,
	t.`Country`,
    t.`Owner` as '_Owner', # Reporting Period 
	t.`Program`,
	'' as '_Standards',#t.`Standards`,
	t.`Period`,
	sum(t.`# Confirmed`) as 'Volume', # Confirmed in Period
	sum(t.`Days Confirmed to Start`) as 'Sum Value', # Avg Days Confirmed to Start
	sum(t.`Confirmed within SLA`) as 'Volume within SLA', # Confirmed within SLA (28 Days)
	sum(t.`# To Be Confirmed`) as 'Target', # # To Be Confirmed
	'' as 'Items', # group_concat(t.`Items`) as 'Items',
	'' as 'Auto-Approved',
	'' as 'With-Hold' ,
    '' as 'With TR',
    '' as 'With Waiting Client',
    t.`Open_Sub_Status`,
    getGlobalAccount(`t`.`Standard`, '') AS 'Global Account'
from global_ops_scheduling_performance_by_audit_period t
where t.`Region` = 'APAC'
and t.`Period` >= date_format(date_add(now(), interval -5 month), '%Y %m')
and t.`Period` <= date_format(date_add(now(), interval 6 month), '%Y %m')
group by `_Type`, `_Metric`, `Country`, `_Owner`, `Business Line`, `Program`,`_Standards`, `Period`, `Global Account`, `Open_Sub_Status`)
union all
# Confirmed vs. Target
(select 
	t.`Type` as '_Type', 
	'Confirmed by Audit Period vs Target' as '_Metric',
	t.`Business Line`,
	t.`Country`,
    '' as '_Owner',
	t.`Program`,
	'' as '_Standards',#t.`Standards`,
	t.`Target Period` as `_Period`,
	sum(t.`# Confirmed`) as 'Volume', # Confirmed in Period
	sum(t.`# To Be Confirmed`) as 'Sum Value', # Not Confirmed in Period
	sum(t.`Confirmed within SLA`) as 'Volume within SLA', # n/a
	if((`t`.`Target Period` = DATE_FORMAT((NOW() + INTERVAL -(1) MONTH), '%Y %m')),
            1,
            IF((`t`.`Target Period` = DATE_FORMAT(NOW(), '%Y %m')),
                0.95,
                IF((`t`.`Target Period` = DATE_FORMAT((NOW() + INTERVAL 1 MONTH), '%Y %m')),
                    0.8,
                    IF((`t`.`Target Period` = DATE_FORMAT((NOW() + INTERVAL 2 MONTH), '%Y %m')),
                        0.7,
                        IF((`t`.`Target Period` = DATE_FORMAT((NOW() + INTERVAL 3 MONTH), '%Y %m')),
                            0.5,
                            IF((`t`.`Target Period` = DATE_FORMAT((NOW() + INTERVAL 4 MONTH), '%Y %m')),
                                0.2,
                                IF((`t`.`Target Period` = DATE_FORMAT((NOW() + INTERVAL 5 MONTH), '%Y %m')),
                                    0.1,
                                    IF((`t`.`Target Period` = DATE_FORMAT((NOW() + INTERVAL 6 MONTH), '%Y %m')),
                                        0.05,
                                        0)))))))) AS `Target`,
	'' as 'Items', # group_concat(t.`Items`) as 'Items',
	'' as 'Auto-Approved',
	'' as 'With-Hold' ,
    '' as 'With TR',
    '' as 'With Waiting Client',
    '' as 'Open_Sub_Status',
    getGlobalAccount(`t`.`Standard`, '') AS 'Global Account'
from global_ops_scheduling_performance_by_audit_period t
where t.`Region` = 'APAC'
and t.`Target Period` >= date_format(date_add(now(), interval -1 month), '%Y %m')
and t.`Target Period` <= date_format(date_add(now(), interval 6 month), '%Y %m')
group by `_Type`, `_Metric`, `Country`, `_Owner`, `Business Line`, `Program`,`_Standards`, `Target`, `_Period`, `Global Account`)
union all
# Scheduling Rework
(select 
	t.`Type` as '_Type', 
	t.`Metric` as '_Metric',
	t.`Business Line`,
	t.`Country`,
    if(t.`# Scheduled`=1, 'Scheduled Once',
		if(t.`# Scheduled`=2, 'Scheduled Twice',
			if(t.`# Scheduled`=3, 'Scheduled Thrice',
				'Scheduled 4 more times'
			)
		)
    ) as '_Owner',
	t.`Program`,
	'' as '_Standards',#t.`Standards`,
	t.`Period`, # Audit Period
	count(distinct t.`Items`) as 'Volume', # WI in Period
	sum(t.`# Scheduled`) as 'Sum Value', # Scheduled
	0 as 'Volume within SLA', 
	0 as 'Target',
	group_concat(t.`Items`) as 'Items',
	'' as 'Auto-Approved',
	'' as 'With-Hold' ,
    '' as 'With TR',
    '' as 'With Waiting Client',
    '' as 'Open_Sub_Status',
    getGlobalAccount(`t`.`Standard`, '') AS 'Global Account'
from global_ops_scheduling_performance_rework t
where t.`Region` = 'APAC'
and t.`Period` >= date_format(date_add(now(), interval -5 month), '%Y %m')
and t.`Period` <= date_format(date_add(now(), interval 6 month), '%Y %m')
group by `_Type`, `_Metric`, `Country`, `_Owner`, `Business Line`, `Program`,`_Standards`, `Target`, `Period`, `Global Account`);

lock tables sla_arg_v2 WRITE, apac_ops_metrics_v4 WRITE;
(select * from apac_ops_metrics_v4);
unlock tables;