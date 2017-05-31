use analytics;

drop temporary table client_size_data;
create temporary table client_size_data as
(select site2.ParentId as 'Client_Id', count(distinct site2.Id) as 'Active Sites', count(distinct scsp2.Id) as 'Registered Site Cert', count(distinct scsp2.Certification_Standard__c) as 'Registered Certifications'
		from salesforce.site_certification_standard_program__c scsp2
		inner join salesforce.certification__c sc2 on scsp2.Site_Certification__c = sc2.Id
		inner join salesforce.account site2 on sc2.Primary_client__c = site2.Id
		where sc2.IsDeleted = 0 
        and scsp2.IsDeleted = 0
        and scsp2.De_registered_Type__c is null
        and scsp2.Status__c in ('Registered', 'Customised', 'Applicant')
        group by site2.ParentId);
create index client_size_data_index on client_size_data(Client_Id);

select * from client_contacts where Id='00190000008nWbbAAE';
drop temporary table client_contacts ;
create temporary table client_contacts as
select t.* from (
select a.Id, a.Name, 
c.Status__c, 'Client' as 'Type', c.Id as 'Contact Id', c.Name as 'Contact Name', c.Title, c.Email, c.Salutation, c.Phone, c.Site_Business_Address_1__c, c.Site_Business_Address_2__c, c.Site_Business_Address_3__c, c.Site_Business_City__c, c.Site_Business_Zip_Postal_Code__c, c.Site_Business_Country__c, c.Site_Business_State__c
from salesforce.account a
inner join salesforce.contact c on c.AccountId = a.Id
where 
a.Record_Type_Name__c = 'Client'
#and a.Id='00190000008nWZ9AAM'
union
select a.ParentId, a.Name, 
c.Status__c, 'Site' as 'Type', c.Id as 'Contact Id', c.Name as 'Contact Name', c.Title, c.Email, c.Salutation, c.Phone, c.Site_Business_Address_1__c, c.Site_Business_Address_2__c, c.Site_Business_Address_3__c, c.Site_Business_City__c, c.Site_Business_Zip_Postal_Code__c, c.Site_Business_Country__c, c.Site_Business_State__c
from salesforce.account a
inner join salesforce.contact c on c.AccountId = a.Id
where 
a.Record_Type_Name__c = 'Client Site'
#and a.ParentId='00190000008nWZ9AAM'
union
select a.Id, a.Name, 
cr_account.Status__c, cr_account.Type__c, c.Id as 'Contact Id', c.Name as 'Contact Name', c.Title, c.Email, c.Salutation, c.Phone, c.Site_Business_Address_1__c, c.Site_Business_Address_2__c, c.Site_Business_Address_3__c, c.Site_Business_City__c, c.Site_Business_Zip_Postal_Code__c, c.Site_Business_Country__c, c.Site_Business_State__c
from salesforce.account a
inner join salesforce.Contact_Role__c cr_account on cr_account.Account__c = a.Id
inner join salesforce.contact c on cr_account.Contact__c = c.Id
where 
a.Record_Type_Name__c = 'Client'
#and a.Id='00190000008nWZ9AAM'
union
select a.ParentId, a.Name, 
cr_account.Status__c, cr_account.Type__c, c.Id as 'Contact Id', c.Name as 'Contact Name', c.Title, c.Email, c.Salutation, c.Phone, c.Site_Business_Address_1__c, c.Site_Business_Address_2__c, c.Site_Business_Address_3__c, c.Site_Business_City__c, c.Site_Business_Zip_Postal_Code__c, c.Site_Business_Country__c, c.Site_Business_State__c
from salesforce.account a
inner join salesforce.Contact_Role__c cr_account on cr_account.Account__c = a.Id
inner join salesforce.contact c on cr_account.Contact__c = c.Id
where 
a.Record_Type_Name__c = 'Client Site'
#and a.ParentId='00190000008nWZ9AAM'
union
select a.Id, a.Name, 
cr_cert.Status__c, cr_cert.Type__c, c.Id as 'Contact Id', c.Name as 'Contact Name', c.Title, c.Email, c.Salutation, c.Phone, c.Site_Business_Address_1__c, c.Site_Business_Address_2__c, c.Site_Business_Address_3__c, c.Site_Business_City__c, c.Site_Business_Zip_Postal_Code__c, c.Site_Business_Country__c, c.Site_Business_State__c
from salesforce.account a
inner join certification__c cert on cert.Primary_client__c = a.Id
inner join salesforce.Contact_Role__c cr_cert on cr_cert.Account__c = cert.Id
inner join salesforce.contact c on cr_cert.Contact__c = c.Id
where 
a.Record_Type_Name__c = 'Client'
#and a.Id='00190000008nWZ9AAM'
union 
select a.Id, a.Name, 
cr_site_cert.Status__c, cr_site_cert.Type__c, c.Id as 'Contact Id', c.Name as 'Contact Name', c.Title, c.Email, c.Salutation, c.Phone, c.Site_Business_Address_1__c, c.Site_Business_Address_2__c, c.Site_Business_Address_3__c, c.Site_Business_City__c, c.Site_Business_Zip_Postal_Code__c, c.Site_Business_Country__c, c.Site_Business_State__c
from salesforce.account a
inner join certification__c cert on cert.Primary_client__c = a.Id
inner join certification__c site_cert on site_cert.Primary_Certification__c = cert.Id
inner join salesforce.Contact_Role__c cr_site_cert on cr_site_cert.Site_Certification__c = site_cert.Id
inner join salesforce.contact c on cr_site_cert.Contact__c = c.Id
where 
a.Record_Type_Name__c = 'Client'
#and a.Id='00190000008nWZ9AAM'
) t
where t.Status__c = 'Active'
group by t.`Contact Id`;

