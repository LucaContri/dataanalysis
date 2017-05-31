select 		
	t.GrandParent, t.Parent, t.Client, 		
	group_concat(distinct t.ClientSegmentation separator '	') as 'Client Segmentations',	
	group_concat(distinct t.ClientNumber separator '	') as 'Client Numbers',
	#(COUNT(distinct t.Id)-count(distinct t.Invoiced)) as 'ErrorsInInvoiced',	
	# if ErrorsInInvoiced>0 use query below to calculate total invoiced	
	sum(distinct t.Invoiced) as 'Invoiced',	
	t.Currency as 'Currency',	
	group_concat(distinct t.RelationshipManager separator '	') as 'Relationship Managers',
	group_concat(distinct t.ServiceDeliveryCoordinator separator '	')  as 'Service Delivery Coordinators',
	group_concat(distinct sc.Standard_Name__c SEPARATOR '	') as 'Standards'	
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
inner join salesforce.account a on a.Id = i.Billing_Client__c 		
left join salesforce.account p ON a.ParentId = p.Id		
left join salesforce.account gp ON gp.Id = p.ParentId		
left join salesforce.User rm on rm.Id = a.Relationship_Manager__c		
left join salesforce.user sc on sc.Id = a.Service_Delivery_Coordinator__c
where i.Invoice_Processed_Date__c >= '2013-07-01' and i.Invoice_Processed_Date__c <= '2014-06-30'		
#and a.Name='Viridian'		
group by `GrandParent`, `Parent`, `Client`, `Currency`, a.Id, `ClientSegmentation`,  `ClientNumber`, `RelationshipManager`, `ServiceDeliveryCoordinator`		
) t		
left join salesforce.certification__c sc on sc.Primary_client__c = t.Id		
where sc.Status__c='Active'		
group by `GrandParent`, `Parent`, `Client`, `Currency`		
limit 10000;		


#explain
select
    gp.ParentId as 'GrandParent',		
    p.Name as 'Parent',		
    a.Name as 'Client',		
	a.Id,	
	a.Client_Segmentation__c as 'ClientSegmentation',	
	a.client_Number__c as 'ClientNumber',	
	rm.Name as 'RelationshipManager',	
	sc.Name as 'ServiceDeliveryCoordinator',
	t.`2013-07` as 'Jul 13',
	t.`2013-08` as 'Aug 13',
	t.`2013-09` as 'Sep 13',
	t.Currency 
from account a 
left join salesforce.account p ON a.ParentId = p.Id		
left join salesforce.account gp ON gp.Id = p.ParentId		
left join salesforce.User rm on rm.Id = a.Relationship_Manager__c		
left join salesforce.user sc on sc.Id = a.Service_Delivery_Coordinator__c
left join (
select
	i.Billing_Client__c, 
	sum(if (date_format(i.Invoice_Processed_Date__c,'%Y-%m') = '2013-07', i.Total_Amount__c , 0)) as '2013-07',
	sum(if (date_format(i.Invoice_Processed_Date__c,'%Y-%m') = '2013-08', i.Total_Amount__c , 0)) as '2013-08',
	sum(if (date_format(i.Invoice_Processed_Date__c,'%Y-%m') = '2013-09', i.Total_Amount__c , 0)) as '2013-09',
	i.CurrencyIsoCode as 'Currency'	
from salesforce.invoice__c i 
where 
date_format(i.Invoice_Processed_Date__c, '%Y-%m') > '2013-07'
and i.isDeleted=0 
and i.Status__c in ('Open', 'Closed')
group by i.Billing_Client__c limit 1000000) t on a.Id = t.Billing_Client__c
where a.IsDeleted=0
and a.Client_Segmentation__c = 'Managed Plus'
and a.Client_Ownership__c='Australia'
group by a.Id
limit 100000;

