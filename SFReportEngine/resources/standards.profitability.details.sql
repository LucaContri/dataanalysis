set @back_office_admin_rate = 30;
set @back_office_prc_rate = 80;
set @employee_rate = 100;
set @contractor_rate = 110;
set @start_period = '2016-07';
set @end_period = '2016-12';
set @region = 'EMEA';

DROP FUNCTION getSimpleStandardFromStandard;
DELIMITER $$
CREATE FUNCTION `getSimpleStandardFromStandard`(s VARCHAR(256), p VARCHAR(256)) RETURNS varchar(256) CHARSET utf8
BEGIN
	DECLARE ss VARCHAR(256) DEFAULT null;
    SET ss = (SELECT 
		replace(replace(replace(
			if (p = 'Health and Disability Services',
				'Health and Disability',
				if(s like 'BRC%', 
					'BRC', 
					if(s like 'McDonalds%', 
						'McDonalds', 
						if (s like 'Woolworths%' or s like 'WQA%' or s like 'WW %',
							'Woolworths',
							if (s like '%Tesco%' or s like 'TFMS%' or s like 'TPPS%', 
								'Tesco',
                                s
							)
						)
					)
				)
			)
        , ' | Certification', ''), ' | Verification' ,''), ' | Evaluation', '')
	);
		
    RETURN ss;
END$$
DELIMITER ;

(select s.NAme, getSimpleStandardFromStandard(s.Name, p.Name), p.Name 
from salesforce.standard__c s 
inner join salesforce.Program__c p on s.Program__C = p.Id );

SELECT    
    if(month(ifnull(wi.Work_Item_Date__c,i.createdDate))<7, Year(ifnull(wi.Work_Item_Date__c,i.createdDate)),Year(ifnull(wi.Work_Item_Date__c,i.createdDate))+1) as 'F.Y.',
    date_format(ifnull(wi.Work_Item_Date__c,i.createdDate), '%Y-%m') as 'WI Period',
    a.Name as 'Billing Client',
	a.Client_Ownership__c as 'ClientOwnership',
    ifnull(wi.Revenue_Ownership__c, ili.Revenue_Ownership__c) as 'RevenueOwnership',
    analytics.getCountryFromRevenueOwnership(ifnull(wi.Revenue_Ownership__c, ili.Revenue_Ownership__c)) as 'Rev Owner Country',
    analytics.getRegionFromCountry(analytics.getCountryFromRevenueOwnership(ifnull(wi.Revenue_Ownership__c, ili.Revenue_Ownership__c))) as 'Rev Owner Region',
    pr.Business_Line__c AS 'BusinessLine',   
    pr.Pathway__c AS 'Pathway',   
    p.Name as 'Program',   
    p.Program_Code__c as 'Program Code',
    s.Name as 'Standard (Compass)',
    analytics.getSimpleStandardFromStandard(s.Name, p.Name) as 'Standard',
    'Revenues' as 'Type',   
    pr.Category__c as 'SubType',
    'n/a' as 'SubType 2', 
    'n/a' as 'SubType 3',
    'Billable' as 'Billable',
    sum(ili.Total_Line_Amount__c) as 'Value',
    group_concat(distinct ili.CurrencyIsoCode) as 'Units',
    SUM(ili.Total_Line_Amount__c/cur.ConversionRate) AS 'Amount',   
    'AUD' as 'Currency',
    SUM(ili.Total_Line_Amount__c/cur.ConversionRate)*0.592000 as 'Amount (GBP)',
    group_concat(distinct wi.Name) as 'Work Items',
    count(distinct wi.Id) as '# Work Items',
    '' as 'Auditor',
    '' as 'Rate Type'
