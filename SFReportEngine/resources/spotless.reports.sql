create or replace view Spotless_Site_Cert_Stds as
select 
	scsp.Id, 
	scsp.Certification_Standard__c,
	scsp.Site_Certification__c,
	scsp.Standard_Program__c,
	scsp.Name as 'Site Certification Standard'
from salesforce.site_certification_standard_program__c scsp
left join salesforce.standard_program__c sp on sp.Id = scsp.Standard_Program__c
left join salesforce.standard__c s on sp.Standard__c = s.Id
left join salesforce.site_certification_standard_family__c scsf on scsf.Site_Certification_Standard__c = scsp.Id
left join salesforce.standard_program__c fsp on scsf.Standard_Program__c = fsp.Id
left join salesforce.standard__c fs on fsp.Standard__c = fs.Id
where 
	(sp.Standard__c in (select s.Id from standard__c s where s.name like '%Spotless%') or 
	fsp.Standard__c in (select s.Id from standard__c s where s.name like '%Spotless%'))
and (scsf.IsDeleted=0 or scsf.IsDeleted is null)
and scsp.Status__c not in ('De-registered','Concluded')
and scsp.IsDeleted=0
group by scsp.Id;

create or replace view Spotless_Client_List as
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
	group_concat(distinct fs.Name) as 'Family Standard' 
from salesforce.Spotless_Site_Cert_Stds t
	inner join salesforce.Certification_Standard_Program__c csp on t.Certification_Standard__c = csp.Id
	inner join salesforce.certification__c sc on t.Site_Certification__c = sc.Id
	inner join salesforce.account site on sc.Primary_client__c = site.id
	left join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id
	left join salesforce.state_code_setup__c scs on site.Business_State__c = scs.Id
	inner join salesforce.account client on site.ParentId = client.id
	left join salesforce.account parent on client.ParentId = parent.id
	left join salesforce.standard_program__c sp on sp.Id = t.Standard_Program__c
	left join salesforce.standard__c s on sp.Standard__c = s.Id
	left join salesforce.site_certification_standard_family__c scsf on scsf.Site_Certification_Standard__c = t.Id
	left join salesforce.standard_program__c fsp on scsf.Standard_Program__c = fsp.Id
	left join salesforce.standard__c fs on fsp.Standard__c = fs.Id
where 
	site.IsDeleted=0
	and sc.IsDeleted=0
	and site.Status__c='Active'
	and sc.Status__c = 'Active'
group by t.Id;

create or replace view Spotless_Audits_Next_Six_Months as
select 
	ccl.`Client Name` as 'Supplier',
	ccl.`Site City` as 'Site',
	ccl.`Site State` as 'State',
	concat (ccl.`Primary Standard`,ifnull(concat(',',ccl.`Family Standard`),'')) as 'Standards',	
	scl.Frequency__c as 'Frequency',
	#'' as 'Auditor Rotation Checked',
	wi.Id as 'Work Item Id', 
	wi.Name as 'Work Item Name', 
	wi.Status__c as 'Audit Status',
	wi.Work_Item_Stage__c as 'Work Item Type',
	wi.Service_Target_Month__c as 'Audit Due Date (Month)',
	wi.Earliest_Service_Date__c as 'Audit From Date',
	wi.End_Service_Date__c as 'Audit End Date',
    group_concat(distinct if(wir.IsDeleted=0 and r.IsDeleted=0, r.Name, null)) as 'Auditors'
from salesforce.work_item__c wi 
	inner join salesforce.Spotless_Client_List ccl on ccl.`Site Certification Standard Id` = wi.Site_Certification_Standard__c
	left join salesforce.Site_Certification_Lifecycle__c scl on scl.Work_Item__c = wi.Id
	left join salesforce.work_item_resource__c wir on wir.Work_Item__c = wi.Id
	left join salesforce.resource__c r on wir.Resource__c = r.Id
where 
	wi.Status__c not in ('Cancelled')
	and date_format(wi.Work_Item_Date__c, '%Y %m') >= date_format(date_add(now(), interval -3 MONTH), '%Y %m')
	and date_format(wi.Work_Item_Date__c, '%Y %m') <= date_format(date_add(now(), interval 6 MONTH), '%Y %m')
	and wi.IsDeleted=0
group by wi.Id;

(select * from salesforce.Spotless_Audits_Next_Six_Months)