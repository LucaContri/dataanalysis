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
	ifnull(group_concat(distinct t.`Items`),'') as 'Items',
	'' as 'Auto-Approved',
	'' as 'With-Hold',
    '' as 'With TR',
    '' as 'With Waiting Client',
    '' as 'Open_Sub_Status',
    getGlobalAccount(t.`Standards`, '') AS 'Global Account'
from global_ops_metrics_rejections_sub_v3 t
where 
	t.`Region` = 'EMEA'
    and t.`Period` >= concat(if(month(utc_timestamp())<7, year(utc_timestamp()), year(utc_timestamp())+1)-1,' 07')
    and t.`Period` <= concat(if(month(utc_timestamp())<7, year(utc_timestamp()), year(utc_timestamp())+1),' 06')
group by `_Type`, `_Metric`, `Country`, `Owner`, `Standards`, `Period`)

union all
# ARG Performance and Backlog
(select 
	t.`_Type`, 
	t.`_Metric`, 
	t.`Business Line`,
	t.`Country`,
	t.`_Owner`,
	t.`Program`,
	t.`Standards`,
	t.`Period`, 
    sum(t.`Volume`) as 'Volume',
    sum(t.`Sum Value`) as 'Sum Value',
    sum(t.`Volume within SLA`) as 'Volume within SLA',
    t.`Target`,
    group_concat(distinct t.`Items`) as 'Items',
    '' as 'Auto-Approved',
    '' as 'With-Hold',
    '' as 'With TR',
    '' as 'With Waiting Client',
    '' as 'Open_Sub_Status',
    getGlobalAccount(t.`Standards`, '') AS 'Global Account'
from global_ops_arg_performance t
where t.`Standards` is not null
and t.`Region` = 'EMEA'
and (t.`Period` >= concat(if(month(utc_timestamp())<7, year(utc_timestamp()), year(utc_timestamp())+1)-1,' 07') or t.`Period` is null)
and (t.`Period` <= concat(if(month(utc_timestamp())<7, year(utc_timestamp()), year(utc_timestamp())+1),' 06') or t.`Period` is null)
group by t.`_Type`, t.`_Metric`, t.`Country`, t.`_Owner`, t.`Standards`, t.`Target`, t.`Period`)
union all
(select `Type`,`Metric`,`Business Line`, `Country`, `Owner`,`Program`, `Standards`, `Period`, `Volume`, `Sum Value`, `Volume within SLA`, `Target`, `Items`,`Auto-Approved`, `With-Hold`, `With TR`,'','','' from global_ops_dummy_records)
union all
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
	t.`With Hold`,
    t.`With TR`,
    t.`With Waiting Client`,
    '' as 'Open_Sub_Status',
    getGlobalAccount(t.`Standards`, '') AS 'Global Account'
from global_ops_metric_arg_end_to_end_1_v3_2 t
where t.`Period` >= concat(if(month(utc_timestamp())<7, year(utc_timestamp()), year(utc_timestamp())+1)-1,' 07')
and t.`Period` <= concat(if(month(utc_timestamp())<7, year(utc_timestamp()), year(utc_timestamp())+1),' 06')
and t.`Region` = 'Emea'
group by `_Type`, t.`_Metric`, `_Country`, `Owner`, `Standards`, `Target`, `Period`, `Auto-Approved`, `With Hold`, t.`With TR`)
union all
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
	sum(if(t.`Sum Value`<=if(t.`Auto-Approved`,7,if(t.`Standards` like '%BRC%',42,21)),1,0)) as 'Volume within SLA',
	if(t.`Auto-Approved`,7,21) as 'Target',
    group_concat(distinct t.`Items`) as 'Items',
    t.`Auto-Approved`,
    t.`With Hold`,
    t.`With TR`,
    t.`With Waiting Client`,
    '' as 'Open_Sub_Status',
    getGlobalAccount(t.`Standards`, '') AS 'Global Account'
from global_ops_metric_arg_end_to_end_2_v3_2 t
where t.`Period` >= concat(if(month(utc_timestamp())<7, year(utc_timestamp()), year(utc_timestamp())+1)-1,' 07')
and t.`Period` <= concat(if(month(utc_timestamp())<7, year(utc_timestamp()), year(utc_timestamp())+1),' 06')
and t.`Region` = 'Emea'
group by `_Type`, `_Metric`, `_Country`, `_Owner`, `Standards`, `Target`, `Period`, `Auto-Approved`, `With Hold`, t.`With TR`)

union all
#Auditor utilisation
(SELECT 
'Performance' as '_Type',
'Resource Utilisation' as '_Metric',
'n/a' as 'Business Line',
if(i.`Business Unit` like '%Product%', 'Product Services', if(i.`Business Unit` like 'AUS%', 'Australia', substring_index(i.`Business Unit`,'-',-1))) as 'Country',
i.`Name` as 'Owner',
'' as 'Program',
'' as 'Standards',
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
    '' AS 'Global Account'
FROM analytics.global_ops_metrics_sub1_v3 i     
INNER JOIN analytics.global_ops_metrics_sub2 j ON i.Period = j.Period
WHERE j.`Working Days`> (i.`Holiday Days`+i.`Leave Days`)
and i.`Period` >= concat(if(month(utc_timestamp())<7, year(utc_timestamp()), year(utc_timestamp())+1)-1,' 07')
and i.`Period` <= concat(if(month(utc_timestamp())<7, year(utc_timestamp()), year(utc_timestamp())+1),' 06')
and i.Region = 'EMEA'
group by Id, i.Period)

