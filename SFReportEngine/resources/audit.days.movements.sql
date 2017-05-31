(SELECT 
    t.date,
    t.Period,
    t.Budget AS 'Budget',
    SUM(t.Completed) AS 'Completed',
    SUM(t.`In Progress`) AS 'In Progress',
    SUM(t.Confirmed) AS 'Confirmed',
    SUM(t.Scheduled) AS 'Scheduled',
    SUM(t.Open) AS 'Open'
FROM
    (SELECT 
        date,
            ColumnName AS 'Period',
            TRIM(SUBSTRING_INDEX(`RowName`, '-', -(1))),
            budget.`days` AS 'Budget',
            IF(TRIM(SUBSTRING_INDEX(`RowName`, '-', -(1))) IN ('Completed'), SUM(Value), 0) AS 'Completed',
            IF(TRIM(SUBSTRING_INDEX(`RowName`, '-', -(1))) IN ('In Progress' , 'Submitted', 'Under Review', 'Under Review - Rejected', 'Support'), SUM(Value), 0) AS 'In Progress',
            IF(TRIM(SUBSTRING_INDEX(`RowName`, '-', -(1))) = 'Confirmed', SUM(Value), 0) AS 'Confirmed',
            IF(TRIM(SUBSTRING_INDEX(`RowName`, '-', -(1))) LIKE 'Scheduled%', SUM(Value), 0) AS 'Scheduled',
            IF(TRIM(SUBSTRING_INDEX(`RowName`, '-', -(1))) IN ('Open' , 'Service Change'), SUM(Value), 0) AS 'Open'
    FROM
        `sf_report_history` rh
        left join (select 
			 date_format(RefDate, '%Y %m') as 'Period', 
			 sum(RefValue) as 'days' 
			from salesforce.sf_data 
			where 
			 DataType = 'Audit Days Budget' 
			 and RefDate between '2016-00-01' and '2017-06-30' 
			 and Region like '%Australia%'
			 and current=1 
			group by `Period`) budget on rh.`ColumnName` = budget.`Period`
    WHERE
        ReportName = 'Audit Days Snapshot'
            #AND DATE_FORMAT(date, '%w') = 1
            AND date BETWEEN '2015-07-01' AND NOW()
            AND ColumnName <= '2017 06'
            AND `Region` LIKE 'Australia%'
            AND CAST(`Value` AS DECIMAL (10 , 2 )) > 0
            AND `Region` NOT LIKE '%Product%'
            AND `Region` NOT LIKE '%Unknown%'
            AND `RowName` LIKE '%Audit%'
            AND `RowName` LIKE '%Days%'
            AND `RowName` NOT LIKE '%Pending%'
    GROUP BY date , `Period` , `RowName`) t
GROUP BY t.date , t.Period
ORDER BY t.date , t.Period);

(SELECT 
        date,
            ColumnName AS 'Period',
            TRIM(SUBSTRING_INDEX(`RowName`, '-', -(1))) as 'Status',
            SUM(Value) AS 'Days',
            budget.`days` as 'Budget Days'
    FROM
        `sf_report_history` rh
        left join (select 
			 date_format(RefDate, '%Y %m') as 'Period', 
			 sum(RefValue) as 'days' 
			from salesforce.sf_data 
			where 
			 DataType = 'Audit Days Budget' 
			 and RefDate between '2014-07-01' and '2017-06-30' 
			 and Region like '%Australia%'
			 and current=1 
			group by `Period`) budget on rh.`ColumnName` = budget.`Period`
    WHERE
        ReportName = 'Audit Days Snapshot'
            #AND DATE_FORMAT(date, '%w') = 1
            AND date BETWEEN '2015-07-01' AND NOW()
            AND ColumnName <= '2017 06'
            AND `Region` LIKE 'Australia%'
            AND CAST(`Value` AS DECIMAL (10 , 2 )) > 0
            AND `Region` NOT LIKE '%Product%'
            AND `Region` NOT LIKE '%Unknown%'
            AND `RowName` LIKE '%Audit%'
            AND `RowName` LIKE '%Days%'
            AND `RowName` NOT LIKE '%Pending%'
    GROUP BY date , `Period` , `Status`);
    
set @period = '2016 09';
# New
(select 'New' as 'Type', wi.Id, wi.Name, wi.CreatedDate, null as 'From', wi.Service_target_date__c as 'To', wi.Required_Duration__c as 'Required Duration'
from salesforce.work_item__c wi
where date_format(wi.Service_target_date__c, '%Y %m') = @period
and wi.Revenue_Ownership__c like 'AUS%' and wi.Revenue_Ownership__c not like '%Product%'
#and wi.Id = 'a3Id00000005bASEAY'
)
union all
# Cancelled
(select 'Cancelled' as 'Type', wi.Id, wi.Name, wih.CreatedDate, wi.Work_Item_Date__c as 'From', null as 'To', -wi.Required_Duration__c as 'Required Duration'
from salesforce.work_item__c wi
inner join salesforce.work_item__history wih on wi.Id = wih.ParentId and wih.Field = 'Status__c' and wih.NewValue = 'Cancelled'
where 
wi.Status__c = 'Cancelled'
and date_format(wi.Work_Item_Date__c, '%Y %m') = @period
and wi.Revenue_Ownership__c like 'AUS%' and wi.Revenue_Ownership__c not like '%Product%'
#and wi.Id = 'a3Id00000005bASEAY'
)
# Rescheduled
union all
(select 
	if(date_format(str_to_date(concat(left(wih.NewValue,10),right(wih.NewValue,4)), '%a %b %d%Y'), '%Y %m') = @period,
		if(date_format(str_to_date(concat(left(wih.OldValue,10),right(wih.OldValue,4)), '%a %b %d%Y'), '%Y %m') = @period, 
			'Rescheduled Same',
			'Rescheduled in'),
		'Rescheduled Out') as 'Type', 
     
	wi.Id, wi.Name, wih.CreatedDate, str_to_date(concat(left(wih.OldValue,10),right(wih.OldValue,4)), '%a %b %d%Y') as 'From', str_to_date(concat(left(wih.NewValue,10),right(wih.NewValue,4)), '%a %b %d%Y') as 'To',
    if(date_format(str_to_date(concat(left(wih.NewValue,10),right(wih.NewValue,4)), '%a %b %d%Y'), '%Y %m') = @period,
		if(date_format(str_to_date(concat(left(wih.OldValue,10),right(wih.OldValue,4)), '%a %b %d%Y'), '%Y %m') = @period, 
			wi.Required_Duration__c,
			wi.Required_Duration__c),
		-wi.Required_Duration__c) as 'Required Duration'
from salesforce.work_item__c wi
inner join salesforce.work_item__history wih on wi.Id = wih.ParentId and wih.Field = 'Track_Start_Date__c' 
	and ((date_format(str_to_date(concat(left(wih.OldValue,10),right(wih.OldValue,4)), '%a %b %d%Y'), '%Y %m') = @period  and wih.NewValue is not null)
    or (date_format(str_to_date(concat(left(wih.NewValue,10),right(wih.NewValue,4)), '%a %b %d%Y'), '%Y %m') = @period and wih.OldValue is not null))
and wi.Revenue_Ownership__c like 'AUS%' and wi.Revenue_Ownership__c not like '%Product%'
#and wi.Id = 'a3Id00000005bASEAY'
)