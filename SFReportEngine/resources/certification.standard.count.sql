(select 
if (ao.Name like 'AUS%' or ao.Name like 'ASIA%', 'APAC', if(ao.Name like 'EMEA%', 'EMEA', ao.Name)) as 'Admin Region',
if (ao.Name like 'AUS%', 'Australia', substring_index(ao.Name, '-',-1)) as 'Admin Country', 
client.Id as 'Client Id',
client.Name as 'Client Name',
site.Name as 'Site Name',
site.Business_City__c as 'City',
scs.Name as 'State',
ccs.Name as 'Country',
concat(if (site.Business_City__c is null, '', site.Business_City__c),' ', if(scs.Name is null, '', scs.Name), ' ',  if(ccs.Name is null, '', ccs.Name)) as 'Location',
sp.Program_Business_Line__c as 'Business Line',
csp.Standard_Service_Type_Name__c as 'Standard'
from salesforce.certification_standard_program__c csp
left join salesforce.administration_group__c ao on csp.Administration_Ownership__c = ao.Id
inner join salesforce.site_certification_standard_program__c scsp on scsp.Certification_Standard__c = csp.Id
left join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
left join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
left join salesforce.certification__c c on csp.Certification__c = c.Id
left join salesforce.account client on c.Primary_client__c = client.Id
left join salesforce.account site on sc.Primary_client__c = site.Id
left join salesforce.state_code_setup__c scs on site.Business_State__c = scs.Id
left join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id
where csp.isDeleted = 0
and scsp.IsDeleted = 0
and csp.Status__c in ('Registered')
and scsp.Status__c in ('Registered')
group by scsp.Id);