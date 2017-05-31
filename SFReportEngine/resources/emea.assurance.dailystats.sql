set @today = (select date_format(now(), '%Y-%m-%d'));
set @yesterday = (select date_format(date_add(@today, interval -1 day), '%Y-%m-%d'));
set @week_start = (select date_format(date_add(@today, interval -WEEKDAY(@today) day), '%Y-%m-%d')) ;
set @month_start = (select date_format(@today, '%Y-%m-01'));
set @region = 'EMEA';
set @noOfMonths = 6;
set @fy = if(month(utc_timestamp())<7, year(utc_timestamp()), year(utc_timestamp())+1);
set @fy_start = concat(@fy-1,'-07-01');
set @fy_end = concat(@fy,'-06-30');

(select 
 max(date_format(rh.`Date`, '%d/%m/%Y %T')) AS `Report Date`,
    analytics.getRegionFromCountry(analytics.getCountryFromRevenueOwnership(rh.`Region`) ) as 'Region',
 replace(analytics.getCountryFromRevenueOwnership(rh.`Region`), 'United Kingdom', 'UK') as 'Country',
    if(rh.`RowName` like '%Food%','Food', 'MS') as 'Stream',
    trim(substring_index(rh.`RowName`,'-',-(1))) as 'Audit Status',
    ifnull(if((trim(substring_index(trim(substring_index(rh.`RowName`,'-',-(2))),'-',1)) in ('Days','Under Review','')),NULL,trim(substring_index(trim(substring_index(rh.`RowName`,'-',-(2))),'-',1))),'') as 'Audit Open SubStatus',
 if(trim(substring_index(rh.`RowName`,'-',-(1))) in ('Open','Service Change'),
  'Open',
        if(trim(substring_index(rh.`RowName`,'-',-(1))) like 'Scheduled%',
   'Scheduled',
             if(trim(substring_index(rh.`RowName`,'-',-(1))) = 'Cancelled',
    'Cancelled',
    'Confirmed'
   )
  )
    ) AS `Simple Status`,
    
    if(str_to_date(concat(rh.`ColumnName`,' 01'),'%Y %m %d')<date_format(now(),'%Y-%m-01'),
  ' Backlog',
  date_format(str_to_date(concat(rh.`ColumnName`,' 01'),'%Y %m %d'), '%Y-%m')) as 'Period',
 sum(if((str_to_date(concat(rh.`ColumnName`,' 01'),'%Y %m %d')>=date_format(now(),'%Y-%m-01') or trim(substring_index(rh.`RowName`,'-',-(1))) in ('Open', 'Service Change')) and date_format(rh.`Date`,'%Y-%m-%d') = @today, cast(rh.`Value` as decimal(10,2)),0)) AS `today`, 
    sum(if((str_to_date(concat(rh.`ColumnName`,' 01'),'%Y %m %d')>=date_format(now(),'%Y-%m-01') or trim(substring_index(rh.`RowName`,'-',-(1))) in ('Open', 'Service Change')) and date_format(rh.`Date`,'%Y-%m-%d') = @yesterday, cast(rh.`Value` as decimal(10,2)),0)) AS `yesterday`,
    sum(if((str_to_date(concat(rh.`ColumnName`,' 01'),'%Y %m %d')>=date_format(now(),'%Y-%m-01') or trim(substring_index(rh.`RowName`,'-',-(1))) in ('Open', 'Service Change')) and date_format(rh.`Date`,'%Y-%m-%d') = @week_start, cast(rh.`Value` as decimal(10,2)),0)) AS `week start`,
    sum(if((str_to_date(concat(rh.`ColumnName`,' 01'),'%Y %m %d')>=date_format(now(),'%Y-%m-01') or trim(substring_index(rh.`RowName`,'-',-(1))) in ('Open', 'Service Change')) and date_format(rh.`Date`,'%Y-%m-%d') = @month_start, cast(rh.`Value` as decimal(10,2)),0)) AS `month start`
    
from `salesforce`.`sf_report_history` rh
where rh.`ReportName` = 'Audit Days Snapshot' and  cast(rh.`Value` as decimal(10,2)) > 0 and  rh.`Region` not like '%Product%' and  rh.`Region` not like '%Unknown%' and  rh.`RowName` like '%Audit%' and  rh.`RowName` like '%Days%' and  rh.`RowName` not like '%Pending%' and  date_format(rh.`Date`,'%Y-%m-%d') in (@today, @yesterday, @week_start, @month_start) and  str_to_date(concat(rh.`ColumnName`,' 01'),'%Y %m %d') <= date_format(date_add(utc_timestamp(), interval @noOfMonths month), '%Y-%m-01') and  analytics.getRegionFromCountry(analytics.getCountryFromRevenueOwnership(rh.`Region`) ) = @region
group by `Region`, `Country`, `Stream`, `Audit Status`, `Audit Open SubStatus`, `Period`) 
union all
(select 
 CreateDate as 'Report Date',
 analytics.getRegionFromCountry(analytics.getCountryFromRevenueOwnership(`Region`)) as 'Region',
 replace(analytics.getCountryFromRevenueOwnership(`Region`), 'United Kingdom', 'UK') as 'Country',
 DataSubType AS 'Stream', 
 if(DataType = 'Audit Days Budget', 'Budget', if(DataType='Audit Days Forecast Calculated', 'Forecast Calc', 'Forecast Fin')) as 'Audit Status',
 '' as 'Audit Open SubStatus',
 if(DataType = 'Audit Days Budget', 'Budget', if(DataType='Audit Days Forecast Calculated', 'Forecast Calc', 'Forecast Fin')) as 'Simple Status',  
 date_format(RefDate, '%Y-%m') as 'Period', 
 sum(RefValue) as 'today' ,
    0 as 'yesterday',
    0 as 'week start',
    0 as 'month start'
from salesforce.sf_data 
where 
 DataType in ('Audit Days Forecast Calculated', 'Audit Days Budget', 'Audit Days Finance Forecast') 
 and date_format(RefDate, '%Y %m') >= date_format(now(), '%Y %m') and date_format(RefDate, '%Y %m') <= date_format(date_add(now(), interval @noOfMonths month), '%Y %m') 
 and analytics.getRegionFromCountry(analytics.getCountryFromRevenueOwnership(`Region`)) = @region
 and current=1 
group by `Region`, `Country`, `Stream`, `Period`, `Audit Status`, `Audit Open SubStatus`)
union all
(select utc_timestamp(), analytics.getRegionFromCountry(c.country) as 'Region', c.country, s.stream, ss.`Simple Status` as 'Audit Status', '' as 'Audit Open SubStatus', ss.`Simple Status`, p.`Period`,  0 AS `today`, 0 AS `yesterday`,0 AS `week start`,0 AS `month start` 
from 
(select date_format(wd.date, '%Y-%m') as 'Period' from salesforce.sf_working_days wd where wd.date between utc_timestamp() and date_add(utc_timestamp(), interval @noOfMonths month) group by `Period`) p,
(select 'Czech Republic' as 'country' union  select 'Egypt' union select 'France' union select 'Germany' union select 'Ireland' union select 'Italy' union select 'Poland' union select 'Russia' union select 'South Africa' union select 'Spain' union select 'Sweden' union select 'Turkey' union select 'UK') c,
(select 'MS' as 'stream' union select 'Food') s,
(select 'Scheduled' as 'Simple Status' union select 'Confirmed' union select 'Open' union select 'Budget' union select 'Forecast Calc' union select 'Forecast Fin') ss);