create or replace view mcdonalads_backlog as 
select 
	if(sla.`Metric` in ('ARG Revision - First', 'ARG Revision - Resubmission'), 'PRC', 
		if(sla.`Metric` in ('ARG Submission - First', 'ARG Submission - Resubmission', 'ARG Submission - Unsubmitted WI'),'Delivery', 
			if(sla.`Metric` in ('ARG Completion/Hold'),'Admin',
				if(sla.`Metric` in ('ARG Hold'),'Admin','?')))) as 'Team',
	sla.`Metric`,
    sla.`Region` as 'Revenue Ownership',
    sla.`Standards` AS `Standards`,
	sla.`Standard Families` AS `Standard Families`,
    if (wi.Id is null, group_concat(distinct scsp2.Administration_Ownership__c), scsp.Administration_Ownership__c) as 'Administration Ownership',
    if (wi.Id is null, group_concat(distinct wi2.Client_Name_No_Hyperlink__c), wi.Client_Name_No_Hyperlink__c) as 'Client Site',
    sla.Id as 'Item Id',
    sla.Name as 'Item Name',
    sla.`Owner` as 'Owner',
    ifnull(author.Name, '') as 'ARG Author',
    if(sla.`Metric` in ('ARG Revision - First', 'ARG Revision - Resubmission'), 'Last Submission', 
		if(sla.`Metric` in ('ARG Submission - First', 'ARG Submission - Resubmission', 'ARG Submission - Unsubmitted WI'),'Audit End/Last Rejection', 
			if(sla.`Metric` in ('ARG Completion/Hold'),'CA Approval',
				if(sla.`Metric` in ('ARG Hold'),'Admin Hold','?')))) as 'From Type',
    convert_tz(sla.`From`,'UTC', sla.`TimeZone`) as 'From Date',
    sla.TimeZone,
    analytics.getBusinessDays(sla.`From`, utc_timestamp(), sla.`TimeZone`) as 'Aging (working days)',
    if(sla.`Metric` in ('ARG Submission - First', 'ARG Submission - Unsubmitted WI'),4, 
		if(sla.`Metric` in ('ARG Submission - Resubmission'),1, 
			if(sla.`Metric` in ('ARG Revision - First'), 1, 
				if(sla.`Metric` in ('ARG Revision - Resubmission'), 1,
					if(sla.`Metric` in ('ARG Completion/Hold'),1,
						if(sla.`Metric` in ('ARG Hold'),1,'?')))))) as 'Target Green',
    if(sla.`Metric` in ('ARG Submission - First', 'ARG Submission - Unsubmitted WI'),5, 
		if(sla.`Metric` in ('ARG Submission - Resubmission'),1, 
			if(sla.`Metric` in ('ARG Revision - First'), 2, 
				if(sla.`Metric` in ('ARG Revision - Resubmission'), 1,
					if(sla.`Metric` in ('ARG Completion/Hold'),1,
						if(sla.`Metric` in ('ARG Hold'),1,'?')))))) as 'Target Red',
    if (wi.Id is null, group_concat(distinct wi2.Work_Item_Stage__c), wi.Work_Item_Stage__c) as 'WI Type(s)',
    date_format(if(wi.Id is null, max(wi2.End_Service_Date__c), wi.End_Service_Date__c), '%Y-%m-%d 17:00:00') as 'Audit End Date',
    date_format(if(wi.Id is null, min(wi2.Work_Item_Date__c), wi.Work_Item_Date__c), '%Y-%m-%d 9:00:00') as 'Audit Start Date',
    analytics.getBusinessDays(convert_tz(date_format(if(wi.Id is null, max(wi2.End_Service_Date__c), wi.End_Service_Date__c), '%Y-%m-%d 17:00:00'), sla.`TimeZone`, 'UTC'), utc_timestamp(), sla.`TimeZone`) as 'Aging from Audit End (working days)'
    
from analytics.sla_arg_v2 sla
left join salesforce.work_item__c wi on sla.Id = wi.Id
left join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
left join salesforce.audit_report_group__c arg on sla.Id = arg.Id
left join salesforce.resource__c author on arg.RAudit_Report_Author__c = author.Id
left join salesforce.arg_work_item__c argwi on arg.Id = argwi.RAudit_Report_Group__c
left join salesforce.work_item__c wi2 on argwi.RWork_Item__c = wi2.Id
left join salesforce.site_certification_standard_program__c scsp2 on wi2.Site_Certification_Standard__c = scsp2.Id
where `To` is null
and (`Standards` like '%McDonald%' or `Standard Families` like '%McDonald%')
group by sla.`Metric`, sla.Id;

select 
 mcd.`Team`, 
 mcd.`Metric`, 
    mcd.`Revenue Ownership`, 
    mcd.`Administration Ownership`, 
    mcd.`Client Site`, 
    mcd.`Item Id`, 
    mcd.`Item Name`, 
    mcd.`Standards`,
    ifnull(mcd.`Standard Families`,'') as 'Standard Families',
    mcd.`Owner`, 
    mcd.`ARG Author`, 
    mcd.`From Date`, 
    mcd.`TimeZone`, 
    mcd.`Aging (working days)`,
    mcd.`WI Type(s)`,
    mcd.`Audit Start Date`,
    mcd.`Audit End Date`,
    mcd.`Aging from Audit End (working days)`,
    if(mcd.`Aging (working days)`<=mcd.`Target Green`, 'G',if(mcd.`Aging (working days)`>mcd.`Target Red`, 'R', 'A')) as 'RAG Status',
    if(mcd.`Aging from Audit End (working days)`<=7, 'G',if(mcd.`Aging from Audit End (working days)`>9, 'R', 'A')) as 'RAG Status Overall'
from mcdonalads_backlog mcd 
where `WI Type(s)` not in ('Follow Up', 'Gap');

select utc_timestamp(), convert_tz(utc_timestamp(), 'UTC', 'GMT'), convert_tz(utc_timestamp(), 'UTC', 'Europe/London');

select s.Id, s.Name, s.Time_Zone__c, s.Client_Ownership__c from salesforce.account s where s.Time_Zone__c in ('Europe/London', 'GMT') and s.Client_Ownership__c is not null;
