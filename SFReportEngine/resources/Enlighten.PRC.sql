use salesforce;
# WIP PRC

create or replace view enlighten_prc_wip_sub as 
select ah.RAudit_Report_Group__c as 'ARG_Id',
arg.Name as 'ARG_Name',
arg.Audit_Report_Status__c as 'ARG_Status',
arg.Client_Ownership__c as 'ClientOwnerShip',
datediff(now(),max(if(ah.Status__c='Submitted', Timestamp__c, null))) as 'Aging',
max(if(ah.Status__c='Submitted', Timestamp__c, null)) as 'Last_Submitted',
min(if(ah.Status__c='Submitted', Timestamp__c, null)) as 'First_Submitted',
min(if(ah.Status__c='Taken', Timestamp__c, null)) as 'First_Taken',
min(if(ah.Status__c='Rejected' or (ah.Assigned_To__c='Client Administration' and ah.Status__c='Approved') or (ah.Assigned_To__c='Technical Review' and ah.Status__c='Requested Technical Review'), Timestamp__c, null)) as 'First_Reviewed',
sum(if(ah.Status__c='Rejected',1,0)) as 'Rejections',
sum(if(ah.Status__c='Requested Technical Review',1,0)) as 'TR Requests',
sum(if(ah.Status__c='Approved' and ah.Assigned_To__c='Certification Approver',1,0)) as 'TR Approved',
arg.Assigned_CA__c,
arg.RAssigned_To__c
from approval_history__c ah 
inner join audit_report_group__c arg on arg.Id = ah.RAudit_Report_Group__c 
where ah.RAudit_Report_Group__c is not null 
and arg.Audit_Report_Status__c='Under Review'
and (arg.Work_Item_Stages__c not like '%Initial Project%' or arg.Work_Item_Stages__c not like '%Product Update%' or arg.Work_Item_Stages__c not like '%Standard Change%')
group by ah.RAudit_Report_Group__c;

create or replace view enlighten_wip_sub_2 as
select t.*,
group_concat(distinct wi.Revenue_Ownership__c) as 'RevenueOwnerships',
count(distinct wi.Id) as 'WorkItemsNo',
group_concat(distinct wi.Work_Item_Stage__c) as 'WorkItemTypes',
group_concat(distinct wi.Primary_Standard__c) as 'PrimaryStandards',
group_concat(distinct stpr.Program_Business_Line__c) as 'ProgramBusinessLines',
GROUP_CONCAT(DISTINCT IF((`scsf`.`IsDeleted` OR `sp`.`IsDeleted`OR `s`.`IsDeleted`),NULL,`s`.`Name`) SEPARATOR ',') AS `Standard Families`
from enlighten_prc_wip_sub t 
inner join arg_work_item__c argwi on argwi.RAudit_Report_Group__c = t.Arg_Id 
inner join work_item__c wi on wi.id = argwi.RWork_Item__c 
inner join `site_certification_standard_program__c` `scsp` ON `wi`.`Site_Certification_Standard__c` = `scsp`.`Id`
inner join `standard_program__c` `stpr` on scsp.Standard_Program__c = stpr.Id
LEFT JOIN `site_certification_standard_family__c` `scsf` ON `scsf`.`Site_Certification_Standard__c` = `scsp`.`Id`
LEFT JOIN `standard_program__c` `sp` ON `scsf`.`Standard_Program__c` = `sp`.`Id`
LEFT JOIN `standard__c` `s` ON `sp`.`Standard__c` = `s`.`Id`
where 
wi.IsDeleted=0 and wi.Status__c not in ('Cancelled') and argwi.IsDeleted=0 
group by t.ARG_Id;

