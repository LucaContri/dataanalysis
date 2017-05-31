use salesforce;

create index opportunity_history_index on opportunityfieldhistory(OpportunityId);
create index opportunitylineitem_index on opportunitylineitem(OpportunityId);
create index opportunitylineitem_standard_index on opportunitylineitem(Standard__c);
create index standard_program_index on standard__c(Program__c);

create or replace view Enlighten_Admin_New_Business_WIP as
select o.Id, group_concat(distinct p.Business_Line__c) as 'Business Lines'
from opportunity o 
left join opportunitylineitem oli on oli.OpportunityId = o.Id
left join standard__c s on oli.Standard__c = s.Id
left join program__c p on s.Program__c = p.Id
where
o.StageName = 'Closed Won'
and o.Manual_Certification_Finalised__c = 0
and o.Delivery_Strategy_Created__c is null
and o.Business_1__c = 'Australia'
and o.CloseDate >= '2012-09-07'
group by o.Id
union
select o.Id, group_concat(distinct p.Business_Line__c) as 'Business Lines'
from opportunity o 
left join opportunitylineitem oli on oli.OpportunityId = o.Id
left join standard__c s on oli.Standard__c = s.Id
left join program__c p on s.Program__c = p.Id
where
o.StageName = 'Negotiation/Review'
and o.Manual_Certification_Finalised__c = 0
and o.Business_1__c = 'Product Services'
and o.CloseDate >= '2012-09-07'
group by o.Id;

create or replace view Enlighten_Admin_ARG_WIP as
SELECT 
	`analytics`.`sla_arg_v2`.`Id` AS `Id`,
	`analytics`.`sla_arg_v2`.`Standards` AS `PrimaryStandards`,
	`analytics`.`sla_arg_v2`.`Region` AS `Business Lines`
FROM
	`analytics`.`sla_arg_v2`
WHERE
	`analytics`.`sla_arg_v2`.`Metric` = 'ARG Completion/Hold'
	AND ISNULL(`analytics`.`sla_arg_v2`.`To`)
	AND `analytics`.`sla_arg_v2`.`Region` LIKE 'AUS%'
GROUP BY `analytics`.`sla_arg_v2`.`Id`;

create or replace view Enlighten_Admin_WIP as
select 'Admin' as 'Team', 'New Business' as 'Activity',`Details` as 'Stream', count(nb.Id) as 'WIP', date_format(now(), '%d/%m/%Y') as 'Date/Time' 
from analytics.sla_admin_newbusiness nb
where nb.`To` is null 
and nb.`from` > '2014'
and nb.`Region` in ('Australia','Product Services')
group by `Activity`,`Stream`
union
select 'Admin' as 'Team', 'New Business - Cert' as 'Activity2',`Details` as 'Stream2', count(distinct ocsp.Id) as 'WIP', date_format(now(), '%d/%m/%Y') as 'Date/Time' 
from analytics.sla_admin_newbusiness nb
left join salesforce.opportunity_certification__c oc on oc.Opportunity__c = nb.Id and oc.IsDeleted = 0
left join salesforce.oppty_cert_standard_program__c ocsp on ocsp.Opportunity_Certification__c = oc.Id and ocsp.IsDeleted = 0
where nb.`To` is null 
and nb.`from` > '2014'
and nb.`Region` in ('Australia','Product Services')
group by `Activity2`,`Stream2`
union
select 'Admin' as 'Team', 'ARG' as 'Activity3',  
if(arg.`Business Lines` like '%Food%', 'Food', if(arg.`Business Lines` like '%Product%', 'PS','MS')) as 'Stream3', count(arg.`Id`) as 'WIP',  date_format(now(), '%d/%m/%Y') as 'Date/Time'
from Enlighten_Admin_ARG_WIP arg
group by `Activity3`,`Stream3`;

select `Team`, `Activity`, sum(`WIP`) as 'WIP', `Date/Time` 
from salesforce.Enlighten_Admin_WIP
group by `Team`, `Activity`; 


select 
`Stream`,
sum(if (`Activity` = 'New Business', `WIP`, 0)) as 'New Business',
sum(if (`Activity` = 'ARG', `WIP`, 0)) as 'ARG'
from Enlighten_Admin_WIP
group by `Stream`;

select * from Enlighten_Admin_ARG_WIP;
# Activities
#Registration and Confirmation Email
select 
'Admin' as 'Team',
u.Name as 'User',
'Registration' as 'Activity',
count(distinct r.Id) as 'Completed',
now() as 'EditDate'
from training.registration__c r
inner join training.registration__history rh on rh.ParentId = r.Id
inner join training.User u on rh.CreatedById= u.Id
where rh.Field = 'Status__c'
and rh.NewValue = 'Confirmed'
#and date_format(date_Add(rh.CreatedDate, interval 9 hour), '%Y-%m-%d') = date_format(now(), '%Y-%m-%d')
and rh.CreatedDate<=utc_timestamp()
and rh.CreatedDate>date_add(utc_timestamp(), interval -1 day)
group by `Team`, `User`,`Activity`;

create or replace view Enlighten_Admin_Completed as
select 'Admin' as 'Team', `Owner` as 'User', 'New Business' as 'Activity', count(nb.Id) as 'Completed', date_format(now(), '%d/%m/%Y') as 'Date/Time', group_concat(distinct nb.Id) as 'Notes' 
from analytics.sla_admin_newbusiness nb
where `To`> date_add(utc_timestamp(), interval -1 day)
group by `Team`, `User`, `Activity`
union
select 'Admin' as 'Team2', `Owner` as 'User2', 'New Business - Cert' as 'Activity2', count(distinct ocsp.Id) as 'Completed', date_format(now(), '%d/%m/%Y') as 'Date/Time', group_concat(distinct nb.Id) as 'Notes' 
from analytics.sla_admin_newbusiness nb
left join salesforce.opportunity_certification__c oc on oc.Opportunity__c = nb.Id and oc.IsDeleted = 0
left join salesforce.oppty_cert_standard_program__c ocsp on ocsp.Opportunity_Certification__c = oc.Id and ocsp.IsDeleted = 0
where `To`> date_add(utc_timestamp(), interval -1 day)
group by `Team2`, `User2`, `Activity2`;

select 'Admin' as 'Team', `Owner` as 'User', 'New Business - Cert' as 'Activity', ocsp.Id as 'Completed', date_format(now(), '%d/%m/%Y') as 'Date/Time', nb.Id as 'Notes' 
from analytics.sla_admin_newbusiness nb
left join salesforce.opportunity_certification__c oc on oc.Opportunity__c = nb.Id and oc.IsDeleted = 0
left join salesforce.oppty_cert_standard_program__c ocsp on ocsp.Opportunity_Certification__c = oc.Id and ocsp.IsDeleted = 0
where `To`> date_add(utc_timestamp(), interval -1 day)
and nb.Id='006d000000gWlhpAAC'
group by nb.Id;

select * from Enlighten_Admin_Completed;

select *, date_add(`To`, interval 10 hour) from analytics.sla_admin_newbusiness 
where date_format(date_add(`To`, interval 11 hour), '%Y-%m-%d') = '2015-04-21';

select * from analytics.sla_admin_newbusiness where `To` is null and `from` > '2014';