select a.Id, a.Name, 
c.Status__c, 'Site' as 'Type', c.Id, c.Name
from salesforce.account a
left join salesforce.contact c on c.AccountId = a.Id
where 
a.Record_Type_Name__c = 'Client Site'
and a.ParentId='00190000008nWZ9AAM';

select * from salesforce.Contact where Id='00390000008M8h9AAC';
select * from salesforce.contact_role__c where Contact__c='00390000008M8h9AAC';

create index postcode_geo_index on analytics.postcodes_geo(postcode);
        
drop temporary table de_registered_sites;
create temporary table de_registered_sites as
#explain
select 
	client.Id as 'Client Id',
    client.Name as 'Client Name',
    site.Id as 'Site Id',
    site.Name as 'Site Name',
    ccs.Name as 'Site Country',
    scs.Name as 'Site State',
    site.Business_Zip_Postal_Code__c as 'Site Postcode',
    if(site.Latitude__c is null, geopc.latitude, site.Latitude__c) as 'Site Latitude',
    if(site.Longitude__c is null, geopc.longitude, site.Longitude__c) as 'Site Longitude',
    if(i.Name in ('03 - 02 | Manufacture of beverages','03 - 05 | Manufacture of food products'),'03 - Manufacturing - Food & Beverages',i.Industry_Sector__c) as 'Industry (Compass)',
	if(i.Name = '99 | To be Confirmed',
		if( group_concat(distinct if(scspc.IsDeleted = 0 and code.IsDeleted = 0 and scsp.IsDeleted = 0 and sc.IsDeleted = 0 and code.Name like 'NACE%', salesforce.getIndustryFromNace(substring_index(replace(code.Name,'NACE: ',''),'.',1)), null)) is null,
			if(group_concat(distinct sp.Program_Business_Line__c) like '%Product Services%', 
				'03 - Manufacturing',
				if(group_concat(distinct sp.Program_Business_Line__c) like '%Food%', 
					'03 - Manufacturing - Food & Beverages',
					if(group_concat(distinct scsp.Standard_Service_Type_Name__c) like '%Disability%' or group_concat(distinct scsp.Standard_Service_Type_Name__c) like '%DSS%', 
						'13 - Human Health and Social Work', 
						if(group_concat(distinct if(scspc.IsDeleted = 0 and code.IsDeleted = 0 and scsp.IsDeleted = 0 and sc.IsDeleted = 0 and code.Name like 'SAI%', code.Name, null)) like '%SE01%' or 
							group_concat(distinct if(scspc.IsDeleted = 0 and code.IsDeleted = 0 and scsp.IsDeleted = 0 and sc.IsDeleted = 0 and code.Name like 'SAI%', code.Name, null)) like '%SH01%',
							'02 - Mining and Quarrying',
							if(client.Client_Ownership__c='Product Services','03 - Manufacturing','99 | To be Confirmed'))
						)
					)
				),
			#group_concat(distinct if(scspc.IsDeleted = 0 and code.IsDeleted = 0 and scsp.IsDeleted = 0 and sc.IsDeleted = 0 and c.IsDeleted = 0 and code.Name like 'NACE%', getIndustryFromNace(substring_index(replace(code.Name,'NACE: ',''),'.',1)), null))),
			min(if(scspc.IsDeleted = 0 and code.IsDeleted = 0 and scsp.IsDeleted = 0 and sc.IsDeleted = 0 and code.Name like 'NACE%', salesforce.getIndustryFromNace(substring_index(replace(code.Name,'NACE: ',''),'.',1)), '99 | To be Confirmed'))),
		if(i.Name in ('03 - 02 | Manufacture of beverages','03 - 05 | Manufacture of food products'),'03 - Manufacturing - Food & Beverages',i.Industry_Sector__c) 
	) as 'Industry (Guess)', 
    group_concat(distinct if(scspc.IsDeleted = 0 and code.IsDeleted = 0 and scsp.IsDeleted = 0 and sc.IsDeleted = 0, code.Name, null)) as 'Codes',
    scsp.Id as 'Site Cert Program Id',
	if(sp.Program_Business_Line__c like '%Food%' or scsp.Standard_Service_Type_Name__c like '%BRC%', 'Food', if(sp.Program_Business_Line__c = 'Product Services','PS','MS')) as 'Stream',
    scsp.Site_Certification__c,
	scsp.Standard_Service_Type_Name__c,
    scsp.Withdrawn_Date__c as 'De-Registered Date',
    scsp.Site_Originally_Registered__c,
    scsp.De_registered_Type__c,
    scsp.Site_Certification_Status_Reason__c,
    if(FSample_Site__c like '%unchecked%', false, true) as 'Sample Site',
	sc.Revenue_Ownership__c,
    sc.Invoice_Group_Registration__c,
    sc.Invoice_Group_Royalty__c,
    sc.Invoice_Group_Work_Item__c,
    sc.CurrencyIsoCode,
    sc.Registration_Fee_Product__c,
    csd.`Registered Site Cert` as 'Client # Registered Site Cert',
    csd.`Registered Certifications` as 'Client # Registered Certifications',
    csd.`Active Sites` as 'Client # Active Sites'
