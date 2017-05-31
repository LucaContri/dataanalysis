# Done last November with Site Certification currently inactive
SELECT 
	wi.Id,
	wi.Name,
	wp.Id,
	wp.name,
	c.Id,
	c.Name,
	c.Id,
	c.Status__c,
	wi.Revenue_Ownership__c,
	wird.FStartDate__c, 
	wi.Status__c,
	wird.Scheduled_Duration__c/8
FROM salesforce.work_item__c wi
INNER JOIN salesforce.work_item_resource__c wir ON wir.work_item__c = wi.Id
INNER JOIN salesforce.work_item_resource_day__c wird ON wird.Work_Item_Resource__c = wir.Id
INNER JOIN salesforce.recordtype rt on wi.RecordTypeId = rt.Id
INNER JOIN salesforce.work_package__c wp on wi.Work_Package__c = wp.Id
INNER JOIN salesforce.certification__c c on wp.Site_Certification__c = c.Id
WHERE 
	rt.Name = 'Audit'
	AND wir.Work_Item_Type__c IN ('Audit','Audit Planning','Client Management')
	AND wi.Status__c IN ('Scheduled','Scheduled - Offered','Confirmed','Service change','In Progress','Submitted','Under Review','Support','Completed')
	AND wi.Revenue_Ownership__c IN ('AUS-Global-NSW/ACT','AUS-Global-VIC/TAS','AUS-Global-QLD','AUS-Global-SA/NT','AUS-Global-WA','AUS-Global-ROW','AUS-Managed Plus-NSW/ACT','AUS-Managed Plus-VIC/TAS','AUS-Managed Plus-QLD','AUS-Managed Plus-SA/NT','AUS-Managed Plus-WA','AUS-Managed Plus-ROW','AUS-Managed-NSW/ACT','AUS-Managed-VIC/TAS','AUS-Managed-QLD','AUS-Managed-SA/NT','AUS-Managed-WA','AUS-Managed-ROW','AUS-Direct-NSW/ACT','AUS-Direct-VIC/TAS','AUS-Direct-QLD','AUS-Direct-SA/NT','AUS-Direct-WA','AUS-Direct-ROW','AUS-Food-NSW/ACT','AUS-Food-VIC/TAS','AUS-Food-QLD','AUS-Food-SA/NT','AUS-Food-WA','AUS-Food-ROW')
	AND wir.Role__c NOT IN ('Observer','Verifying Auditor','Verifier')
	AND DATE_FORMAT(wird.FStartDate__c,'%Y %m') = '2012 11'
	AND c.Status__c='Inactive';

# WI with target month November 2012 belonging to Active Site Certification without any WI with target month November 2013 
SELECT 
	c3.Id, c3.Name, rt3.Name, c3.Status__c, c3.Operational_Ownership__c, t2.TargetDates, IF(c3.FSample_Site__c LIKE '%checkbox_checked%', 'Sample Site', 'Not Sample Site') AS 'Type', c3.Status__c,
	t2.Service_Target_Year__c, t2.Service_Target_Month__c
	#count(c3.Id) AS 'Missing from following year'
