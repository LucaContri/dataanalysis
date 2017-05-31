set @employee_rate = 100;
set @contractor_rate = 110;
set @start_period = '2015-07';
set @end_period = '2017-02';
set @region = 'EMEA';


SELECT    		
	if(month(ifnull(wi.Work_Item_Date__c,i.createdDate))<7, Year(ifnull(wi.Work_Item_Date__c,i.createdDate)),Year(ifnull(wi.Work_Item_Date__c,i.createdDate))+1) as 'F.Y.',		
	date_format(ifnull(wi.Work_Item_Date__c,i.createdDate), '%Y-%m') as 'WI Period',		
	a.Name as 'Billing Client', ifnull(pa.Name, a.Name) as 'Parent Client',
	a.Client_Ownership__c as 'ClientOwnership',	
	ifnull(wi.Revenue_Ownership__c, ili.Revenue_Ownership__c) as 'RevenueOwnership',		
	analytics.getCountryFromRevenueOwnership(ifnull(wi.Revenue_Ownership__c, ili.Revenue_Ownership__c)) as 'Rev Owner Country',		
	analytics.getRegionFromCountry(analytics.getCountryFromRevenueOwnership(ifnull(wi.Revenue_Ownership__c, ili.Revenue_Ownership__c))) as 'Rev Owner Region',    		
	site.Name as 'Site Name',		
	analytics.getRegionFromCountry(ccs.Name) as 'Site Region',		
	ccs.Name as 'Site Country',		
	r.Name as 'WI Owner',		
	analytics.getRegionFromCountry(rccs.Name) as 'WI Owner Region',		
	rccs.Name as 'WI Owner Country',		
	pr.Business_Line__c AS 'BusinessLine',   		
	pr.Pathway__c AS 'Pathway',   		
	p.Name as 'Program',   		
	p.Program_Code__c as 'Program Code',		
	s.Name as 'Standard (Compass)',		
	analytics.getSimpleStandardFromStandard(s.Name, p.Name) as 'Standard',		
	'Revenues' as 'Type',   		
	pr.Category__c as 'SubType',		
	'n/a' as 'SubType 2', 		
	'n/a' as 'SubType 3', 'Billable' as 'Billable', sum(ili.Total_Line_Amount__c) as 'Value',		
	group_concat(distinct ili.CurrencyIsoCode) as 'Units',		
	SUM(ili.Total_Line_Amount__c/cur.ConversionRate) AS 'Amount', 'AUD' as 'Currency', group_concat(distinct wi.Name) as 'Work Items', count(distinct wi.Id) as '# Work Items', '' as 'Auditor', '' as 'Rate Type'
FROM salesforce.invoice__c i   		
	INNER JOIN salesforce.invoice_line_item__c ili ON ili.invoice__c = i.Id		
	left join salesforce.work_item__c wi on ili.Work_Item__c = wi.Id and wi.IsDeleted = 0 and wi.Status__c not in ('Draft', 'Open', 'Scheduled', 'Scheduled - Offered', 'Cancelled', 'Budget', 'Initiate Service', 'Confirmed', 'In Progress', 'Service Change')				
	left join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id		
	left join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id		
	left join salesforce.account site on sc.Primary_client__c = site.Id		
	left join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id		
	left join salesforce.resource__c r on wi.Work_Item_Owner__c = r.Id		
	left join salesforce.country_code_setup__c rccs on r.Home_Country1__c = rccs.Id		
	INNER JOIN salesforce.currencytype cur ON cur.IsoCode = ili.CurrencyIsoCode   		
	INNER JOIN salesforce.product2 pr ON pr.Id = ili.Product__c  		
	INNER JOIN salesforce.standard__c s ON pr.Standard__c = s.Id  		
	INNER JOIN salesforce.Program__c p on s.Program__c = p.Id   		
	INNER JOIN salesforce.account a ON a.Id = i.Billing_Client__c  		
    left join salesforce.account pa on a.ParentId = pa.Id
