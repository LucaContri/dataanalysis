#Certifications
use salesforce;
#select 'Sales' as 'Team', 'Qualify Lead' as 'WIP', 'Web To Lead - Cert' as 'Details', 'Lead' as 'Id Type', l.Id as 'Id', 'Lead Created Date' as 'Aging Type', l.CreatedDate as 'From', datediff(now(), l.CreatedDate) as 'Aging', 5 as 'unit time (min)'
# Sub Views
create or replace view enlighten_sales_riskass_sub_view as 
select 
'Sales' as 'Team', 'Risk Assessment' as 'WIP', 'Risk Assessment' as 'Details', 'Sales-10' as 'Enlighten Activity Code', 'Opportunity' as 'Id Type', o.Id as 'Id', u.Name as 'Owner', 'Opportunity Created Date' as 'Aging Type', o.CreatedDate as 'From', datediff(utc_timestamp(), o.CreatedDate) as 'Aging', 10 as 'unit time (min)',
if(group_concat(distinct s.Name) like '%18001%' or group_concat(distinct s.Name) like '%4801%' or group_concat(distinct s.Name) like '%14001%', 1,0) as 'RiskAssessment'
from salesforce.opportunity o 
left join salesforce.opportunity_certification__c oc on oc.Opportunity__c = o.Id
left join salesforce.Oppty_Cert_Standard_Program__c osc on osc.Opportunity_Certification__c = oc.Id
left join salesforce.standard_program__c sp on sp.Id = osc.Standard_Program__c
left join salesforce.standard__c s on s.Id = sp.Standard__c
left join user u on u.Id = o.OwnerId
where o.StageName in ('Sales Duration Review')
and o.IsDeleted=0
and o.Business_1__c='Australia'
group by o.Id;

create or replace view enlighten_sales_riskass_view as 
select t.`Team`, t.`WIP`, t.`Details`, t.`Enlighten Activity Code`, t.`Id Type`, t.`Id`, t.`Owner`, t.`Aging Type`, t.`From`, t.`Aging`, t.`unit time (min)` from enlighten_sales_riskass_sub_view t where t.`RiskAssessment` = 1;

create or replace view enlighten_sales_proposal_sub_view as
select 
'Sales' as 'Team', 
if(o.Number_of_Sites__c >= 4 or count(distinct sp.Id)>=3, 'Proposal & CR - Complex','Proposal & CR - Simple') as 'WIP', 
if(o.Number_of_Sites__c >= 4 or count(distinct sp.Id)>=3, 'Proposal & CR - Complex','Proposal & CR - Simple') as 'Details', 
if(o.Number_of_Sites__c >= 4 or count(distinct sp.Id)>=3, 'Sales-22','Sales-21') as 'Enlighten Activity Code', 
'Opportunity' as 'Id Type', o.Id as 'Id', u.Name as 'Owner', 'Opportunity Created Date' as 'Aging Type', o.CreatedDate as 'From', datediff(utc_timestamp(), o.CreatedDate) as 'Aging', 
if(o.Number_of_Sites__c >= 4 or count(distinct sp.Id)>=3, 300,120) as 'unit time (min)'
from salesforce.opportunity o 
left join salesforce.opportunity_certification__c oc on oc.Opportunity__c = o.Id
left join salesforce.Oppty_Cert_Standard_Program__c osc on osc.Opportunity_Certification__c = oc.Id
left join salesforce.standard_program__c sp on sp.Id = osc.Standard_Program__c
left join salesforce.standard__c s on s.Id = sp.Standard__c
left join user u on u.Id = o.OwnerId
where o.StageName in ('Sales Duration Review')
and o.IsDeleted=0
and o.Business_1__c='Australia'
group by o.Id;