FROM salesforce.certification__c c3 
INNER JOIN salesforce.recordtype rt3 ON rt3.Id = c3.RecordTypeId
INNER JOIN (
	SELECT c2.Id, c2.Name, c2.Status__c, GROUP_CONCAT(wi2.Service_target_date__c SEPARATOR ';') AS 'TargetDates' #, GROUP_CONCAT(wi.Name SEPARATOR ';')
	, t.Service_Target_Year__c, t.Service_Target_Month__c
	FROM salesforce.work_item__c wi2
	INNER JOIN salesforce.work_package__c wp2 on wi2.Work_Package__c = wp2.Id
	INNER JOIN salesforce.certification__c c2 on wp2.Site_Certification__c = c2.Id
	INNER JOIN (

		SELECT 
			c.Id,
			wi.Service_Target_Year__c,
			wi.Service_Target_Month__c
		FROM salesforce.work_item__c wi
		INNER JOIN salesforce.recordtype rt on wi.RecordTypeId = rt.Id
		INNER JOIN salesforce.work_package__c wp on wi.Work_Package__c = wp.Id
		INNER JOIN salesforce.certification__c c on wp.Site_Certification__c = c.Id
		WHERE 
			rt.Name = 'Audit'
			AND wi.Status__c IN ('Scheduled','Scheduled - Offered','Confirmed','Service change','In Progress','Submitted','Under Review','Support','Completed')
			AND c.Operational_Ownership__c IN ('AUS - Management Systems', 'AUS - Food')
			AND DATE_FORMAT(wi.Service_target_date__c,'%Y %m') IN ('2012 07', '2012 08', '2012 09', '2012 10', '2012 11', '2012 12', '2013 01', '2013 02')
		GROUP BY c.Id
	) t on t.Id = c2.Id
	GROUP BY c2.Id, c2.Name, c2.Status__c
) t2 on t2.Id = c3.Id	
WHERE t2.TargetDates NOT LIKE CONCAT('%',t2.Service_Target_Year__c+1,'-', t2.Service_Target_Month__c, '-01%')
LIMIT 10000; 
#AND c3.Status__c='Active';
#GROUP BY t2.Service_Target_Year__c, t2.Service_Target_Month__c;

#Flown out items
SELECT
	wi.Name,
	wi.Revenue_Ownership__c,
	wi.Work_Item_Stage__c,
	wi.Status__c,
	DATE_FORMAT(wi.Service_target_date__c, '%Y %m') AS 'Target Period',
	FLOOR(DATEDIFF(wi.Work_Item_Date__c, wi.Service_target_date__c)/30) AS 'Relative Scheduled Period',
	DATE_FORMAT(wi.Work_Item_Date__c,'%Y %m') AS 'Scheduled Period',
	sum(wi.Scheduled_Duration__c/8) AS 'Scheduled Days',
	count(wi.Id) AS 'WI Count'
	
FROM salesforce.work_item__c wi
INNER JOIN salesforce.recordtype rt on wi.RecordTypeId = rt.Id

WHERE 
	wi.Status__c NOT IN ('Budget', 'Cancelled')
	AND rt.Name = 'Audit'
	AND wi.Revenue_Ownership__c IN ('AUS-Global-NSW/ACT','AUS-Global-VIC/TAS','AUS-Global-QLD','AUS-Global-SA/NT','AUS-Global-WA','AUS-Global-ROW','AUS-Managed Plus-NSW/ACT','AUS-Managed Plus-VIC/TAS','AUS-Managed Plus-QLD','AUS-Managed Plus-SA/NT','AUS-Managed Plus-WA','AUS-Managed Plus-ROW','AUS-Managed-NSW/ACT','AUS-Managed-VIC/TAS','AUS-Managed-QLD','AUS-Managed-SA/NT','AUS-Managed-WA','AUS-Managed-ROW','AUS-Direct-NSW/ACT','AUS-Direct-VIC/TAS','AUS-Direct-QLD','AUS-Direct-SA/NT','AUS-Direct-WA','AUS-Direct-ROW','AUS-Food-NSW/ACT','AUS-Food-VIC/TAS','AUS-Food-QLD','AUS-Food-SA/NT','AUS-Food-WA','AUS-Food-ROW')
GROUP BY wi.Revenue_Ownership__c, wi.Work_Item_Stage__c, wi.Status__c, `Target Period`,`Relative Scheduled Period`, `Scheduled Period`
#GROUP BY `Target Period`,`Relative Scheduled Period`, `Scheduled Period`
ORDER BY wi.Name,`Target Period`, `Relative Scheduled Period`, `Scheduled Period`
LIMIT 100000;

# Cancellations
SELECT 
	c.Operational_Ownership__c as 'Business Unit'
	,wi.Cancellation_Reason__c as 'Reason'
	#,wi.Name
	#,wi.Id
	#,wi.Required_Duration__c/8
	, DATE_FORMAT(wi.Service_target_date__c,'%Y %m') AS 'Period' 
	, sum(wi.Required_Duration__c/8) AS 'Days'
	#, wi.Id, wi.Name, wi.Service_target_date__c, rt.Name, c.Primary_Standard__c, t.Status__c, c.Client_Site__c