from salesforce.site_certification_standard_program__c scsp
inner join salesforce.certification__c sc ON scsp.Site_Certification__c = sc.Id
inner join salesforce.account site on sc.Primary_client__c = site.Id
left join analytics.postcodes_geo geopc on site.Business_Zip_Postal_Code__c = geopc.postcode COLLATE utf8_unicode_ci
left join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id
left join salesforce.state_code_setup__c scs on site.Business_State__c = scs.Id
inner join salesforce.account client on site.ParentId = client.Id
left join salesforce.industry__c i on client.Industry_2__c = i.Id
left join analytics.client_size_data csd on csd.`Client_Id` = client.Id
left join salesforce.site_certification_standard_program__history scsph ON scsph.ParentId = scsp.Id
left join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
left join salesforce.site_cert_standard_program_code__c scspc on scspc.Site_Certification_Standard_Program__c = scsp.Id
left join salesforce.code__c code on scspc.Code__c = code.Id
where
	scsp.De_registered_Type__c in ('Client Initiated' , 'SAI Initiated')
	and scsp.Site_Certification_Status_Reason__c not in ('Correction of customer data' , 'Customer consolidation of licences', 'Other – no loss of revenue')
	and scsp.Status__c = 'De-registered'
	and scsph.Field = 'Status__c'
	and scsph.NewValue = 'De-registered'
	and scsp.IsDeleted = 0
	and scsph.IsDeleted = 0
	and sc.Revenue_Ownership__c like 'EMEA%'
