DELIMITER $$
CREATE FUNCTION `getTargetARGGlobal`(Metric VARCHAR(64), Region ENUM('APAC', 'EMEA', 'AMERICAs')) RETURNS int(11)
BEGIN
	DECLARE target INTEGER DEFAULT null;
    SET target = (SELECT 
		if(Metric in ('Change Request'), 5,
		if(Metric in ('ARG Process Time (BRC)'), 30,
		if(Metric in ('ARG Process Time (Other)'), 15,
        if(Metric in ('ARG Process Time (technical-approved)'), 21,
        if(Metric in ('ARG Process Time (auto-approved)'), 7,
		if(Metric in ('ARG Completion/Hold'), 5,
		if(Metric in ('ARG Revision - Resubmission'), 2,
		if(Metric in ('ARG Revision - First'), 5,
		if(Metric in ('ARG Submission - Resubmission'), 2,
		if(Metric in ('ARG Submission - First'), 5,
		if(Metric in ('ARG Submission - Unsubmitted WI'), 5,
        if(Metric in ('ARG Submission - Waiting On Client'), 30,
		if(Metric in ('ARG Submission - Submitted WI No ARG'), 5, null))))))))))))));
        
    RETURN target;
 END$$
DELIMITER ;

DELIMITER $$
CREATE FUNCTION `getRegionFromReportingBusinessUnit`(rbu VARCHAR(256)) RETURNS VARCHAR(256)
BEGIN
	DECLARE region VARCHAR(256) DEFAULT null;
    SET region = (SELECT if (rbu like '%EMEA%', 'EMEA', 'APAC'));
		
    RETURN region;
 END$$
DELIMITER ;

drop function getBUFromReportingBusinessUnit;
DELIMITER $$
CREATE FUNCTION `getBUFromReportingBusinessUnit`(rbu VARCHAR(256)) RETURNS VARCHAR(256)
BEGIN
	DECLARE bu VARCHAR(256) DEFAULT null;
    SET bu = (SELECT 
		if(rbu like '%Product%', 'Product Services', if(rbu like 'AUS%' or rbu like 'ASS%' or rbu like '%AMERICAS%' or (rbu like '%MS%' and rbu not in ('EMEA-MS','MS-EMEA')), 
			'Australia', 
            #if(rbu like 'ASS%', 'Corporate', 
				if (rbu in ('EMEA-MS','MS-EMEA'), 'UK', substring_index(rbu,'-',-1))) )
			#)
        );
	#SET bu = (SELECT 
	#	if(rbu like '%Product%', 
	#		'Product Services', 
	#		if(rbu like 'AUS%', 
	#			'Australia', 
	#			if (rbu like 'EMEA-%' or rbu like 'Asia-%', 
	#				substring_index(rbu,'-',-1),
    #                rbu
    #            )
	#		)
	#	)
	#);	
    RETURN bu;
 END$$
DELIMITER ;

create or replace view global_ops_metrics_sub11_v3 as 
(SELECT getRegionFromReportingBusinessUnit(r.Reporting_Business_Units__c) as 'Region', getBUFromReportingBusinessUnit(r.Reporting_Business_Units__c) as 'Country',  r.Id, r.Name, r.Resource_Target_Days__c, r.Resource_Capacitiy__c, r.Resource_Type__c, r.Work_Type__c, r.Reporting_Business_Units__c, m.Name as 'Manager', rt.Name AS 'Type', IF(wir.Work_Item_Type__c IS NULL, bop.Resource_Blackout_Type__c, wir.Work_Item_Type__c) AS 'SubType', e.DurationInMinutes AS 'DurationMin', e.DurationInMinutes / 60 / 8 AS 'DurationDays', e.ActivityDate 
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
    AND r.Reporting_Business_Units__c NOT IN ('AUS-CSC' , 'AUS-MGT', 'AUS-OPS')
    AND r.Active_User__c = 'Yes'             
	AND r.Resource_Type__c = 'Employee'             
	AND r.Resource_Capacitiy__c IS NOT NULL             
	AND r.Resource_Capacitiy__c >= 30             
	AND (e.IsDeleted = 0 OR e.Id IS NULL));
                
