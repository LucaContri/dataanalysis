set @start_date = '2015-07-01';

(select 
	wi.Id,
    wi.Name,
    site.Name as 'Site',
    ccs.Name as 'Site Country',
    analytics.getRegionFromCountry(ccs.Name) as 'Site Region',
    wi.Primary_Standard__c,
    date_format(wi.Work_Item_Date__c, '%Y %m') as 'Period', 
    r.Id as 'Resource Id',
    r.Name as 'Resource', 
    r.Reporting_Business_Units__c as 'Reporting Business Unit', 
    analytics.getBUFromReportingBusinessUnit(r.Reporting_Business_Units__c) as 'Business Unit',
    rccs.Name as 'Resource Country',
    r.Resource_Type__c as 'Resource Type',
    'Audit Count' as 'Metric',
    count(distinct wi.Id) as 'Value',
    '#' as 'Unit'
from salesforce.work_item__c wi
inner join salesforce.timesheet_line_item__c tsli on tsli.Work_Item__c = wi.Id
inner join salesforce.resource__c r on tsli.Resource_Name__c = r.Name 
left join salesforce.country_code_setup__c rccs on r.Home_Country1__c = rccs.Id
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
inner join salesforce.account site on sc.Primary_client__c = site.Id
left join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id
where
wi.Work_Item_Date__c >= @start_date
and wi.Status__c in ('Completed')
and wi.Work_Item_Stage__c not in ('Follow Up')
and tsli.IsDeleted = 0
and tsli.Category__c = 'Audit'
group by r.Id, wi.Id, `Period`)

union all

(select 
    wi.Id,
    wi.Name,
    site.Name as 'Site',
    ccs.Name as 'Site Country',
    analytics.getRegionFromCountry(ccs.Name) as 'Site Region',
    wi.Primary_Standard__c,
    date_format(wi.Work_Item_Date__c, '%Y %m') as 'Period', 
    r.Id as 'Resource Id',
    r.Name as 'Resource', 
    r.Reporting_Business_Units__c as 'Reporting Business Unit', 
    analytics.getBUFromReportingBusinessUnit(r.Reporting_Business_Units__c) as 'Business Unit',
    rccs.Name as 'Resource Country',
    r.Resource_Type__c as 'Resource Type',
    'Audit Days' as 'Type',
    sum(tsli.Actual_Hours__c)/8 as 'Value',
    'Day' as 'Unit'
from salesforce.work_item__c wi
inner join salesforce.timesheet_line_item__c tsli on tsli.Work_Item__c = wi.Id
inner join salesforce.resource__c r on tsli.Resource_Name__c = r.Name 
left join salesforce.country_code_setup__c rccs on r.Home_Country1__c = rccs.Id
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
inner join salesforce.account site on sc.Primary_client__c = site.Id
left join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id
where
wi.Work_Item_Date__c >= @start_date
and wi.Status__c in ('Completed')
and tsli.IsDeleted = 0
and tsli.Category__c = 'Audit'
group by r.Id, wi.Id, `Period`)

union all

(select 
    wi.Id,
    wi.Name,
    site.Name as 'Site',
    ccs.Name as 'Site Country',
    analytics.getRegionFromCountry(ccs.Name) as 'Site Region',
    wi.Primary_Standard__c,
    date_format(wi.Work_Item_Date__c, '%Y %m') as 'Period', 
    r.Id as 'Resource Id',
    r.Name as 'Resource', 
    r.Reporting_Business_Units__c as 'Reporting Business Unit', 
    analytics.getBUFromReportingBusinessUnit(r.Reporting_Business_Units__c) as 'Business Unit',
    rccs.Name as 'Resource Country',
    r.Resource_Type__c as 'Resource Type',
    'Travel Days' as 'Type',
    sum(tsli.Actual_Hours__c)/8 as 'Value',
    'Day' as 'Unit'
from salesforce.work_item__c wi
inner join salesforce.timesheet_line_item__c tsli on tsli.Work_Item__c = wi.Id
inner join salesforce.resource__c r on tsli.Resource_Name__c = r.Name 
left join salesforce.country_code_setup__c rccs on r.Home_Country1__c = rccs.Id
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
inner join salesforce.account site on sc.Primary_client__c = site.Id
left join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id
where
wi.Work_Item_Date__c >= @start_date
and wi.Status__c in ('Completed')
and tsli.IsDeleted = 0
and tsli.Category__c = 'Travel'
and r.Reporting_Business_Units__c = 'EMEA-UK'
group by r.Id, wi.Id, `Period`)

union all

(select 
    wi.Id,
    wi.Name,
    site.Name as 'Site',
    ccs.Name as 'Site Country',
    analytics.getRegionFromCountry(ccs.Name) as 'Site Region',
    wi.Primary_Standard__c,
    date_format(wi.Work_Item_Date__c, '%Y %m') as 'Period', 
    r.Id as 'Resource Id',
    r.Name as 'Resource', 
    r.Reporting_Business_Units__c as 'Reporting Business Unit', 
    analytics.getBUFromReportingBusinessUnit(r.Reporting_Business_Units__c) as 'Business Unit',
    rccs.Name as 'Resource Country',
    r.Resource_Type__c as 'Resource Type',
    'Travel Distance' as 'Type',
    sum(eli.Quantity__c) as 'Value',
    'Miles/Km' as 'Unit'
    #analytics.distance(geo.Latitude, geo.Longitude, rgeo.Latitude, rgeo.Longitude) as 'Calculated Distance (Km)'
from salesforce.work_item__c wi
inner join salesforce.expense_line_item__c eli on eli.Work_Item__c = wi.Id
inner join salesforce.resource__c r on eli.Resource_Name__c = r.Name 
left join salesforce.country_code_setup__c rccs on r.Home_Country1__c = rccs.Id
#left join salesforce.state_code_setup__c rscs on r.Home_State_Province__c = rscs.Id
#left join salesforce.saig_geocode_cache rgeo 
#	on concat(
#		ifnull(concat(r.Home_Address_1__c, " "),""),
#        ifnull(concat(r.Home_Address_2__c, " "),""),
#        ifnull(concat(r.Home_Address_3__c, " "),""),
#        ifnull(concat(r.Home_City__c, " "),""),
#        ifnull(concat(rscs.Name, " "),""),
#        ifnull(concat(rccs.Name, " "),""),
#        ifnull(concat(r.Home_Postcode__c, " "),"")
#        ) = rgeo.Address
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
inner join salesforce.account site on sc.Primary_client__c = site.Id
left join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id
#left join salesforce.state_code_setup__c scs on site.Business_State__c = ccs.Id
#left join salesforce.saig_geocode_cache geo 
#	on concat(
#		ifnull(concat(site.Business_Address_1__c, " "),""),
#        ifnull(concat(site.Business_Address_2__c, " "),""),
#        ifnull(concat(site.Business_Address_3__c, " "),""),
#        ifnull(concat(site.Business_City__c, " "),""),
#        ifnull(concat(scs.Name, " "),""),
#        ifnull(concat(ccs.Name, " "),""),
#        ifnull(concat(site.Business_Zip_Postal_Code__c , " "),"")
#        ) = geo.Address
where
wi.Work_Item_Date__c > @start_date
and wi.Status__c in ('Completed')
and eli.IsDeleted = 0
and eli.Category__c = 'Travel Cost - Distance'
group by r.Id, wi.Id, `Period`);