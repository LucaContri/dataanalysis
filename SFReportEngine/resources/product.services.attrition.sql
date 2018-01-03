#drop function isClientTypeTestOnly
DELIMITER $$
CREATE FUNCTION `isClientTypeTestOnly`(clientId VARCHAR(18)) RETURNS BOOLEAN 
BEGIN
	DECLARE retValue BOOLEAN DEFAULT false;
    SET retValue = (
		select ifnull(sum(csp.Standard_Service_Type_Name__c like '%TypeTest%') = count(csp.Id),0)
        from salesforce.certification_standard_program__c csp
        inner join salesforce.certification__c c on csp.Certification__c = c.Id
        where 
			c.Primary_client__c = clientId 
			and csp.Status__c not in ('De-Registered', 'Concluded')
    );
		
    RETURN retValue;
END$$
DELIMITER ;

DELIMITER $$
CREATE FUNCTION `getClientLastInvoiceDate`(clientId VARCHAR(18)) RETURNS DATETIME
BEGIN
	DECLARE retValue DATETIME default null;
    SET retValue = (
		select max(ifnull(i.From_Date__c, i.CreatedDate)) 
        from salesforce.invoice__c i 
		where 
			i.Billing_Client__c = clientId 
            and i.IsDeleted = 0
            and i.Status__c not in ('Cancelled')
		);
		
    RETURN retValue;
END$$
DELIMITER ;