group by scsp.Id;
select * from de_registered_sites;
select * from de_registered_sites_data;
#explain
(select t.* from (
select 
	`Client Id`, `Client Name`, count(distinct Site_certification__c) as '# Site Certs', `Industry (Guess)`, group_concat(distinct Standard_Service_Type_Name__c order by Standard_Service_Type_Name__c) as 'Programs', max(`De-Registered Date`) as 'Last Deregistration', `Stream`, datediff(max(`De-Registered Date`), min(`Site_Originally_Registered__c`)) as 'Duration',
    De_registered_Type__c as 'De-Registered Type', Site_Certification_Status_Reason__c as 'De-Registered Reason',
    cc.`Contact Name`, cc.`Contact Id`,  cc.Title, cc.Email, cc.Salutation, cc.Phone, cc.Site_Business_Address_1__c, cc.Site_Business_Address_2__c, cc.Site_Business_Address_3__c, cc.Site_Business_City__c, cc.Site_Business_Zip_Postal_Code__c,
    cc.Site_Business_Country__c, cc.Site_Business_State__c
from de_registered_sites drs
left join client_contacts cc on drs.`Client Id` = cc.Id
where 
	`Client # Registered Site Cert` is null
    and `Stream` in ('MS', 'Food')
    and `Revenue_Ownership__c` like 'EMEA%'
group by `Client Id`) t
where t.`# Site Certs` < 4);

