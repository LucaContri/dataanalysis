set @period_to_forecast = '2015 06';
set @stream = 'MS';

select 
(select sum(Value) as 'Available Days' 
from financial_visisbility_latest 
where `Region` like 'Australia%' 
and `Revenue Stream` = @stream
and `Period` = @period_to_forecast
and `Audit Status` not in ('Cancelled') 
and (`Audit Open SubStatus` not in ('Pending Cancellation', 'Pending Suspension') or `Audit Open SubStatus` is null))
/
(select avg(t1.`Available Days`/t2.`Final Confirmed`) from (
select str_to_date(`Report Date-Time`,'%d/%m/%Y - %T') as 'Snapshot Date', `Period`, sum(Value) as 'Available Days' 
from financial_visisbility 
where `Region` like 'Australia%' 
and `Revenue Stream` = @stream
and `Period` < @period_to_forecast
and `Period` < date_format(now(), '%Y %m')
and `Audit Status` not in ('Cancelled') 
and (`Audit Open SubStatus` not in ('Pending Cancellation', 'Pending Suspension') or `Audit Open SubStatus` is null)
and datediff(str_to_date(concat(`Period`, ' 01'), '%Y %m %d'), str_to_date(`Report Date-Time`,'%d/%m/%Y - %T')) = datediff(str_to_date(concat(@period_to_forecast, ' 01'), '%Y %m %d'),now()) 
group by `Snapshot Date`, `Period` order by `Period` desc limit 3) t1
left join (
select ColumnName as `Period`, sum(value) as 'Final Confirmed' from sf_report_history 
	where ReportName='Audit Days Snapshot' 
    and Date = (select max(Date) from sf_report_history where ReportName='Audit Days Snapshot') 
    and Region like 'Australia%' 
    and ColumnName < @period_to_forecast
	and ColumnName < date_format(now(), '%Y %m')
    and RowName like concat(@stream, '%') 
    and (RowName not like '%Open%' and RowName not like '%Service Change%' and RowName not like '%Scheduled%' and RowName not like '%Cancelled%')
    group by `Period`
) t2 on t2.`Period` = t1.`Period`) as 'Forecast';