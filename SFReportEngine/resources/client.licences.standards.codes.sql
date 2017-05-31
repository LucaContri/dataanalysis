select client.Client_Ownership__c, client.Name as 'Client Name', csp.SAI_Certificate_Number__c as 'Licence Number', group_concat(scsp.Name) as 'Site Cert Standards', group_concat(s.Name) as 'Standards', group_concat(code.NAme) as 'NACE Codes'
from salesforce.site_certification_standard_program__c scsp
inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
inner join salesforce.account site on sc.Primary_client__c = site.Id
inner join salesforce.account client on site.ParentId = client.Id
inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
inner join salesforce.certification_standard_program__c csp on scsp.Certification_Standard__c = csp.Id
inner join salesforce.standard__c s on sp.Standard__c = s.Id
inner join salesforce.Site_Cert_Standard_Program_Code__c scspc on scspc.Site_Certification_Standard_Program__c = scsp.Id
inner join salesforce.code__c code on scspc.Code__C = code.Id
where s.Name like '%22000%'
and scspc.IsDeleted = 0
and scsp.De_registered_Type__c is null
and scsp.IsDeleted=0
and (code.Name like '%10.92%' or code.Name like '%20%' or code.Name like '%22%' or code.Name like '%01.4%') 
and code.Name like '%NACE%'
group by csp.Id;

select * from salesforce.code__c where name like '%01.4%'