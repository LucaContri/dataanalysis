set @employee_rate = 100;
set @contractor_rate = 110;
set @region = 'APAC';

(select t.`Business Line`, t.`Pathway`, t.`Program`, t.`Primary Standard`, t.`Revenue Ownership Region`, t.`Revenue Ownership Country`, t.`Revenue Ownership`, t.`Site Region`, t.`Site Country`, t.`Resource Country`, t.`Intercountry Auditor`, date_format(t.`Date`, '%Y-%m') as 'Period', year(t.`Date`) as 'Year', date_format(t.`Date`, '%m') as 'Month', t.`Category`, 
sum(if(t.`Record Type` = 'Expense Line Item', t.`Amount (AUD)`, 0)) as 'Non Billable Expenses (AUD)',
sum(if(t.`Record Type` = 'Timesheet Line Item', t.`Value`, 0)) as 'Non Billable Resource Hours',
sum(if(t.`Record Type` = 'Timesheet Line Item', t.`Amount (AUD)`, 0)) as 'Non Billable Resource Cost (AUD)',
sum(if(t.`Record Type` = 'Audit Days', t.`Value`, 0))/8 as 'Completed Audit Days' from (

	#Expenses
	select 
		'Expense Line Item' as 'Record Type',
		wi.Id as 'WI Id',
		wi.Name as 'Work Item',
		p.Business_Line__c as 'Business Line',
        p.Pathway__c as 'Pathway',
        p.Name as 'Program',
        wi.Primary_Standard__c as 'Primary Standard',
		analytics.getRegionFromCountry(analytics.getCountryFromRevenueOwnership(wi.Revenue_Ownership__c)) as 'Revenue Ownership Region',
		analytics.getCountryFromRevenueOwnership(wi.Revenue_Ownership__c) as 'Revenue Ownership Country',
		wi.Revenue_Ownership__c as 'Revenue Ownership',
		site.Name as 'Client Site',
		analytics.getRegionFromCountry(sccs.Name) as 'Site Region',
		sccs.Name as 'Site Country',
		sscs.Name as 'Site State',
		r.Id as 'Resource Id',
		r.Name as 'Resource Name',
		analytics.getRegionFromCountry(rccs.Name) as 'Resource Region',
		rccs.Name as 'Resource Country',
		rscs.Name as 'Resource State',
		if (rccs.Name = sccs.Name, false, true) as 'Intercountry Auditor',
		if (rscs.Name = sscs.Name, false, true) as 'Interstate Auditor',
		eli.Category__c as 'Category',
		eli.Status__c as 'Status',
		eli.Expense_Date__c as 'Date',
		eli.Expense_Type__c as 'Type',
		eli.Description__c as 'Description',
		eli.Billable__c as 'Billable',
		eli.Total_Amount_incl_Tax__c as 'Value',
		eli.CurrencyIsoCode as 'Unit',
		eli.Total_Amount_incl_Tax__c/ct.ConversionRate as 'Amount (AUD)'
	from salesforce.expense_line_item__c eli
		inner join salesforce.currencytype ct on eli.CurrencyIsoCode = ct.IsoCode
		inner join salesforce.work_item__c wi on eli.Work_Item__c = wi.Id
		inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
		inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
        inner join salesforce.program__c p on sp.Program__c = p.Id
		inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
		inner join salesforce.account site on sc.Primary_client__c = site.Id
		left join salesforce.country_code_setup__c sccs on site.Business_Country2__c = sccs.Id
		left join salesforce.state_code_setup__c sscs on site.Business_State__c = sscs.Id
		left join salesforce.resource__c r on eli.Resource_Name__c = r.Name
		left join salesforce.country_code_setup__c rccs on r.Home_Country1__c = rccs.Id
		left join salesforce.state_code_setup__c rscs on r.Home_State_Province__c = rscs.Id
	where 
		wi.Work_Item_Date__c between '2013-07-01' and '2016-11-30'
		and wi.Status__c in ('Completed')
		and eli.IsDeleted = 0
		and wi.IsDeleted = 0
		and eli.Billable__c = 'Non-Billable'
		and eli.Status__c = 'Submitted'
		and analytics.getRegionFromCountry(analytics.getCountryFromRevenueOwnership(wi.Revenue_Ownership__c)) = @region
	union all
	# Resource Cost
	select 
		'Timesheet Line Item' as 'Record Type',
		wi.Id as 'WI Id',
		wi.Name as 'Work Item',
		p.Business_Line__c as 'Business Line',
        p.Pathway__c as 'Pathway',
        p.Name as 'Program',
        wi.Primary_Standard__c as 'Primary Standard', 
		analytics.getRegionFromCountry(analytics.getCountryFromRevenueOwnership(wi.Revenue_Ownership__c)) as 'Revenue Ownership Region',
		analytics.getCountryFromRevenueOwnership(wi.Revenue_Ownership__c) as 'Revenue Ownership Country',
		wi.Revenue_Ownership__c as 'Revenue Ownership',
		site.Name as 'Client Site',
		analytics.getRegionFromCountry(sccs.Name) as 'Site Region',
		sccs.Name as 'Site Country',
		sscs.Name as 'Site State',
		r.Id as 'Resource Id',
		r.Name as 'Resource Name',
		analytics.getRegionFromCountry(rccs.Name) as 'Resource Region',
		rccs.Name as 'Resource Country',
		rscs.Name as 'Resource State',
		if (rccs.Name = sccs.Name, false, true) as 'Intercountry Auditor',
		if (rscs.Name = sscs.Name, false, true) as 'Interstate Auditor',
		tsli.Category__c,
		tsli.Status__c,
		wi.Work_Item_Date__c,
		tsli.Work_Item_Type__c,
		tsli.Additional_Comments__c,
		tsli.Billable__c ,
		tsli.Actual_Hours__c as 'Value',
		'Hour' as 'Unit',
		tsli.Actual_Hours__c*ifnull(if(r.Reporting_Business_Units__c like '%UK' and r.Resource_Type__c='Contractor' and wi.Work_Item_Stage__c='Follow Up',0, ar.`Avg Hourly Rate (AUD)`),if(r.Resource_Type__c='Employee',@employee_rate, @contractor_rate)) as 'Amount (AUD)'
	from salesforce.timesheet_line_item__c tsli
		inner join salesforce.work_item__c wi on tsli.Work_Item__c = wi.Id
		inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
		inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
        inner join salesforce.program__c p on sp.Program__c = p.Id
		inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
		inner join salesforce.account site on sc.Primary_client__c = site.Id
		left join salesforce.country_code_setup__c sccs on site.Business_Country2__c = sccs.Id
		left join salesforce.state_code_setup__c sscs on site.Business_State__c = sscs.Id
		left join salesforce.resource__c r on tsli.Resource_Name__c = r.Name
		left join salesforce.country_code_setup__c rccs on r.Home_Country1__c = rccs.Id
		left join salesforce.state_code_setup__c rscs on r.Home_State_Province__c = rscs.Id
		left join 
		(select * from (
			select ar.`Resource Id`, ar.period, ar.value/ct.ConversionRate as 'Avg Hourly Rate (AUD)', ar.`type`
			from `analytics`.`auditor_rates_2` ar  
			left join salesforce.currencytype ct on ar.currency_iso_code = ct.IsoCode  
			where ar.value>0 
			order by ar.`Resource Id` desc, ar.period desc) t 
		group by t.`Resource Id`) ar on ar.`resource id` = r.Id
	where 
		wi.Work_Item_Date__c between '2013-07-01' and '2016-11-30'
		and wi.Status__c in ('Completed')
		and tsli.IsDeleted = 0
		and wi.IsDeleted = 0
		and tsli.Billable__c = 'Non-Billable'
		and tsli.Status__c = 'Submitted'
		and analytics.getRegionFromCountry(analytics.getCountryFromRevenueOwnership(wi.Revenue_Ownership__c)) = @region
	union all
	# Audit Days
	select 
		'Audit Days' as 'Record Type',
		wi.Id as 'WI Id',
		wi.Name as 'Work Item',
        p.Business_Line__c as 'Business Line',
        p.Pathway__c as 'Pathway',
        p.Name as 'Program',
		wi.Primary_Standard__c as 'Primary Standard', 
		analytics.getRegionFromCountry(analytics.getCountryFromRevenueOwnership(wi.Revenue_Ownership__c)) as 'Revenue Ownership Region',
		analytics.getCountryFromRevenueOwnership(wi.Revenue_Ownership__c) as 'Revenue Ownership Country',
		wi.Revenue_Ownership__c as 'Revenue Ownership',
		site.Name as 'Client Site',
		analytics.getRegionFromCountry(sccs.Name) as 'Site Region',
		sccs.Name as 'Site Country',
		sscs.Name as 'Site State',
		r.Id as 'Resource Id',
		r.Name as 'Resource Name',
		analytics.getRegionFromCountry(rccs.Name) as 'Resource Region',
		rccs.Name as 'Resource Country',
		rscs.Name as 'Resource State',
		if (rccs.Name = sccs.Name, false, true) as 'Intercountry Auditor',
		if (rscs.Name = sscs.Name, false, true) as 'Interstate Auditor',
		'',
		'',
		wir.Start_Date__c,
		'',
		'',
		'',
		wir.Total_Duration__c as 'Value',
		'Hour' as 'Unit',
		''
	from salesforce.work_item__c wi 
		inner join salesforce.work_item_resource__c wir on wir.Work_Item__c = wi.Id
		inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
        inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
        inner join salesforce.program__c p on sp.Program__c = p.Id
		inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
		inner join salesforce.account site on sc.Primary_client__c = site.Id
		left join salesforce.country_code_setup__c sccs on site.Business_Country2__c = sccs.Id
		left join salesforce.state_code_setup__c sscs on site.Business_State__c = sscs.Id
		left join salesforce.resource__c r on wir.Resource__c = r.Id
		left join salesforce.country_code_setup__c rccs on r.Home_Country1__c = rccs.Id
		left join salesforce.state_code_setup__c rscs on r.Home_State_Province__c = rscs.Id
	where 
		wi.Work_Item_Date__c between '2013-07-01' and '2016-11-30'
		and wi.Status__c in ('Completed')
		and wi.IsDeleted = 0
		and wir.IsDeleted = 0
		and analytics.getRegionFromCountry(analytics.getCountryFromRevenueOwnership(wi.Revenue_Ownership__c)) = @region) t
group by t.`Business Line`, t.`Pathway`, t.`Program`, t.`Primary Standard`, t.`Revenue Ownership Region`, t.`Revenue Ownership Country`, t.`Revenue Ownership`, t.`Site Region`, t.`Site Country`, t.`Resource Country`, t.`Intercountry Auditor`, `Period`, t.`Category`);
