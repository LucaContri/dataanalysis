set @start_period = '2016-07';
set @end_period = '2016-12';
set @region = 'APAC';

# Expenses analysis
(SELECT    
    if(month(wi.Work_Item_Date__c)<7, Year(wi.Work_Item_Date__c),Year(wi.Work_Item_Date__c)+1) as 'F.Y.',
    date_format(wi.Work_Item_Date__c, '%Y-%m') as 'WI Period',
    a.Name as 'Billing Client',
	a.Client_Ownership__c as 'ClientOwnership',  
    wi.Revenue_Ownership__c as 'RevenueOwnership',
    analytics.getCountryFromRevenueOwnership(wi.Revenue_Ownership__c) as 'Rev Owner Country',
    analytics.getRegionFromCountry(analytics.getCountryFromRevenueOwnership(wi.Revenue_Ownership__c)) as 'Rev Owner Region',
	p.Business_Line__c AS 'BusinessLine',  
    p.Pathway__c as 'Pathway',   
    p.Name as 'Program',   
    p.Program_Code__c as 'Program Code',   
    ps.Name as 'Standard (Compass)',
    analytics.getSimpleStandardFromStandard(ps.Name, p.Name) as 'Standard',   
    eli.Category__c as 'Category',
    r.Resource_Type__c as 'Resource Type',
    eli.Billable__c as 'Billable',
    sum(eli.FTotal_Amount_Ex_Tax__c) as 'Total Expenses',
    eli.CurrencyIsoCode as 'Currency',
    sum(eli.FTotal_Amount_Ex_Tax__c / cur.ConversionRate) as 'Total Expenses (AUD)',
    sum(if(eli.Category__c not in ('Travel Costs - Accommodation','Travel Costs - Meals', 'Technical Advisor Hours'), eli.FTotal_Amount_Ex_Tax__c / cur.ConversionRate,0)) as 'Travel Expenses (AUD)',
    sum(if(eli.Category__c in ('Travel Costs - Accommodation'), eli.FTotal_Amount_Ex_Tax__c / cur.ConversionRate,0)) as 'Accommodation Expenses (AUD)',
    sum(if(eli.Category__c in ('Travel Costs - Meals'), eli.FTotal_Amount_Ex_Tax__c / cur.ConversionRate,0)) as 'Meal Expenses (AUD)',
    wi.Name as 'Work Item',
    wi.Required_Duration__c as 'Duration (Hrs)',
    r.Name as 'Auditor',
    analytics.distance(geo.Latitude, geo.Longitude, sgeo.Latitude, sgeo.Longitude)*2 as 'Resource Return Distance',
    ceil(analytics.distance(geo.Latitude, geo.Longitude, sgeo.Latitude, sgeo.Longitude)*2/100)*100 as 'Distance Group'
FROM salesforce.expense_line_item__c eli   
	INNER JOIN salesforce.daily_timesheet__c dts ON dts.Id = eli.Daily_Timesheet__c
	INNER JOIN salesforce.currencytype cur ON cur.IsoCode = eli.CurrencyIsoCode  
	INNER JOIN salesforce.resource__c r ON r.Name = eli.Resource_Name__c  
	INNER JOIN salesforce.work_item__c wi ON eli.Work_Item__c = wi.Id
	INNER join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id   
    inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
    inner join salesforce.account site on sc.Primary_client__c = site.Id
    left join salesforce.country_code_setup__c sccs on site.Business_Country2__c = sccs.Id
	left join salesforce.state_code_setup__c sscs on site.Business_State__c = sscs.Id
	left join salesforce.saig_geocode_cache sgeo on concat(
													 ifnull(concat(site.Business_Address_1__c ,' '),''),
													 ifnull(concat(site.Business_Address_2__c,' '),''),
													 ifnull(concat(site.Business_Address_3__c,' '),''),
													 ifnull(concat(site.Business_City__c ,' '),''),
													 ifnull(concat(sscs.Name,' '),''),
													 ifnull(concat(sccs.Name,' '),''),
													 ifnull(concat(site.Business_Zip_Postal_Code__c ,' '),'')) = sgeo.Address
	inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id   
	inner join salesforce.standard__c s on sp.Standard__c = s.Id   
	inner join salesforce.standard__c ps on s.Parent_Standard__c = ps.Id   
	inner join salesforce.program__c p on s.Program__c = p.Id   
	INNER JOIN salesforce.account a ON a.Id = eli.Client__c  
    left join salesforce.country_code_setup__c accs on r.Home_Country1__c = accs.Id
	left join salesforce.state_code_setup__c ascs on r.Home_State_Province__c = ascs.Id
	left join salesforce.saig_geocode_cache geo on concat(
													 ifnull(concat(r.Home_Address_1__c,' '),''),
													 ifnull(concat(r.Home_Address_2__c,' '),''),
													 ifnull(concat(r.Home_Address_3__c,' '),''),
													 ifnull(concat(r.Home_City__c,' '),''),
													 ifnull(concat(ascs.Name,' '),''),
													 ifnull(concat(accs.Name,' '),''),
													 ifnull(concat(r.Home_Postcode__c,' '),'')) = geo.Address
WHERE eli.IsDeleted = 0   
      AND dts.IsDeleted = 0   
      and wi.Work_Item_Stage__c not in ('Follow Up')
      and wi.Status__c not in ('Draft', 'Open', 'Scheduled', 'Scheduled - Offered', 'Cancelled', 'Budget', 'Initiate Service', 'Confirmed', 'In Progress', 'Service Change')
      and date_format(wi.Work_Item_Date__c, '%Y-%m') >= @start_period
      and date_format(wi.Work_Item_Date__c, '%Y-%m') <= @end_period
      and analytics.getRegionFromCountry(analytics.getCountryFromRevenueOwnership(wi.Revenue_Ownership__c)) = @region
      and analytics.getCountryFromRevenueOwnership(wi.Revenue_Ownership__c) = 'Australia'
      and sgeo.Latitude is not null
GROUP BY wi.Id, eli.Category__c );