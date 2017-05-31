
SELECT * FROM salesforce.allocator_schedule where BatchId='TEST 2nd half 2012-2013 - 1' and SubBatchId=1 and Type='AUDIT' and ResourceType='Contractor' and Competencies='NSW Regulatory Food Safety Audit:2010 | Verification,NACE: 56,22000:2005 | Certification,';

SELECT *
FROM salesforce.allocator_schedule als 
where  als.BatchId='TEST 2nd half 2012-2013 - 3' and als.SubBatchId=1
LIMIT 20000;

# Analyse Resource Allocator Output
# 1) Skill gaps
SELECT t.PrimaryStandard, t.Competencies, 

SUM(IF(t.ResourceType='Employee', 1, 0)) AS 'Allocated to Employee',
SUM(IF(t.ResourceType='Employee', t.Duration, 0)) AS 'Allocated to Employee - Duration',

SUM(IF(t.ResourceType='Contractor', 1, 0)) AS 'Allocated to Contractors',
SUM(IF(t.ResourceType='Contractor', t.Duration, 0)) AS 'Allocated to Contractors - Duration',

SUM(IF(t.ResourceType is null, 1, 0)) AS 'Not Allocated' ,
SUM(IF(t.ResourceType is null, t.Duration, 0)) AS 'Not Allocated - Duration' 

FROM (
	SELECT ResourceType, PrimaryStandard, Competencies, Duration 
		FROM salesforce.allocator_schedule 
		WHERE BatchId='TEST 2nd half 2012-2013 - 3' 
			AND SubBatchId=1 
			AND Type='AUDIT' ) t
GROUP BY t.PrimaryStandard, t.Competencies ORDER BY `Allocated to Contractors` DESC
LIMIT 2000;

# 1) Skill gaps
SELECT t.PrimaryStandard, t.Competencies, 

SUM(IF(t.ResourceType='Contractor', 1, 0)) AS 'Allocated to Contractors',
SUM(IF(t.ResourceType='Contractor', t.Duration, 0)) AS 'Allocated to Contractors - Duration',

SUM(IF(t.ResourceType is null, 1, 0)) AS 'Not Allocated' ,
SUM(IF(t.ResourceType is null, t.Duration, 0)) AS 'Not Allocated - Duration' 

FROM (
	SELECT ResourceType, PrimaryStandard, Competencies, Duration, MONTH(startDate) 
		FROM salesforce.allocator_schedule 
		WHERE BatchId='TEST 2nd half 2012-2013 - 3' 
			AND SubBatchId=1 
			AND Type='AUDIT' ) t
GROUP BY t.PrimaryStandard, t.Competencies, MONTH(startDate) ORDER BY `Allocated to Contractors` DESC
LIMIT 2000;

# 2) contractor vs employee (hrs)
SELECT ResourceType, Sum(Duration) FROM salesforce.allocator_schedule where BatchId='TEST 2nd half 2012-2013 - 1' and SubBatchId=1 group by ResourceType;

# 3) travel vs audit
SELECT Type, Sum(Duration) FROM salesforce.allocator_schedule where BatchId='TEST 2nd half 2012-2013 - 1' and SubBatchId=1 group by Type;

#Compare with actual allocation from SF data (if already done in the past)
SELECT 
	wi.Status__c, wi.Name 
	, wir.work_item_type__c 
	, IF(wir.work_item_type__c = 'Audit', wi.Required_Duration__c,0) AS `Scheduled Duration`, SUM(wir.Total_duration__c)
	, r.Resource_Type__c, COUNT(DISTINCT(r.Name)) AS `Resource No.`
	, als.PrimaryStandard, als.Competencies  
FROM Work_Item__c wi 
INNER JOIN Work_Item_Resource__c wir on wi.Id = wir.Work_Item__c
INNER JOIN Resource__c r on wir.Resource__c = r.Id
INNER JOIN allocator_schedule als on wi.Name = als.WorkItemName
WHERE 
	wi.Status__c IN ('Completed') 
	AND wi.Revenue_Ownership__c IN ('AUS-Managed-NSW/ACT', 'AUS-Managed-QLD', 'AUS-Managed-SA/NT', 'AUS-Managed-VIC/TAS', 'AUS-Managed-WA', 'AUS-Managed Plus-NSW/ACT', 'AUS-Managed Plus-QLD', 'AUS-Managed Plus-SA/NT', 'AUS-Managed Plus-VIC/TAS', 'AUS-Managed Plus-WA', 'AUS-Direct-NSW/ACT', 'AUS-Direct-QLD', 'AUS-Direct-SA/NT', 'AUS-Direct-VIC/TAS', 'AUS-Direct-WA', 'AUS-Food-NSW/ACT', 'AUS-Food-QLD', 'AUS-Food-SA/NT', 'AUS-Food-SA/NT', 'AUS-Food-VIC/TAS', 'AUS-Food-WA') 
	AND wi.Service_target_date__c>='2013-01-01' 
	AND wi.Service_target_date__c<='2013-06-30' 
	AND als.BatchId = 'TEST 2nd half 2012-2013 - 3' 
	AND als.SubBatchId=1 
	AND als.type = 'AUDIT'