create or replace view enlighten_prc_wip as
select 
t2.*,
'PRC' as 'Team', 
if (t2.Rejections>0 , 'Re-Submission',
	if (t2.`TR Requests`>0 and t2.RAssigned_To__c=t2.Assigned_CA__c, 'Post TR',
		if (t2.RevenueOwnerships like '%Food%',
			#Food
			if(t2.PrimaryStandards like '%BRC%',
				#BRC
				if(t2.WorkItemTypes like '%Follow Up%' or t2.WorkItemTypes like '%Gap%',
					'BRC/SQF/FSSC Follow Up/Gap',
					'BRC Cert/Recert'
				),
				if(t2.PrimaryStandards like '%SQF%' or t2.PrimaryStandards like '%FSSC%',
					#SQF/FSSC
					if(t2.WorkItemTypes like '%Follow Up%' or t2.WorkItemTypes like '%Gap%',
						'BRC/SQF/FSSC Follow Up/Gap',
						'SQF/FSSC Cert/Recert'
					),
					#General Food
					if(t2.WorkItemTypes like '%Follow Up%',
						'Food - Follow Up',
						if(t2.WorkItemsNo<3,
							'Food - Low Complexity',
							if(t2.WorkItemsNo<6,
								'Food - Medium Complexity',
								'Food - High Complexity'
							)
						)
					)		
				)
			),
			if(t2.PrimaryStandards like '%16949%',
				# Automotive
				if(t2.WorkItemTypes like '%Follow Up%',
					'Automotive - Follow Up',
					'Automotive'
				),
				# Management Systems
				if(t2.WorkItemTypes like '%Follow Up%',
					'MS - Follow Up',
					if(t2.WorkItemsNo<4,
						'MS - Low Complexity',
						if(t2.WorkItemsNo<12,
							'MS - Medium Complexity',
							'MS - High Complexity'
						)
					)
				)
			)
		)
	)
) as 'Activity',
count(t2.ARG_Id) as 'WIP',
date_format(now(), '%d/%m/%Y') as 'Date/Time'
from enlighten_wip_sub_2 t2
where 
(t2.RevenueOwnerships like '%AUS-Managed%' or t2.RevenueOwnerships like '%AUS-Food%' or t2.RevenueOwnerships like '%AUS-Direct%' or (t2.RevenueOwnerships like 'ASIA%' and t2.PrimaryStandards like '%16949%'))
#and not(concat(t2.`PrimaryStandards`,t2.`Standard Families`)  like '%WQA%' or concat(t2.`PrimaryStandards`,t2.`Standard Families`)  like '%Woolworths%')
and (t2.`PrimaryStandards` not like '%WQA%'
	and t2.`PrimaryStandards` not like '%Woolworths%'
	and (t2.`Standard Families` not like '%WQA%' or t2.`Standard Families` is null)
	and (t2.`Standard Families` not like '%Woolworths%' or t2.`Standard Families` is null))
group by 
t2.ARG_Id;

select epw.`Team`, epw.`Activity`, sum(epw.`WIP`) as 'WIP', epw.`Date/Time` 
from enlighten_prc_wip epw 
group by epw.`Team`, epw.`Activity`;


select * from enlighten_prc_wip;

# Activities Done
create or replace view enlighten_prc_activity_sub as
select ah.RAudit_Report_Group__c as 'ARG_Id',
arg.Name as 'ARG_Name',
arg.Audit_Report_Status__c as 'ARG_Status',
arg.Client_Ownership__c as 'ClientOwnerShip',
arg.Assigned_CA__c,
arg.Assigned_Admin__c,
min(if(ah.Status__c='Submitted', Timestamp__c, null)) as 'First_Submitted',
max(if(ah.Status__c='Submitted', Timestamp__c, null)) as 'Last_Submitted',
min(if(ah.Status__c='Taken', Timestamp__c, null)) as 'First_Taken',
min(if(ah.Status__c='Rejected', Timestamp__c, null)) as 'First_Rejected',
min(if(ah.Status__c='Rejected' or (ah.Assigned_To__c='Client Administration' and ah.Status__c='Approved') or (ah.Assigned_To__c='Technical Review' and ah.Status__c='Requested Technical Review'), Timestamp__c, null)) as 'First_Reviewed',
min(if(ah.Status__c='Completed' || ah.Status__c='Hold', Timestamp__c, null)) as 'First_Reviewed_Admin',
sum(if(ah.Status__c='Rejected',1,0)) as 'Rejections',
sum(if(ah.Status__c='Requested Technical Review',1,0)) as 'TR Requests',
sum(if(ah.Status__c='Approved' and ah.Assigned_To__c='Certification Approver',1,0)) as 'TR Approved'
from approval_history__c ah 
inner join audit_report_group__c arg on arg.Id = ah.RAudit_Report_Group__c 
where ah.RAudit_Report_Group__c is not null 
and (arg.Work_Item_Stages__c not like '%Initial Project%' or arg.Work_Item_Stages__c not like '%Product Update%' or arg.Work_Item_Stages__c not like '%Standard Change%')
group by ah.RAudit_Report_Group__c;

