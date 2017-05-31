# Zew Zealand based clients
(select 
	scsp.Id as 'Site Cert Std Id', 
    scsp.Name as 'Site Cert Std', 
    scsp.Status__c as 'Status',
    p.Business_Line__c as 'Business Line', p.Name as 'Program', s.Name as 'Standard', 
	site.Name as 'Client Site', 
    site.Business_Address_1__c, site.Business_Address_2__c, site.Business_Address_3__c, site.Business_City__c, site.Business_Zip_Postal_Code__c, ccs.Name as 'Country',
    concat(ifnull(site.Business_Address_1__c,''), ' ', ifnull(site.Business_Address_2__c,''), ' ', ifnull(site.Business_Address_3__c,''), ' ', ifnull(site.Business_City__c,''), ' ', ifnull(site.Business_Zip_Postal_Code__c,''), ' ', ccs.Name) as 'Full Address'
from salesforce.site_certification_standard_program__c scsp
	inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
	inner join salesforce.standard__c s on sp.Standard__c = s.Id
	inner join salesforce.program__c p on sp.Program__c = p.Id
	inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
	inner join salesforce.account site on sc.Primary_client__c = site.Id
	inner join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id
where scsp.Status__c in ('Applicant','Registered','Customised') 
and ccs.Name = 'New Zealand');