create or replace view enlighten_sales_qualify_lead_cert as
select 'Sales' as 'Team', 'Qualify Lead' as 'WIP', 'Qualify Lead - Cert' as 'Details', 
'Sales-02' as 'Enlighten Activity Code', 'Lead' as 'Id Type', l.Id as 'Id', u.Name as 'Owner', 'Lead Created Date' as 'Aging Type', l.CreatedDate as 'From', datediff(utc_timestamp(), l.CreatedDate) as 'Aging', 5 as 'unit time (min)'
from salesforce.Lead l 
inner join salesforce.User cb on cb.Id = l.CreatedById
inner join salesforce.User o on o.Id = l.OwnerId
inner join  salesforce.RecordType rt on rt.Id = l.RecordTypeId
left join user u on u.Id = l.OwnerId
where l.IsDeleted = 0
and l.Status like '%Unqualified%'
#and cb.Name = 'Castiron User'
and rt.Name = 'AUS - Lead'
and l.Business__c = 'Australia'
and l.CreatedDate>='2014-07-01';

create or replace view enlighten_sales_qualify_lead_tis as
select 'Sales' as 'Team', 'Qualify Lead' as 'WIP', 'Qualify Lead - TIS' as 'Details', 
'Sales-02' as 'Enlighten Activity Code', 'Lead' as 'Id Type', l.Id as 'Id', u.Name as 'Owner', 'Lead Created Date' as 'Aging Type', l.CreatedDate as 'From', datediff(utc_timestamp(), l.CreatedDate) as 'Aging', 5 as 'unit time (min)'
from training.Lead l 
inner join training.User cb on cb.Id = l.CreatedById
inner join  training.RecordType rt on rt.Id = l.RecordTypeId
left join training.user u on u.Id = l.OwnerId
where l.IsDeleted = 0
and l.Status like '%Unqualified%'
#and cb.Name = 'Castiron User'
and rt.Name = 'TIS APAC Lead Record Type'
and l.CreatedDate>='2014-07-01'
and l.OwnerId not like '00G20000000vzaCEAQ'; # This is the Marketiing Queue: https://emea.salesforce.com/p/own/Queue/d?id=00G20000000vzaC

create or replace view enlighten_sales_qualify_lead as 
select * from enlighten_sales_qualify_lead_cert
union
select * from enlighten_sales_qualify_lead_tis;

select * from enlighten_sales_qualify_lead_tis limit 1000000;

create or replace view enlighten_sales_lead_followup_cert as
select 'Sales' as 'Team', 'Lead / Opp Follow Up' as 'WIP', 'Lead Follow Up - Cert' as 'Details', 
'Sales-04' as 'Enlighten Activity Code', 'Task' as 'Id Type', t.Id as 'Id', u.Name as 'Owner', 'Last Task Modified Date' as 'Aging Type', max(t.LastModifiedDate) as 'From', datediff(utc_timestamp(), max(t.LastModifiedDate)) as 'Aging', 4 as 'unit time (min)'
from salesforce.task t
inner join salesforce.lead l on t.WhoId = l.Id
inner join  salesforce.RecordType rt on rt.Id = l.RecordTypeId
left join user u on u.Id = t.OwnerId
where t.Status in ('Deferred','In Progress','Not Started')
and t.IsDeleted=0
and l.IsDeleted=0
and rt.Name = 'AUS - Lead'
and l.Business__c = 'Australia'
and t.CreatedDate>='2014-07-01'
group by t.Id;

create or replace view enlighten_sales_opp_followup_cert as
select 'Sales' as 'Team', 'Lead / Opp Follow Up' as 'WIP', 'Opp Follow Up - Cert' as 'Details', 
'Sales-04' as 'Enlighten Activity Code', 'Task' as 'Id Type', t.Id as 'Id', u.Name as 'Owner', 'Last Task Modified Date' as 'Aging Type', max(t.LastModifiedDate) as 'From', datediff(utc_timestamp(), max(t.LastModifiedDate)) as 'Aging', 4 as 'unit time (min)'
from salesforce.task t
inner join salesforce.opportunity o on t.WhatId = o.Id
left join user u on u.Id = t.OwnerId
where t.Status in ('Deferred','In Progress','Not Started')
and t.IsDeleted=0
and o.IsDeleted=0
and o.Business_1__c='Australia'
group by t.Id;

