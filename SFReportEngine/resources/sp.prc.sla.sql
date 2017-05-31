use analytics;

CREATE TABLE `sla_arg` (
  `Name` tinytext NOT NULL,
  `Id` varchar(18) NOT NULL,
  `Status` tinytext,
  `Auditors Time` bigint(20) DEFAULT NULL,
  `PRC Time` decimal(32,0) DEFAULT NULL,
  `Admin Time` decimal(21,0) DEFAULT NULL,
  `Audit End` date DEFAULT NULL,
  `First Submitted` datetime DEFAULT NULL,
  `CA Completed` datetime DEFAULT NULL,
  `Admin Completed` datetime DEFAULT NULL,
  `LastModifiedDate` datetime NOT NULL,
  `Auditor` tinytext,
  `CA Name` tinytext,
  `Admin Name` tinytext,
  `RevenueOwnerships` text,
  `ClientOwnership` varchar(255),
  `WorkItemsNo` bigint(21) NOT NULL DEFAULT '0',
  `WorkItemTypes` text,
  `PrimaryStandards` text,
  `Standard Families` text,
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

truncate sla_arg;
drop procedure SlaUpdateArg;
DELIMITER //
CREATE PROCEDURE SlaUpdateArg()
 BEGIN
 
insert into analytics.sla_arg 
select t.Name, t.Id, t.`Status`, 
if (t.`Status` in ('Support', 'Completed', 'Hold'),
	if(t.`Auditors Time` is null, 0,t.`Auditors Time`),
    null) as 'Auditors Time', 
if (t.`Status` in ('Support', 'Completed', 'Hold'),
	if(t.`PRC Time`<0 or (t.`PRC Time`> t.`PRC Time UB` and t.`PRC Time`>0), t.`PRC Time UB`, t.`PRC Time`),
    null) as 'PRC Time',
if (t.`Status` in ('Completed', 'Hold'),
	t.`Admin Time`,
    null) as 'Admin Time',
t.`End_Date__c` as 'Audit End', 
t.`First_Submitted__c` as 'First Submitted',
t.`CA_Approved__c` as 'CA Completed',
t.`Admin Completed`,
t.LastModifiedDate,
author.name as 'Auditor',
ca.name as 'CA Name',
admin.Name as 'Admin Name',
group_concat(distinct wi.Revenue_Ownership__c separator ';') as 'RevenueOwnerships',
t.`Client_Ownership__c` as 'ClientOwnership',
count(distinct wi.Id) as 'WorkItemsNo',
group_concat(distinct wi.Work_Item_Stage__c separator ';') as 'WorkItemTypes',
group_concat(distinct wi.Primary_Standard__c separator ';') as 'PrimaryStandards',
GROUP_CONCAT(DISTINCT IF((`scsf`.`IsDeleted` OR `sp`.`IsDeleted`OR `s`.`IsDeleted`),NULL,`s`.`Name`) SEPARATOR ';') AS `Standard Families`
from (
select arg.Name, arg.Client_Ownership__c, ah.RAudit_Report_Group__c as 'Id', arg.Audit_Report_Status__c as 'Status', arg.End_Date__c, arg.First_Submitted__c,
greatest((greatest((if(ah.status__c in ('Submitted'),UNIX_TIMESTAMP(ah.Timestamp__c),if(ah.Status__c in ('Rejected','Recalled'), -UNIX_TIMESTAMP(ah.Timestamp__c),0))), UNIX_TIMESTAMP(arg.First_Submitted__c)) - UNIX_TIMESTAMP(arg.End_Date__c)),0) as 'Auditors Time',
# Negative PRC Time are within Auto Approved group
greatest(sum(distinct if(ah.status__c in ('Rejected','Recalled') or (ah.Status__c = 'Approved' and ah.Assigned_To__c = 'Client Administration'),UNIX_TIMESTAMP(ah.Timestamp__c),if(ah.Status__c in ('Submitted') and ah.Timestamp__c>=arg.First_Submitted__c, -UNIX_TIMESTAMP(ah.Timestamp__c),0))),0) as 'PRC Time',
greatest((max(if(ah.Status__c = 'Approved' and ah.Assigned_To__c = 'Client Administration', UNIX_TIMESTAMP(ah.Timestamp__c),0)) - UNIX_TIMESTAMP(First_Submitted__c)),0) as 'PRC Time UB',
min(if(ah.Status__c in ('Completed','Hold'), ah.Timestamp__c,null)) as 'Admin Completed',
arg.CA_Approved__c,
if(arg.Audit_Report_Status__c in ('Completed'),
	UNIX_TIMESTAMP(max(if(ah.Status__c = 'Completed', ah.Timestamp__c, null))) - if(arg.CA_Approved__c is null, UNIX_TIMESTAMP(arg.First_Submitted__c), UNIX_TIMESTAMP(arg.CA_Approved__c)),
    if(arg.Audit_Report_Status__c in ('Hold'),
		min(if(ah.Status__c = 'Hold', UNIX_TIMESTAMP(ah.timestamp__c),99999999999999999999) - if(arg.CA_Approved__c is null, UNIX_TIMESTAMP(arg.First_Submitted__c), UNIX_TIMESTAMP(arg.CA_Approved__c))),
        null
    )
) as 'Admin Time',
group_concat(ah.Status__c) as 'Statuses',
ah.CurrencyIsoCode,
arg.RAudit_Report_Author__c,
arg.Assigned_CA__c,
arg.Assigned_Admin__c,
arg.LastModifiedDate
from salesforce.approval_history__c ah
inner join salesforce.audit_report_group__c arg on arg.Id = ah.RAudit_Report_Group__c
where 
arg.IsDeleted = 0
and ah.IsDeleted = 0
and (arg.Work_Item_Stages__c not like '%Initial Project%' and arg.Work_Item_Stages__c not like '%Product Update%' and arg.Work_Item_Stages__c not like '%Standard Change%')
and arg.LastModifiedDate > (select if(max(slaarg.LastModifiedDate) is null, '1970-01-01',max(slaarg.LastModifiedDate)) from analytics.sla_arg slaarg)
group by arg.Id) t
left join salesforce.resource__c author on t.RAudit_Report_Author__c = author.Id
left join salesforce.resource__c ca on t.Assigned_CA__c = ca.Id
left join salesforce.resource__c admin on t.Assigned_Admin__c = admin.Id
inner join salesforce.`arg_work_item__c` argwi on argwi.RAudit_Report_Group__c = t.Id 
inner join salesforce.`work_item__c` wi on wi.id = argwi.RWork_Item__c 
inner join salesforce.`site_certification_standard_program__c` `scsp` ON `wi`.`Site_Certification_Standard__c` = `scsp`.`Id`
LEFT JOIN salesforce.`site_certification_standard_family__c` `scsf` ON `scsf`.`Site_Certification_Standard__c` = `scsp`.`Id`
LEFT JOIN salesforce.`standard_program__c` `sp` ON `scsf`.`Standard_Program__c` = `sp`.`Id`
LEFT JOIN salesforce.`standard__c` `s` ON `sp`.`Standard__c` = `s`.`Id`
group by t.`Id`
ON DUPLICATE KEY UPDATE 
`Name`=VALUES(`Name`),
`Id`=VALUES(`Id`),
`Status`=VALUES(`Status`),
`Auditors Time`=VALUES(`Auditors Time`),
`PRC Time`=VALUES(`PRC Time`),
`Admin Time`=VALUES(`Admin Time`),
`Audit End`=VALUES(`Audit End`),
`First Submitted`=VALUES(`First Submitted`),
`CA Completed`=VALUES(`CA Completed`),
`Admin Completed`=VALUES(`Admin Completed`),
`LastModifiedDate`=VALUES(`LastModifiedDate`),
`Auditor`=VALUES(`Auditor`),
`CA Name`=VALUES(`CA Name`),
`Admin Name`=VALUES(`Admin Name`),
`RevenueOwnerships`=VALUES(`RevenueOwnerships`),
`ClientOwnership`=VALUES(`ClientOwnership`),
`WorkItemsNo`=VALUES(`WorkItemsNo`),
`WorkItemTypes`=VALUES(`WorkItemTypes`),
`PrimaryStandards`=VALUES(`PrimaryStandards`),
`Standard Families`=VALUES(`Standard Families`);

insert into analytics.sp_log VALUES(null,'SlaUpdateArg',utc_timestamp());

 END //
DELIMITER ;

use analytics;
drop EVENT SlaUpdateEventArg;
CREATE EVENT SlaUpdateEventArg
    ON SCHEDULE EVERY 10 minute DO 
		call SlaUpdateArg();

# Completed Auditors
select 
'Delivery' as 'Team', 
'ARG Submission' as 'Activity', 
t.RevenueOwnerships as 'Details', 
'ARG' as 'Id Type',
t.Id as 'Id',
t.`Auditor` as 'Owner',
'Audit End' as 'Aging Type',
t.`Audit End` as 'From',
date_add(t.`Audit End`, interval 5 day) as 'SLA Due',
date_add(t.`Audit End`, interval t.`Auditors Time` second ) as 'To',
concat(t.`PrimaryStandards`, ';', if(t.`Standard Families` is null, '',t.`Standard Families`) ) as 'Tags'
from sla_arg t
where t.`Status` in ('Completed', 'Hold', 'Support')
and t.`First Submitted` >= '2015-04-20'
#and t.`First Submitted` <= '2015-04-20'
and t.RevenueOwnerships like 'AUS%';

# Backlog Auditors
create or replace view analytics.sla_auditors_argsubmission_backlog as
select 
'Delivery' as 'Team', 
'ARG Submission' as 'Activity', 
t.RevenueOwnerships as 'Details', 
'ARG' as 'Id Type',
t.Id as 'Id',
t.`Auditor` as 'Owner',
'Audit End' as 'Aging Type',
t.`Audit End` as 'From',
date_add(t.`Audit End`, interval 5 day) as 'SLA Due',
null as 'To',
concat(t.`PrimaryStandards`, ';', if(t.`Standard Families` is null, '',t.`Standard Families`) ) as 'Tags'
from analytics.sla_arg t
where 
t.`Status` in ('Under Review - Rejected', 'Pending') 
and t.RevenueOwnerships like 'AUS%';

select * from analytics.sla_auditors_argsubmission_backlog;

# Completed PRC
select 
'PRC' as 'Team', 
'ARG Approvals' as 'Activity', 
t.RevenueOwnerships as 'Details', 
'ARG' as 'Id Type',
t.Id as 'Id',
t.`CA Name` as 'Owner',
'First Submitted' as 'Aging Type',
#t.`First Submitted` as 'From',
date_add(t.`CA Completed`, interval -t.`PRC Time` second) as 'From',
date_add(date_add(t.`CA Completed`, interval -t.`PRC Time` second), interval 2 day) as 'SLA Due',
t.`CA Completed` as 'To',
concat(t.`PrimaryStandards`, ';', if(t.`Standard Families` is null, '',t.`Standard Families`) ) as 'Tags',
count(Id)
from sla_arg t
where 
t.`CA Completed` >= '2014-04-01'
and t.`CA Completed` <= '2015-04-01'
and t.RevenueOwnerships like 'AUS%';

# Backlog PRC
create or replace view analytics.sla_prc_argapproval_backlog as
select 
'PRC' as 'Team', 
'ARG Approvals' as 'Activity', 
t.RevenueOwnerships as 'Details', 
'ARG' as 'Id Type',
t.Id as 'Id',
t.`CA Name` as 'Owner',
'First Submitted' as 'Aging Type',
t.`First Submitted` as 'From',
date_add(t.`First Submitted`, interval 2 day) as 'SLA Due',
null as 'To',
concat(t.`PrimaryStandards`, ';', if(t.`Standard Families` is null, '',t.`Standard Families`) ) as 'Tags'
from sla_arg t
where 
t.`Status` = 'Under Review'
and t.RevenueOwnerships like 'AUS%';

# Completed CS Admin
select 
'CS Administration' as 'Team', 
'ARG Completion' as 'Activity', 
t.RevenueOwnerships as 'Details', 
'ARG' as 'Id Type',
t.Id as 'Id',
t.`Admin Name` as 'Owner',
'From CA Approval' as 'Aging Type',
t.`CA Completed` as 'From',
date_add(t.`Audit End`, interval 2 day) as 'SLA Due',
t.`Admin Completed` as 'To',
concat(t.`PrimaryStandards`, ';', if(t.`Standard Families` is null, '',t.`Standard Families`) ) as 'Tags'
from sla_arg t
where t.`Status` in ('Completed', 'Hold')
and t.`First Submitted` >= '2015-04-20'
#and t.`First Submitted` <= '2015-04-20'
and t.RevenueOwnerships like 'AUS%';

# Backlog Admin
create or replace view analytics.sla_admin_argcompletion_backlog as
select 
'CS Administration' as 'Team', 
'ARG Completion' as 'Activity', 
t.RevenueOwnerships as 'Details', 
'ARG' as 'Id Type',
t.Id as 'Id',
t.`Admin Name` as 'Owner',
'From CA Approval' as 'Aging Type',
t.`CA Completed` as 'From',
date_add(t.`Audit End`, interval 2 day) as 'SLA Due',
null as 'To',
concat(t.`PrimaryStandards`, ';', if(t.`Standard Families` is null, '',t.`Standard Families`) ) as 'Tags'
from sla_arg t
where 
t.`Status` in ('Support') 
and t.RevenueOwnerships like 'AUS%';

select * from analytics.sla_admin_argcompletion_backlog;

select * from sla_arg t
where 
t.`Status` in ('Support') 
and t.RevenueOwnerships like 'AUS%';
