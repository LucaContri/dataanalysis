use salesforce;
# McDonalds Standards
create or replace view McDonalds_Standards as
select s.Name, s.Id from salesforce.standard__c s
where (s.name like '%McDonalds%' or s.Name like '%SQMS%' or s.Name like '%DQMP%');

# McDonalds Products
select p.Id, p.Name from salesforce.Product2 p 
where p.Standard__c in 
	(select s.Id from salesforce.standard__c s
	where s.name like '%McDonalds%');

# List of Upcoming Audits
(select 
	analytics.getRegionFromCountry(ccs.Name) as 'Region', 
    ccs.Name as 'Country',
    site.Name as 'Site Name',
    wi.Id as 'Work Item Id', 
    wi.Name as 'Work Item',
    wi.Work_Item_Date__c as 'Work Item Date',
    wi.Status__c as 'Work Item Status',
    wi.Required_Duration__c as 'Required Duration (hrs)',
    s.Name as 'Standard'
from salesforce.work_item__c wi
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
inner join salesforce.standard__c s on sp.Standard__c = s.Id
inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
inner join salesforce.account site on sc.Primary_client__c = site.Id
left join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id
where 
(s.name like '%McDonalds%' or s.Name like '%SQMS%' or s.Name like '%DQMP%')
and wi.IsDeleted = 0
and wi.Status__c not in ('Cancelled', 'Draft', 'Initiate Service')
and wi.Work_Item_Date__c between '2017-01-01' and '2017-12-31');

#List of Sites (global)
#explain
create or replace view McDonalds_Client_List as
(select 
	parent.Id as 'Parent Id',
	parent.Name as 'Parent Client',
	client.id as 'Client Id',
	client.Name as 'Client Name',
    client.Client_Ownership__c as 'Ownership',
	site.Id as 'Site Id', 
	site.Name as 'Site Name', 
	site.Business_Address_1__c as 'Site Address 1',
	site.Business_Address_2__c as 'Site Address 2',
	site.Business_Address_3__c as 'Site Address 3',
	site.Business_City__c as 'Site City',
	scs.Name as 'Site State',
	site.Business_Zip_Postal_Code__c as 'Site PostCode',
	ccs.Name as 'Site Country',
	sc.Id as 'Site Certification Id', 
	sc.Name as 'Site Certification', 
    sc.Revenue_Ownership__c as 'Revenue Ownership',
    scsp.Administration_Ownership__c as 'Administration Ownership',
	scsp.Id as 'Site Certification Standard Id', 
	scsp.Name as 'Site Certification Standard', 
    scsp.External_Site_Code__c as 'External Site Ref.',
	csp.Name as 'Certification Standard',
	csp.External_provided_certificate__c as 'Certification Standard External Ref',
	s.Name as 'Primary Standard', 
	group_concat(distinct if(scsf.IsDeleted or fsp.isDeleted or fs.IsDeleted, null,fs.Name)) as 'Family Standard',
    group_concat(distinct if(scspc.IsDeleted or cod.isDeleted, null,cod.Name)) as 'Codes'
from site_certification_standard_program__c scsp
	inner join salesforce.Certification_Standard_Program__c csp on scsp.Certification_Standard__c = csp.Id
	inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
	inner join salesforce.account site on sc.Primary_client__c = site.id
	left join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id
	left join salesforce.state_code_setup__c scs on site.Business_State__c = scs.Id
	inner join salesforce.account client on site.ParentId = client.id
	left join salesforce.account parent on client.ParentId = parent.id
	left join salesforce.standard_program__c sp on sp.Id = scsp.Standard_Program__c
	left join salesforce.standard__c s on sp.Standard__c = s.Id
	left join salesforce.site_certification_standard_family__c scsf on scsf.Site_Certification_Standard__c = scsp.Id
	left join salesforce.standard_program__c fsp on scsf.Standard_Program__c = fsp.Id
	left join salesforce.standard__c fs on fsp.Standard__c = fs.Id
	left join salesforce.site_cert_standard_program_code__c scspc on scspc.Site_Certification_Standard_Program__c = scsp.Id
	left join salesforce.code__c cod on scspc.Code__c = cod.Id
	left join salesforce.McDonalds_Standards mcs1 on sp.Standard__c = mcs1.Id
	left join salesforce.McDonalds_Standards mcs2 on fsp.Standard__c = mcs2.Id
where 
	(mcs1.Id is not null or mcs2.Id is not null)
	and site.IsDeleted=0
	and sc.IsDeleted=0
	and scsp.IsDeleted=0
	and site.Status__c='Active'
	and sc.Status__c = 'Active'
	and scsp.Status__c not in ('De-registered','Concluded')
	and (scsf.IsDeleted=0 or scsf.IsDeleted is null)
group by scsp.Id);

