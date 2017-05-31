# BRC Completed Performance
(select pt.*, ca.`Owner` as 'CA', r.Reporting_Business_Units__c as 'CA Business Unit',
if(pt.`Region` like 'AUS%' or pt.`Region` like 'Asia%', 'APAC', if(pt.`Region` like 'EMEA%', 'EMEA', '?')) as 'Region2',
if(pt.`Region` like 'AUS%', 'Australia', if(pt.`Region` like 'Asia%', replace(substring_index(pt.`Region`, '-',-2),'-Food',''), substring_index(pt.`Region`, '-',-1))) as 'Country',
if(pt.`To`<pt.`SLA Due`, true, false) as 'Within SLA'
from analytics.sla_arg_v2 pt
left join analytics.sla_arg_v2 ca on pt.Id = ca.Id and ca.`Metric` in ('ARG Revision - First','ARG Revision - Resubmission')
left join salesforce.resource__c r on ca.Owner = r.Name
where pt.`Metric` = 'ARG Process Time (BRC)' 
and pt.`To` is not null
#and pt.`Id` = 'a1Wd000000097vHEAQ'
group by pt.Id);

# BRC Completed Performance
(select pt.*,
if(pt.`Region` like 'AUS%' or pt.`Region` like 'Asia%', 'APAC', if(pt.`Region` like 'EMEA%', 'EMEA', '?')) as 'Region2',
if(pt.`Region` like 'AUS%', 'Australia', if(pt.`Region` like 'Asia%', replace(substring_index(pt.`Region`, '-',-2),'-Food',''), substring_index(pt.`Region`, '-',-1))) as 'Country',
if(utc_timestamp()>pt.`SLA Due`, true, false) as 'Over SLA'
from analytics.sla_arg_v2 pt
where pt.Standards like '%BRC%' 
and pt.`To` is null
#and pt.`Id` = 'a1Wd000000097vHEAQ'
);

# BRC Audit Schedule
(select wi.Id, wi.Name as 'Work Item', wi.Client_Name_No_Hyperlink__c as 'Client Name', wi.Client_Site__c as 'Client Site', ccs.Name as 'Site Country', wi.Work_Item_Date__c as 'Target/Scheduled Date', date_format(wi.Work_Item_Date__c, '%x-%v') as 'Target/scheduled week', date_format(wi.Work_Item_Date__c, '%Y-%m') as 'Target/scheduled month', wi.Status__c as 'Status', wi.Primary_Standard__c as 'Primary Standard', wi.Revenue_Ownership__c, wi.Work_Item_stage__C as 'Work Item Type',
if(wi.Revenue_Ownership__c like 'AUS%', 'Australia', if(wi.Revenue_Ownership__c like 'Asia%', replace(substring_index(wi.Revenue_Ownership__c, '-',-2),'-Food',''), substring_index(wi.Revenue_Ownership__c, '-',-1))) as 'Revenue Ownership Country'
from salesforce.work_item__c wi
inner join salesforce.work_package__c wp on wi.Work_Package__c = wp.Id
inner join salesforce.certification__c sc on wp.Site_Certification__c = sc.Id
inner join salesforce.account site on sc.Primary_client__c = site.Id
left join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id
where wi.IsDeleted = 0
and wi.Status__c not in ('Cancelled', 'Draft', 'Initiate service')
and wi.Work_Item_Date__c >= '2015-07-01'
and wi.Primary_Standard__c like '%BRC%');