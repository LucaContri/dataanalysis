create or replace view global_auditors_metrics_summary as
#ARG rejection rate
(select
	t.`_Type`, 
	t.`_Metric`,
	t.`Business Line`,
	t.`Country`,
	t.`Owner` as 'Resource',
    t.`Resource Type`,
	t.`Program`,
	t.`Standards` as '_Standards', #t.`Standards`,
	t.`Period`,
	sum(t.`Volume`) as 'Volume',
	sum(t.`Sum Value`) as 'Sum Value', #distinct ah.Id means I am counting each rejection
	(sum(t.`Volume`) - sum(t.`Sum Value`)) as 'Volume within SLA',
	t.`Target`,
	ifnull(group_concat(t.`Items`),'') as 'Items', #ifnull(group_concat(t.`Items`),'') as 'Items',
	getGlobalAccount(`t`.`Standards`, '') AS 'Global Account'
from global_ops_metrics_rejections_sub_v3 t
where t.`Region` in ('APAC', 'EMEA')
and t.`Period` >= date_format(date_add(now(), interval -11 month), '%Y %m')
group by `_Type`, `_Metric`, `Country`, `Resource`, `Business Line`, `Program`, `_Standards`, `Period`, `Global Account`)
union all
# ARG Performance and Backlog
(select 
	t.`_Type`, 
	t.`_Metric`, 
	t.`Business Line`,
	t.`Country`,
	t.`_Owner` as '__Owner', # t.`_Owner`,
    r.Resource_Type__c as 'Resource Type',
	t.`Program`,
	t.`Standards` as '_Standards', #t.`Standards`,
	t.`Period`, 
    sum(t.`Volume`) as 'Volume',
    sum(t.`Sum Value`) as 'Sum Value',
    sum(t.`Volume within SLA`) as 'Volume within SLA',
    t.`Target`,
    group_concat(t.`Items`) as 'Items', # group_concat(t.`Items`) as 'Items',
    getGlobalAccount(`t`.`Standards`, '') AS 'Global Account'
from global_ops_arg_performance t
left join salesforce.resource__c r on t.`_Owner` = r.Name
where t.`Region` in ('APAC', 'EMEA')
and t.`_Type` = 'Performance'
and t.`_Metric` in ('Auditor First Submission (Days)', 'Auditor Re-Submission (Days)')
and t.`Standards` is not null
and (t.`Period` >= date_format(date_add(now(), interval -11 month), '%Y %m') or t.`Period` is null)
group by t.`_Type`, t.`_Metric`, t.`Country`, `__Owner`, t.`Business Line`, t.`Program`, `_Standards`, t.`Target`, t.`Period`, `Global Account`
)
union all
#Auditor utilisation
(SELECT 
	'Performance' as '_Type',
	'Resource Utilisation' as '_Metric',
	'n/a' as 'Business Line',
	i.`Country`,
    i.`Name` as '_Owner',
    i.Resource_Type__c as 'Resource Type',
	'' as 'Program',
	'' as '_Standards',
	i.`Period` as 'Period',
	(j.`Working Days`-(i.`Holiday Days`+i.`Leave Days`))*i.`Resource Capacitiy (%)`/100 as 'Volume',
	i.`Audit Days`+i.`Travel Days` as 'Sum Value',
	if((i.`Audit Days`+i.`Travel Days`)/((j.`Working Days`-(i.`Holiday Days`+i.`Leave Days`))*i.`Resource Capacitiy (%)`/100)>=0.8,1,0) as 'Volume within SLA',
	0.8 as 'Target',
    '' as 'Items',
    '' as 'Global Account'
FROM analytics.global_ops_metrics_sub1_v3 i     
INNER JOIN analytics.global_ops_metrics_sub2 j ON i.Period = j.Period
WHERE j.`Working Days`> (i.`Holiday Days`+i.`Leave Days`)
and i.`Period` >= date_format(date_add(now(), interval -5 month), '%Y %m')
and i.`Period` <= date_format(date_add(now(), interval 6 month), '%Y %m')
and i.Region in ('APAC', 'EMEA')
group by Id, i.Period);

lock tables sla_arg_v2 WRITE, global_auditors_metrics_summary WRITE;
(select * from global_auditors_metrics_summary);
unlock tables;