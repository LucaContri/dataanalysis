set @today = (select date_format(now(), '%Y-%m-%d'));
set @yesterday = (select date_format(date_add(@today, interval -1 day), '%Y-%m-%d'));
set @week_start = (select date_format(date_add(@today, interval -WEEKDAY(@today) day), '%Y-%m-%d')) ;
set @month_start = (select date_format(@today, '%Y-%m-01'));
set @region = 'APAC';
set @noOfMonths = 6;
set @fy = if(month(utc_timestamp())<7, year(utc_timestamp()), year(utc_timestamp())+1);
set @fy_start = concat(@fy-1,'-07-01');
set @fy_end = concat(@fy,'-06-30');

(select 
 max(date_format(rh.`Date`, '%d/%m/%Y %T')) AS `Report Date`,
    analytics.getRegionFromCountry(analytics.getCountryFromRevenueOwnership(rh.`Region`)) as 'Region',
	analytics.getCountryFromRevenueOwnership(rh.`Region`) as 'Country',
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
where rh.`ReportName` = 'Audit Days Snapshot' and  cast(rh.`Value` as decimal(10,2)) > 0 and  rh.`Region` not like '%Product%' and  rh.`Region` not like '%Unknown%' and  rh.`RowName` like '%Audit%' and  rh.`RowName` like '%Days%' and  rh.`RowName` not like '%Pending%' and  date_format(rh.`Date`,'%Y-%m-%d') in (@today, @yesterday, @week_start, @month_start) and  str_to_date(concat(rh.`ColumnName`,' 01'),'%Y %m %d') <= date_format(date_add(utc_timestamp(), interval @noOfMonths month), '%Y-%m-01') and  analytics.getRegionFromCountry(analytics.getCountryFromRevenueOwnership(rh.`Region`)) = @region
group by `Region`, `Country`, `Stream`, `Audit Status`, `Audit Open SubStatus`, `Period`) 
union all
(select 
 max(date_format(rh.`Date`, '%d/%m/%Y %T')) AS `Report Date`,
    analytics.getRegionFromCountry(analytics.getCountryFromRevenueOwnership(rh.`Region`)) as 'Region2',
	analytics.getCountryFromRevenueOwnership(rh.`Region`) as 'Country',
    if(rh.`RowName` like '%Food%','Food', 'MS') as 'Stream',
    'PFY Completed' as 'Audit Status',
    '' as 'Audit Open SubStatus',
	'PFY Completed' AS `Simple Status`,
    date_format(date_add(str_to_date(concat(rh.`ColumnName`,' 01'),'%Y %m %d'), interval 1 year), '%Y-%m') as 'Period',
 sum(cast(rh.`Value` as decimal(10,2))) AS `today`, 
0,0,0    
from `salesforce`.`sf_report_history` rh
where rh.`ReportName` = 'Audit Days Snapshot' 
and  cast(rh.`Value` as decimal(10,2)) > 0 
and  rh.`Region` not like '%Product%' 
and  rh.`Region` not like '%Unknown%' 
and  rh.`RowName` like '%Audit%' 
and  rh.`RowName` like '%Days%' 
and  rh.`RowName` not like '%Pending%' 
and  date_format(rh.`Date`,'%Y-%m-%d') in (@today) 
and  str_to_date(concat(rh.`ColumnName`,' 01'),'%Y %m %d') <= date_format(date_add(date_add(utc_timestamp(), interval -1 year), interval @noOfMonths month), '%Y-%m-01') 
and  str_to_date(concat(rh.`ColumnName`,' 01'),'%Y %m %d') >= date_format(date_add(utc_timestamp(), interval -1 year), '%Y-%m-01') 
and  analytics.getRegionFromCountry(analytics.getCountryFromRevenueOwnership(rh.`Region`)) = @region
and trim(substring_index(rh.`RowName`,'-',-(1))) = 'Completed'
group by `Region2`, `Country`, `Stream`, `Audit Status`, `Audit Open SubStatus`, `Period`)
union all
(select 
 CreateDate as 'Report Date',
 analytics.getRegionFromCountry(analytics.getCountryFromRevenueOwnership(`Region`)) as 'Region',
 analytics.getCountryFromRevenueOwnership(`Region`) as 'Country',
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
 DataType in ('Audit Days Budget', 'Audit Days Finance Forecast') 
 and date_format(RefDate, '%Y %m') >= date_format(now(), '%Y %m') and date_format(RefDate, '%Y %m') <= date_format(date_add(now(), interval @noOfMonths month), '%Y %m') 
 and analytics.getRegionFromCountry(analytics.getCountryFromRevenueOwnership(`Region`)) = @region
 and current=1 
group by `Region`, `Country`, `Stream`, `Period`, `Audit Status`, `Audit Open SubStatus`)
union all
(select now() as 'Report Date', analytics.getRegionFromCountry(ad.`Country`) as 'Region', ad.`Country`, ad.`Revenue Stream` as 'Stream', 'Forecast Calc' as 'Audit Status', '' as 'Audit Open SubStatus', 'Forecast Calc' as 'Simple Status', replace(ad.`forecast period`,' ', '-') as 'Period', ad.`Available Days`/forecast.`Forecast Factor` as 'today', 0 as 'yesterday', 0 as 'week start', 0 as 'month start' 
from 
(select `Region`, analytics.getCountryFromRevenueOwnership(`Region`) as 'Country', `Revenue Stream`, fp.`forecast period`, sum(Value) as 'Available Days' 
from salesforce.financial_visisbility_latest, (select date_format(wd.`date`, '%Y %m') as 'forecast period' from salesforce.sf_working_days wd where date between now() and date_add(now(), interval 6 month) group by `forecast period`) fp
where (analytics.getCountryFromRevenueOwnership(`Region`) in ('Australia', 'Asia Regional Desk', 'China', 'India', 'Indonesia', 'Japan', 'Korea', 'Thailand') ) and `Region` not like '%Product%' and `Period` = fp.`forecast period`  and `Audit Status` not in ('Cancelled') and (`Audit Open SubStatus` not in ('Pending Cancellation', 'Pending Suspension') or `Audit Open SubStatus` is null)
group by `Country`, `Revenue Stream`, fp.`forecast period`) as ad
left join
(select t1.`Country`, t1.`Revenue Stream`, t1.`forecast period`, avg(t1.`Available Days`/t2.`Final Confirmed`) as 'Forecast Factor' from (
select analytics.getCountryFromRevenueOwnership(`Region`) as 'Country', `Revenue Stream`, str_to_date(`Report Date-Time`,'%d/%m/%Y - %T') as 'Snapshot Date', fp.`forecast period`, `Period`, sum(Value) as 'Available Days' 
from salesforce.financial_visisbility, (select date_format(wd.`date`, '%Y %m') as 'forecast period' from salesforce.sf_working_days wd where date between now() and date_add(now(), interval 6 month) group by `forecast period`) fp
where (analytics.getCountryFromRevenueOwnership(`Region`) in ('Australia', 'Asia Regional Desk', 'China', 'India', 'Indonesia', 'Japan', 'Korea', 'Thailand') ) and `Region` not like '%Product%' and `Period` < fp.`forecast period` and `Period` > date_format(date_Add(now(), interval -4 month), '%Y %m') and `Period` < date_format(now(), '%Y %m') and `Audit Status` not in ('Cancelled') and (`Audit Open SubStatus` not in ('Pending Cancellation', 'Pending Suspension') or `Audit Open SubStatus` is null) and datediff(str_to_date(concat(`Period`, ' 01'), '%Y %m %d'), str_to_date(`Report Date-Time`,'%d/%m/%Y - %T')) = datediff(str_to_date(concat(fp.`forecast period`,' 01'), '%Y %m %d'),now()) 
group by `Country`,`Revenue Stream`, `Snapshot Date`, fp.`forecast period`, `Period` order by `Country`,`Revenue Stream`, `Period` ) t1 
left join ( 
select analytics.getCountryFromRevenueOwnership(`Region`) as 'Country', if(RowName like '%Food%', 'Food', if(RowName like '%Product%', 'PS', 'MS')) as `Revenue Stream`, ColumnName as `Period`, sum(value) as 'Final Confirmed' from salesforce.sf_report_history 
where ReportName='Audit Days Snapshot' and Date = (select max(Date) from salesforce.sf_report_history where ReportName='Audit Days Snapshot') and `Region` not like '%Product%' and (analytics.getCountryFromRevenueOwnership(`Region`) in ('Australia', 'Asia Regional Desk', 'China', 'India', 'Indonesia', 'Japan', 'Korea', 'Thailand') ) and ColumnName < date_format(now(), '%Y %m') and (RowName not like '%Open%' and RowName not like '%Service Change%' and RowName not like '%Scheduled%' and RowName not like '%Cancelled%') 
group by `Country`,`Revenue Stream`,`Period`) t2 on t2.`Period` = t1.`Period` and t2.`Country` = t1.`Country` and t2.`Revenue Stream` = t1.`Revenue Stream`
group by t1.`Country`, t1.`Revenue Stream`, t1.`forecast period`) forecast on ad.Country = forecast.Country and ad.`Revenue Stream` = forecast.`Revenue Stream` and ad.`forecast period`= forecast.`forecast period`
group by ad.`Country`, ad.`Revenue Stream`, ad.`forecast period`)
union all
(select 
 CreateDate as 'Report Date',
 analytics.getRegionFromCountry(analytics.getCountryFromRevenueOwnership(`Region`)) as 'Region',
 analytics.getCountryFromRevenueOwnership(`Region`) as 'Country', 'TIS' AS 'Stream', RefName as 'Audit Status', 'PFY Actual' as 'Audit Open SubStatus', '' as 'Simple Status',  date_format(date_add(RefDate, interval 1 year), '%Y-%m') as 'Period', sum(RefValue) as 'today' , 0 as 'yesterday', 0 as 'week start', 0 as 'month start'
from salesforce.sf_data 
where 
 DataType = 'Peoplesoft' 
 and DataSubType = 'Revenue'
 and refDate between date_add(@fy_start, interval -1 year) and  date_add(@fy_end, interval -1 year) 
 and analytics.getRegionFromCountry(analytics.getCountryFromRevenueOwnership(`Region`)) = @region
 and current=1 
group by `Region`, `Country`, `Stream`, `Period`, `Audit Status`, `Audit Open SubStatus`)
union all
(select 
 t.Date as 'Report Date', 'APAC' as 'Region', 'Australia' as 'Country', 'TIS' as 'Stream', 'eLearning' as 'Audit Status', 'Actual' as 'Audit Open SubStatus', '' as 'Simple Status', date_format(t.Date, '%Y-%m') as 'Period', sum(t.Amount) as 'today', sum(if(t.`Date`=@yesterday, t.Amount,0)) as 'yesterday', sum(if(t.`Date`>=@week_start, t.Amount,0)) as 'week start', sum(if(t.`Date`>=@month_start, t.Amount,0)) as 'month start'
from (
(select 
i.Id,
date_format(date_add(max(ih.CreatedDate), INTERVAL 10 HOUR), '%Y-%m-%d') as 'Date', 
if(i.GST_Exempt__c, i.Total_Amount__c, i.Total_Amount__c/1.1) as 'Amount' 
from training.registration__c r 
inner join training.recordtype rt on r.RecordTypeId = rt.Id 
inner join training.invoice_ent__c i ON i.Registration__c = r.Id 
inner join training.invoice_ent__history ih on ih.ParentId = i.id 
where r.Course_Type__c = 'eLearning'  and  rt.Name not like 'TIS - AMER%'  and  ih.Field='Processed__c' and ih.NewValue='true'  and  ih.CreatedDate  >= @fy_start  and  ih.CreatedDate <= @fy_end 
group by i.Id) 
union all
(select 
pa.id,
date_format(date_add(max(ih.CreatedDate), INTERVAL 10 HOUR), '%Y-%m-%d') as 'Date', 
if(pa.GST_Exempt__c, pa.Total_Amount__c, pa.Total_Amount__c/1.1) as 'Amount' 
from training.registration__c r 
inner join training.recordtype rt on r.RecordTypeId = rt.Id 
inner join training.invoice_ent__c pa ON pa.Registration__c = r.Id 
inner join training.invoice_ent__c i ON i.Prior_Adjustment__c = pa.Name 
inner join training.invoice_ent__history ih on ih.ParentId = i.id 
where r.Course_Type__c = 'eLearning'  and  rt.Name not like 'TIS - AMER%'  and  ih.Field='Processed__c' and ih.NewValue='true'  and  i.Invoice_Type__c = 'ARB' and  ih.CreatedDate  >= @fy_start  and  ih.CreatedDate <= @fy_end
group by i.Id)) t 
where t.Date >= @fy_start and  t.Date <= @fy_end
group by t.`Date` order by t.`Date`)
union all
(select t2.`Class_Begin_Date__c` as 'Report Date', 'APAC' as 'Region', 'Australia' as 'Country', 'TIS' as 'Stream', 'public' as 'Audit Status', 'Actual' as 'Audit Open SubStatus', '' as 'Simple Status', date_format(t2.`Class_Begin_Date__c`, '%Y-%m') as 'Period', t2.`Amount` as 'today', if(t2.`Date`=@yesterday, t2.`Amount`,0) as 'yesterday', if(t2.`Date`>=@week_start, t2.`Amount`,0) as 'week start', if(t2.`Date`>=@month_start, t2.`Amount`,0) as 'month start'
from (
(select t.`Date`, t.`Date` as 'Class_Begin_Date__c', t.`Date` as 'Class_End_Date__c', sum(t.Amount) as 'Amount' from (
select 
date_format(date_add(max(if(ih.Field='Processed__c' and ih.NewValue='true', ih.CreatedDate, i.CreatedDate)), INTERVAL 10 HOUR), '%Y-%m-%d') as 'Date', 
i.Total_Amount__c/1.1 as 'Amount' 
from training.registration__c r 
inner join training.recordtype rt on r.RecordTypeId = rt.Id 
inner join training.invoice_ent__c i ON i.Registration__c = r.Id 
left join training.invoice_ent__history ih on ih.ParentId = i.id 
where (r.Course_Type__c not in ('eLearning') or i.Accounting__c is null)  and  rt.Name not like 'TIS - AMER%'  and  i.Bill_Type__c = 'ADF'  and  r.NZ_AFS__c = 0  and  r.Coles_Brand_Employee__c = 0  and  r.Error__c = 0  and  r.Status__c not in ('Pending')  and  i.Processed__c = 1  and  (i.Accounting__c not like ('PRC_HACCP%') or i.Accounting__c is null) 
group by i.Id) t 
where t.`Date`>= @fy_start  and  t.`Date`<= @fy_end  and  t.`Amount` is not null 
group by t.`Date` 
order by t.`Date`) 
union (select t.`Date`, t.`Date` as 'Class_Begin_Date__c', t.`Date` as 'Class_End_Date__c', sum(t.Amount) as 'Amount' from ( 
select 
date_format(date_add(max(if(ih.Field='Processed__c' and ih.NewValue='true', ih.CreatedDate, i.CreatedDate)), INTERVAL 10 HOUR), '%Y-%m-%d') as 'Date', 
if(i.From_Date__c is null, r.Class_Begin_Date__c, i.From_Date__c ) as 'Class_Begin_Date__c', 
if(i.To_Date__c is null, r.Class_End_Date__c, i.To_Date__c) as 'Class_End_Date__c', 
if(i.GST_Exempt__c, i.Total_Amount__c, i.Total_Amount__c/1.1) as 'Amount' 
from training.registration__c r 
inner join training.recordtype rt on r.RecordTypeId = rt.Id 
inner join training.invoice_ent__c i ON i.Registration__c = r.Id 
left join training.invoice_ent__history ih on ih.ParentId = i.id 
where (r.Course_Type__c not in ('eLearning') or i.Accounting__c is null)  and  rt.Name not like 'TIS - AMER%'  and  i.Bill_Type__c not in ('ADF')  and  r.NZ_AFS__c = 0  and  r.Coles_Brand_Employee__c = 0  and  r.Error__c = 0  and  r.Status__c not in ('Pending')  and  i.Processed__c = 1  and  (i.Accounting__c not like ('PRC_HACCP%') or i.Accounting__c is null) 
group by i.Id) t 
where t.`Date`>= @fy_start  and  t.`Date`<= @fy_end  and  (t.`Date` >= t.Class_Begin_Date__c or t.Class_Begin_Date__c is null)  and  t.`Amount` is not null 
group by t.`Date` 
order by t.`Date`
) union 
(select t.`Date`, t.Class_Begin_Date__c, t.Class_End_Date__c, sum(t.Amount) as 'Amount' from ( 
select 
date_format(date_add(max(if(ih.Field='Processed__c' and ih.NewValue='true', ih.CreatedDate, i.CreatedDate)), INTERVAL 10 HOUR), '%Y-%m-%d') as 'Date', 
if(i.From_Date__c is null, r.Class_Begin_Date__c, i.From_Date__c ) as 'Class_Begin_Date__c', 
if(i.To_Date__c is null, r.Class_End_Date__c, i.To_Date__c) as 'Class_End_Date__c', 
if(i.GST_Exempt__c, i.Total_Amount__c, i.Total_Amount__c/1.1) as 'Amount' 
from training.registration__c r 
inner join training.recordtype rt on r.RecordTypeId = rt.Id 
inner join training.invoice_ent__c i ON i.Registration__c = r.Id 
left join training.invoice_ent__history ih on ih.ParentId = i.id 
where (r.Course_Type__c not in ('eLearning') or i.Accounting__c is null)  and  rt.Name not like 'TIS - AMER%'  and  i.Bill_Type__c not in ('ADF')  and  r.NZ_AFS__c = 0  and  r.Coles_Brand_Employee__c = 0  and  r.Error__c = 0  and  r.Status__c not in ('Pending')  and  i.Processed__c = 1  and  (i.Accounting__c not like ('PRC_HACCP%') or i.Accounting__c is null) 
group by i.Id) t 
where t.`Date` < t.Class_Begin_Date__c  and  t.Class_Begin_Date__c <= @fy_end  and  t.Class_Begin_Date__c >= @fy_start  and  t.`Amount` is not null 
group by t.`Date`, t.Class_Begin_Date__c, t.Class_End_Date__c 
order by t.Class_Begin_Date__c)) t2 order by t2.Class_Begin_Date__c)
union all
(select c.Class_End_Date__c as 'Report Date', 'APAC' as 'Region', 'Australia' as 'Country', 'TIS' as 'Stream', 'inhouse' as 'Audit Status', 'Actual' as 'Audit Open SubStatus', '' as 'Simple Status', date_format(c.Class_End_Date__c, '%Y-%m') as 'Period', sum(Total_Course_Base_Price__c) as 'today', sum(if(date_format(ihe.CreatedDate,'%-%m-%d')=@yesterday, Total_Course_Base_Price__c, 0)) as 'yesterday', sum(if(date_format(ihe.CreatedDate,'%-%m-%d')=@week_start, Total_Course_Base_Price__c, 0)) as 'week start', sum(if(date_format(ihe.CreatedDate,'%-%m-%d')=@month_start, Total_Course_Base_Price__c, 0)) as 'month start'
from training.In_House_Event__c ihe 
inner join training.class__c c on ihe.Class__c = c.Id 
inner join training.RecordType rt on c.RecordTypeId = rt.Id 
where ihe.Status__c not in ('Cancelled','Postponed')  and rt.Name not like 'TIS - AMER%'  and c.Class_Status__c not in ('Cancelled','Postponed')  and date_format(date_add(c.Class_End_Date__c, interval 11 hour),'%Y-%m-%d') >= @fy_start  and date_format(date_add(c.Class_End_Date__c, interval 11 hour),'%Y-%m-%d') <= @fy_end  and (c.Name not like '%Actual%' and c.Name not like '%Budget%')  and c.RecordTypeId = '012200000000YGcAAM'  
group by ihe.id order by c.Class_End_Date__c)
union all
(select wd.Date as 'Report Date', 'APAC' as 'Region', 'Australia' as 'Country', 'TIS' as 'Stream', d.DataSubType as 'Audit Status', 'Budget' as 'Audit Open SubStatus', '' as 'Simple Status', date_format(wd.Date, '%Y-%m') as 'Period', d.RefValue/(select count(Date) from salesforce.sf_working_days where date_format(Date,'%Y-%m')=date_format(d.RefDate,'%Y-%m')) as 'today', 0 as 'yesterday', 0 as 'week start', 0 as 'month start'
from salesforce.sf_working_days wd left join salesforce.sf_data d on date_format(d.RefDate, '%Y-%m') = date_format(wd.date, '%Y-%m')
where d.DataType='Training'  and d.DataSubType in ('eLearning', 'public', 'inhouse')  and d.RefName='budget'  and wd.Date >= @fy_start  and wd.date <= @fy_end order by wd.date)
union all
(select utc_timestamp(), analytics.getRegionFromCountry(c.country) as 'Region', c.country, s.stream, ss.`Simple Status` as 'Audit Status', '' as 'Audit Open SubStatus', ss.`Simple Status`, p.`Period`,  0 AS `today`, 0 AS `yesterday`,0 AS `week start`,0 AS `month start` from 
(select date_format(wd.date, '%Y-%m') as 'Period' from salesforce.sf_working_days wd where wd.date between utc_timestamp() and date_add(utc_timestamp(), interval @noOfMonths month) group by `Period`) p,
(select 'Australia' as 'country' union select 'India' union select 'Asia Regional Desk' union select 'China' union select 'Indonesia' union select 'Japan' union select 'Korea' union select 'Thailand') c,
(select 'MS' as 'stream' union select 'Food') s,
(select 'Scheduled' as 'Simple Status' union select 'Confirmed' union select 'Open' union select 'Budget' union select 'Forecast Calc' union select 'Forecast Fin') ss);

