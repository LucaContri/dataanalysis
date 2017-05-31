drop table `standards_targets`; 
CREATE TABLE `standards_targets` (
  `id` int(11) NOT NULL auto_increment,
  `standard__c` varchar(18) NOT NULL,
  `metric` enum('ARG Submission - Unsubmitted WI','ARG Submission - First','ARG Submission - Resubmission','ARG Revision - First','ARG Revision - Resubmission','ARG Completion/Hold','ARG Hold','Overall Process') NOT NULL,
  `team` enum ('Delivery', 'Technical', 'Admin') default null,
  `end_of_process` enum('ARG Completion', 'ARG Approval', 'ARG Submission') default null,
  `target_green` decimal(10,6) not null,
  `target_red` decimal(10,6) not null,
  `uom` enum('Working Days', 'Calendar Days') not null,
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

insert into standards_targets 
(select 
	null, 
    mcs.Id, 
    m.Metric, 
    if(m.`Metric` in ('ARG Revision - First', 'ARG Revision - Resubmission'), 'Technical', 
		if(m.`Metric` in ('ARG Submission - First', 'ARG Submission - Resubmission', 'ARG Submission - Unsubmitted WI'),'Delivery', 
			if(m.`Metric` in ('ARG Completion/Hold'),'Admin',
				if(m.`Metric` in ('ARG Hold'),'Admin',null)))) as 'Team',
    if(m.Metric = 'Overall Process', 'ARG Approval', null) as 'end_of_process', 
    if(m.`Metric` in ('ARG Submission - First', 'ARG Submission - Unsubmitted WI'),4, 
		if(m.`Metric` in ('ARG Submission - Resubmission'),1, 
			if(m.`Metric` in ('ARG Revision - First'), 1, 
				if(m.`Metric` in ('ARG Revision - Resubmission'), 1,
					if(m.`Metric` in ('ARG Completion/Hold'),1,
						if(m.`Metric` in ('ARG Hold'),1,7)))))) as 'target_green',
    if(m.`Metric` in ('ARG Submission - First', 'ARG Submission - Unsubmitted WI'),5, 
		if(m.`Metric` in ('ARG Submission - Resubmission'),1, 
			if(m.`Metric` in ('ARG Revision - First'), 2, 
				if(m.`Metric` in ('ARG Revision - Resubmission'), 1,
					if(m.`Metric` in ('ARG Completion/Hold'),1,
						if(m.`Metric` in ('ARG Hold'),1,10)))))) as 'target_red',
	'Working Days' as 'uom'
from salesforce.mcdonalds_standards mcs,
(select 'ARG Submission - Unsubmitted WI' as 'metric' union select 'ARG Submission - First' union select 'ARG Submission - Resubmission' union select 'ARG Revision - First' union select 'ARG Revision - Resubmission' union select 'ARG Completion/Hold' union select 'ARG Hold' union select 'Overall Process') m
);


# Backlog RAG
#explain
select t2.Team, t2.Metric, t2.`Revenue Ownership` ,t2.`Administration Ownership` ,t2.`Client Site` ,t2.`Item Id` ,t2.`Item Name` ,t2.Owner ,t2.`From Type` ,t2.`From Date` ,t2.TimeZone ,t2.`Aging`, t2.`uom` as 'Ageing UOM', group_concat(t2.Standard_Service_Type_Name__c) as 'Standards' ,t2.`Target Green` ,t2.`Target Red` ,t2.`WI Type(s)` ,t2.`Audit End Date` ,t2.`Audit Start Date` ,t2.`Aging from Audit End` ,t2.`Overall Target Green`,t2.`Overall Target Red` from (
select t.* from (
select 
	st.team as 'Team',
	sla.`Metric`,
    sla.`Region` as 'Revenue Ownership',
    scsp.Administration_Ownership__c as 'Administration Ownership',
    group_concat(distinct wi.Client_Name_No_Hyperlink__c) as 'Client Site',
    sla.Id as 'Item Id',
    sla.Name as 'Item Name',
    sla.`Owner` as 'Owner',
    if(sla.`Metric` in ('ARG Revision - First', 'ARG Revision - Resubmission'), 'Last Submission', 
		if(sla.`Metric` in ('ARG Submission - First', 'ARG Submission - Resubmission', 'ARG Submission - Unsubmitted WI'),'Audit End/Last Rejection', 
			if(sla.`Metric` in ('ARG Completion/Hold'),'CA Approval',
				if(sla.`Metric` in ('ARG Hold'),'Admin Hold','?')))) as 'From Type',
    convert_tz(sla.`From`,'UTC', sla.`TimeZone`) as 'From Date',
    sla.TimeZone,
    if(st.uom='Working Days',
		analytics.getBusinessDays(sla.`From`, utc_timestamp(), sla.`TimeZone`),
        timestampdiff(day, sla.`From`, utc_timestamp())
	) as 'Aging',
    ifnull(st.uom, 'Calendar Days') as 'uom',
    'Primary Standard' as 'Standard Role',
    sp.Standard__c,
    sp.Standard_Service_Type_Name__c, 
	ifnull(st.target_green, analytics.getTargetARGGlobal(sla.`Metric`,null)*0.8) as 'Target Green',
    ifnull(st.target_red, analytics.getTargetARGGlobal(sla.`Metric`,null)) as 'Target Red',
    group_concat(distinct wi.Work_Item_Stage__c) as 'WI Type(s)',
    date_format(max(wi.End_Service_Date__c), '%Y-%m-%d 17:00:00') as 'Audit End Date',
    date_format(min(wi.Work_Item_Date__c), '%Y-%m-%d 9:00:00') as 'Audit Start Date',
    if(st.uom='Working Days',
		analytics.getBusinessDays(convert_tz(date_format(max(wi.End_Service_Date__c), '%Y-%m-%d 17:00:00'), sla.`TimeZone`, 'UTC'), utc_timestamp(), sla.`TimeZone`),
        timestampdiff(day,convert_tz(date_format(max(wi.End_Service_Date__c), '%Y-%m-%d 17:00:00'), sla.`TimeZone`, 'UTC'), utc_timestamp())
	) as 'Aging from Audit End',
    ifnull((select sstt.target_green from analytics.standards_targets sstt where sstt.Standard__c = sp.Standard__c and sstt.metric = 'Overall Process'), analytics.getTargetARGGlobal('ARG Process Time (Other)',null)*0.8) as 'Overall Target Green',
    ifnull((select sstt.target_red from analytics.standards_targets sstt where sstt.Standard__c = sp.Standard__c and sstt.metric = 'Overall Process'), analytics.getTargetARGGlobal('ARG Process Time (Other)',null)) as 'Overall Target Red'
    
from analytics.sla_arg_v2 sla
#left join salesforce.work_item__c wi on sla.Id = wi.Id
#left join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.audit_report_group__c arg on sla.Id = arg.Id
inner join salesforce.arg_work_item__c argwi on arg.Id = argwi.RAudit_Report_Group__c
inner join salesforce.work_item__c wi on argwi.RWork_Item__c = wi.Id
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
left join analytics.standards_targets st on sp.Standard__c = st.standard__c and st.`metric` = sla.`Metric`
where 
	`To` is null # backlog
    and sla.`Metric` in ('ARG Submission - First','ARG Submission - Resubmission','ARG Revision - First','ARG Revision - Resubmission','ARG Completion/Hold','ARG Hold')
	and (`Standards` like '%McDonald%' or `Standard Families` like '%McDonald%')
group by sla.`Metric`, sla.Id, sp.Standard__c

union all

select 
	st.team as 'Team',
	sla.`Metric`,
    sla.`Region` as 'Revenue Ownership',
    scsp.Administration_Ownership__c as 'Administration Ownership',
    group_concat(distinct wi.Client_Name_No_Hyperlink__c) as 'Client Site',
    sla.Id as 'Item Id',
    sla.Name as 'Item Name',
    sla.`Owner` as 'Owner',
    if(sla.`Metric` in ('ARG Revision - First', 'ARG Revision - Resubmission'), 'Last Submission', 
		if(sla.`Metric` in ('ARG Submission - First', 'ARG Submission - Resubmission', 'ARG Submission - Unsubmitted WI'),'Audit End/Last Rejection', 
			if(sla.`Metric` in ('ARG Completion/Hold'),'CA Approval',
				if(sla.`Metric` in ('ARG Hold'),'Admin Hold','?')))) as 'From Type',
    convert_tz(sla.`From`,'UTC', sla.`TimeZone`) as 'From Date',
    sla.TimeZone,
    if(st.uom='Working Days',
		analytics.getBusinessDays(sla.`From`, utc_timestamp(), sla.`TimeZone`),
        timestampdiff(day, sla.`From`, utc_timestamp())
	) as 'Aging',
    ifnull(st.uom, 'Calendar Days') as 'uom',
    'Family of Standards' as 'Standard Role',
    spf.Standard__c,
    spf.Standard_Service_Type_Name__c, 
    ifnull(st.target_green, analytics.getTargetARGGlobal(sla.`Metric`,null)*0.8) as 'Target Green',
    ifnull(st.target_red, analytics.getTargetARGGlobal(sla.`Metric`,null)) as 'Target Red',
    group_concat(distinct wi.Work_Item_Stage__c) as 'WI Type(s)',
    date_format(max(wi.End_Service_Date__c), '%Y-%m-%d 17:00:00') as 'Audit End Date',
    date_format(min(wi.Work_Item_Date__c), '%Y-%m-%d 9:00:00') as 'Audit Start Date',
    analytics.getBusinessDays(convert_tz(date_format(max(wi.End_Service_Date__c), '%Y-%m-%d 17:00:00'), sla.`TimeZone`, 'UTC'), utc_timestamp(), sla.`TimeZone`) as 'Aging from Audit End (working days)',
    ifnull((select sstt.target_green from analytics.standards_targets sstt where sstt.Standard__c = spf.Standard__c and sstt.metric = 'Overall Process'), analytics.getTargetARGGlobal('ARG Process Time (Other)',null)*0.8) as 'Overall Target Green', 
    ifnull((select sstt.target_red from analytics.standards_targets sstt where sstt.Standard__c = spf.Standard__c and sstt.metric = 'Overall Process'), analytics.getTargetARGGlobal('ARG Process Time (Other)',null)) as 'Overall Target Red' 
    
from analytics.sla_arg_v2 sla
#left join salesforce.work_item__c wi on sla.Id = wi.Id
#left join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.audit_report_group__c arg on sla.Id = arg.Id
inner join salesforce.arg_work_item__c argwi on arg.Id = argwi.RAudit_Report_Group__c
inner join salesforce.work_item__c wi on argwi.RWork_Item__c = wi.Id
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.site_certification_standard_family__c scspf on scspf.Site_Certification_Standard__c = scsp.Id and scspf.IsDeleted = 0
inner join salesforce.standard_program__c spf on scspf.Standard_Program__c = spf.Id
left join analytics.standards_targets st on spf.Standard__c = st.standard__c and st.`metric` = sla.`Metric`
where 
	`To` is null # backlog
    and sla.`Metric` in ('ARG Submission - First','ARG Submission - Resubmission','ARG Revision - First','ARG Revision - Resubmission','ARG Completion/Hold','ARG Hold')
	and (`Standards` like '%McDonald%' or `Standard Families` like '%McDonald%')
group by sla.`Metric`, sla.Id, spf.Standard__c) t
order by t.`Metric`, t.`Item Id`, t.`Overall Target Red`) t2
group by t2.`Metric`, t2.`Item Id`;

select analytics.getTargetARGGlobal('ARG Process Time (Other)',null);