WHERE i.IsDeleted = 0		
	and ili.IsDeleted =0 		
	AND i.Status__c NOT IN ('Cancelled')		
	and date_format(ifnull(wi.Work_Item_Date__c,i.createdDate), '%Y-%m') >= @start_period
	and date_format(ifnull(wi.Work_Item_Date__c,i.createdDate), '%Y-%m') <= @end_period		
	and analytics.getRegionFromCountry(analytics.getCountryFromRevenueOwnership(ifnull(wi.Revenue_Ownership__c, ili.Revenue_Ownership__c))) = @region
GROUP BY ili.Id,`F.Y.`, `WI Period`, `ClientOwnership`, `BusinessLine` , `Pathway` , `Standard`, `Type`, `SubType`, `SubType 2`,`SubType 3`, `Billable`		
union all		
# Expenses   		
SELECT    		
	if(month(wi.Work_Item_Date__c)<7, Year(wi.Work_Item_Date__c),Year(wi.Work_Item_Date__c)+1) as 'F.Y.',		
	date_format(wi.Work_Item_Date__c, '%Y-%m') as 'WI Period',		
	a.Name as 'Billing Client', ifnull(pa.Name, a.Name) as 'Parent Client',
	a.Client_Ownership__c as 'ClientOwnership',  		
	wi.Revenue_Ownership__c as 'RevenueOwnership',		
	analytics.getCountryFromRevenueOwnership(wi.Revenue_Ownership__c) as 'Rev Owner Country',		
	analytics.getRegionFromCountry(analytics.getCountryFromRevenueOwnership(wi.Revenue_Ownership__c)) as 'Rev Owner Region',		
	site.Name as 'Site Name',		
	analytics.getRegionFromCountry(ccs.Name) as 'Site Region',		
	ccs.Name as 'Site Country',		
	r.Name as 'WI Owner',		
	analytics.getRegionFromCountry(rccs.Name) as 'WI Owner Region',		
	rccs.Name as 'WI Owner Country',		
	p.Business_Line__c AS 'BusinessLine',  	
	p.Pathway__c as 'Pathway',   		
	p.Name as 'Program',   		
	p.Program_Code__c as 'Program Code',   		
	ps.Name as 'Standard (Compass)',		
	analytics.getSimpleStandardFromStandard(ps.Name, p.Name) as 'Standard',   		
	'Expenses' as 'Type',   		
	eli.Category__c as 'SubType', 		
	'n/a' as 'SubType 2', 		
	r.Resource_Type__c as 'SubType 3', eli.Billable__c as 'Billable', sum(eli.FTotal_Amount_Ex_Tax__c) as 'Value',		
	group_concat(distinct eli.CurrencyIsoCode) as 'Units',		
	sum(eli.FTotal_Amount_Ex_Tax__c / cur.ConversionRate) as 'Amount', 'AUD' as 'Currency', group_concat(distinct wi.Name) as 'Work Items', count(distinct wi.Id) as '# Work Items', r.Name as 'Auditor', '' as 'Rate Type'
FROM salesforce.expense_line_item__c eli   		
	INNER JOIN salesforce.daily_timesheet__c dts ON dts.Id = eli.Daily_Timesheet__c		
	INNER JOIN salesforce.currencytype cur ON cur.IsoCode = eli.CurrencyIsoCode  		
	INNER JOIN salesforce.resource__c r ON r.Name = eli.Resource_Name__c  		
	INNER JOIN salesforce.work_item__c wi ON eli.Work_Item__c = wi.Id		
	inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id   		
	inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id		
	inner join salesforce.account site on sc.Primary_client__c = site.Id		
	inner join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id		
	inner join salesforce.country_code_setup__c rccs on r.Home_Country1__c = rccs.Id		
	inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id   		
	inner join salesforce.standard__c s on sp.Standard__c = s.Id   		
	inner join salesforce.standard__c ps on s.Parent_Standard__c = ps.Id   		
	inner join salesforce.program__c p on s.Program__c = p.Id   		
	INNER JOIN salesforce.account a ON a.Id = eli.Client__c
    left join salesforce.account pa on a.ParentId = pa.Id
WHERE eli.IsDeleted = 0   		
	AND dts.IsDeleted = 0   		
	and wi.Status__c not in ('Draft', 'Open', 'Scheduled', 'Scheduled - Offered', 'Cancelled', 'Budget', 'Initiate Service', 'Confirmed', 'In Progress', 'Service Change')		
	and date_format(wi.Work_Item_Date__c, '%Y-%m') >= @start_period
	and date_format(wi.Work_Item_Date__c, '%Y-%m') <= @end_period		
	and analytics.getRegionFromCountry(analytics.getCountryFromRevenueOwnership(wi.Revenue_Ownership__c)) = @region
