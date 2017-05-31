#Resource Days available (working days - BOP)
SELECT 
	i.Reporting_Business_Units__c as 'Business Unit',
	i.Resource_Type__c as 'Resource Type',
	i.Name as 'Resource Name',
	date_format(i.date, '%Y %m') as 'Period',
	count(i.date) 
FROM ( 
	SELECT 
		wd.date, 
		r.Name,
		r.Id,
		r.Resource_Type__c,
		r.Reporting_Business_Units__c
	FROM 
		`sf_working_days` wd, 
		salesforce.resource__c r 
	WHERE 
		r.Reporting_Business_Units__c IN ('AUS-Food-NSW/ACT','AUS-Food-VIC/TAS','AUS-Food-QLD','AUS-Food-SA/NT','AUS-Food-WA','AUS-Food-ROW', 'AUS-Global-NSW/ACT','AUS-Global-VIC/TAS','AUS-Global-QLD', 'AUS-Global-SA/NT','AUS-Global-WA','AUS-Global-ROW','AUS-Managed Plus-NSW/ACT','AUS-Managed Plus-VIC/TAS','AUS-Managed Plus-QLD','AUS-Managed Plus-SA/NT','AUS-Managed Plus-WA','AUS-Managed Plus-ROW','AUS-Managed-NSW/ACT','AUS-Managed-VIC/TAS','AUS-Managed-QLD','AUS-Managed-SA/NT','AUS-Managed-WA','AUS-Managed-ROW','AUS-Direct-NSW/ACT','AUS-Direct-VIC/TAS','AUS-Direct-QLD','AUS-Direct-SA/NT','AUS-Direct-WA','AUS-Direct-ROW') 
		AND wd.date>='2013-07-01' 
		AND wd.date<='2014-06-30'
	) i 

LEFT JOIN  (
	SELECT 
		r.Id, 
		e.ActivityDate 
	FROM `event` e 
	INNER JOIN `resource__c` r ON r.User__c = e.OwnerId
	INNER JOIN `recordtype` rt on e.RecordTypeId = rt.Id 
	WHERE e.ActivityDate>='2013-07-01' 
	AND e.ActivityDate<='2014-06-30'
	AND rt.Name = 'Blackout Period Resource'
	) t ON t.ActivityDate = i.date AND t.id=i.Id 
WHERE t.Id is NULL
GROUP BY `Business Unit`, `Resource Type`, `Resource Name`, `Period`
LIMIT 100000;

#Resource Hours allocation by period
SELECT 
	i.Reporting_Business_Units__c as 'Business Unit',
	i.Resource_Type__c as 'Resource Type',
	i.Name as 'Resource Name',
	if (t.Id is null, 'Free', t.Name) as 'Activity Type',
	if (t.Id is null, 'Fishing', t.SubType) as 'SubType',
	date_format(i.date, '%Y %m') as 'Period',
	sum(if (t.Id is null, 8, t.Hours)) as 'Hours',
	sum(if (t.Id is null, 8, t.Hours))/8 as 'Days'
FROM ( 
	SELECT 
		wd.date, 
		r.Name,
		r.Id,
		r.Resource_Type__c,
		r.Reporting_Business_Units__c
	FROM 
		`sf_working_days` wd, 
		salesforce.resource__c r 
	WHERE 
		r.Reporting_Business_Units__c IN ('AUS-Food-NSW/ACT','AUS-Food-VIC/TAS','AUS-Food-QLD','AUS-Food-SA/NT','AUS-Food-WA','AUS-Food-ROW', 'AUS-Global-NSW/ACT','AUS-Global-VIC/TAS','AUS-Global-QLD', 'AUS-Global-SA/NT','AUS-Global-WA','AUS-Global-ROW','AUS-Managed Plus-NSW/ACT','AUS-Managed Plus-VIC/TAS','AUS-Managed Plus-QLD','AUS-Managed Plus-SA/NT','AUS-Managed Plus-WA','AUS-Managed Plus-ROW','AUS-Managed-NSW/ACT','AUS-Managed-VIC/TAS','AUS-Managed-QLD','AUS-Managed-SA/NT','AUS-Managed-WA','AUS-Managed-ROW','AUS-Direct-NSW/ACT','AUS-Direct-VIC/TAS','AUS-Direct-QLD','AUS-Direct-SA/NT','AUS-Direct-WA','AUS-Direct-ROW') 
		AND wd.date>='2013-07-01' 
		AND wd.date<='2014-06-30'
	) i 

LEFT JOIN  (
	SELECT 
		r.Id, 
		e.ActivityDate, 
		rt.Name,
		if (wir.Work_Item_Type__c is null, bop.Resource_Blackout_Type__c , wir.Work_Item_Type__c) as 'SubType',
		if (wir.Work_Item_Type__c is null, bop.Days__c*8,wir.Total_Duration__c) as 'Hours'
	FROM `event` e 
	INNER JOIN `resource__c` r ON r.User__c = e.OwnerId
	INNER JOIN `recordtype` rt on e.RecordTypeId = rt.Id 
	LEFT JOIN `work_item_resource__c` wir on wir.Id = e.WhatId 
	LEFT JOIN `blackout_period__c` bop on bop.Id = e.WhatId 
	WHERE e.ActivityDate>='2013-07-01' 
	AND e.ActivityDate<='2014-06-30'
	#AND rt.Name = 'Blackout Period Resource'
	) t ON t.ActivityDate = i.date AND t.id=i.Id 
#WHERE i.Name like 'Ardin K%'
#and date_format(i.date, '%Y %m') = '2013 10'
GROUP BY `Business Unit`, `Resource Type`, `Resource Name`, `Activity Type`, `SubType`, `Period`
LIMIT 100000;


# Working Days
SELECT 
		wd.date, 
		r.Name,
		r.Id,
		r.Resource_Type__c,
		r.Reporting_Business_Units__c
	FROM 
		`sf_working_days` wd, 
		salesforce.resource__c r 
	WHERE 
		r.Reporting_Business_Units__c IN ('AUS-Food-NSW/ACT','AUS-Food-VIC/TAS','AUS-Food-QLD','AUS-Food-SA/NT','AUS-Food-WA','AUS-Food-ROW', 'AUS-Global-NSW/ACT','AUS-Global-VIC/TAS','AUS-Global-QLD', 'AUS-Global-SA/NT','AUS-Global-WA','AUS-Global-ROW','AUS-Managed Plus-NSW/ACT','AUS-Managed Plus-VIC/TAS','AUS-Managed Plus-QLD','AUS-Managed Plus-SA/NT','AUS-Managed Plus-WA','AUS-Managed Plus-ROW','AUS-Managed-NSW/ACT','AUS-Managed-VIC/TAS','AUS-Managed-QLD','AUS-Managed-SA/NT','AUS-Managed-WA','AUS-Managed-ROW','AUS-Direct-NSW/ACT','AUS-Direct-VIC/TAS','AUS-Direct-QLD','AUS-Direct-SA/NT','AUS-Direct-WA','AUS-Direct-ROW') 
		AND wd.date>='2013-07-01' 
		AND wd.date<='2014-06-30'
LIMIT 100000;