select * from salesforce.McDonalds_Client_List where `Client Name` like '%Lion%';

#Revenues from McDonalds Standard
create or replace view McDonalds_Revenues as
#explain
(select 
	'Invoice Line Item' as 'Record Type',
	i.Billing_Client__c as 'Client Id', 
	mccl.`Client Name`,
	i.Id as 'Invoice Id', 
	i.Name as 'Invoice Name',
	i.Status__c as 'Invoice Status', 
	i.Invoice_Processed_Date__c as 'Invoice Processed Date', 
	date_format(i.Invoice_Processed_Date__c, '%Y %m') as 'Invoice Processed Period', 
    if(month(i.Invoice_Processed_Date__c)<7,0,1)+year(i.Invoice_Processed_Date__c) as 'Invoice Processed FY',
	i.CreatedDate as 'Invoice Created Date', 
	date_format(i.CreatedDate, '%Y %m') as 'Invoice Created Period', 
    if(month(i.CreatedDate)<7,0,1)+year(i.CreatedDate) as 'Invoice Created FY',
	ili.Revenue_Ownership__c as 'Revenue Ownership', 
    analytics.getCountryFromRevenueOwnership(ili.Revenue_Ownership__c) as 'Country',
    if(ili.Revenue_Ownership__c like 'Asia%', 'Asia',if(ili.Revenue_Ownership__c like 'EMEA%', 'EMEA',if(ili.Revenue_Ownership__c like 'AUS%', 'Australia',ili.Revenue_Ownership__c))) as 'Region',
	ili.Total_Line_Amount__c as 'Total Amount Ex Tax', 
	ili.CurrencyIsoCode, 
    ili.Total_Line_Amount__c/ct.ConversionRate as 'Total Amount Ex Tax (AUD)', 
	p.Name as 'Product Name',
	ili.Product_Category__c as 'Product Category', 
	if (p.Standard__c in (select ID from salesforce.McDonalds_Standards), 1,0) as 'McDonald Product Revenue',
    if(s.Name like '%McDonald%' or group_concat(fs.Name) like '%McDonald%' or s.Name like '%DQMP%' or group_concat(fs.Name) like '%DQMP%', 1, 0) as 'McDonald Standard or FoS',
    wi.Id as 'Work Item Id', 
    wi.Name as 'Work Item',
    wi.Work_Item_Date__c as 'Audit Start Date',
    date_format(wi.Work_Item_Date__c, '%Y %m') as 'Audit Period', 
    if(month(wi.Work_Item_Date__c)<7,0,1)+year(wi.Work_Item_Date__c) as 'Audit FY',
    wi.`Client_Site__c` as 'Client Site',
    s.Name as 'Primary Standard',
    group_concat(fs.Name) as 'Family Standard'
from salesforce.invoice__c i
	inner join salesforce.Invoice_Line_Item__c ili on ili.invoice__c = i.Id
    inner join salesforce.currencytype ct on ili.CurrencyIsoCode = ct.IsoCode
	inner join salesforce.product2 p on ili.Product__c = p.Id
	inner join salesforce.McDonalds_Client_List mccl on mccl.`Client Id` = i.Billing_Client__c
    left join salesforce.work_item__c wi on ili.Work_Item__c = wi.Id
    left join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c =  scsp.Id
    left join salesforce.standard_program__c sp on sp.Id = scsp.Standard_Program__c
	left join salesforce.standard__c s on sp.Standard__c = s.Id
	left join salesforce.site_certification_standard_family__c scsf on scsf.Site_Certification_Standard__c = scsp.Id
	left join salesforce.standard_program__c fsp on scsf.Standard_Program__c = fsp.Id
	left join salesforce.standard__c fs on fsp.Standard__c = fs.Id
where 
	i.Status__c not in ('Cancelled')
	and i.IsDeleted=0
	and ili.IsDeleted=0
	and p.IsDeleted=0
group by ili.Id)
union all
(select 
	'Work Item in Progress' as 'Record Type',
	mccl.`Client Id`, 
	mccl.`Client Name`,
	null as 'Invoice Id', 
	null as 'Invoice Name',
	null as 'Invoice Status', 
	null as 'Invoice Processed Date', 
	null as 'Invoice Processed Period', 
    null as 'Invoice Processed FY',
	null as 'Invoice Created Date', 
	null as 'Invoice Created Period', 
    null as 'Invoice Created FY',
	sc.Revenue_Ownership__c as 'Revenue Ownership', 
    analytics.getCountryFromRevenueOwnership(sc.Revenue_Ownership__c) as 'Country',
    if(sc.Revenue_Ownership__c like 'Asia%', 'Asia',if(sc.Revenue_Ownership__c like 'EMEA%', 'EMEA',if(sc.Revenue_Ownership__c like 'AUS%', 'Australia',sc.Revenue_Ownership__c))) as 'Region',
	av.`Calculated Value` as 'Total Amount Ex Tax', 
	av.`Calculated Currency`, 
    av.`Calculated Value`/ct.`ConversionRate` as 'Total Amount Ex Tax (AUD)', 
	null as 'Product Name',
	'Audit' as 'Product Category', 
	if (s.Id in (select ID from salesforce.McDonalds_Standards), 1,0) as 'McDonald Product Revenue',
    if(s.Name like '%McDonald%' or group_concat(fs.Name) like '%McDonald%' or s.Name like '%DQMP%' or group_concat(fs.Name) like '%DQMP%', 1, 0) as 'McDonald Standard or FoS',
    wi.Id as 'Work Item Id', 
    wi.Name as 'Work Item',
    wi.Work_Item_Date__c as 'Audit Start Date',
    date_format(wi.Work_Item_Date__c, '%Y %m') as 'Audit Period', 
    if(month(wi.Work_Item_Date__c)<7,0,1)+year(wi.Work_Item_Date__c) as 'Audit FY',
    wi.`Client_Site__c` as 'Client Site',
    s.Name as 'Primary Standard',
    group_concat(fs.Name) as 'Family Standard'
from salesforce.work_item__c wi 
	inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c =  scsp.Id
    inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
    inner join salesforce.account site on sc.Primary_client__c = site.Id
    inner join salesforce.McDonalds_Client_List mccl on mccl.`Client Id` = site.ParentId
    inner join salesforce.standard_program__c sp on sp.Id = scsp.Standard_Program__c
	inner join salesforce.standard__c s on sp.Standard__c = s.Id
	left join salesforce.site_certification_standard_family__c scsf on scsf.Site_Certification_Standard__c = scsp.Id
	left join salesforce.standard_program__c fsp on scsf.Standard_Program__c = fsp.Id
	left join salesforce.standard__c fs on fsp.Standard__c = fs.Id
    left join analytics.audit_values av on av.`Work Item Id` = wi.Id
    left join salesforce.currencytype ct on av.`Calculated Currency` = ct.`IsoCode`
where 
	wi.Status__c in ('In Progress')
	and wi.IsDeleted = 0
group by wi.Id);

