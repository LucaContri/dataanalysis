SELECT 
    IF(i.`Business Unit` LIKE '%Food%',
        'Food',
        'MS') AS 'Stream',
    SUBSTRING_INDEX(i.`Business Unit`, '-', -(1)) AS 'State',
    i.`Manager`,
    i.`Name`,
    i.`Resource Capacitiy (%)`,
    i.`Period`,
    j.`Working Days`,
    i.`Audit Days`,
    i.`Travel Days`,
    i.`Holiday Days`,
    i.`Leave Days`,
    IF(j.`Working Days` - (i.`Holiday Days` + i.`Leave Days`) = 0,
        NULL,
        (i.`Audit Days` + i.`Travel Days`) / ((j.`Working Days` - (i.`Holiday Days` + i.`Leave Days`)) * i.`Resource Capacitiy (%)` / 100) * 100) AS 'Utilisation %',
    i.`Other BOPs`,
    i.`Other BOP Types`,
    (j.`Working Days` - i.`Audit Days` - i.`Travel Days` - i.`Holiday Days` - i.`Leave Days` - i.`Other BOPs`) AS 'Spare Capacity',
    (j.`Working Days` - (i.`Holiday Days` + i.`Leave Days`)) * (i.`Resource Capacitiy (%)` / 100) AS 'Days Avaialble',
    (i.`Audit Days` + i.`Travel Days`) AS 'Charged Days'
FROM
    (SELECT 
        t.Id,
            t.Name,
            t.Resource_Capacitiy__c AS 'Resource Capacitiy (%)',
            t.Reporting_Business_Units__c AS 'Business Unit',
            t.Manager,
            DATE_FORMAT(t.ActivityDate, '%Y %m') AS 'Period',
            SUM(IF(t.SubType = 'Audit', t.DurationDays, 0)) AS 'Audit Days',
            SUM(IF(t.SubType = 'Travel', t.DurationDays, 0)) AS 'Travel Days',
            SUM(IF(t.SubType = 'Public Holiday', t.DurationDays, 0)) AS 'Holiday Days',
            SUM(IF(t.SubType LIKE 'Leave%', t.DurationDays, 0)) AS 'Leave Days',
            SUM(IF(t.SubType NOT LIKE 'Leave%'
                AND t.Subtype NOT IN ('Audit' , 'Travel', 'Public Holiday'), t.DurationDays, 0)) AS 'Other BOPs',
            GROUP_CONCAT(DISTINCT IF(t.SubType NOT LIKE 'Leave%'
                AND t.Subtype NOT IN ('Audit' , 'Travel', 'Public Holiday'), t.Subtype, NULL)) AS 'Other BOP Types'
    FROM
        (SELECT 
        r.Id,
            r.Name,
            r.Resource_Target_Days__c,
            r.Resource_Capacitiy__c,
            r.Resource_Type__c,
            r.Work_Type__c,
            r.Reporting_Business_Units__c,
            m.Name AS 'Manager',
            rt.Name AS 'Type',
            IF(wir.Work_Item_Type__c IS NULL, bop.Resource_Blackout_Type__c, wir.Work_Item_Type__c) AS 'SubType',
            e.DurationInMinutes AS 'DurationMin',
            e.DurationInMinutes / 60 / 8 AS 'DurationDays',
            e.ActivityDate
    FROM
        resource__c r
    INNER JOIN user u ON u.Id = r.User__c
    INNER JOIN user m ON u.ManagerId = m.Id
    INNER JOIN event e ON u.Id = e.OwnerId
    INNER JOIN recordtype rt ON e.RecordTypeId = rt.Id
    LEFT JOIN work_item_resource__c wir ON wir.Id = e.WhatId
    LEFT JOIN blackout_period__c bop ON bop.Id = e.WhatId
    WHERE
        (r.Reporting_Business_Units__c LIKE 'AUS%'
            OR r.Reporting_Business_Units__c LIKE 'ASS%')
            AND ((DATE_FORMAT(e.ActivityDate, '%Y %m') < DATE_FORMAT(DATE_ADD(NOW(), INTERVAL 7 MONTH), '%Y %m')
            AND DATE_FORMAT(e.ActivityDate, '%Y %m') > DATE_FORMAT(DATE_ADD(NOW(), INTERVAL - 6 MONTH), '%Y %m'))
            OR e.Id IS NULL)
            AND Resource_Type__c NOT IN ('Client Services')
            AND r.Reporting_Business_Units__c NOT IN ('AUS-CSC' , 'AUS-MGT', 'AUS-OPS')
            AND r.Reporting_Business_Units__c NOT LIKE 'AUS-Product%'
            AND (r.Reporting_Business_Units__c LIKE 'AUS%')
            AND r.Active_User__c = 'Yes'
            AND r.Resource_Type__c = 'Employee'
            AND r.Resource_Capacitiy__c IS NOT NULL
            AND r.Resource_Capacitiy__c >= 30
            AND (e.IsDeleted = 0 OR e.Id IS NULL)) t
    GROUP BY `Period` , t.Id) i
        INNER JOIN
    (SELECT 
        DATE_FORMAT(wd.date, '%Y %m') AS 'Period',
            COUNT(wd.date) AS 'Working Days'
    FROM
        `sf_working_days` wd
    WHERE
        DATE_FORMAT(wd.date, '%Y %m') < DATE_FORMAT(DATE_ADD(NOW(), INTERVAL 7 MONTH), '%Y %m')
            AND DATE_FORMAT(wd.date, '%Y %m') > DATE_FORMAT(DATE_ADD(NOW(), INTERVAL - 6 MONTH), '%Y %m')
    GROUP BY `Period`) j ON i.Period = j.Period
