create temporary table delivered_days as
(select * from 
(select 
	if(`Region` like 'Australia%', 'Australia',`Region`) as 'Country', 
    if(RowName like '%Food%', 'Food', if(RowName like '%Product%', 'PS', 'MS')) as `Stream`, 
    ColumnName as `Period`, 
    sum(value) as 'Final Confirmed' 
	from salesforce.sf_report_history 
	where ReportName='Audit Days Snapshot' 
		#and Date = (select max(Date) from salesforce.sf_report_history where ReportName='Audit Days Snapshot') 
		and `Region` not like '%Product%'
		and ColumnName < date_format(now(), '%Y %m') 
		and (RowName not like '%Open%' and RowName not like '%Service Change%' and RowName not like '%Scheduled%' and RowName not like '%Cancelled%') 
	group by date, `Country`,`Stream`,`Period`
    order by `Country`,`Stream`,`Period`, date desc) t
group by `Country`,`Stream`,`Period`);

create temporary table audit_snapshots as
(SELECT 
    rh.`date` as 'Report Date',
	analytics.getRegionFromCountry(if(rh.`Region` like 'Australia%', 'Australia', rh.`Region`) ) as 'Region',
	if(rh.`Region` like 'Australia%', 'Australia', rh.`Region`) as 'Country',
    if(rh.`RowName` like '%Food%','Food', 'MS') as 'Stream',
    ColumnName AS 'Period',
    TRIM(SUBSTRING_INDEX(`RowName`, '-', -(1))) AS 'Status',
    SUM(Value) AS 'Days'
FROM salesforce.`sf_report_history` rh
WHERE
    ReportName = 'Audit Days Snapshot'
	#AND date BETWEEN '2014-07-01' AND NOW()
	AND ColumnName < date_format(now(), '%Y %m')
	#AND `Region` LIKE 'Australia%'
	AND CAST(`Value` AS DECIMAL (10 , 2 )) > 0
	AND `Region` NOT LIKE '%Product%'
	AND `Region` NOT LIKE '%Unknown%'
	AND `RowName` LIKE '%Audit%'
	AND `RowName` LIKE '%Days%'
	AND `RowName` NOT LIKE '%Pending%'
GROUP BY date , rh.`Region`, `Period` , `Status`);

select concat('2015 01', ' 01');
select date_add(date_add(str_to_date(concat('2015 01', ' 01'), '%Y %m %d'), interval 1 month), interval -1 day);

#explain
(select rh.`Report Date`, rh.`Region`, rh.`Country`, rh.`Stream`, rh.`Period`,
date_add(date_add(str_to_date(concat(rh.`Period`, ' 01'), '%Y %m %d'), interval 1 month), interval -1 day) as 'Period End Date',
sum(if(rh.`Status` in ('Open', 'Service Change', 'Draft', 'Initiate Service'), rh.`Days`,0)) as 'Open',
sum(if(rh.`Status` in ('Scheduled', 'Scheduled Offered'), rh.`Days`,0)) as 'Scheduled',
sum(if(rh.`Status` in ('Confirmed', 'In Progress', 'Submitted', 'Under Review', 'Under Review - Rejected', 'Support', 'Completed'), rh.`Days`,0)) as 'Confirmed',
sum(if(rh.`Status` not in ('Cancelled', 'Budget'), rh.`Days`,0)) as 'Available',
fc.`Final Confirmed` as 'Final Confirmed Days',
sum(if(rh.`Status` not in ('Cancelled', 'Budget'), rh.`Days`,0))/fc.`Final Confirmed` as 'Available/Final Confirmed',
timestampdiff(day, rh.`Report Date`, date_add(date_add(str_to_date(concat(rh.`Period`, ' 01'), '%Y %m %d'), interval 1 month), interval -1 day) ) as 'Days to Period End Date'
from audit_snapshots rh
LEFT JOIN delivered_days fc ON rh.`Period` = fc.`Period` and rh.`Stream` = fc.`Stream` and rh.`Country` = fc.`Country`
where date_format(rh.`Report Date`, '%Y %m') <= rh.`Period`
group by  rh.`Report Date`, rh.`Region`, rh.`Country`, rh.`Stream`, rh.`Period`)