FROM salesforce.invoice__c i   
INNER JOIN salesforce.invoice_line_item__c ili ON ili.invoice__c = i.Id
left join salesforce.work_item__c wi on ili.Work_Item__c = wi.Id and wi.IsDeleted = 0 and wi.Status__c not in ('Draft', 'Open', 'Scheduled', 'Scheduled - Offered', 'Cancelled', 'Budget', 'Initiate Service', 'Confirmed', 'In Progress', 'Service Change')
INNER JOIN salesforce.currencytype cur ON cur.IsoCode = ili.CurrencyIsoCode   
INNER JOIN salesforce.product2 pr ON pr.Id = ili.Product__c  
INNER JOIN salesforce.standard__c s ON pr.Standard__c = s.Id  
INNER JOIN salesforce.Program__c p on s.Program__c = p.Id   
INNER JOIN salesforce.account a ON a.Id = i.Billing_Client__c  
WHERE i.IsDeleted = 0
	and ili.IsDeleted =0 
    AND i.Status__c NOT IN ('Cancelled')
    and date_format(ifnull(wi.Work_Item_Date__c,i.createdDate), '%Y-%m') >= @start_period
    and date_format(ifnull(wi.Work_Item_Date__c,i.createdDate), '%Y-%m') <= @end_period
    #and analytics.getCountryFromRevenueOwnership(ifnull(wi.Revenue_Ownership__c, ili.Revenue_Ownership__c)) in ('Australia', 'UK')
    and analytics.getRegionFromCountry(analytics.getCountryFromRevenueOwnership(ifnull(wi.Revenue_Ownership__c, ili.Revenue_Ownership__c))) = @region
GROUP BY ili.Id,`F.Y.`, `WI Period`, `ClientOwnership`, `BusinessLine` , `Pathway` , `Standard`, `Type`, `SubType`, `SubType 2`,`SubType 3`, `Billable`
union all
# Expenses   
SELECT    
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
    'Expenses' as 'Type',   
    eli.Category__c as 'SubType', 
    'n/a' as 'SubType 2', 
    r.Resource_Type__c as 'SubType 3',
    eli.Billable__c as 'Billable',
    sum(eli.FTotal_Amount_Ex_Tax__c) as 'Value',
    group_concat(distinct eli.CurrencyIsoCode) as 'Units',
    sum(eli.FTotal_Amount_Ex_Tax__c / cur.ConversionRate) as 'Amount',
    'AUD' as 'Currency',
    sum(eli.FTotal_Amount_Ex_Tax__c / cur.ConversionRate)*0.592000 as 'Amount (GBP)',
    group_concat(distinct wi.Name) as 'Work Items',
    count(distinct wi.Id) as '# Work Items',
    r.NAme as 'Auditor',
    '' as 'Rate Type'
FROM   
    salesforce.expense_line_item__c eli   
	INNER JOIN salesforce.daily_timesheet__c dts ON dts.Id = eli.Daily_Timesheet__c
	INNER JOIN salesforce.currencytype cur ON cur.IsoCode = eli.CurrencyIsoCode  
	INNER JOIN salesforce.resource__c r ON r.Name = eli.Resource_Name__c  
	INNER JOIN salesforce.work_item__c wi ON eli.Work_Item__c = wi.Id
    INNER join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id   
    inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id   
    inner join salesforce.standard__c s on sp.Standard__c = s.Id   
    inner join salesforce.standard__c ps on s.Parent_Standard__c = ps.Id   
    inner join salesforce.program__c p on s.Program__c = p.Id   
	INNER JOIN salesforce.account a ON a.Id = eli.Client__c  
WHERE eli.IsDeleted = 0   
      AND dts.IsDeleted = 0   
      and wi.Status__c not in ('Draft', 'Open', 'Scheduled', 'Scheduled - Offered', 'Cancelled', 'Budget', 'Initiate Service', 'Confirmed', 'In Progress', 'Service Change')
      and date_format(wi.Work_Item_Date__c, '%Y-%m') >= @start_period
      and date_format(wi.Work_Item_Date__c, '%Y-%m') <= @end_period
      #and analytics.getCountryFromRevenueOwnership(wi.Revenue_Ownership__c) in ('Australia', 'UK')
      and analytics.getRegionFromCountry(analytics.getCountryFromRevenueOwnership(wi.Revenue_Ownership__c)) = @region