GROUP BY wi.Id,`F.Y.`, `WI Period`, `ClientOwnership`, `BusinessLine` , `Pathway` , `Standard`, `Type`, `SubType`, `SubType 2`,`SubType 3`, `Billable` 		
union all		
select
	if(month(wi.Work_Item_Date__c)<7, Year(wi.Work_Item_Date__c),Year(wi.Work_Item_Date__c)+1) as 'F.Y.',		
	date_format(wi.Work_Item_Date__c, '%Y-%m') as 'WI Period',		
	a.Name as 'Billing Client', ifnull(pa.Name, a.Name) as 'Parent Client',
	a.Client_Ownership__c as 'ClientOwnership',  	
	wi.Revenue_Ownership__c as 'RevenueOwnership',		
	analytics.getCountryFromRevenueOwnership(wi.Revenue_Ownership__c) as 'Rev Owner Country',		
	analytics.getRegionFromCountry(analytics.getCountryFromRevenueOwnership(wi.Revenue_Ownership__c)) as 'Rev Owner Region',		
	site.Name as 'Site Name',		
	analytics.getRegionFromCountry(ccs.Name) as 'Site Region',		
	ccs.Name as 'Site Country',		
	r.Name as 'WI Owner',		
	analytics.getRegionFromCountry(rccs.Name) as 'WI Owner Region',		
	rccs.Name as 'WI Owner Country',		
	p.Business_Line__c AS 'BusinessLine',   		
	p.Pathway__c as 'Pathway',   		
	p.Name as 'Program',   		
	p.Program_Code__c as 'Program Code',   		
	ps.Name as 'Standard (Compass)',		
	analytics.getSimpleStandardFromStandard(ps.Name, p.Name) as 'Standard',   		
	'Resource Cost' as 'Type',   		
	tsli.Category__c as 'SubType',		
	if(wi.Work_Item_Stage__c='Follow Up', 'Follow Up','Other') as 'SubType 2', 		
	r.Resource_Type__c as 'SubType 3',		
	tsli.Billable__c as 'Billable', sum(tsli.Actual_Hours__c) as 'Value', 'Hours' as 'Unit',		
	sum(tsli.Actual_Hours__c*ifnull(if(r.Reporting_Business_Units__c like '%UK' and r.Resource_Type__c='Contractor' and wi.Work_Item_Stage__c='Follow Up',0, ar.`Avg Hourly Rate (AUD)`),if(r.Resource_Type__c='Employee',@employee_rate, @contractor_rate))) as 'Amount',   		
	'AUD' as 'Currency', group_concat(distinct wi.Name) as 'Work Items', count(distinct wi.Id) as '# Work Items', r.Name as 'Auditor', ar.`type` as 'Rate Type'
from salesforce.timesheet_line_item__c tsli    		
	inner join salesforce.resource__c r on r.Name = tsli.Resource_Name__c    		
	inner join salesforce.work_item__c wi on tsli.Work_Item__c = wi.Id    		
	inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id   		
	inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id		
	inner join salesforce.account site on sc.Primary_client__c = site.Id		
	inner join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id		
	inner join salesforce.country_code_setup__c rccs on r.Home_Country1__c = rccs.Id		
	inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id   		
	inner join salesforce.standard__c s on sp.Standard__c = s.Id   		
	inner join salesforce.standard__c ps on s.Parent_Standard__c = ps.Id   		
	inner join salesforce.program__c p on s.Program__c = p.Id   		
	inner join salesforce.account a on a.Id = tsli.Client__c    		
    left join salesforce.account pa on a.ParentId = pa.Id
	left join (select * from (		
		select ar.`Resource Id`, ar.period, ar.value/ct.ConversionRate as 'Avg Hourly Rate (AUD)', ar.`type`		
		from `analytics`.`auditor_rates_2` ar  		
			left join salesforce.currencytype ct on ar.currency_iso_code = ct.IsoCode  		
		where ar.value>0 		
		order by ar.`Resource Id` desc, ar.period desc) t group by t.`Resource Id`) ar on ar.`resource id` = r.Id #and ar.period<wi.Work_Item_Date__c 		