create or replace view global_ops_metrics_sub1_v3 as 
(SELECT                       
t.Region, t.Country, t.Id, t.Resource_Type__c, t.Name, t.Resource_Capacitiy__c as 'Resource Capacitiy (%)', t.Reporting_Business_Units__c as 'Business Unit', t.Manager, DATE_FORMAT(t.ActivityDate, '%Y %m') AS 'Period', SUM(IF(t.SubType = 'Audit', t.DurationDays, 0)) AS 'Audit Days', SUM(IF(t.SubType = 'Travel', t.DurationDays, 0)) AS 'Travel Days', SUM(IF(t.SubType = 'Public Holiday', t.DurationDays, 0)) AS 'Holiday Days', SUM(IF(t.SubType LIKE 'Leave%', t.DurationDays, 0)) AS 'Leave Days', SUM(IF(t.SubType not like 'Leave%' and t.Subtype not in ('Audit','Travel','Public Holiday'), t.DurationDays,0)) as 'Other BOPs',GROUP_CONCAT(DISTINCT IF(t.SubType not like 'Leave%' and t.Subtype not in ('Audit','Travel','Public Holiday'), t.Subtype ,null)) as 'Other BOP Types'     
FROM global_ops_metrics_sub11_v3 t     
GROUP BY `Period` , t.Id);

create or replace view global_ops_metrics_sub2 as                 
(SELECT DATE_FORMAT(wd.date, '%Y %m') AS 'Period', COUNT(wd.date) AS 'Working Days' 
FROM salesforce.`sf_working_days` wd 
#WHERE
#	DATE_FORMAT(wd.date, '%Y %m') >= '2015 07' AND DATE_FORMAT(wd.date, '%Y %m') <= '2016 06'
GROUP BY `Period`);
                
create or replace view global_ops_metric_arg_end_to_end_1_v3 as 
(select 
	arg.Id,
	if(arg.`Metric` in ('ARG Submission - First','ARG Submission - Resubmission'), 'Delivery (Days)', 
		if(arg.`Metric` in ('CA Revision'),'Technical CA (Days)',
			if(arg.`Metric` in ('TR Revision'),'Technical TR (Days)',
				if(arg.`Metric` in ('ARG Completion/Hold'), 'Admin (Days)', 
					if(arg.`Metric` in ('ARG Hold'),'Hold (Days)','Waiting Client (Days)'))))) as '_Metric', 
arg_orig.Client_Ownership__c as 'Country',
if (arg_orig.Client_Ownership__c like 'EMEA%', 'EMEA', 'APAC') as 'Region',
date_format((select max(`To`) from analytics.sla_arg_v2 where Id=arg_orig.Id), '%Y %m')  as 'Period',
if((select count(`Id`) from analytics.sla_arg_v2 where Id=arg_orig.Id)=2,TRUE,FALSE)  as 'Auto-Approved',
if((select count(t3.`Id`) from analytics.sla_arg_v2 t3 where t3.Id=arg_orig.Id and t3.`Metric`='ARG Hold')=1,TRUE,FALSE)  as 'With Hold',
if((select count(t3.`Id`) from analytics.sla_arg_v2 t3 where t3.Id=arg_orig.Id and t3.`Metric`='TR Revision')>0,TRUE,FALSE)  as 'With TR',
if((select count(t3.`Id`) from analytics.sla_arg_v2 t3 where t3.Id=arg_orig.Id and t3.`Metric`='ARG Submission - Waiting On Client')>0,TRUE,FALSE)  as 'With Waiting Client',
count(distinct arg.Id) as 'Volume',
sum(timestampdiff(second, arg.`From`, arg.`To`)/3600/24) as 'Sum Value',
group_concat(distinct arg_orig.Name) as 'Items',
arg.`Standard Families` as 'FoS'
from salesforce.audit_report_group__c arg_orig 
left join analytics.sla_arg_v2 arg on arg_orig.Id = arg.Id
where
arg_orig.Audit_Report_Status__c = 'Completed'
and arg_orig.IsDeleted = 0
and arg_orig.Work_Item_Stages__c not like ('%Product Update%')
and arg_orig.Work_Item_Stages__c not like ('%Initial Project%')
and arg.`Metric` in ('ARG Submission - First','ARG Submission - Resubmission', 'CA Revision', 'TR Revision','ARG Completion/Hold', 'ARG Hold', 'ARG Submission - Waiting On Client')
group by arg_orig.Id, `_Metric`);

