

(select 
	t2.*,
	sum(analytics.getPSActivityDurationMin(salesforce.getCriteriaWithType(left(substring_index(c.name__c,'**Client Output Language Not Found For This Criteria** ',-1),90), `t2`.`Conformity_Type__c`)))/60/.73 as 'Enlighten Completed Activities FTE Hrs',
    sum(if(c.Applicability__c='Mandatory', analytics.getPSActivityDurationMin(salesforce.getCriteriaWithType(left(substring_index(c.name__c,'**Client Output Language Not Found For This Criteria** ',-1),90), `t2`.`Conformity_Type__c`)), 0))/60/.73 as 'Enlighten Completed Mandatory Activities FTE Hrs',
    sum(if(c.Applicability__c='Optional', analytics.getPSActivityDurationMin(salesforce.getCriteriaWithType(left(substring_index(c.name__c,'**Client Output Language Not Found For This Criteria** ',-1),90), `t2`.`Conformity_Type__c`)), 0))/60/.73 as 'Enlighten Completed Optional Activities FTE Hrs'
from
	(select 
		t.*,
		sum(if(pr.UOM__c='DAY', ili.Quantity__c*8, 
				if(pr.UOM__c='HFD', ili.Quantity__c*4, 
					if(pr.UOM__c='HR', ili.Quantity__c,0)
				)
			)
		) as 'Invoiced Hours',
		sum(if(pr.UOM__c='KM', ili.Quantity__c,0)) as 'Invoiced Km',
		ifnull(group_Concat(distinct ili.id), '') as 'ILIs',
		ifnull(group_Concat(distinct ili.Invoice__c), '') as 'Invoices'
	from
		(select 
			client.Name as 'Client',
			site.Name as 'Site',
			continent.name as 'Site Continent',
			country.sai_region as 'Site SAI Region',
			country.name as 'Site Country',
			country.full_name as 'Site Country Full Name',
			csp.SAI_Certificate_Number__c as 'SAI Certificate No.',
			pm.name as 'Project Manager',
			wi.Id as 'WI Id', 
			wi.Name as 'Work Item',
            wi.Project_Start_Date__c as 'Project Start Date',
            year(wi.Project_Start_Date__c) as 'Project Start Year', 
			wi.Work_Item_Stage__c as 'Work Item Type', 
			p.Business_Line__c as 'Business Line',
			p.Pathway__c as 'Pathway',
			p.Name as 'Program',
			s.Name as 'Standard',
            s.Conformity_Type__c ,
			sum(tsli.Actual_Hours__c) as 'Project Time Actual Hours',
			sum(if(tsli.Billable__c = 'Billable', tsli.Actual_Hours__c, 0)) as 'Project Time Billable Hours',
			sum(if(tsli.Billable__c = 'Non-Billable', tsli.Actual_Hours__c, 0)) as 'Project Time Non-Billable Hours',
			sum(if(tsli.Billable__c = 'Pre-paid', tsli.Actual_Hours__c, 0)) as 'Project Time Pre-paid Hours',
			ifnull(group_Concat(distinct tsli.id), '') as 'TSLIs'
		from salesforce.work_item__c wi
			inner join salesforce.site_certification_standard_program__c scsp on scsp.Id = wi.Site_Certification_Standard__c
			inner join salesforce.certification_standard_program__c csp on scsp.Certification_Standard__c = csp.Id
			inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
			inner join salesforce.standard__c s on sp.Standard__c = s.Id
			inner join salesforce.program__c p on sp.Program__c = p.Id
			inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
			inner join salesforce.certification__c c on sc.Primary_Certification__c = c.Id
			inner join salesforce.account site on sc.Primary_client__c = site.Id
			left join salesforce.resource__c pm on c.Project_Manager_2__c = pm.id
			left join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id
			left join analytics.countries_names cn on ccs.Name = cn.name
			left join analytics.countries country on cn.code = country.code
			left join analytics.continents continent on country.continent_code = continent.code
			inner join salesforce.account client on site.ParentId = client.Id
			inner join salesforce.recordtype rt on wi.RecordTypeId = rt.Id
			left join salesforce.timesheet_line_item__c tsli on tsli.Work_Item__c = wi.Id and tsli.IsDeleted = 0 and tsli.Category__c = 'Project Time'
		where
			wi.IsDeleted = 0
			and rt.name = 'Project'
			and wi.Status__c = 'Completed'
		group by wi.Id) t
		left join salesforce.invoice_line_item__c ili on ili.Work_Item__c = t.`WI Id` and ili.IsDeleted = 0
		left join salesforce.product2 pr on ili.Product__c = pr.Id
	group by t.`WI Id`) t2
    left join salesforce.criteria__c c on c.Work_Item__c = t2.`WI Id` and c.IsDeleted = 0 and c.Status__c = 'Completed'
group by t2.`WI Id`
);