where tsli.IsDeleted = 0    		
	and r.Resource_Type__c in ('Employee', 'Contractor')   		
	and wi.Status__c not in ('Draft', 'Open', 'Scheduled', 'Scheduled - Offered', 'Cancelled', 'Budget', 'Initiate Service', 'Confirmed', 'In Progress', 'Service Change')		
	and date_format(wi.Work_Item_Date__c, '%Y-%m') >= @start_period
	and date_format(wi.Work_Item_Date__c, '%Y-%m') <= @end_period		
	and analytics.getRegionFromCountry(analytics.getCountryFromRevenueOwnership(wi.Revenue_Ownership__c)) = @region
group by wi.Id,`F.Y.`, `WI Period`, `ClientOwnership`, `BusinessLine` , `Pathway` , `Standard`, `Type`, `SubType`, `SubType 2`,`SubType 3`, `Billable`  		
union all		
select    		
	if(month(wi.Work_Item_Date__c)<7, Year(wi.Work_Item_Date__c),Year(wi.Work_Item_Date__c)+1) as 'F.Y.',		
	date_format(wi.Work_Item_Date__c, '%Y-%m') as 'WI Period',  		
	wi.Client_Name_No_Hyperlink__c as 'Billing Client', ifnull(pa.Name, a.Name) as 'Parent Client',
	wi.Client_Ownership__c as 'ClientOwnership',  		
	wi.Revenue_Ownership__c as 'RevenueOwnership',		
	analytics.getCountryFromRevenueOwnership(wi.Revenue_Ownership__c) as 'Rev Owner Country',		
	analytics.getRegionFromCountry(analytics.getCountryFromRevenueOwnership(wi.Revenue_Ownership__c)) as 'Rev Owner Region',		
	site.Name as 'Site Name',		
	analytics.getRegionFromCountry(ccs.Name) as 'Site Region',		
	ccs.Name as 'Site Country',		
	r.Name as 'WI Owner',		
	analytics.getRegionFromCountry(rccs.Name) as 'WI Owner Region',		
	rccs.Name as 'WI Owner Country',		
	p.Business_Line__c AS 'BusinessLine',   		
	p.Pathway__c as 'Pathway',   		
	p.Name as 'Program',		
	p.Program_Code__c as 'Program Code',   		
	ps.Name as 'Standard (Compass)',		
	analytics.getSimpleStandardFromStandard(ps.Name, p.Name) as 'Standard',		
	'Audit' as 'Type',		
	'Count' as 'SubType',		
	if(wi.Work_Item_Stage__c='Follow Up', 'Follow Up','Other') as 'SubType 2',		
	r.Resource_Type__c as 'SubType 3',		
	'n/a' as 'Billable', count(distinct wi.Id) as 'Value', '#' as 'Unit',		
	count(distinct wi.Id) as 'Amount', '#' as 'Currency', group_concat(distinct wi.Name) as 'Work Items', count(distinct wi.Id) as '# Work Items', r.Name as 'Auditor', '' as 'Rate Type'		
from salesforce.work_item__c wi  		
	inner join salesforce.resource__c r on r.Id = wi.Work_Item_Owner__c		
	inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id   		
	inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id		
	inner join salesforce.account site on sc.Primary_client__c = site.Id		
	inner join salesforce.account a on site.ParentId = a.Id
    left join salesforce.account pa on a.ParentId = pa.Id
    inner join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id		
	inner join salesforce.country_code_setup__c rccs on r.Home_Country1__c = rccs.Id		
	inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id   		
	inner join salesforce.standard__c s on sp.Standard__c = s.Id   		
	inner join salesforce.standard__c ps on s.Parent_Standard__c = ps.Id   		
	inner join salesforce.program__c p on s.Program__c = p.Id   		
where wi.IsDeleted = 0   		
	and wi.Status__c not in ('Draft', 'Open', 'Scheduled', 'Scheduled - Offered', 'Cancelled', 'Budget', 'Initiate Service', 'Confirmed', 'In Progress', 'Service Change')   		
	and date_format(wi.Work_Item_Date__c, '%Y-%m') >= @start_period
	and date_format(wi.Work_Item_Date__c, '%Y-%m') <= @end_period		
	and analytics.getRegionFromCountry(analytics.getCountryFromRevenueOwnership(wi.Revenue_Ownership__c)) = @region
