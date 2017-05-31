set @past_months = 6;
set @future_months = 6;

(select * from (
# Audit and Travel
(select rt.NAme as 'Record Type',
	r.Reporting_Business_Units__c as 'Reporting Business Unit', r.Resource_Type__c as 'Resource Type', r.Id as 'Resource Id', r.Name as 'Resource', m.Name as 'Manager',
    wi.Id as 'Work Item Id', wi.Name as 'Work Item', wir.Work_Item_Type__c as 'Resource Work Type', wi.Status__c as 'Work Item Status',
    p.Business_Line__c as 'Business Line', p.Name as 'Program', s.Name as 'Standard', 
    Start_Time__c as 'Date', date_format(Start_Time__c, '%Y %m') as 'Period', wir.Total_Duration__c/8 as 'Duration (Days)',
    '' as 'Note',0 as 'Project Historical Duration (hours)',0 as 'Pre Paid Hours',0 as '# TSLI',0 as 'TSLI Hours'
from salesforce.work_item__c wi
	inner join salesforce.recordtype rt on wi.RecordTypeId = rt.Id
	inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
	inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
	inner join salesforce.standard__c s on sp.Standard__c = s.Id
	inner join salesforce.program__c p on sp.Program__c = p.Id
	inner join salesforce.work_item_resource__c wir on wir.Work_Item__c = wi.Id
	inner join salesforce.resource__c r on wir.Resource__c = r.Id
    left join salesforce.user u on r.User__c = u.Id
    left join salesforce.user m on u.ManagerId = m.Id
where
	wi.IsDeleted= 0
    and wir.IsDeleted = 0
    and rt.Name = 'Audit'
    and wir.Start_Time__c >= date_format(date_add(utc_timestamp(), interval -@past_months month), '%Y=%m-01')
    and wir.Start_Time__c < date_format(date_add(utc_timestamp(), interval (@future_months+1) month), '%Y=%m-01')
    and wi.Status__c not in ('Budget','Cancelled')
    and r.Reporting_Business_Units__c like '%Product%')
union
# BOP
(select 'BOP' as 'Record Type',
	r.Reporting_Business_Units__c as 'Reporting Business Unit', r.Resource_Type__c as 'Resource Type', r.Id as 'Resource Id', r.Name as 'Resource', m.Name as 'Manager',
    null as 'Work Item Id', null as 'Work Item', bop.Resource_Blackout_Type__c as 'Resource Work Type', null as 'Work Item Status',
    null as 'Business Line', null as 'Program', null as 'Standard', 
    e.StartDateTime as 'Date', date_format(e.StartDateTime, '%Y %m') as 'Period', e.DurationInMinutes/60/8 as 'Duration (Days)',
    '' as 'Note',0 as 'Project Historical Duration (hours)',0 as 'Pre Paid Hours',0 as '# TSLI',0 as 'TSLI Hours'
from salesforce.blackout_period__c bop
	inner join salesforce.event e on e.WhatId = bop.Id
    inner join salesforce.resource__c r on bop.Resource__c = r.Id
    left join salesforce.user u on r.User__c = u.Id
    left join salesforce.user m on u.ManagerId = m.Id
where
	bop.IsDeleted= 0
    and e.IsDeleted = 0
    and bop.Event_Removed__c = 0
    and e.StartDateTime >= date_format(date_add(utc_timestamp(), interval -@past_months month), '%Y=%m-01')
    and e.StartDateTime < date_format(date_add(utc_timestamp(), interval (@future_months+1) month), '%Y=%m-01')
    and r.Reporting_Business_Units__c like '%Product%')
union
# Projects
(select rt.Name as 'Record Type',
	r.Reporting_Business_Units__c as 'Reporting Business Unit', r.Resource_Type__c as 'Resource Type', r.Id as 'Resource Id', r.Name as 'Resource', m.Name as 'Manager',
    wi.Id as 'Work Item Id', wi.Name as 'Work Item', wi.Work_Item_Stage__C as 'Resource Work Type', wi.Status__c as 'Work Item Status',
    p.Business_Line__c as 'Business Line', p.Name as 'Program', s.Name as 'Standard', 
    if(wi.Status__c='Completed', 
		#if (wi.Project_Projected_End_Date__c between date_format(date_add(utc_timestamp(), interval -@past_months month), '%Y=%m-01') and date_format(date_add(utc_timestamp(), interval (@future_months+1) month), '%Y=%m-01'),
		#	wi.Project_Projected_End_Date__c,wi.Project_End_Date__c),
        ifnull(wi.Project_End_Date__c,wi.Project_Projected_End_Date__c),
		if (wi.Project_Projected_End_Date__c is null,utc_timestamp(),wi.Project_Projected_End_Date__c)
	) as 'Date',
    date_format(if(wi.Status__c='Completed', 
		#if (wi.Project_Projected_End_Date__c between date_format(date_add(utc_timestamp(), interval -@past_months month), '%Y=%m-01') and date_format(date_add(utc_timestamp(), interval (@future_months+1) month), '%Y=%m-01'),
		#	wi.Project_Projected_End_Date__c,wi.Project_End_Date__c),
        ifnull(wi.Project_End_Date__c,wi.Project_Projected_End_Date__c),
		if (wi.Project_Projected_End_Date__c is null,utc_timestamp(),wi.Project_Projected_End_Date__c)
	), '%Y %m')  as 'Period',
    if(wi.Status__c='Completed', 
		ifnull(sum(tsli.Actual_Hours__c),0),
		if(wi.Work_Item_Stage__c = 'Initial Project',
			greatest(ifnull(wi.Hours_Pre_paid__c,analytics.getPSProjectDurationMin(p.Pathway__c,wi.Work_Item_Stage__c)/60) - ifnull(sum(tsli.Actual_Hours__c),0),0),
			greatest(analytics.getPSProjectDurationMin(p.Pathway__c,wi.Work_Item_Stage__c)/60 - ifnull(sum(tsli.Actual_Hours__c),0),0)
		)
	)/8 as 'Duration (Days)',
    if(wi.Status__c='Completed', 
		if (wi.Project_Projected_End_Date__c between date_format(date_add(utc_timestamp(), interval -@past_months month), '%Y=%m-01') and date_format(date_add(utc_timestamp(), interval (@future_months+1) month), '%Y=%m-01'),
			if(wi.Work_Item_Stage__c = 'Initial Project', 'Initial Project - Completed - Projected End Date OK. Duration: T&E, Period: Projected End Date', 'Product Update - Completed - Projected End Date OK. Duration: T&E, Period: Projected End Date'),
			if(wi.Project_End_Date__c between date_format(date_add(utc_timestamp(), interval -@past_months month), '%Y=%m-01') and date_format(date_add(utc_timestamp(), interval (@future_months+1) month), '%Y=%m-01'), 
				if(wi.Work_Item_Stage__c = 'Initial Project', 'Initial Project - Completed - Projected End Date Missing. Duration: T&E, Period: End Date', 'Product Update - Completed - Projected End Date Missing. Duration: T&E, Period: End Date'),
				-1
			)
		),
		if (wi.Project_Projected_End_Date__c is null,
			if(wi.Work_Item_Stage__c = 'Initial Project',
				if(wi.Hours_Pre_paid__c is null, 'Initial Project - Not Completed - Projected End Date missing - Prepaid Hours missing. Duration: Historical minus T&E, Period: current month', 'Initial Project - Not Completed - Projected End Date missing - Prepaid Hours OK. Duration: Prepaid minus T&E, Period: current month'),
				# Product Update
				'Product Update - Not Completed - Projected End Date Missing. Duration: historical minus T&E, Period: current month'
			),
			if (wi.Project_Projected_End_Date__c between date_format(date_add(utc_timestamp(), interval -@past_months month), '%Y=%m-01') and date_format(date_add(utc_timestamp(), interval (@future_months+1) month), '%Y=%m-01'),
				if(wi.Work_Item_Stage__c = 'Initial Project',
					if(wi.Hours_Pre_paid__c is null, 'Initial Project - Not Completed - Projected End Date OK - Prepaid Hours Missing. Duration: Historical minus T&E, Period: Projected End Date', 'Initial Project - Not Completed - Projected End Date OK - Prepaid Hours OK. Duration: Prepaid minus T&E, Period: Projected End Date'),
					# Product Update
					'Product Update - Not Completed - Projected End Date OK. Duration: Historical minus T&E, Period: Projected End Date'
				),
				-1
			)
		)
	) as 'Note',
    analytics.getPSProjectDurationMin(p.Pathway__c,wi.Work_Item_Stage__c)/60 as 'Project Historical Duration (hours)',
    wi.Hours_Pre_paid__c as 'Pre Paid Hours',
    count(distinct tsli.Id) as '# TSLI',
    ifnull(sum(tsli.Actual_Hours__c),0) as 'TSLI Hours'
from salesforce.work_item__c wi
	left join salesforce.timesheet_line_item__c tsli on tsli.Work_Item__c = wi.Id
	inner join salesforce.recordtype rt on wi.RecordTypeId = rt.Id
	inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
	inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
	inner join salesforce.standard__c s on sp.Standard__c = s.Id
	inner join salesforce.program__c p on sp.Program__c = p.Id
	left join salesforce.resource__c r on wi.Work_Item_Owner__c = r.Id
    left join salesforce.user u on r.User__c = u.Id
    left join salesforce.user m on u.ManagerId = m.Id
where
	wi.IsDeleted= 0
    and rt.Name = 'Project'
    and wi.Status__c not in ('Budget','Cancelled')
    and r.Reporting_Business_Units__c like '%Product%'
    and if(wi.Status__c='Completed', 
			wi.Project_Projected_End_Date__c between date_format(date_add(utc_timestamp(), interval -@past_months month), '%Y=%m-01') and date_format(date_add(utc_timestamp(), interval (@future_months+1) month), '%Y=%m-01')
			or wi.Project_End_Date__c between date_format(date_add(utc_timestamp(), interval -@past_months month), '%Y=%m-01') and date_format(date_add(utc_timestamp(), interval (@future_months+1) month), '%Y=%m-01'),
            (wi.Project_Projected_End_Date__c between date_format(date_add(utc_timestamp(), interval -@past_months month), '%Y=%m-01') and date_format(date_add(utc_timestamp(), interval (@future_months+1) month), '%Y=%m-01')) or wi.Project_Projected_End_Date__c is null
		)
group by wi.Id)
union all
#CA Approvals
(select 'ARG' as 'Record Type',
	r.Reporting_Business_Units__c as 'Reporting Business Unit', r.Resource_Type__c as 'Resource Type', r.Id as 'Resource Id', r.Name as 'Resource', m.Name as 'Manager',
    arg.Id as 'Record Id', arg.Name as 'Record Name', 'CA Approvals' as 'Resource Work Type', 'n/a' as 'Work Item Status',
    p.Business_Line__c as 'Business Line', p.Name as 'Program', s.Name as 'Standard', 
    ah.CreatedDate as 'Date', date_format(ah.CreatedDate, '%Y %m') as 'Period', 0.0868055555556 as 'Duration (Days)', # 30 minutes with productivity 72%
    '' as 'Note',0 as 'Project Historical Duration (hours)',0 as 'Pre Paid Hours',0 as '# TSLI',0 as 'TSLI Hours'
from salesforce.approval_history__c ah
	inner join salesforce.audit_report_group__c arg on arg.Id = ah.RAudit_Report_Group__c
	inner join salesforce.arg_work_item__c argwi on argwi.RAudit_Report_Group__c = arg.Id
	inner join salesforce.work_item__c wi on argwi.RWork_Item__c = wi.Id
	inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
	inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
	inner join salesforce.standard__c s on sp.Standard__c = s.Id
	inner join salesforce.program__c p on sp.Program__c = p.Id
    left join salesforce.resource__c r on ah.RApprover__c = r.Id
    left join salesforce.user u on r.User__c = u.Id
    left join salesforce.user m on u.ManagerId = m.Id
where
	arg.IsDeleted= 0
    and ah.IsDeleted = 0
    and argwi.IsDeleted = 0
    and ah.CreatedDate >= date_format(date_add(utc_timestamp(), interval -@past_months month), '%Y=%m-01')
    and ah.CreatedDate < date_format(date_add(utc_timestamp(), interval (@future_months+1) month), '%Y=%m-01')
    and ah.Status__c = 'Approved'
    and ah.Assigned_To__c = 'Client Administration'
    and r.Reporting_Business_Units__c like '%Product%'
group by arg.Id, ah.Id)
) t 
where 
	t.`Date` >= date_format(date_add(utc_timestamp(), interval -@past_months month), '%Y=%m-01')
    and t.`Date` < date_format(date_add(utc_timestamp(), interval (@future_months+1) month), '%Y=%m-01'));

