# indexes
create index site_certification_standard_family on site_certification_standard_family__c (Site_Certification_Standard__c, Standard_Program__c);
create index work_item_resource_wi_index on work_item_resource__c (Work_Item__c);

# Woolworths Standards
create or replace view Woolworths_Standards as
select s.Name, s.Id from salesforce.standard__c s
where 
	s.name like 'WQA%' 
    or s.name like '%Woolworths%' 
    or s.Name like 'Endeavour Drinks Group Quality Standard%' ;

select * from Woolworths_Standards;

# Woolworths Products
select p.Id, p.Name from Product2 p 
where p.Standard__c in ('a36900000004F2EAAU','a36900000004FRPAA2','a36900000004FRQAA2','a36900000004FRRAA2','a36d00000004ZXrAAM','a36d00000004ZXwAAM','a36d0000000Ci6QAAS','a36d0000000Ci6VAAS');

#List of Sites (global)
#explain
create or replace view Woolworths_Client_List as
select 
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
	scsp.Id as 'Site Certification Standard Id', 
	scsp.Name as 'Site Certification Standard', 
    scsp.External_Site_Code__c as 'External Site Ref.',
	csp.Name as 'Certification Standard',
	csp.External_provided_certificate__c as 'Certification Standard External Ref',
	s.Name as 'Primary Standard', 
	group_concat(distinct if(scsf.IsDeleted or fsp.isDeleted or fs.IsDeleted, null,fs.Name)) as 'Family Standard',
    group_concat(distinct if(scspc.IsDeleted or cod.isDeleted, null,cod.Name)) as 'Codes'
from site_certification_standard_program__c scsp
inner join Certification_Standard_Program__c csp on scsp.Certification_Standard__c = csp.Id
inner join certification__c sc on scsp.Site_Certification__c = sc.Id
inner join account site on sc.Primary_client__c = site.id
left join country_code_setup__c ccs on site.Business_Country2__c = ccs.Id
left join state_code_setup__c scs on site.Business_State__c = scs.Id
inner join account client on site.ParentId = client.id
left join account parent on client.ParentId = parent.id
left join standard_program__c sp on sp.Id = scsp.Standard_Program__c
left join standard__c s on sp.Standard__c = s.Id
left join site_certification_standard_family__c scsf on scsf.Site_Certification_Standard__c = scsp.Id
left join standard_program__c fsp on scsf.Standard_Program__c = fsp.Id
left join standard__c fs on fsp.Standard__c = fs.Id
left join site_cert_standard_program_code__c scspc on scspc.Site_Certification_Standard_Program__c = scsp.Id
left join code__c cod on scspc.Code__c = cod.Id
left join Woolworths_Standards ws1 on sp.Standard__c = ws1.Id
left join Woolworths_Standards ws2 on fsp.Standard__c = ws2.Id
where 
#(sp.Standard__c in ('a36d00000004ZXrAAM','a36d0000000CrA3AAK','a36d0000000Cr9yAAC','a36900000004FRQAA2','a36900000004FRRAA2','a36900000004FRPAA2','a36d00000004ZXwAAM','a36d0000000CtD2AAK','a36d0000000Ci6VAAS','a36d0000000Ci6QAAS','a36900000004F2EAAU')
#or fsp.Standard__c in ('a36d00000004ZXrAAM','a36d0000000CrA3AAK','a36d0000000Cr9yAAC','a36900000004FRQAA2','a36900000004FRRAA2','a36900000004FRPAA2','a36d00000004ZXwAAM','a36d0000000CtD2AAK','a36d0000000Ci6VAAS','a36d0000000Ci6QAAS','a36900000004F2EAAU'))
(ws1.Id is not null or ws2.Id is not null)
and site.IsDeleted=0
and sc.IsDeleted=0
and scsp.IsDeleted=0
and site.Status__c='Active'
and sc.Status__c = 'Active'
and scsp.Status__c not in ('De-registered','Concluded')
and (scsf.IsDeleted=0 or scsf.IsDeleted is null)
group by scsp.Id;