union all
# Contractors vs FTEs 
(select 
'Performance' as '_Type', 
'Contractor Usage' as '_Metric',
sp.Program_Business_Line__c as 'Business Line',
if(wi.Revenue_Ownership__c like '%Product%', 'Product Services', if(wi.Revenue_Ownership__c like 'AUS%', 'Australia', substring_index(substring_index(wi.Revenue_Ownership__c,'-',2),'-',-1))) as 'Country',
null as '_Owner',
p.Name as 'Program',
sp.Standard_Service_Type_Name__c as 'Standards',
date_format(wi.work_item_Date__c, '%Y %m') as 'Period',
sum(wi.Required_Duration__c/8) as 'Volume',
sum(if(r.Resource_Type__c='Contractor', wi.Required_Duration__c/8, 0)) as 'Sum Value',
null as 'Volume within SLA',
0.2 as 'Target',
ifnull(group_concat(distinct if(r.Resource_Type__c='Contractor', wi.Name, null)) ,'') as 'Items',
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
and wi.Revenue_Ownership__c like 'EMEA%'
and wi.Work_Item_Stage__c not in ('Product Update', 'Initial Project')
and wi.Work_Item_Date__c >= concat(if(month(utc_timestamp())<7, year(utc_timestamp()), year(utc_timestamp())+1)-1,'-07-01')
and wi.Work_Item_Date__c <= concat(if(month(utc_timestamp())<7, year(utc_timestamp()), year(utc_timestamp())+1),'-06-30')
group by `_Type`, `_Metric`, `Country`, `_Owner`, `Standards`, `Target`, `Period`)
union all
(select 
	'Backlog' as '_Type', 
	'Change Request' as '_Metric',
	p.Business_Line__c as 'Business Line',
	if(crb.Region like '%Product%','Product Services',if(crb.Region like 'AUS%','Australia', substring_index(crb.Region ,'-',-1))) as 'Country',
    null as '_Owner',
	p.Name as 'Program',
	s.Name as 'Standards',
	null as 'Period',
	count(distinct crb.Id) as 'Volume',
	sum(getBusinessDays(crb.`From`, utc_timestamp(), 'UTC')) as 'Sum Value', # Total Aging
	count(distinct if(getBusinessDays(crb.`From`, utc_timestamp(), 'UTC')<=getTargetARGGlobal('Change Request',null),crb.Id,null)) as 'Volume within SLA',
	getTargetARGGlobal('Change Request',null) as 'Target',
	ifnull(group_concat(distinct crb.Name) ,'') as 'Items',
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
crb.Region like 'EMEA%'
group by `_Type`, `_Metric`, `Country`, `_Owner`, `Standards`, `Target`, `Period`)
union all
(select 
	'Performance' as '_Type', 
	'Change Request' as '_Metric',
	p.Business_Line__c as 'Business Line',
	if(crc.Region like '%Product%','Product Services', if(crc.Region like 'AUS%','Australia', substring_index(crc.Region ,'-',-1))) as 'Country',
    crc.Owner as '_Owner',
	p.Name as 'Program',
	s.Name as 'Standards',
	date_format(crc.`To`, '%Y %m') as 'Period',
	count(distinct crc.Id) as 'Volume',
	sum(getBusinessDays(crc.`From`, crc.`To`, 'UTC')) as 'Sum Value', # Total Processing Business Days
	count(distinct if(getBusinessDays(crc.`From`, crc.`To`, 'UTC')<=getTargetARGGlobal('Change Request',null),crc.Id,null)) as 'Volume within SLA',
	getTargetARGGlobal('Change Request',null) as 'Target',
	ifnull(group_concat(distinct crc.Name) ,'') as 'Items',
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
where 
crc.`To` >= concat(if(month(utc_timestamp())<7, year(utc_timestamp()), year(utc_timestamp())+1)-1,'-07-01')
and crc.`To` <= concat(if(month(utc_timestamp())<7, year(utc_timestamp()), year(utc_timestamp())+1),'-06-30')
and crc.Region like 'EMEA%'
group by `_Type`, `_Metric`, `Country`, `_Owner`, `Standards`, `Target`, `Period`)
# Scheduling metrics
# Scheduling backlog
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
    '' as 'With TR',
    '' as 'With Waiting Client',
    t.`Open_Sub_Status`,
    analytics.getGlobalAccount(`t`.`Standard`, '') AS 'Global Account'
from global_ops_scheduling_backlog t
where t.`Region` = 'EMEA'
group by `_Type`, `_Metric`, `Country`, `_Owner`, `Business Line`, `Program`,`_Standards`, `Target`, `Period`, t.`Open_Sub_Status`, `Global Account`)

union all
# Confirmed by Audit Period
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
    analytics.getGlobalAccount(`t`.`Standard`, '') AS 'Global Account'
from global_ops_scheduling_performance_by_audit_period t
where t.`Region` = 'EMEA'
and t.`Period` >= concat(if(month(utc_timestamp())<7, year(utc_timestamp()), year(utc_timestamp())+1)-1,' 07') 
and t.`Period` <= concat(if(month(utc_timestamp())<7, year(utc_timestamp()), year(utc_timestamp())+1),' 06')
group by `_Type`, `_Metric`, `Country`, `_Owner`, `Business Line`, `Program`,`_Standards`, `Period`, `Global Account`, `Open_Sub_Status`);

lock tables sla_arg_v2 WRITE, emea_ops_metrics WRITE, sla_scheduling_backlog WRITE;
(select * from analytics.emea_ops_metrics);
unlock tables;
