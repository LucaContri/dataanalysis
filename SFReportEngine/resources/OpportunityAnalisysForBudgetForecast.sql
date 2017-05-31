# Opportunity broken down by type - including opportunities by client segmentation / client complexity
# Timeframe from opportunity closed/won to audit days across all cert all sites
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
o2.OppDays as 'OppDays',
a.Name as 'Client', 
a.Client_Segmentation__c as 'Client Segmentation',
a.Scheduling_Complexity__c as 'Scheduling Complexity',
t.*,
t.WorkItemDays/o2.OppDays as 'PercentageDone/Scheduled'
#t.CertificationsCount as 'Certifications Count',
#t.SitesCount as 'Sites Count',
#t.WorkItemsCount as 'Work Items Count',
#t.FirstGapWorkItemStartDate as 'First Gap Work Item Start Date',
#t.FirstStage1WorkItemStartDate as 'First Stage1 Work Item Start Date',
#t.FirstWorkItemStartDate as 'First Work Item Start Date',
#t.OpportunityClosedToFirstWorkItemStartDays as 'Opportunity Closed to First Work Item Start (Days)',
#t.OpportunityClosedToFirstWorkItemStartWeeks as 'Opportunity Closed to First Work Item Start (Weeks)'
from salesforce.opportunity o 
inner join salesforce.user u on o.OwnerId = u.Id
inner join salesforce.account a on o.AccountId = a.Id
#left join salesforce.opportunitylineitem oli on oli.OpportunityId = o.Id
inner join (
select
o.Id as 'OppId',
sum(oli.Days__c) as 'OppDays'
from salesforce.opportunity o 
left join salesforce.opportunitylineitem oli on oli.OpportunityId = o.Id
where 
o.Business_1__c='Australia'
and o.CloseDate >= '2013-01-01' and o.CloseDate <= '2013-12-31'
and o.Type = 'New Bus-New Client'
and o.StageName = 'Closed Won'
group by o.Id) o2 on o2.OppId = o.Id
inner join (
select 
o.Id as 'OppId', 
c.Id as 'CertId',
c.Name as 'CertName',
sc.Client_Site_NOLINK__c as 'ClientSite',
wi.Id as 'WorkItemId',
wi.Name as 'WorkItemName',
wi.Status__c as 'WorkItemStatus',
wi.Required_Duration__c/8 as 'WorkItemDays',
datediff(wi.Work_Item_Date__c, o.CloseDate) as 'OpportunityClosedToWorkItemStartDays',
round(datediff(wi.Work_Item_Date__c, o.CloseDate)/7,0) as 'OpportunityClosedToWorkItemStartWeeks'
#count(distinct c.Id) as 'CertificationsCount',
#count(distinct sc.Client_Site_NOLINK__c) as 'SitesCount',
#count(wi.Id) as 'WorkItemsCount',
#min(if (wi.Work_Item_Stage__c='Gap', wi.Work_Item_Date__c, null)) as 'FirstGapWorkItemStartDate',
#min(if (wi.Work_Item_Stage__c='Stage 1', wi.Work_Item_Date__c, null)) as 'FirstStage1WorkItemStartDate',
#min(wi.Work_Item_Date__c) as 'FirstWorkItemStartDate',
#datediff(min(wi.Work_Item_Date__c), o.CloseDate) as 'OpportunityClosedToFirstWorkItemStartDays',
#round(datediff(min(wi.Work_Item_Date__c), o.CloseDate)/7,0) as 'OpportunityClosedToFirstWorkItemStartWeeks'
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
and wi.Status__c in ('Open', 'Scheduled', 'Scheduled - Offered', 'Confirmed', 'Service change', 'In Progress', 'Submitted', 'Under Review', 'Support', 'Completed') 
and sc.Status__c not in ('Inactive', 'Pending') 
and wp.Type__c = 'Initial'
#group by o.Id
) t on t.OppId = o.Id
where 
o.Business_1__c='Australia'
and o.CloseDate >= '2013-01-01' and o.CloseDate <= '2013-12-31'
and o.Type = 'New Bus-New Client'
and o.StageName = 'Closed Won'
#group by o.Id
limit 100000;

# Total New Business/ New Client Opp closed/won Days with link to Certification
select sum(if(o2.linkWithCert=1, o1.OppDays,0)) from
(select
o.Id,
sum(oli.Days__c) as 'OppDays'
from salesforce.opportunity o 
left join salesforce.opportunitylineitem oli on oli.OpportunityId = o.Id
where 
o.Business_1__c='Australia'
and o.CloseDate >= '2013-01-01' and o.CloseDate <= '2013-12-31'
and o.Type = 'New Bus-New Client'
and o.StageName = 'Closed Won') o1
left join 
(select o.Id, if(c.Id is null,0,1) as 'linkWithCert' 
from salesforce.opportunity o 
left join salesforce.certification__c c on c.Opportunity_Created_From__c = o.Id
where 
o.Business_1__c='Australia'
and o.CloseDate >= '2013-01-01' and o.CloseDate <= '2013-12-31'
and o.Type = 'New Bus-New Client'
and o.StageName = 'Closed Won') o2 on o1.Id=o2.Id;

select
sum(oli.Days__c) as 'OppDays',
sum(oli.TotalPrice) as 'OppRevenues'

from salesforce.opportunity o 
left join salesforce.opportunitylineitem oli on oli.OpportunityId = o.Id
where 
o.Business_1__c='Australia'
and o.CloseDate >= '2013-01-01' and o.CloseDate <= '2013-12-31'
and o.Type = 'New Bus-New Client'
and o.StageName = 'Closed Won'
and oli.Status__c = 'Active'