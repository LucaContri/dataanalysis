# Woolworths Standards
create or replace view TGI_CDG_Standards as
select s.Name, s.Id, s.Parent_Standard__c from salesforce.standard__c s
where s.name like '%TGI%' or s.name like '%CDG%';

select * from TGI_CDG_Standards;

#List of Sites (global)
#explain
create or replace view TGI_CDG_Client_List as
select 
	parent.Id as 'Parent Id',
	parent.Name as 'Parent Client',
	client.id as 'Client Id',
	client.Name as 'Client Name',
    client.Client_Ownership__c as ' ClientOwnership',
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
	scsp.Id as 'Site Certification Standard Id', 
	scsp.Name as 'Site Certification Standard', 
    sc.Revenue_Ownership__c as 'Revenue Ownership',
    scsp.External_Site_Code__c as 'External Site Ref.',
	csp.Name as 'Certification Standard',
	csp.External_provided_certificate__c as 'Certification Standard External Ref',
	s.Name as 'Primary Standard', 
	group_concat(distinct if(scsf.IsDeleted or fsp.isDeleted or fs.IsDeleted, null,fs.Name)) as 'Family Standard',
    group_concat(distinct if(scspc.IsDeleted or cod.isDeleted, null,cod.Name)) as 'Codes'
from salesforce.site_certification_standard_program__c scsp
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
left join analytics.TGI_CDG_Standards ws1 on sp.Standard__c = ws1.Id
left join analytics.TGI_CDG_Standards ws2 on fsp.Standard__c = ws2.Id
where 
(ws1.Id is not null or ws2.Id is not null)
and site.IsDeleted=0
and sc.IsDeleted=0
and scsp.IsDeleted=0
and site.Status__c='Active'
and sc.Status__c = 'Active'
and scsp.Status__c not in ('De-registered','Concluded')
and (scsf.IsDeleted=0 or scsf.IsDeleted is null)
group by scsp.Id;

select * from TGI_CDG_Client_List;

# List of all tgi, cdg audits
create or replace view TGI_CDG_Audits as
select 
	wcl.`Client Name`,
	wcl.`Site Name`,
	wcl.`Site Address 1`,
	wcl.`Site Address 2`,
	wcl.`Site Address 3`,
	wcl.`Site City`,
	wcl.`Site State`,
	wcl.`Site PostCode`,
	wcl.`Site Country`,
	wcl.`Site Certification`,
	wcl.`Site Certification Standard`,
	wcl.`Certification Standard`,
	wcl.`Certification Standard External Ref`,
    wcl.`External Site Ref.`,
	wcl.`Primary Standard`,
	wcl.`Family Standard`,
    wcl.`Codes`,
	wi.Revenue_Ownership__c as 'Revenue Ownership',
	wi.Work_Package_Type__c as 'Work Package Type',
	wi.Id as 'Work Item Id', 
	wi.Name as 'Work Item Name', 
    date_format(wi.Service_target_date__c, '%b %Y') as 'Target Month',
	wi.Work_Item_Date__c as 'Work Item Date', 
	wi.End_Service_Date__c as 'Work Item End Date', 
	wi.Status__c as 'Work Item Status',
	wi.Work_Item_Stage__c as 'Work Item Type',
	group_concat(distinct if(wir.IsDeleted,null,r.Name)) as 'Auditors'
from salesforce.work_item__c wi 
inner join analytics.TGI_CDG_Client_List wcl on wcl.`Site Certification Standard Id` = wi.Site_Certification_Standard__c
left join salesforce.work_item_resource__c wir on wir.Work_Item__c = wi.Id
left join salesforce.resource__c r on r.Id = wir.Resource__c
where wi.Status__c not in ('Cancelled')
and wi.IsDeleted=0
group by wi.id;

select * from TGI_CDG_Audits;

#Revenues from TGI CDG Standard
create or replace view TGI_CDG_Revenues as
select 
i.Billing_Client__c as 'Client Id', 
c.Name as 'Client Name',
i.Id as 'Invoice Id', 
i.Name as 'Invoice Name',
i.Status__c as 'Invoice Status', 
i.Invoice_Processed_Date__c as 'Invoice Processed Date', 
date_format(i.Invoice_Processed_Date__c, '%Y %m') as 'Invoice Processed Period', 
ili.Revenue_Ownership__c as 'Revenue Ownership', 
ili.Total_Line_Amount__c as 'Total Amount Ex Tax', 
ili.CurrencyIsoCode, 
p.Name as 'Product Name',
ili.Product_Category__c as 'Product Category', 
if (p.Name like '%TGI%', 1,0) as 'TGI Revenue',
if (p.Name like '%CDG%', 1,0) as 'CDG Revenue'
from salesforce.invoice__c i
inner join salesforce.Invoice_Line_Item__c ili on ili.invoice__c = i.Id
inner join salesforce.product2 p on ili.Product__c = p.Id
inner join salesforce.account c on c.Id = i.Billing_Client__c
#inner join analytics.TGI_CDG_Standards ws on ws.Id  = p.Standard__c
where 
i.Billing_Client__c in (select wcl.`Client Id` from analytics.TGI_CDG_Client_List wcl)
and i.Status__c not in ('Cancelled')
and i.IsDeleted=0
and ili.IsDeleted=0
and p.IsDeleted=0;

select * from TGI_CDG_Revenues;
select count(*) from Woolworths_WQA_Revenues;
#Revenues from clients with at least one site with WQA
create or replace view Woolworths_WQA_Clients_Revenues as
select 
i.Billing_Client__c as 'Client Id', 
c.Name as 'Client Name',
i.Id as 'Invoice Id',
i.Name as 'Invoice Name',
i.Status__c as 'Invoice Status', 
i.Invoice_Processed_Date__c as 'Invoice Processed Date', 
date_format(i.Invoice_Processed_Date__c, '%Y %m') as 'Invoice Processed Period', 
ili.Revenue_Ownership__c as 'Revenue Ownership', 
ili.Total_Line_Amount__c as 'Total Amount Ex Tax', 
ili.CurrencyIsoCode, 
p.Name as 'Product Name',
ili.Product_Category__c as 'Product Category', 
if (p.Name like 'WQA%', 1,0) as 'WQA Revenue'
from invoice__c i
inner join Invoice_Line_Item__c ili on ili.invoice__c = i.Id
inner join product2 p on ili.Product__c = p.Id
inner join account c on c.Id = i.Billing_Client__c
where 
i.Billing_Client__c in (select wcl.`Client Id` from Woolworths_Client_List wcl)
and i.Status__c not in ('Cancelled')
and i.IsDeleted=0
and ili.IsDeleted=0
and p.IsDeleted=0;