(select rt.Name as 'Record Type',
	r.Reporting_Business_Units__c as 'Reporting Business Unit', r.Resource_Type__c as 'Resource Type', r.Id as 'Resource Id', r.Name as 'Resource', m.Name as 'Manager',
    wi.Id as 'Work Item Id', wi.Name as 'Work Item', wi.Work_Item_Stage__C as 'Resource Work Type', wi.Status__c as 'Work Item Status',
    p.Business_Line__c as 'Business Line', p.Name as 'Program', s.Name as 'Standard', 
    #wi.Project_End_Date__c as 'Date', date_format(wi.Project_End_Date__c, '%Y %m') as 'Period', 
    if(wi.Status__c='Completed', 
		if (wi.Project_Projected_End_Date__c between date_format(date_add(utc_timestamp(), interval -@past_months month), '%Y=%m-01') and date_format(date_add(utc_timestamp(), interval (@future_months+1) month), '%Y=%m-01'),
			wi.Project_Projected_End_Date__c,
			if(wi.Project_End_Date__c between date_format(date_add(utc_timestamp(), interval -@past_months month), '%Y=%m-01') and date_format(date_add(utc_timestamp(), interval (@future_months+1) month), '%Y=%m-01'), 
				wi.Project_End_Date__c,
				'Error'
			)
		),
		if (wi.Project_Projected_End_Date__c is null,
			utc_timestamp(),
			if (wi.Project_Projected_End_Date__c between date_format(date_add(utc_timestamp(), interval -@past_months month), '%Y=%m-01') and date_format(date_add(utc_timestamp(), interval (@future_months+1) month), '%Y=%m-01'),
				wi.Project_Projected_End_Date__c,
				'Error'
			)
		)
	) as 'Date',
    date_format(if(wi.Status__c='Completed', 
		if (wi.Project_Projected_End_Date__c between date_format(date_add(utc_timestamp(), interval -@past_months month), '%Y=%m-01') and date_format(date_add(utc_timestamp(), interval (@future_months+1) month), '%Y=%m-01'),
			wi.Project_Projected_End_Date__c,
			if(wi.Project_End_Date__c between date_format(date_add(utc_timestamp(), interval -@past_months month), '%Y=%m-01') and date_format(date_add(utc_timestamp(), interval (@future_months+1) month), '%Y=%m-01'), 
				wi.Project_End_Date__c,
				'Error'
			)
		),
		if (wi.Project_Projected_End_Date__c is null,
			utc_timestamp(),
			if (wi.Project_Projected_End_Date__c between date_format(date_add(utc_timestamp(), interval -@past_months month), '%Y=%m-01') and date_format(date_add(utc_timestamp(), interval (@future_months+1) month), '%Y=%m-01'),
				wi.Project_Projected_End_Date__c,
				'Error'
			)
		)
	), '%Y %m')  as 'Period',
    if(wi.Status__c='Completed', 
		if (wi.Project_Projected_End_Date__c between date_format(date_add(utc_timestamp(), interval -@past_months month), '%Y=%m-01') and date_format(date_add(utc_timestamp(), interval (@future_months+1) month), '%Y=%m-01'),
			'Completed Projected End Date in Range',
			if(wi.Project_End_Date__c between date_format(date_add(utc_timestamp(), interval -@past_months month), '%Y=%m-01') and date_format(date_add(utc_timestamp(), interval (@future_months+1) month), '%Y=%m-01'), 
				'Completed End Date in Range',
				'Error'
			)
		),
		if (wi.Project_Projected_End_Date__c is null,
			'Not Completed with no projected End Date',
			if (wi.Project_Projected_End_Date__c between date_format(date_add(utc_timestamp(), interval -@past_months month), '%Y=%m-01') and date_format(date_add(utc_timestamp(), interval (@future_months+1) month), '%Y=%m-01'),
				'Not Completed with Projected End DAte in Range',
				'Error'
			)
		)
	) as 'Category',
	
    if(wi.Status__c='Completed', 
		if (wi.Project_Projected_End_Date__c between date_format(date_add(utc_timestamp(), interval -@past_months month), '%Y=%m-01') and date_format(date_add(utc_timestamp(), interval (@future_months+1) month), '%Y=%m-01'),
			ifnull(sum(tsli.Actual_Hours__c),0),
			if(wi.Project_End_Date__c between date_format(date_add(utc_timestamp(), interval -@past_months month), '%Y=%m-01') and date_format(date_add(utc_timestamp(), interval (@future_months+1) month), '%Y=%m-01'), 
				ifnull(sum(tsli.Actual_Hours__c),0),
				-1
			)
		),
		if (wi.Project_Projected_End_Date__c is null,
			if(wi.Work_Item_Stage__c = 'Initial Project',
				greatest(ifnull(wi.Hours_Pre_paid__c,analytics.getPSProjectDurationMin(p.Pathway__c,wi.Work_Item_Stage__c)/60) - ifnull(sum(tsli.Actual_Hours__c),0),0),
				# Product Update
				greatest(analytics.getPSProjectDurationMin(p.Pathway__c,wi.Work_Item_Stage__c)/60 - ifnull(sum(tsli.Actual_Hours__c),0),0)
			),
			if (wi.Project_Projected_End_Date__c between date_format(date_add(utc_timestamp(), interval -@past_months month), '%Y=%m-01') and date_format(date_add(utc_timestamp(), interval (@future_months+1) month), '%Y=%m-01'),
				if(wi.Work_Item_Stage__c = 'Initial Project',
					greatest(ifnull(wi.Hours_Pre_paid__c,analytics.getPSProjectDurationMin(p.Pathway__c,wi.Work_Item_Stage__c)/60) - ifnull(sum(tsli.Actual_Hours__c),0),0),
					# Product Update
					greatest(analytics.getPSProjectDurationMin(p.Pathway__c,wi.Work_Item_Stage__c)/60 - ifnull(sum(tsli.Actual_Hours__c),0),0)
				),
				-1
			)
		)
	) as 'Duration (Hrs)',
    if(wi.Status__c='Completed', 
		if (wi.Project_Projected_End_Date__c between date_format(date_add(utc_timestamp(), interval -@past_months month), '%Y=%m-01') and date_format(date_add(utc_timestamp(), interval (@future_months+1) month), '%Y=%m-01'),
			if(wi.Work_Item_Stage__c = 'Initial Project', 'Completed Initial Project - Duration based on T&E', 'Completed Product Update - Duration based on T&E'),
			if(wi.Project_End_Date__c between date_format(date_add(utc_timestamp(), interval -@past_months month), '%Y=%m-01') and date_format(date_add(utc_timestamp(), interval (@future_months+1) month), '%Y=%m-01'), 
				if(wi.Work_Item_Stage__c = 'Initial Project', 'Completed Initial Project - Duration based on T&E', 'Completed Product Update - Duration based on T&E'),
				-1
			)
		),
		if (wi.Project_Projected_End_Date__c is null,
			if(wi.Work_Item_Stage__c = 'Initial Project',
				if(wi.Hours_Pre_paid__c is null, 'Not Completed Initial Project - No Prepaid Hours - Using historical duration minus logged T&E', 'Not Completed Initial Project - Using Prepaid Hours minus logged T&E'),
				# Product Update
				'Not Completed Product Update - Using historical duration minus logged T&E'
			),
			if (wi.Project_Projected_End_Date__c between date_format(date_add(utc_timestamp(), interval -@past_months month), '%Y=%m-01') and date_format(date_add(utc_timestamp(), interval (@future_months+1) month), '%Y=%m-01'),
				if(wi.Work_Item_Stage__c = 'Initial Project',
					if(wi.Hours_Pre_paid__c is null, 'Not Completed Initial Project - No Prepaid Hours - Using historical duration minus logged T&E', 'Not Completed Initial Project - Using Prepaid Hours minus logged T&E'),
					# Product Update
					'Not Completed Product Update - Using historical duration minus logged T&E'
				),
				-1
			)
		)
	) as 'Duration Comment',
    analytics.getPSProjectDurationMin(p.Pathway__c,wi.Work_Item_Stage__c)/60 as 'Project Historical Duration (hours)',
    wi.Hours_Pre_paid__c as 'Pre Paid Hours',
    count(distinct tsli.Id) as '# TSLI',
    ifnull(sum(tsli.Actual_Hours__c),0) as 'TSLI Hours'
from salesforce.work_item__c wi
	left join salesforce.timesheet_line_item__c tsli on tsli.Work_Item__c = wi.Id
	inner join salesforce.recordtype rt on wi.RecordTypeId = rt.Id
	inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
	inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
	inner join salesforce.standard__c s on sp.Standard__c = s.Id
	inner join salesforce.program__c p on sp.Program__c = p.Id
	left join salesforce.resource__c r on wi.Work_Item_Owner__c = r.Id
    left join salesforce.user u on r.User__c = u.Id
    left join salesforce.user m on u.ManagerId = m.Id
where
	wi.IsDeleted= 0
    and rt.Name = 'Project'
    and wi.Status__c not in ('Budget','Cancelled')
    and r.Reporting_Business_Units__c like '%Product%'
    and if(wi.Status__c='Completed', 
			wi.Project_Projected_End_Date__c between date_format(date_add(utc_timestamp(), interval -@past_months month), '%Y=%m-01') and date_format(date_add(utc_timestamp(), interval (@future_months+1) month), '%Y=%m-01')
			or wi.Project_End_Date__c between date_format(date_add(utc_timestamp(), interval -@past_months month), '%Y=%m-01') and date_format(date_add(utc_timestamp(), interval (@future_months+1) month), '%Y=%m-01'),
            (wi.Project_Projected_End_Date__c between date_format(date_add(utc_timestamp(), interval -@past_months month), '%Y=%m-01') and date_format(date_add(utc_timestamp(), interval (@future_months+1) month), '%Y=%m-01')) or wi.Project_Projected_End_Date__c is null
		)
group by wi.Id);