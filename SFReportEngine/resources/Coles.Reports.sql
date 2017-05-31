use salesforce;
use salesforce;
# Coles Standards
select '' as 'Dummy', group_concat(s.Id) from standard__c s
where s.name like '%Coles%'
group by `Dummy`;

select s.Id, s.Name from standard__c s
where s.name like '%Coles%';

# Coles Products
select p.Id, p.Name from Product2 p 
where p.Standard__c in ('a36900000004F23AAE','a36900000004FRFAA2');


#List of Sites (global)
#explain
create or replace view Coles_Client_List_Sub as
select 
	scsp.Id, 
	scsp.Certification_Standard__c,
	scsp.Site_Certification__c,
	scsp.Standard_Program__c,
	scsp.Name as 'Site Certification Standard'
from site_certification_standard_program__c scsp
left join standard_program__c sp on sp.Id = scsp.Standard_Program__c
left join standard__c s on sp.Standard__c = s.Id
left join site_certification_standard_family__c scsf on scsf.Site_Certification_Standard__c = scsp.Id
left join standard_program__c fsp on scsf.Standard_Program__c = fsp.Id
left join standard__c fs on fsp.Standard__c = fs.Id
where (sp.Standard__c in ('a36900000004F23AAE','a36900000004FRFAA2') or fsp.Standard__c in ('a36900000004F23AAE','a36900000004FRFAA2'))
and (scsf.IsDeleted=0 or scsf.IsDeleted is null)
and scsp.Status__c not in ('De-registered','Concluded')
and scsp.IsDeleted=0
group by scsp.Id;

create or replace view Coles_Client_List as
select 
	parent.Id as 'Parent Id',
	parent.Name as 'Parent Client',
	client.id as 'Client Id',
	client.Name as 'Client Name',
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
	t.Id as 'Site Certification Standard Id',
	t.`Site Certification Standard`,
	csp.Name as 'Certification Standard',
	csp.External_provided_certificate__c as 'Certification Standard External Ref',
	s.Name as 'Primary Standard', 
	group_concat(distinct if (fs.Name like '%Aldi%' or fs.Name like '%Costco%' or fs.Name like '%Woolworths%'or fs.Name like '%WQA%'or fs.Name like '%McDonalds%'or fs.Name like '%Food Safety Victoria%',null,fs.Name)) as 'Family Standard' 
from Coles_Client_List_Sub t
inner join Certification_Standard_Program__c csp on t.Certification_Standard__c = csp.Id
inner join certification__c sc on t.Site_Certification__c = sc.Id
inner join account site on sc.Primary_client__c = site.id
left join country_code_setup__c ccs on site.Business_Country2__c = ccs.Id
left join state_code_setup__c scs on site.Business_State__c = scs.Id
inner join account client on site.ParentId = client.id
left join account parent on client.ParentId = parent.id
left join standard_program__c sp on sp.Id = t.Standard_Program__c
left join standard__c s on sp.Standard__c = s.Id
left join site_certification_standard_family__c scsf on scsf.Site_Certification_Standard__c = t.Id
left join standard_program__c fsp on scsf.Standard_Program__c = fsp.Id
left join standard__c fs on fsp.Standard__c = fs.Id
where 
site.IsDeleted=0
and sc.IsDeleted=0
and site.Status__c='Active'
and sc.Status__c = 'Active'
group by t.Id;

use salesforce;

create index Site_cert_Lifecycle_Work_Item_Index on Site_Certification_Lifecycle__c(Work_Item__c);
#List of wi 
create or replace view Coles_Audits_Next_Six_Months as
#explain
select 
	#ccl.`Site Certification`,
	#ccl.`Site Certification Standard`,
	#wi.Revenue_Ownership__c as 'Revenue Ownership',
	#wi.Work_Package_Type__c as 'Work Package Type',
	ccl.`Client Name` as 'Supplier',
	ccl.`Site City` as 'Site',
	ccl.`Site State` as 'State',
	concat (ccl.`Primary Standard`,',',ccl.`Family Standard`) as 'Standard & Version audited to',	
	scl.Frequency__c as 'Frequency',
	'' as 'Auditor Rotation Checked',
	wi.Id as 'Work Item Id', 
	wi.Name as 'Work Item Name', 
	wi.Status__c as 'Audit Status',
	wi.Work_Item_Stage__c as 'Work Item Type',
	wi.Service_Target_Month__c as 'Audit Due Date (Month)',
	wi.Earliest_Service_Date__c as 'Audit From Date',
	wi.End_Service_Date__c as 'Audit End Date',
    group_concat(distinct if(wir.IsDeleted=0 and r.IsDeleted=0, r.Name, null)) as 'Auditors'
from work_item__c wi 
inner join Coles_Client_List ccl on ccl.`Site Certification Standard Id` = wi.Site_Certification_Standard__c
left join Site_Certification_Lifecycle__c scl on scl.Work_Item__c = wi.Id
left join work_item_resource__c wir on wir.Work_Item__c = wi.Id
left join resource__c r on wir.Resource__c = r.Id
where wi.Status__c not in ('Cancelled')
and date_format(wi.Work_Item_Date__c, '%Y %m') >= date_format(date_add(now(), interval -3 MONTH), '%Y %m')
and date_format(wi.Work_Item_Date__c, '%Y %m') <= date_format(date_add(now(), interval 6 MONTH), '%Y %m')
and wi.IsDeleted=0
group by wi.Id;

select * from Coles_Audits_Next_Six_Months;

#Revenues from clients with at least one site with Coles Standard
create or replace view salesforce.Coles_Clients_Revenues as
select 
i.Billing_Client__c as 'Client Id', 
c.Name as 'Client Name',
i.Id as 'Invoice Id',
i.Name as 'Invoice Name',
i.Status__c as 'Invoice Status', 
i.Invoice_Processed_Date__c as 'Invoice Processed Date', 
if(month(i.Invoice_Processed_Date__c)<7,year(i.Invoice_Processed_Date__c), year(i.Invoice_Processed_Date__c)+1) as 'Invoice Processed FY',
date_format(i.Invoice_Processed_Date__c, '%Y %m') as 'Invoice Processed Period', 
ili.Revenue_Ownership__c as 'Revenue Ownership', 
ili.Total_Line_Amount__c as 'Total Amount Ex Tax', 
ili.CurrencyIsoCode, 
p.Name as 'Product Name',
ili.Product_Category__c as 'Product Category',
p.Pathway__c as 'Pathway',
p.Program__c as 'Program',
s.Name as 'Standard'
from salesforce.invoice__c i
inner join salesforce.Invoice_Line_Item__c ili on ili.invoice__c = i.Id
inner join salesforce.product2 p on ili.Product__c = p.Id
inner join salesforce.standard__c s on p.Standard__c = s.Id
inner join salesforce.account c on c.Id = i.Billing_Client__c
where 
i.Billing_Client__c in (select ccl.`Client Id` from salesforce.Coles_Client_List ccl)
and i.Status__c not in ('Cancelled')
and i.IsDeleted=0
and ili.IsDeleted=0
and p.IsDeleted=0;

(select * from salesforce.Coles_Clients_Revenues)