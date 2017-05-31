set @standard = '%16949%';
set @period_from = '2015 01';
set @period_to = '2015 01';

#ARG rejection rate
(select
	t.`_Type`, 
	t.`_Metric`,
	t.`Business Line`,
	t.`Country`,
	t.`Owner`,
	t.`Program`,
	t.`Standards`,
    t.`Fos`,
    getGlobalAccount(t.`Standards`, t.`FoS`) as 'Global Account',
	t.`Period`,
	sum(t.`Volume`) as 'Volume',
	sum(t.`Sum Value`) as 'Sum Value', #distinct ah.Id means I am counting each rejection
	(sum(t.`Volume`) - sum(t.`Sum Value`)) as 'Volume within SLA',
	t.`Target`,
	ifnull(group_concat(distinct t.`Items`),'') as 'Items',
	null as 'Auto-Approved',
	null as 'With-Hold',
    null as 'With TR'
from global_ops_metrics_rejections_sub_v3 t
where
	t.`Period` >= @period_from
    and t.`Period` <= @period_to
	and t.`Standards` like @standard
group by t.`Id`,t.`_Type`, t.`_Metric`, t.`Country`, t.`Owner`, t.`Standards`, t.`Target`, t.`Period`
)
union
(select * from global_ops_dummy_records)
union
# ARG Performance and Backlog
(select 
	t.`_Type`, 
	t.`_Metric`, 
	t.`Business Line`,
	t.`Country`,
	t.`_Owner`,
	t.`Program`,
	t.`Standards`,
    t.`FoS`,
    getGlobalAccount(t.`Standards`, t.`FoS`) as 'Global Account',
	t.`Period`, 
    sum(t.`Volume`) as 'Volume',
    sum(t.`Sum Value`) as 'Sum Value',
    sum(t.`Volume within SLA`) as 'Volume within SLA',
    t.`Target`,
    group_concat(t.`Items`) as 'Items',
    t.`Auto-Approved`,
    t.`With-Hold`,
    null as 'With TR'
from global_ops_arg_performance t
where 
	((t.`Period` >= @period_from and t.`Period` <= @period_to) or t.`Period` is null)
    and t.`Standards` is not null
group by t.`Id`,t.`_Type`, t.`_Metric`, t.`Country`, t.`_Owner`, t.`Standards`, t.`Target`, t.`Period`)
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
    t.`Fos`,
    getGlobalAccount(t.`Standards`, t.`FoS`) as 'Global Account',
	t.`Period`,
	sum(t.`Volume`) as 'Volume',
	sum(`Sum Value`) as 'Sum Value',
	null as 'Volume within SLA',
	null as 'Target',
	group_concat(t.`Items`) as 'Items',
    t.`Auto-Approved`,
	t.`With Hold`,
    t.`With TR`
from global_ops_metric_arg_end_to_end_1_v3_2 t
where 
	t.`Period` >= @period_from
    and t.`Period` <= @period_to
	and t.`Standards` like @standard
group by t.`Id`,`_Type`, t.`_Metric`, `_Country`, `Owner`, `Standards`, `Target`, `Period`, `Auto-Approved`, `With Hold`, `With TR`)
union
(select 
	'Performance' as '_Type',
	'ARG End-to-End'as '_Metric', 
	t.`Business Line`,
	substring_index(t.`Country`, ' - ',-1) as '_Country',
	null as '_Owner',
	t.`Program`,
	t.`Standards`,
    t.`Fos`,
    getGlobalAccount(t.`Standards`, t.`FoS`) as 'Global Account',
	t.`Period`,
    sum(t.`Volume`) as 'Volume',
	sum(t.`Sum Value`) as 'Sum Value',
	sum(if(t.`Sum Value`<=if(t.`Auto-Approved`,7,21),1,0)) as 'Volume within SLA',
	if(t.`Auto-Approved`,7,21) as 'Target',
    group_concat(distinct t.`Items`) as 'Items',
    t.`Auto-Approved`,
    t.`With Hold`,
    t.`With TR`
from global_ops_metric_arg_end_to_end_2_v3_2 t
where 
	t.`Period` >= @period_from
    and t.`Period` <= @period_to
	and t.`Standards` like @standard
group by t.`Id`, `_Type`, `_Metric`, `_Country`, `_Owner`, `Standards`, `Target`, `Period`, `Auto-Approved`, `With Hold`, `With TR`);


# Rejections Details
(select
	arg.Id as 'Id',
	'Performance' as '_Type', 
	'ARG rejection rate' as '_Metric',
	sp.Program_Business_Line__c as 'Business Line',
    analytics.getRegionFromReportingBusinessUnit(r.Reporting_Business_Units__c) as 'Region', 
    #if (r.Reporting_Business_Units__c like 'AUS%' or r.Reporting_Business_Units__c like 'Asia%' or r.Reporting_Business_Units__c like 'ASS%' or r.Reporting_Business_Units__c like 'MS%' or r.Reporting_Business_Units__c like 'AMERICA%', 'APAC', 'EMEA') as 'Region',
    r.Reporting_Business_Units__c,
	analytics.getBUFromReportingBusinessUnit(r.Reporting_Business_Units__c) as 'Country', 
    #if (r.Reporting_Business_Units__c like '%Product%', 'Product Services', if(r.Reporting_Business_Units__c like 'AUS%' or r.Reporting_Business_Units__c like 'ASS%' or r.Reporting_Business_Units__c like 'MS%' or r.Reporting_Business_Units__c like 'AMERICA%', 'Australia', substring_index(r.Reporting_Business_Units__c,'-',-1))) as 'Country',
	r.Name as 'Owner',
	p.Name as 'Program',
	sp.Standard_Service_Type_Name__c as 'Standards',
    group_concat(distinct if(scsf.isDeleted=0 and spf.IsDeleted=0, spf.Standard_Service_Type_Name__c,null)) as 'FoS',
	date_format(arg.CA_Approved__c, '%Y %m')  as 'Period',
	count(distinct arg.Id) as 'Volume',
	count(distinct if(ah.Status__c='Rejected', ah.Id, null)) as 'Sum Value', #distinct ah.Id means I am counting each rejection
    group_concat(distinct ah.Rejection_Reason__c) as 'Rejection Reasons',
	if(sp.Standard_Service_Type_Name__c like '%16949%',0.1,if(sp.Program_Business_Line__c like '%Food%', 0.1,0.08))as 'Target',
	ifnull(group_concat(distinct arg.Name) ,'') as 'Items'
from salesforce.approval_history__c ah 
inner join salesforce.audit_report_group__c arg on arg.Id = ah.RAudit_Report_Group__c
inner join salesforce.resource__c r on arg.RAudit_Report_Author__c = r.Id
inner join salesforce.arg_work_item__c argwi on argwi.RAudit_Report_Group__c = arg.Id
inner join salesforce.work_item__c wi on argwi.RWork_Item__c = wi.Id
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
inner join salesforce.program__c p on sp.Program__c = p.Id
left join salesforce.site_certification_standard_family__c scsf on scsf.Site_Certification_Standard__c = scsp.Id
left join salesforce.standard_program__c spf on scsf.Standard_Program__c = spf.Id
where 
arg.IsDeleted = 0
and wi.Work_Item_Stage__c not in ('Product Update', 'Initial Project')
and ah.IsDeleted = 0
and date_format(arg.CA_Approved__c, '%Y %m') >= @period_from
and date_format(arg.CA_Approved__c, '%Y %m') <= @period_to
and sp.Standard_Service_Type_Name__c like @standard
group by arg.Id);