create database analytics;
use analytics;

CREATE TABLE `analytics`.`sp_log` (
  `Id` INT NOT NULL AUTO_INCREMENT,
  `sp_name` VARCHAR(128) NOT NULL,
  `exec_time` DATETIME NOT NULL,
  PRIMARY KEY (`Id`));

select sp_name, min(exec_time) as 'Since', max(exec_time) as 'LastUpdate', count(*) as 'Count' from analytics.sp_log group by sp_name;

DROP TABLE `sla`;
CREATE TABLE IF NOT EXISTS `sla` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `Team` varchar(256) NOT NULL,
  `Name` varchar(64) NOT NULL,
  `Description` text NULL,
  `SLA Target` double(18,10) null,
  `SLA Unit` varchar(16) null,
  `SLA Target Text` varchar(64) null,
  `Enlighten Activities` varchar(512) null,
  `Activity Duration` double(18,10) null,
  `Backlog Datasource` varchar(64) not null,
  `command backlog` text null,
  `Completed Datasource` varchar(64) not null,
  `command completed` text null,
  PRIMARY KEY (`Id`),
  UNIQUE(`Name`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

ALTER TABLE `analytics`.`sla` 
ADD COLUMN `Region Filter Type` VARCHAR(45) NULL AFTER `command completed`;
ALTER TABLE `analytics`.`sla` 
ADD COLUMN `Is Multiregion` boolean default false AFTER `command completed`;
ALTER TABLE `analytics`.`sla` 
ADD COLUMN `Reporting Order` int not NULL default 0 AFTER `Region Filter Type`;

truncate analytics.sla;
insert into analytics.`sla` VALUES(null,'AS Sales - Australia', 'Qualify Lead', 'Qualify Lead', 24,'Hrs', '24 Hours', 'Qualify Lead (Sales-02)', 5, 'analytics', 'select * from sla_sales_qualifylead_backlog', 'analytics', null, false, null,10);
insert into analytics.`sla` VALUES(null,'AS Sales - Australia', 'Lead/Opp Follow up', 'Lead Follow up', null,null, 'Follow up task due date', 'Lead or Opportunity Follow Up (Sales-04)', 4, 'analytics', 'select * from sla_sales_leadoppfollowup_backlog','analytics', null, false, null,11);
insert into analytics.`sla` VALUES(null,'AS Sales - Australia', 'Risk Assessment', 'Risk Assessment', 24,'Hrs', '24 Hours', 'Risk Assessment (Sales-10)', 10,'analytics', 'select * from sla_sales_risk_assessment_backlog','analytics', 'select * from sla_sales_risk_assessment_completed where `to`> \'@fromP\' and `To`<= \'@toP\'', false, null,12);
insert into analytics.`sla` VALUES(null,'AS Sales - Australia', 'Proposal and CR - Simple', 'Proposal & CR Simple', 48,'Hrs', '48 Hours', 'Complete CR and Proposal (Sales-21)', 90, 'analytics', 'select * from sla_sales_proposalcr_backlog where `Details`=\'Simple\'','analytics', 'select * from sla_sales_proposalcr_completed where `Details`=\'Simple\' and `to`> \'@fromP\' and `To`<= \'@toP\'', false, null,13);
insert into analytics.`sla` VALUES(null,'AS Sales - Australia', 'Proposal and CR - Complex', 'Proposal & CR Complex', 120,'Hrs', '120 Hours', 'Complete CR and Proposal 3+ Stds and 4+ Sites (Sales-22)', 180, 'analytics', 'select * from sla_sales_proposalcr_backlog where `Details`=\'Complex\'','analytics', 'select * from sla_sales_proposalcr_completed where `Details`=\'Complex\' and `to`> \'@fromP\' and `To`<= \'@toP\'', false, null,14);

insert into analytics.`sla` VALUES(null,'CS Administration', 'New Business', 'CS Admin team - New Business activity.\nForm opportunity closed won to delivery strategy created.\nSLA target: 5 business days.\nTimezone based on the location of financial site for client.\nRegion determined using Client Ownership field in Compass.', 5,'Business Days', '5 Business Days', 'NewBus Set Up (AS NewBus-01)', 30, 'analytics', 'select * from analytics.sla_admin_newbusiness where `To` is null and `from` > \'2014\' and `Region` in @regions','analytics', 'select * from analytics.sla_admin_newbusiness where `To`> \'@fromP\' and `To`<= \'@toP\'  and `Region` in @regions', true, 'Client Ownership',20);

insert into analytics.`sla` VALUES(null,'Scheduling', 'MS Scheduled', 'Scheduled', 14,'Days', 'Variable depending on client complexity', 'Sched-02', 2, 'analytics', 'select * from sla_scheduling_backlog where `Team`=\'Scheduling - MS\' and `Activity`=\'Scheduled\'','analytics', 'select * from sla_scheduling_completed where `Team`=\'Scheduling - MS\' and `Activity`=\'Scheduled\' and `to`> \'@fromP\' and `To`<= \'@toP\'', false, null,30);
insert into analytics.`sla` VALUES(null,'Scheduling', 'MS Scheduled - Offered', 'Scheduled - Offered', 35,'Days', '2 month before audit date', 'Sched-05', 3, 'analytics', 'select * from sla_scheduling_backlog where `Team`=\'Scheduling - MS\' and `Activity`=\'Scheduled Offered\'','analytics', 'select * from sla_scheduling_completed where `Team`=\'Scheduling - MS\' and `Activity`=\'Scheduled Offered\' and `to`> \'@fromP\' and `To`<= \'@toP\'', false, null,31);
insert into analytics.`sla` VALUES(null,'Scheduling', 'MS Confirmed', 'Confirmed', null,null, '28 Days before Audit Date', 'Sched-06', 5, 'analytics', 'select * from sla_scheduling_backlog where `Team`=\'Scheduling - MS\' and `Activity`=\'Confirmed\'','analytics', 'select * from sla_scheduling_completed where `Team`=\'Scheduling - MS\' and `Activity`=\'Confirmed\' and `to`> \'@fromP\' and `To`<= \'@toP\'', false, null,32);
insert into analytics.`sla` VALUES(null,'Scheduling', 'MS Open W Substatus', 'Open W Substatus', null,null, null, 'Sched-10', 0, 'analytics', 'select * from sla_scheduling_backlog where `Team`=\'Scheduling - MS\' and `Activity`=\'Open W Substatus\'','analytics', null, false, null,33);
insert into analytics.`sla` VALUES(null,'Scheduling', 'MS Validate Lifecycle', 'Validate Lifecycle', 7,'Days', '7 Days from Cert Registered', 'Sched-16', 3, 'analytics', 'select * from sla_scheduling_backlog where `Team`=\'Scheduling - MS\' and `Activity`=\'Validate Lifecycle\'','analytics', 'select * from sla_scheduling_completed where `Team`=\'Scheduling - MS\' and `Activity`=\'Validate Lifecycle\' and `to`> \'@fromP\' and `To`<= \'@toP\'', false, null,34);

insert into analytics.`sla` VALUES(null,'Scheduling', 'FP Scheduled', 'Scheduled', 14,'Days', 'Variable depending on client complexity', 'Sched-02', 2, 'analytics', 'select * from sla_scheduling_backlog where `Team`=\'Scheduling - FP\' and `Activity`=\'Scheduled\'','analytics', 'select * from sla_scheduling_completed where `Team`=\'Scheduling - FP\' and `Activity`=\'Scheduled\' and `To`> \'@fromP\' and `To`<= \'@toP\'', false, null,35);
insert into analytics.`sla` VALUES(null,'Scheduling', 'FP Scheduled - Offered', 'Scheduled - Offered', 35,'Days', '2 month before audit date', 'Sched-05', 3, 'analytics', 'select * from sla_scheduling_backlog where `Team`=\'Scheduling - FP\' and `Activity`=\'Scheduled Offered\'','analytics', 'select * from sla_scheduling_completed where `Team`=\'Scheduling - FP\' and `Activity`=\'Scheduled Offered\' and `To`> \'@fromP\' and `To`<= \'@toP\'', false, null,36);
insert into analytics.`sla` VALUES(null,'Scheduling', 'FP Confirmed', 'Confirmed', null,null, '28 Days before Audit Date', 'Sched-06', 5, 'analytics', 'select * from sla_scheduling_backlog where `Team`=\'Scheduling - FP\' and `Activity`=\'Confirmed\'','analytics', 'select * from sla_scheduling_completed where `Team`=\'Scheduling - FP\' and `Activity`=\'Confirmed\' and `To`> \'@fromP\' and `To`<= \'@toP\'', false, null,37);
insert into analytics.`sla` VALUES(null,'Scheduling', 'FP Open W Substatus', 'Open W Substatus', null,null, null, 'Sched-10', 0, 'analytics', 'select * from sla_scheduling_backlog where `Team`=\'Scheduling - FP\' and `Activity`=\'Open W Substatus\'','analytics', null, false, null,38);
insert into analytics.`sla` VALUES(null,'Scheduling', 'FP Validate Lifecycle', 'Validate Lifecycle', 7,'Days', '7 Days from Cert Registered', 'Sched-16', 3, 'analytics', 'select * from sla_scheduling_backlog where `Team`=\'Scheduling - FP\' and `Activity`=\'Validate Lifecycle\'','analytics', 'select * from sla_scheduling_completed where `Team`=\'Scheduling - FP\' and `Activity`=\'Validate Lifecycle\' and `To`> \'@fromP\' and `To`<= \'@toP\'', false, null,39);

#insert into analytics.`sla` VALUES(null,'Auditors', 'ARG Submission', 'ARG Submission', 120,'Hrs', '5 Days', 'n/a', null, 'analytics', 
#'select 
#\'Delivery\' as \'Team\', 
#\'ARG Submission\' as \'Activity\', 
#t.RevenueOwnerships as \'Details\', 
#t.RevenueOwnerships as \'Region\', 
#\'ARG\' as \'Id Type\',
#t.Id as \'Id\',
#t.`Auditor` as \'Owner\',
#\'Audit End\' as \'Aging Type\',
#t.`Audit End` as \'From\',
#date_add(t.`Audit End`, interval 5 day) as \'SLA Due\',
#null as \'To\',
#concat(t.`PrimaryStandards`, \';\', if(t.`Standard Families` is null, \'\',t.`Standard Families`) ) as \'Tags\'
#from analytics.sla_arg t
#where 
#t.`Status` in (\'Under Review - Rejected\', \'Pending\') 
#and t.RevenueOwnerships in @regions',
#'analytics', 
#'select 
#\'Delivery\' as \'Team\', 
#\'ARG Submission\' as \'Activity\', 
#t.RevenueOwnerships as \'Details\',
#t.RevenueOwnerships as \'Region\', 
#\'ARG\' as \'Id Type\',
#t.Id as \'Id\',
#t.`Auditor` as \'Owner\',
#\'Audit End\' as \'Aging Type\',
#t.`Audit End` as \'From\',
#date_add(t.`Audit End`, interval 5 day) as \'SLA Due\',
#date_add(t.`Audit End`, interval t.`Auditors Time` second ) as \'To\',
#concat(t.`PrimaryStandards`, \';\', if(t.`Standard Families` is null, \'\',t.`Standard Families`) ) as \'Tags\'
#from sla_arg t
#where t.`Status` in (\'Completed\', \'Hold\', \'Support\')
#and t.`First Submitted` >= \'@fromP\' 
#and t.`First Submitted` <= \'@toP\' 
#and t.RevenueOwnerships in @regions', true, 'Revenue Ownership',40);

insert into analytics.`sla` VALUES(null,'Auditors', 'ARG Submission', 'Delivery team - Audit Report Group Submssion.\nForm end of last audit in the ARG to ARG submitted in Compass.\nSLA target: 5 business days for first submission. 2 business days for resubmission after rejection from PRC team.\nTimezone based on the location of ther last completed audit in the ARG.\nRegion determined using Revenue Ownership field in Compass.', 120,'Hrs', '5 Business Days', 'n/a', null, 'analytics', 
'select 
\'Delivery\' as \'Team\', 
\'ARG Submission\' as \'Activity\', 
t.`metric`,
null as \'Details\',
t.Region as \'Region\', 
t.`TimeZone` as \'TimeZone\',
\'ARG\' as \'Id Type\',
t.Id as \'Id\',
t.Name as \'Name\',
t.`Owner` as \'Owner\',
if(t.`metric` = \'ARG Submission - First\', \'Audit End\', \'Previous Rejection\') as \'Aging Type\',
t.`From` as \'From\',
t.`SLA Target (Business Days)` as \'SLA Target (Business Days)\',
t.`SLA Due` as \'SLA Due\',
t.`To` as \'To\',
t.`Tags`
from analytics.sla_arg_v2 t
where
t.`To` is null 
and t.`Metric` in (\'ARG Submission - First\', \'ARG Submission - Resubmission\')
and t.Region in @regions',
'analytics', 
'select 
\'Delivery\' as \'Team\', 
\'ARG Submission\' as \'Activity\', 
t.`metric`,
null as \'Details\',
t.Region as \'Region\', 
t.`TimeZone` as \'TimeZone\',
\'ARG\' as \'Id Type\',
t.Id as \'Id\',
t.Name as \'Name\',
t.`Owner` as \'Owner\',
if(t.`metric` = \'ARG Submission - First\', \'Audit End\', \'Previous Rejection\') as \'Aging Type\',
t.`From` as \'From\',
t.`SLA Target (Business Days)` as \'SLA Target (Business Days)\',
t.`SLA Due` as \'SLA Due\',
t.`To` as \'To\',
t.`Tags`
from analytics.sla_arg_v2 t
where
t.`To` is not null 
and t.`To` >= \'@fromP\' and t.`To` <= \'@toP\'
and t.`Metric` in (\'ARG Submission - First\', \'ARG Submission - Resubmission\')
and t.Region in @regions', true, 'Revenue Ownership',41);

#insert into analytics.`sla` VALUES(null,'PRC', 'ARG Approval', 'ARG Approval', 48,'Hrs', '48 Hours', 'PRC-38 to PRC-50', null, 'analytics', 
#'select 
#\'PRC\' as \'Team\', 
#\'ARG Approvals\' as \'Activity\', 
#t.RevenueOwnerships as \'Details\',
#t.RevenueOwnerships as \'Region\', 
#\'ARG\' as \'Id Type\',
#t.Id as \'Id\',
#t.`CA Name` as \'Owner\',
#\'First Submitted\' as \'Aging Type\',
#t.`First Submitted` as \'From\',
#date_add(t.`First Submitted`, interval 2 day) as \'SLA Due\',
#null as \'To\',
#concat(t.`PrimaryStandards`, \';\', if(t.`Standard Families` is null, \'\',t.`Standard Families`) ) as \'Tags\'
#from sla_arg t
#where 
#t.`Status` = \'Under Review\'
#and t.RevenueOwnerships in @regions',
#'analytics', 
#'select 
#\'PRC\' as \'Team\', 
#\'ARG Approvals\' as \'Activity\', 
#t.RevenueOwnerships as \'Details\',
#t.RevenueOwnerships as \'Region\', 
#\'ARG\' as \'Id Type\',
#t.Id as \'Id\',
#t.`CA Name` as \'Owner\',
#\'First Submitted\' as \'Aging Type\',
#date_add(t.`CA Completed`, interval -t.`PRC Time` second) as \'From\',
#date_add(date_add(t.`CA Completed`, interval -t.`PRC Time` second), interval 2 day) as \'SLA Due\',
#t.`CA Completed` as \'To\',
#concat(t.`PrimaryStandards`, \';\', if(t.`Standard Families` is null, \'\',t.`Standard Families`)) as \'Tags\'
#from sla_arg t
#where t.`CA Completed` is not null
#and t.`Status` in (\'Completed\', \'Support\', \'Hold\')
#and t.`CA Completed` >= \'@fromP\' 
#and t.`CA Completed` <= \'@toP\' 
#and t.RevenueOwnerships in @regions', true, 'Revenue Ownership',50);

insert into analytics.`sla` VALUES(null,'PRC', 'ARG Revision', 'PRC team - ARG Revision activity.\nForm Audit Report Group submitted/resubmitted to approval/rejection.\nSLA target: 5 business days from first submission. 2 business days from resubmission.\nnTimezone based on the location of ther last completed audit in the ARG.\nRegion determined using Revenue Ownership field in Compass.', 120,'Hrs', '5 Business Days', 'PRC-38 to PRC-50', null, 'analytics', 
'select 
\'PRC\' as \'Team\', 
\'ARG Revision\' as \'Activity\', 
t.`metric`,
null as \'Details\',
t.Region as \'Region\', 
t.`TimeZone` as \'TimeZone\',
\'ARG\' as \'Id Type\',
t.Id as \'Id\',
t.Name as \'Name\',
t.`Owner` as \'Owner\',
if(t.`metric` = \'ARG Revision - First\', \'First Submission\', \'Previous Resubmission\') as \'Aging Type\',
t.`From` as \'From\',
t.`SLA Target (Business Days)` as \'SLA Target (Business Days)\',
t.`SLA Due` as \'SLA Due\',
t.`To` as \'To\',
t.`Tags`
from analytics.sla_arg_v2 t
where
t.`To` is null 
and t.`Metric` in (\'ARG Revision - First\', \'ARG Revision - Resubmission\')
and t.`Region` in @regions',
'analytics', 
'select 
\'Delivery\' as \'Team\', 
\'ARG Revision\' as \'Activity\', 
t.`metric`,
null as \'Details\',
t.Region as \'Region\', 
t.`TimeZone` as \'TimeZone\',
\'ARG\' as \'Id Type\',
t.Id as \'Id\',
t.Name as \'Name\',
t.`Owner` as \'Owner\',
if(t.`metric` = \'ARG Revision - First\', \'First Submission\', \'Previous Resubmission\') as \'Aging Type\',
t.`From` as \'From\',
t.`SLA Target (Business Days)` as \'SLA Target (Business Days)\',
t.`SLA Due` as \'SLA Due\',
t.`To` as \'To\',
t.`Tags`
from analytics.sla_arg_v2 t
where
t.`To` is not null 
and t.`To` >= \'@fromP\' and t.`To` <= \'@toP\'
and t.`Metric` in (\'ARG Revision - First\', \'ARG Revision - Resubmission\')
and t.`Region` in @regions', true, 'Revenue Ownership',51);

insert into analytics.`sla` VALUES(null,'CS Administration', 'ARG Completion', 
'CS Admin team - Audit Report Group completion.\nForm ARG approved by PRC team to ARG completed/hold.\nSLA target: 5 business days.\nTimezone based on the location of ther last completed audit in the ARG.\nRegion determined using Revenue Ownership field in Compass.', 120,'Hrs', '5 Business Days', 'n/a', null, 'analytics', 
'select 
\'CS Administration\' as \'Team\', 
\'ARG Completion\' as \'Activity\', 
t.`metric`,
null as \'Details\',
t.Region as \'Region\', 
t.`TimeZone` as \'TimeZone\',
\'ARG\' as \'Id Type\',
t.Id as \'Id\',
t.Name as \'Name\',
t.`Owner` as \'Owner\',
\'ARG Approved by CA\' as \'Aging Type\',
t.`From` as \'From\',
t.`SLA Target (Business Days)` as \'SLA Target (Business Days)\',
t.`SLA Due` as \'SLA Due\',
t.`To` as \'To\',
t.`Tags`
from analytics.sla_arg_v2 t
where
t.`To` is null 
and t.`Metric` in (\'ARG Completion/Hold\')
and t.`Region` in @regions',
'analytics', 
'select 
\'CS Administration\' as \'Team\', 
\'ARG Completion\' as \'Activity\', 
t.`metric`,
null as \'Details\',
t.Region as \'Region\', 
t.`TimeZone` as \'TimeZone\',
\'ARG\' as \'Id Type\',
t.Id as \'Id\',
t.Name as \'Name\',
t.`Owner` as \'Owner\',
\'ARG Approved by CA\' as \'Aging Type\',
t.`From` as \'From\',
t.`SLA Target (Business Days)` as \'SLA Target (Business Days)\',
t.`SLA Due` as \'SLA Due\',
t.`To` as \'To\',
t.`Tags`
from analytics.sla_arg_v2 t
where
t.`To` is not null 
and t.`To` >= \'@fromP\' and t.`To` <= \'@toP\'
and t.`Metric` in (\'ARG Completion/Hold\')
and t.`Region` in @regions', true, 'Revenue Ownership',60);

insert into analytics.`sla` VALUES(null,'CS Administration', 'Change Requests', 
'CS Admin team - Change Requests.\nFrom ARG approved by CA to change request completed. Using change request last modified date as proxy for completion date as the latter is not available in Compass.\nSLA Target: 3 Business Days\nTimezone based on audit site location.\nRegion determined using Administration Ownership field in Compass.', 3,'Business Days', '3 Business Days', 'n/a', 0, 
'analytics', 'select * from analytics.change_request_backlog_sub t where t.`From` is not null and t.`Region` in @regions',
'analytics', 'select * from analytics.change_request_completed_sub t where t.`To` >= \'@fromP\' and t.`To` <= \'@toP\' and t.`Region` in @regions', true, 'Administration Ownership',70);

insert into analytics.`sla` VALUES(null,'CS Administration', 'Lapsed Certification', 
'CS Admin team - Lapsed Certification Count.\nCount of Certification standard in status Applicant, Registered, Under Suspension, Customised, On Hold with licence Expiry Date in the past.\nSLA Target: Licence has to be De-Registered within 30 days from Expiry\nRegion determined using Administration Ownership field in Compass.', 30,'Business Days', '30 Business Days', 'n/a', 0, 
'analytics', 'select * from lapsed_certifications where `Region` in @regions',
'analytics', null, true, 'Administration Ownership',80);

select sp_name, max(exec_time) from analytics.sp_log group by sp_name;
show events;
select count(distinct Id) as 'backlog', count(distinct if(Aging>1,Id, null)) as 'backlogOverSLA', avg(Aging) as 'AverageAging' from 
(select * from sla_sales_risk_assessment_completed where `from`> date_add(utc_timestamp, interval -1 day) and `To`<=utc_timestamp()) t;

use salesforce;
select count(distinct t.`Id`) as 'Processed', count(if (TIMESTAMPDIFF(DAY,t.`From`, t.`To`)>1,t.`Id`, null)) as 'ProcessedOverSLA', avg(TIMESTAMPDIFF(DAY,t.`From`, t.`To`)) from (
select * from sla_sales_risk_assessment_completed where `from`> date_add(utc_timestamp(), interval -100 day) and `To`<= utc_timestamp()) t;

select * from enlighten_sales_riskass_view;
select max(`To`), count(*) from sla_sales_risk_assessment_completed; #2015-03-20 04:24:34	1957
select utc_timestamp(), count(*) from sla_sales_risk_assessment_backlog; #2015-03-22 22:40:43	6

select date_format(t.`To`, '%Y-%m') as 'Period', count(distinct t.`Id`) as 'Processed', count(if (TIMESTAMPDIFF(DAY,t.`From`, t.`To`)>1,t.`Id`, null)) as 'ProcessedOverSLA', avg(TIMESTAMPDIFF(DAY,t.`From`, t.`To`)) from 
(select * from salesforce.sla_sales_risk_assessment_completed where `from`> '2014-10-18 11:18:15' and `To`<= '2015-03-18 11:18:15') t group by `Period`;

select t.`Owner`, count(distinct t.`Id`) as 'Processed', count(if (TIMESTAMPDIFF(DAY,t.`From`, t.`To`)>1,t.`Id`, null)) as 'ProcessedOverSLA', avg(TIMESTAMPDIFF(DAY,t.`From`, t.`To`)) from 
(select * from salesforce.sla_sales_risk_assessment_completed where `from`> '2014-10-18 11:18:15' and `To`<= '2015-03-18 11:18:15') t group by `Owner`;