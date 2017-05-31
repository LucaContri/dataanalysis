use salesforce;
describe sf_data;

select 
date_format(CreateDate, '%Y-%m-%d') as 'Forecast Date', 
t.`Confirmed`, 
sum(RefValue) as 'August Forecast', 
(select 
	sum(if(ColumnName='2014 08',Value, null)) as '2014 08'
	from sf_report_history 
	where ReportName = 'Audit Days Snapshot' 
	and Region like '%Australia%'
	and Date = (select max(Date) from sf_report_history where ReportName = 'Audit Days Snapshot' and Region like '%Australia%')
	and (RowName like 'Food%' or RowName like 'MS%')
	and (RowName like '%Confirmed' or RowName like '%In Progress' or RowName like '%Complete%' or RowName like '%Under Review%' or RowName like '%Submitted' or RowName like '%Support')
	and ColumnName = '2014 08' ) as 'Actual Confirmed'
from sf_data 
inner join 
(select 
date_format(Date, '%Y-%m-%d') as 'Date',
sum(Value) as 'Confirmed'
from sf_report_history 
where ReportName = 'Audit Days Snapshot' 
and Region like '%Australia%'
and (RowName like 'Food%' or RowName like 'MS%')
and (RowName like '%Confirmed' or RowName like '%In Progress' or RowName like '%Complete%' or RowName like '%Under Review%' or RowName like '%Submitted' or RowName like '%Support')
and ColumnName = '2014 08'
group by `Date`) t on t.`Date` = date_format(CreateDate, '%Y-%m-%d')
where DataType='Audit Days Forecast Calculated' 
and RefDate='2014-08-01 00:00:00'
group by CreateDate
order by CreateDate;

(select f.CreateDate as 'Forecast Date', f.DataSubType as 'Stream', date_format(f.RefDate, '%Y %m') as 'Period', f.RefValue as 'Forecast', fc.`Final Confirmed`
from salesforce.sf_data f
left join analytics.delivered_days fc ON date_format(f.RefDate, '%Y %m') = fc.`Period` and f.DataSubType = fc.`Stream` and 'Australia' = fc.`Country`
where DataType='Audit Days Forecast Calculated' 
and Region like 'Australia%');