create or replace view global_ops_metric_arg_end_to_end_1_v3_2 as
(select t.`Id`,  t.`_Metric`, p.Business_Line__c as 'Business Line', t.`Country`, t.`Region`, p.Name as 'Program', s.Name as 'Standards', t.`FoS`, t.`Period`, t.`Auto-Approved`, t.`With Hold`, t.`Volume`, t.`Sum Value`, t.`Items`, t.`With TR`, t.`With Waiting Client`
from global_ops_metric_arg_end_to_end_1_v3 t
left join salesforce.arg_work_item__c argwi on argwi.RAudit_Report_Group__c = t.Id and argwi.IsDeleted = 0
left join salesforce.work_item__c wi on argwi.RWork_Item__c = wi.Id and wi.IsDeleted = 0
left join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
left join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
left join salesforce.standard__c s on sp.Standard__c = s.Id
left join salesforce.program__c p on sp.Program__c = p.Id
group by t.`Id`,  t.`_Metric`);

create or replace view global_ops_metric_arg_end_to_end_2_v3 as
(select 
	arg_completed.Id as 'Id',
	arg_completed.Client_Ownership__c as 'Country',
    if (arg_completed.Client_Ownership__c like 'EMEA%', 'EMEA', 'APAC') as 'Region',
	null as 'Owner',
	date_format(max(arg.`To`), '%Y %m')  as 'Period',
	count(distinct arg.Id) as 'Volume',
    if(group_concat(arg.`Metric`) like '%ARG Hold%', TRUE, FALSE) as 'With Hold',
    if(group_concat(arg.`Metric`) like '%TR Revision%', TRUE, FALSE) as 'With TR',
    if(group_concat(arg.`Metric`) like '%Waiting On Client%', TRUE, FALSE) as 'With Waiting Client',
	sum(timestampdiff(second, arg.`From`, arg.`To`)/3600/24) as 'Sum Value',
	if(count(arg.Id)=1,1, 0) as 'Auto-Approved',
    group_concat(distinct arg_completed.Name) as 'Items',
    arg.`Standard Families` as 'FoS',
    arg_completed.Work_Item_Stages__c 
from salesforce.audit_report_group__c arg_completed
left join analytics.sla_arg_v2 arg on arg_completed.Id = arg.Id
where
arg_completed.IsDeleted = 0
and arg_completed.Audit_Report_Status__c in ('Completed') 
and arg_completed.Work_Item_Stages__c not like ('%Product Update%')
and arg_completed.Work_Item_Stages__c not like ('%Initial Project%')
and arg.`Metric` in ('ARG Submission - First','ARG Submission - Resubmission', 'CA Revision', 'TR Revision','ARG Completion/Hold', 'ARG Hold', 'ARG Submission - Waiting On Client')
group by arg_completed.Id);

create or replace view global_ops_metric_arg_end_to_end_2_v3_2 as
(select t.`Id`,  p.Business_Line__c as 'Business Line', t.`Country`, t.`Region`, p.Name as 'Program', s.Name as 'Standards', t.`FoS`, t.`Period`, t.`Auto-Approved`, t.`With Hold`, t.`Volume`, t.`Sum Value`, t.`Items`, t.`With TR`, t.`With Waiting Client`, wi.Revenue_Ownership__c, t.Work_Item_Stages__c 
from global_ops_metric_arg_end_to_end_2_v3 t
left join salesforce.arg_work_item__c argwi on argwi.RAudit_Report_Group__c = t.Id and argwi.IsDeleted = 0
left join salesforce.work_item__c wi on argwi.RWork_Item__c = wi.Id and wi.IsDeleted = 0
left join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
left join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
left join salesforce.standard__c s on sp.Standard__c = s.Id
left join salesforce.program__c p on sp.Program__c = p.Id
group by t.Id);

