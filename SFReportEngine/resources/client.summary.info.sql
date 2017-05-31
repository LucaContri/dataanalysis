(select t2.*,
if (t2.`First Audit`<'9999-12-31' and t2.`Last Audit`>'1970-01-01', if(datediff(t2.`Last Audit`, t2.`First Audit`)<365, t2.`Total Days`, t2.`Total Days`/datediff(t2.`Last Audit`, t2.`First Audit`)*365),0) as 'Avg Days/Year',
if (t2.`Active Site Certs`=0 and t2.`De-Registered Site Certs`>0, 1,0) as 'is_churn',
if(t2.`De-Registered Reasons` like '%No added value / interest%', 1,0) as 'no_added_value',
if(t2.`De-Registered Reasons` like '%Change to other CB (Other)%', 1,0) as 'change_to_other_cb-other',
if(t2.`De-Registered Reasons` like '%Change to other CB (Service delivery)%', 1,0) as 'change_to_other_cb-service',
if(t2.`De-Registered Reasons` like '%Change to other CB (Cost)%', 1,0) as 'change_to_other_cb-cost',
if(t2.`De-Registered Reasons` like '%Business / site closed down%', 1,0) as 'business_site_closed_down',
if(t2.`Programs2` like '%9001%' or t2.`ProgramsFamilies` like '%9001%', 1, 0) as 'has_9001',
if(t2.`Programs2` like '%4801%' or t2.`ProgramsFamilies` like '%4801%', 1, 0) as 'has_4801',
if(t2.`Programs2` like '%14001%' or t2.`ProgramsFamilies` like '%14001%', 1, 0) as 'has_14001',
if(t2.`Programs2` like '%HACCP%' or t2.`ProgramsFamilies` like '%HACCP%', 1, 0) as 'has_HACCP',
if(t2.`Programs2` like '%BRC%' or t2.`ProgramsFamilies` like '%BRC%', 1, 0) as 'has_BRC',
if(t2.`Programs2` like '%27001%' or t2.`ProgramsFamilies` like '%27001%', 1, 0) as 'has_27001',
if(t2.`Programs2` like '%DSS%' or t2.`ProgramsFamilies` like '%DSS%', 1, 0) as 'has_DSS',
if(t2.`Programs2` like '%WaterMark%' or t2.`ProgramsFamilies` like '%WaterMark%', 1, 0) as 'has_WaterMark',
if(t2.`Programs2` like '%WQA%' or t2.`Programs` like '%Woolworth%' or t2.`ProgramsFamilies` like '%WQA%' or t2.`ProgramsFamilies` like '%Woolworth%', 1, 0) as 'has_WQA'
from (
select client.id as 'ClientId', client.Name as 'ClientName', site.Id as 'SiteID', site.Name as 'SiteName', client.Client_Ownership__c, scs.Name as 'State', ccs.Name as 'Country', site.Business_Zip_Postal_Code__c, 
i.Name as 'Industry',
count(distinct if(sc.IsDeleted=0 and scsp.IsDeleted=0 and scsp.Status__c in ('De-registered','Concluded'), sc.Id, null)) as 'De-Registered Site Certs',
count(distinct if(sc.IsDeleted=0 and scsp.IsDeleted=0 and scsp.Status__c not in ('De-registered','Concluded'), sc.Id, null)) as 'Active Site Certs',
min(if(sc.IsDeleted=0 and scsp.IsDeleted=0, csp.Originally_Registered__c, '9999-12-31')) as 'First Originally Registered',
group_concat(distinct if(scsp.IsDeleted=0 and sp.IsDeleted=0, s.Name, null)) as 'Programs2',
group_concat(distinct if(scsp.IsDeleted=0 and scsf.IsDeleted=0 and spf.IsDeleted=0, sf.Name, null)) as 'ProgramsFamilies',
group_concat(distinct if(wi.IsDeleted=0 , wi.Primary_Standard__c, null)) as 'Programs',
count(distinct if(wi.IsDeleted=0, wi.Primary_Standard__c, null)) as '# Programs',
group_concat(distinct if(sc.IsDeleted=0 and scsp.IsDeleted=0 and scsp.Status__c in ('De-registered','Concluded'), scsp.Site_Certification_Status_Reason__c, null)) as 'De-Registered Reasons',
sum(if(wi.IsDeleted=0 and wi.Status__c in ('Confirmed', 'In Progress', 'Submitted', 'Under Review', 'Support', 'Completed', 'Under Review - Rejected', 'Complete'), wi.Required_Duration__c,0))/8 as 'Total Days',
min(if(wi.IsDeleted=0 and wi.Status__c in ('Confirmed', 'In Progress', 'Submitted', 'Under Review', 'Support', 'Completed', 'Under Review - Rejected', 'Complete'), wi.work_item_Date__c,'9999-12-31')) as 'First Audit',
max(if(wi.IsDeleted=0 and wi.Status__c in ('Confirmed', 'In Progress', 'Submitted', 'Under Review', 'Support', 'Completed', 'Under Review - Rejected', 'Complete'), wi.work_item_Date__c,'1970-01-01')) as 'Last Audit'

from salesforce.account client 
inner join salesforce.account site on site.ParentId = client.Id
left join salesforce.industry__c i on client.Industry_2__c = i.Id
left join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id
left join salesforce.state_code_setup__c scs on site.Business_State__c = scs.Id
left join salesforce.certification__c sc on sc.Primary_client__c = site.Id
left join salesforce.work_package__c wp on wp.Site_Certification__c = sc.Id
left join salesforce.work_item__c wi on wi.Work_Package__c = wp.Id
left join salesforce.site_certification_standard_program__c scsp on scsp.Site_Certification__c = sc.Id
left join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
left join salesforce.standard__c s on sp.Standard__c = s.Id
left join salesforce.site_certification_standard_family__c scsf on scsf.Site_Certification_Standard__c = scsp.id
left join salesforce.standard_program__c spf on scsf.Standard_Program__c = spf.Id
left join salesforce.standard__c sf on spf.Standard__c = sf.Id
left join salesforce.certification_standard_program__c csp on scsp.Certification_Standard__c = csp.Id
where
client.isDeleted = 0
and site.IsDeleted = 0
and client.Client_Account_Status__c = 'Active'
and site.Client_Account_Status__c = 'Active'
group by client.Id) t2); 
#where t2.`Active Site Certs`=0 and t2.`De-Registered Site Certs`>0);salesforce.


describe site_certification_standard_program__c;