GROUP BY 
	wi.Status__c, wi.Name
	, wir.work_item_type__c
	, r.Resource_Type__c
	, als.PrimaryStandard, als.Competencies
LIMIT 20000;

select count(distinct(t2.Name)) FROM (
SELECT t.Status__c, t.Name, als.PrimaryStandard, als.Competencies, r.Resource_Type__c, t.Category__c, count(distinct(t.Resource_Name__c)) AS 'Resource_No',  sum(t.Actual_Duration) FROM (
	SELECT 
		wi.Status__c, wi.Name, tsli.Resource_Name__c, tsli.Category__c 
		, SUM(tsli.Actual_Hours__c)  AS `Actual_Duration`
	FROM Work_Item__c wi 
	INNER JOIN timesheet_line_item__c tsli ON wi.Id = tsli.Work_Item__c  
	WHERE 
		wi.Status__c IN ('Completed') 
		AND wi.Revenue_Ownership__c IN ('AUS-Managed-NSW/ACT', 'AUS-Managed-QLD', 'AUS-Managed-SA/NT', 'AUS-Managed-VIC/TAS', 'AUS-Managed-WA', 'AUS-Managed Plus-NSW/ACT', 'AUS-Managed Plus-QLD', 'AUS-Managed Plus-SA/NT', 'AUS-Managed Plus-VIC/TAS', 'AUS-Managed Plus-WA', 'AUS-Direct-NSW/ACT', 'AUS-Direct-QLD', 'AUS-Direct-SA/NT', 'AUS-Direct-VIC/TAS', 'AUS-Direct-WA', 'AUS-Food-NSW/ACT', 'AUS-Food-QLD', 'AUS-Food-SA/NT', 'AUS-Food-SA/NT', 'AUS-Food-VIC/TAS', 'AUS-Food-WA') 
		AND wi.Service_target_date__c>='2013-01-01' 
		AND wi.Service_target_date__c<='2013-06-30' 
	GROUP BY 
		wi.Status__c, wi.Name
		, tsli.Resource_Name__c
		, tsli.Category__c
	LIMIT 20000 ) t 
INNER JOIN allocator_schedule als on t.Name = als.WorkItemName
INNER JOIN Resource__c r ON t.Resource_Name__c = r.Name
WHERE  
	als.BatchId = 'TEST 2nd half 2012-2013 - 3' 
	AND als.SubBatchId=1 
	AND als.type = 'AUDIT'
GROUP BY 
	t.Status__c, t.Name, t.Category__c
	, als.PrimaryStandard, als.Competencies
	, r.Resource_Type__c
LIMIT 20000
) t2;

#After exporting the above as table allocator_2012-2013.actual
# 1) Skill gap
SELECT 
	PrimaryStandard, 
	Competencies, 
	SUM(IF(Resource_Type__c='Employee', 1, 0)) AS 'Employee - EventCount',
	SUM(IF(Resource_Type__c='Employee', `Total_Duration`, 0)) AS 'Employee - Duration',
	SUM(IF(Resource_Type__c='Contractor', 1, 0)) AS 'Contractor - EventCount',
	SUM(IF(Resource_Type__c='Contractor', `Total_Duration`, 0)) AS 'Contractor - Duration'
FROM salesforce.`allocator_2012-2013.actual` 
GROUP BY PrimaryStandard, Competencies
ORDER BY `Contractor - EventCount` DESC
LIMIT 2000;

# 2) contractor vs employee
SELECT Resource_Type__c,  sum(Total_Duration) FROM salesforce.`allocator_2012-2013.actual` group by Resource_Type__c;

# 3) travel vs audit
SELECT work_item_type__c, sum(Total_Duration) FROM salesforce.`allocator_2012-2013.actual` group by work_item_type__c;