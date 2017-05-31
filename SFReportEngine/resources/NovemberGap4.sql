(SELECT 
	c.Operational_Ownership__c as 'Business Unit'
	, DATE_FORMAT(wi.Service_target_date__c,'%Y %m') AS 'Period' 	
	,'Cancellation' AS 'Status'
	,wi.Cancellation_Reason__c as 'Reason'
	,wi.Name
	,wi.Id
	,wi.Required_Duration__c/8
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
	#AND DATE_FORMAT(wi.Service_target_date__c,'%Y %m') = '2013 11'
#GROUP BY c.Operational_Ownership__c, `Period`, `Status`, `Reason`
ORDER BY c.Operational_Ownership__c, `Period`, `Status`, `Reason`)
UNION
#New Business
(select 
	c.Operational_Ownership__c as 'Business Unit'
	, DATE_FORMAT(wi.Service_target_date__c,'%Y %m') AS 'Period' 
	, 'New Business' AS 'Status'
	, wi.Work_Item_Stage__c as 'Reason'
	
	, wi.Id
	, wi.Name	
	,wi.Required_Duration__c
	#, sum(wi.Required_Duration__c/8) AS 'Days'
FROM salesforce.work_item__c wi 
INNER JOIN salesforce.user u on wi.CreatedById = u.Id 
INNER JOIN salesforce.recordtype rt on wi.RecordTypeId = rt.Id
INNER JOIN salesforce.work_package__c wp on wp.Id = wi.Work_Package__c 
INNER JOIN salesforce.certification__c c on c.Id = wp.Site_Certification__c
WHERE 
	rt.Name = 'Audit'
	AND wi.Status__c !='Cancelled'
	AND c.Operational_Ownership__c IN ('AUS - Management Systems', 'AUS - Food')
	AND (u.Name in ('Edison Li', 'Marvin Isidro'))
#GROUP BY `Period`, u.Id, u.Name

);



select 
	c.Operational_Ownership__c as 'Business Unit'
	, c.Id
	, c.Name
	#, DATE_FORMAT(wi.Service_target_date__c,'%Y %m') AS 'Period'
	, DATE_FORMAT(wi.CreatedDate,'%Y %m') AS 'Period' 
	, wi.Service_target_date__c
	, 'New Business' AS 'Status'
	, wi.Work_Item_Stage__c as 'Reason'
	, sclc.Duration__c
	, sclc.Frequency__c
	, sclc.Is_Recurring__c
	, sclc.IsDeleted
	, wi.Work_Package__c
	, wi.Work_Package_Type__c
	, wi.Id
	, wi.Name	
	,wi.Required_Duration__c
	#, sum(wi.Required_Duration__c/8) AS 'Days'
FROM salesforce.work_item__c wi 
INNER JOIN salesforce.user u on wi.CreatedById = u.Id 
INNER JOIN salesforce.recordtype rt on wi.RecordTypeId = rt.Id
INNER JOIN salesforce.work_package__c wp on wp.Id = wi.Work_Package__c 
INNER JOIN salesforce.certification__c c on c.Id = wp.Site_Certification__c
INNER JOIN salesforce.site_certification_lifecycle__c sclc on sclc.Work_Item__c=wi.Id

WHERE 
	rt.Name = 'Audit'
	#AND wi.Status__c !='Cancelled'
	AND c.Operational_Ownership__c IN ('AUS - Management Systems', 'AUS - Food')
	AND (u.Name in ('Edison Li', 'Marvin Isidro'))
	#AND c.Id='a1kd00000009nNpAAI'
ORDER BY `Business Unit`, c.Id, `Period`
LIMIT 100000;


SELECT 
	c.Operational_Ownership__c as 'Business Unit'
	, c.Name
	,'Cancellation' AS 'Status'
	, wi.Cancellation_Reason__c as 'Reason'
	, wi.Work_Package_Type__c
	, wi.Name
	, DATE_FORMAT(wi.Service_target_date__c,'%Y %m') AS 'Period' 	
	, wi.Service_target_date__c
	,wi.Id
	,wi.Required_Duration__c/8
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
	#AND DATE_FORMAT(wi.Service_target_date__c,'%Y %m') = '2013 11'
#GROUP BY c.Operational_Ownership__c, `Period`, `Status`, `Reason`
ORDER BY c.Operational_Ownership__c, `Period`, `Status`, `Reason`;

# Sales Report 
select 
	o.Delivery_Strategy_Created__c
	, o.Id
	, oli.TotalPrice
	, oli.Quantity
	, oli.Days__c
	, o.Name
	, o.Probability
	, pbe.id
	, pbe.Product2Id
	, pbe.ProductCode
	, p.Name
	, p.Category__c
	, o.Amount
	, o.Status__c
	, o.Opportunity_Status__c
	, o.CloseDate
#	, c.Id
#	, c.Name
#oli.Days__c, o.Name, o.Status__c, o.Opportunity_Status__c, o.CloseDate,    
from salesforce.opportunity o
left join salesforce.opportunitylineitem oli on oli.OpportunityId=o.Id
left join salesforce.pricebookentry pbe on oli.PricebookEntryId = pbe.Id
left join salesforce.product2 p on pbe.Product2Id = p.Id
#inner join salesforce.certification__c c on c.Opportunity_Created_From__c = o.Id
where
#where 
#and p.UOM__c in ('DAY', 'HFD', 'HR')
oli.First_Year_Revenue__c=1
#and p.Category__c IN ('Audit', 'Client Management - Day')
and o.Business_1__c IN ('Australia')
and oli.New_Retention__c='New'
and o.Opportunity_Status__c='Won'
and o.CloseDate>='2013-07-01' and o.CloseDate<='2014-06-30'
#and o.Delivery_Strategy_Created__c is not null
#and o.Id='006d000000CgiSfAAJ'
#and c.Id is not null
limit 10000;

select 
	o.Id
	,o.Name
	,o.Probability
	,o.Amount
	,o.CloseDate
	, if (o.Delivery_Strategy_Created__c is null, false, true) AS 'Processed'
	, sum(oli.Days__c) AS 'Days'
#	, c.Id
#	, c.Name
#oli.Days__c, o.Name, o.Status__c, o.Opportunity_Status__c, o.CloseDate,    
from salesforce.opportunity o
left join salesforce.opportunitylineitem oli on oli.OpportunityId=o.Id
left join salesforce.pricebookentry pbe on oli.PricebookEntryId = pbe.Id
left join salesforce.product2 p on pbe.Product2Id = p.Id
#inner join salesforce.certification__c c on c.Opportunity_Created_From__c = o.Id
where
#where 
#and p.UOM__c in ('DAY', 'HFD', 'HR')
oli.First_Year_Revenue__c=1
#and p.Category__c IN ('Audit', 'Client Management - Day')
and o.Business_1__c IN ('Australia')
and oli.New_Retention__c='New'
and o.Opportunity_Status__c='Won'
#and o.CloseDate>='2013-07-01' and o.CloseDate<='2014-06-30'
#and o.Delivery_Strategy_Created__c is not null
#and o.Id='006d000000CgiSfAAJ'
#and c.Id is not null
group by o.id
limit 10000;