# Opportunity broken down by type - including opportunities by client segmentation / client complexity
# Opportunity closed/won which the audit has progressed + Timeframe from opportunity closed/won to initial audit across all cert all sites
#explain
select 
u.Name as 'Opp. Owner', 
o.Id as 'Opp. Id', 
o.Name as 'Opp. Name', 
o.CloseDate as 'Closed Date', 
o.StageName as 'Stage', 
o.Type as 'Type', 
o.ExpectedRevenue as 'Expected Revenues', 
o.Amount as 'Amount',
a.Name as 'Client', 
a.Client_Segmentation__c as 'Client Segmentation',
a.Scheduling_Complexity__c as 'Scheduling Complexity',
t.CertificationsCount as 'Certifications Count',
t.SitesCount as 'Sites Count',
t.WorkItemsCount as 'Work Items Count',
t.FirstGapWorkItemStartDate as 'First Gap Work Item Start Date',
t.FirstStage1WorkItemStartDate as 'First Stage1 Work Item Start Date',
t.FirstWorkItemStartDate as 'First Work Item Start Date',
t.OpportunityClosedToFirstWorkItemStartDays as 'Opportunity Closed to First Work Item Start (Days)',
t.OpportunityClosedToFirstWorkItemStartWeeks as 'Opportunity Closed to First Work Item Start (Weeks)'
from salesforce.opportunity o 
inner join salesforce.user u on o.OwnerId = u.Id
inner join salesforce.account a on o.AccountId = a.Id
left join (
select 
o.Id as 'OppId', 
count(distinct c.Id) as 'CertificationsCount',
count(distinct sc.Client_Site_NOLINK__c) as 'SitesCount',
count(wi.Id) as 'WorkItemsCount',
min(if (wi.Work_Item_Stage__c='Gap', wi.Work_Item_Date__c, null)) as 'FirstGapWorkItemStartDate',
min(if (wi.Work_Item_Stage__c='Stage 1', wi.Work_Item_Date__c, null)) as 'FirstStage1WorkItemStartDate',
min(wi.Work_Item_Date__c) as 'FirstWorkItemStartDate',
datediff(min(wi.Work_Item_Date__c), o.CloseDate) as 'OpportunityClosedToFirstWorkItemStartDays',
round(datediff(min(wi.Work_Item_Date__c), o.CloseDate)/7,0) as 'OpportunityClosedToFirstWorkItemStartWeeks'
from salesforce.opportunity o 
left join salesforce.certification__c c on c.Opportunity_Created_From__c = o.Id
left join salesforce.certification__c sc on sc.Primary_Certification__c = c.Id
left join salesforce.work_package__c wp on wp.Site_Certification__c = sc.Id
left join salesforce.work_item__c wi on wi.Work_Package__c = wp.Id
where 
o.Business_1__c='Australia'
and o.CloseDate >= '2013-01-01' and o.CloseDate <= '2013-12-31'
and o.Type = 'New Bus-New Client'
and o.StageName = 'Closed Won'
and wi.Status__c in ('Scheduled', 'Scheduled - Offered', 'Confirmed', 'Service change', 'In Progress', 'Submitted', 'Under Review', 'Support', 'Completed') 
and sc.Status__c not in ('Inactive', 'Pending') 
group by o.Id) t on t.OppId = o.Id
where 
o.Business_1__c='Australia'
and o.CloseDate >= '2013-01-01' and o.CloseDate <= '2013-12-31'
limit 100000;

create index work_item_work_package_index on work_item__c(work_package__c);
create index work_package_site_cert_index on work_package__c(Site_Certification__c);
#explain
select 
o.Id as 'OppId', 
o.Type as 'OppType',
o.closeDate as 'OppCloseDate',
date_format(o.closeDate, '%Y %m') as 'OppClosePeriod',
c.Id as 'CertificationId',
c.Status__c as 'CertStatus',
sc.Id as 'SiteCertId',
sc.Status__c as 'SiteCertStatus',
wi.IsDeleted as 'WorkItemDeleted',
wi.Id as 'WorkItemId',
wi.Work_Item_Stage__c,
if (wi.Work_Item_Date__c is null, '2099-01-01',wi.Work_Item_Date__c) as 'Work_Item_Date__c',
wi.Status__c,
datediff(if (wi.Work_Item_Date__c is null, '2099-01-01',wi.Work_Item_Date__c), o.CloseDate) as 'OppClosedToWorkItemStart(Days)',
round(datediff(if (wi.Work_Item_Date__c is null, '2099-01-01',wi.Work_Item_Date__c), o.CloseDate)/7) as 'OppClosedToWorkItemStart(Weeks)',
round(datediff(if (wi.Work_Item_Date__c is null, '2099-01-01',wi.Work_Item_Date__c), o.CloseDate)/30) as 'OppClosedToWorkItemStart(Months)',
if (wi.Status__c in ('Open', 'Service change'), 'Open', if (wi.Status__c like 'Schedule%' or wi.Status__c = 'Confirmed', 'Scheduled/Confirmed', 'Completed')) as 'SimpleStatus' 
from salesforce.opportunity o 
left join salesforce.certification__c c on c.Opportunity_Created_From__c = o.Id
left join salesforce.certification__c sc on sc.Primary_Certification__c = c.Id
left join salesforce.work_package__c wp on wp.Site_Certification__c = sc.Id
left join salesforce.work_item__c wi on wi.Work_Package__c = wp.Id
where 
o.Business_1__c='Australia'
and o.CloseDate >= '2013-01-01' 
and o.CloseDate <= '2014-06-30'
#and o.Type = 'New Bus-New Client'
and o.StageName = 'Closed Won'
#and wi.Status__c in ('Scheduled', 'Scheduled - Offered', 'Confirmed', 'Service change', 'In Progress', 'Submitted', 'Under Review', 'Support', 'Completed') 
and sc.Status__c not in ('Inactive', 'Pending')
order by o.Id, c.Id, sc.Id, `Work_Item_Date__c`
limit 10000000;