create or replace view enlighten_sales_lead_followup_tis as
select 'Sales' as 'Team', 'Lead / Opp Follow Up' as 'WIP', 'Lead Follow Up - TIS' as 'Details', 
'Sales-04' as 'Enlighten Activity Code', 'Task' as 'Id Type', t.Id as 'Id', u.Name as 'Owner', 'Last Task Modified Date' as 'Aging Type', max(t.LastModifiedDate) as 'From', datediff(utc_timestamp(), max(t.LastModifiedDate)) as 'Aging', 4 as 'unit time (min)'
from training.task t
inner join training.lead l on t.WhoId = l.Id
inner join  training.RecordType rt on rt.Id = l.RecordTypeId
left join training.user u on u.Id = t.OwnerId
where t.Status in ('Deferred','In Progress','Not Started')
and t.IsDeleted=0
and l.IsDeleted=0
and rt.Name in ('TIS APAC Lead Record Type','ENT - APAC - Lead (Web)','ENT - APAC - Lead (Marketing)','ENT - APAC - Lead (IH)','ENT - APAC - Lead (EOI)')
and t.CreatedDate>='2014-07-01'
group by t.Id;

create or replace view enlighten_sales_opp_followup_tis as
select 'Sales' as 'Team', 'Lead / Opp Follow Up' as 'WIP', 'Opp Follow Up - TIS' as 'Details', 
'Sales-04' as 'Enlighten Activity Code', 'Task' as 'Id Type', t.Id as 'Id', if (o.BDM_picklist__c is null, u.Name, o.BDM_picklist__c) as 'Owner', 'Last Task Modified Date' as 'Aging Type', max(t.LastModifiedDate) as 'From', datediff(utc_timestamp(), max(t.LastModifiedDate)), 4 as 'unit time (min)'
from training.task t
inner join training.opportunity o on t.WhatId = o.Id
inner join training.recordtype rt on rt.Id = o.RecordTypeId
left join training.user u on u.Id = t.OwnerId#o.BDM__c
where t.Status in ('Deferred','In Progress','Not Started')
and t.IsDeleted=0
and o.IsDeleted=0
and rt.Name in ('ENT - APAC - Opportunity (In House)','ENT - APAC - Opportunity (Marketing)','ENT - APAC - Opportunity (Public)')
group by t.Id;

# Summary view
create or replace view enlighten_sales_wip as
(select t.`Team`, t.`WIP`, t.`Details`, count(t.`Id`) as 'Value' from enlighten_sales_qualify_lead_cert t group by t.`WIP`)
UNION 
(select t.`Team`, t.`WIP`, t.`Details`, count(t.`Id`) as 'Value' from enlighten_sales_qualify_lead_tis t group by t.`WIP`)
UNION
(select t.`Team`, t.`WIP`, t.`Details`, count(t.`Id`) as 'Value' from enlighten_sales_lead_followup_cert t group by t.`WIP`) 
UNION 
(select t.`Team`, t.`WIP`, t.`Details`, count(t.`Id`) as 'Value' from enlighten_sales_opp_followup_cert t group by t.`WIP`)
union
(select t.`Team`, t.`WIP`, t.`Details`, count(t.`Id`) as 'Value' from enlighten_sales_proposal_sub_view t group by t.`WIP`)
UNION 
(select t.`Team`, t.`WIP`, t.`Details`, count(t.`Id`) as 'Value' from enlighten_sales_riskass_view t group by t.`WIP`)
union
(select t.`Team`, t.`WIP`, t.`Details`, count(t.`Id`) as 'Value' from enlighten_sales_lead_followup_tis t group by t.`WIP`)
union
(select t.`Team`, t.`WIP`, t.`Details`, count(t.`Id`) as 'Value' from enlighten_sales_opp_followup_tis t group by t.`WIP`);

