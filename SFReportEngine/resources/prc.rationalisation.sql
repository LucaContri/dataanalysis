# PRC Review

# Technical Resources Organigram - Who are the CA, TA.  Who do they report to.  Where are they located.
(select 
	r.Reporting_Business_Units__c, 
    getBUFromReportingBusinessUnit(r.Reporting_Business_Units__c) as 'BU Country', 
    getRegionFromCountry(getBUFromReportingBusinessUnit(r.Reporting_Business_Units__c)) as 'Region', 
    ccs.Name as 'Home Country', 
    getRegionFromCountry(ccs.Name) as 'Home Region',
    r.Id, 
    r.Name, 
    r.Active_User__c, 
    r.Status__c, 
    date_format(arg.CA_Approved__c, '%Y %m') as 'CA Approved Period', 
    wi.Primary_Standard__c, 
    count(distinct arg.Id) as '# ARG',
    count(distinct if(ah.Status__c = 'Approved' and ah.Assigned_To__c = 'Certification Approver',ah.Id,null)) as '# TR Approvals',
    count(distinct if(ah.Status__c = 'Approved' and ah.Assigned_To__c = 'Client Administration',ah.Id,null)) as '# CA Approvals',
    count(distinct if(ah.Status__c = 'Rejected',ah.Id,null)) as '# Rejections'
from salesforce.audit_report_group__c arg 
inner join salesforce.approval_history__c ah on arg.Id = ah.RAudit_Report_Group__c and ah.Status__c in ('Approved','Rejected') and ah.IsDeleted = 0
inner join salesforce.arg_work_item__c argwi on arg.Id = argwi.RAudit_Report_Group__c and argwi.IsDeleted = 0
inner join salesforce.work_item__c wi on argwi.RWork_Item__c = wi.Id
inner join salesforce.resource__c r on arg.Assigned_CA__c = r.Id
left join salesforce.country_code_setup__c ccs on r.Home_Country1__c = ccs.Id
where arg.CA_Approved__c >= '2016-01-01'
group by r.Id, wi.Primary_Standard__c, `CA Approved Period`);

(select Status__C, Assigned_To__c from salesforce.approval_history__c where Status__c in ('Approved','Rejected') group by Status__C, Assigned_To__c);

#explain
(select 
	date_format(ah.CreatedDate, '%Y %m') as 'Period', 
    ah.Status__c, 
    ah.Assigned_To__c, 
    r.Name as 'Approver', 
    getRegionFromCountry(ccs.Name) as 'Approver Region',
    ccs.Name as 'Approver Country', 
    count(distinct ah.Id) as 'Count',
    wi.Revenue_Ownership__c, wi.Primary_Standard__c
from salesforce.approval_history__c ah
inner join salesforce.audit_report_group__c arg on ah.RAudit_Report_Group__c = arg.Id
inner join salesforce.arg_work_item__c argwi on arg.Id = argwi.RAudit_Report_Group__c and argwi.IsDeleted = 0
inner join salesforce.work_item__c wi on argwi.RWork_Item__c = wi.Id
left join salesforce.Resource__c r on ah.RApprover__c = r.Id
left join salesforce.country_code_setup__c ccs on r.Home_Country1__c = ccs.Id
where ah.IsDeleted = 0
and arg.Audit_Report_Status__c = 'Completed'
and ah.CreatedDate >= '2016'
group by `Period`, ah.Status__c, ah.Assigned_To__c, r.Id, wi.Revenue_Ownership__c, wi.Primary_Standard__c);