#select r.Reporting_Business_Units__c, analytics.getRegionFromReportingBusinessUnit(r.Reporting_Business_Units__c) as 'Region', analytics.getBUFromReportingBusinessUnit(r.Reporting_Business_Units__c) as 'Country' from salesforce.resource__c r group by r.Reporting_Business_Units__c ;

create or replace view global_ops_metrics_rejections_sub_v3 as
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
	if(sp.Standard_Service_Type_Name__c like '%16949%',0.1,if(sp.Program_Business_Line__c like '%Food%', 0.1,0.08))as 'Target',
	ifnull(group_concat(distinct arg.Name) ,'') as 'Items', r.Resource_Type__c as 'Resource Type'
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
#and date_format(arg.CA_Approved__c, '%Y-%m') >= '2015-07'
group by arg.Id);

create or replace view global_ops_arg_performance as
select t.* from global_ops_arg_performance_sub t
where 
(t.Audit_Report_Status__c not in ('Cancelled') or t.Audit_Report_Status__c  is null)
and (t.IsDeleted = 0 or t.IsDeleted is null);

create or replace view global_ops_arg_performance_sub as
(select 
arg.Id,
arg_orig.IsDeleted, arg_orig.Audit_Report_Status__c, 
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
ifnull(p.business_line__c, p2.business_line__c) as 'Business Line',
if(r.Reporting_Business_Units__c is null,
	if(arg.Region like '%Product%', 'Product Services', if(arg.Region like 'ASS%' or arg.Region like 'AUS%' or arg.Region like '%AMERICAS%', 'Australia', substring_index(substring_index(arg.Region,'-',2),'-',-1))) ,
	getBUFromReportingBusinessUnit(r.Reporting_Business_Units__c ) 
    #if(r.Reporting_Business_Units__c like '%Product%', 'Product Services', if(r.Reporting_Business_Units__c like 'AUS%', 'Australia', substring_index(r.Reporting_Business_Units__c,'-',-1))) 
) as 'Country',
if(r.Reporting_Business_Units__c is null,
	if(arg.Region like '%EMEA%', 'EMEA', 'APAC'),
	getRegionFromReportingBusinessUnit(r.Reporting_Business_Units__c )
    #if(r.Reporting_Business_Units__c like '%AMERICAS%' or r.Reporting_Business_Units__c like 'ASS%' or r.Reporting_Business_Units__c like 'AUS%' or r.Reporting_Business_Units__c like 'Asia%', 'APAC', 'EMEA')
) as 'Region',

arg.`Owner` as '_Owner',
ifnull(p.Name, p2.name) as 'Program',
ifnull(s.Name, s2.Name) as 'Standards',
arg.`Standard Families` as 'FoS',
date_format(arg.`To`, '%Y %m')  as 'Period',
1 as 'Volume',
analytics.getBusinessDays(arg.`From`, ifnull(arg.`To`, utc_timestamp()), arg.`TimeZone`) as 'Sum Value',
if(analytics.getBusinessDays(arg.`From`, ifnull(arg.`To`, utc_timestamp()), arg.`TimeZone`)<=getTargetARGGlobal(arg.`Metric`, null),1,0) as 'Volume within SLA',
getTargetARGGlobal(arg.`Metric`, null) as 'Target',
arg.Name as 'Items',
null as 'Auto-Approved',
null as 'With-Hold'
from analytics.sla_arg_v2 arg 
left join salesforce.audit_report_group__c arg_orig on arg.Id = arg_orig.Id
left join salesforce.Resource__c r on arg.`Owner` = r.Name
left join salesforce.arg_work_item__c argwi on argwi.RAudit_Report_Group__c = arg.Id and argwi.IsDeleted = 0
left join salesforce.work_item__c wi on argwi.RWork_Item__c = wi.Id and wi.IsDeleted = 0
left join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
left join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
left join salesforce.standard__c s on sp.Standard__c = s.Id
left join salesforce.program__c p on sp.Program__c = p.Id
left join salesforce.work_item__c wi2 on arg.Id = wi2.Id and wi2.IsDeleted = 0
left join salesforce.site_certification_standard_program__c scsp2 on wi2.Site_Certification_Standard__c = scsp2.Id
left join salesforce.standard_program__c sp2 on scsp2.Standard_Program__c = sp2.Id
left join salesforce.standard__c s2 on sp2.Standard__c = s2.Id
left join salesforce.program__c p2 on sp2.Program__c = p2.Id

where
#(date_format(arg.`To`, '%Y-%m') >= '2015-07' or arg.`To` is null) and 
arg.Tags not like '%Product Update' 
and arg.Tags not like '%Initial Project'
and arg.`Metric` not in ('ARG Process Time (BRC)', 'ARG Process Time (Other)', 'CA Revision', 'TR Revision')
group by `_Type`, `_Metric`, arg.Id
);

