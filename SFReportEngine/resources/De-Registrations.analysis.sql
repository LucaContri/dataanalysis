(select 
	client.Id as 'Client Id',
    client.name as 'Client Name',
    site.Id as 'Site Id',
    site.name as 'Site Name',
    analytics.getRegionFromCountry(ccs.Name) as 'Site Region',
    ccs.Name as 'Site Country',
    scs.Name as 'Site State',
    site.Business_Zip_Postal_Code__c as 'Site PostCode',
    site.Latitude__c as 'Site Latitude',
    site.Longitude__c as 'Site Longitude',
    i.Name as 'Industry (Compass)',
    if(i.Name = '99 | To be Confirmed',
		if( group_concat(distinct if(scspc.IsDeleted = 0 and codes.IsDeleted = 0 and scsp.IsDeleted = 0 and sc.IsDeleted = 0 and codes.Name like 'NACE%', salesforce.getIndustryFromNace(substring_index(replace(codes.Name,'NACE: ',''),'.',1)), null)) is null,
			if(group_concat(distinct sp.Program_Business_Line__c) like '%Product Services%', 
				'03 - Manufacturing',
				if(group_concat(distinct sp.Program_Business_Line__c) like '%Food%', 
					'03 - Manufacturing - Food & Beverages',
					if(group_concat(distinct scsp.Standard_Service_Type_Name__c) like '%Disability%' or group_concat(distinct scsp.Standard_Service_Type_Name__c) like '%DSS%', 
						'13 - Human Health and Social Work', 
						if(group_concat(distinct if(scspc.IsDeleted = 0 and codes.IsDeleted = 0 and scsp.IsDeleted = 0 and sc.IsDeleted = 0 and codes.Name like 'SAI%', codes.Name, null)) like '%SE01%' or 
							group_concat(distinct if(scspc.IsDeleted = 0 and codes.IsDeleted = 0 and scsp.IsDeleted = 0 and sc.IsDeleted = 0 and codes.Name like 'SAI%', codes.Name, null)) like '%SH01%',
							'02 - Mining and Quarrying',
							if(client.Client_Ownership__c='Product Services','03 - Manufacturing','99 | To be Confirmed'))
						)
					)
				),
			min(if(scspc.IsDeleted = 0 and codes.IsDeleted = 0 and scsp.IsDeleted = 0 and sc.IsDeleted = 0 and codes.Name like 'NACE%', salesforce.getIndustryFromNace(substring_index(replace(codes.Name,'NACE: ',''),'.',1)), '99 | To be Confirmed'))),
		if(i.Name in ('03 - 02 | Manufacture of beverages','03 - 05 | Manufacture of food products'),'03 - Manufacturing - Food & Beverages',i.Industry_Sector__c) 
	) as 'Industry (Guess)',
    group_concat(distinct codes.Name order by codes.Name) as 'Codes',
    scsp.Id as 'Site Cert Program Id',
    p.Business_Line__c as 'Business Line',
    sc.Id as 'Site Cert Id',
    dacv.`ACV`/ct.ConversionRate as 'Estimated lost value (AUD)',
    s.Name as 'Primary Standard',
    scsp.Withdrawn_Date__c as 'De-Registered Date',
    ifnull(scsp.Site_Originally_Registered__c, scsp.createdDate) as 'Originally Registered Date',
    scsp.De_registered_Type__c as 'De-Registered Type',
    scsp.Site_Certification_Status_Reason__c as 'De-Registered Reason',
    sc.Revenue_Ownership__c as 'Revenue Ownership',
    analytics.getCountryFromRevenueOwnership(sc.Revenue_Ownership__c) as 'Rev. Ownership Country',
    analytics.getRegionFromCountry(analytics.getCountryFromRevenueOwnership(sc.Revenue_Ownership__c)) as 'Rev. Ownership Region',
    timestampdiff(day, ifnull(scsp.Site_Originally_Registered__c, scsp.CreatedDate), scsp.Withdrawn_Date__c) as 'Duration (days)',
    substring_index(group_concat(distinct wi.Id order by wi.Work_Item_Date__c desc),',',1) as 'Last Audit Id',
    substring_index(group_concat(distinct wi.Name order by wi.Work_Item_Date__c desc),',',1) as 'Last Audit',
    substring_index(group_concat(distinct wi.Work_Item_Date__c order by wi.Work_Item_Date__c desc),',',1) as 'Last Audit Date',
    substring_index(group_concat(distinct wi.Work_Item_Stage__c order by wi.Work_Item_Date__c desc),',',1) as 'Last Audit Type',
    substring_index(group_concat(distinct wio.Name order by wi.Work_Item_Date__c desc),',',1) as 'Last WI Owner',
    substring_index(group_concat(distinct scheduler.Name order by wi.Work_Item_Date__c desc, wih.CreatedDate desc),',',1) as 'Last WI Confirmed by',
    c.Sample_Service__c as 'Sample Site',
    count(distinct if(otherScsp.Status__c in ('Registered', 'Customised', 'Applicant'), otherScsp.Id, null)) as 'Client # Registered Site Cert',
    count(distinct if(otherScsp.Status__c in ('Registered', 'Customised', 'Applicant'), otherSc.Primary_Certification__c, null)) as 'Client # Registered Certifications',
    count(distinct if(otherScsp.Status__c in ('Registered', 'Customised', 'Applicant'), otherSites.Id, null)) as 'Client # Active Sites'
from salesforce.site_certification_standard_program__c scsp
	left join analytics.deregistration_acv dacv on dacv.`Site Cert Std Id` = scsp.Id
    left join salesforce.currencytype ct on dacv.`Currency` = ct.IsoCode
	inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
    inner join salesforce.certification__c c on sc.Primary_Certification__c = c.Id
	inner join salesforce.account site on sc.Primary_client__c = site.Id
	inner join salesforce.account client on site.ParentId = client.Id
	left join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id
	left join salesforce.state_code_setup__c scs on site.Business_State__c = scs.Id
	left join salesforce.industry__c i on client.Industry_2__c = i.Id
	inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
    inner join salesforce.standard__c s on sp.Standard__c = s.Id
    inner join salesforce.program__c p on sp.Program__c = p.Id
    left join salesforce.site_cert_standard_program_code__c scspc on scspc.Site_Certification_Standard_Program__c = scsp.Id
	left join salesforce.code__c codes on scspc.Code__c = codes.Id
    left join salesforce.work_item__c wi on wi.Site_Certification_Standard__c = scsp.Id and wi.IsDeleted = 0 and wi.Status__c in ('In Progress', 'Submitted', 'Under Review', 'Under Review - Rejected', 'Support', 'Completed')
    left join salesforce.user wio on wi.OwnerId = wio.Id
    left join salesforce.work_item__history wih on wih.ParentId = wi.Id and wih.IsDeleted = 0 and wih.Field = 'Status__c' and wih.NewValue = 'Confirmed'
    left join salesforce.user scheduler on wih.CreatedById = scheduler.Id
    left join salesforce.account otherSites on otherSites.ParentId = client.Id and otherSites.IsDeleted = 0
    left join salesforce.certification__c otherSc on otherSc.Primary_client__c = otherSites.Id and otherSc.IsDeleted = 0
    left join salesforce.site_certification_standard_program__c otherScsp on otherScsp.Site_Certification__c = otherSc.Id and otherScsp.IsDeleted = 0
where
	scsp.IsDeleted=0
    and scsp.De_registered_Type__c in ('Client Initiated', 'SAI Initiated')
group by scsp.id);

