use salesforce;

create index Contact_Role_cert_index on Contact_Role__c(Certification__c);
create index Contact_Role_client_index on Contact_Role__c(Account__c);
#explain
select 
client.Id as 'Client Id', 
client.Name as 'Client Name',
client.Client_Ownership__c as 'Client Ownership',
csp.Name as 'Certification', 
csp.Status__c as 'Certification Status', 
csp.Originally_Registered__c as 'Originally Registered',
csp.Expires__c as 'Expiry Date',
csp.Withdrawn_Date__c as 'De-Registration Date',
datediff( if(csp.Withdrawn_Date__c is null, now(), csp.Withdrawn_Date__c), if(csp.Originally_Registered__c is null, now(),csp.Originally_Registered__c)) as 'Days Registered',
datediff( if(csp.Withdrawn_Date__c is null, now(), csp.Withdrawn_Date__c), if(csp.Originally_Registered__c is null, now(),csp.Originally_Registered__c))/365 as 'Years Registered',
scsp.FSiteName__c as 'Site Name',
scsp.RT_Location__c as 'Site Location', 

if (cr.Status__c='Active' and cr.Type__c='Certificate Register', cont.Name, null) as 'Certificate Register',
if (cr.Status__c='Active' and cr.Type__c='Certificate Register', cont.Email, null) as 'Certificate Register Email',
if (cr.Status__c='Active' and cr.Type__c='Corporate', cont.Name, null) as 'Corporate',
if (cr.Status__c='Active' and cr.Type__c='Corporate', cont.Email, null) as 'Corporate Email',
if (cr.Status__c='Active' and cr.Type__c='Correspondence', cont.Name, null) as 'Correspondence',
if (cr.Status__c='Active' and cr.Type__c='Correspondence', cont.Email, null) as 'Correspondence Email'
#if (siteCont.IsDeleted=0, null, siteCont.Name) as 'Primary Site Contact',
#if (siteCont.IsDeleted=0, null, siteCont.Email) as 'Primary Site Contact Email'
from certification_standard_program__c csp
inner join certification__c c on csp.Certification__c = c.Id
inner join account client on c.Primary_client__c = client.Id
inner join site_certification_standard_program__c scsp on scsp.Certification_Standard__c = csp.Id
#inner join certification__c site_cert on scsp.Site_Certification__c = site_cert.Id
#inner join account site on site_cert.Primary_client__c = site.Id
#left join Contact siteCont on site.Id = siteCont.AccountId
left join Contact_Role__c cr on cr.Account__c = client.Id
left join Contact cont on cr.Contact__c = cont.Id

where
csp.IsDeleted = 0
and c.IsDeleted = 0
and client.IsDeleted = 0
and client.Client_Ownership__c = 'Australia'
and scsp.IsDeleted = 0
and scsp.Primary_Site__c like '%checkbox_checked%'
and datediff( if(csp.Withdrawn_Date__c is null, now(), csp.Withdrawn_Date__c), if(csp.Originally_Registered__c is null, now(),csp.Originally_Registered__c))/365>=5
and csp.Status__c = 'Registered'
group by client.Id, c.Id
limit 100000;
#group by client.Id