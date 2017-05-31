select wi.Id, wi.Name, wi.Work_Item_Stage__c, wi.Status__c from work_item__C wi where wi.Work_Item_Stage__c in ('Initial Project','Product Update');

select * from salesforce.sf_tables where TableName='criteria__c';

# Backlog
create or replace view enlighten_product_backlog as 
(select 
'Product' AS `Team`,
`ca`.`Name` AS `User`,
'Approvals - ARG' AS `Activity`,
count(distinct `arg`.`Id`) AS `WIP`,
date_format(now(),'%d/%m/%Y') AS `Date/Time`,
group_concat(distinct `arg`.`Name` separator ',') AS `Notes` 
from ((((`audit_report_group__c` `arg` 
	left join `resource__c` `ca` on((`arg`.`Assigned_CA__c` = `ca`.`Id`))) 
    left join `arg_work_item__c` `argwi` on((`argwi`.`RAudit_Report_Group__c` = `arg`.`Id`))) 
    left join `work_item__c` `wi` on((`argwi`.`RWork_Item__c` = `wi`.`Id`))) 
    left join `site_certification_standard_program__c` `scsp` on((`wi`.`Site_Certification_Standard__c` = `scsp`.`Id`))) 
where 
	((`arg`.`Audit_Report_Status__c` = 'Under Review') 
	and (`scsp`.`Administration_Ownership__c` = 'AUS-Product Services') 
    and ((not((`arg`.`Work_Item_Stages__c` like '%Initial Project%'))) or (not((`arg`.`Work_Item_Stages__c` like '%Product Update%'))) or (not((`arg`.`Work_Item_Stages__c` like '%Standard Change%'))))) 
group by `User`) 
union 
(select 
	'Product' AS `Team`,
    `o`.`Name` AS `User`,
    'ARG Submitted' AS `Activity`,
    count(distinct `wi`.`Id`) AS `WIP`,
    date_format(now(),'%d/%m/%Y') AS `Date/Time`,
    group_concat(distinct `wi`.`Name` separator ',') AS `Notes` 
from 
	((`work_item__c` `wi` 
    left join `site_certification_standard_program__c` `scsp` on((`wi`.`Site_Certification_Standard__c` = `scsp`.`Id`))) 
    left join `resource__c` `o` on((`wi`.`Work_Item_Owner__c` = `o`.`Id`))) 
where 
((`scsp`.`Administration_Ownership__c` = 'AUS-Product Services') 
and (`wi`.`IsDeleted` = 0) 
and (`wi`.`Status__c` = 'In Progress') 
and (`wi`.`Work_Item_Stage__c` not in ('Initial Project','Product Update')) 
and (`wi`.`End_Service_Date__c` < now())) group by `User`)
union 
(select 
'Product' AS `Team`,
c.Criteria_Owner_Name__c AS `User`,
#substring_index(c.Name__c , '**Client Output Language Not Found For This Criteria** ',-1) as 'Activity',
getCriteriaWithType(left(substring_index(c.Name__c , '**Client Output Language Not Found For This Criteria** ',-1),90),s.Conformity_Type__c) as 'Activity',
count(distinct c.Id) AS `WIP`,
date_format(now(),'%d/%m/%Y') AS `Date/Time`,
group_concat(distinct c.`Work_Item__c` separator ',') AS `Notes`
from salesforce.criteria__c c 
inner join salesforce.work_item__c wi on c.Work_Item__c = wi.Id
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
inner join salesforce.standard__c s on sp.Standard__c = s.Id
where c.Status__c in ('Allocated','In Progress') #'Client', 'For Review'
and c.Applicability__c in ('Mandatory')#('Optional', 'Mandatory')
and c.Work_Item_Status__c not in ('Cancelled', 'Completed') 
group by `Activity`, `User`);


select * from enlighten_product_backlog;

