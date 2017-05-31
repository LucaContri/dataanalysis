# Risk Assessment
DROP PROCEDURE SlaUpdateSalesRiskAssessmentCompleted;
DELIMITER //
CREATE PROCEDURE SlaUpdateSalesRiskAssessmentCompleted()
 BEGIN
 declare lastUpdate datetime;
 set lastUpdate = (select max(`To`) from analytics.sla_sales_risk_assessment_completed);
 insert into analytics.sla_sales_risk_assessment_completed 
  (select `Team`,`Activity`,`Details`,`Enlighten Activity Code`,`Id Type`,`Id`,`Owner`, `Aging Type`,`From`,`SLA Due`,`To`,`Tags` from (
 select 'Sales' as 'Team',
'Risk Assessment' as 'Activity',
'Risk Assessment' as 'Details',
'Sales-10' as 'Enlighten Activity Code',
'Opportunity' as 'Id Type',
o.Id as 'Id',
cb.Name as 'Owner', 
'Opportunity Created' as 'Aging Type',
o.CreatedDate as 'From',
date_add(o.CreatedDate, interval 1 day) as 'SLA Due',
oh.CreatedDate as 'To',
TIMESTAMPDIFF(DAY,o.CreatedDate, oh.CreatedDate) as 'Aging',
'' as 'Tags',
if(group_concat(distinct s.Name) like '%18001%' or group_concat(distinct s.Name) like '%4801%' or group_concat(distinct s.Name) like '%14001%', 1,0) as 'RiskAssessment'
from salesforce.opportunity o 
inner join salesforce.opportunityfieldhistory oh on oh.OpportunityId = o.Id 
inner join salesforce.user cb on cb.Id = oh.CreatedById
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
and oh.CreatedDate>lastUpdate
group by o.Id) t where t.`RiskAssessment`=1);

insert into analytics.sp_log VALUES(null,'SlaUpdateSalesRiskAssessmentCompleted',utc_timestamp());
 END //
DELIMITER ;

CREATE EVENT SlaUpdateEventSalesRiskAssessmentCompleted
    ON SCHEDULE EVERY 10 minute DO 
		call SlaUpdateSalesRiskAssessmentCompleted();

select * from analytics.sp_log where sp_name = 'SlaUpdateSalesProposalAndCRBacklog' order by exec_time desc limit 5;

DROP PROCEDURE SlaUpdateSalesRiskAssessmentBacklog;
DELIMITER //        
CREATE PROCEDURE SlaUpdateSalesRiskAssessmentBacklog()
 BEGIN
 truncate analytics.sla_sales_risk_assessment_backlog;
 insert into analytics.sla_sales_risk_assessment_backlog (
 select t.`Team`, t.`Activity`, t.`Details`, t.`Enlighten Activity Code`, t.`Id Type`, t.`Id`, t.`Owner`, t.`Aging Type`, t.`From`, t.`SLA Due`, null as 'To', t.`Tags` 
 from (select 
'Sales' as 'Team', 'Risk Assessment' as 'Activity', 'Risk Assessment' as 'Details', 'Sales-10' as 'Enlighten Activity Code', 'Opportunity' as 'Id Type', o.Id as 'Id', u.Name as 'Owner', 'Opportunity Created' as 'Aging Type', o.CreatedDate as 'From', date_add(o.CreatedDate, interval 1 day) as 'SLA Due',
if(group_concat(distinct s.Name) like '%18001%' or group_concat(distinct s.Name) like '%4801%' or group_concat(distinct s.Name) like '%14001%', 1,0) as 'RiskAssessment', null as 'Tags'
from salesforce.opportunity o 
left join salesforce.opportunity_certification__c oc on oc.Opportunity__c = o.Id
left join salesforce.Oppty_Cert_Standard_Program__c osc on osc.Opportunity_Certification__c = oc.Id
left join salesforce.standard_program__c sp on sp.Id = osc.Standard_Program__c
left join salesforce.standard__c s on s.Id = sp.Standard__c
left join salesforce.user u on u.Id = o.OwnerId
where o.StageName in ('Sales Duration Review')
and o.IsDeleted=0
and o.Business_1__c='Australia'
group by o.Id) t 
 where t.`RiskAssessment` = 1);
 
 insert into analytics.sp_log VALUES(null,'SlaUpdateSalesRiskAssessmentBacklog',utc_timestamp());
  END //
DELIMITER ;

CREATE EVENT SlaUpdateEventSalesRiskAssessmentBacklog
    ON SCHEDULE EVERY 10 minute DO 
		call SlaUpdateSalesRiskAssessmentBacklog();

# Proposal and CR      
drop procedure SlaUpdateSalesProposalAndCRCompleted;
DELIMITER //
CREATE PROCEDURE SlaUpdateSalesProposalAndCRCompleted()
 BEGIN
 declare lastUpdate datetime;
 set lastUpdate = (select max(`To`) from analytics.sla_sales_proposalcr_completed);
