USE salesforce;
select SUBSTRING_INDEX('AUS-Managed Plus-NSW/ACT', '-', -(1));
    
    SELECT 
		if(i.`Business Unit` like '%Food%', 'Food', 'MS') as 'Stream', SUBSTRING_INDEX(i.`Business Unit`, '-', -(1)) as 'State', i.`Manager`, i.`Name`, i.`Resource Capacitiy (%)`, i.`Period`, j.`Working Days`, i.`Audit Days`, i.`Travel Days`, i.`Holiday Days`, i.`Leave Days`,
        if(j.`Working Days`-(i.`Holiday Days`+i.`Leave Days`)=0,'n/a', (i.`Audit Days`+i.`Travel Days`)/((j.`Working Days`-(i.`Holiday Days`+i.`Leave Days`))*i.`Resource Capacitiy (%)`/100)) as 'Utilisation'
        
    FROM
        (SELECT 
        
            t.Id,
            t.Name,
            #t.Resource_Target_Days__c,
            t.Resource_Capacitiy__c as 'Resource Capacitiy (%)',
            t.Reporting_Business_Units__c as 'Business Unit',
            t.Manager,
            DATE_FORMAT(t.ActivityDate, '%Y %m') AS 'Period',
            SUM(IF(t.SubType = 'Audit', t.DurationDays, 0)) AS 'Audit Days',
            SUM(IF(t.SubType = 'Travel', t.DurationDays, 0)) AS 'Travel Days',
            SUM(IF(t.SubType = 'Public Holiday', t.DurationDays, 0)) AS 'Holiday Days',
            SUM(IF(t.SubType LIKE 'Leave%', t.DurationDays, 0)) AS 'Leave Days'
    FROM
        (SELECT 
        r.Id,
            r.Name,
            r.Resource_Target_Days__c,
            r.Resource_Capacitiy__c,
            r.Resource_Type__c,
            r.Work_Type__c,
            r.Reporting_Business_Units__c,
            m.Name as 'Manager',
            rt.Name AS 'Type',
            IF(wir.Work_Item_Type__c IS NULL, bop.Resource_Blackout_Type__c, wir.Work_Item_Type__c) AS 'SubType',
            e.DurationInMinutes AS 'DurationMin',
            e.DurationInMinutes / 60 / 8 AS 'DurationDays',
            e.ActivityDate
    FROM
        resource__c r
    INNER JOIN user u ON u.Id = r.User__c
    inner join user m on u.ManagerId = m.Id
    INNER JOIN event e ON u.Id = e.OwnerId
    INNER JOIN recordtype rt ON e.RecordTypeId = rt.Id
    LEFT JOIN work_item_resource__c wir ON wir.Id = e.WhatId
    LEFT JOIN blackout_period__c bop ON bop.Id = e.WhatId
    WHERE
        (r.Reporting_Business_Units__c LIKE 'AUS%'
            OR r.Reporting_Business_Units__c LIKE 'ASS%')
            AND ((DATE_FORMAT(e.ActivityDate, '%Y %m') < DATE_FORMAT(DATE_ADD(NOW(), INTERVAL 5 MONTH), '%Y %m')
            AND DATE_FORMAT(e.ActivityDate, '%Y %m') > DATE_FORMAT(DATE_ADD(NOW(), INTERVAL -3 MONTH), '%Y %m'))
            OR e.Id IS NULL)
            AND Resource_Type__c NOT IN ('Client Services')
            AND r.Reporting_Business_Units__c NOT IN ('AUS-CSC' , 'AUS-MGT', 'AUS-OPS')
            AND r.Reporting_Business_Units__c NOT LIKE 'AUS-Product%'
            AND (r.Reporting_Business_Units__c LIKE '%AUS-Food%' OR r.Reporting_Business_Units__c LIKE '%AUS-Manage%' OR r.Reporting_Business_Units__c LIKE '%AUS-Direct%' or r.Reporting_Business_Units__c LIKE '%AUS-Global%')
            AND r.Active_User__c = 'Yes'
            AND r.Resource_Type__c = 'Employee'
            AND r.Resource_Capacitiy__c IS NOT NULL
            AND r.Resource_Capacitiy__c >= 30
            AND (e.IsDeleted = 0 OR e.Id IS NULL)) t
    GROUP BY `Period` , t.Id) i
    INNER JOIN (SELECT 
        DATE_FORMAT(wd.date, '%Y %m') AS 'Period',
            COUNT(wd.date) AS 'Working Days'
    FROM
        `sf_working_days` wd
    WHERE
        DATE_FORMAT(wd.date, '%Y %m') < DATE_FORMAT(DATE_ADD(NOW(), INTERVAL 5 MONTH), '%Y %m')
            AND DATE_FORMAT(wd.date, '%Y %m') > DATE_FORMAT(DATE_ADD(NOW(), INTERVAL -3 MONTH), '%Y %m')
    GROUP BY `Period`) j ON i.Period = j.Period
    group by Id, i.Period;
    
