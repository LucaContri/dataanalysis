(select 
	if(pa.Id is null,'Single Client', 'Corporate Client') as 'Account Type',
	ifnull(pa.Id, a.Id) as 'Parent Account Id', 
    ifnull(pa.Name, a.Name) as 'Parent Account Name', 
    a.Id as 'Account Id', 
    a.Name as 'Account Name', 
    i.Id as 'Invoice Id', 
    i.Name as 'Invoice', 
    i.Status__c as 'Invoice Status', 
    p.Name as 'Product',
    p.Category__c, 
    p.Product_Type__c, 
    st.Name as 'Standard',
    prog.Business_Line__c as 'Business Line',
    ili.Product_Category__c as 'Product Category', 
    ili.Revenue_Ownership__c as 'Revenue Ownership', 
    ili.Work_Item__c as 'Work Item', 
    ili.Total_Line_Amount__c as 'Amount', 
    ili.CurrencyIsoCode,
    i.From_Date__c, i.To_Date__c, i.Closed_Date__c, i.CreatedDate, wi.Earliest_Service_Date__c, wi.End_Service_Date__c, i.Invoice_Processed_Date__c, wi.Work_Item_Stage__c, wi.Sample_Site__c
from salesforce.invoice_line_item__c ili
inner join salesforce.invoice__c i on ili.Invoice__c = i.Id
inner join salesforce.account a on i.Billing_Client__c = a.Id
inner join salesforce.product2 p on ili.Product__c = p.Id
inner join salesforce.standard__c st on p.Standard__c = st.Id
inner join salesforce.program__c prog on st.Program__c = prog.Id
left join salesforce.account pa on a.ParentId = pa.Id
left join salesforce.work_item__c wi on ili.Work_Item__c = wi.Id
where ili.IsDeleted = 0
and i.Status__c not in ('Cancelled')
and i.Closed_Date__c >= '2015-07-01' and i.Closed_Date__c < '2016-07-01'
and a.Client_Ownership__c = 'Australia');

