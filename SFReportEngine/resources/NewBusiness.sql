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
p.UOM__c in ('DAY', 'HFD', 'HR')
and oli.First_Year_Revenue__c=1
and p.Category__c IN ('Audit', 'Client Management - Day')
and o.Business_1__c IN ('Australia', 'Product Services')
and oli.New_Retention__c='New'
and o.Opportunity_Status__c='Won'
and o.CloseDate>='2013-01-01' and o.CloseDate<='2013-12-31'

#and o.Delivery_Strategy_Created__c is not null
#and o.Id='006d000000CgiSfAAJ'
#and c.Id is not null
limit 10000;

# Sales Report - Summary
select 
	date_format(o.CloseDate, '%Y %m') as 'Period',	
	sum(o.Amount)
	
from salesforce.opportunity o
where
o.Total_First_Year_Revenue__c>0
and o.Business_1__c IN ('Australia', 'Product Services')
and o.Opportunity_Status__c='Won'
and o.CloseDate>='2013-01-01' and o.CloseDate<='2013-12-31'

group by `Period`
limit 100000;