(select 
	if(i.Name = '99 | To be Confirmed',
		if( group_concat(distinct if(scspc.IsDeleted = 0 and codes.IsDeleted = 0 and scsp.IsDeleted = 0 and sc.IsDeleted = 0 and codes.Name like 'NACE%', salesforce.getIndustryFromNace(substring_index(replace(codes.Name,'NACE: ',''),'.',1)), null)) is null,
			if(group_concat(distinct sp.Program_Business_Line__c) like '%Product Services%', 
				'03 - Manufacturing',
				if(group_concat(distinct sp.Program_Business_Line__c) like '%Food%', 
					'03 - Manufacturing - Food & Beverages',
					if(group_concat(distinct scsp.Standard_Service_Type_Name__c) like '%Disability%' or group_concat(distinct scsp.Standard_Service_Type_Name__c) like '%DSS%', 
						'13 - Human Health and Social Work', 
						if(group_concat(distinct if(scspc.IsDeleted = 0 and codes.IsDeleted = 0 and scsp.IsDeleted = 0 and sc.IsDeleted = 0 and codes.Name like 'SAI%', codes.Name, null)) like '%SE01%' or 
							group_concat(distinct if(scspc.IsDeleted = 0 and codes.IsDeleted = 0 and scsp.IsDeleted = 0 and sc.IsDeleted = 0 and codes.Name like 'SAI%', codes.Name, null)) like '%SH01%',
							'02 - Mining and Quarrying',
							if(client.Client_Ownership__c='Product Services','03 - Manufacturing','99 | To be Confirmed'))
						)
					)
				),
			min(if(scspc.IsDeleted = 0 and codes.IsDeleted = 0 and scsp.IsDeleted = 0 and sc.IsDeleted = 0 and codes.Name like 'NACE%', salesforce.getIndustryFromNace(substring_index(replace(codes.Name,'NACE: ',''),'.',1)), '99 | To be Confirmed'))),
		if(i.Name in ('03 - 02 | Manufacture of beverages','03 - 05 | Manufacture of food products'),'03 - Manufacturing - Food & Beverages',i.Industry_Sector__c) 
	) as 'Industry (Guess)',
    p.Business_Line__c as 'Business Line',
    count(sc.Id) as '# Site Cert Id',
    s.Name as 'Primary Standard',
    sc.Revenue_Ownership__c as 'Revenue Ownership',
    analytics.getCountryFromRevenueOwnership(sc.Revenue_Ownership__c) as 'Rev. Ownership Country',
    analytics.getRegionFromCountry(analytics.getCountryFromRevenueOwnership(sc.Revenue_Ownership__c)) as 'Rev. Ownership Region'
    from salesforce.site_certification_standard_program__c scsp
	inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
    inner join salesforce.certification__c c on sc.Primary_Certification__c = c.Id
	inner join salesforce.account site on sc.Primary_client__c = site.Id
	inner join salesforce.account client on site.ParentId = client.Id
	left join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id
	left join salesforce.state_code_setup__c scs on site.Business_State__c = scs.Id
	left join salesforce.industry__c i on client.Industry_2__c = i.Id
	inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
    inner join salesforce.standard__c s on sp.Standard__c = s.Id
    inner join salesforce.program__c p on sp.Program__c = p.Id
    left join salesforce.site_cert_standard_program_code__c scspc on scspc.Site_Certification_Standard_Program__c = scsp.Id
	left join salesforce.code__c codes on scspc.Code__c = codes.Id
where
	scsp.IsDeleted=0
    and scsp.Status__c in ('Registered', 'Customised')
group by `Industry (Guess)`,
    `Business Line`,
    `Primary Standard`,
    `Revenue Ownership`);