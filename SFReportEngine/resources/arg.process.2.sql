select Name from salesforce.sf_business_process_details group by Name;

select * from analytics.sla_arg_v2 where Metric = 'ARG Submission - Submitted WI No ARG';

# WI Finished not submitted
select 
	'Queue' as 'Type',
	'WI_FINISHED_NOT_SUBMMITTED' as 'Name',
	Id as 'Record Id',
	Name as 'Record Name',
	Region,
	null as 'Business Lines',
	null as 'Program',
	`Standards`,
	`Standard Families`,
	`From`,
	`To`,
	analytics.getBusinessDays(`From`, utc_timestamp(), `TimeZone`) as 'Duration',
	'Business Days' as 'Unit',
	`Owner`,
	`Owner` as 'Executed By',
	null as 'Business Unit',
	`Tags`
from analytics.sla_arg_v2 
where Metric = 'ARG Submission - Unsubmitted WI'
union
# WI Submitted without ARG
select 
	'Queue' as 'Type',
	'WI_SUBMITTED_WITHOUT_ARG' as 'Name',
	Id as 'Record Id',
	Name as 'Record Name',
	Region,
	null as 'Business Lines',
	null as 'Program',
	`Standards`,
	`Standard Families`,
	`From`,
	`To`,
	analytics.getBusinessDays(`From`, utc_timestamp(), `TimeZone`) as 'Duration',
	'Business Days' as 'Unit',
	`Owner`,
	`Owner` as 'Executed By',
	null as 'Business Unit',
	`Tags`
from analytics.sla_arg_v2 
where Metric = 'ARG Submission - Submitted WI No ARG'
union
# WI Submitted ARG Pending
select 
	'Queue' as 'Type',
	'WI_SUBMITTED_ARG_PENDING' as 'Name',
	Id as 'Record Id',
	Name as 'Record Name',
	Region,
	null as 'Business Lines',
	null as 'Program',
	`Standards`,
	`Standard Families`,
	`From`,
	`To`,
	analytics.getBusinessDays(`From`, utc_timestamp(), `TimeZone`) as 'Duration',
	'Business Days' as 'Unit',
	`Owner`,
	`Owner` as 'Executed By',
	null as 'Business Unit',
	`Tags`
from analytics.sla_arg_v2 
where Metric = 'ARG Submission - First'
and `To` is null
union
# ARG Rejected to be resubmitted
select 
	'Queue' as 'Type',
	'ARG_REJECTED_TO_BE_RESUBMITTED' as 'Name',
	Id as 'Record Id',
	Name as 'Record Name',
	Region,
	null as 'Business Lines',
	null as 'Program',
	`Standards`,
	`Standard Families`,
	`From`,
	`To`,
	analytics.getBusinessDays(`From`, utc_timestamp(), `TimeZone`) as 'Duration',
	'Business Days' as 'Unit',
	`Owner`,
	`Owner` as 'Executed By',
	null as 'Business Unit',
	`Tags`
from analytics.sla_arg_v2 
where Metric = 'ARG Submission - Resubmission'
and `To` is null
union
# WI Finished to ARG Submitted
select 
	'Performance' as 'Type',
	'WI_FINISHED_TO_ARG_SUBMMITTED' as 'Name',
	Id as 'Record Id',
	Name as 'Record Name',
	Region,
	null as 'Business Lines',
	null as 'Program',
	`Standards`,
	`Standard Families`,
	`From`,
	`To`,
	analytics.getBusinessDays(`From`, `To`, `TimeZone`) as 'Duration',
	'Business Days' as 'Unit',
	`Owner`,
	`Owner` as 'Executed By',
	null as 'Business Unit',
	`Tags`
from analytics.sla_arg_v2 
where Metric = 'ARG Submission - First'
and `To` is not null
union
# PRC - ARG Submitted (backlog for ARG Taken Activity)
select 
	'Queue' as 'Type',
	'ARG_SUBMITTED_NOT_TAKEN' as 'Name',
	Id as 'Record Id',
	Name as 'Record Name',
	Region,
	null as 'Business Lines',
	null as 'Program',
	`Standards`,
	`Standard Families`,
	`From`,
	`To`,
	analytics.getBusinessDays(`From`, utc_timestamp(), `TimeZone`) as 'Duration',
	'Business Days' as 'Unit',
	`Owner`,
	`Owner` as 'Executed By',
	null as 'Business Unit',
	`Tags`
from analytics.sla_arg_v2 
where Metric in ('ARG Revision - First','ARG Revision - Resubmission')
and `To` is null
and `Owner` is null
union
# PRC - ARG taken not reviewed
select 
	'Queue' as 'Type',
	'ARG_TAKEN_NOT_REVIEWED' as 'Name',
	Id as 'Record Id',
	Name as 'Record Name',
	Region,
	null as 'Business Lines',
	null as 'Program',
	`Standards`,
	`Standard Families`,
	`From`,
	`To`,
	analytics.getBusinessDays(`From`, utc_timestamp(), `TimeZone`) as 'Duration',
	'Business Days' as 'Unit',
	`Owner`,
	`Owner` as 'Executed By',
	null as 'Business Unit',
	`Tags`
from analytics.sla_arg_v2 
where Metric in ('ARG Revision - First','ARG Revision - Resubmission')
and `To` is null
and `Owner` is not null
union
# PRC - ARG Submitted to Approved
select 
	'Performance' as 'Type',
	'ARG_SUBMITTED_TO_ARG_APPROVED' as 'Name',
	Id as 'Record Id',
	Name as 'Record Name',
	Region,
	null as 'Business Lines',
	null as 'Program',
	`Standards`,
	`Standard Families`,
	min(`From`) as 'From',
	max(`To`) as 'To',
	analytics.getBusinessDays(min(`From`), max(`To`), `TimeZone`) as 'Duration',
	'Business Days' as 'Unit',
	`Owner`,
	`Owner` as 'Executed By',
	null as 'Business Unit',
	`Tags`
from analytics.sla_arg_v2 
where Metric in ('ARG Revision - First','ARG Revision - Resubmission')
and `To` is not null
group by Id;