# Exceptions (over SLA) Details
(select *, date_add(`From`, interval 1 day) as 'KPI Due Date', if(Aging > 1, 'true', 'false') as 'Over KPI' from enlighten_sales_qualify_lead_cert) UNION 
(select *, date_add(`From`, interval 1 day) as 'KPI Due Date', if(Aging > 1, 'true', 'false') as 'Over KPI' from enlighten_sales_qualify_lead_tis) UNION 
(select wip.*, t.ActivityDate as 'KPI Due Date', if(t.ActivityDate < now(), 'true', 'false') as 'Over KPI' from enlighten_sales_lead_followup_cert wip inner join salesforce.task t on wip.Id = t.Id) UNION 
(select wip.*, t.ActivityDate as 'KPI Due Date', if(t.ActivityDate < now(), 'true', 'false') as 'Over KPI' from enlighten_sales_opp_followup_cert wip inner join salesforce.task t on wip.Id = t.Id) UNION 
(select *, date_add(`From`, interval if(Details='Proposal & CR - Simple', 2,5) day) as 'KPI Due Date', if((Details='Proposal & CR - Simple' and Aging > 2) or (Details='Proposal & CR - Complex' and Aging > 5), 'true', 'false') as 'Over KPI' from enlighten_sales_proposal_sub_view ) UNION 
(select *, date_add(`From`, interval 1 day) as 'KPI Due Date', if(Aging > 1, 'true', 'false') as 'Over KPI' from enlighten_sales_riskass_view) UNION 
(select wip.*, t.ActivityDate as 'KPI Due Date', if(t.ActivityDate < now(), 'true', 'false') as 'Over KPI' from enlighten_sales_lead_followup_tis wip inner join training.task t on wip.Id = t.Id) UNION 
(select wip.*, t.ActivityDate as 'KPI Due Date', if(t.ActivityDate < now(), 'true', 'false') as 'Over KPI' from enlighten_sales_opp_followup_tis wip inner join training.task t on wip.Id = t.Id);

# Exceptions (over SLA) Summary
select Owner, 
count(distinct if (t.`Details`='Qualify Lead - Cert' or t.`Details`='Qualify Lead - TIS', t.`Id`, null)) as 'Qualify Lead',
count(distinct if ((t.`Details`='Qualify Lead - Cert' or t.`Details`='Qualify Lead - TIS') and t.`SLA Due Date` < utc_timestamp(), t.`Id`, null)) as 'Qualify Lead - Over SLA',
count(distinct if (t.`Details`='Lead Follow Up - TIS' or t.`Details`='Lead Follow Up - Cert', t.`Id`, null)) as 'Lead Follow Up',
count(distinct if ((t.`Details`='Lead Follow Up - TIS' or t.`Details`='Lead Follow Up - Cert') and t.`SLA Due Date` < utc_timestamp(), t.`Id`, null)) as 'Lead Follow Up - Over SLA',
count(distinct if (t.`Details`='Opp Follow Up - Cert' or t.`Details`='Opp Follow Up - TIS', t.`Id`, null)) as 'Opp Follow Up',
count(distinct if ((t.`Details`='Opp Follow Up - Cert' or t.`Details`='Opp Follow Up - TIS') and t.`SLA Due Date` < utc_timestamp(), t.`Id`, null)) as 'Opp Follow Up - Over SLA',
count(distinct if (t.`Details`='Proposal & CR - Complex' or t.`Details`='Proposal & CR - Simple', t.`Id`, null)) as 'Proposal & CR',
count(distinct if ((t.`Details`='Proposal & CR - Complex' or t.`Details`='Proposal & CR - Simple') and t.`SLA Due Date` < utc_timestamp(), t.`Id`, null)) as 'Proposal & CR - Over SLA',
count(distinct if (t.`Details`='Risk Assessment', t.`Id`, null)) as 'Risk Assessment',
count(distinct if (t.`Details`='Risk Assessment' and t.`SLA Due Date` < utc_timestamp(), t.`Id`, null)) as 'Risk Assessment'
from (
(select *, date_add(`From`, interval 1 day) as 'SLA Due Date' from enlighten_sales_qualify_lead_cert) UNION 
(select *, date_add(`From`, interval 1 day) as 'SLA Due Date' from enlighten_sales_qualify_lead_tis) UNION 
(select wip.*, t.ActivityDate as 'SLA Due Date' from enlighten_sales_lead_followup_cert wip inner join salesforce.task t on wip.Id = t.Id ) UNION 
(select wip.*, t.ActivityDate as 'SLA Due Date' from enlighten_sales_opp_followup_cert wip inner join salesforce.task t on wip.Id = t.Id ) UNION 
(select *, date_add(`From`, interval if(Details='Proposal & CR - Simple', 2,5) day) as 'SLA Due Date' from enlighten_sales_proposal_sub_view) UNION 
(select *, date_add(`From`, interval 1 day) as 'SLA Due Date' from enlighten_sales_riskass_view where Aging > 1) UNION 
(select wip.*, t.ActivityDate as 'SLA Due Date' from enlighten_sales_lead_followup_tis wip inner join training.task t on wip.Id = t.Id) UNION 
(select wip.*, t.ActivityDate as 'SLA Due Date' from enlighten_sales_opp_followup_tis wip inner join training.task t on wip.Id = t.Id)) t 
group by t.`Owner`;

