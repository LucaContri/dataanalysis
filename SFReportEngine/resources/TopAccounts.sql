select 
t.GrandParent, t.Parent, t.Client, 
group_concat(distinct t.ClientSegmentation separator ';') as 'Client Segmentations',
	group_concat(distinct t.ClientNumber separator ';') as 'Client Numbers',
	(COUNT(distinct t.Id)-count(distinct t.Invoiced)) as 'ErrorsInInvoiced',
	# if ErrorsInInvoiced>0 use query below to calculate total invoiced
	sum(distinct t.Invoiced) as 'Invoiced',
	t.Currency as 'Currency',
	group_concat(distinct t.RelationshipManager separator ';') as 'Relationship Managers',
	group_concat(distinct t.ServiceDeliveryCoordinator separator ';')  as 'Service Delivery Coordinators',
group_concat(distinct sc.Standard_Name__c SEPARATOR ';') as 'Standards'
from 
(select 
    gp.ParentId as 'GrandParent',
    p.Name as 'Parent',
    a.Name as 'Client',
	a.Id,
	a.Client_Segmentation__c as 'ClientSegmentation',
	a.client_Number__c as 'ClientNumber',
	rm.Name as 'RelationshipManager',
	sc.Name as 'ServiceDeliveryCoordinator',
	sum(i.Total_Amount__c) as 'Invoiced',
	i.CurrencyIsoCode as 'Currency'
from
	salesforce.invoice__c i 
inner join    
salesforce.account a on a.Id = i.Billing_Client__c 
        left join
    salesforce.account p ON a.ParentId = p.Id
        left join
    salesforce.account gp ON gp.Id = p.ParentId
left join salesforce.User rm on rm.Id = a.Relationship_Manager__c
left join salesforce.user sc on sc.Id = a.Service_Delivery_Coordinator__c

where i.Closed_Date__c >= '2013-01-01' and i.Closed_Date__c <= '2013-12-31'
#and a.Name='Viridian'
group by `GrandParent`, `Parent`, `Client`, `Currency`, a.Id, `ClientSegmentation`,  `ClientNumber`, `RelationshipManager`, `ServiceDeliveryCoordinator`
) t
left join salesforce.certification__c sc on sc.Primary_client__c = t.Id
where sc.Status__c='Active'
group by `GrandParent`, `Parent`, `Client`, `Currency`
limit 10000;

select 
    gp.ParentId as 'GrandParent',
    p.Name as 'Parent',
    a.Name as 'Client',
	sum(i.Total_Amount__c) as 'Invoiced',
	i.CurrencyIsoCode as 'Currency'
from
	salesforce.invoice__c i 
inner join    
salesforce.account a on a.Id = i.Billing_Client__c 
        left join
    salesforce.account p ON a.ParentId = p.Id
        left join
    salesforce.account gp ON gp.Id = p.ParentId


where i.Closed_Date__c >= '2013-01-01' and i.Closed_Date__c <= '2013-12-31'
and a.Name='Tyco Australia Pty Ltd'
group by `GrandParent`, `Parent`, `Client`, `Currency`