create or replace view enlighten_prc_activity_sub2 as 
select t.*, 
r.Name as 'ActionedBy',
r.Reporting_Business_Units__c,
ah.Timestamp__c as 'ActionDate/Time',
ah.Id as 'ActionId',
ah.Status__c as 'Action',
ah.Assigned_To__c as 'Assigned To',
group_concat(distinct wi.Revenue_Ownership__c) as 'RevenueOwnerships',
count(distinct wi.Id) as 'WorkItemsNo',
group_concat(distinct wi.Work_Item_Stage__c) as 'WorkItemTypes',
group_concat(distinct wi.Primary_Standard__c) as 'PrimaryStandards',
group_concat(distinct stpr.Program_Business_Line__c) as 'ProgramBusinessLines',
GROUP_CONCAT(DISTINCT IF((`scsf`.`IsDeleted` OR `sp`.`IsDeleted`OR `s`.`IsDeleted`),NULL,`s`.`Name`) SEPARATOR ',') AS `Standard Families`
from enlighten_prc_activity_sub t
inner join Approval_History__c ah on ah.RAudit_Report_Group__c = t.ARG_Id
inner join Resource__c r on ah.RApprover__c = r.Id
inner join arg_work_item__c argwi on argwi.RAudit_Report_Group__c = t.Arg_Id 
inner join work_item__c wi on wi.id = argwi.RWork_Item__c 
inner join `site_certification_standard_program__c` `scsp` ON `wi`.`Site_Certification_Standard__c` = `scsp`.`Id`
inner join `standard_program__c` `stpr` on scsp.Standard_Program__c = stpr.Id
LEFT JOIN `site_certification_standard_family__c` `scsf` ON `scsf`.`Site_Certification_Standard__c` = `scsp`.`Id`
LEFT JOIN `standard_program__c` `sp` ON `scsf`.`Standard_Program__c` = `sp`.`Id`
LEFT JOIN `standard__c` `s` ON `sp`.`Standard__c` = `s`.`Id`
where
wi.IsDeleted=0 and wi.Status__c not in ('Cancelled') and argwi.IsDeleted=0 
and ah.IsDeleted=0
and ah.Status__c in ('Approved','Rejected', 'Requested Technical Review')
#and date_format(date_add(ah.Timestamp__c, interval 11 HOUR), '%Y-%m-%d') = '2016-05-09' #date_format(now(), '%Y-%m-%d')
and ah.Timestamp__c<= utc_timestamp()
and ah.Timestamp__c> date_add(utc_timestamp(), interval -1 day)
group by ah.Id;