(select * from salesforce.McDonalds_Revenues);

#Revenues from McDonalds Standard
create or replace view McDonalds_Revenues_V2 as
#explain
(select 
	'Invoice Line Item' as 'Record Type',
	i.Billing_Client__c as 'Client Id', 
	mccl.`Name` as 'Client Name',
	i.Id as 'Invoice Id', 
	i.Name as 'Invoice Name',
	i.Status__c as 'Invoice Status', 
	i.Invoice_Processed_Date__c as 'Invoice Processed Date', 
	date_format(i.Invoice_Processed_Date__c, '%Y %m') as 'Invoice Processed Period', 
    if(month(i.Invoice_Processed_Date__c)<7,0,1)+year(i.Invoice_Processed_Date__c) as 'Invoice Processed FY',
	i.CreatedDate as 'Invoice Created Date', 
	date_format(i.CreatedDate, '%Y %m') as 'Invoice Created Period', 
    if(month(i.CreatedDate)<7,0,1)+year(i.CreatedDate) as 'Invoice Created FY',
	ili.Revenue_Ownership__c as 'Revenue Ownership', 
    analytics.getCountryFromRevenueOwnership(ili.Revenue_Ownership__c) as 'Country',
    if(ili.Revenue_Ownership__c like 'Asia%', 'Asia',if(ili.Revenue_Ownership__c like 'EMEA%', 'EMEA',if(ili.Revenue_Ownership__c like 'AUS%', 'Australia',ili.Revenue_Ownership__c))) as 'Region',
	ili.Total_Line_Amount__c as 'Total Amount Ex Tax', 
	ili.CurrencyIsoCode, 
    ili.Total_Line_Amount__c/ct.ConversionRate as 'Total Amount Ex Tax (AUD)', 
	p.Name as 'Product Name',
	ili.Product_Category__c as 'Product Category', 
	if (p.Standard__c in (select ID from salesforce.McDonalds_Standards), 1,0) as 'McDonald Product Revenue',
    if(s.Name like '%McDonald%' or group_concat(fs.Name) like '%McDonald%' or s.Name like '%DQMP%' or group_concat(fs.Name) like '%DQMP%', 1, 0) as 'McDonald Standard or FoS',
    wi.Id as 'Work Item Id', 
    wi.Name as 'Work Item',
    wi.Work_Item_Date__c as 'Audit Start Date',
    date_format(wi.Work_Item_Date__c, '%Y %m') as 'Audit Period', 
    if(month(wi.Work_Item_Date__c)<7,0,1)+year(wi.Work_Item_Date__c) as 'Audit FY',
    wi.`Client_Site__c` as 'Client Site',
    s.Name as 'Primary Standard',
    group_concat(fs.Name) as 'Family Standard'
from salesforce.invoice__c i
	inner join salesforce.Invoice_Line_Item__c ili on ili.invoice__c = i.Id
    inner join salesforce.currencytype ct on ili.CurrencyIsoCode = ct.IsoCode
	inner join salesforce.product2 p on ili.Product__c = p.Id
	inner join salesforce.account mccl on mccl.Id = i.Billing_Client__c
    inner join salesforce.work_item__c wi on ili.Work_Item__c = wi.Id
    inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c =  scsp.Id
    inner join salesforce.standard_program__c sp on sp.Id = scsp.Standard_Program__c
	inner join salesforce.standard__c s on sp.Standard__c = s.Id
	left join salesforce.site_certification_standard_family__c scsf on scsf.Site_Certification_Standard__c = scsp.Id
	left join salesforce.standard_program__c fsp on scsf.Standard_Program__c = fsp.Id
	left join salesforce.standard__c fs on fsp.Standard__c = fs.Id
where 
	i.Status__c not in ('Cancelled')
	and i.IsDeleted=0
	and ili.IsDeleted=0
	and p.IsDeleted=0
    and (s.Id in (select Id from McDonalds_Standards) or fs.Id in (select Id from McDonalds_Standards))
group by ili.Id)
union all
(select 
	'Work Item in Progress' as 'Record Type',
	mccl.Id as 'Client Id', 
	mccl.Name as 'Client Name',
	null as 'Invoice Id', 
	null as 'Invoice Name',
	null as 'Invoice Status', 
	null as 'Invoice Processed Date', 
	null as 'Invoice Processed Period', 
    null as 'Invoice Processed FY',
	null as 'Invoice Created Date', 
	null as 'Invoice Created Period', 
    null as 'Invoice Created FY',
	sc.Revenue_Ownership__c as 'Revenue Ownership', 
    analytics.getCountryFromRevenueOwnership(sc.Revenue_Ownership__c) as 'Country',
    if(sc.Revenue_Ownership__c like 'Asia%', 'Asia',if(sc.Revenue_Ownership__c like 'EMEA%', 'EMEA',if(sc.Revenue_Ownership__c like 'AUS%', 'Australia',sc.Revenue_Ownership__c))) as 'Region',
	av.`Calculated Value` as 'Total Amount Ex Tax', 
	av.`Calculated Currency`, 
    av.`Calculated Value`/ct.`ConversionRate` as 'Total Amount Ex Tax (AUD)', 
	null as 'Product Name',
	'Audit' as 'Product Category', 
	if (s.Id in (select ID from salesforce.McDonalds_Standards), 1,0) as 'McDonald Product Revenue',
    if(s.Name like '%McDonald%' or group_concat(fs.Name) like '%McDonald%' or s.Name like '%DQMP%' or group_concat(fs.Name) like '%DQMP%', 1, 0) as 'McDonald Standard or FoS',
    wi.Id as 'Work Item Id', 
    wi.Name as 'Work Item',
    wi.Work_Item_Date__c as 'Audit Start Date',
    date_format(wi.Work_Item_Date__c, '%Y %m') as 'Audit Period', 
    if(month(wi.Work_Item_Date__c)<7,0,1)+year(wi.Work_Item_Date__c) as 'Audit FY',
    wi.`Client_Site__c` as 'Client Site',
    s.Name as 'Primary Standard',
    group_concat(fs.Name) as 'Family Standard'
from salesforce.work_item__c wi 
	inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c =  scsp.Id
    inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
    inner join salesforce.account site on sc.Primary_client__c = site.Id
    inner join salesforce.account mccl on mccl.Id = site.ParentId
    inner join salesforce.standard_program__c sp on sp.Id = scsp.Standard_Program__c
	inner join salesforce.standard__c s on sp.Standard__c = s.Id
	left join salesforce.site_certification_standard_family__c scsf on scsf.Site_Certification_Standard__c = scsp.Id
	left join salesforce.standard_program__c fsp on scsf.Standard_Program__c = fsp.Id
	left join salesforce.standard__c fs on fsp.Standard__c = fs.Id
    left join analytics.audit_values av on av.`Work Item Id` = wi.Id
    left join salesforce.currencytype ct on av.`Calculated Currency` = ct.`IsoCode`
where 
	wi.Status__c in ('In Progress')
	and wi.IsDeleted = 0
    and (s.Id in (select Id from McDonalds_Standards) or fs.Id in (select Id from McDonalds_Standards))
group by wi.Id);

(select * from salesforce.McDonalds_Revenues_V2);