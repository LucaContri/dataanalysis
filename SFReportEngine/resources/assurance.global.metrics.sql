select * from (
#Confirmed Audit Days
select 
if(RowName like 'Food%', 'Food', 'MS') as 'Stream',
'Confirmed Audit Days' as 'Metric',
sum(if(ColumnName='2014 07',Value, null)) as '2014 07',
sum(if(ColumnName='2014 08',Value, null)) as '2014 08',
sum(if(ColumnName='2014 09',Value, null)) as '2014 09'
from sf_report_history 
where ReportName = 'Audit Days Snapshot' 
and Region like '%Australia%'
and Date = (select max(Date) from sf_report_history where ReportName = 'Audit Days Snapshot' and Region like '%Australia%')
and (RowName like 'Food%' or RowName like 'MS%')
and (RowName like '%Confirmed' or RowName like '%In Progress' or RowName like '%Complete%' or RowName like '%Under Review%' or RowName like '%Submitted' or RowName like '%Support')
and ColumnName >= '2014 07' and ColumnName <= '2015 06'
group by `Stream`, `Metric`

union
#% Customer Revenue Retained
select lbr.`Stream`, '% Customer Revenue Retained' as 'Metric', 
1-sum(if(lbr.`Cancelled Period`='2014 07', lbr.`Quantity`*lbr.`EffectivePrice`, null))/if( lbr.`Stream`='MS',
	(select sum(RefValue) as 'Audit Days Revenue fy 2014' from sf_data where DataType='PeopleSoft' and DataSubType = 'Audit Revenue' and RefName = 'MS' and RefDate >= '2013-07-01' and RefDate <= '2014-06-30'),
	(select sum(RefValue) as 'Audit Days Revenue fy 2014' from sf_data where DataType='PeopleSoft' and DataSubType = 'Audit Revenue' and RefName = 'Food' and RefDate >= '2013-07-01' and RefDate <= '2014-06-30')
) as '2014 07',
1-sum(if(lbr.`Cancelled Period`='2014 08', lbr.`Quantity`*lbr.`EffectivePrice`, null))/if( lbr.`Stream`='MS',
	(select sum(RefValue) as 'Audit Days Revenue fy 2014' from sf_data where DataType='PeopleSoft' and DataSubType = 'Audit Revenue' and RefName = 'MS' and RefDate >= '2013-07-01' and RefDate <= '2014-06-30'),
	(select sum(RefValue) as 'Audit Days Revenue fy 2014' from sf_data where DataType='PeopleSoft' and DataSubType = 'Audit Revenue' and RefName = 'Food' and RefDate >= '2013-07-01' and RefDate <= '2014-06-30')
) as '2014 08',
1-sum(if(lbr.`Cancelled Period`='2014 09', lbr.`Quantity`*lbr.`EffectivePrice`, null))/if( lbr.`Stream`='MS',
	(select sum(RefValue) as 'Audit Days Revenue fy 2014' from sf_data where DataType='PeopleSoft' and DataSubType = 'Audit Revenue' and RefName = 'MS' and RefDate >= '2013-07-01' and RefDate <= '2014-06-30'),
	(select sum(RefValue) as 'Audit Days Revenue fy 2014' from sf_data where DataType='PeopleSoft' and DataSubType = 'Audit Revenue' and RefName = 'Food' and RefDate >= '2013-07-01' and RefDate <= '2014-06-30')
) as '2014 09'
from lost_business_revenue lbr
where lbr.`Cancelled Period`>='2014 07'	
group by `Stream`, `Metric`

union
#Customer Revenue Lost
select lbr.`Stream`, 'Customer Revenue Lost' as 'Metric', 
sum(if(lbr.`Cancelled Period`='2014 07', lbr.`Quantity`*lbr.`EffectivePrice`, null)) as '2014 07',
sum(if(lbr.`Cancelled Period`='2014 08', lbr.`Quantity`*lbr.`EffectivePrice`, null)) as '2014 08',
sum(if(lbr.`Cancelled Period`='2014 09', lbr.`Quantity`*lbr.`EffectivePrice`, null)) as '2014 09'
from lost_business_revenue lbr
where lbr.`Cancelled Period`>='2014 07'	
group by `Stream`, `Metric`

#union 
#Average Unit Price of Audits

union 
#New Business Won
select 'MS and Food' as 'stream', 'New Business Won (Fees)' as 'metric', 
sum(if(t.WonPeriod = '2014 07', oli.TotalPrice, null)) as '2014 07',
sum(if(t.WonPeriod = '2014 08', oli.TotalPrice, null)) as '2014 08',
sum(if(t.WonPeriod = '2014 09', oli.TotalPrice, null)) as '2014 09'
from (select o.Id, o.Total_First_Year_Revenue__c, date_format(date_add(min(oh.CreatedDate),INTERVAL 11 HOUR),'%Y %m') as 'WonPeriod' from opportunity o inner join opportunityfieldhistory oh ON oh.OpportunityId = o.Id where o.IsDeleted = 0
			and date_format(date_add(oh.CreatedDate,INTERVAL 11 HOUR),'%Y %m') >= '2014 07'
			and date_format(date_add(oh.CreatedDate,INTERVAL 11 HOUR),'%Y %m') <= '2014 08'
			and o.Business_1__c = 'Australia'
			and o.StageName='Closed Won'
			and oh.Field = 'StageName'
			and o.Status__c = 'Active'
			group by o.Id) t
left join opportunitylineitem oli on oli.OpportunityId = t.Id
where oli.IsDeleted=0
and oli.Days__c>0 #Exclude Fees, only Audit
and oli.First_Year_Revenue__c =1
group by `stream`, `metric`

union 
select 'MS and Food' as 'stream', 'New Business Won (Fees)' as 'metric', 
sum(if(t.WonPeriod = '2014 07', oli.TotalPrice, null)) as '2014 07',
sum(if(t.WonPeriod = '2014 08', oli.TotalPrice, null)) as '2014 08',
sum(if(t.WonPeriod = '2014 09', oli.TotalPrice, null)) as '2014 09'
from (select o.Id, o.Total_First_Year_Revenue__c, date_format(date_add(min(oh.CreatedDate),INTERVAL 11 HOUR),'%Y %m') as 'WonPeriod' from opportunity o inner join opportunityfieldhistory oh ON oh.OpportunityId = o.Id where o.IsDeleted = 0
			and date_format(date_add(oh.CreatedDate,INTERVAL 11 HOUR),'%Y %m') >= '2014 07'
			and date_format(date_add(oh.CreatedDate,INTERVAL 11 HOUR),'%Y %m') <= '2014 08'
			and o.Business_1__c = 'Australia'
			and o.StageName='Closed Won'
			and oh.Field = 'StageName'
			and o.Status__c = 'Active'
			group by o.Id) t
left join opportunitylineitem oli on oli.OpportunityId = t.Id
where oli.IsDeleted=0
and oli.Days__c=0 #Exclude Audits, only Fees
and oli.First_Year_Revenue__c =1
group by `stream`, `metric`

union 
#Unit Price Quoted
select 'MS and Food' as 'stream', 'Avg Audit Day Price Quoted' as 'metric', 
sum(if(t.WonPeriod = '2014 07', oli.TotalPrice, null))/sum(if(t.WonPeriod = '2014 07', oli.Days__c, null)) as '2014 07',
sum(if(t.WonPeriod = '2014 08', oli.TotalPrice, null))/sum(if(t.WonPeriod = '2014 08', oli.Days__c, null)) as '2014 08',
sum(if(t.WonPeriod = '2014 09', oli.TotalPrice, null))/sum(if(t.WonPeriod = '2014 09', oli.Days__c, null)) as '2014 09'
from (select o.Id, o.Total_First_Year_Revenue__c, date_format(date_add(min(oh.CreatedDate),INTERVAL 11 HOUR),'%Y %m') as 'WonPeriod' from opportunity o inner join opportunityfieldhistory oh ON oh.OpportunityId = o.Id where o.IsDeleted = 0
			and date_format(date_add(oh.CreatedDate,INTERVAL 11 HOUR),'%Y %m') >= '2014 07'
			and date_format(date_add(oh.CreatedDate,INTERVAL 11 HOUR),'%Y %m') <= '2014 08'
			and o.Business_1__c = 'Australia'
			and o.StageName='Closed Won'
			and oh.Field = 'StageName'
			and o.Status__c = 'Active'
			group by o.Id) t
left join opportunitylineitem oli on oli.OpportunityId = t.Id
where oli.IsDeleted=0
and oli.Days__c>0 #Exclude Audits, only Fees
and oli.First_Year_Revenue__c =1
group by `stream`, `metric`

union 
#Internal FTE Utilisation
select
if (RowName like 'Food%', 'Food', if(RowName like 'MS%', 'MS', 'MS and Food')) as 'Stream',
'FTE Auditor Utilisation' as 'metric', 70 as 'index',
sum(if(ColumnName='2014 07', Value, null)) as '2014 07', 
sum(if(ColumnName='2014 08', Value, null)) as '2014 08', 
sum(if(ColumnName='2014 09', Value, null)) as '2014 09' 
from (
select 
t.*
from (
select * from sf_report_history 
where ReportName='Scheduling Auditors Metrics'
and ColumnName >= '2014 07'
and ColumnName <= '2015 06'
and RowName like '%Utilisation'
order by Date desc) t
group by Region,ColumnName,RowName) t2
group by Region,RowName

#union 
#Contract Auditor Unit Cost (per day) - Not in SF

#union 
#FTE Auditor Unit Cost (per day) - Not in SF

#union 
#Travel Recovery (per day) - Not in SF

union 
#No of Public Training Seats Filled
select 'TIS' as 'Stream', 'No of Registrations (Public)' as 'Metric', '#' as 'Unit', 110 as 'index',
sum(if(date_format(c.Class_Begin_Date__c, '%Y %m') = '2014 07',c.Number_Of_Confirmed_attendees__c,null)) as '2014 07',
sum(if(date_format(c.Class_Begin_Date__c, '%Y %m') = '2014 08',c.Number_Of_Confirmed_attendees__c,null)) as '2014 08',
sum(if(date_format(c.Class_Begin_Date__c, '%Y %m') = '2014 09',c.Number_Of_Confirmed_attendees__c,null)) as '2014 09' 
from training.class__c c
inner join training.recordtype rt on rt.Id = c.RecordTypeId
where rt.Name in ('Generic Class','Public Class')
and c.Class_Status__c not in ('Cancelled')
and c.Product_Code__c not in ('RMS04','RMS05','NAR','Y23','21st')
and c.Name not like '%Budget%'
and c.Name not like '%Conference%'
and c.Class_Location__c not in ('Online')
and date_format(c.Class_Begin_Date__c, '%Y %m') >= '2014 07'
and date_format(c.Class_Begin_Date__c, '%Y %m') <= '2015 06'
and c.IsDeleted = 0
group by `Stream`, `Metric`

#union 
#No of Public Classes

union 
#Average Class Size
select 'TIS' as 'Stream', 'Average Class Size (Public)' as 'Metric',
sum(if(date_format(c.Class_Begin_Date__c, '%Y %m') = '2014 07' and c.Class_Status__c not in ('Cancelled'),1,null))/sum(if(date_format(c.Class_Begin_Date__c, '%Y %m') = '2014 07' ,1,null)) as '2014 07',
sum(if(date_format(c.Class_Begin_Date__c, '%Y %m') = '2014 08' and c.Class_Status__c not in ('Cancelled'),1,null))/sum(if(date_format(c.Class_Begin_Date__c, '%Y %m') = '2014 08' ,1,null)) as '2014 08',
sum(if(date_format(c.Class_Begin_Date__c, '%Y %m') = '2014 09' and c.Class_Status__c not in ('Cancelled'),1,null))/sum(if(date_format(c.Class_Begin_Date__c, '%Y %m') = '2014 09' ,1,null)) as '2014 09' 
from training.class__c c
inner join training.recordtype rt on rt.Id = c.RecordTypeId
where rt.Name in ('Generic Class','Public Class')
and c.Product_Code__c not in ('RMS04','RMS05','NAR','Y23','21st')
and c.Name not like '%Budget%'
and c.Name not like '%Conference%'
and c.Class_Location__c not in ('Online')
and date_format(c.Class_Begin_Date__c, '%Y %m') >= '2014 07'
and date_format(c.Class_Begin_Date__c, '%Y %m') <= '2015 06'
and c.IsDeleted = 0
group by `Stream`, `Metric`

union 
#Public Course Run Rate
select 'TIS' as 'Stream', 'No of Classes (Public)' as 'Metric',
sum(if(date_format(c.Class_Begin_Date__c, '%Y %m') = '2014 07' and c.Class_Status__c not in ('Cancelled'),1,null))/sum(if(date_format(c.Class_Begin_Date__c, '%Y %m') = '2014 07' ,1,null)) as '2014 07',
sum(if(date_format(c.Class_Begin_Date__c, '%Y %m') = '2014 08' and c.Class_Status__c not in ('Cancelled'),1,null))/sum(if(date_format(c.Class_Begin_Date__c, '%Y %m') = '2014 08' ,1,null)) as '2014 08',
sum(if(date_format(c.Class_Begin_Date__c, '%Y %m') = '2014 09' and c.Class_Status__c not in ('Cancelled'),1,null))/sum(if(date_format(c.Class_Begin_Date__c, '%Y %m') = '2014 09' ,1,null)) as '2014 09' 
from training.class__c c
inner join training.recordtype rt on rt.Id = c.RecordTypeId
where rt.Name in ('Generic Class','Public Class')
and c.Product_Code__c not in ('RMS04','RMS05','NAR','Y23','21st')
and c.Name not like '%Budget%'
and c.Name not like '%Conference%'
and c.Class_Location__c not in ('Online')
and date_format(c.Class_Begin_Date__c, '%Y %m') >= '2014 07'
and date_format(c.Class_Begin_Date__c, '%Y %m') <= '2015 06'
and c.IsDeleted = 0
group by `Stream`, `Metric`

#union 
#Average Revenue / Public Seat

#union 
#Trainer Utilisation

#union 
#Customer Satisfaction - Not in SF

#union 
#No Overdue NCRs - Not in SF

#union 
#No Days to Issue Certificate

) t_all
order by `Stream`;


