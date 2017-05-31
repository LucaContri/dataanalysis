use salesforce;
create index site_certification_standard_program__cert_std_index on site_certification_standard_program__c(Certification_Standard__c); 
create index account_parent_index on account(ParentId);

#explain
create or replace view china_cnca_product_services_report as
(select 
	licence_holder_site.Name as 'Licence Holder',
    concat(
		ifnull(licence_holder_site.Business_Address_1__c, ''), 
		ifnull(concat(',',licence_holder_site.Business_Address_2__c), ''), 
        ifnull(concat(',',licence_holder_site.Business_City__c), ''), 
        ifnull(concat(',',licence_holder_site_state.Name), ''), 
        ifnull(concat(',',licence_holder_site_country.Name), ''), 
        ifnull(concat(',',licence_holder_site.Business_Zip_Postal_Code__c), '')) as 'Licence Holder Address',
	site.Name as 'Site Name',
    ifnull(site.Client_Site_Local_Language__c,'') as 'Client Site Local Language',
    #site.Client_Name_Local_Language__c,
    concat(
		ifnull(site.Business_Address_1__c, ''), 
		ifnull(concat(',',site.Business_Address_2__c), ''), 
        ifnull(concat(',',site.Business_City__c), ''), 
        ifnull(concat(',',site_state.Name), ''), 
        ifnull(concat(',',site_country.Name), ''), 
        ifnull(concat(',',site.Business_Zip_Postal_Code__c), '')) as 'Site Address',
	industry.Name as 'Industry',
    s.Name as 'Standard',
    csp.SAI_Certificate_Number__c as 'SAI Certificate Number',
    csp.Status__c as 'SAI Certificate Status',
    ifnull(csp.Certification_Status_Reason__c,'') as 'De-Registered Reason',
    ifnull(csp.Originally_Registered__c, '') as 'Cert Originally Registered',
    ifnull(csp.Current_Certification__c, '') as 'Cert Current Registration Date',
    ifnull(csp.Issued__c, '') as 'Cert Issue Date',
    ifnull(csp.Expires__c, '') as 'Cert Expiry Date',
    ifnull(csp.Withdrawn_Date__c,'') as 'De-Registration Date', 
    ifnull(csp.Under_Suspension_Date__c,'') as 'Under Suspension Date',
    ifnull(max(if(csph.NewValue = 'On Hold', csph.CreatedDate, null)),'') as 'On Hold Date (Last)',
    ifnull(max(if(csph.OldValue = 'On Hold', csph.CreatedDate, null)),'') as 'Out of On Hold Date (Last)',
    ifnull(max(if(csph.NewValue = 'Under Suspension', csph.CreatedDate, null)),'') as 'Under Suspension Date (Last)',
    ifnull(max(if(csph.OldValue = 'Under Suspension', csph.CreatedDate, null)),'') as 'Out of Under Suspension Date (Last)',
    sc.Name as 'Site Certification', 
    if(sc.Primary_Site__c, 'TRUE', 'FALSE') as 'Primary Site',
    if(sc.Auditable_Site__c, 'TRUE', 'FALSE') as 'Auditable Site',
	scsp.Status__c as 'SAI Site Certificate Status',
    ifnull(scsp.Site_Originally_Registered__c,'') as 'Site Cert Originally Registered', 
    ifnull(scsp.Withdrawn_Date__c, '') as 'Site Cert De-Registration Date', 
    ifnull(contact.Name, '') as 'Site Contact',
    ifnull(contact.Phone, '') as 'Contact Phone'
from salesforce.certification_standard_program__c csp 
	left join salesforce.certification_standard_program__history csph on csph.ParentId = csp.Id and csph.Field = 'Status__c'
	inner join salesforce.certification__c c on csp.Certification__c = c.Id
	inner join salesforce.site_certification_standard_program__c scsp on scsp.Certification_Standard__c = csp.Id
	inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
	inner join salesforce.standard__c s on sp.Standard__c = s.Id
	inner join salesforce.program__c p on sp.Program__c = p.Id
	inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
	inner join salesforce.account site on sc.Primary_client__c = site.Id 
    inner join salesforce.country_code_setup__c site_country on site.Business_Country2__c = site_country.Id and site_country.Name = 'China'
    left join salesforce.state_code_setup__c site_state on site.Business_State__c = site_state.Id
    inner join salesforce.account client on site.ParentId = client.Id
    left join salesforce.industry__c industry on client.Industry_2__c = industry.Id
    left join salesforce.certification__c sc_ps on sc_ps.Primary_Certification__c = c.Id and sc_ps.Primary_Site__c = 1
    left join salesforce.account licence_holder_site on  licence_holder_site.Id = sc_ps.Primary_client__c
    left join salesforce.country_code_setup__c licence_holder_site_country on licence_holder_site.Business_Country2__c = licence_holder_site_country .Id
    left join salesforce.state_code_setup__c licence_holder_site_state on licence_holder_site.Business_State__c = licence_holder_site_state.Id  
	left join salesforce.contact_role__c cr on cr.Site_Certification__c = sc.Id
	left join salesforce.contact contact on cr.Contact__c = contact.Id
where
	p.Business_Line__c = 'Product Services'
    and csp.Status__c not in ('Applicant')
group by csp.Id, scsp.Id);

(select * from china_cnca_product_services_report);