# Finance Forecast Data Entry
select * from salesforce.sf_data where DataType in ('Audit Days Forecast Calculated');

INSERT INTO salesforce.sf_data VALUES(null,'2016-06-09','Australia - MS','Audit Days Finance Forecast','MS','Forecast','2016-07-01',1077,null,1);
INSERT INTO salesforce.sf_data VALUES(null,'2016-06-09','Australia - MS','Audit Days Finance Forecast','MS','Forecast','2016-08-01',1127,null,1);
INSERT INTO salesforce.sf_data VALUES(null,'2016-06-09','Australia - MS','Audit Days Finance Forecast','MS','Forecast','2016-09-01',1200,null,1);
INSERT INTO salesforce.sf_data VALUES(null,'2016-06-09','Australia - MS','Audit Days Finance Forecast','MS','Forecast','2016-10-01',1077,null,1);
INSERT INTO salesforce.sf_data VALUES(null,'2016-06-09','Australia - MS','Audit Days Finance Forecast','MS','Forecast','2016-11-01',1162,null,1);
INSERT INTO salesforce.sf_data VALUES(null,'2016-06-09','Australia - MS','Audit Days Finance Forecast','MS','Forecast','2016-12-01',807,null,1);
INSERT INTO salesforce.sf_data VALUES(null,'2016-06-09','Australia - MS','Audit Days Finance Forecast','MS','Forecast','2017-01-01',573,null,1);
INSERT INTO salesforce.sf_data VALUES(null,'2016-06-09','Australia - MS','Audit Days Finance Forecast','MS','Forecast','2017-02-01',1049,null,1);
INSERT INTO salesforce.sf_data VALUES(null,'2016-06-09','Australia - MS','Audit Days Finance Forecast','MS','Forecast','2017-03-01',1315,null,1);
INSERT INTO salesforce.sf_data VALUES(null,'2016-06-09','Australia - MS','Audit Days Finance Forecast','MS','Forecast','2017-04-01',978,null,1);
INSERT INTO salesforce.sf_data VALUES(null,'2016-06-09','Australia - MS','Audit Days Finance Forecast','MS','Forecast','2017-05-01',1197,null,1);
INSERT INTO salesforce.sf_data VALUES(null,'2016-06-09','Australia - MS','Audit Days Finance Forecast','MS','Forecast','2017-06-01',1158,null,1);
INSERT INTO salesforce.sf_data VALUES(null,'2016-06-09','Australia - Food','Audit Days Finance Forecast','Food','Forecast','2016-07-01',267,null,1);
INSERT INTO salesforce.sf_data VALUES(null,'2016-06-09','Australia - Food','Audit Days Finance Forecast','Food','Forecast','2016-08-01',237,null,1);
INSERT INTO salesforce.sf_data VALUES(null,'2016-06-09','Australia - Food','Audit Days Finance Forecast','Food','Forecast','2016-09-01',275,null,1);
INSERT INTO salesforce.sf_data VALUES(null,'2016-06-09','Australia - Food','Audit Days Finance Forecast','Food','Forecast','2016-10-01',303,null,1);
INSERT INTO salesforce.sf_data VALUES(null,'2016-06-09','Australia - Food','Audit Days Finance Forecast','Food','Forecast','2016-11-01',252,null,1);
INSERT INTO salesforce.sf_data VALUES(null,'2016-06-09','Australia - Food','Audit Days Finance Forecast','Food','Forecast','2016-12-01',223,null,1);
INSERT INTO salesforce.sf_data VALUES(null,'2016-06-09','Australia - Food','Audit Days Finance Forecast','Food','Forecast','2017-01-01',176,null,1);
INSERT INTO salesforce.sf_data VALUES(null,'2016-06-09','Australia - Food','Audit Days Finance Forecast','Food','Forecast','2017-02-01',309,null,1);
INSERT INTO salesforce.sf_data VALUES(null,'2016-06-09','Australia - Food','Audit Days Finance Forecast','Food','Forecast','2017-03-01',309,null,1);
INSERT INTO salesforce.sf_data VALUES(null,'2016-06-09','Australia - Food','Audit Days Finance Forecast','Food','Forecast','2017-04-01',287,null,1);
INSERT INTO salesforce.sf_data VALUES(null,'2016-06-09','Australia - Food','Audit Days Finance Forecast','Food','Forecast','2017-05-01',319,null,1);
INSERT INTO salesforce.sf_data VALUES(null,'2016-06-09','Australia - Food','Audit Days Finance Forecast','Food','Forecast','2017-06-01',271,null,1);