(select * from Woolworths_Client_List);

select * from (
select
	wcl.`Ownership`,
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
	wcl.`Primary Standard`,
	wcl.`Family Standard`,
    wcl.`External Site Ref.`,
    o.Name as 'Auditor',
    scl.Frequency__c as 'Frequncy',
	wi.Revenue_Ownership__c as 'Revenue Ownership',
	wi.Work_Package_Type__c as 'Work Package Type',
	wi.Id as 'Work Item Id', 
	wi.Name as 'Work Item Name', 
    wi.Work_Item_Stage__c as 'Stage',
	wi.Work_Item_Date__c as 'Work Item Date', 
	wi.Status__c as 'Work Item Status'
from work_item__c wi 
inner join Woolworths_Client_List wcl on wcl.`Site Certification Standard Id` = wi.Site_Certification_Standard__c
left join resource__c o on wi.Work_Item_Owner__c = o.Id
left join Site_Certification_Lifecycle__c scl on scl.Work_Item__c = wi.Id
where wi.Status__c not in ('Completed', 'Cancelled')
and wi.Work_Item_Stage__c not in ('Follow Up')
and wi.IsDeleted=0
order by wcl.`Site Certification Standard Id`, wi.Work_Item_Date__c asc) t 
group by t.`Site Certification Standard`;


#List of wi not in (Open, Cancelled) next 6 months
create or replace view Woolworths_Scheduled_Audits_Next_Six_Months as
select 
	wcl.`Site Name`,
	wcl.`Site Certification`,
	wcl.`Site Certification Standard`,
	wcl.`Primary Standard`,
	wcl.`Family Standard`,
	wi.Revenue_Ownership__c as 'Revenue Ownership',
	wi.Work_Package_Type__c as 'Work Package Type',
	wi.Id as 'Work Item Id', 
	wi.Name as 'Work Item Name', 
	wi.Work_Item_Date__c as 'Work Item Date', 
	wi.Status__c as 'Work Item Status'
from work_item__c wi 
inner join Woolworths_Client_List wcl on wcl.`Site Certification Standard Id` = wi.Site_Certification_Standard__c
where wi.Status__c not in ('Open', 'Cancelled')
and date_format(wi.Work_Item_Date__c, '%Y %m') >= date_format(now(), '%Y %m')
and date_format(wi.Work_Item_Date__c, '%Y %m') <= date_format(date_add(now(), interval 6 MONTH), '%Y %m')
and wi.IsDeleted=0;

#List of all wi next 6 months
create or replace view Woolworths_Audits_Next_Six_Months as
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
	wi.Revenue_Ownership__c as 'Revenue Ownership',
	wi.Work_Package_Type__c as 'Work Package Type',
	wi.Id as 'Work Item Id', 
	wi.Name as 'Work Item Name', 
	wi.Work_Item_Date__c as 'Work Item Date', 
	wi.End_Service_Date__c as 'Work Item End Date', 
	wi.Status__c as 'Work Item Status',
	wi.Work_Item_Stage__c as 'Work Item Type',
	group_concat(distinct if(wir.IsDeleted,null,r.Name)) as 'Auditors'
from work_item__c wi 
inner join Woolworths_Client_List wcl on wcl.`Site Certification Standard Id` = wi.Site_Certification_Standard__c
left join work_item_resource__c wir on wir.Work_Item__c = wi.Id
left join resource__c r on r.Id = wir.Resource__c
where wi.Status__c not in ('Cancelled')
and date_format(wi.Work_Item_Date__c, '%Y %m') >= date_format(date_add(now(), interval -1 MONTH), '%Y %m')
and date_format(wi.Work_Item_Date__c, '%Y %m') <= date_format(date_add(now(), interval 6 MONTH), '%Y %m')
and wi.IsDeleted=0
group by wi.id;

