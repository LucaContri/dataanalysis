select wi.Client_Name_No_Hyperlink__c as 'Client Name', wi.Name as 'Work ITem', wi.Work_Item_Stage__c as 'Audit Type', wi.Primary_Standard__c as 'Primary Standard',
date_format(wi.Service_target_date__c, '%d/%m/%Y') as 'Service Target Date',
date_format(wi.Earliest_Service_Date__c, '%d/%m/%Y') as 'Work Item Start Date',
date_format(wi.End_Service_Date__c, '%d/%m/%Y') as 'Work Item End Date',
wi.Status__c as 'Work Item Status',
r.Name as 'Work Item Owner',
group_concat(distinct if(scspc.IsDeleted=0 and c.IsDeleted=0, c.Name, null)) as 'Codes',
csp.Scope__c as 'Scope',
date_format(csp.Expires__c, '%d/%m/%Y')as 'Expiry'
from salesforce.work_item__c wi
left join salesforce.resource__c r on wi.Work_Item_Owner__c = r.Id
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
left join salesforce.site_cert_standard_program_code__c scspc on scspc.Site_Certification_Standard_Program__c = scsp.Id
left join salesforce.code__c c on scspc.Code__c = c.Id
inner join salesforce.certification_standard_program__c csp on scsp.Certification_Standard__c = csp.Id
where
wi.IsDeleted = 0
#and wi.Status__c not in ('Cancelled', 'Draft', 'Initiate service')
and wi.Primary_Standard__c like '%13485%'
group by wi.Id;

select Id, Name from salesforce.program__c where NAme like '%space%';

#Aerospace
(select wi.Client_Name_No_Hyperlink__c as 'Client Name', wi.Name as 'Work ITem', wi.Work_Item_Stage__c as 'Audit Type', wi.Primary_Standard__c as 'Primary Standard',
date_format(wi.Service_target_date__c, '%d/%m/%Y') as 'Service Target Date',
date_format(wi.Earliest_Service_Date__c, '%d/%m/%Y') as 'Work Item Start Date',
date_format(wi.End_Service_Date__c, '%d/%m/%Y') as 'Work Item End Date',
wi.Status__c as 'Work Item Status',
r.Name as 'Work Item Owner',
group_concat(distinct if(scspc.IsDeleted=0 and c.IsDeleted=0, c.Name, null)) as 'Codes',
csp.Scope__c as 'Scope',
date_format(csp.Expires__c, '%d/%m/%Y')as 'Expiry'
from salesforce.work_item__c wi
left join salesforce.resource__c r on wi.Work_Item_Owner__c = r.Id
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
inner join salesforce.program__c p on sp.Program__c = p.Id
left join salesforce.site_cert_standard_program_code__c scspc on scspc.Site_Certification_Standard_Program__c = scsp.Id
left join salesforce.code__c c on scspc.Code__c = c.Id
inner join salesforce.certification_standard_program__c csp on scsp.Certification_Standard__c = csp.Id
where
wi.IsDeleted = 0
and scsp.IsDeleted = 0
and sp.IsDeleted = 0
and p.Name = 'Aerospace'
group by wi.Id);