GROUP BY wi.Id,`F.Y.`, `WI Period`, `ClientOwnership`, `BusinessLine` , `Pathway` , `Standard`, `Type`, `SubType`, `SubType 2`,`SubType 3`, `Billable` 
union all
select    
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
    'Resource Cost' as 'Type',   
    tsli.Category__c as 'SubType',
	if(wi.Work_Item_Stage__c='Follow Up', 'Follow Up','Other') as 'SubType 2', 
    r.Resource_Type__c as 'SubType 3',
    tsli.Billable__c as 'Billable',
    sum(tsli.Actual_Hours__c) as 'Value',
    'Hours' as 'Unit',
    sum(tsli.Actual_Hours__c*ifnull(if(r.Reporting_Business_Units__c like '%UK' and r.Resource_Type__c='Contractor' and wi.Work_Item_Stage__c='Follow Up',0, ar.`Avg Hourly Rate (AUD)`),if(r.Resource_Type__c='Employee',@employee_rate, @contractor_rate))) as 'Amount',   
    'AUD' as 'Currency',
    sum(tsli.Actual_Hours__c*ifnull(if(r.Reporting_Business_Units__c like '%UK' and r.Resource_Type__c='Contractor' and wi.Work_Item_Stage__c='Follow Up',0, ar.`Avg Hourly Rate (AUD)`),if(r.Resource_Type__c='Employee',@employee_rate, @contractor_rate)))*0.592000 as 'Amount (GBP)',   
    group_concat(distinct wi.Name) as 'Work Items',
    count(distinct wi.Id) as '# Work Items',
    r.Name as 'Auditor',
    ar.`type` as 'Rate Type'
from salesforce.timesheet_line_item__c tsli    
	inner join salesforce.resource__c r on r.Name = tsli.Resource_Name__c    
	inner join salesforce.work_item__c wi on tsli.Work_Item__c = wi.Id    
	#inner join (select ili.Work_Item__c, ili.Invoice__c, min(i.CreatedDate) as 'Invoice Created Date' from salesforce.invoice_line_item__c ili inner join salesforce.invoice__c i on ili.Invoice__c = i.Id group by ili.Work_Item__c) iid on iid.Work_Item__c = wi.Id
	inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id   
	inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id   
	inner join salesforce.standard__c s on sp.Standard__c = s.Id   
	inner join salesforce.standard__c ps on s.Parent_Standard__c = ps.Id   
	inner join salesforce.program__c p on s.Program__c = p.Id   
	inner join salesforce.account a on a.Id = tsli.Client__c    
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
    #and analytics.getCountryFromRevenueOwnership(wi.Revenue_Ownership__c) in ('Australia', 'UK')
    and analytics.getRegionFromCountry(analytics.getCountryFromRevenueOwnership(wi.Revenue_Ownership__c)) = @region
group by wi.Id,`F.Y.`, `WI Period`, `ClientOwnership`, `BusinessLine` , `Pathway` , `Standard`, `Type`, `SubType`, `SubType 2`,`SubType 3`, `Billable`  
union all
select    
    if(month(wi.Work_Item_Date__c)<7, Year(wi.Work_Item_Date__c),Year(wi.Work_Item_Date__c)+1) as 'F.Y.',
	date_format(wi.Work_Item_Date__c, '%Y-%m') as 'WI Period',  
    wi.Client_Name_No_Hyperlink__c as 'Billing Client',
	wi.Client_Ownership__c as 'ClientOwnership',  
    wi.Revenue_Ownership__c as 'RevenueOwnership',
    analytics.getCountryFromRevenueOwnership(wi.Revenue_Ownership__c) as 'Rev Owner Country',
    analytics.getRegionFromCountry(analytics.getCountryFromRevenueOwnership(wi.Revenue_Ownership__c)) as 'Rev Owner Region',
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
    'n/a' as 'Billable',
    count(distinct wi.Id) as 'Value',   
    '#' as 'Unit',
    count(distinct wi.Id) as 'Amount',   
    '#' as 'Currency',
    count(distinct wi.Id),
    group_concat(distinct wi.Name) as 'Work Items',
    count(distinct wi.Id) as '# Work Items',
    r.NAme as 'Auditor',
    '' as 'Rate Type'