select * from enlighten_prc_activity_sub2 ;
create or replace view enlighten_prc_activity as
select 
t2.*,
'PRC' as 'Team', 
if(t2.`Action`='Requested Technical Review', ca.Name, t2.`ActionedBy`) as 'User',
if (t2.`Action`='Requested Technical Review', 'Requested TR',
	if(t2.`Rejections`>0 and not(t2.`First_Rejected`=t2.`ActionDate/Time`), 'Re-Submission',
	#if (t2.Rejections>1, 'Re-Submission',
		#if (t2.`TR Requests`=1 and not(t2.`Assigned To`='Certification Approver'), 'Post TR',
			if (t2.RevenueOwnerships like '%Food%',
				#Food
				if(t2.PrimaryStandards like '%BRC%',
					#BRC
					if(t2.WorkItemTypes like '%Follow Up%' or t2.WorkItemTypes like '%Gap%',
						'BRC/SQF/FSSC Follow Up/Gap',
						'BRC Cert/Recert'
					),
					if(t2.PrimaryStandards like '%SQF%' or t2.PrimaryStandards like '%FSSC%',
						#SQF/FSSC
						if(t2.WorkItemTypes like '%Follow Up%' or t2.WorkItemTypes like '%Gap%',
							'BRC/SQF/FSSC Follow Up/Gap',
							'SQF/FSSC Cert/Recert'
						),
						#General Food
						if(t2.WorkItemTypes like '%Follow Up%',
							'Food - Follow Up',
							if(t2.WorkItemsNo<3,
								'Food - Low Complexity',
								if(t2.WorkItemsNo<6,
									'Food - Medium Complexity',
									'Food - High Complexity'
								)
							)
						)		
					)
				),
				if(t2.PrimaryStandards like '%16949%',
					# Automotive
					if(t2.WorkItemTypes like '%Follow Up%',
						'Automotive - Follow Up',
						'Automotive'
					),
					# Management Systems
					if(t2.WorkItemTypes like '%Follow Up%',
						'MS - Follow Up',
						if(t2.WorkItemsNo<4,
							'MS - Low Complexity',
							if(t2.WorkItemsNo<12,
								'MS - Medium Complexity',
								'MS - High Complexity'
							)
						)
					)
				)
			)
		#)
	)
) as 'Activity',
count(t2.ARG_Id) as 'Completed',
date_format(now(), '%d/%m/%Y') as 'Date/Time',
group_concat(t2.ARG_Name) as 'ARG Names'
from enlighten_prc_activity_sub2 t2
left join Resource__c ca on t2.Assigned_CA__c = ca.Id
where (t2.`PrimaryStandards` not like '%WQA%'
	and t2.`PrimaryStandards` not like '%Woolworths%'
	and (t2.`Standard Families` not like '%WQA%' or t2.`Standard Families` is null)
	and (t2.`Standard Families` not like '%Woolworths%' or t2.`Standard Families` is null))
group by 
t2.`ActionDate/Time`; 

select * from enlighten_prc_activity epa;

select epa.`Team`, epa.`User`, epa.`Activity`, sum(epa.`Completed`) as 'Completed', epa.`Date/Time`, group_concat(distinct epa.`ARG Names`) as 'Notes'
from enlighten_prc_activity epa
group by epa.`Team`, epa.`User`, epa.`Activity`;

select * from enlighten_prc_activity;