#explain
(select t.*, count(distinct scsp.Certification_Standard__c) as '# Active Licences', count(distinct scsp.Id ) as '# Active Site Certs', count(distinct sites.Id) as '# Active Sites', if(count(distinct scsp.Certification_Standard__c)=0,false, true) as 'Client Active'
	, if(t.`Metric` = 'Actual Revenues', analytics.isClientTypeTestOnly(t.`Client Id`), 'n/a') as 'TypeTest Only Client'
    , if(t.`Metric` = 'Actual Revenues', analytics.getClientLastInvoiceDate(t.`Client Id`)<date_add(utc_timestamp(), interval -12 month), 'n/a') as 'Client Last Invoiced Over 12 Months'
from 
	((select 
		'De-Registraions' as 'Metric',
		scsp.Id as 'Id',
		sc.Revenue_Ownership__c as 'Revenue Ownership', 
		continent.name as 'Continent',
		country.sai_region as 'SAI Region',
		country.name as 'Country',
		client.Name as 'Client',
		client.Id as 'Client Id',
		site.Name as 'Site',
		scsp.Id as 'Site Cert Std Id', 
		scsp.Name as 'Site Cert Std', 
		scsp.Status__c as 'Site Cert Std Status',
		scsp.Withdrawn_Date__c as 'Date',
		'De-Registered Date' as 'Date Desc',
		date_format(scsp.Withdrawn_Date__c, '%Y %m') as 'Period', 
		scsp.De_registered_Type__c as 'Type',
		'De-Registered Type' as 'Type Desc',
		scsp.Site_Certification_Status_Reason__c as 'Category',
		'De-Registration Reason' as 'Category Desc',
		p.Business_Line__c as 'Business Line', 
		p.Pathway__c as 'Pathway',
		p.Name as 'Program',
		s.Name as 'Standard',
		rfp.Name as 'Product',
		'Registration Fee Product' as 'Product Desc',
		sum(ifnull(cep.FSales_Price__c/cct.ConversionRate, pbe.UnitPrice/ct.ConversionRate)/(ifnull(replace(replace(igr.Recurring_Fee_Frequency__c, ' months',''), 'Monthly', 1),12))*12) as 'Amount (AUD)',
		'Registration Fee Yearly (AUD)' as 'Amount Desc'
	from salesforce.site_certification_standard_program__c scsp
		inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
		inner join salesforce.account site on sc.Primary_client__c = site.Id
		inner join salesforce.account client on site.ParentId = client.Id
		left join salesforce.country_code_setup__c ccs on client.Client_Tax_Country__c = ccs.Id #site.Business_Country2__c = ccs.Id
		left join analytics.countries_names cn on ccs.Name = cn.name
		left join analytics.countries country on cn.code = country.code
		left join analytics.continents continent on country.continent_code = continent.code
		inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
		inner join salesforce.standard__c s on sp.Standard__c = s.Id
		inner join salesforce.program__c p on sp.Program__c = p.Id
		left join salesforce.product2 rfp on sc.Registration_Fee_Product__c = rfp.Id
		left join salesforce.invoice_group__c igr on sc.Invoice_Group_Registration__c = igr.Id
		left join salesforce.pricebookentry pbe on pbe.Product2Id = rfp.Id and pbe.Pricebook2Id = sc.Pricebook2Id__c
		left join salesforce.certification_pricing__c cep on cep.Certification__c = sc.Id and cep.IsDeleted = 0 and cep.Product__c = rfp.Id and cep.Sales_Price_Start_Date__c <= scsp.Withdrawn_Date__c and cep.Sales_Price_End_Date__c >= scsp.Withdrawn_Date__c
		left join salesforce.currencytype ct on pbe.CurrencyIsoCode = ct.IsoCode
		left join salesforce.currencytype cct on cep.CurrencyIsoCode = cct.IsoCode
	where 
		scsp.Status__c in ('De-Registered', 'Applicant Cancelled', 'Under Suspension', 'Expired', 'Concluded')
		and scsp.De_registered_Type__c in ('Client Initiated', 'SAI Initiated')
		and sc.Revenue_Ownership__c like '%Product%'
	group by `Revenue Ownership`, `Continent`, `SAI Region`,`Country`, `Id`, `Period`, `Type`, `Category`, `Business Line`, `Pathway`, `Program`, `Standard`)
	union
	(select 
		'Actual Revenues' as 'Metric',
		sha2(concat(client.Id, ili.Revenue_Ownership__c, date_format(ifnull(i.From_Date__c, i.CreatedDate), '%Y %m'), p.Product_Type__c, p.Category__c, s.Name), 256) as 'Id',
		ili.Revenue_Ownership__c as 'Revenue Ownership', 
		continent.name as 'Continent',
		country.sai_region as 'SAI Region',
		country.name as 'Country',
		client.Name as 'Client',
		client.Id as 'Client Id',
		'' as 'Site',
		'' as 'Site Cert Std Id', 
		'' as 'Site Cert Std', 
		'' as 'Site Cert Std Status',
		date_format(ifnull(i.From_Date__c, i.CreatedDate), '%Y-%m-01') as 'Date',
		'Invoice From or Created Date' as 'Date Desc',
		date_format(ifnull(i.From_Date__c, i.CreatedDate), '%Y %m') as 'Period', 
		p.Product_Type__c as 'Type',
		'Product Type' as 'Type Desc',
		p.Category__c as 'Category',
		'Product Category' as 'Category Desc',
		pr.Business_Line__c as 'Business Line', 
		pr.Pathway__c as 'Pathway',
		pr.Name as 'Program',
		s.Name as 'Standard',
		'' as 'Product',
		'' as 'Product Desc',
		sum(ili.Total_Line_Amount__c/ct.ConversionRate) as 'Amount',
		'Line Item Amount' as 'Amount Desc'
	from salesforce.invoice_line_item__c ili
		inner join salesforce.currencytype ct on ili.CurrencyIsoCode = ct.IsoCode
		inner join salesforce.product2 p on ili.Product__c = p.Id
		inner join salesforce.invoice__c i on ili.Invoice__c = i.Id
		inner join salesforce.account client on i.Billing_Client__c = client.Id
		left join salesforce.country_code_setup__c ccs on client.Client_Tax_Country__c = ccs.Id
		left join analytics.countries_names cn on ccs.Name = cn.name
		left join analytics.countries country on cn.code = country.code
		left join analytics.continents continent on country.continent_code = continent.code
		inner join salesforce.standard__c s on p.Standard__c = s.Id
		inner join salesforce.program__c pr on s.Program__c = pr.Id
	where
		ili.IsDeleted =0
		and i.IsDeleted = 0
		and i.Status__c not in ('Cancelled')
		and ili.Revenue_Ownership__c like '%Product%'
	group by `Revenue Ownership`, `Continent`, `SAI Region`,`Country`, client.id, `Period`, p.Product_Type__c, p.Category__c, `Business Line`, `Pathway`, `Program`, `Standard`)) t
	left join salesforce.account sites on t.`Client Id` = sites.ParentId and sites.IsDeleted = 0
	left join salesforce.certification__c sc on sc.Primary_client__c = sites.Id and sc.IsDeleted = 0
	left join salesforce.site_certification_standard_program__c scsp on scsp.Site_Certification__c = sc.Id and scsp.Status__c in ('Registered', 'Applicant', 'Customised') and scsp.IsDeleted = 0
group by t.`Metric`, t.`Id`
);