# Activities Completed
create or replace view enlighten_product_activity_sub as
(select 
'Product' as 'Team',
r.Name as 'User',
'Audit/Witness Volume' as 'Activity',
1 as 'Completed',
date_format(now(), '%d/%m/%Y') as 'Date/Time',	
wi.Name as 'Notes'
from salesforce.event e
inner join salesforce.work_item_resource__c wir on e.WhatId = wir.Id
inner join salesforce.work_item__c wi on wir.Work_Item__c = wi.Id
inner join salesforce.resource__c r on wir.Resource__c = r.Id
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
where 
e.ActivityDate < utc_timestamp()
and e.ActivityDate > date_add(utc_timestamp(), interval -1 day)
and r.Reporting_Business_Units__c like 'AUS-Product%'
#and scsp.Administration_Ownership__c in ('AUS-Product Services')
and wir.Work_Item_Type__c in ('Audit')
and wi.IsDeleted = 0
and wir.IsDeleted = 0
and e.IsDeleted =  0
and wi.Status__C not in ('Cancelled'))
union
(select 
'Product' as 'Team',
r.Name as 'User',
if(wir.Work_Item_Type__c='Audit', 'Audit/Witness Time (mins)', 'Travel Time (mins)') as 'Activity',
e.DurationInMinutes as 'Completed',
date_format(now(), '%d/%m/%Y') as 'Date/Time',
wi.Name as 'Notes'
from salesforce.event e
inner join salesforce.work_item_resource__c wir on e.WhatId = wir.Id
inner join salesforce.work_item__c wi on wir.Work_Item__c = wi.Id
inner join salesforce.resource__c r on wir.Resource__c = r.Id
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
where 
e.ActivityDate < utc_timestamp()
and e.ActivityDate > date_add(utc_timestamp(), interval -1 day)
#and scsp.Administration_Ownership__c in ('AUS-Product Services')
and r.Reporting_Business_Units__c like 'AUS-Product%'
and wir.Work_Item_Type__c in ('Audit', 'Travel')
and wi.IsDeleted = 0
and wir.IsDeleted = 0
and e.IsDeleted =  0
and wi.Status__C not in ('Cancelled'))
union
(select 
'Product' as 'Team',
r.Name as 'User',
if(ah.Status__c='Approved', 'Approvals - ARG', 'ARG - Submission') as 'Activity',
count(distinct arg.Id) as 'Completed',
date_format(now(), '%d/%m/%Y') as 'Date/Time',
group_concat(distinct arg.Name) as 'Notes'
from salesforce.approval_history__c ah 
inner join salesforce.audit_report_group__c arg on arg.Id = ah.RAudit_Report_Group__c
inner join resource__c r on ah.RApprover__c = r.Id
left join salesforce.arg_work_item__c argwi on argwi.RAudit_Report_Group__c = arg.Id
left join salesforce.work_item__c wi on argwi.RWork_Item__c = wi.Id
left join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
where 
( 
	(ah.Status__c in ('Approved') and Assigned_To__c = 'Client Administration') 
    or (ah.Status__c in ('Submitted') and Assigned_To__c = 'Certification Approver') )
#and scsp.Administration_Ownership__c in ('AUS-Product Services')
and r.Reporting_Business_Units__c like 'AUS-Product%'
and (arg.Work_Item_Stages__c not like '%Initial Project%' or arg.Work_Item_Stages__c not like '%Product Update%' or arg.Work_Item_Stages__c not like '%Standard Change%')
and ah.Timestamp__c > date_add(utc_timestamp(), interval -1 day)
group by ah.Id)
union
(select 
'Product' AS `Team`,
lmb.Name AS `User`,
#substring_index(c.Name__c , '**Client Output Language Not Found For This Criteria** ',-1) as 'Activity',
getCriteriaWithType(left(substring_index(c.Name__c , '**Client Output Language Not Found For This Criteria** ',-1),90),s.Conformity_Type__c) as 'Activity',
count(distinct c.Id) AS `Completed`,
date_format(now(),'%d/%m/%Y') AS `Date/Time`,
group_concat(distinct c.`Work_Item__c` separator ',') AS `Notes`
from 
salesforce.criteria__c c 
inner join salesforce.work_item__c wi on c.Work_Item__c = wi.Id
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
inner join salesforce.standard__c s on sp.Standard__c = s.Id
inner join salesforce.user lmb on c.LastModifiedById = lmb.Id
where 
#c.Status__c in ('Completed')
c.Status__c not in (' Not Applicable','Cancelled','Allocated')
and c.LastModifiedDate>date_add(utc_timestamp(), interval -1 day)
group by `Activity`, `User`);

