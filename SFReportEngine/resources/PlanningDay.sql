SELECT * FROM (
# MS + Food - New
(SELECT 
	c.Operational_Ownership__c as 'Business Unit'
	, DATE_FORMAT(wi.Service_target_date__c,'%Y %m') AS 'Period' 
	, 'New Business' AS 'Status'
	, sum(wi.Required_Duration__c/8) AS 'Days'
	#, wi.Id, wi.Name, wi.Service_target_date__c, rt.Name, c.Primary_Standard__c, t.Status__c, c.Client_Site__c
FROM salesforce.work_item__c wi 
INNER JOIN salesforce.recordtype rt on wi.RecordTypeId = rt.Id
INNER JOIN salesforce.work_package__c wp on wp.Id = wi.Work_Package__c 
INNER JOIN salesforce.certification__c c on c.Id = wp.Site_Certification__c
INNER JOIN
	(SELECT scsp.Site_Certification__c, scsp.Status__c FROM salesforce.site_certification_standard_program__c scsp where Status__c IN ('Applicant', 'Customised')) t ON t.Site_Certification__c= c.Id
WHERE 
	wi.Status__c='Open' 
	AND rt.Name = 'Audit'
	AND wi.Work_Item_Stage__c IN ('Certification', 'Gap', 'Initial Inspection', 'Stage 1', 'Stage 2')
	AND c.Operational_Ownership__c IN ('AUS - Management Systems', 'AUS - Food')
	#AND c.Operational_Ownership__c IN ('AUS - Management Systems')
	#AND DATE_FORMAT(wi.Service_target_date__c,'%Y %m') = '2013 12'
GROUP BY c.Operational_Ownership__c, `Period`
ORDER BY c.Operational_Ownership__c, `Period`)
#ORDER BY wi.Name;

UNION

# MS + Food - Open
(SELECT 
	IF(wi.Revenue_Ownership__c LIKE 'AUS-Food%', 'AUS - Food', 'AUS - Management Systems') AS 'Business Unit'
	, DATE_FORMAT(wi.Service_target_date__c,'%Y %m') AS 'Period' 
	, 'Open' AS 'Status'
	, ROUND(SUM(wi.Required_Duration__c/8)) AS 'Days'
	#, wi.Id, wi.Name, wi.Service_target_date__c, rt.Name, c.Primary_Standard__c, t.Status__c, c.Client_Site__c
FROM salesforce.work_item__c wi 
INNER JOIN salesforce.recordtype rt on wi.RecordTypeId = rt.Id
INNER JOIN salesforce.work_package__c wp on wp.Id = wi.Work_Package__c 
INNER JOIN salesforce.certification__c c on c.Id = wp.Site_Certification__c
WHERE 
	wi.Status__c='Open' 
	AND rt.Name = 'Audit'
	AND wi.Work_Item_Stage__c NOT IN ('Certification', 'Gap', 'Initial Inspection', 'Stage 1', 'Stage 2')
	AND wi.Revenue_Ownership__c IN ('AUS-Food-NSW/ACT','AUS-Food-VIC/TAS','AUS-Food-QLD','AUS-Food-SA/NT','AUS-Food-WA','AUS-Food-ROW', 'AUS-Global-NSW/ACT','AUS-Global-VIC/TAS','AUS-Global-SA/NT','AUS-Global-WA','AUS-Global-ROW','AUS-Managed Plus-NSW/ACT','AUS-Managed Plus-VIC/TAS','AUS-Managed Plus-QLD','AUS-Managed Plus-SA/NT','AUS-Managed Plus-WA','AUS-Managed Plus-ROW','AUS-Managed-NSW/ACT','AUS-Managed-VIC/TAS','AUS-Managed-QLD','AUS-Managed-SA/NT','AUS-Managed-WA','AUS-Managed-ROW','AUS-Direct-NSW/ACT','AUS-Direct-VIC/TAS','AUS-Direct-QLD','AUS-Direct-SA/NT','AUS-Direct-WA','AUS-Direct-ROW')
	#AND wi.Service_target_date__c >='2013-07-01' and wi.Service_target_date__c <='2014-06-30'
	#AND DATE_FORMAT(wi.Service_target_date__c,'%Y %m') = '2013 11'
GROUP BY `Business Unit`, `Period`
ORDER BY `Business Unit`, `Period`)
#ORDER BY wi.Name

UNION

# MS + Food - Audit Days
(SELECT 
	IF(wi.Revenue_Ownership__c LIKE 'AUS-Food%', 'AUS - Food', 'AUS - Management Systems') AS 'Business Unit',
	DATE_FORMAT(wird.FStartDate__c,'%Y %m') as 'Period', 
	IF(wi.Status__c = 'Service change', 'Service change', IF(wi.Status__c = 'Scheduled','Scheduled',IF(wi.Status__c='Scheduled - Offered','Scheduled - Offered',IF(wi.Status__c='Budget', 'Budget','Confirmed')))) AS 'Status', 
	sum(if (Budget_Days__c is null,wird.Scheduled_Duration__c/8,wird.Scheduled_Duration__c/8+Budget_Days__c) ) AS 'Days' 
	#sum(wird.Budget_Days__c) AS 'Budget Days'
	#wi.id, wi.Name, wird.FStartDate__c, wird.StartDateTime__c , wird.Budget_Days__c, wird.Scheduled_Duration__c, wird.Scheduled_Duration__c/8
FROM salesforce.work_item__c wi
INNER JOIN salesforce.work_item_resource__c wir ON wir.work_item__c = wi.Id
INNER JOIN salesforce.work_item_resource_day__c wird ON wird.Work_Item_Resource__c = wir.Id
INNER JOIN salesforce.recordtype rt on wi.RecordTypeId = rt.Id
WHERE 
	rt.Name = 'Audit'
	AND wir.Work_Item_Type__c IN ('Audit','Audit Planning','Client Management','Budget')
	AND wi.Status__c IN ('Scheduled','Scheduled - Offered','Confirmed','Service change','In Progress','Submitted','Under Review','Support','Completed','Budget')
	AND wi.Revenue_Ownership__c IN ('AUS-Global-NSW/ACT','AUS-Global-VIC/TAS','AUS-Global-QLD','AUS-Global-SA/NT','AUS-Global-WA','AUS-Global-ROW','AUS-Managed Plus-NSW/ACT','AUS-Managed Plus-VIC/TAS','AUS-Managed Plus-QLD','AUS-Managed Plus-SA/NT','AUS-Managed Plus-WA','AUS-Managed Plus-ROW','AUS-Managed-NSW/ACT','AUS-Managed-VIC/TAS','AUS-Managed-QLD','AUS-Managed-SA/NT','AUS-Managed-WA','AUS-Managed-ROW','AUS-Direct-NSW/ACT','AUS-Direct-VIC/TAS','AUS-Direct-QLD','AUS-Direct-SA/NT','AUS-Direct-WA','AUS-Direct-ROW','AUS-Food-NSW/ACT','AUS-Food-VIC/TAS','AUS-Food-QLD','AUS-Food-SA/NT','AUS-Food-WA','AUS-Food-ROW')
	AND wir.Role__c NOT IN ('Observer','Verifying Auditor','Verifier')
	#AND DATE_FORMAT(wird.FStartDate__c,'%Y %m') IN ('2013 10', '2013 11', '2013 12')
GROUP BY `Business Unit`, `Period`, `Status`
ORDER BY `Business Unit`, `Period`, `Status`) 
) t
WHERE `Period` >= '2013 07' and `Period` <= '2014 06'
ORDER BY `Business Unit`, `Period`, `Status`;