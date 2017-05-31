SELECT 
c.Operational_Ownership__c as 'Operational Owership', 
wi.Revenue_Ownership__c as 'Revenue Onewrship',
cp.Name as 'Certification', 
c.Name as 'Site certification',
a.Name as 'Client Name',
s.Name as 'Standard',
p.Name as 'Program',
wi.Status__c as 'Status',
wi.Work_Item_Stage__c as 'Stage',
wi.Work_Item_Date__c as 'Work Item Start Date',
wi.Service_target_date__c as 'Service target date',
wi.Required_Duration__c as 'Required Duration'

FROM salesforce.work_item__c wi 
#INNER JOIN salesforce.recordtype rt on wi.RecordTypeId = rt.Id
INNER JOIN salesforce.work_package__c wp on wp.Id = wi.Work_Package__c 
INNER JOIN salesforce.certification__c c on c.Id = wp.Site_Certification__c
INNER JOIN salesforce.certification__c cp on cp.Id = c.Primary_Certification__c
INNER JOIN salesforce.account a ON cp.Primary_client__c = a.Id 
INNER JOIN salesforce.site_certification_standard_program__c scsp on c.Id = scsp.Site_Certification__c
INNER JOIN salesforce.standard_program__c sp ON scsp.Standard_Program__c=sp.Id
INNER JOIN salesforce.program__c p ON sp.Program__c = p.Id
INNER JOIN salesforce.standard__c s ON sp.Standard__c = s.Id
WHERE 
	wi.Status__c IN ('Open', 'Scheduled', 'Scheduled - Offered', 'Confirmed', 'Service change', 'In Progress', 'Submitted', 'Under Review', 'Completed', 'Complete') 
	AND wi.Work_Item_Stage__c IN ('Gap', 'Stage 1', 'Stage 2')
	#AND rt.Name = 'Audit'
	AND c.Operational_Ownership__c IN ('AUS - Management Systems', 'AUS - Food')
	#AND DATE_FORMAT(wi.Service_target_date__c,'%Y %m') = '2013 11'

LIMIT 10000