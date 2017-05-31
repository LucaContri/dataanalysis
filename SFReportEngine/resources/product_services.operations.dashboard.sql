select * from analytics.sla_arg_v2 arg where arg.`Tags` like '%Initial Project%' or arg.`Tags` like '%Product Update%' or arg.`Tags` like '%Standard Change%';

DELIMITER $$
CREATE FUNCTION `getTargetARGPS`(Metric VARCHAR(64)) RETURNS int(11)
BEGIN
	DECLARE target INTEGER DEFAULT null;
    SET target = (SELECT 
		if(Metric in ('ARG Process Time (BRC)'), 30,
		if(Metric in ('ARG Process Time (Other)'), 15,
		if(Metric in ('ARG Completion/Hold'), 5,
		if(Metric in ('ARG Revision - Resubmission'), 2,
		if(Metric in ('ARG Revision - First'), 5,
		if(Metric in ('ARG Submission - Resubmission'), 2,
		if(Metric in ('ARG Submission - First'), 5,
		if(Metric in ('ARG Submission - Unsubmitted WI'), 5,
		if(Metric in ('ARG Submission - Submitted WI No ARG'), 5, null))))))))));
        
    RETURN target;
 END$$
DELIMITER ;

create or replace view ps_ops_metrics as
#ARG rejection rate
select
'Performance' as '_Type', 
'ARG rejection rate' as '_Metric',
if(arg.Work_Item_Stages__c like '%Initial Project%' or arg.Work_Item_Stages__c like '%Product Update%' or arg.Work_Item_Stages__c like '%Standard Change%','Projects', 'Audits') as '_Category',
sp.Program_Business_Line__c as 'Business Line',
if(r.Reporting_Business_Units__c like 'AUS%', 'Australia', substring_index(r.Reporting_Business_Units__c,'-',-1)) as 'Country',
r.Name as 'Owner',
p.Name as 'Program',
sp.Standard_Service_Type_Name__c as 'Standards',
date_format(arg.CA_Approved__c, '%Y %m')  as 'Period',
count(distinct arg.Id) as 'Volume',
count(distinct if(ah.Status__c='Rejected', ah.Id, null)) as 'Sum Value', #distinct ah.Id means I am counting each rejection
(count(distinct arg.Id) - count(distinct if(ah.Status__c='Rejected', ah.Id, null))) as 'Volume within SLA',
if(sp.Standard_Service_Type_Name__c like '%16949%',0.1,if(sp.Program_Business_Line__c like '%Food%', 0.1,0.08))as 'Target',
ifnull(group_concat(distinct if(ah.Status__c='Rejected', arg.Name, null)) ,'') as 'Items'

from salesforce.approval_history__c ah 
inner join salesforce.audit_report_group__c arg on arg.Id = ah.RAudit_Report_Group__c
inner join salesforce.resource__c r on arg.RAudit_Report_Author__c = r.Id
inner join salesforce.arg_work_item__c argwi on argwi.RAudit_Report_Group__c = arg.Id
inner join salesforce.work_item__c wi on argwi.RWork_Item__c = wi.Id
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
inner join salesforce.program__c p on sp.Program__c = p.Id
where 
arg.IsDeleted = 0
and ah.IsDeleted = 0
and date_format(arg.CA_Approved__c, '%Y-%m') >= '2015-07'
#and (r.Reporting_Business_Units__c like '%Product%' or sp.Program_Business_Line__c like '%Product%')
and sp.Program_Business_Line__c like '%Product%'
group by `_Type`, `_Metric`, `_Category`, `Country`, `Owner`, `Standards`, `Period`

union
# ARG Performance and Backlog
select 
if(arg.`To` is null, 'Backlog', 'Performance') as '_Type',

	if(arg.`Metric` in ('ARG Process Time (BRC)', 'ARG Process Time (Other)'), 'ARG Cycle (Days)',
		if(arg.`Metric` in ('ARG Completion/Hold'), 'Admin Completion (Days)',
			if(arg.`Metric` in ('ARG Revision - Resubmission'), 'Technical Review - Resubmission (Days)',
				if(arg.`Metric` in ('ARG Revision - First'), 'Technical Review - First (Days)',
					if(arg.`Metric` in ('ARG Submission - Resubmission'), 'Auditor Re-Submission (Days)',
						if(arg.`Metric` in ('ARG Submission - First'), 'Auditor First Submission (Days)',
							arg.`Metric`
						)
					)
				)
			)
		)
	) as '_Metric',
if(arg.`Tags` like '%Initial Project%' or arg.`Tags` like '%Product Update%' or arg.`Tags` like '%Standard Change%', 'Projects', 'Audits') as '_Category',
#if(arg.`Tags` like 'MS;%', 'Management Systems', if(arg.`Tags` like 'Food;%', 'Agri-Food', if(arg.`Tags` like 'PS;%', 'Product Services', '?'))) as 'Stream',
p.business_line__c as 'Business Line',
if(r.Reporting_Business_Units__c like 'AUS%', 'Australia', substring_index(r.Reporting_Business_Units__c,'-',-1)) as 'Country',
arg.`Owner` as 'Owner',
p.Name as 'Program',
arg.`Standards` as `Standards`,
date_format(arg.`To`, '%Y %m')  as 'Period',
count(arg.Id) as 'Volume',
sum(analytics.getBusinessDays(arg.`From`, ifnull(arg.`To`, utc_timestamp()), arg.`TimeZone`)) as 'Sum Value',
#sum(timestampdiff(second, arg.`From`, ifnull(arg.`To`, utc_timestamp())))/3600/24 as 'Sum Value',
sum(if(analytics.getBusinessDays(arg.`From`, ifnull(arg.`To`, utc_timestamp()), arg.`TimeZone`)<=getTargetARGPS(arg.`Metric`),1,0)) as 'Volume within SLA',
#sum(if(timestampdiff(second, arg.`From`, ifnull(arg.`To`, utc_timestamp()))/3600/24<=getTargetARGApac(arg.`Metric`),1,0)) as 'Volume within SLA',
getTargetARGPS(arg.`Metric`) as 'Target',
group_concat(distinct arg.Name) as 'Items'
from analytics.sla_arg_v2 arg 
left join salesforce.Resource__c r on arg.`Owner` = r.Name
left join salesforce.standard__c s on s.Name = substring_index(arg.`Standards`, ',',1) and s.Parent_Standard__c is not null
left join salesforce.program__c p on s.Program__c = p.Id
where
(date_format(arg.`To`, '%Y-%m') >= '2015-07' or arg.`To` is null)
#and (r.Reporting_Business_Units__c like '%Product%' or p.business_line__c like '%Product%')
and p.business_line__c like '%Product%'
#and arg.`Metric` not in ('ARG Process Time (BRC)', 'ARG Process Time (Other)', 'ARG Completion/Hold')
and arg.`Metric` not in ('ARG Process Time (BRC)', 'ARG Process Time (Other)')
group by `_Type`, `_Metric`, `_Category`, `Country`, `Owner`, `Standards`, `Target`, `Period`;

(select * from ps_ops_metrics);