insert into analytics.sla_sales_proposalcr_completed 
  (select 'Sales' as 'Team',
 'Proposal & CR' as 'Activity',
 if(o.Number_of_Sites__c >= 4 or count(distinct sp.Id)>=3, 'Complex','Simple') as 'Details',
 if(o.Number_of_Sites__c >= 4 or count(distinct sp.Id)>=3, 'Sales-22','Sales-21') as 'Enlighten Activity Code',
 'Opportunity' as 'Id Type',
o.Id as 'Id',
cb.Name as 'Owner', 
'Opportunity Created' as 'Aging Type',
o.CreatedDate as 'From',
date_add(o.CreatedDate, interval if(o.Number_of_Sites__c >= 4 or count(distinct sp.Id)>=3, 5, 2) day) as 'SLA Due',
oh.CreatedDate as 'To',
null as 'Tags'
from salesforce.opportunity o 
inner join salesforce.opportunityfieldhistory oh on oh.OpportunityId = o.Id 
inner join salesforce.user cb on cb.Id = oh.CreatedById
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
and oh.CreatedDate>lastUpdate
group by o.Id);

insert into analytics.sp_log VALUES(null,'SlaUpdateSalesProposalAndCRCompleted',utc_timestamp());

 END //
DELIMITER ;

CREATE EVENT SlaUpdateEventSalesProposalAndCRCompleted
    ON SCHEDULE EVERY 10 minute DO 
		call SlaUpdateSalesProposalAndCRCompleted();

drop procedure SlaUpdateSalesProposalAndCRBacklog;
DELIMITER //
CREATE PROCEDURE SlaUpdateSalesProposalAndCRBacklog()
 BEGIN
 truncate sla_sales_proposalcr_backlog;
 insert into analytics.sla_sales_proposalcr_backlog 
  (select 'Sales' as 'Team',
 'Proposal & CR' as 'Activity',
 if(o.Number_of_Sites__c >= 4 or count(distinct sp.Id)>=3, 'Complex','Simple') as 'Details',
 if(o.Number_of_Sites__c >= 4 or count(distinct sp.Id)>=3, 'Sales-22','Sales-21') as 'Enlighten Activity Code',
 'Opportunity' as 'Id Type',
o.Id as 'Id',
u.Name as 'Owner', 
'Opportunity Created' as 'Aging Type',
o.CreatedDate as 'From',
date_add(o.CreatedDate, interval if(o.Number_of_Sites__c >= 4 or count(distinct sp.Id)>=3, 5, 2) day) as 'SLA Due',
null as 'To',
null as 'Tags'
from salesforce.opportunity o 
left join salesforce.opportunity_certification__c oc on oc.Opportunity__c = o.Id
left join salesforce.Oppty_Cert_Standard_Program__c osc on osc.Opportunity_Certification__c = oc.Id
left join salesforce.standard_program__c sp on sp.Id = osc.Standard_Program__c
left join salesforce.standard__c s on s.Id = sp.Standard__c
left join salesforce.user u on u.Id = o.OwnerId
where 
o.StageName in ('Sales Duration Review')
and o.IsDeleted=0
and o.Business_1__c='Australia'
group by o.Id);

insert into analytics.sp_log VALUES(null,'SlaUpdateSalesProposalAndCRBacklog',utc_timestamp());

 END //
DELIMITER ;

CREATE EVENT SlaUpdateEventSalesProposalAndCRBacklog
    ON SCHEDULE EVERY 10 minute DO 
		call SlaUpdateSalesProposalAndCRBacklog();
        
# Qualify lead

drop procedure SlaUpdateSalesQualifyLeadBacklog;
DELIMITER //
CREATE PROCEDURE SlaUpdateSalesQualifyLeadBacklog()
 BEGIN
 truncate analytics.sla_sales_qualifylead_backlog;
 insert into analytics.sla_sales_qualifylead_backlog 
  (select 'Sales' as 'Team',
 'Qualify Lead' as 'Activity',
 `Details`,
 'Sales-02' as 'Enlighten Activity Code',
 'Lead' as 'Id Type',
`Id` as 'Id',
`Owner`, 
'Lead Created' as 'Aging Type',
`From`,
date_add(`From`, interval 1 day) as 'SLA Due',
null as 'To',
null as 'Tags'
from (
select 'Certification' as 'Details', l.Id as 'Id', u.Name as 'Owner', l.CreatedDate as 'From'
from salesforce.Lead l 
inner join salesforce.User cb on cb.Id = l.CreatedById
inner join salesforce.User o on o.Id = l.OwnerId
inner join  salesforce.RecordType rt on rt.Id = l.RecordTypeId
left join salesforce.user u on u.Id = l.OwnerId
where l.IsDeleted = 0
and l.Status like '%Unqualified%'
and rt.Name = 'AUS - Lead'
and l.Business__c = 'Australia'
and l.CreatedDate>='2014-07-01'
union
select 'Training' as 'Details', l.Id as 'Id', u.Name as 'Owner', l.CreatedDate as 'From'
from training.Lead l 
inner join training.User cb on cb.Id = l.CreatedById
inner join  training.RecordType rt on rt.Id = l.RecordTypeId
left join training.user u on u.Id = l.OwnerId
where l.IsDeleted = 0
and l.Status like '%Unqualified%'
and rt.Name = 'TIS APAC Lead Record Type'
and l.CreatedDate>='2014-07-01'
and l.OwnerId not like '00G20000000vzaCEAQ' # This is the Marketiing Queue: https://emea.salesforce.com/p/own/Queue/d?id=00G20000000vzaC
) t);