create or replace view global_ops_dummy_records as 
select 'Backlog' as 'Type','ARG Submission - Submitted WI No ARG' as 'Metric','Management Systems' as 'Business Line','UK' as 'Country', 'Dummy' as 'Owner', 'Quality Management' as 'Program', '9001:2008 | Certification' as 'Standards', 'Woolworths Quality Assurance Standard Liquor - V1 | Verification' as 'FoS', 'Woolworths' as 'Global Account', null as 'Period',0 as 'Volume',0 as 'Sum Value',0 as 'Volume within SLA',5 as 'Target','' as 'Items', null as 'Auto-Approved',null as 'With-Hold',null as 'With TR';

create or replace view global_ops_scheduling_backlog as 
(select 
'Backlog' as 'Type',
'Open WI' as 'Metric',
p.Business_Line__c as 'Business Line',
if (t.`Region` like 'EMEA%', 'EMEA', 'APAC') as 'Region',
if(t.`Region` like '%Product%', 'Product Services', if(t.`Region` like 'AUS%', 'Australia', substring_index(t.`Region`, ' - ',-1))) as 'Country',
p.Name as 'Program',
s.Name as 'Standard',
date_format(ifnull(wi.Service_Target_Date__c,wi.Work_Item_Date__c), '%Y %m') as 'Period',
count(distinct t.Id) as 'Volume',
count(distinct if(ifnull(wi.Service_Target_Date__c,wi.Work_Item_Date__c) > utc_timestamp(), t.Id, null)) as 'Volume within SLA',
group_concat(wi.Name) as 'Items' ,
replace(replace(wi.Open_Sub_Status__c, ' – ', ' '), '  ', ' ') as 'Open_Sub_Status'
from analytics.sla_scheduling_backlog t
left join salesforce.work_item__c wi on wi.Id = t.Id
left join salesforce.recordtype rt on wi.RecordTypeId = rt.Id
left join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
left join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
left join salesforce.standard__c s on sp.Standard__c = s.Id
left join salesforce.program__c p on sp.Program__c = p.Id
where 
t.`Activity` in ('Open W Substatus','Scheduled')
and wi.IsDeleted = 0
#and wi.Status__c not in ('Service Change')
and rt.Name = 'Audit'
group by wi.Id
);

create or replace view global_ops_scheduling_snapshot_dates as
select date_format(min(`Date`), '%Y-%m-%d') as `Date` from salesforce.sf_working_days where `Date` between date_format(date_add(utc_timestamp(), interval -4 month), '%Y-%m-01') and utc_timestamp() group by date_format(`Date`, '%Y-%m') union all select  date_format(utc_timestamp(), '%Y-%m-%d');

