# Opportunity Closed-Won to Site Certification to Work Package to Work Item
select 
	o.Id as 'Opp. Id'
	, o.Name as 'Opp. Name'
	, o.Probability as 'Opp. Probability'
	, o.Amount as 'Opp. Amount'
	, o.Status__c as 'Opp. Status'
	, o.Opportunity_Status__c as 'Opp. Stage'
	, o.CloseDate as 'Opp. Closed Date'
	, o.Delivery_Strategy_Created__c
	, c.Id as 'Site Cert Id'
	, c.Name as 'Site Cert Name'
	, c.Primary_Certification__c as 'Cert Id'
	, c.Status__c as 'Site Cert Status'
	, wp.Id as 'Work Package Id'
	, wp.Name as 'Work Package Name'
	, wp.Status__c as 'Work Package Status'
	, wp.Type__c as 'Work Package Type'
	, wi.Id as 'Work Item Id'
	, wi.Name as 'Work Item Name'
	, wi.Status__c as 'Work Item Status'
from salesforce.opportunity o
inner join salesforce.certification__c c on c.Opportunity_Created_From__c = o.Id
INNER JOIN salesforce.work_package__c wp on c.Id = wp.Site_Certification__c
INNER JOIN salesforce.work_item__c wi on wp.Id = wi.Work_Package__c 

where
o.Business_1__c IN ('Australia')
AND o.Opportunity_Status__c='Won'
and o.CloseDate>='2013-07-01' and o.CloseDate<='2014-06-30'
and o.Delivery_Strategy_Created__c is not null
and c.Primary_Certification__c is not null
#and o.Id='006d000000CgiSfAAJ'
#cand c.Id = 'a1kd00000004KzHAAU'
limit 10000;

# Opportunity Closed-Won to Site Certification to Work Package Initial to Work Item count all, count open, count cancelled
select 
	t.*
	, if (t.Others > 0, 1, 0) as 'Pay Commission'
	, if (t.Cancelled > 0, 1, 0) as 'Follow Up'
	, if (t.Others = 0 and t.Cancelled = 0, 1, 0) as 'No Commission'
	
from (
	select 
		o.Id as 'Opp. Id'
		, o.Name as 'Opp. Name'
		,u.Name as 'Opp. Owner'
		#, a.Name as 'Client Site'
		#, c.Id as 'Site Cert Id'
		#, c.Name as 'Site Cert Name'
		, count(wi.Id) as 'Count Work Item'
		, sum(if (wi.Status__c='Scheduled' or wi.Status__c='Scheduled - Offered' or wi.Status__c='Open' or wi.Status__c='Service change' or wi.Status__c='Cancelled',0,1)) as 'Others'
		, sum(if (wi.Status__c='Cancelled',1,0)) as 'Cancelled'
		, sum(if (wi.Status__c='Scheduled' or wi.Status__c='Scheduled - Offered' or wi.Status__c='Open' or wi.Status__c='Service change' ,1,0)) as 'Sched/SchedOff/Open/SerChange'

	from salesforce.opportunity o
	left join salesforce.user u on o.OwnerId = u.Id
	inner join salesforce.certification__c c on c.Opportunity_Created_From__c = o.Id
	INNER JOIN salesforce.account a on a.Id = c.Primary_client__c
	INNER JOIN salesforce.work_package__c wp on c.Id = wp.Site_Certification__c
	INNER JOIN salesforce.work_item__c wi on wp.Id = wi.Work_Package__c 
	where
	o.Business_1__c IN ('Australia')
	AND o.Opportunity_Status__c='Won'
	and o.CloseDate>='2013-07-01' and o.CloseDate<='2013-12-31'
	and o.Delivery_Strategy_Created__c is not null
	and c.Primary_Certification__c is not null
	and wp.Type__c = 'Initial'
	group by `Opp. Id`, `Opp. Name`#, `Site Cert Id`, `Site Cert Name`
) t
limit 10000;

select 
	sum(o.Amount)	
from salesforce.opportunity o
where
o.Business_1__c IN ('Australia')
AND o.Opportunity_Status__c='Won'
and o.CloseDate>='2013-07-01' and o.CloseDate<='2014-06-30'
and o.Delivery_Strategy_Created__c is not null
limit 10000;

select sum(i.Total_Amount__c) 
from salesforce.invoice__c i
where i.Invoice_Processed_Date__c>='2013-07-01' and i.Invoice_Processed_Date__c<='2014-06-30'