from salesforce.work_item__c wi  
	inner join salesforce.resource__c r on r.Id = wi.Work_Item_Owner__c
	inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id   
	inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id   
	inner join salesforce.standard__c s on sp.Standard__c = s.Id   
	inner join salesforce.standard__c ps on s.Parent_Standard__c = ps.Id   
	inner join salesforce.program__c p on s.Program__c = p.Id   
where wi.IsDeleted = 0   
	and wi.Status__c not in ('Draft', 'Open', 'Scheduled', 'Scheduled - Offered', 'Cancelled', 'Budget', 'Initiate Service', 'Confirmed', 'In Progress', 'Service Change')   
    and date_format(wi.Work_Item_Date__c, '%Y-%m') >= @start_period
    and date_format(wi.Work_Item_Date__c, '%Y-%m') <= @end_period
    #and analytics.getCountryFromRevenueOwnership(wi.Revenue_Ownership__c) in ('Australia', 'UK')
    and analytics.getRegionFromCountry(analytics.getCountryFromRevenueOwnership(wi.Revenue_Ownership__c)) = @region
group by wi.ID,`F.Y.`, `WI Period`, `ClientOwnership`, `BusinessLine` , `Pathway` , `Standard`, `Type`, `SubType`, `SubType 2`,`SubType 3`, `Billable`
union all
select    
    if(month(wi.Work_Item_Date__c)<7, Year(wi.Work_Item_Date__c),Year(wi.Work_Item_Date__c)+1) as 'F.Y.',
	date_format(wi.Work_Item_Date__c, '%Y-%m') as 'WI Period',
    wi.Client_Name_No_Hyperlink__c as 'Billing Client',
	wi.Client_Ownership__c as 'ClientOwnership',  
    wi.Revenue_Ownership__c as 'RevenueOwnership',
    analytics.getCountryFromRevenueOwnership(wi.Revenue_Ownership__c) as 'Rev Owner Country',
    analytics.getRegionFromCountry(analytics.getCountryFromRevenueOwnership(wi.Revenue_Ownership__c)) as 'Rev Owner Region',
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
    '#' as 'Unit',
    sum(wi.Required_Duration__c/8) as 'Amount',   
    '#' as 'Currency',
    sum(wi.Required_Duration__c/8),
    group_concat(distinct wi.Name) as 'Work Items',
    count(distinct wi.Id) as '# Work Items',
    r.NAme as 'Auditor',
    '' as 'Rate Type'
from salesforce.work_item__c wi
	inner join salesforce.resource__c r on r.Id = wi.Work_Item_Owner__c
	inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id   
	inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id   
	inner join salesforce.standard__c s on sp.Standard__c = s.Id   
	inner join salesforce.standard__c ps on s.Parent_Standard__c = ps.Id   
	inner join salesforce.program__c p on s.Program__c = p.Id   
where wi.IsDeleted = 0
	and wi.Status__c not in ('Draft', 'Open', 'Scheduled', 'Scheduled - Offered', 'Cancelled', 'Budget', 'Initiate Service', 'Confirmed', 'In Progress', 'Service Change')   
    and date_format(wi.Work_Item_Date__c, '%Y-%m') >= @start_period
    and date_format(wi.Work_Item_Date__c, '%Y-%m') <= @end_period
    #and analytics.getCountryFromRevenueOwnership(wi.Revenue_Ownership__c) in ('Australia', 'UK')
    and analytics.getRegionFromCountry(analytics.getCountryFromRevenueOwnership(wi.Revenue_Ownership__c)) = @region
