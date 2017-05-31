use salesforce;

select * from sf_tables where TableName like '%Admini%';

select count(*) from Change_Request2__c;

# Questions:
#	1) Who creates a CR? Auditor? CA? Both? Anyone else?
# 	2) When does a cr become actionable for CS Admin? When it is created? When it is Submitted? When ARG approved.
#	3) When is a CR submitted?  When the WI is submitted?
#	4) When is a change request completed?  When the status is completed?  Can we use last modified as a proxy?
#	5) Who is the owner of the CR? How are they allocated to CS Admin team members?
#	6) How can CSC Administrator be null on a completed CR? (e.g. https://c.na14.visual.force.com/a3Ld0000000HjuxEAC)

#backlog
create or replace view analytics.change_request_backlog_sub_old as
select 
'CS Administration' as 'Team', 
'Change Request' as 'Activity', 
null as 'Details', 
cr.Administration_Group_Name__c as 'Region',
site.Time_Zone__c as 'TimeZone',
'Change Request' as 'Id Type',
cr.Id as 'Id',
cr.Name as 'Name',
arg.Id,
null as 'Owner',
'From ARG CA Approved' as 'Aging Type',
if(group_concat(ah.comments__c) like '%Auto Approved%', arg.First_Submitted__c, arg.CA_Approved__c) as 'From',
analytics.getSLADueUTCTimestamp(
	if(group_concat(ah.comments__c) like '%Auto Approved%', arg.First_Submitted__c, arg.CA_Approved__c), 
    site.Time_Zone__c, 3) as 'SLA Due',
null as 'To',
null as 'Tags'
from salesforce.Change_Request2__c cr 
inner join salesforce.Work_Item__c wi on cr.Work_Item__c = wi.Id
inner join salesforce.work_package__c wp on wi.Work_Package__c = wp.Id
inner join salesforce.certification__c sc on wp.Site_Certification__c = sc.Id
inner join salesforce.account site on sc.Primary_client__c = site.Id
inner join salesforce.arg_work_item__c argwi on argwi.RWork_Item__c = wi.Id
inner join salesforce.audit_report_group__c arg on argwi.RAudit_Report_Group__c = arg.Id
left join salesforce.approval_history__c ah on ah.RAudit_Report_Group__c = arg.Id
inner join salesforce.user u on cr.LastModifiedById = u.Id
where 
cr.CSC_administrator__c  is null
and argwi.IsDeleted=0
and cr.Status__c in ('Submitted')
and cr.IsDeleted = 0
and wi.IsDeleted = 0
group by cr.ID;

create or replace view analytics.change_request_backlog_sub as
select 
'CS Administration' as 'Team', 
'Change Request' as 'Activity', 
null as 'Details', 
cr.Administration_Group_Name__c as 'Region',
wi.Client_Ownership__c,
site.Time_Zone__c as 'TimeZone',
'Change Request' as 'Id Type',
cr.Id as 'Id',
cr.Name as 'Name',
null as 'Owner',
'From WI Completed' as 'Aging Type',
wi.Work_Item_Completed_Date__c as 'From',
analytics.getSLADueUTCTimestamp(
	wi.Work_Item_Completed_Date__c, 
    site.Time_Zone__c, 5) as 'SLA Due',
null as 'To',
null as 'Tags'
from salesforce.Change_Request2__c cr 
inner join salesforce.Work_Item__c wi on cr.Work_Item__c = wi.Id
inner join salesforce.work_package__c wp on wi.Work_Package__c = wp.Id
inner join salesforce.certification__c sc on wp.Site_Certification__c = sc.Id
inner join salesforce.account site on sc.Primary_client__c = site.Id
where 
cr.Status__c in ('Open','Submitted')
and cr.IsDeleted = 0
and wi.IsDeleted = 0
and wi.Status__c in ('Completed');

(select * from analytics.change_request_backlog_sub t where t.`From` is not null and t.`Region` in ('Asia-China'));