select * from client_size_data where `Client_Id` = '00190000008nWBQAA2';
#explain
#select t4.*, 
#if(sum(if(oscsp.IsDeleted = 0 and oscsp.De_registered_Type__c is null, 1, 0))>0, true, false) as 'Site Active'
#from 
#(select 
#t3.`Client Id`, t3.`Client Name`, t3.`Site Id`, t3.`Site Name`, t3.`Site Cert Program Id`, t3.`Stream`, t3.`Site Cert Id`, t3.`Primary Standard`, t3.`De-Registered Date`, t3.`Originally Registered Date`, t3.`De-Registered Type`, t3.`De-Registered Reason`, t3.`Revenue Ownership`,
#t3.`Last Audit Id`, t3.`Last Audit Date`, t3.`Last Audit Type`, 
#group_concat(distinct t3.`Auditors` order by t3.`Auditors`) as 'Auditors',
#t3.`Confirmed By` as 'Last Audit Confirmed By',
#group_concat(distinct t3.`Confirmed By` order by t3.`Confirmed By`) as 'Confirmed By',
#t3.`Invoice Created Date` as 'Last Invoice Created Date',
#t3.`Invoice Amount (ex Tax)` as 'Last Invoice Amount (ex Tax)'
#from (
#select t2.*, 
#i.CreatedDate as 'Invoice Created Date',
#i.Total_Amount__c as 'Invoice Amount (ex Tax)'
#from 
create temporary table de_registered_sites_data as
(select
t.`Client Id`, t.`Client Name`, t.`Site Id`, t.`Site Name`, t.`Site Country`,t.`Site State`,t.`Site Postcode`,t.`Site Latitude`, t.`Site Longitude`,t.`Industry (Compass)`,t.`Industry (Guess)`,t.`Codes`, t.`Site Cert Program Id`, t.`Stream`, t.`Site_Certification__c` as 'Site Cert Id', t.Standard_Service_Type_Name__c as 'Primary Standard', t.`De-Registered Date`, t.Site_Originally_Registered__c as 'Originally Registered Date', t.De_registered_Type__c as 'De-Registered Type', t.Site_Certification_Status_Reason__c as 'De-Registered Reason', t.Revenue_Ownership__c as 'Revenue Ownership',
if (t.Revenue_Ownership__c like 'AUS%', 'Australia', substring_index(t.Revenue_Ownership__c, '-',2)) as 'Region',
datediff(t.`De-Registered Date`, t.`Site_Originally_Registered__c`) as 'Duration',
if (t.`Work Item IsDeleted` = 0 and t.`Work Item Status` in ('Submitted', 'Under Review', 'Support', 'Completed', 'Under Review - Rejected', 'Complete'), t.`Audit Id`, null) as 'Last Audit Id',
if (t.`Work Item IsDeleted` = 0 and t.`Work Item Status` in ('Submitted', 'Under Review', 'Support', 'Completed', 'Under Review - Rejected', 'Complete'), t.`Audit Date`, null) as 'Last Audit Date',
if (t.`Work Item IsDeleted` = 0 and t.`Work Item Status` in ('Submitted', 'Under Review', 'Support', 'Completed', 'Under Review - Rejected', 'Complete'), t.`Audit Type`, null) as 'Last Audit Type',
group_concat(distinct if (t.`Work Item IsDeleted` = 0 and t.`Work Item Status` in ('Submitted', 'Under Review', 'Support', 'Completed', 'Under Review - Rejected', 'Complete'), t.`Auditor`, null) order by t.`Auditor`) as 'Auditors',
if (t.`Work Item IsDeleted` = 0 and t.`Work Item Status` in ('Submitted', 'Under Review', 'Support', 'Completed', 'Under Review - Rejected', 'Complete'), t.`Confirmed By`, null) as 'Last Audit Confirmed By',
group_concat(distinct if (t.`Work Item IsDeleted` = 0 and t.`Work Item Status` in ('Submitted', 'Under Review', 'Support', 'Completed', 'Under Review - Rejected', 'Complete'), t.`Confirmed By`, null) order by t.`Confirmed By`) as 'Confirmed By',
t.`Sample Site`,
if(t.`Client # Registered Site Cert` is null,0,t.`Client # Registered Site Cert`) as 'Client # Registered Site Cert',
if(t.`Client # Registered Certifications` is null,0,t.`Client # Registered Certifications`) as 'Client # Registered Certifications',
if(t.`Client # Active Sites` is null, 0, t.`Client # Active Sites`) as 'Client # Active Sites'
#t.Invoice_Group_Registration__c,
#t.Invoice_Group_Royalty__c,
#t.Invoice_Group_Work_Item__c,
#t.CurrencyIsoCode,
#t.Registration_Fee_Product__c,
from
(select drs.*, 
wi.Id as 'Audit Id',
if (wi.IsDeleted = 0 and wi.Status__c in ('Submitted', 'Under Review', 'Support', 'Completed', 'Under Review - Rejected', 'Complete'), 1, 0) as 'Sort Order',
wi.Status__c as 'Work Item Status',
wi.IsDeleted as 'Work Item IsDeleted',
wi.work_item_Date__c as 'Audit Date',
wi.Work_Item_Stage__c as 'Audit Type',
r.Name as 'Auditor',
group_concat(distinct if(wih.IsDeleted=0 and wih.Field = 'Status__c' and wih.NewValue = 'Confirmed', cb.Name, null) order by cb.Name) as 'Confirmed By'
from analytics.de_registered_sites drs
left join salesforce.work_item__c wi on drs.`Site Cert Program Id` = wi.Site_Certification_Standard__c
left join salesforce.work_item__history wih on wih.ParentId = wi.Id
left join salesforce.user cb on wih.CreatedById = cb.Id
left join salesforce.resource__c r on wi.RAudit_Report_Author__c = r.Id
group by drs.`Site Cert Program Id`, wi.Id
order by drs.`Site Cert Program Id`, `Sort Order` desc, wi.work_item_Date__c desc) t
group by t.`Site Cert Program Id`); 
#t2
#inner join salesforce.invoice_group__c ig on t2.Invoice_Group_Work_Item__c = ig.Id
#inner join salesforce.invoice__c i on i.Invoice_Group__c = ig.Id
#where ig.IsDeleted = 0
#and i.IsDeleted = 0
#and i.Status__c not in ('Cancelled')
#group by t2.`Site Cert Program Id`, i.Id
#order by t2.`Site Cert Program Id`, i.CreatedDate desc ) t3
#group by t3.`Site Cert Program Id`)
# t4
#left join salesforce.certification__c osc on t4.`Site Id` = osc.Primary_Site__c
#left join salesforce.site_certification_standard_program__c oscsp on oscsp.Site_Certification__c = osc.Id
#group by t4.`Site Cert Program Id`;