# This is not working as classes are overlapped
select 
concat(
	if (t1.Id in ('0032000000G93bcAAB','00320000017Fxf1AAC','00320000018XX2nAAG', '0032000000vM7uNAAS', '0032000000oDh2pAAC'),t1.Name,''),
	if (t1.Id in ('0032000000G93bcAAB','00320000017Fxf1AAC','00320000018XX2nAAG', '0032000000vM7uNAAS', '0032000000oDh2pAAC') and t2.Id in ('0032000000G93bcAAB','00320000017Fxf1AAC','00320000018XX2nAAG', '0032000000vM7uNAAS', '0032000000oDh2pAAC'),',',''),
	if (t2.Id in ('0032000000G93bcAAB','00320000017Fxf1AAC','00320000018XX2nAAG', '0032000000vM7uNAAS', '0032000000oDh2pAAC'),t2.Name,'')) as 'trainers', 
	c.Id,
c.Class_Begin_Date__c,
c.Class_End_Date__c,
c.Class_Status__c,
	if (date_format(c.Class_End_Date__c, '%Y %m') = '2014 07' or date_format(c.Class_Begin_Date__c, '%Y %m') = '2014 07', datediff(least(c.Class_End_Date__c, '2014-07-31'), greatest(c.Class_Begin_Date__c, '2014-07-01'))+1, null) as '2014 07'