group by wi.Id, `F.Y.`, `WI Period`, `ClientOwnership`, `BusinessLine` , `Pathway` , `Standard`, `Type`, `SubType`, `SubType 2`,`SubType 3`, `Billable`; 

# Back Office Cost Allocation
select    
    if(month(wi.Work_Item_Date__c)<7, Year(wi.Work_Item_Date__c),Year(wi.Work_Item_Date__c)+1) as 'F.Y.',
	date_format(wi.Work_Item_Date__c, '%Y-%m') as 'Invoice Created Period',  
    wi.Client_Name_No_Hyperlink__c as 'Billing Client',
	wi.Client_Ownership__c as 'ClientOwnership',  
    wi.Revenue_Ownership__c as 'RevenueOwnership',
    analytics.getCountryFromRevenueOwnership(wi.Revenue_Ownership__c) as 'Rev Owner Country',
    analytics.getRegionFromCountry(analytics.getCountryFromRevenueOwnership(wi.Revenue_Ownership__c)) as 'Rev Owner Region',
    p.Business_Line__c AS 'BusinessLine',   
    p.Pathway__c as 'Pathway',   
    p.Name as 'Program',
    p.Program_Code__c as 'Program Code',   
    ps.Name as 'Standard',
    'Schedule' as 'Type',
    'Count' as 'SubType',
    '' as 'SubType 2',
    '' as 'SubType 3',
    'n/a' as 'Billable',
	sum(if (wih.NewValue = 'Scheduled', 15,
		if (wih.NewValue = 'Scheduled - Offered', 2,
		2 #Confirmed
	)))/0.72 as 'Value',
    'min' as 'Unit',
    if (wih.NewValue = 'Scheduled', 15,
		if (wih.NewValue = 'Scheduled - Offered', 2,
		2 #Confirmed
	))/60/0.72*@back_office_admin_rate as 'Amount',   
    'AUD' as 'Currency',
    if (wih.NewValue = 'Scheduled', 15,
		if (wih.NewValue = 'Scheduled - Offered', 2,
		2 #Confirmed
	))/60/0.72*@back_office_admin_rate*0.592 as 'Amount (GBP)',
    group_concat(distinct wi.Name) as 'Work Items',
    count(distinct wi.Id) as '# Work Items',
    '' as 'Auditor',
    '' as 'Rate Type'
from salesforce.work_item__c wi
	inner join salesforce.work_item__history wih on wih.ParentId = wi.Id and wih.Field = 'Status__c' and wih.NewValue in ('Scheduled', 'Scheduled - Offered', 'Confirmed')
	inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id   
	inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id   
	inner join salesforce.standard__c s on sp.Standard__c = s.Id   
	inner join salesforce.standard__c ps on s.Parent_Standard__c = ps.Id   
	inner join salesforce.program__c p on s.Program__c = p.Id   
where wi.IsDeleted = 0   
	and wi.Status__c not in ('Draft', 'Open', 'Scheduled', 'Scheduled - Offered', 'Cancelled', 'Budget', 'Initiate Service', 'Confirmed', 'In Progress', 'Service Change')   
    and wi.Work_Item_Stage__c not in ('Follow Up')
    and date_format(wi.Work_Item_Date__c, '%Y-%m') >= '2015-07'
group by wi.ID,`F.Y.`, `Invoice Created Period`, `ClientOwnership`, `BusinessLine` , `Pathway` , `Standard`, `Type`, `SubType`, `SubType 2`,`SubType 3`, `Billable`;

# EMEA-UK Revenue Ownership - Expenses Sanity check - Period Jan 16 to Mar 16
# Test 1 - Distance >= 160 Km, Duration >= 16 hours No accomodation expenses
# Test 2 - Intercountry travel, no airfare expenses
# Test 3 - Only Airfare expenses.  Nothing else
# Test 4 - More than 25% discrepancy between straight line distance and distance claimed in auditors expenses

