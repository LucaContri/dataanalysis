DELIMITER $$
CREATE FUNCTION `getEnlightenUnitsPerHour`(activity VARCHAR(256)) RETURNS decimal(16,10) 
BEGIN
	DECLARE uph decimal(16,10) DEFAULT null;
    SET uph  = (SELECT 
		if(activity = 'Re-Submission', 12,
        if(activity = 'BRC/SQF/FSSC Follow Up/Gap', 4,
        if(activity = 'BRC Cert/Recert', 1,
        if(activity = 'SQF/FSSC Cert/Recert', 2.4,
        if(activity = 'Food - Follow Up', 12,
        if(activity = 'Food - Low Complexity', 10,
        if(activity = 'Food - Medium Complexity', 4,
        if(activity = 'Food - High Complexity', 2.4,
        if(activity = 'Automotive - Follow Up', 3.5,
        if(activity = 'Automotive', 2.4,
        if(activity = 'MS - Follow Up', 12,
        if(activity = 'MS - Low Complexity', 7.5,
        if(activity = 'MS - Medium Complexity', 4,
        if(activity = 'MS - High Complexity', 2.5,
        if(activity = 'Requested TR', 12,null))))))))))))))));	
    RETURN uph;
 END$$
DELIMITER ;

# Auditing Activities
(select 
	'Auditing' as 'Activity Type',
    wir.Work_Item_Type__c as 'Activity Name',
    r.Reporting_Business_Units__c as 'Reporting Business Unit',
    if(r.Reporting_Business_Units__c like '%Product%', 'Product Services', if(r.Reporting_Business_Units__c like 'AUS%', 'Australia', r.Reporting_Business_Units__c )) as 'Reporting Business Unit Simple',
    wi.Revenue_Ownership__c as 'Revenue Ownership',
    if(wi.Revenue_Ownership__c like '%Product%', 'Product Services', if(wi.Revenue_Ownership__c like 'AUS%', 'Australia', wi.Revenue_Ownership__c)) as 'Revenue Ownership Simple',
	r.Id as 'Resource Id', 
	r.Name as 'Resource', 
	date_format(wir.Start_Date__c, '%Y-%m') as 'Period',
    count(distinct wir.work_item__C) as 'Count',
	sum(wir.Total_Duration__c)/8 as 'Days'
	
from salesforce.resource__c r 
inner join salesforce.work_item_resource__c wir on wir.Resource__c = r.Id
inner join salesforce.work_item__c wi on wir.Work_Item__c = wi.Id
where 
	wir.IsDeleted = 0
group by r.Id, `Period`, `Activity Name`)

union all

# Technical Review Activities
(select 
	'Technical Review' as 'Activity Type',
    t3.`Activity` as 'Activity Name',
    t3.`Reporting Business Unit` as 'Reporting Business Unit',
    if(t3.`Reporting Business Unit` like '%Product%', 'Product Services', if(t3.`Reporting Business Unit` like 'AUS%', 'Australia', t3.`Reporting Business Unit` )) as 'Reporting Business Unit Simple',
    substring_index(t3.`RevenueOwnerships`,',',1) as 'Revenue Ownership',
    if(t3.`RevenueOwnerships` like '%Product%', 'Product Services', if(t3.`RevenueOwnerships` like 'AUS%', 'Australia', substring_index(t3.`RevenueOwnerships`,',',1) )) as 'Reporting Business Unit Simple',
    t3.`Resource Id`,
    t3.`Resource`,
    t3.`Period`,
    t3.`Completed` as 'Count',
    t3.`Completed`*(60/getEnlightenUnitsPerHour(t3.`Activity`))/60/8 as 'Days' from (
select 
date_format(t2.`ActionDate/Time`, '%Y-%m') as 'Period',
if(t2.`Action`='Requested Technical Review', ca.Id, t2.`Resource Id`) as 'Resource Id',
if(t2.`Action`='Requested Technical Review', ca.Name, t2.`Resource`) as 'Resource',
if(t2.`Action`='Requested Technical Review', ca.Reporting_Business_Units__c , t2.`Reporting_Business_Units__c`) as 'Reporting Business Unit',
t2.`RevenueOwnerships`,
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
group_concat(t2.ARG_Name) as 'ARG Names'
from 
	(select t.*, 
			r.Name as 'Resource',
            r.Id as 'Resource Id',
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
		from salesforce.enlighten_prc_activity_sub t
			inner join salesforce.Approval_History__c ah on ah.RAudit_Report_Group__c = t.ARG_Id
			inner join salesforce.Resource__c r on ah.RApprover__c = r.Id
			inner join salesforce.arg_work_item__c argwi on argwi.RAudit_Report_Group__c = t.Arg_Id 
			inner join salesforce.work_item__c wi on wi.id = argwi.RWork_Item__c 
			inner join salesforce.`site_certification_standard_program__c` `scsp` ON `wi`.`Site_Certification_Standard__c` = `scsp`.`Id`
			inner join salesforce.`standard_program__c` `stpr` on scsp.Standard_Program__c = stpr.Id
			LEFT JOIN salesforce.`site_certification_standard_family__c` `scsf` ON `scsf`.`Site_Certification_Standard__c` = `scsp`.`Id`
			LEFT JOIN salesforce.`standard_program__c` `sp` ON `scsf`.`Standard_Program__c` = `sp`.`Id`
			LEFT JOIN salesforce.`standard__c` `s` ON `sp`.`Standard__c` = `s`.`Id`
		where
			wi.IsDeleted=0 and wi.Status__c not in ('Cancelled') and argwi.IsDeleted=0 
			and ah.IsDeleted=0
			and ah.Status__c in ('Approved','Rejected', 'Requested Technical Review')
			#and ah.Timestamp__c<= utc_timestamp()
			#and ah.Timestamp__c> date_add(utc_timestamp(), interval -1 day)
		group by ah.Id) t2
left join salesforce.Resource__c ca on t2.Assigned_CA__c = ca.Id
#where (t2.`PrimaryStandards` not like '%WQA%'
#and t2.`PrimaryStandards` not like '%Woolworths%'
#and (t2.`Standard Families` not like '%WQA%' or t2.`Standard Families` is null)
#and (t2.`Standard Families` not like '%Woolworths%' or t2.`Standard Families` is null))
group by `Resource Id`,`Action`, `Period`) t3);#t2.`ActionDate/Time`;