from training.class__c c
left join training.contact t1 on c.Trainer_1__c = t1.Id
left join training.contact t2 on c.Trainer2__c = t2.Id
where 
# Trainers FTE
(t1.Id in ('0032000000G93bcAAB','00320000017Fxf1AAC','00320000018XX2nAAG', '0032000000vM7uNAAS', '0032000000oDh2pAAC')
or t2.Id in ('0032000000G93bcAAB','00320000017Fxf1AAC','00320000018XX2nAAG', '0032000000vM7uNAAS', '0032000000oDh2pAAC'))
and c.Class_Begin_Date__c <= '2014-07-31'
and c.Class_End_Date__c >= '2014-07-01'
and c.IsDeleted=0
and c.Class_Status__c not in ('Cancelled');

create index approval_history_index on approval_history__c (RAudit_Report_Group__c);
create index arg_work_item_index on arg_work_item__c (RAudit_Report_Group__c,RWork_Item__c);

select t.* from (
select 
arg.id as 'ARG_Id',
max(wi.End_Service_Date__c) as 'End Last Audit',
(if(ah.Status__c='Completed', date_add(ah.Timestamp__c, interval 10 hour), null)) as 'Completed'
from audit_report_group__c arg 
inner join arg_work_item__c argwi on arg.id = argwi.RAudit_Report_Group__c 
inner join work_item__c wi on wi.Id = argwi.RWork_Item__c 
inner join approval_history__c ah on arg.Id = ah.RAudit_Report_Group__c
where arg.Client_Ownership__c in ('Australia') 
and arg.IsDeleted = 0 
and wi.IsDeleted = 0 
and wi.Status__c not in ('Cancelled') 
group by arg.id) t
where date_format(t.`Completed`, '%Y %m') >= '2014 07'
and date_format(t.`Completed`, '%Y %m') <= '2014 07'
and t.`End Last Audit` is not null;