(select 
	site.name as 'Client Site',
	site.Id as 'ClientSiteId',
	site_geo.Latitude as 'Client Site Lat',
	site_geo.Longitude as 'Client Site Lon',
	concat(
		 ifnull(concat(site.Business_Address_1__c,' '),''),
		 ifnull(concat(site.Business_Address_2__c,' '),''),
		 ifnull(concat(site.Business_Address_3__c,' '),''),
		 ifnull(concat(site.Business_City__c,' '),''),
		 ifnull(concat(site_scs.Name,' '),''),
		 ifnull(concat(site_ccs.Name,' '),''),
		 ifnull(concat(site.Business_Zip_Postal_Code__c,' '),'')) as 'Client Site Address',
	site_ccs.name as 'Client Site Country',
	site_scs.Name as 'Client Site State',
	site.Business_City__c as 'Client Site City',
	site.Business_Zip_Postal_Code__c as 'Client Site Postcode',
	wi.Id as 'Work Item Id', 
    wi.Name as 'Work Item',
    wi.Work_Item_Stage__c as 'Work Item Type',
    wi.Primary_Standard__c as 'Primary Standard',
    wi.Required_Duration__c as 'Work Item Duration',
    r_geo.Latitude as 'Latitude__c',
	r_geo.Longitude as 'Longitude__c',
	concat(
		 ifnull(concat(r.Home_Address_1__c,' '),''),
		 ifnull(concat(r.Home_Address_2__c,' '),''),
		 ifnull(concat(r.Home_Address_3__c,' '),''),
		 ifnull(concat(r.Home_City__c,' '),''),
		 ifnull(concat(r_scs.Name,' '),''),
		 ifnull(concat(r_ccs.Name,' '),''),
		 ifnull(concat(r.Home_Postcode__c,' '),'')) as 'Resource Address',
	r_ccs.Name as 'Resource Country',
	r_scs.Name as 'Resource State',
	r.Home_City__c as 'Resource City',
	r.Home_Postcode__c as 'Resource Postcode',
	r.Name,
	r.Reporting_Business_Units__c,
	r.Resource_Type__c,
	r.Resource_Capacitiy__c,
    
    analytics.distance(r_geo.latitude, r_geo.longitude, site_geo.latitude, site_geo.longitude) as 'Line Distance (km)',
    sum(if(eli.Category__c = 'Travel Cost - Distance',eli.Quantity__c,0)) as 'Travel Cost - Distance - Qty', 
    sum(if(eli.Category__c = 'Travel Cost - Distance',eli.Amount_Ex_VAT__c/cur.ConversionRate,0)) as 'Travel Cost - Distance - Amt (AUD)',
    max(if(eli.Category__c = 'Travel Cost - Per Diem',1,0)) as 'Has Travel Cost - Per Diem',
    max(if(eli.Category__c = 'Technical Advisor Hours',1,0)) as 'Has Technical Advisor Hours',
    max(if(eli.Category__c = 'Travel Cost - Metro',1,0)) as 'Has Travel Cost - Metro',
    max(if(eli.Category__c = 'Travel Costs - Accommodation',1,0)) as 'Has Travel Costs - Accommodation',
    max(if(eli.Category__c = 'Travel Costs - Airfares',1,0)) as 'Has Travel Cost - Airfares',
    max(if(eli.Category__c like '%Car%' or eli.Category__c like '%Taxi%',1,0)) as 'Has Travel Cost - Car/Taxi',
    max(if(eli.Category__c like '%Meals%',1,0)) as 'Has Travel Cost - Meals',
    max(if(eli.Category__c = 'Travel Costs - Other',1,0)) as 'Has Travel Cost - Other',
    sum(if(eli.Category__c = 'Technical Advisor Hours',eli.Amount_Ex_VAT__c/cur.ConversionRate,0)) as 'Technical Advisor Hours (AUD)',
    sum(if(eli.Category__c = 'Travel Cost - Per Diem',eli.Amount_Ex_VAT__c/cur.ConversionRate,0)) as 'Travel Cost - Per Diem (AUD)',
    sum(if(eli.Category__c = 'Travel Cost - Metro',eli.Amount_Ex_VAT__c/cur.ConversionRate,0)) as 'Travel Cost - Metro (AUD)',
    sum(if(eli.Category__c = 'Travel Costs - Accommodation',eli.Amount_Ex_VAT__c/cur.ConversionRate,0)) as 'Travel Costs - Accommodation (AUD)',
    sum(if(eli.Category__c = 'Travel Costs - Airfares',eli.Amount_Ex_VAT__c/cur.ConversionRate,0)) as 'Travel Cost - Airfares (AUD)',
    sum(if(eli.Category__c like '%Car%' or eli.Category__c like '%Taxi%',eli.Amount_Ex_VAT__c/cur.ConversionRate,0)) as 'Travel Cost - Car/Taxi (AUD)',
    sum(if(eli.Category__c like '%Meals%',eli.Amount_Ex_VAT__c/cur.ConversionRate,0)) as 'Travel Cost - Meals (AUD)',
    sum(if(eli.Category__c = 'Travel Costs - Other',eli.Amount_Ex_VAT__c/cur.ConversionRate,0)) as 'Travel Cost - Other (AUD)',
    if(analytics.distance(r_geo.latitude, r_geo.longitude, site_geo.latitude, site_geo.longitude) > 160,1,0) as 'More than 160 km',
    if(r_ccs.Name = site_ccs.Name,0,1) as 'Intercountry travel'
from salesforce.work_item__c wi
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
inner join salesforce.account site on sc.Primary_client__c = site.Id
left join salesforce.country_code_setup__c site_ccs on site.Business_Country2__c = site_ccs.Id
left join salesforce.state_code_setup__c site_scs on site.Business_State__c = site_scs.Id
inner join salesforce.resource__c r on r.Id = wi.Work_Item_Owner__c
left join salesforce.country_code_setup__c r_ccs on r.Home_Country1__c = r_ccs.Id
left join salesforce.state_code_setup__c r_scs on r.Home_State_Province__c = r_scs.Id
left join salesforce.saig_geocode_cache r_geo on r_geo.Address = concat(
						 ifnull(concat(r.Home_Address_1__c,' '),''),
						 ifnull(concat(r.Home_Address_2__c,' '),''),
						 ifnull(concat(r.Home_Address_3__c,' '),''),
						 ifnull(concat(r.Home_City__c,' '),''),
						 ifnull(concat(r_scs.Name,' '),''),
						 ifnull(concat(r_ccs.Name,' '),''),
						 ifnull(concat(r.Home_Postcode__c,' '),'')) 
left join salesforce.saig_geocode_cache site_geo on site_geo.Address = concat(
						 ifnull(concat(site.Business_Address_1__c,' '),''),
						 ifnull(concat(site.Business_Address_2__c,' '),''),
						 ifnull(concat(site.Business_Address_3__c,' '),''),
						 ifnull(concat(site.Business_City__c,' '),''),
						 ifnull(concat(site_scs.Name,' '),''),
						 ifnull(concat(site_ccs.Name,' '),''),
						 ifnull(concat(site.Business_Zip_Postal_Code__c,' '),'')) 
left join salesforce.expense_line_item__c eli on eli.Work_Item__c = wi.Id and eli.IsDeleted = 0
left join salesforce.currencytype cur on eli.CurrencyIsoCode = cur.IsoCode
where 
	wi.isDeleted = 0
	and wi.Status__c not in ('Draft', 'Open', 'Scheduled', 'Scheduled - Offered', 'Cancelled', 'Budget', 'Initiate Service', 'Confirmed', 'In Progress', 'Service Change')  
    and wi.Revenue_Ownership__c = 'EMEA-UK'
    and wi.Work_Item_Date__c between '2016-01-01' and '2016-03-31'
group by wi.Id
);