(select t.*,
if(t.`Last Invoice Created Date` is null, 99999, datediff(t.`First WI Cancellation Date`, t.`Last Invoice Created Date`)) as 'First Cancellation to Last Invoice (days)',
datediff(t.`First WI Cancellation Date`, t.`First WI Scheduled Date`) as 'First Cancellation to First WI Date (days)',
if(t.`Last Invoice Created Date` is null, 99999, round(datediff(t.`First WI Cancellation Date`, t.`Last Invoice Created Date`)/30)) as 'First Cancellation to Last Invoice (months)',
round(datediff(t.`First WI Cancellation Date`, t.`First WI Scheduled Date`)/30) as 'First Cancellation to First WI Date (months)'
 from 
(select lba.Client_Id__c, lba.Site_Certification__c, lba.Site_Cert_Satndard_Id, lba.De_registered_Type__c, lba.Site_Certification_Status_Reason__c, lba.Sample_Site__c, lba.StandardName as 'Standard', 
min(lba.`Cancelled Date`) as 'First WI Cancellation Date', 
min(lba.work_item_Date__c) as 'First WI Scheduled Date', 
max(if(i.IsDeleted=0 and i.Status__c not in ('Cancelled'), i.CreatedDate, null)) as 'Last Invoice Created Date', 
if (lba.Revenue_Ownership__c like 'AUS%', 'Australia', substring_index(lba.Revenue_Ownership__c, '-',2)) as 'Region',
lba.Revenue_Ownership__c, lba.StandardName 
from salesforce.sf_lost_business_audits_multi_region lba
inner join salesforce.certification__c sc on sc.Id = lba.Site_Certification__c
left join salesforce.invoice_group__c ig on sc.Invoice_Group_Work_Item__c = ig.Id
left join salesforce.invoice__c i on i.Invoice_Group__c = ig.Id
where lba.De_registered_Type__c in ('Client Initiated' , 'SAI Initiated')
group by lba.Site_Certification__c) t);

select table_name from information_schema.tables where table_schema='salesforce' and table_name like '%post%';

describe salesforce.saig_australian_postcodes;
describe salesforce.saig_postcodes_to_sla4;

select * from salesforce.saig_postcodes_to_sla4;

drop FUNCTION analytics.standardCompanyName;
DELIMITER //
CREATE FUNCTION analytics.standardCompanyName(original TEXT, exclude TEXT) RETURNS TEXT
BEGIN
	DECLARE stdName TEXT DEFAULT '';
    SET stdName = Lower(original);
    SET stdName = replace(stdName, 'the', '');
    SET stdName = replace(stdName, 'pty', '');
    SET stdName = replace(stdName, 'ltd', '');
    SET stdName = replace(stdName, 'limited', '');
    SET stdName = replace(stdName, 'group', '');
    SET stdName = if (exclude is null,stdName, replace(stdName, exclude, ''));
    SET stdName = replace(stdName, '-', '');
    SET stdName = replace(stdName, ',', '');
    SET stdName = replace(stdName, ';', '');
    SET stdName = replace(stdName, ')', '');
    SET stdName = replace(stdName, '(', '');
    SET stdName = trim(stdName);
    #RETURN soundex(stdName);
    RETURN stdName;
 END //
DELIMITER ;
select standardCompanyName('The Laminex Group Pty Limited',null);

(select 
#drsd.`Client Name`, drsd.`Site Name`, jco.Name, jco.City, jco.Country, jco.CertificationBody 
drsd.*, max(jco.Name) as 'JAS ANZ Name', max(jco.CertificationBody) as 'Current CB'
from de_registered_sites_data drsd 
#left join jasanz_certified_organisations jco on standardCompanyName(drsd.`Client Name`,null) = standardCompanyName(jco.Name, jco.City) and jco.CertificationStandards = 'AS/NZS ISO 9001:2008'
left join jasanz_certified_organisations jco on standardCompanyName(drsd.`Client Name`,null) = standardCompanyName(jco.Name, jco.City)
where 
#drsd.`Primary Standard` = '9001:2008 | Certification' and 
drsd.`De-Registered Reason` in ('Change to other CB (Cost)','Change to other CB (Service delivery)','Change to other CB (Other)')
group by drsd.`Site Cert Program Id`);

(select sc.Id, sc.Name, scsp.Standard_Service_Type_Name__c as 'Primary Standard', sc.Revenue_Ownership__c as 'Region', ccs.Name as 'Site Country' 
from salesforce.site_certification_standard_program__c scsp
inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
inner join salesforce.account site on sc.Primary_client__c = site.Id
inner join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id
where
scsp.Status__c in ('Applicant', 'Registered', 'Customised')
and scsp.IsDeleted = 0
and sc.IsDeleted = 0
and sc.Revenue_Ownership__c like 'EMEA%');