GROUP BY Id , i.Period;

select * from salesforce.work_item_resource__c wir where wir.IsDeleted = 0 order by wir.CreatedDate desc limit 100;

# Check all tsli are linked to a resource
select tsli.Id, tsli.Name, r.Name, tsli.Resource_Name__c, max(tsli.createdDate)
from salesforce.timesheet_line_item__c tsli
left join salesforce.daily_timesheet__c dts on tsli.Daily_Timesheet__c = dts.Id
left join salesforce.weekly_timesheet__c wts on dts.Weekly_Timesheet__c = wts.Id
left join salesforce.user u on wts.Employee__c = u.Id
left join salesforce.resource__c r on u.Id = r.User__c
where 
tsli.IsDeleted = 0
and r.Id is null
group by tsli.Resource_Name__c;

# Lagging indicator - based on Timesheet line items
(select 
	i.*, 
    ifnull(h.`Out of Office Days`,0) as 'Out of Office Days (from Calendar)', 
    j.`Working Days`, 
    j.`Working Days` - ifnull(h.`Out of Office Days`,0) as 'Days Available',
    (j.`Working Days` - ifnull(h.`Out of Office Days`,0))*i.`Capacity` as 'Days Available (Capacity Adjusted)' 
from 
(select 
r.Reporting_Business_Units__c ,
analytics.getBUFromReportingBusinessUnit(r.Reporting_Business_Units__c) as 'Business Unit',
analytics.getRegionFromCountry(analytics.getBUFromReportingBusinessUnit(r.Reporting_Business_Units__c)) as 'Region',
r.Resource_Type__c ,
r.Job_Family__c , 
m.Name as 'Manager',
r.Name as 'Resource',
u.Name as 'User',
u.Id as 'User Id',
ifnull(r.Resource_Capacitiy__c/100,1) as 'Capacity',
tsli.Resource_Name__c,
date_format(dts.Date__c, '%Y %m') as 'Period',
sum(tsli.FFinal_Hours__c)/8 as 'Days',
sum(if(tsli.Billable__c in ('Billable','Pre-pais'), tsli.FFinal_Hours__c, 0))/8 as 'Billable Days',
sum(if(tsli.Category__c like '%leave%' or tsli.Category__c like '%holiday%' , tsli.FFinal_Hours__c, 0))/8  as 'Out of Office Days (from TSLI)',
sum(if(tsli.Category__c like '%travel%', tsli.FFinal_Hours__c, 0))/8  as 'Travel Days',
sum(if(tsli.Category__c = 'audit', tsli.FFinal_Hours__c, 0))/8  as 'Audit Days',
sum(if(tsli.Category__c not like 'audit' and tsli.Category__c not like '%travel%' and tsli.Category__c not like '%leave%', tsli.FFinal_Hours__c, 0))/8 as 'Other Days'
from salesforce.timesheet_line_item__c tsli
left join salesforce.daily_timesheet__c dts on tsli.Daily_Timesheet__c = dts.Id
left join salesforce.weekly_timesheet__c wts on dts.Weekly_Timesheet__c = wts.Id
left join salesforce.user u on wts.Employee__c = u.Id
left join salesforce.user m on u.ManagerId = m.Id
left join salesforce.resource__c r on u.Id = r.User__c
where 
	tsli.IsDeleted = 0
	and date_format(dts.Date__c , '%Y %m') >= date_format(date_Add(utc_timestamp(), INTERVAL - 12 MONTH), '%Y %m')
	and date_format(dts.Date__c , '%Y %m') < date_format(utc_timestamp(), '%Y %m')
    and r.Active_User__c = 'Yes'
    and r.Resource_Type__c = 'Employee'
    and r.Reporting_Business_Units__c not like '%product%'
group by tsli.Resource_Name__c , u.Id, `Period`) i
inner join  
	(select date_format(wd.date, '%Y %m') AS 'Period', count(wd.date) as 'Working Days'
    from salesforce.`sf_working_days` wd
    where 
		date_format(wd.date, '%Y %m') < date_format(utc_timestamp(), '%Y %m')
        and date_format(wd.date, '%Y %m') >= date_format(date_Add(utc_timestamp(), INTERVAL - 12 MONTH), '%Y %m')
    GROUP BY `Period`) j ON i.Period = j.Period
left join
	(SELECT 
        u.Id as 'User Id',
        date_format(e.ActivityDate, '%Y %m') as 'Period',
        sum(e.DurationInMinutes)/60/8 AS 'Out of Office Days'
    from salesforce.event e 
    inner join salesforce.user u ON u.Id = e.OwnerId
    inner join salesforce.resource__c r on r.User__c = u.Id
    inner join salesforce.blackout_period__c bop on bop.Id = e.WhatId
    where
        date_format(e.ActivityDate, '%Y %m') >= date_format(date_add(utc_timestamp(), INTERVAL -12 MONTH), '%Y %m')
        and date_format(e.ActivityDate, '%Y %m') < date_format(utc_timestamp(), '%Y %m')
        and (bop.Resource_Blackout_Type__c like '%leave%' or bop.Resource_Blackout_Type__c like '%holiday%')
    GROUP BY `Period` , u.Id) h on h.`Period` = i.`Period` and h.`User Id` = i.`User Id`)
    