# List of all wi in the future
create or replace view Woolworths_Audits as
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
from work_item__c wi 
inner join Woolworths_Client_List wcl on wcl.`Site Certification Standard Id` = wi.Site_Certification_Standard__c
left join work_item_resource__c wir on wir.Work_Item__c = wi.Id
left join resource__c r on r.Id = wir.Resource__c
where wi.Status__c not in ('Cancelled')
and date_format(wi.Work_Item_Date__c, '%Y %m') >= date_format(date_add(now(), interval -1 MONTH), '%Y %m')
#and date_format(wi.Work_Item_Date__c, '%Y %m') <= date_format(date_add(now(), interval 6 MONTH), '%Y %m')
and wi.IsDeleted=0
group by wi.id;

select * from Woolworths_Audits;
#List of wi open next 6 months
create or replace view Woolworths_Open_Audits_Next_Six_Months as
select 
	wcl.`Site Name`,
	wcl.`Site Certification`,
	wcl.`Site Certification Standard`,
	wcl.`Primary Standard`,
	wcl.`Family Standard`,
	wi.Revenue_Ownership__c as 'Revenue Ownership',
	wi.Work_Package_Type__c as 'Work Package Type',
	wi.Id as 'Work Item Id', 
	wi.Name as 'Work Item Name', 
	wi.Work_Item_Date__c as 'Work Item Date', 
	wi.Status__c as 'Work Item Status'
from work_item__c wi 
inner join Woolworths_Client_List wcl on wcl.`Site Certification Standard Id` = wi.Site_Certification_Standard__c
where wi.Status__c in ('Open')
and date_format(wi.Work_Item_Date__c, '%Y %m') >= date_format(date_add(now(), interval -1 MONTH), '%Y %m')
and date_format(wi.Work_Item_Date__c, '%Y %m') <= date_format(date_add(now(), interval 6 MONTH), '%Y %m')
and wi.IsDeleted=0;

#List of Submitted wi with no ARG
create or replace view Woolworths_Submitted_Audits_With_No_ARG as
select 
	wcl.`Site Name`,
	wcl.`Site Certification`,
	wcl.`Site Certification Standard`,
	wcl.`Primary Standard`,
	wcl.`Family Standard`,
	wi.Revenue_Ownership__c as 'Revenue Ownership',
	wi.Work_Package_Type__c as 'Work Package Type',
	wi.Id as 'Work Item Id', 
	wi.Name as 'Work Item Name', 
	wi.Work_Item_Date__c as 'Work Item Date', 
	wi.Status__c as 'Work Item Status',
	group_concat(distinct r.Name) as 'Auditors'
from work_item__c wi 
inner join work_item_resource__c wir on wir.Work_Item__c = wi.Id
inner join resource__c r on wir.Resource__c = r.id
inner join Woolworths_Client_List wcl on wcl.`Site Certification Standard Id` = wi.Site_Certification_Standard__c
left join ARG_Work_Item__c argwi on wi.id = argwi.RWork_Item__c
where wi.Status__c = 'Submitted'
and wi.IsDeleted=0
and argwi.id is null
group by wi.id;

#List ARG with status
create or replace view Woolworths_ARG_List_sub as
select 
	wcl.`Site Name`,
	wcl.`Site Certification`,
	wcl.`Site Certification Standard`,
	wcl.`Certification Standard External Ref`,
	wcl.`Primary Standard`,
	wcl.`Family Standard`,
	arg.Id as 'ARG Id',
	arg.Name as 'ARG Name',
	group_concat(distinct r.Name) as 'Auditors Names',
	group_concat(distinct wi.Revenue_Ownership__c) as 'Revenue Ownerships',
    group_concat(distinct wi.Work_Item_Stage__c) as 'WI Type',
    group_concat(distinct date_format(wi.Service_target_date__c, '%b %Y')) as 'Target Months',
    wcl.`Codes`,
	arg.Audit_Report_Status__c as 'ARG Status',
	arg.Start_Date__c as 'ARG Start Date',
	arg.End_Date__c as 'ARG End Date',
	arg.First_Submitted__c as 'ARG First Submitted',
	arg.TR_Approved__c as 'ARG TA Approved',
	arg.CA_Approved__c as 'ARG CA Approved',
	arg.Admin_Closed__c as 'ARG Admin Closed'