group by wi.Id,`F.Y.`, `WI Period`, `ClientOwnership`, `BusinessLine` , `Pathway` , `Standard`, `Type`, `SubType`, `SubType 2`,`SubType 3`, `Billable`		
union all		
select    		
	if(month(wi.Work_Item_Date__c)<7, Year(wi.Work_Item_Date__c),Year(wi.Work_Item_Date__c)+1) as 'F.Y.',		
	date_format(wi.Work_Item_Date__c, '%Y-%m') as 'WI Period',	
	wi.Client_Name_No_Hyperlink__c as 'Billing Client', ifnull(pa.Name, a.Name) as 'Parent Client', wi.Client_Ownership__c as 'ClientOwnership',  	
	wi.Revenue_Ownership__c as 'RevenueOwnership',		
	analytics.getCountryFromRevenueOwnership(wi.Revenue_Ownership__c) as 'Rev Owner Country',		
	analytics.getRegionFromCountry(analytics.getCountryFromRevenueOwnership(wi.Revenue_Ownership__c)) as 'Rev Owner Region',		
	site.Name as 'Site Name',		
	analytics.getRegionFromCountry(ccs.Name) as 'Site Region',		
	ccs.Name as 'Site Country',		
	r.Name as 'WI Owner',		
	analytics.getRegionFromCountry(rccs.Name) as 'WI Owner Region',		
	rccs.Name as 'WI Owner Country',		
	p.Business_Line__c AS 'BusinessLine',   		
	p.Pathway__c as 'Pathway',   		
	p.Name as 'Program',   		
	p.Program_Code__c as 'Program Code',   		
	ps.Name as 'Standard (Compass)',		
	analytics.getSimpleStandardFromStandard(ps.Name, p.Name) as 'Standard',   		
	'Audit' as 'Type',   		
	'Days' as 'SubType',		
	if(wi.Work_Item_Stage__c='Follow Up', 'Follow Up','Other') as 'SubType 2',		
	r.Resource_Type__c as 'SubType 3',		
	'n/a' as 'Billable',		
	sum(wi.Required_Duration__c/8) as 'Value',   		
	'#' as 'Unit', sum(wi.Required_Duration__c/8) as 'Amount', '#' as 'Currency', group_concat(distinct wi.Name) as 'Work Items', count(distinct wi.Id) as '# Work Items', r.Name as 'Auditor', '' as 'Rate Type'		
from salesforce.work_item__c wi		
	inner join salesforce.resource__c r on r.Id = wi.Work_Item_Owner__c		
	inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id   		
	inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id		
	inner join salesforce.account site on sc.Primary_client__c = site.Id		
    inner join salesforce.account a on site.ParentId = a.Id
    left join salesforce.account pa on a.ParentId = pa.Id
	inner join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id		
	inner join salesforce.country_code_setup__c rccs on r.Home_Country1__c = rccs.Id		
	inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id   		
	inner join salesforce.standard__c s on sp.Standard__c = s.Id   		
	inner join salesforce.standard__c ps on s.Parent_Standard__c = ps.Id   		
	inner join salesforce.program__c p on s.Program__c = p.Id   		
where wi.IsDeleted = 0		
	and wi.Status__c not in ('Draft', 'Open', 'Scheduled', 'Scheduled - Offered', 'Cancelled', 'Budget', 'Initiate Service', 'Confirmed', 'In Progress', 'Service Change')   		
	and date_format(wi.Work_Item_Date__c, '%Y-%m') >= @start_period
	and date_format(wi.Work_Item_Date__c, '%Y-%m') <= @end_period
	and analytics.getRegionFromCountry(analytics.getCountryFromRevenueOwnership(wi.Revenue_Ownership__c)) = @region
group by wi.Id, `F.Y.`, `WI Period`, `ClientOwnership`, `BusinessLine` , `Pathway` , `Standard`, `Type`, `SubType`, `SubType 2`,`SubType 3`, `Billable`;