#Completed
create or replace view analytics.change_request_completed_sub_old as
select 
'CS Administration' as 'Team', 
'Change Request' as 'Activity', 
null as 'Details', 
cr.Administration_Group_Name__c as 'Region',
site.Time_Zone__c as 'TimeZone',
'Change Request' as 'Id Type',
cr.Id as 'Id',
cr.Name as 'Name',
u.Name as 'Owner',
'From ARG CA Approved' as 'Aging Type',
if(group_concat(ah.comments__c) like '%Auto Approved%', arg.First_Submitted__c, arg.CA_Approved__c) as 'From',
analytics.getSLADueUTCTimestamp(
	if(group_concat(ah.comments__c) like '%Auto Approved%', arg.First_Submitted__c, arg.CA_Approved__c), 
    site.Time_Zone__c, 3) as 'SLA Due',
cr.LastModifiedDate as 'To',
null as 'Tags'
from salesforce.Change_Request2__c cr 
inner join salesforce.Work_Item__c wi on cr.Work_Item__c = wi.Id
inner join salesforce.work_package__c wp on wi.Work_Package__c = wp.Id
inner join salesforce.certification__c sc on wp.Site_Certification__c = sc.Id
inner join salesforce.account site on sc.Primary_client__c = site.Id
inner join salesforce.arg_work_item__c argwi on argwi.RWork_Item__c = wi.Id
inner join salesforce.audit_report_group__c arg on argwi.RAudit_Report_Group__c = arg.Id
left join salesforce.approval_history__c ah on ah.RAudit_Report_Group__c = arg.Id
inner join salesforce.user u on cr.LastModifiedById = u.Id
where 
cr.CSC_administrator__c  is null
and argwi.IsDeleted=0
and cr.Status__c in ('Completed')
and cr.IsDeleted = 0
and wi.IsDeleted = 0
group by cr.ID;

create or replace view analytics.change_request_completed_sub as
select 
'CS Administration' as 'Team', 
'Change Request' as 'Activity', 
null as 'Details', 
cr.Administration_Group_Name__c as 'Region',
site.Time_Zone__c as 'TimeZone',
'Change Request' as 'Id Type',
cr.Id as 'Id',
cr.Name as 'Name',
u.Name as 'Owner',
'From WI Completed' as 'Aging Type',
wi.Work_Item_Completed_Date__c as 'From',
analytics.getSLADueUTCTimestamp(
	wi.Work_Item_Completed_Date__c, 
    site.Time_Zone__c, 5) as 'SLA Due',
cr.LastModifiedDate as 'To',
null as 'Tags'
from salesforce.Change_Request2__c cr 
inner join salesforce.Work_Item__c wi on cr.Work_Item__c = wi.Id
inner join salesforce.work_package__c wp on wi.Work_Package__c = wp.Id
inner join salesforce.certification__c sc on wp.Site_Certification__c = sc.Id
inner join salesforce.account site on sc.Primary_client__c = site.Id
inner join salesforce.arg_work_item__c argwi on argwi.RWork_Item__c = wi.Id
inner join salesforce.audit_report_group__c arg on argwi.RAudit_Report_Group__c = arg.Id
inner join salesforce.approval_history__c ah on ah.RAudit_Report_Group__c = arg.Id
inner join salesforce.user u on cr.LastModifiedById = u.Id
where 
argwi.IsDeleted=0
and cr.Status__c in ('Completed')
and ah.comments__c like '%Auto Approved%'
and cr.IsDeleted = 0
and wi.IsDeleted = 0
group by cr.ID;

select * from analytics.change_request_completed_sub t 
where t.`To` >= '2015-07-01'
and t.`To` <= '';

# Lapsed Certification over 30 Days.
create or replace view analytics.lapsed_certifications as
select 
'CS Administration' as 'Team', 
'Lapsed Certifications' as 'Activity', 
null as 'TimeZone',
null as 'Details', 
ao.Name as 'Region',
'Certification Standard' as 'Id Type',
csp.Id as 'Id',
csp.Name as 'Name',
null as 'Owner',
'From Licence Expired' as 'Aging Type',
csp.Expires__c as 'From',
date_add(csp.Expires__c, interval 30 day) as 'SLA Due',
null as 'To',
null as 'Tags'
from
salesforce.certification_standard_program__c csp
inner join salesforce.administration_group__c ao on csp.Administration_Ownership__c = ao.Id
where csp.Status__c in ('Applicant', 'Registered', 'Under Suspension', 'Customised', 'On Hold')
and csp.Expires__c <= utc_timestamp()
group by csp.Id;
and ao.Name in @regions;