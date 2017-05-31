use training;
create index opportunityhistory_index on opportunityhistory(OpportunityId);

#explain
(select 
	o.Type,
    a.Name as 'Client',
    #o.Id,
    o.CreatedDate as 'Date Created',
    o.CloseDate,
    min(if(oh.StageName in ('Closed Won', 'Closed Lost'),oh.CreatedDate,null)) as 'Date Closed',
    o.Amount/ct.ConversionRate as 'Amount GST',
    oo.Name as 'Owner',
    ifnull(o.LeadSource,'') as 'Lead Source',
    o.Opportunity_Product_Line_Items__c,
    ifnull(o.Contract_Term__c,'') as 'Contract Term',
    timestampdiff(day,o.createdDate,min(if(oh.StageName in ('Closed Won', 'Closed Lost'),oh.CreatedDate,null))) as 'Aging Created',
    group_concat(distinct oh.StageName) as 'Stages',
    sum(if(oh.StageName='Opportunity Qualified',1,0)) as 'Opportunity Qualified', # Probability 10
	sum(if(oh.StageName='Analysis of Needs',1,0)) as 'Analysis of Needs', # Probability 20
	sum(if(oh.StageName='Solution Proposal',1,0)) as 'Solution Proposal', # Probability 30
	sum(if(oh.StageName='Presentation',1,0)) as 'Presentation', # Probability 40
	sum(if(oh.StageName='Vendor Finalist',1,0)) as 'Vendor Finalist', # Probability 51
	sum(if(oh.StageName='Verbal Acceptance',1,0)) as 'Verbal Acceptance', # Probability 80
	sum(if(oh.StageName='In Legal',1,0)) as 'In Legal', # Probability 91
	sum(if(oh.StageName='Submit For Approval',1,0)) as 'Submit For Approval', # Probability 93
	sum(if(oh.StageName='Waiting For Approval',1,0)) as 'Waiting For Approval', # Probability 94
    
    ifnull(timestampdiff(day,o.CreatedDate, min(if(oh.StageName='Opportunity Qualified',oh.CreatedDate,null))),'') as ' Days to Opportunity Qualified',
	ifnull(timestampdiff(day,o.CreatedDate, min(if(oh.StageName='Analysis of Needs',oh.CreatedDate,null))),'') as ' Days to Analysis of Needs',
	ifnull(timestampdiff(day,o.CreatedDate, min(if(oh.StageName='Solution Proposal',oh.CreatedDate,null))),'') as ' Days to Solution Proposal',
	ifnull(timestampdiff(day,o.CreatedDate, min(if(oh.StageName='Presentation',oh.CreatedDate,null))),'') as ' Days to Presentation',
	ifnull(timestampdiff(day,o.CreatedDate, min(if(oh.StageName='Vendor Finalist',oh.CreatedDate,null))),'') as ' Days to Vendor Finalist',
	ifnull(timestampdiff(day,o.CreatedDate, min(if(oh.StageName='Verbal Acceptance',oh.CreatedDate,null))),'') as ' Days to Verbal Acceptance',
	ifnull(timestampdiff(day,o.CreatedDate, min(if(oh.StageName='In Legal',oh.CreatedDate,null))),'') as ' Days to In Legal',
	ifnull(timestampdiff(day,o.CreatedDate, min(if(oh.StageName='Submit For Approval',oh.CreatedDate,null))),'') as ' Days to Submit For Approval',
	ifnull(timestampdiff(day,o.CreatedDate, min(if(oh.StageName='Waiting For Approval',oh.CreatedDate,null))),'') as ' Days to Waiting For Approval',
    ifnull(o.Region__c,'') as 'Region',
    o.IsWon
from training.opportunity o
left join training.opportunityhistory oh on oh.OpportunityId = o.Id and oh.IsDeleted = 0
left join salesforce.currencytype ct on o.CurrencyIsoCode = ct.IsoCode
left join training.user oo on o.OwnerId = oo.Id
left join training.account a on o.AccountId = a.Id
where
	o.IsDeleted = 0
    and o.StageName in ('Closed Won', 'Closed Lost')
    and o.Type in ('BV - GRC - Implementation Services','BV - EHS - Implementation Services')
group by o.Id);

select * from training.sf_tables where TableName = 'opportunityhistory';

select oh.StageName, count(distinct oh.Id), oh.Probability
from training.opportunityhistory oh
inner join training.opportunity o on oh.OpportunityId = o.Id
where
	o.IsDeleted = 0
    and o.Type in ('BV - GRC - Implementation Services','BV - EHS - Implementation Services')
	and oh.IsDeleted = 0
    and oh.CreatedDate >= '2015'
group by oh.StageName;


(select 
	o.Type,
    a.Name as 'Client',

    #o.Id,
    o.CreatedDate as 'Date Created',
    #o.CloseDate,
    #min(if(oh.StageName in ('Closed Won', 'Closed Lost'),oh.CreatedDate,null)) as 'Date Closed',
    #o.Amount/ct.ConversionRate as 'Amount GST',
    oo.Name as 'Owner',
    ifnull(o.LeadSource,'') as 'Lead Source',
    
    o.Opportunity_Product_Line_Items__c,
    ifnull(o.Contract_Term__c,'') as 'Contract Term',
    
    timestampdiff(day,o.createdDate,oh.CreatedDate) as 'Aging Created',
    oh.StageName,
    oh.Amount/ct.ConversionRate as 'Amount AUD',
    oh.Probability,
    ifnull(o.Region__c,'') as 'Region',
    o.IsWon,
    BillingCity, BillingCountry, BillingPostalCode, BillingState, a.Industry, a.Industry_Vertical__c, a.Industry_Sub_group__c
from training.opportunity o
inner join training.opportunityhistory oh on oh.OpportunityId = o.Id and oh.IsDeleted = 0
left join salesforce.currencytype ct on oh.CurrencyIsoCode = ct.IsoCode
left join training.user oo on o.OwnerId = oo.Id
left join training.account a on o.AccountId = a.Id
where
	o.IsDeleted = 0
    and o.StageName in ('Closed Won', 'Closed Lost')
    #and o.Type in ('BV - GRC - Implementation Services','BV - EHS - Implementation Services')
group by oh.Id);


(select 
	o.Id,
    o.CreatedDate as 'Date Created',
	oh.CreatedDate as 'Date Updated',
    o.Type,
    a.Name as 'Client',
    oo.Name as 'Owner',
    ifnull(o.LeadSource,'') as 'Lead Source',    
    timestampdiff(day,o.createdDate,oh.CreatedDate) as 'Aging Created',
    oh.StageName,
    oh.Amount/ct.ConversionRate as 'Amount AUD',
    oh.Probability,
    ifnull(o.Region__c,'') as 'Region',
    if(o.StageName='Closed Won',1,0) as 'IsWon',
    a.BillingCity, a.BillingCountry, a.BillingPostalCode, a.BillingState, a.Industry
from salesforce.opportunity o
inner join salesforce.opportunityhistory oh on oh.OpportunityId = o.Id and oh.IsDeleted = 0
left join salesforce.currencytype ct on oh.CurrencyIsoCode = ct.IsoCode
left join salesforce.user oo on o.OwnerId = oo.Id
left join salesforce.account a on o.AccountId = a.Id
where
	o.IsDeleted = 0
    and o.StageName in ('Closed Won', 'Closed Lost')
    AND a.Client_Ownership__c = 'Australia'
group by oh.Id);