create or replace view global_ops_scheduling_performance_by_confirmed_period as
(select 
	'Performance' as 'Type',
	'Confirmed by Confirmed Period' as 'Metric',
	p.Business_Line__c as 'Business Line',
	trim(getRegionFromReportingBusinessUnit(sc.Operational_Ownership__c)) as 'Region',
	trim(getBUFromReportingBusinessUnit(sc.Operational_Ownership__c)) as 'Country',
    scheduler.name as 'Owner',
	scheduler.Reporting_Business_Units__c,
	sc.Operational_Ownership__c, 
	p.Name as 'Program',
	s.Name as 'Standard',
	date_format(min(wih.createdDate), '%Y %m') as 'Period',
	1 as 'Volume',
    timestampdiff(day, min(wih.CreatedDate), wi.work_item_Date__c) as 'Sum Value',
	if(timestampdiff(day, min(wih.CreatedDate), wi.work_item_Date__c)>=28,1,0) as 'Volume within SLA',
	group_concat(distinct wi.Name) as 'Items' 
from salesforce.work_item__c wi
	inner join salesforce.work_item__history wih on wih.ParentId = wi.Id
	left join salesforce.user u on wih.CreatedById = u.Id
	left join salesforce.resource__c scheduler on scheduler.User__c = u.Id
	inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
    inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
	inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
	inner join salesforce.standard__c s on sp.Standard__c = s.Id
	inner join salesforce.program__c p on sp.Program__c = p.Id
where
	wi.Status__c not in ('Cancelled')
    and wi.IsDeleted = 0
	and wih.Field = 'Status__c'
	and wih.NewValue in ('Confirmed', 'In Progress')
group by wi.Id);

create or replace view global_ops_scheduling_performance_by_audit_period as
(select 
	'Performance' as 'Type',
	'Confirmed by Audit Period' as 'Metric',
	p.Business_Line__c as 'Business Line',
	trim(getRegionFromReportingBusinessUnit(sc.Operational_Ownership__c)) as 'Region',
	trim(getBUFromReportingBusinessUnit(sc.Operational_Ownership__c)) as 'Country',
    scheduler.name as 'Owner',
	scheduler.Reporting_Business_Units__c,
    sc.Operational_Ownership__c,
    wi.Revenue_Ownership__c,
    p.Name as 'Program',
	s.Name as 'Standard',
	date_format(wi.Work_Item_Date__c, '%Y %m') as 'Period',
    date_format(wi.Service_target_date__c, '%Y %m') as 'Target Period',
	count(distinct if(wi.Status__c in ('Confirmed', 'In Progress', 'Submitted', 'Under Review', 'Under Review - Rejected', 'Support', 'Completed'), wi.Id, null)) as '# Confirmed',
    count(distinct if(wi.Status__c not in ('Confirmed', 'In Progress', 'Submitted', 'Under Review', 'Under Review - Rejected', 'Support', 'Completed'), wi.Id, null)) as '# To Be Confirmed', # To be confirmed
    timestampdiff(day, ifnull(max(if(wih.NewValue = 'Confirmed', wih.CreatedDate, null)), max(if(wih.NewValue = 'In Progress', wih.CreatedDate, null))), wi.work_item_Date__c) as 'Days Confirmed to Start',
    if(wi.Status__c in ('Confirmed', 'In Progress', 'Submitted', 'Under Review', 'Under Review - Rejected', 'Support', 'Completed') and timestampdiff(day, ifnull(max(if(wih.NewValue = 'Confirmed', wih.CreatedDate, null)), max(if(wih.NewValue = 'In Progress', wih.CreatedDate, null))), wi.work_item_Date__c)>=28,1,0) as 'Confirmed within SLA', # Confirmed within SLA
	group_concat(distinct wi.Name) as 'Items',
    if(wi.Status__c = 'Open', replace(replace(wi.Open_Sub_Status__c, ' – ', ' '), '  ', ' '), null) as 'Open_Sub_Status'
from salesforce.work_item__c wi
	inner join salesforce.recordtype rt on wi.RecordTypeId = rt.Id
	left join salesforce.work_item__history wih on wih.ParentId = wi.Id and wih.Field = 'Status__c' and wih.NewValue in ('Confirmed', 'In Progress')
	left join salesforce.user u on wih.CreatedById = u.Id
	left join salesforce.resource__c scheduler on scheduler.User__c = u.Id
	inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id 
    inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
	inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
	inner join salesforce.standard__c s on sp.Standard__c = s.Id
	inner join salesforce.program__c p on sp.Program__c = p.Id
where
	wi.Status__c not in ('Cancelled')
    and wi.IsDeleted = 0
    and scsp.Status__c in ('Registered','Applicant','Customised')
    and sc.Status__c = 'Active'
    and rt.Name not in ('Project')
group by wi.Id);