FROM salesforce.work_item__c wi 
INNER JOIN salesforce.recordtype rt on wi.RecordTypeId = rt.Id
INNER JOIN salesforce.work_package__c wp on wp.Id = wi.Work_Package__c 
INNER JOIN salesforce.certification__c c on c.Id = wp.Site_Certification__c
WHERE 
	wi.Status__c='Cancelled' 
	AND rt.Name = 'Audit'
	AND c.Operational_Ownership__c IN ('AUS - Management Systems', 'AUS - Food')
	#AND DATE_FORMAT(wi.Service_target_date__c,'%Y %m') = '2013 11'
GROUP BY c.Operational_Ownership__c, wi.Cancellation_Reason__c, `Period`
ORDER BY c.Operational_Ownership__c, wi.Cancellation_Reason__c, `Period`;


# Target Months Changes
#select t2.name, count(t2.WorkItem) from
#(
#select t.Name, t.WorkItem from (
SELECT 
	wi.Name as 'WorkItem'
	, wi.Revenue_Ownership__c
#, wi.Comments__c
	, wih.CreatedDate
	#, u.Name
	, DATE_FORMAT(wih.CreatedDate, "%Y %m") AS 'ChangePeriod'
	, wih.Field
	, wih.OldValue
	, wih.NewValue
	, wi.Service_target_date__c
	, wi.Service_Target_Month__c
	, wi.Service_Target_Year__c
FROM salesforce.work_item__history wih
INNER JOIN salesforce.user u ON u.Id= wih.CreatedById
LEFT JOIN salesforce.work_item__c wi ON wih.ParentId = wi.Id
WHERE 
	Field IN ('Service_Target_Month__c', 'Service_Target_Year__c')
	#AND wi.Name in ('WI-595652','WI-595658','WI-595778','WI-583079','WI-583084','WI-595939','WI-569440','AU-324282','WI-573327','WI-596644','AU-283537','WI-573895','WI-596896','WI-570114','WI-582495','WI-582501','WI-582519','WI-582515','WI-582497','WI-582505','WI-582521','WI-582510','AU-384676','WI-601611','WI-601616','WI-584951','WI-583074','WI-583070','WI-584946','WI-584952','WI-584959','WI-605103','AS-418879','AU-358917','WI-597275','WI-582636','WI-597577','WI-597582','WI-597586','WI-597589','WI-569214','WI-569213','WI-569212','WI-569211','WI-569208','WI-569206','WI-569205','WI-569204','WI-569203','WI-569202','WI-569201','WI-605673','WI-605676','WI-605679','WI-605682','WI-560229','WI-532374','WI-573809','WI-596170','AS-404341','AS-404337','AS-404339','WI-562552','WI-562542','WI-562547','WI-562529','WI-562533','WI-562537','WI-573513','WI-595860','WI-607402','WI-607403','WI-514013','WI-595632','AS-409956','AS-363049','AS-364945','AS-418849','AS-365232','AS-360404','AS-363006','AS-365212','AS-364871','AS-362547','AS-366007','AS-365951','AS-361210','AS-401747','AS-362992','AS-363302','AS-361147','AS-362847','AS-362845','AS-372202','AS-367572','AS-365972','AS-365393','AS-361143','AS-361154','AS-361145','AS-361037','WI-563910','WI-563908','WI-563913','WI-607147','WI-607142','AS-415370','WI-596175','AS-397191','AS-372216','AS-400802','AS-363222','AS-363140','AS-372218','AS-363593','AS-362692','AS-362167','AS-358303','AS-401290','AS-401288','AS-363015','AS-363280','AS-398742','AS-397269','AS-400788','AS-339529','AS-339511','AS-404497','AS-398194','AS-398170','AS-398207','AS-398177','AS-399817','AS-398308','AS-398303','AS-398629','AS-398633','AS-398287','AS-399824','AS-338687','AS-361793','AS-338677','WI-576779','WI-610410','WI-610510','WI-610281','WI-610663')
	#wih.ParentId='a3Id000000055cmEAA'