(select 
	if(pa.Id is null,'Single Client', 'Corporate Client') as 'Account Type',
    a.Client_Ownership__c as 'Client Ownership',
    sc.Revenue_Ownership__c as 'Revenue Ownership',
    crm.Name as 'Client Relationship Manager',
    i.Name as 'Industry',
	ifnull(pa.Id, a.Id) as 'Parent Account Id', 
    ifnull(pa.Client_Number__c, a.Client_Number__c) as 'Parent Client Number', 
    ifnull(pa.Name, a.Name) as 'Parent Account Name', 
    a.Id as 'Account Id', 
    a.Client_Number__c as 'Client Number',
    a.Name as 'Account Name',
    scsp.Id as 'Site Cert Std Id', 
    scsp.Name as 'Site Cert Std',
    c.Sample_Service__c as 'Sample Site',
    st.Name as 'Standard',
    pr.Name as 'Program',
    pr.Business_Line__c as 'Business Line',
    'Audit' as 'Record Type',
    wi.Id as 'Id', 
    wi.Name as 'Name', 
    wi.Work_item_stage__c as 'Work Item Stage',
    #wi.Work_item_stage__c as 'Work Item Stage',
    #wi.status__c as 'Work Item Status',
    #wi.Required_Duration__c as 'Required Duration',
    av.`Calculated Value` as 'Calculated Amount', 
    av.`Calculated Currency` as 'Currency', 
    ct.ConversionRate as 'Conversion Rate',
    av.`Calculated Value`/ct.ConversionRate as 'Calculated Amount (AUD)',
    wi.work_item_date__c as 'Date'
    #av.`Total Invoiced Amount`,
    #av.`Invoiced Amount - Audit`/ct.ConversionRate as 'Invoiced Amount Audit (AUD)',
    #av.`Invoiced Amount - Travel`/ct.ConversionRate as 'Invoiced Amount Travel (AUD)',
    #av.`Invoiced Currency`,
    #if(av.`Invoiced Amount - Audit` is null, av.`Calculated Value`, av.`Invoiced Amount - Audit`)/ct.ConversionRate as 'Amount Audit (AUD)',
    #if(av.`Invoiced Amount - Audit` is null, 'Calculated', 'Invoiced') as 'Amount Calculation Type',
    #year(wi.Work_Item_Date__c)+if(month(wi.Work_Item_Date__c)<7,0,1) as 'FY'
from salesforce.site_certification_standard_program__c scsp 
inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
inner join salesforce.standard__c st on sp.Standard__c = st.Id
inner join salesforce.program__c pr on sp.Program__c = pr.Id
inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
inner join salesforce.certification__c c on sc.Primary_Certification__c = c.Id
inner join salesforce.account site on sc.Primary_client__c = site.Id
inner join salesforce.account a on site.ParentId = a.Id
left join salesforce.user crm on a.Relationship_Manager__c = crm.Id
left join salesforce.industry__c i on a.Industry_2__c = i.Id
left join salesforce.account pa on a.ParentId = pa.Id
inner join salesforce.work_item__c wi on wi.Site_Certification_Standard__c = scsp.Id
left join analytics.audit_values av on av.`Work Item Id` = wi.Id
left join salesforce.currencytype ct on av.`Calculated Currency` = ct.IsoCode
where 
a.Client_Ownership__c in ('Australia', 'Product Services')
and wi.Work_Item_Date__c between '2016-07-01' and '2017-06-30'
and wi.Status__c not in ('Cancelled')
#and wi.Work_Item_Stage__c not in ('Follow Up')
)
union all
(select 
	if(pa.Id is null,'Single Client', 'Corporate Client') as 'Account Type',
    a.Client_Ownership__c as 'Client Ownership',
    sc.Revenue_Ownership__c as 'Revenue Ownership',
    crm.Name as 'Client Relationship Manager',
    i.Name as 'Industry',
	ifnull(pa.Id, a.Id) as 'Parent Account Id', 
    ifnull(pa.Client_Number__c, a.Client_Number__c) as 'Parent Client Number', 
    ifnull(pa.Name, a.Name) as 'Parent Account Name', 
    a.Id as 'Account Id', 
    a.Client_Number__c as 'Client Number',
    a.Name as 'Account Name', 
    scsp.Id as 'Site Cert Std Id', 
    scsp.Name as 'Site Cert Std',
    c.Sample_Service__c as 'Sample Site',
    st.Name as 'Standard',
    pr.Name as 'Program',
    pr.Business_Line__c as 'Business Line',
    'Travel' as 'Record Type',
    wi.Id as 'Id', 
    wi.Name as 'Name', 
    wi.Work_item_stage__c as 'Work Item Stage',
    #wi.Work_item_stage__c as 'Work Item Stage',
    #wi.status__c as 'Work Item Status',
    #wi.Required_Duration__c as 'Required Duration',
    if(pr.Business_Line__c='Management Systems', 0.132, if(pr.Business_Line__c='Agri-Food',0.184,0.083))*av.`Calculated Value` as 'Calculated Amount', 
    av.`Calculated Currency` as 'Currency', 
    ct.ConversionRate as 'Conversion Rate',
    if(pr.Business_Line__c='Management Systems', 0.132, if(pr.Business_Line__c='Agri-Food',0.184,0.083))*av.`Calculated Value`/ct.ConversionRate as 'Calculated Amount (AUD)',
    wi.work_item_date__c as 'Date'
    #av.`Total Invoiced Amount`,
    #av.`Invoiced Amount - Audit`/ct.ConversionRate as 'Invoiced Amount Audit (AUD)',
    #av.`Invoiced Amount - Travel`/ct.ConversionRate as 'Invoiced Amount Travel (AUD)',
    #av.`Invoiced Currency`,
    #if(av.`Invoiced Amount - Audit` is null, av.`Calculated Value`, av.`Invoiced Amount - Audit`)/ct.ConversionRate as 'Amount Audit (AUD)',
    #if(av.`Invoiced Amount - Audit` is null, 'Calculated', 'Invoiced') as 'Amount Calculation Type',
    #year(wi.Work_Item_Date__c)+if(month(wi.Work_Item_Date__c)<7,0,1) as 'FY'
from salesforce.site_certification_standard_program__c scsp 
inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
inner join salesforce.standard__c st on sp.Standard__c = st.Id
inner join salesforce.program__c pr on sp.Program__c = pr.Id
inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
inner join salesforce.certification__c c on sc.Primary_Certification__c = c.Id
inner join salesforce.account site on sc.Primary_client__c = site.Id
inner join salesforce.account a on site.ParentId = a.Id
left join salesforce.user crm on a.Relationship_Manager__c = crm.Id
left join salesforce.industry__c i on a.Industry_2__c = i.Id
left join salesforce.account pa on a.ParentId = pa.Id
inner join salesforce.work_item__c wi on wi.Site_Certification_Standard__c = scsp.Id
left join analytics.audit_values av on av.`Work Item Id` = wi.Id
left join salesforce.currencytype ct on av.`Calculated Currency` = ct.IsoCode
where 
a.Client_Ownership__c in ('Australia', 'Product Services')
and wi.Work_Item_Date__c between '2016-07-01' and '2017-06-30'
and wi.Status__c not in ('Cancelled')
#and wi.Work_Item_Stage__c not in ('Follow Up')
)
union all
(select t.*, periods.`Date` from
(select if(pa.Id is null,'Single Client', 'Corporate Client') as 'Account Type',
    a.Client_Ownership__c as 'Client Ownership',
    sc.Revenue_Ownership__c as 'Revenue Ownership',
    crm.Name as 'Client Relationship Manager',
    i.Name as 'Industry',
	ifnull(pa.Id, a.Id) as 'Parent Account Id', 
    ifnull(pa.Client_Number__c, a.Client_Number__c) as 'Parent Client Number', 
    ifnull(pa.Name, a.Name) as 'Parent Account Name', 
    a.Id as 'Account Id', 
    a.Client_Number__c as 'Client Number',
    a.Name as 'Account Name', 
    #sc.Id, sc.Name, sc.Pricebook2Id__c,rfp.Id,
    scsp.Id as 'Site Cert Std Id', 
    scsp.Name as 'Site Cert Std',
    c.Sample_Service__c as 'Sample Site',
    #scsp.Status__c, scsp.De_registered_Type__c, scsp.Withdrawn_Date__c,
    st.Name as 'Standard',
    prog.Name as 'Program',
    prog.Business_Line__c as 'Business Line',
    'Registration Fee' as 'Record Type',
    sc.Registration_Fee_Product__c as 'Id', 
    #sc.Invoice_Group_Registration__c, 
    rfp.Name as 'Name', 
    'n/a' as 'Work Item Stage',
    #rfp.Category__c, #rfp.UOM__c,
    #pbe.UnitPrice as 'ListPrice', 
	if(cp.Sales_Price_Start_Date__c<= now() and cp.Sales_Price_End_Date__c>= now(), cp.FSales_Price__c, null)/
		if(igr.Recurring_Fee_Frequency__c='36 months', 36, if(igr.Recurring_Fee_Frequency__c='12 months',12,if(igr.Recurring_Fee_Frequency__c='6 months',6,if(igr.Recurring_Fee_Frequency__c='3 months',3,if(igr.Recurring_Fee_Frequency__c='monthly',1,0))))) as 'Calculated Amount Monthly', #as 'Site Cert Pricing',
    pbe.CurrencyIsoCode as 'Currency',
    ct.ConversionRate as 'Conversion Rate',
	#ifnull(if(cp.Sales_Price_Start_Date__c<= now() and cp.Sales_Price_End_Date__c>= now(), cp.FSales_Price__c, null),pbe.UnitPrice)/ct.ConversionRate as 'Calculated Amount (AUD)',
    ifnull(if(cp.Sales_Price_Start_Date__c<= now() and cp.Sales_Price_End_Date__c>= now(), cp.FSales_Price__c, null),pbe.UnitPrice)/ct.ConversionRate/
		if(igr.Recurring_Fee_Frequency__c='36 months', 36, if(igr.Recurring_Fee_Frequency__c='12 months',12,if(igr.Recurring_Fee_Frequency__c='6 months',6,if(igr.Recurring_Fee_Frequency__c='3 months',3,if(igr.Recurring_Fee_Frequency__c='monthly',1,0))))) as 'Calculated Amount Monthly (AUD)'
	#igr.Invoice_as_Lump_Sum__c, igr.Recurring_Fee_Frequency__c
from salesforce.certification__c sc
inner join salesforce.certification__c c on sc.Primary_Certification__c = c.Id
left join salesforce.invoice_group__c igr on sc.Invoice_Group_Registration__c = igr.Id
left join salesforce.product2 rfp on sc.Registration_Fee_Product__c = rfp.Id
left join salesforce.pricebookentry pbe ON pbe.Product2Id = rfp.Id and pbe.Pricebook2Id = sc.Pricebook2Id__c and pbe.IsDeleted = 0 and pbe.CurrencyIsoCode = sc.CurrencyIsoCode
left join salesforce.currencytype ct on pbe.CurrencyIsoCode = ct.IsoCode
left join salesforce.certification_pricing__c cp ON cp.Product__c = rfp.Id and cp.Certification__c = sc.Id and cp.IsDeleted = 0 and cp.Status__c = 'Active' and cp.Sales_Price_Start_Date__c<= now() and cp.Sales_Price_End_Date__c>= now()
#left join salesforce.certification_effective_price__c cep ON cp.Id = cep.Certification_Pricing__c and cep.IsDeleted = 0
inner join salesforce.site_certification_standard_program__c scsp on scsp.Site_Certification__c = sc.Id
inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
inner join salesforce.standard__c st on sp.Standard__c = st.Id
inner join salesforce.program__c prog on sp.Program__c = prog.Id
inner join salesforce.account site on sc.Primary_client__c = site.Id
inner join salesforce.account a on site.ParentId = a.Id
left join salesforce.user crm on a.Relationship_Manager__c = crm.Id
left join salesforce.industry__c i on a.Industry_2__c = i.Id
left join salesforce.account pa on a.ParentId = pa.Id
where 
a.Client_Ownership__c in ('Australia', 'Product Services')
and scsp.Status__c in ('Registered', 'Customised')
group by scsp.Id) t, 
(select p.* from (select '2016-07-01' as 'Date' union select '2016-08-01' union select '2016-09-01' union select '2016-10-01' union select '2016-11-01' union select '2016-12-01' union select '2017-01-01' union select '2017-02-01' union select '2017-03-01' union select '2017-04-01' union select '2017-05-01' union select '2017-06-01') p) periods);