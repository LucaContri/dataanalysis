# WIP
create or replace view enlighten_prc_wow_wip as 
(select 'WOW' as 'Team', 
	'' as 'User',
	if (t.`Rejections`>0,'WOW Review ARG Resubmitted',
		if (t.`TR Approved`>0, 'WOW Certification Approval Post TR',
			if (t.`WorkItemTypes` = 'Follow Up', 'WOW Review ARG Follow Up', 'WOW Review ARG Full')
        )
    ) as 'Activity',
    count(distinct t.`ARG_Id`) as 'WIP',
    date_format(now(), '%d/%m/%Y') as 'Date/Time'
from enlighten_wip_sub_2 t
where 
t.`PrimaryStandards` like '%WQA%'
or t.`PrimaryStandards` like '%Woolworths%'
or t.`Standard Families` like '%WQA%'
or t.`Standard Families` like '%Woolworths%'
group by `Team`, `Activity`)
union 
(select 'WOW' as 'Team', 
#t.`Admin Name` as 'User', 
'' as 'User',
if(WorkItemTypes = 'Follow Up', 'Upload WOW Audit (Subsequent)', 'Upload WOW Audit (Initial)') as 'Activity', count(distinct t.`Id`) as 'WIP', date_format(now(), '%d/%m/%Y') as 'Date/Time' from analytics.sla_arg t
where (t.`PrimaryStandards` like '%WQA%'
or t.`PrimaryStandards` like '%Woolworths%'
or t.`Standard Families` like '%WQA%'
or t.`Standard Families` like '%Woolworths%')
and t.`Status` = 'Support'
group by `Team`, `User`, `Activity`);

select * from enlighten_prc_wow_wip;

# Activities
create or replace view enlighten_prc_wow_activity_sub as
select t.*, 
r.Name as 'ActionedBy',
t.`First_Reviewed` as 'ActionDate/Time',
t.`ARG_Id` as 'ActionId',
'Completed' as 'Action',
t.Assigned_Admin__c as 'Assigned To',
group_concat(distinct wi.Revenue_Ownership__c) as 'RevenueOwnerships',
count(distinct wi.Id) as 'WorkItemsNo',
group_concat(distinct wi.Work_Item_Stage__c) as 'WorkItemTypes',
group_concat(distinct wi.Primary_Standard__c) as 'PrimaryStandards',
GROUP_CONCAT(DISTINCT IF((`scsf`.`IsDeleted` OR `sp`.`IsDeleted`OR `s`.`IsDeleted`),NULL,`s`.`Name`) SEPARATOR ',') AS `Standard Families`
from enlighten_prc_activity_sub t
inner join Resource__c r on t.`Assigned_Admin__c` = r.Id
inner join arg_work_item__c argwi on argwi.RAudit_Report_Group__c = t.Arg_Id 
inner join work_item__c wi on wi.id = argwi.RWork_Item__c 
inner join `site_certification_standard_program__c` `scsp` ON `wi`.`Site_Certification_Standard__c` = `scsp`.`Id`
LEFT JOIN `site_certification_standard_family__c` `scsf` ON `scsf`.`Site_Certification_Standard__c` = `scsp`.`Id`
LEFT JOIN `standard_program__c` `sp` ON `scsf`.`Standard_Program__c` = `sp`.`Id`
LEFT JOIN `standard__c` `s` ON `sp`.`Standard__c` = `s`.`Id`
where
wi.IsDeleted=0 and wi.Status__c not in ('Cancelled') and argwi.IsDeleted=0 
and t.`First_Reviewed_Admin`<= utc_timestamp()
and t.`First_Reviewed_Admin`> date_add(utc_timestamp(), interval -1 day)
#and date_format(date_add(t.`First_Reviewed_Admin`, interval 10 hour), '%Y-%m-%d')  = '2015-05-28'
group by t.`ARG_Id`;

create or replace view enlighten_prc_wow_activity as 
(select 'WOW' as 'Team',
t.ActionedBy as 'User',
if(t.WorkItemTypes = 'Follow Up', 'Upload WOW Audit (Subsequent)', 'Upload WOW Audit (Initial)') as 'Activity',
count(distinct t.`ARG_Id`) as 'Completed',
date_format(now(), '%Y-%m-%d') as 'Date/Time',
    group_concat(distinct t.ARG_Name) as 'Notes'
from enlighten_prc_wow_activity_sub t
where (t.`PrimaryStandards` like '%WQA%'
	or t.`PrimaryStandards` like '%Woolworths%'
	or t.`Standard Families` like '%WQA%'
	or t.`Standard Families` like '%Woolworths%')
group by `Team`, `User`, `Activity`)
union
(select 'WOW' as 'Team',
	if(t.`Action`='Requested Technical Review', ca.Name, t.`ActionedBy`) as 'User',
    if(t.`Action`='Requested Technical Review', 'WOW Requested TR',
		if (t.`TR Approved`>0 and t.`Action`='Approved' and t.`Assigned To` = 'Client Administration', 'WOW Certification Approval Post TR',
			if (t.`Rejections`>0 and not(t.`First_Rejected`=t.`ActionDate/Time`),'WOW Review ARG Resubmitted',
				if (t.`WorkItemTypes` = 'Follow Up', 'WOW Review ARG Follow Up', 'WOW Review ARG Full')
			)
		)
	) as 'Activity',
    count(distinct t.`ARG_Id`) as 'Completed',
    date_format(now(), '%Y-%m-%d') as 'Date/Time',
    group_concat(distinct t.ARG_Name) as 'Notes'
from enlighten_prc_activity_sub2 t
left join Resource__c ca on t.Assigned_CA__c = ca.Id
where 
t.`PrimaryStandards` like '%WQA%'
or t.`PrimaryStandards` like '%Woolworths%'
or t.`Standard Families` like '%WQA%'
or t.`Standard Families` like '%Woolworths%'
group by `Team`, `User`, `Activity`);

select * from enlighten_prc_wow_activity;

select 'WOW' as 'Team', t.`Admin Name` as 'User', if(WorkItemTypes = 'Follow Up', 'Upload WOW Audit (Subsequent)', 'Upload WOW Audit (Initial)') as 'Activity', count(distinct t.`Id`) as 'WIP', date_format(now(), '%d/%m/%Y') as 'Date/Time' from analytics.sla_arg t
where (t.`PrimaryStandards` like '%WQA%'
or t.`PrimaryStandards` like '%Woolworths%'
or t.`Standard Families` like '%WQA%'
or t.`Standard Families` like '%Woolworths%')
and t.`Status` = 'Support'
group by `Team`, `User`, `Activity`;