#Summary
select * from enlighten_sales_wip;
select t.Team, t.WIP as 'Activity', sum(t.Value) as 'WIP', now() as 'Date/Time' from enlighten_sales_wip t group by t.WIP;

create or replace view enlighten_sales_lead_opp_followup as
(select * from enlighten_sales_lead_followup_tis)
UNION 
(select * from enlighten_sales_opp_followup_tis)
UNION
(select * from enlighten_sales_lead_followup_cert) 
UNION 
(select * from enlighten_sales_opp_followup_cert);

create or replace view enlighten_sales_proposal_simple_view as 
select * from enlighten_sales_proposal_sub_view where `Details` = 'Proposal & CR - Simple';

create or replace view enlighten_sales_proposal_complex_view as 
select * from enlighten_sales_proposal_sub_view where `Details` = 'Proposal & CR - Complex';

# Details view
(select * from enlighten_sales_qualify_lead_cert)
UNION 
(select * from enlighten_sales_qualify_lead_tis)
UNION
(select * from enlighten_sales_lead_followup_cert) 
UNION 
(select * from enlighten_sales_opp_followup_cert)
union
(select * from enlighten_sales_proposal_sub_view)
UNION 
(select * from enlighten_sales_riskass_view)
union
(select * from enlighten_sales_lead_followup_tis)
union
(select * from enlighten_sales_opp_followup_tis);

# Activities

#Sub Views
create or replace view enlighten_sales_riskass_sub_activity as
select cb.Name as 'User', 
if(group_concat(distinct s.Name) like '%18001%' or group_concat(distinct s.Name) like '%4801%' or group_concat(distinct s.Name) like '%14001%', 1,0) as 'RiskAssessment',
if(group_concat(distinct s.Name) like '%18001%' or group_concat(distinct s.Name) like '%4801%' or group_concat(distinct s.Name) like '%14001%', o.Id,null) as 'Id'
from salesforce.opportunity o 
inner join opportunityfieldhistory oh on oh.OpportunityId = o.Id 
inner join user cb on cb.Id = oh.CreatedById
left join salesforce.opportunity_certification__c oc on oc.Opportunity__c = o.Id
left join salesforce.Oppty_Cert_Standard_Program__c osc on osc.Opportunity_Certification__c = oc.Id
left join salesforce.standard_program__c sp on sp.Id = osc.Standard_Program__c
left join salesforce.standard__c s on s.Id = sp.Standard__c
where 
o.IsDeleted=0
and o.Business_1__c='Australia'
and o.Status__c = 'Active' 
and oh.Field = 'StageName'
and oh.NewValue in ('Proposal Sent')
#and date_format(date_add(oh.CreatedDate, INTERVAL 11 HOUR), '%Y-%m-%d') = date_format(now(), '%Y-%m-%d')
and oh.CreatedDate<=utc_timestamp()
and oh.CreatedDate>date_add(utc_timestamp(), interval -1 day)
group by o.Id;