insert into analytics.sp_log VALUES(null,'SlaUpdateSalesQualifyLeadBacklog',utc_timestamp());

 END //
DELIMITER ;

CREATE EVENT SlaUpdateEventSalesQualifyLeadBacklog
    ON SCHEDULE EVERY 10 minute DO 
		call SlaUpdateSalesQualifyLeadBacklog();

select * from analytics.sp_log where sp_name = 'SlaUpdateSalesLeadOppFollowUpBacklog' order by exec_time desc limit 5;

# Qualify lead
drop procedure SlaUpdateSalesLeadOppFollowUpBacklog;
DELIMITER //
CREATE PROCEDURE SlaUpdateSalesLeadOppFollowUpBacklog()
 BEGIN
 truncate analytics.sla_sales_leadoppfollowup_backlog;
 insert into analytics.sla_sales_leadoppfollowup_backlog 
  (select 'Sales' as 'Team',
 'Lead/Opp Follow Up' as 'Activity',
 `Details`,
 'Sales-04' as 'Enlighten Activity Code',
 'Task' as 'Id Type',
`Id` as 'Id',
`Owner`, 
'Task Last Modified Date' as 'Aging Type',
`From`,
`SLA Due`,
null as 'To',
null as 'Tags'
from (
select 'Lead Certification' as 'Details', t.Id as 'Id', u.Name as 'Owner', max(t.LastModifiedDate) as 'From', t.ActivityDate as 'SLA Due'
from salesforce.task t
inner join salesforce.lead l on t.WhoId = l.Id
inner join  salesforce.RecordType rt on rt.Id = l.RecordTypeId
left join salesforce.user u on u.Id = t.OwnerId
where t.Status in ('Deferred','In Progress','Not Started')
and t.IsDeleted=0
and l.IsDeleted=0
and rt.Name = 'AUS - Lead'
and l.Business__c = 'Australia'
and t.CreatedDate>='2014-07-01'
group by t.Id
union
select 'Opportunity Certification' as 'Details', t.Id as 'Id', u.Name as 'Owner', max(t.LastModifiedDate) as 'From', t.ActivityDate as 'SLA Due'
from salesforce.task t
inner join salesforce.opportunity o on t.WhatId = o.Id
left join salesforce.user u on u.Id = t.OwnerId
where t.Status in ('Deferred','In Progress','Not Started')
and t.IsDeleted=0
and o.IsDeleted=0
and o.Business_1__c='Australia'
group by t.Id
union
select 'Lead TIS' as 'Details', t.Id as 'Id', u.Name as 'Owner', max(t.LastModifiedDate) as 'From', t.ActivityDate as 'SLA Due'
from training.task t
inner join training.lead l on t.WhoId = l.Id
inner join  training.RecordType rt on rt.Id = l.RecordTypeId
left join training.user u on u.Id = t.OwnerId
where t.Status in ('Deferred','In Progress','Not Started')
and t.IsDeleted=0
and l.IsDeleted=0
and rt.Name in ('TIS APAC Lead Record Type','ENT - APAC - Lead (Web)','ENT - APAC - Lead (Marketing)','ENT - APAC - Lead (IH)','ENT - APAC - Lead (EOI)')
and t.CreatedDate>='2014-07-01'
group by t.Id
union
select 'Opportunity TIS' as 'Details', t.Id as 'Id', if (o.BDM_picklist__c is null, u.Name, o.BDM_picklist__c) as 'Owner', max(t.LastModifiedDate) as 'From', t.ActivityDate as 'SLA Due'
from training.task t
inner join training.opportunity o on t.WhatId = o.Id
inner join training.recordtype rt on rt.Id = o.RecordTypeId
left join training.user u on u.Id = t.OwnerId#o.BDM__c
where t.Status in ('Deferred','In Progress','Not Started')
and t.IsDeleted=0
and o.IsDeleted=0
and rt.Name in ('ENT - APAC - Opportunity (In House)','ENT - APAC - Opportunity (Marketing)','ENT - APAC - Opportunity (Public)')
group by t.Id
) t);

insert into analytics.sp_log VALUES(null,'SlaUpdateSalesLeadOppFollowUpBacklog',utc_timestamp());

 END //
DELIMITER ;

CREATE EVENT SlaUpdateEventSalesLeadOppFollowUpBacklog
    ON SCHEDULE EVERY 20 minute DO 
		call SlaUpdateSalesLeadOppFollowUpBacklog();

show events;

show variables like 'event_scheduler';