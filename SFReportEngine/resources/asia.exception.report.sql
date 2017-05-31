# Audit Days Open
select 'Backlog' as 'Type', '1. Open Audit Days' as 'Metric', utc_date() as 'Date', date_format(wi.Work_Item_Date__c, '%Y-%m') as 'Period',
if(wi.Revenue_Ownership__c like 'AUS%', 'Australia', substring_index(substring_index(wi.Revenue_Ownership__c, '-',2),'-',-1)) as 'Region', 
sum(wi.Required_Duration__c/8) as 'Value'
from salesforce.work_item__c wi
where wi.IsDeleted = 0 and wi.Status__c = 'Open'
and (wi.Revenue_Ownership__c like 'Asia%' or (wi.Revenue_Ownership__c like 'AUS%' and wi.Required_Duration__c not like '%Product%'))
and wi.Open_Sub_Status__c is null
and wi.Work_Item_Date__c <= date_format(date_add(utc_timestamp(), interval 6 month), '%Y-%m-31')
group by `Metric`, `Region`, `Date`, `Period`
union
#Overdue Audit days open
select 'Backlog' as 'Type', '2. Overdue Open Audit Days' as 'Metric', utc_date() as 'Date', date_format(wi.Work_Item_Date__c, '%Y-%m') as 'Period',
if(wi.Revenue_Ownership__c like 'AUS%', 'Australia', substring_index(substring_index(wi.Revenue_Ownership__c, '-',2),'-',-1)) as 'Region', 
sum(wi.Required_Duration__c/8) as 'Value'
from salesforce.work_item__c wi
where wi.IsDeleted = 0 and wi.Status__c = 'Open'
and (wi.Revenue_Ownership__c like 'Asia%' or (wi.Revenue_Ownership__c like 'AUS%' and wi.Required_Duration__c not like '%Product%'))
and wi.Open_Sub_Status__c is null
and wi.Work_Item_Date__c < now()
group by `Metric`, `Region`, `Date`, `Period`
union
# Work Items Not Yet Confirmed Overdue - Asia Region
select 'Backlog' as 'Type', '3. To be Confirmed Audit Days' as 'Metric', utc_date() as 'Date', date_format(wi.Work_Item_Date__c, '%Y-%m') as 'Period',
if(wi.Revenue_Ownership__c like 'AUS%', 'Australia', substring_index(substring_index(wi.Revenue_Ownership__c, '-',2),'-',-1)) as 'Region', 
sum(wi.Required_Duration__c/8) as 'Value'
from salesforce.work_item__c wi
where wi.IsDeleted = 0 and wi.Status__c in ('Scheduled', 'Scheduled - Offered')
and (wi.Revenue_Ownership__c like 'Asia%' or (wi.Revenue_Ownership__c like 'AUS%' and wi.Required_Duration__c not like '%Product%'))
and wi.Work_Item_Date__c <= date_format(date_add(utc_timestamp(), interval 6 month), '%Y-%m-31')
group by `Metric`, `Region`, `Date`, `Period`
union
# Work Items Not Yet Confirmed - Asia Region
select 'Backlog' as 'Type', '4. To be Confirmed Overdue Audit Days' as 'Metric', utc_date() as 'Date', date_format(wi.Work_Item_Date__c, '%Y-%m') as 'Period',
if(wi.Revenue_Ownership__c like 'AUS%', 'Australia', substring_index(substring_index(wi.Revenue_Ownership__c, '-',2),'-',-1)) as 'Region', 
sum(wi.Required_Duration__c/8) as 'Value'
from salesforce.work_item__c wi
where wi.IsDeleted = 0 and wi.Status__c in ('Scheduled', 'Scheduled - Offered')
and (wi.Revenue_Ownership__c like 'Asia%' or (wi.Revenue_Ownership__c like 'AUS%' and wi.Required_Duration__c not like '%Product%'))
and wi.Work_Item_Date__c < now()
group by `Metric`, `Region`, `Date`, `Period`
union
# Submitted WIs with no ARG - Asia Region
select 
'Backlog' as 'Type', '5. WIs with no ARG' as 'Metric2', utc_date() as 'Date', date_format(`From`, '%Y-%m') as 'Period',
if(`Region` like 'AUS%', 'Australia', substring_index(substring_index(`Region`, '-',2),'-',-1)) as 'Region2', 
count(distinct `Id`) as 'Value'
from analytics.sla_arg_v2 
where Metric = 'ARG Submission - Submitted WI No ARG'
and (`Region` like 'Asia%' or `Region` like 'AUS%') and `Region` not like '%Product%'
group by `Metric2`, `Region2`, `Date`, `Period`
union
# Un-submitted ARG - Asia Region
select 
'Backlog' as 'Type', '6. Unsubmitted ARG' as 'Metric2', utc_date() as 'Date', date_format(`From`, '%Y-%m') as 'Period',
if(`Region` like 'AUS%', 'Australia', substring_index(substring_index(`Region`, '-',2),'-',-1)) as 'Region2', 
count(distinct `Id`) as 'Value'
from analytics.sla_arg_v2 
where Metric in ('ARG Submission - First', 'ARG Submission - Resubmission')
and `To` is null
and (`Region` like 'Asia%' or `Region` like 'AUS%') and `Region` not like '%Product%'
group by `Metric2`, `Region2`, `Date`, `Period`
union
# Un-assigned ARG in Support
select 
'Backlog' as 'Type', '7. ARG in Support' as 'Metric2', utc_date() as 'Date', date_format(`From`, '%Y-%m') as 'Period',
if(`Region` like 'AUS%', 'Australia', substring_index(substring_index(`Region`, '-',2),'-',-1)) as 'Region2', 
count(distinct `Id`) as 'Value'
from analytics.sla_arg_v2 
where Metric = 'ARG Completion/Hold'
and `To` is null
and (`Region` like 'Asia%' or `Region` like 'AUS%') and `Region` not like '%Product%'
group by `Metric2`, `Region2`, `Date`, `Period`
union
# Lapsed Ceertifications
select
'Backlog' as 'Type', '8. Lapsed Certification' as 'Metric',utc_date() as 'Date', date_format(`From`, '%Y-%m') as 'Period',
if(`Region` like 'AUS%', 'Australia',substring_index(`Region`, '-',-1)) as 'Region', 
count(distinct `Id`) as 'Value' 
from analytics.lapsed_certifications 
where 
(`Region` like 'Asia%' or `Region` like 'AUS%') and `Region` not like '%Product%'
group by `Metric`, `Region`, `Date`, `Period`
union
# Auditor Submission
select 
'Performace' as 'Type', '1. Avg Auditor Submission (Days)' as 'Metric2', 
utc_date() as 'Date', 
date_format(`To`, '%Y-%m') as 'Period',
if(`Region` like 'AUS%', 'Australia', substring_index(`Region`, '-',2)) as 'Region2', 
avg(timestampdiff(day, `From`, `To`)) as 'Value'
from analytics.sla_arg_v2 
where Metric in ('ARG Submission - First')
and `To` is not null
and (`Region` like 'Asia%' or `Region` like 'AUS%') and `Region` not like '%Product%'
#and `To` > date_format(now(), '%Y-%m-01') 
group by `Metric2`, `Region2`, `Date`, `Period`
union
#Average of Work Item approval Time (days) by CA -  CA KPI
select 
'Performace' as 'Type', '2. Avg CA Approval (Days)' as 'Metric2', 
utc_date() as 'Date', 
date_format(t.`To`, '%Y-%m') as 'Period',
if(t.`Region` like 'AUS%', 'Australia', substring_index(t.`Region`, '-',2)) as 'Region2', 
avg(t.`Value`) as 'Value'
from (
select `Id`, min(`From`) as 'From', max(`To`) as 'To', `Region`,
timestampdiff(day, min(`From`), max(`To`)) as 'Value'
from analytics.sla_arg_v2 
where Metric in ('ARG Revision - First','ARG Revision - Resubmission')
and `To` is not null
and (`Region` like 'Asia%' or `Region` like 'AUS%') and `Region` not like '%Product%'
#and `To` > date_format(now(), '%Y-%m-01') 
group by `Id`) t
group by `Metric2`, `Region2`, `Date`, `Period`
union
select 
'Performace' as 'Type', '3. Avg Admin Completion (Days)' as 'Metric2', 
utc_date() as 'Date', 
date_format(`To`, '%Y-%m') as 'Period',
if(`Region` like 'AUS%', 'Australia', substring_index(`Region`, '-',2)) as 'Region2', 
avg(timestampdiff(day, `From`, `To`)) as 'Value'
from analytics.sla_arg_v2 
where Metric in ('ARG Completion/Hold')
and `To` is not null
and (`Region` like 'Asia%' or `Region` like 'AUS%') and `Region` not like '%Product%'
#and `To` > date_format(now(), '%Y-%m-01') 
group by `Metric2`, `Region2`, `Date`, `Period`
union
select 
'Performace' as 'Type', '4. Avg ARG Turn Around (Days)' as 'Metric2', utc_date() as 'Date', date_format(`To`, '%Y-%m') as 'Period',
if(`Region` like 'AUS%', 'Australia', substring_index(`Region`, '-',2)) as 'Region2', 
avg(timestampdiff(day, `From`, `To`)) as 'Value'
from analytics.sla_arg_v2 
where Metric in ('ARG Process Time (BRC)', 'ARG Process Time (Other)')
and `To` is not null
#and `Region` like 'Asia%'
and (`Region` like 'Asia%' or `Region` like 'AUS%') and `Region` not like '%Product%'
#and `To` > date_format(now(), '%Y-%m-01') 
group by `Metric2`, `Region2`, `Date`, `Period`
union
select
'Days' as 'Type', 
if(wi.Status__c in ('Open', 'Service Change'), 'Open', if (wi.Status__c in ('Scheduled', 'Scheduled - Offered'), 'Scheduled', 'Confirmed')) as 'Metric2', 
utc_date() as 'Date', date_format(wi.Work_Item_Date__c, '%Y-%m') as 'Period',
if(wi.Revenue_Ownership__c like 'AUS%', 'Australia', substring_index(wi.Revenue_Ownership__c, '-',2)) as 'Region2', 
sum(wi.Required_Duration__c/8) as 'Value'
from salesforce.work_item__c wi
where wi.IsDeleted = 0
and wi.Status__c not in ('Budget', 'Cancelled', 'Draft', 'Initiate Service')
and (wi.Revenue_Ownership__c like 'Asia%' or wi.Revenue_Ownership__c like 'AUS%') and wi.Revenue_Ownership__c not like '%Product%'
and wi.Work_Item_Date__c between '2015-07-01' and '2016-06-30'
group by `Metric2`, `Region2`, `Date`, `Period`
union
select 'Days' as 'Type', 'Budget' as 'Metric2', utc_date() as 'Date', date_format(RefDate, '%Y-%m') as 'Period', concat('Asia-', Region) as 'Region2', RefValue as 'Value'
FROM salesforce.sf_data 
where DataType = 'Asia Audit Days Budget'
union
select 'Days' as 'Type', 'Budget' as 'Metric2', utc_date() as 'Date', date_format(RefDate, '%Y-%m') as 'Period', 'Australia' as 'Region2', RefValue as 'Value'
FROM salesforce.sf_data 
where DataType = 'Audit Days Budget'
union
select
'Days' as 'Type', 
'Confirmed minus Budget' as 'Metric2', 
utc_date() as 'Date', 
date_format(wi.Work_Item_Date__c, '%Y-%m') as 'Period',
if(wi.Revenue_Ownership__c like 'AUS%', 'Australia', substring_index(wi.Revenue_Ownership__c, '-',2)) as 'Region2', 
(sum(wi.Required_Duration__c/8) - b.RefValue) as 'Value'
from salesforce.work_item__c wi
inner join salesforce.sf_data b on date_format(b.RefDate, '%Y-%m') = date_format(wi.Work_Item_Date__c, '%Y-%m') and concat('Asia-', b.Region) = substring_index(wi.Revenue_Ownership__c, '-',2)
where wi.IsDeleted = 0
and wi.Status__c not in ('Budget', 'Cancelled', 'Draft', 'Initiate Service', 'Open', 'Service Change', 'Scheduled', 'Scheduled - Offered')
and wi.Revenue_Ownership__c like 'Asia%'
and wi.Work_Item_Date__c between '2015-07-01' and '2016-06-30'
group by `Metric2`, `Region2`, `Date`, `Period`
union
select
'Days' as 'Type', 
'Confirmed minus Budget' as 'Metric2', 
utc_date() as 'Date', 
date_format(wi.Work_Item_Date__c, '%Y-%m') as 'Period',
if(wi.Revenue_Ownership__c like 'AUS%', 'Australia', substring_index(wi.Revenue_Ownership__c, '-',2)) as 'Region2', 
(sum(wi.Required_Duration__c/8) - b.RefValue) as 'Value'
from salesforce.work_item__c wi
inner join (select RefDate, sum(RefValue) as 'RefValue' from salesforce.sf_data where DataType = 'Audit Days Budget' and Region like 'Australia%' group by RefDate) b on date_format(b.RefDate, '%Y-%m') = date_format(wi.Work_Item_Date__c, '%Y-%m')
where wi.IsDeleted = 0
and wi.Status__c not in ('Budget', 'Cancelled', 'Draft', 'Initiate Service', 'Open', 'Service Change', 'Scheduled', 'Scheduled - Offered')
and wi.Revenue_Ownership__c like 'AUS%' and wi.Revenue_Ownership__c not like '%Product%'
and wi.Work_Item_Date__c between '2015-07-01' and '2016-06-30'
group by `Metric2`, `Region2`, `Date`, `Period`;

select * from salesforce.sf_data where DataType = 'Audit Days Budget';