create or replace view global_ops_scheduling_performance_rework as
(select 
	'Performance' as 'Type',
	'Scheduling Rework' as 'Metric',
	p.Business_Line__c as 'Business Line',
	trim(getRegionFromReportingBusinessUnit(sc.Operational_Ownership__c)) as 'Region',
	trim(getBUFromReportingBusinessUnit(sc.Operational_Ownership__c)) as 'Country',
    sc.Operational_Ownership__c,
    wi.Revenue_Ownership__c,
    p.Name as 'Program',
	s.Name as 'Standard',
	date_format(wi.Work_Item_Date__c, '%Y %m') as 'Period',
	count(distinct wih.Id) as '# Scheduled',
    wi.Name as 'Items'
from salesforce.work_item__c wi
	inner join salesforce.recordtype rt on wi.RecordTypeId = rt.Id
	inner join salesforce.work_item__history wih on wih.ParentId = wi.Id and wih.Field = 'Status__c' and wih.NewValue in ('Scheduled')
	inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id 
    inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
	inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
	inner join salesforce.standard__c s on sp.Standard__c = s.Id
	inner join salesforce.program__c p on sp.Program__c = p.Id
where
	wi.Status__c not in ('Cancelled')
    and wi.IsDeleted = 0
    and scsp.Status__c in ('Registered','Applicant','Customised')
    and sc.Status__c = 'Active'
    and rt.Name not in ('Project')
group by wi.Id);

(select * from global_ops_scheduling_performance);


# Not Used
(select 
	'Performance' as 'Type',
	'Confirmed WI %' as 'Metric',
    '' as 'Business Line',
    analytics.getRegionFromCountry(if(rh.`Region` like 'Australia%', 'Australia', rh.`Region`) ) as 'Region2',
	trim(if(rh.`Region` like 'Australia%', 'Australia', rh.`Region`)) as 'Country',
    date_format(rh.`Date`, '%d/%m/%Y') AS 'Owner', # `Report Date`,
    '' as 'Reporting_Business_Units__c',
    '' as 'Scheduling_Ownership__c',
    '' as 'Program',
    '' as 'Standard',
    date_format(str_to_date(concat(rh.`ColumnName`,' 01'),'%Y %m %d'), '%Y %m') as 'Period',
    sum(if(trim(substring_index(rh.`RowName`,'-',-(1))) not in ('Open','Service Change') and trim(substring_index(rh.`RowName`,'-',-(1))) not like 'Scheduled%',
		cast(rh.`Value` as decimal(10,2)),0)) as 'Volume', #as 'Confirmed'
	sum(if(trim(substring_index(rh.`RowName`,'-',-(1))) in ('Open','Service Change') or trim(substring_index(rh.`RowName`,'-',-(1))) like 'Scheduled%',
		cast(rh.`Value` as decimal(10,2)),0)) as 'Sum Value', #'Not Confirmed'
    '' as 'Volume within SLA',
    '' as 'Items'
from `salesforce`.`sf_report_history` rh
inner join global_ops_scheduling_snapshot_dates rd on rd.`Date` = date_format(rh.`Date`,'%Y-%m-%d')
where 
rh.`ReportName` = 'Audit Days Snapshot'
and cast(rh.`Value` as decimal(10,2)) > 0
and rh.`Region` not like '%Product%'
and rh.`Region` not like '%Unknown%'
and rh.`RowName` like '%Audit%'
and rh.`RowName` like '%Days%'
and rh.`RowName` not like '%Pending%'
#and date_format(rh.`Date`,'%Y-%m-%d') in ()
and str_to_date(concat(rh.`ColumnName`,' 01'),'%Y %m %d') <= date_format(date_add(utc_timestamp(), interval 4 month), '%Y-%m-01')
and str_to_date(concat(rh.`ColumnName`,' 01'),'%Y %m %d') >= date_format(date_add(utc_timestamp(), interval -1 month), '%Y-%m-01')
#and analytics.getRegionFromCountry(if(rh.`Region` like 'Australia%', 'Australia', rh.`Region`) ) = 'APAC'
and trim(substring_index(rh.`RowName`,'-',-(1))) not in ('Cancelled')
group by `Region2`, `Country`, `Owner`, `Period`);