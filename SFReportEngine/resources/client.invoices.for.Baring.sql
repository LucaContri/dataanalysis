create temporary table client_industry as
(select a.Id as 'Client Compass Id',
if(i.Name in ('03 - 02 | Manufacture of beverages','03 - 05 | Manufacture of food products'),'03 - Manufacturing - Food & Beverages',i.Industry_Sector__c) as 'Industry (Compass)',
if(i.Name = '99 | To be Confirmed',
	if( group_concat(distinct if(scspc.IsDeleted = 0 and code.IsDeleted = 0 and scsp.IsDeleted = 0 and sc.IsDeleted = 0 and c.IsDeleted = 0 and code.Name like 'NACE%', salesforce.getIndustryFromNace(substring_index(replace(code.Name,'NACE: ',''),'.',1)), null)) is null,
		if(group_concat(distinct prog.Business_Line__c) like '%Product Services%', 
			'03 - Manufacturing',
            if(group_concat(distinct prog.Business_Line__c) like '%Food%', 
				'03 - Manufacturing - Food & Beverages',
                if(group_concat(distinct std.Name) like '%Disability%' or group_concat(distinct std.Name) like '%DSS%', 
					'13 - Human Health and Social Work', 
                    if(group_concat(distinct if(scspc.IsDeleted = 0 and code.IsDeleted = 0 and scsp.IsDeleted = 0 and sc.IsDeleted = 0 and c.IsDeleted = 0 and code.Name like 'SAI%', code.Name, null)) like '%SE01%' or 
						group_concat(distinct if(scspc.IsDeleted = 0 and code.IsDeleted = 0 and scsp.IsDeleted = 0 and sc.IsDeleted = 0 and c.IsDeleted = 0 and code.Name like 'SAI%', code.Name, null)) like '%SH01%',
						'02 - Mining and Quarrying',
                        if(a.Client_Ownership__c='Product Services','03 - Manufacturing','99 | To be Confirmed'))
                    )
				)
            ),
        min(if(scspc.IsDeleted = 0 and code.IsDeleted = 0 and scsp.IsDeleted = 0 and sc.IsDeleted = 0 and c.IsDeleted = 0 and code.Name like 'NACE%', salesforce.getIndustryFromNace(substring_index(replace(code.Name,'NACE: ',''),'.',1)), '99 | To be Confirmed'))),
	if(i.Name in ('03 - 02 | Manufacture of beverages','03 - 05 | Manufacture of food products'),'03 - Manufacturing - Food & Beverages',i.Industry_Sector__c) 
) as 'Industry (Guess)'
from salesforce.account a
inner join salesforce.account inv_site on inv_site.ParentId = a.Id
inner join salesforce.industry__c i on a.Industry_2__c = i.Id
left join salesforce.certification__c c on c.Primary_client__c = a.Id
left join salesforce.standard_program__c sp on c.Primary_Standard__c = sp.Id
left join salesforce.standard__c std on sp.Standard__c = std.Id
left join salesforce.program__c prog on sp.Program__c = prog.Id
left join salesforce.certification__c sc on sc.Primary_Certification__c = c.Id
left join salesforce.site_certification_standard_program__c scsp on scsp.Site_Certification__c = sc.Id
left join salesforce.site_cert_standard_program_code__c scspc on scspc.Site_Certification_Standard_Program__c = scsp.Id
left join salesforce.code__c code on scspc.Code__c = code.Id
where a.Record_Type_Name__c = 'Client'
and a.IsDeleted = 0
and a.Status__c = 'Active'
and if(a.Client_Ownership__c in ('Australia', 'Product Services'), inv_site.Finance_Statement_Site__c, 1)
group by a.Id);

create index client_industry_index on client_industry(`Client Compass Id`);

#explain
(select
	client.name as 'Client Name',
    client.Client_Number__c as 'Client Number',
    client.Id as 'Client Compass Id',
    client.Client_Ownership__c as 'Client Ownership', 
    ci.`Industry (Compass)`,
    ci.`Industry (Guess)`,
    i.Id as 'Invoice Compass Id',
    i.Name as 'Invoice Name',
    i.CreatedDate as 'Invoice Created Date',
    i.Invoice_Processed_Date__c as 'Invoice Processed Date',
    i.Status__c as 'Invoice Status',
    ili.Id as 'Invoice Line Item Compass Id',
    ili.Name as 'Invoice Line Item',
    analytics.getRegionFromCountry(analytics.getCountryFromRevenueOwnership(ili.Revenue_Ownership__c)) as 'Revenue Oenwership Region',
    analytics.getCountryFromRevenueOwnership(ili.Revenue_Ownership__c) as 'Revenue Oenwership Country',
    ili.Revenue_Ownership__c as 'Revenue Ownership',
    ili.Total_Line_Amount__c as 'Total Line Amount',
    ili.CurrencyIsoCode as 'Currency',
    ili.Total_Line_Amount__c/ct.ConversionRate as 'Total Line Amount (AUD)',
    pr.Name as 'Product',
    pr.Category__c as 'Product Category',
    pr.Product_Type__c as 'Product Type',
    pr.UOM__c as 'Unit of Measure',
    ili.Quantity__c as 'Quantity',
    if (pr.UOM__c = 'DAY', 8, if(pr.UOM__c = 'HFD', 4, if(pr.UOM__c = 'HR', 1, 0)))*ili.Quantity__c as 'Duration (Hrs)',
    if (pr.UOM__c = 'KM',1,0)*ili.Quantity__c as 'Distance (km)', 
    p.Business_Line__c as 'Business Line',
    p.Pathway__c as 'Pathway',
    p.Name as 'Program',
    s.Name as 'Standard',
    ifnull(wi.Id, '') as 'Work Item Compass Id',
    ifnull(wi.Name, '') as 'Work Item',
    ifnull(wi.Work_Item_Date__c, '') as 'Work Item Date',
    ifnull(wi.Required_Duration__c, '') as 'Work Item Required Duration (hr)'
from salesforce.invoice__c i
	inner join salesforce.account client on i.Billing_Client__c = client.Id
    left join client_industry ci on ci.`Client Compass Id` = client.Id
    inner join salesforce.invoice_line_item__c ili on ili.Invoice__c = i.Id
    inner join salesforce.currencytype ct on ili.CurrencyIsoCode = ct.IsoCode
	left join salesforce.industry__c ind on client.`Industry_2__c` = ind.Id
    inner join salesforce.product2 pr on ili.Product__c = pr.Id
    inner join salesforce.standard__c s on pr.Standard__c = s.Id
    inner join salesforce.program__c p on s.Program__c = p.Id
    left join salesforce.work_item__c wi on ili.Work_Item__c = wi.Id
where
	i.IsDeleted = 0
    and i.Status__c not in ('Cancelled')
    and ili.IsDeleted = 0
group by ili.Id);