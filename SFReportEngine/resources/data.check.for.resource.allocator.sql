# Auditor Location Exceptions
(select 
	r.Reporting_Business_Units__c as 'Reporting Business Unit', 
    r.Resource_Type__c as 'Resource Type',
    r.Job_Family__c,
    r.Id as 'Resource Id', 
    r.Name as 'Resource', 
    r.Resource_Capacitiy__c as 'Resource Capacity',
    m.Name as 'Manager',
    analytics.getRegionFromCountry(ccs.Name) as 'Region', 
    ccs.Name as 'Country', 
    scs.Name as 'State', 
    r.Home_City__c as 'City', 
    r.Home_Postcode__c as 'Postcode',
    (ccs.Name is null) as 'Missing Country',
    r.Home_City__c is null as 'Missing City',
    (analytics.getRegionFromCountry(ccs.Name) not in ('EMEA')) as 'Region not matching Business Unit',
    (m.Name is null) as 'Missing Manager',
    r.Home_City__c is null and r.Home_Postcode__c is null as 'Missing City and PostCode'
from salesforce.resource__c r
	inner join salesforce.user u on r.User__c = u.Id
    left join salesforce.user m on u.ManagerId = m.Id
	left join salesforce.country_code_setup__c ccs on r.Home_Country1__c = ccs.Id
	left join salesforce.state_code_setup__c scs on r.Home_State_Province__c = scs.Id
where r.Reporting_Business_Units__c like 'EMEA%'
and r.Job_Family__c like '%audit%'
and r.Status__c = 'Active'
);

# Site Location
(select 
	scsp.Administration_Ownership__c as 'Admin Ownership', 
	site.Id as 'Site Id',
	site.Name as 'Site Name',
    site.Business_Address_1__c as 'Address Line 1', 
    site.Business_Address_2__c as 'Address Line 2', 
    site.Business_Address_3__c as 'Address Line 3', 
    site.Business_City__c as 'City',
    scs.Name as 'State',
    ccs.Name as 'Country',
    site.Business_Zip_Postal_Code__c as 'Postcode',
    site.Business_Address_1__c is null as 'Missing Address Line 1',
    site.Business_City__c is null as 'Missing City',
    scs.Name is null as 'Missing State',
    ccs.Name is null as 'Missing Country',
    site.Business_Zip_Postal_Code__c is null as 'Missing Postcode',
    concat(
	 ifnull(concat(site.Business_Address_1__c,' '),''),
	 ifnull(concat(site.Business_Address_2__c,' '),''),
	 ifnull(concat(site.Business_Address_3__c,' '),''),
	 ifnull(concat(site.Business_City__c,' '),''),
	 ifnull(concat(scs.Name,' '),''),
	 ifnull(concat(ccs.Name,' '),''),
	 ifnull(concat(site.Business_Zip_Postal_Code__c,' '),'')) as 'Formatted Address',
    ifnull(geo_site.Latitude,'') as 'Google Geocoding Latitude', 
    ifnull(geo_site.Longitude,'') as 'Google Geocoding Longitude',
    ifnull(site.Latitude__c,'') as 'Compass Latitude',
    ifnull(site.Longitude__c,'') as 'Compass Longitude'
from salesforce.site_certification_standard_program__c scsp 
	inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
    inner join salesforce.account site on sc.Primary_client__c = site.Id
    left join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id
    left join salesforce.state_code_setup__c scs on site.Business_State__c = scs.Id
    left join salesforce.saig_geocode_cache geo_site on geo_site.Address = concat(
	 ifnull(concat(site.Business_Address_1__c,' '),''),
	 ifnull(concat(site.Business_Address_2__c,' '),''),
	 ifnull(concat(site.Business_Address_3__c,' '),''),
	 ifnull(concat(site.Business_City__c,' '),''),
	 ifnull(concat(scs.Name,' '),''),
	 ifnull(concat(ccs.Name,' '),''),
	 ifnull(concat(site.Business_Zip_Postal_Code__c,' '),''))
where
	scsp.Administration_Ownership__c like 'EMEA%'
    and scsp.Status__c in ('Applicant','Registered','Customised')
    and geo_site.Latitude is null
);

