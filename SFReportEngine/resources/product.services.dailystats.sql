
set @today = (select date_format(now(), '%Y-%m-%d'));
set @yesterday = (select date_format(date_add(@today, interval -1 day), '%Y-%m-%d'));
set @week_start = (select date_format(date_add(@today, interval -WEEKDAY(@today) day), '%Y-%m-%d')) ;
set @month_start = (select date_format(@today, '%Y-%m-01'));

select 
	max(date_format(rh.`Date`, '%d/%m/%Y %T')) AS `Report Date`,
    trim(substring_index(rh.`RowName`,'-',-(1))) as 'Audit Status',
    if((trim(substring_index(trim(substring_index(rh.`RowName`,'-',-(2))),'-',1)) in ('Days','Under Review','')),NULL,trim(substring_index(trim(substring_index(rh.`RowName`,'-',-(2))),'-',1))) as 'Audit Open SubStatus',
	if(trim(substring_index(rh.`RowName`,'-',-(1))) in ('Open','Service Change'),
		'Open',
        if(trim(substring_index(rh.`RowName`,'-',-(1))) = 'Scheduled',
			'Scheduled',
            if(trim(substring_index(rh.`RowName`,'-',-(1))) = 'Scheduled Offered',
				'Scheduled - Offered',
				if(trim(substring_index(rh.`RowName`,'-',-(1)))='Cancelled',
					'Cancelled',
					if(trim(substring_index(rh.`RowName`,'-',-(1))) in ('Confirmed', 'In Progress'),
						'Confirmed',
						'Done'
					)
				)
			)
		)
	) AS `Simple Status`,
    
    if(str_to_date(concat(rh.`ColumnName`,' 01'),'%Y %m %d')<date_format(now(),'%Y-%m-01'),
		' Backlog',
		date_format(str_to_date(concat(rh.`ColumnName`,' 01'),'%Y %m %d'), '%Y-%m')) as 'Period',
	sum(if((str_to_date(concat(rh.`ColumnName`,' 01'),'%Y %m %d')>=date_format(now(),'%Y-%m-01') or trim(substring_index(rh.`RowName`,'-',-(1))) in ('Open', 'Service Change', 'Scheduled', 'Scheduled - Offered', 'Confirmed', 'In Progress')) and date_format(rh.`Date`,'%Y-%m-%d') = @today, cast(rh.`Value` as decimal(10,2)),0)) AS `today`, 
    sum(if((str_to_date(concat(rh.`ColumnName`,' 01'),'%Y %m %d')>=date_format(now(),'%Y-%m-01') or trim(substring_index(rh.`RowName`,'-',-(1))) in ('Open', 'Service Change', 'Scheduled', 'Scheduled - Offered', 'Confirmed', 'In Progress')) and date_format(rh.`Date`,'%Y-%m-%d') = @yesterday, cast(rh.`Value` as decimal(10,2)),0)) AS `yesterday`,
    sum(if((str_to_date(concat(rh.`ColumnName`,' 01'),'%Y %m %d')>=date_format(now(),'%Y-%m-01') or trim(substring_index(rh.`RowName`,'-',-(1))) in ('Open', 'Service Change', 'Scheduled', 'Scheduled - Offered', 'Confirmed', 'In Progress')) and date_format(rh.`Date`,'%Y-%m-%d') = @week_start, cast(rh.`Value` as decimal(10,2)),0)) AS `week start`,
    sum(if((str_to_date(concat(rh.`ColumnName`,' 01'),'%Y %m %d')>=date_format(now(),'%Y-%m-01') or trim(substring_index(rh.`RowName`,'-',-(1))) in ('Open', 'Service Change', 'Scheduled', 'Scheduled - Offered', 'Confirmed', 'In Progress')) and date_format(rh.`Date`,'%Y-%m-%d') = @month_start, cast(rh.`Value` as decimal(10,2)),0)) AS `month start`
    
from `salesforce`.`sf_report_history` rh
where 
rh.`ReportName` = 'Audit Days Snapshot'
and cast(rh.`Value` as decimal(10,2)) > 0
and rh.`Region` like '%Product%'
and rh.`RowName` like '%Audit%'
and rh.`RowName` like '%Days%'
and date_format(rh.`Date`,'%Y-%m-%d') in (@today, @yesterday, @week_start, @month_start)
and str_to_date(concat(rh.`ColumnName`,' 01'),'%Y %m %d') <= date_format(date_add(utc_timestamp(), interval 6 month), '%Y-%m-01')
group by `Audit Status`, `Audit Open SubStatus`, `Period`;

select rh.`Region`
from `salesforce`.`sf_report_history` rh
where 
rh.`ReportName` = 'Audit Days Snapshot'
and cast(rh.`Value` as decimal(10,2)) > 0
and rh.`RowName` like '%Audit%'
and rh.`RowName` like '%Days%'
group by rh.`Region`