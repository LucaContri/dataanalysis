#Incoming (New Business) vs. Outgoing (Cancelled)
# Cancellations
SELECT 
	c.Operational_Ownership__c as 'Business Unit'
	, DATE_FORMAT(wi.Work_Item_Date__c,'%Y %m') AS 'Period' 	
	,wi.Id
	,wi.Name
	,wi.Status__c
	,wi.Required_Duration__c/8 as 'Days'
	,wi.Cancellation_Reason__c as 'Cancellation Reason'
	,wi.Service_Change_Reason__c as 'Service Change Reason'
	,wi.Comments__c
	#, sum(wi.Required_Duration__c/8) AS 'Days'
	#, wi.Id, wi.Name, wi.Service_target_date__c, rt.Name, c.Primary_Standard__c, t.Status__c, c.Client_Site__c
FROM salesforce.work_item__c wi 
INNER JOIN salesforce.recordtype rt on wi.RecordTypeId = rt.Id
INNER JOIN salesforce.work_package__c wp on wp.Id = wi.Work_Package__c 
INNER JOIN salesforce.certification__c c on c.Id = wp.Site_Certification__c
WHERE 
	wi.Status__c='Cancelled' 
	AND rt.Name = 'Audit'
	AND c.Operational_Ownership__c IN ('AUS - Management Systems', 'AUS - Food')
	AND DATE_FORMAT(wi.Work_Item_Date__c,'%Y') IN ('2013', '2014')
#GROUP BY c.Operational_Ownership__c, `Period`, `Status`, `Cancellation Reason`, `Service Change Reason`
#ORDER BY c.Operational_Ownership__c, `Period`, `Status`, `Cancellation Reason`, `Service Change Reason`
limit 1000000;

#New Business
(SELECT 
	c.Operational_Ownership__c as 'Business Unit'
	, DATE_FORMAT(wi.Service_target_date__c,'%Y %m') AS 'Period' 
	, 'New Business' AS 'Status'
	, 'n/a' as 'Reason'
	, sum(wi.Required_Duration__c/8) AS 'Days'
	#, wi.Id, wi.Name, wi.Service_target_date__c, rt.Name, c.Primary_Standard__c, t.Status__c, c.Client_Site__c
FROM salesforce.work_item__c wi 
INNER JOIN salesforce.recordtype rt on wi.RecordTypeId = rt.Id
INNER JOIN salesforce.work_package__c wp on wp.Id = wi.Work_Package__c 
INNER JOIN salesforce.certification__c c on c.Id = wp.Site_Certification__c
INNER JOIN
	(SELECT scsp.Site_Certification__c, scsp.Status__c FROM salesforce.site_certification_standard_program__c scsp where Status__c IN ('Applicant', 'Customised')) t ON t.Site_Certification__c= c.Id
WHERE 
	#wi.Status__c='Open' 
	#AND 
	rt.Name = 'Audit'
	AND wi.Work_Item_Stage__c IN ('Certification', 'Gap', 'Initial Inspection', 'Stage 1', 'Stage 2')
	AND c.Operational_Ownership__c IN ('AUS - Management Systems', 'AUS - Food')
	#AND c.Operational_Ownership__c IN ('AUS - Management Systems')
	#AND DATE_FORMAT(wi.Service_target_date__c,'%Y %m') = '2013 12'
GROUP BY c.Operational_Ownership__c, `Period`, `Status`, `Reason`
ORDER BY c.Operational_Ownership__c, `Period`, `Status`, `Reason`)