select 
		'Actual Revenues' as 'Metric',
		sha2(concat(client.Id, ili.Revenue_Ownership__c, date_format(ifnull(i.From_Date__c, i.CreatedDate), '%Y %m'), p.Product_Type__c, p.Category__c, s.Name), 256) as 'Id',
		ili.Revenue_Ownership__c as 'Revenue Ownership', 
        ili.Id,
        i.Id,
		continent.name as 'Continent',
		country.sai_region as 'SAI Region',
		country.name as 'Country',
		client.Name as 'Client',
		client.Id as 'Client Id',
		'' as 'Site',
		'' as 'Site Cert Std Id', 
		'' as 'Site Cert Std', 
		'' as 'Site Cert Std Status',
		date_format(ifnull(i.From_Date__c, i.CreatedDate), '%Y-%m-01') as 'Date',
		'Invoice From or Created Date' as 'Date Desc',
		date_format(ifnull(i.From_Date__c, i.CreatedDate), '%Y %m') as 'Period', 
		p.Product_Type__c as 'Type',
		'Product Type' as 'Type Desc',
		p.Category__c as 'Category',
        p.Name,
		'Product Category' as 'Category Desc',
		pr.Business_Line__c as 'Business Line', 
		pr.Pathway__c as 'Pathway',
		pr.Name as 'Program',
		s.Name as 'Standard',
		'' as 'Product',
		'' as 'Product Desc',
		ili.Total_Line_Amount__c/ct.ConversionRate as 'Amount',
		'Line Item Amount' as 'Amount Desc'
	from salesforce.invoice_line_item__c ili
		inner join salesforce.currencytype ct on ili.CurrencyIsoCode = ct.IsoCode
		inner join salesforce.product2 p on ili.Product__c = p.Id
		inner join salesforce.invoice__c i on ili.Invoice__c = i.Id
		inner join salesforce.account client on i.Billing_Client__c = client.Id
		left join salesforce.country_code_setup__c ccs on client.Client_Tax_Country__c = ccs.Id
		left join analytics.countries_names cn on ccs.Name = cn.name
		left join analytics.countries country on cn.code = country.code
		left join analytics.continents continent on country.continent_code = continent.code
		inner join salesforce.standard__c s on p.Standard__c = s.Id
		inner join salesforce.program__c pr on s.Program__c = pr.Id
	where
		ili.IsDeleted =0
		and i.IsDeleted = 0
		and i.Status__c not in ('Cancelled')
		and ili.Revenue_Ownership__c like '%Product%'
        and i.Billing_Client__c = '00190000008nWypAAE';
        
select p.NAme, p.Id, p.Category__c, p.Product_Type__c from salesforce.product2 p where p.Name like '%change%';

select cr.Id, cr.NAme, cr.Status__c , cr.Change_Request_Type__c ,  cr.Work_Item__c, ili.Id, ili.Invoice__c, p.Product_Type__c, p.Category__c 
from salesforce.change_request2__c cr 
left join salesforce.work_item__c wi on cr.Work_Item__c = wi.Id
left join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
left join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
left join salesforce.invoice_line_item__c ili on cr.Work_Item__c = ili.Work_Item__c and ili.IsDeleted = 0 and ili.Invoice_Status__c not in ('Cancelled')
left join salesforce.product2 p on ili.Product__c = p.Id 
where 
	cr.IsDeleted = 0
    and sp.Program_Business_Line__c = 'Product Services'
    and cr.Status__c = 'Completed'
order by cr.CreatedDate desc;

use salesforce;
create index change_request_wi_index on salesforce.change_request2__c(Work_Item__c) ;

#explain
select 
	cr.Id, 
    cr.NAme,
    cr.*,
    ili.Id, 
    ili.Invoice__c,
    wi.Name,
    wi.Id,
    wi.Status__c ,
    p.Product_Type__c, 
    p.Category__c
from salesforce.change_request2__c cr
	inner join salesforce.work_item__c wi on cr.Work_Item__c = wi.Id
    left join salesforce.invoice_line_item__c ili on wi.Id = ili.Work_Item__c and ili.IsDeleted = 0 and ili.Invoice_Status__c not in ('Cancelled')
	left join salesforce.product2 p on ili.Product__c = p.Id 
	
where 
	cr.Status__c = 'Completed'
    and wi.RecordTypeId in ('012900000003IkUAAU') # WI Project
    and wi.Status__c not in ('Cancelled', 'Budget')
    and cr.IsDeleted = 0
    and wi.IsDeleted = 0
order by cr.CreatedDate desc