create or replace view enlighten_sales_proposal_sub_activity as
select cb.Name as 'User', 
if(o.Number_of_Sites__c >= 4 or count(distinct sp.Id)>=3, 'Proposal & CR - Complex','Proposal & CR - Simple') as 'Activity', count(distinct o.Id) as 'Count', o.Id as 'Id'
from opportunity o 
inner join opportunityfieldhistory oh on oh.OpportunityId = o.Id 
inner join user cb on cb.Id = oh.CreatedById
left join salesforce.opportunity_certification__c oc on oc.Opportunity__c = o.Id
left join salesforce.Oppty_Cert_Standard_Program__c osc on osc.Opportunity_Certification__c = oc.Id
left join salesforce.standard_program__c sp on sp.Id = osc.Standard_Program__c
where 
o.Business_1__c in ('Australia') 
and o.IsDeleted = 0 
and o.Status__c = 'Active' 
and o.StageName not in ('Budget') 
and oh.Field = 'StageName'
and oh.NewValue in ('Proposal Sent')
#and date_format(date_add(oh.CreatedDate, INTERVAL 11 HOUR), '%Y-%m-%d') = '2015-05-11'  
and oh.CreatedDate<=utc_timestamp()
and oh.CreatedDate>date_add(utc_timestamp(), interval -1 day)
group by o.Id;

create or replace view enlighten_sales_dummy_activities as 
select 'Benjamin Rieck','Proposal & CR - Complex', 0, null
union
select 'Benjamin Rieck','Proposal & CR - Simple', 0, null
union
select 'Benjamin Rieck','Close Won', 0, null
union
select 'Benjamin Rieck','Opportunity Created', 0, null;

create or replace view enlighten_sales_closed_won_activity as
select cb.Name as 'User', 
'Close Won' as 'Activity', 
count(distinct o.Id) as 'Count',
o.Id as 'Id'
from salesforce.opportunity o 
inner join salesforce.opportunityfieldhistory oh on oh.OpportunityId = o.Id 
inner join salesforce.user cb on cb.Id = oh.CreatedById
where 
o.Business_1__c in ('Australia') 
and o.IsDeleted = 0 
and o.Status__c = 'Active' 
and o.StageName not in ('Budget') 
and oh.Field = 'StageName'
and oh.NewValue in ('Closed Won')
#and date_format(date_add(oh.CreatedDate, INTERVAL 11 HOUR), '%Y-%m-%d') = '2015-05-11'  
and oh.CreatedDate<=utc_timestamp()
and oh.CreatedDate>date_add(utc_timestamp(), interval -1 day)
group by o.Id;

# Summary view
create or replace view enlighten_sales_activity as
(select t.User, 'Risk Assessment' as 'Activity', count(t.RiskAssessment) as 'Count', group_concat(distinct t.Id) as 'Notes' 
from enlighten_sales_riskass_sub_activity t
where t.RiskAssessment = 1
group by t.`User`, `Activity`)
union
(select t.`User`, t.`Activity`, sum(t.`Count`) as 'Count', group_concat(distinct t.Id) as 'Notes' from enlighten_sales_proposal_sub_activity t
group by t.`User`, t.`Activity`)
union
(select t.`User`, t.`Activity`, sum(t.`Count`) as 'Count', group_concat(distinct t.Id) as 'Notes' from enlighten_sales_closed_won_activity t
group by t.`User`, t.`Activity`)
union
(select cb.Name as 'User', 'Opportunity Created' as 'Activity', count(distinct o.Id) as 'Count', group_concat(distinct o.Id) as 'Notes'
from opportunity o 
inner join user cb on cb.Id = o.CreatedById
where 
o.Business_1__c in ('Australia') 
and o.IsDeleted = 0 
and o.Status__c = 'Active' 
and o.StageName not in ('Budget') 
#and date_format(date_add(o.CreatedDate, INTERVAL 11 HOUR), '%Y-%m-%d') = date_format(now(), '%Y-%m-%d')#'2014-07-15'  
and o.CreatedDate<=utc_timestamp()
and o.CreatedDate>date_add(utc_timestamp(), interval -1 day)
group by `User`, `Activity`)
union 
(select * from enlighten_sales_dummy_activities);


#Test
select 'Sales' as 'Team', t.User, t.Activity, t.`Count` as 'Completed', date_format(now(), '%d/%m/%Y'), t.Notes  from enlighten_sales_activity t;
select t.Team, t.WIP as 'Activity', sum(t.Value) as 'WIP', date_format(now(), '%d/%m/%Y') as 'Date/Time' from enlighten_sales_wip t group by t.WIP;
select * from enlighten_sales_wip;