from audit_report_group__c arg
inner join ARG_Work_Item__c argwi on argwi.RAudit_Report_Group__c = arg.id
inner join work_item__c wi on wi.id = argwi.RWork_Item__c
inner join work_item_resource__c wir on wir.Work_Item__c = wi.id
inner join resource__c r on wir.Resource__c = r.id
inner join Woolworths_Client_List wcl on wcl.`Site Certification Standard Id` = wi.Site_Certification_Standard__c
and wi.IsDeleted=0
and arg.isDeleted=0 
group by arg.Id, wcl.`Site Certification Standard`;

create or replace view Woolworths_ARG_List as
select 
	arg.*, 
	sum(if (ah.Status__c='Rejected',1,0)) as 'Rejections',
	max(if(ah.Status__c='Rejected',ah.Timestamp__c,null)) as 'Last Rejected',
	group_concat(if(ah.Status__c='Rejected',approver.Name,null)) as 'Rejected By'
from Woolworths_ARG_List_sub arg
left join approval_history__c ah on arg.`ARG Id` = ah.RAudit_Report_Group__c
left join Resource__c approver on ah.RApprover__c = approver.Id
group by arg.`ARG Id`;

(select * from Woolworths_ARG_List);

#Revenues from WQA Standard
create or replace view Woolworths_WQA_Revenues as
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
inner join Woolworths_Standards ws on ws.Id  = p.Standard__c
where 
#p.Standard__c in ('a36d00000004ZXrAAM','a36d0000000CrA3AAK','a36d0000000Cr9yAAC','a36900000004FRQAA2','a36900000004FRRAA2','a36900000004FRPAA2','a36d00000004ZXwAAM','a36d0000000CtD2AAK','a36d0000000Ci6VAAS','a36d0000000Ci6QAAS','a36900000004F2EAAU') and 
i.Billing_Client__c in (select wcl.`Client Id` from Woolworths_Client_List wcl)
and i.Status__c not in ('Cancelled')
and i.IsDeleted=0
and ili.IsDeleted=0
and p.IsDeleted=0;

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
ifnull(wi.Primary_Standard__c ,s.Name) as 'Standard',
ili.Product_Category__c as 'Product Category', 
if (ifnull(wi.Primary_Standard__c ,s.Name) like 'Endeavour Drinks Group Quality Standard%' 
	or ifnull(wi.Primary_Standard__c ,s.Name) like '%Woolworth%' 
    or ifnull(wi.Primary_Standard__c ,s.Name) like '%WQA%', 1,0) as 'WQA Revenue'
from invoice__c i
inner join salesforce.Invoice_Line_Item__c ili on ili.invoice__c = i.Id
left join salesforce.work_item__c wi on ili.Work_Item__c = wi.Id
inner join salesforce.product2 p on ili.Product__c = p.Id
left join salesforce.standard__c s on p.Standard__c = s.Id
inner join salesforce.account c on c.Id = i.Billing_Client__c
where 
i.Billing_Client__c in (select wcl.`Client Id` from Woolworths_Client_List wcl)
and i.Status__c not in ('Cancelled')
and i.IsDeleted=0
and ili.IsDeleted=0
and p.IsDeleted=0;

select p.Id, p.NAme,s.NAme from salesforce.product2 p
inner join salesforce.standard__c s on p.Standard__c = s.Id
where s.NAme like '%Woolworths%' ;

select wi.Id, ili.Id, ili.Name, ili.Invoice__c ,p.Name, s.Name, i.Status__c
from salesforce.invoice_line_item__c ili
inner join salesforce.invoice__c i on ili.Invoice__c = i.Id
inner join salesforce.product2 p on ili.Product__c = p.Id
inner join salesforce.standard__c s on p.Standard__c = s.Id
inner join salesforce.work_item__c wi on ili.Work_Item__c = wi.Id
where wi.Primary_Standard__c like 'Endeavour Drinks Group Quality%'