use salesforce;
select gp.ParentId as 'GrandParent',p.Name as 'Parent',a.Name as 'Client',a.Id,a.Client_Segmentation__c as 'ClientSegmentation',a.client_Number__c as 'ClientNumber',rm.Name as 'RelationshipManager',sc.Name as 'ServiceDeliveryCoordinator',
t.`2013-07` as 'Jul 13',
t.`2013-08` as 'Aug 13',
t.`2013-09` as 'Sep 13',
t.`2013-10` as 'Oct 13',
t.`2013-11` as 'Nov 13',
t.`2013-12` as 'Dec 13',
t.`2014-01` as 'Jan 14',
t.`2014-02` as 'Feb 14',
t.`2014-03` as 'Mar 14',
t.`2014-04` as 'Apr 14',
t.`2014-05` as 'May 14',
t.`2014-06` as 'Jun 14',
t.Currency from account a left join salesforce.account p ON a.ParentId = p.Id left join salesforce.account gp ON gp.Id = p.ParentId left join salesforce.User rm on rm.Id = a.Relationship_Manager__c left join salesforce.user sc on sc.Id = a.Service_Delivery_Coordinator__c left join ( select i.Billing_Client__c,
sum(if (date_format(i.Invoice_Processed_Date__c,'%Y-%m') = '2013-07', i.Total_Amount__c , 0)) as '2013-07',
sum(if (date_format(i.Invoice_Processed_Date__c,'%Y-%m') = '2013-08', i.Total_Amount__c , 0)) as '2013-08',
sum(if (date_format(i.Invoice_Processed_Date__c,'%Y-%m') = '2013-09', i.Total_Amount__c , 0)) as '2013-09',
sum(if (date_format(i.Invoice_Processed_Date__c,'%Y-%m') = '2013-10', i.Total_Amount__c , 0)) as '2013-10',
sum(if (date_format(i.Invoice_Processed_Date__c,'%Y-%m') = '2013-11', i.Total_Amount__c , 0)) as '2013-11',
sum(if (date_format(i.Invoice_Processed_Date__c,'%Y-%m') = '2013-12', i.Total_Amount__c , 0)) as '2013-12',
sum(if (date_format(i.Invoice_Processed_Date__c,'%Y-%m') = '2014-01', i.Total_Amount__c , 0)) as '2014-01',
sum(if (date_format(i.Invoice_Processed_Date__c,'%Y-%m') = '2014-02', i.Total_Amount__c , 0)) as '2014-02',
sum(if (date_format(i.Invoice_Processed_Date__c,'%Y-%m') = '2014-03', i.Total_Amount__c , 0)) as '2014-03',
sum(if (date_format(i.Invoice_Processed_Date__c,'%Y-%m') = '2014-04', i.Total_Amount__c , 0)) as '2014-04',
sum(if (date_format(i.Invoice_Processed_Date__c,'%Y-%m') = '2014-05', i.Total_Amount__c , 0)) as '2014-05',
sum(if (date_format(i.Invoice_Processed_Date__c,'%Y-%m') = '2014-06', i.Total_Amount__c , 0)) as '2014-06',
i.CurrencyIsoCode as 'Currency' from salesforce.invoice__c i 
where date_format(i.Invoice_Processed_Date__c, '%Y-%m') > '2013-07' 
and i.isDeleted=0 
and i.Status__c in ('Open', 'Closed') 
group by i.Billing_Client__c) t on a.Id = t.Billing_Client__c 
where a.IsDeleted=0 
and a.Client_Segmentation__c = 'Managed Plus' 
and a.Client_Ownership__c='Australia' 
and a.Client_Account_Status__c not in ('Pre-Sales')
group by a.Id;

create or replace view assurance_top120_sub as
select i.Billing_Client__c,
date_format(i.Invoice_Processed_Date__c,'%Y-%m') as 'Period',
i.Total_Amount__c as 'Amount',
i.CurrencyIsoCode as 'Currency' from salesforce.invoice__c i 
where date_format(i.Invoice_Processed_Date__c, '%Y-%m') > '2013-07' 
and i.isDeleted=0 
and i.Status__c in ('Open', 'Closed') 
group by i.Billing_Client__c, `Period`;

create or replace view assurance_top120 as 
select gp.ParentId as 'GrandParent',p.Name as 'Parent',a.Name as 'Client',a.Id,a.Client_Segmentation__c as 'ClientSegmentation',
a.client_Number__c as 'ClientNumber',
site.Business_City__c, scs.Name as 'State', ccs.Name as 'Country', site.Business_Zip_Postal_Code__c as 'Postcode', 
rm.Name as 'RelationshipManager',sc.Name as 'ServiceDeliveryCoordinator',t.*
from account a 
left join salesforce.account p ON a.ParentId = p.Id 
left join salesforce.account gp ON gp.Id = p.ParentId 
left join salesforce.User rm on rm.Id = a.Relationship_Manager__c 
left join salesforce.user sc on sc.Id = a.Service_Delivery_Coordinator__c 
left join salesforce.account site on site.ParentId = a.Id
left join salesforce.State_Code_Setup__c scs on site.Business_State__c = scs.Id
left join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id
left join assurance_top120_sub t on a.Id = t.Billing_Client__c 
where a.IsDeleted=0 
and a.Client_Segmentation__c = 'Managed Plus' 
and a.Client_Ownership__c='Australia' 
and a.Client_Account_Status__c not in ('Pre-Sales')
and site.Finance_Statement_Site__c=1
group by a.Id, t.Period;

select * from assurance_top120;