ORDER by ParentId, CreatedDate desc
LIMIT 200000;#) t;
#GROUP by t.WorkItem, t.Name) t2;
#group by t2.Name;


select t.Name, t.WorkItem, t.Id from (
SELECT 
	wi.Name as 'WorkItem'
	, wi.Id
	, wi.Comments__c
	, wih.CreatedDate
	, u.Name
	, DATE_FORMAT(wih.CreatedDate, "%Y %m") AS 'ChangePeriod'
	, wih.Field
	, wih.OldValue
	, wih.NewValue
	,  wi.Service_target_date__c
	, Service_Target_Month__c
	, wi.Service_Target_Year__c
FROM salesforce.work_item__history wih
INNER JOIN salesforce.user u ON u.Id= wih.CreatedById
LEFT JOIN salesforce.work_item__c wi ON wih.ParentId = wi.Id
WHERE 
	Field IN ('Service_Target_Month__c', 'Service_Target_Year__c')
	AND wi.Name in ('WI-595652','WI-595658','WI-595778','WI-583079','WI-583084','WI-595939','WI-569440','AU-324282','WI-573327','WI-596644','AU-283537','WI-573895','WI-596896','WI-570114','WI-582495','WI-582501','WI-582519','WI-582515','WI-582497','WI-582505','WI-582521','WI-582510','AU-384676','WI-601611','WI-601616','WI-584951','WI-583074','WI-583070','WI-584946','WI-584952','WI-584959','WI-605103','AS-418879','AU-358917','WI-597275','WI-582636','WI-597577','WI-597582','WI-597586','WI-597589','WI-569214','WI-569213','WI-569212','WI-569211','WI-569208','WI-569206','WI-569205','WI-569204','WI-569203','WI-569202','WI-569201','WI-605673','WI-605676','WI-605679','WI-605682','WI-560229','WI-532374','WI-573809','WI-596170','AS-404341','AS-404337','AS-404339','WI-562552','WI-562542','WI-562547','WI-562529','WI-562533','WI-562537','WI-573513','WI-595860','WI-607402','WI-607403','WI-514013','WI-595632','AS-409956','AS-363049','AS-364945','AS-418849','AS-365232','AS-360404','AS-363006','AS-365212','AS-364871','AS-362547','AS-366007','AS-365951','AS-361210','AS-401747','AS-362992','AS-363302','AS-361147','AS-362847','AS-362845','AS-372202','AS-367572','AS-365972','AS-365393','AS-361143','AS-361154','AS-361145','AS-361037','WI-563910','WI-563908','WI-563913','WI-607147','WI-607142','AS-415370','WI-596175','AS-397191','AS-372216','AS-400802','AS-363222','AS-363140','AS-372218','AS-363593','AS-362692','AS-362167','AS-358303','AS-401290','AS-401288','AS-363015','AS-363280','AS-398742','AS-397269','AS-400788','AS-339529','AS-339511','AS-404497','AS-398194','AS-398170','AS-398207','AS-398177','AS-399817','AS-398308','AS-398303','AS-398629','AS-398633','AS-398287','AS-399824','AS-338687','AS-361793','AS-338677','WI-576779','WI-610410','WI-610510','WI-610281','WI-610663')
	#wih.ParentId='a3Id000000055cmEAA'
ORDER by ParentId, CreatedDate desc
LIMIT 200000) t
GROUP by t.WorkItem, t.Name;

# Target Months Changes
SELECT 
	wi.Name
	, count(wi.Name)
FROM salesforce.work_item__history wih
LEFT JOIN salesforce.work_item__c wi ON wih.ParentId = wi.Id
WHERE 
	Field IN ('Service_Target_Month__c', 'Service_Target_Year__c')
	#wih.ParentId='a3Id000000055cmEAA'
GROUP BY wi.Name
ORDER by count(wi.Name) desc

LIMIT 200000;