# Asia
#select w.*, avg(w.Utilisation) as 'Utlisation' from (
SELECT 
	i.*, j.`Working Days`, 
    if(i.Resource_Capacitiy__c is null ,'N/A', i.AuditPlusTravelDays/(j.`Working Days`*i.Resource_Capacitiy__c/100-i.LeavePlusHolidayDays)) as 'Utilisation'
    #if(i.Resource_Target_Days__c<=50,'N/A', i.AuditPlusTravelDays/(j.`Working Days`/180*i.Resource_Target_Days__c-LeavePlusHolidayDays)) as 'Utilisation',
    #i.AuditPlusTravelDays/(j.`Working Days`-LeavePlusHolidayDays) as 'Utilisation 2'
FROM
	(SELECT 
	DATE_FORMAT(t.ActivityDate, '%Y %m') AS 'Period',
		t.Id,
		t.Name,
		t.Resource_Target_Days__c,
        t.Resource_Capacitiy__c,
        t.Resource_Type__c,
        t.Reporting_Business_Units__c,
		SUM(IF(t.SubType = 'Audit'
			OR t.SubType = 'Travel', t.DurationDays, 0)) AS 'AuditPlusTravelDays',
		SUM(IF(t.SubType LIKE 'Leave%'
			OR t.SubType = 'Public Holiday', t.DurationDays, 0)) AS 'LeavePlusHolidayDays'
FROM
	(SELECT 
	r.Id,
		r.Name,
		r.Resource_Target_Days__c,
		r.Resource_Capacitiy__c,
		r.Resource_Type__c,
        r.Reporting_Business_Units__c,
		r.Work_Type__c,
		rt.Name AS 'Type',
		IF(wir.Work_Item_Type__c IS NULL, bop.Resource_Blackout_Type__c, wir.Work_Item_Type__c) AS 'SubType',
		e.DurationInMinutes AS 'DurationMin',
		e.DurationInMinutes / 60 / 8 AS 'DurationDays',
		e.ActivityDate
FROM
	resource__c r
INNER JOIN user u ON u.Id = r.User__c
INNER JOIN event e ON u.Id = e.OwnerId
INNER JOIN recordtype rt ON e.RecordTypeId = rt.Id
LEFT JOIN work_item_resource__c wir ON wir.Id = e.WhatId
LEFT JOIN blackout_period__c bop ON bop.Id = e.WhatId
WHERE
	r.Reporting_Business_Units__c LIKE 'AUS%'
		AND ((DATE_FORMAT(e.ActivityDate, '%Y %m') < DATE_FORMAT(DATE_ADD(NOW(), INTERVAL 5 MONTH), '%Y %m')
		AND DATE_FORMAT(e.ActivityDate, '%Y %m') in ('2015 02'))
		OR e.Id IS NULL)
		AND Resource_Type__c NOT IN ('Client Services')
		AND r.Reporting_Business_Units__c LIKE '%Asia%' 
		AND r.Active_User__c = 'Yes'
		AND r.Resource_Type__c = 'Employee'
		#AND r.Resource_Target_Days__c IS NOT NULL
		#AND r.Resource_Target_Days__c > 0
		AND (e.IsDeleted = 0 OR e.Id IS NULL)) t
GROUP BY `Period` , t.Id) i
INNER JOIN (SELECT 
	DATE_FORMAT(wd.date, '%Y %m') AS 'Period',
		COUNT(wd.date) AS 'Working Days'
FROM
	`sf_working_days` wd
WHERE
	DATE_FORMAT(wd.date, '%Y %m') < DATE_FORMAT(DATE_ADD(NOW(), INTERVAL 5 MONTH), '%Y %m')
            AND DATE_FORMAT(wd.date, '%Y %m') >= DATE_FORMAT(NOW(), '%Y %m')
GROUP BY `Period`) j ON i.Period = j.Period;
#) w 
#group by w.Id

SELECT 
	r.Id,
		r.Name,
		r.Resource_Target_Days__c,
		r.Resource_Capacitiy__c,
		r.Resource_Type__c,
        r.Reporting_Business_Units__c,
		r.Work_Type__c,
		rt.Name AS 'Type',
		IF(wir.Work_Item_Type__c IS NULL, bop.Resource_Blackout_Type__c, wir.Work_Item_Type__c) AS 'SubType',
		e.DurationInMinutes AS 'DurationMin',
		e.DurationInMinutes / 60 / 8 AS 'DurationDays',
		e.ActivityDate
FROM
	resource__c r
INNER JOIN user u ON u.Id = r.User__c
INNER JOIN event e ON u.Id = e.OwnerId
INNER JOIN recordtype rt ON e.RecordTypeId = rt.Id
LEFT JOIN work_item_resource__c wir ON wir.Id = e.WhatId
LEFT JOIN blackout_period__c bop ON bop.Id = e.WhatId
WHERE
	r.Reporting_Business_Units__c LIKE 'Asia%'
		AND ((DATE_FORMAT(e.ActivityDate, '%Y %m') < DATE_FORMAT(DATE_ADD(NOW(), INTERVAL 5 MONTH), '%Y %m')
		AND DATE_FORMAT(e.ActivityDate, '%Y %m') in ('2014 12'))
		OR e.Id IS NULL)
		AND Resource_Type__c NOT IN ('Client Services')
		AND r.Reporting_Business_Units__c LIKE '%Asia%' 
		AND r.Active_User__c = 'Yes'
		AND r.Resource_Type__c = 'Employee'
		#AND r.Resource_Target_Days__c IS NOT NULL
		#AND r.Resource_Target_Days__c > 0
		AND (e.IsDeleted = 0 OR e.Id IS NULL) limit 100000;