(select 
t2.`ActionDate/Time`,
t2.RevenueOwnerships,
if(analytics.getCountryFromRevenueOwnership(t2.RevenueOwnerships)='UK', 'United Kingdom', analytics.getCountryFromRevenueOwnership(t2.RevenueOwnerships)) as 'Rev Owner Country',
analytics.getRegionFromCountry(if(analytics.getCountryFromRevenueOwnership(t2.RevenueOwnerships)='UK', 'United Kingdom', analytics.getCountryFromRevenueOwnership(t2.RevenueOwnerships))) as 'Rev Owner Region',
t2.primaryStandards,
t2.ProgramBusinessLines,
if(t2.`Action`='Requested Technical Review', ca.Name, t2.`ActionedBy`) as 'Resource',
analytics.getRegionFromCountry(if(t2.`Action`='Requested Technical Review', ccs2.NAme, t2.`ActionBy Country`)) as 'Resource Region',
if(t2.`Action`='Requested Technical Review', ccs2.NAme, t2.`ActionBy Country`) as 'Resource Country',
if (t2.`Action`='Requested Technical Review', 'Requested TR',
	if(t2.`Rejections`>0 and not(t2.`First_Rejected`=t2.`ActionDate/Time`), 'Re-Submission',
	#if (t2.Rejections>1, 'Re-Submission',
		#if (t2.`TR Requests`=1 and not(t2.`Assigned To`='Certification Approver'), 'Post TR',
			if (t2.ProgramBusinessLines like '%Food%',
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
if (t2.`Action`='Requested Technical Review', 5,
	if(t2.`Rejections`>0 and not(t2.`First_Rejected`=t2.`ActionDate/Time`), 5,
	#if (t2.Rejections>1, 'Re-Submission',
		#if (t2.`TR Requests`=1 and not(t2.`Assigned To`='Certification Approver'), 'Post TR',
			if (t2.t2.ProgramBusinessLines like '%Food%',
				#Food
				if(t2.PrimaryStandards like '%BRC%',
					#BRC
					if(t2.WorkItemTypes like '%Follow Up%' or t2.WorkItemTypes like '%Gap%',
						15,
						60
					),
					if(t2.PrimaryStandards like '%SQF%' or t2.PrimaryStandards like '%FSSC%',
						#SQF/FSSC
						if(t2.WorkItemTypes like '%Follow Up%' or t2.WorkItemTypes like '%Gap%',
							15,
							25
						),
						#General Food
						if(t2.WorkItemTypes like '%Follow Up%',
							10,
							if(t2.WorkItemsNo<3,
								6,
								if(t2.WorkItemsNo<6,
									15,
									25
								)
							)
						)		
					)
				),
				if(t2.PrimaryStandards like '%16949%',
					# Automotive
					if(t2.WorkItemTypes like '%Follow Up%',
						17,
						25
					),
					# Management Systems
					if(t2.WorkItemTypes like '%Follow Up%',
						5,
						if(t2.WorkItemsNo<4,
							8,
							if(t2.WorkItemsNo<12,
								15,
								24
							)
						)
					)
				)
			)
		#)
	)
) as 'Activity Duration (min)',
count(t2.ARG_Id) as 'Completed',
group_concat(t2.ARG_Name) as 'ARG Names'
from (select t.*, 
		r.Name as 'ActionedBy',
        ccs.NAme as 'ActionBy Country',
		r.Reporting_Business_Units__c,
		ah.Timestamp__c as 'ActionDate/Time',
		ah.Id as 'ActionId',
        wi.Id as 'Work Item Id',
        wi.Name as 'Work Item Name',
		ah.Status__c as 'Action',
		ah.Assigned_To__c as 'Assigned To',
		group_concat(distinct wi.Revenue_Ownership__c) as 'RevenueOwnerships',
		count(distinct wi.Id) as 'WorkItemsNo',
		group_concat(distinct wi.Work_Item_Stage__c) as 'WorkItemTypes',
		group_concat(distinct wi.Primary_Standard__c) as 'PrimaryStandards',
		group_concat(distinct stpr.Program_Business_Line__c) as 'ProgramBusinessLines',
		GROUP_CONCAT(DISTINCT IF((`scsf`.`IsDeleted` OR `sp`.`IsDeleted`OR `s`.`IsDeleted`),NULL,`s`.`Name`) SEPARATOR ',') AS `Standard Families`
		from (select ah.RAudit_Report_Group__c as 'ARG_Id',
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
				from salesforce.approval_history__c ah 
				inner join salesforce.audit_report_group__c arg on arg.Id = ah.RAudit_Report_Group__c 
				where ah.RAudit_Report_Group__c is not null 
				and (arg.Work_Item_Stages__c not like '%Initial Project%' or arg.Work_Item_Stages__c not like '%Product Update%' or arg.Work_Item_Stages__c not like '%Standard Change%')
                #and arg.Name = 'ARG-315297'
				group by ah.RAudit_Report_Group__c) t
		inner join salesforce.Approval_History__c ah on ah.RAudit_Report_Group__c = t.ARG_Id
		inner join salesforce.Resource__c r on ah.RApprover__c = r.Id
        left join salesforce.country_code_setup__c ccs on r.Home_Country1__c = ccs.Id
		inner join salesforce.arg_work_item__c argwi on argwi.RAudit_Report_Group__c = t.Arg_Id 
		inner join salesforce.work_item__c wi on wi.id = argwi.RWork_Item__c 
		inner join salesforce.`site_certification_standard_program__c` `scsp` ON `wi`.`Site_Certification_Standard__c` = `scsp`.`Id`
		inner join salesforce.`standard_program__c` `stpr` on scsp.Standard_Program__c = stpr.Id
		LEFT JOIN salesforce.`site_certification_standard_family__c` `scsf` ON `scsf`.`Site_Certification_Standard__c` = `scsp`.`Id`
		LEFT JOIN salesforce.`standard_program__c` `sp` ON `scsf`.`Standard_Program__c` = `sp`.`Id`
		LEFT JOIN salesforce.`standard__c` `s` ON `sp`.`Standard__c` = `s`.`Id`
		where
		wi.IsDeleted=0 
        and wi.Status__c not in ('Cancelled') 
        and argwi.IsDeleted=0 
		and ah.IsDeleted=0
		and ah.Status__c in ('Approved','Rejected', 'Requested Technical Review')
		and date_format(ah.Timestamp__c, '%Y %m') >= '2015 11'
		group by ah.Id, wi.Id) t2
left join salesforce.Resource__c ca on t2.Assigned_CA__c = ca.Id
left join salesforce.country_code_setup__c ccs2 on ca.Home_Country1__c = ccs2.Id
group by 
t2.`ActionId`, t2.`Work Item Id`);

# Technical Resource Approval Workload. Top Standards, Utilisation.