select if(t.`Revenue Ownerships` like '%Food%', 'Food', 'MS') as 'Stream', 'No of Days to Issue a Certifcate' as 'Metric', 
	avg(if (date_format(t.`Completed`, '%Y %m') = '2014 07', datediff(t.`Completed`, t.`End Last Audit`), null)) as '2014 07',
	avg(if (date_format(t.`Completed`, '%Y %m') = '2014 08', datediff(t.`Completed`, t.`End Last Audit`), null)) as '2014 08',
	avg(if (date_format(t.`Completed`, '%Y %m') = '2014 09', datediff(t.`Completed`, t.`End Last Audit`), null)) as '2014 09' 
from (
select 
arg.id as 'ARG_Id',
max(wi.End_Service_Date__c) as 'End Last Audit',
group_concat(wi.Revenue_Ownership__c) as 'Revenue Ownerships',
(arg.Admin_Closed__c) as 'Completed'
from audit_report_group__c arg 
inner join arg_work_item__c argwi on arg.id = argwi.RAudit_Report_Group__c 
inner join work_item__c wi on wi.Id = argwi.RWork_Item__c 
where arg.Client_Ownership__c in ('Australia') 
and arg.IsDeleted = 0 
and wi.IsDeleted = 0 
and wi.Status__c not in ('Cancelled') 
and arg.Hold_Reason__c is null
group by arg.id) t
where date_format(t.`Completed`, '%Y %m') >= '2014 07'
and date_format(t.`Completed`, '%Y %m') <= '2014 09'
and t.`End Last Audit` is not null
group by `Stream`, `Metric`;


select c.Id
from training.class__c c
inner join training.recordtype rt on rt.Id = c.RecordTypeId
where rt.Name in ('Generic Class','Public Class')
and c.Product_Code__c not in ('RMS01','RMS02','F29 - Do not use','Y34','RMS04','RMS05','NAR','NARev','Y23','21st')
and c.Name not like '%Budget%'
and c.Name not like '%Conference%'
and c.Name not like '%DO NOT USE%'
and c.Class_Location__c not in ('Online')
and c.Class_Status__c not in ('Cancelled')
and c.Class_Begin_Date__c >= '2013-07-01'
and c.Class_Begin_Date__c <= '2014-06-30'
and c.IsDeleted = 0
limit 2000;