# Auditor competency codes (Auditors with Standards but not matching codes)
#explain
(select * from
	(select 
		r.Reporting_Business_Units__c as 'Reporting Business Unit', 
		r.Resource_Type__c as 'Resource Type', 
        r.Id as 'Resource Id', 
        r.Name as 'Resource', 
        s.NAme as 'Standard', 
        rcs.Rank__c as 'Rank',
        r.Resource_Capacitiy__c as 'Capacity',
        sc.Code_Type__c as 'Code Type', 
        trim(substring_index(sc.Code_Type__c, ';',1)) as 'Code Type 1',
        trim(substring_index(substring_index(sc.Code_Type__c, ';',2),';',-1)) as 'Code Type 2',
        trim(substring_index(substring_index(sc.Code_Type__c, ';',3),';',-1)) as 'Code Type 3',
        concat(
			ifnull(group_concat(distinct c1.Name),''),
			ifnull(group_concat(distinct c2.Name),''),
			ifnull(group_concat(distinct c3.Name),'')) as 'Codes'
	from salesforce.resource__c r
	inner join salesforce.resource_competency__c rcs on r.Id = rcs.Resource__c
	inner join salesforce.standard__c s on rcs.Standard__c = s.Id
	inner join salesforce.standard_code__c sc on sc.Standard__c = s.Id
	left join salesforce.resource_competency__c rcc on rcc.Resource__c = r.Id and rcc.Status__c = 'Active'
	left join salesforce.code__c c1 on rcc.Code__c = c1.Id and c1.Type__c = trim(substring_index(sc.Code_Type__c, ';',1))
    left join salesforce.code__c c2 on rcc.Code__c = c2.Id and c2.Type__c = trim(substring_index(substring_index(sc.Code_Type__c, ';',2),';',-1))
    left join salesforce.code__c c3 on rcc.Code__c = c3.Id and c3.Type__c = trim(substring_index(substring_index(sc.Code_Type__c, ';',2),';',-1))
	where 
		r.Reporting_Business_Units__c like 'EMEA%'
        and r.Job_Family__c like '%audit%'
		and rcs.Status__c = 'Active'
        and rcs.Rank__c like '%Auditor%'
		and rcs.Standard__c is not null
	group by r.Id, rcs.Id
	) t 
where t.`Codes` = '');

# Site codes
(select t.* from
	(select 
		scsp.Administration_Ownership__c as 'Administration Ownership', 
        site.Name as 'Site',
		scsp.Id as 'Site Cert Std Id', 
        scsp.Name as 'Site Cert Std', 
        scsp.Status__c as 'Status',
        sp.Standard_Service_Type_Name__c as 'Standard', 
        ifnull(group_concat(c.Name), '') as 'Codes'
	from salesforce.site_certification_standard_program__c scsp
		inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
        inner join salesforce.account site on sc.Primary_client__c = site.Id
		inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
		left join salesforce.site_cert_standard_program_code__c scspc on scspc.Site_Certification_Standard_Program__c = scsp.Id and scspc.IsDeleted = 0
		left join salesforce.code__C c on c.Id = scspc.Code__c
	where scsp.Administration_Ownership__c like 'EMEA%'
		and scsp.Status__c in ('Applicant','Registered','Customised')
	group by scsp.Id) t
where t.`Codes` = '');

# Duration of audit
(select 
	wi.Id, 
    wi.Name,
    wi.Required_Duration__c,
    wi.Revenue_Ownership__c,
    scsp.Administration_Ownership__c,
    wi.Primary_Standard__c,
    wi.Status__c,
    wi.Work_Item_Stage__c
from salesforce.work_item__c wi
	inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
where (scsp.Administration_Ownership__c like 'EMEA%' or wi.Revenue_Ownership__c like 'EMEA%')
	and wi.IsDeleted = 0
    and wi.Status__c in ('Open')
    and wi.Required_Duration__c is null)