create or replace view enlighten_product_activity as 
select `Team`, `User`, `Activity`, sum(`Completed`) as 'Completed', `Date/Time`, group_concat(distinct `Notes`) as 'Notes'
from enlighten_product_activity_sub
group by `Team`, `User`, `Activity`;

select * from enlighten_product_activity;

use salesforce;
drop function salesforce.getCriteriaWithType;
DELIMITER //
CREATE FUNCTION salesforce.getCriteriaWithType(Criteria VARCHAR(128), Type VARCHAR(32)) RETURNS VARCHAR(128)
BEGIN
	DECLARE criteriaWithType VARCHAR(128) DEFAULT '';
    SET type = (SELECT IF(type is null, 'Type 5',type));
    SET criteriaWithType = 
		(SELECT 
			IF (Criteria in (
					left('Review Test Report and verify compliance.',90), 
					left('Review Test Report for correct TRF, country deviations and compliance.',90), 
					left('Review Test Report, verify validity, adequacy and ompliance.',90), 
					left('Verifying issuing laboratory & test scope.',90), 
					left('Advise AQIS of Changes to certification type/status.',90), 
					left('Assess against AWPCS revision.',90), 
					left('Define the certified product range, establish model description matrix.',90), 
					left('Verify that the information supplied, i.e. product specifications, drawings, test reports, material information, installation instructions, are in accordance with the Evaluation Plan.',90), 
					left('Verify that the Product Specifications, Materials and Design, where applicable, comply with the standard.',90), 
					left('Verify that the the Product Specifications, critical components/Materials and approvals comply with the standard.',90), 
					left('Verify that the the Product Specifications, critical components/Materials and approvals, where applicable, comply with regulation and standard.',90)),
				concat(Criteria, ' - ', substring_index(Type,' - ',-1)), 
				Criteria
			)
		);
	RETURN criteriaWithType ;
 END //
DELIMITER ;

# Criteria
describe salesforce.criteria__c;
select 
'Product' AS `Team`,
c.Criteria_Owner_Name__c AS `User`,
#substring_index(c.Name__c , '**Client Output Language Not Found For This Criteria** ',-1) as 'Activity',
getCriteriaWithType(left(substring_index(c.Name__c , '**Client Output Language Not Found For This Criteria** ',-1),90),s.Conformity_Type__c) as 'Activity',
count(distinct c.Id) AS `Completed`,
date_format(now(),'%d/%m/%Y') AS `Date/Time`,
group_concat(distinct c.`Work_Item__c` separator ',') AS `Notes`
from 
criteria__c c 
inner join salesforce.work_item__c wi on c.Work_Item__c = wi.Id
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
inner join salesforce.standard__c s on sp.Standard__c = s.Id
where 
#c.Status__c in ('Completed')
c.Status__c not in (' Not Applicable','Cancelled','Allocated')
#and c.LastModifiedDate>date_add(utc_timestamp(), interval -1 day)
and date_format(date_add(c.LastModifiedDate, interval 9 hour), '%Y-%m-%d') = '2015-06-16'
and Criteria_Owner_Name__c = 'David Connelly'
group by `Activity`, `User`;

select substring_index(Name__c , '**Client Output Language Not Found For This Criteria** ',-1) as 'Activity', count(Id) 
from salesforce.criteria__c 
where LastModifiedDate >= '2014'
group by `Activity`;

select 'test', left('Verify that the information supplied, i.e. product specifications, drawings, test reports, material information, installation instructions, are in accordance with the Evaluation Plan. - Type 1',90);