
select t.`Business`, 
    t.`Opportunity Type`, 
    t.`Opportunity Id`, 
    t.`Opportunity`, 
    t.`Opportunity Created Date`, 
    t.`Opportunity Closed Won Date`,
    date_format(t.`Opportunity Closed Won Date`,'%Y %m') as 'Opportunity Closed Won Period',
    t.`Days`,
    t.`Amount`,
    t.`Currency`,
    ifnull(t.Delivery_Strategy_Created__c, min(oh.CreatedDate)) as 'Delivery Strategy Created Date',     
    c.Id as 'Certification Id', 
    c.Name as 'Certification', 
    ifnull(c.CreatedDate,'') as 'Certification Created Date', 
    ifnull(min(wi.work_item_Date__c),'') as 'First Audit Date',
    date_format(ifnull(min(wi.work_item_Date__c),''), '%Y %m') as 'First Audit Period',
    ifnull(timestampdiff(day, t.`Opportunity Created Date`, t.`Opportunity Closed Won Date`),'') as 'Opp Created to Won Days',
    ifnull(timestampdiff(day, t.`Opportunity Closed Won Date`, ifnull(t.Delivery_Strategy_Created__c, min(oh.CreatedDate))),'') 'Opp Won to Finalised Days',
    ifnull(timestampdiff(day, ifnull(t.Delivery_Strategy_Created__c, min(oh.CreatedDate)), min(wi.work_item_Date__c)),'') as 'Opp Finalised to First Audit'
from (
select 
	o.Business_1__c as 'Business', 
    o.Type as 'Opportunity Type', 
    o.Id as 'Opportunity Id', 
    o.Name as 'Opportunity', 
    o.CreatedDate as 'Opportunity Created Date', 
    o.CloseDate as 'Opportunity Closed Won Date', 
    o.Manual_Certification_Finalised__c, 
    o.Delivery_Strategy_Created__c,
	sum(oli.Days__c) as 'Days',
    sum(oli.TotalPrice) as 'Amount',
    oli.CurrencyIsoCode as 'Currency'
from salesforce.opportunity o
inner join salesforce.opportunitylineitem oli on oli.OpportunityId = o.Id and oli.IsDeleted=0 and oli.Days__c > 0
inner join salesforce.standard__c s on oli.Standard__c = s.Id
where o.IsDeleted = 0
and o.StageName = 'Closed Won'
and (s.Name like '%WQA%' or s.Name like '%Woolworth%')
and o.CloseDate>='2016-01-01'
group by o.Id) t
left join salesforce.opportunityfieldhistory oh on oh.OpportunityId = t.`Opportunity Id` and oh.Field = 'Manual_Certification_Finalised__c'
left join salesforce.certification__c c on c.Opportunity_Created_From__c = t.`Opportunity Id` and c.IsDeleted = 0
left join salesforce.certification__c sc on sc.Primary_Certification__c = c.Id and sc.IsDeleted = 0
left join salesforce.work_package__c wp on wp.Site_Certification__c = sc.Id and wp.IsDeleted = 0
left join salesforce.work_item__c wi on wi.Work_Package__c = wp.Id and wi.IsDeleted = 0 and wi.Status__c not in ('Cancelled')
group by t.`Opportunity Id`;