select 
    o.Id,
    o.AccountId,
    o.Amount,
    o.Probability,
    o.Type,
    o.leadSource,
	GROUP_CONCAT(DISTINCT oli.PricebookEntryId) as products,
	o.HasOpportunityLineItem,
	o.OwnerId,
	o.Business_1__c,
	o.Client_Status__c,
	o.Employee_Referral_Qualified__c,
	o.Lead_Type__c,
	o.No_of_Employess__c,
	o.Number_of_Sample_Sites__c,
	o.Number_of_Sites__c,
	o.Opportunity_Status__c,
	o.Proposed_Delivery_Date__c,
	o.Pre_paid__c,
	o.Program__c,
	o.Proposed_Service_Type__c,
	o.SAIG_Employee_Referral__c,
	o.Sample_Service__c,
	o.Region__c,
    o.StageName
from
    salesforce.opportunity o
	left join salesforce.opportunitylineitem oli on oli.OpportunityId = o.Id
where
    o.isDeleted = 0
	and o.isClosed in (1)
	and o.Status__c='Active'
group by o.Id,
    o.AccountId,
    o.Amount,
    o.Probability,
    o.Type,
    o.leadSource,
	o.HasOpportunityLineItem,
	o.OwnerId,
	o.Business_1__c,
	o.Client_Status__c,
	o.Employee_Referral_Qualified__c,
	o.Lead_Type__c,
	o.No_of_Employess__c,
	o.Number_of_Sample_Sites__c,
	o.Number_of_Sites__c,
	o.Opportunity_Status__c,
	o.Proposed_Delivery_Date__c,
	o.Pre_paid__c,
	o.Program__c,
	o.Proposed_Service_Type__c,
	o.SAIG_Employee_Referral__c,
	o.Sample_Service__c,
	o.Region__c,
    o.StageName
limit 100000