# Family of Standard Combinations
select t.*,
if (t.FamilyOfStandards is null, t.PrimaryStandards, concat(t.PrimaryStandards, ',', t.FamilyOfStandards)) as 'Primary_Standards_Plus_Family',
min(if(ah.Status__c='Taken', Timestamp__c, null)) as 'First_Taken',
min(if(ah.Status__c='Rejected', Timestamp__c, null)) as 'First_Rejected',
min(if(ah.Status__c='Approved', Timestamp__c, null)) as 'First_Approved',
sum(if (ah.Status__c='Requested Technical Review',1,0)) as 'Technical_Reviews',
TIMESTAMPDIFF(MINUTE,min(if(ah.Status__c='Taken', Timestamp__c, null)), min(if(ah.Status__c='Rejected', Timestamp__c, null))) as 'First_Taken_To_First_Rejected_Minutes',
TIMESTAMPDIFF(MINUTE,min(if(ah.Status__c='Taken', Timestamp__c, null)), min(if(ah.Status__c='Approved', Timestamp__c, null))) as 'First_Taken_To_First_Approved_Minutes'
from (
select arg.id as 'id', 
arg.Name as 'name',
arg.Client_Ownership__c,
if(wi.Revenue_Ownership__c like '%Food%', 'food', if(wi.Revenue_Ownership__c like '%Product%', 'ps', 'ms')) as 'Stream',
count(distinct wi.Id) as 'WorkItemsNo',
group_concat(distinct wi.Work_Item_Stage__c) as 'WorkItemType',
group_concat(distinct wi.Primary_Standard__c order by wi.Primary_Standard__c) as 'PrimaryStandards',  
group_concat(distinct fs.Name order by fs.Name) as 'FamilyOfStandards'
from audit_report_group__c arg
inner join arg_work_item__c argwi on argwi.RAudit_Report_Group__c = arg.Id 
inner join work_item__c wi on wi.id = argwi.RWork_Item__c 
inner join site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
left join standard_program__c sp on sp.Id = scsp.Standard_Program__c
left join standard__c s on sp.Standard__c = s.Id
left join site_certification_standard_family__c scsf on scsf.Site_Certification_Standard__c = scsp.Id
left join standard_program__c fsp on scsf.Standard_Program__c = fsp.Id
left join standard__c fs on fsp.Standard__c = fs.Id
where 
wi.IsDeleted=0 and wi.Status__c not in ('Cancelled') and argwi.IsDeleted=0 
group by arg.Id) t
left join Approval_History__c ah on ah.RAudit_Report_Group__c = t.Id
inner join User u on ah.CreatedById = u.id
where ah.IsDeleted=0
and u.Name in ('Martin Cutler')
group by t.Id
limit 100000;


# Error Lost Time Automation
create or replace view enlighten_prc_elt_rejections as
(select 
date_format(ah.Timestamp__c, '%d/%m/%Y %k:%i:%s') as 'Date Occurred',
'PRC' as 'Found By Team',
prc.Name as 'Found by Team Member',
'Internal Error' as 'Source',
substring(SUBSTRING_INDEX(ah.Rejection_Reason__c,';',1),1,50) as 'Error Type',
'Actual' as 'Error Severity',
arg.Name as 'Reference Number',
concat(ah.Comments__c, '\n\n', 'Rejection Reasons: ', ah.Rejection_Reason__c) as 'Found by Details',
#a.Reporting_Business_Units__c as 'Caused by Team',
#a.Name as 'Caused by Team Member',
'NSW Auditors' as 'Caused by Team',
'ELT Auditor' as 'Caused by Team Member',
null as 'External Party',
null as 'External Party Details',
'Closed' as 'Error Status',
date_format(ah.Timestamp__c, '%d/%m/%Y %k:%i:%s') as 'Assigned To Date',
prc.Reporting_Business_Units__c  as 'Assigned to Team',
prc.Name as 'Assigned to Team Member',
'Auto-Tally from Compass (Salesforce)' as 'Assigned to Details',
date_format(ah.Timestamp__c, '%d/%m/%Y %k:%i:%s') as 'Date Closed',
'ARG Rejection Correspondence' as 'Error Activity'
from salesforce.approval_history__c ah 
inner join salesforce.audit_report_group__c arg on ah.RAudit_Report_Group__c = arg.Id
inner join salesforce.resource__c a on arg.RAudit_Report_Author__c = a.Id
inner join salesforce.resource__c prc on ah.RApprover__c = prc.Id
where 
ah.Status__c in ('Rejected')
and ah.Timestamp__c<= utc_timestamp()
and ah.Timestamp__c> date_add(utc_timestamp(), interval -1 day)
);

select substring(SUBSTRING_INDEX(Rejection_Reason__c,';',1),1,50) as 'Error Type', count(ID) from salesforce.approval_history__c group by `Error Type`;
select * from salesforce.enlighten_prc_elt_rejections;