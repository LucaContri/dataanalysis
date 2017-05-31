select 
    o.Id,
    o.Name,
    o.Proposed_Delivery_Date__c,
    p.name as 'Product',
    oli.Days__c,
    c.Name as 'Client Site Name',
    c.Business_Address_1__c,
    c.Business_Address_2__c,
    c.Business_Address_3__c,
    c.Business_City__c,
    c.Business_Zip_Postal_Code__c,
    c.FCountry__c,
    scs.Name as 'State',
    s.Name as 'Standard',
    cd.Name as 'Code'
from
    salesforce.opportunity o
        left join
    salesforce.opportunitylineitem oli ON oli.OpportunityId = o.Id
        left join
    salesforce.pricebookentry pbe ON pbe.Id = oli.PricebookEntryId
        left join
    salesforce.product2 p ON p.Id = pbe.Product2Id
        left join
    salesforce.opportunity_site_certification__c osc ON osc.Id = oli.Opportunity_Site_Certification__c
        left join
    salesforce.account c ON c.Id = osc.Client_Site__c
        left join
    salesforce.State_Code_Setup__c scs ON c.Business_State__c = scs.Id
        left join
    salesforce.oppty_site_cert_standard_program__c oscs ON oscs.Opportunity_Site_Certification__c = osc.Id
        left join
    salesforce.standard_program__c sp ON oscs.Standard_Program__c = sp.Id
        left join
    salesforce.standard__c s ON sp.Standard__c = s.Id
        left join
    salesforce.opportunity_site_certification_code__c oscc ON oscc.Oppty_Site_Cert_Standard_Program__c = oscs.Id
        left join
    salesforce.code__c cd ON cd.Id = oscc.Code__c
where
    oli.Id = '00kd0000009OqDWAA0'
        and o.IsDeleted = 0
        and oli.Status__c = 'Active'
        and oli.Days__C > 0
order by `Product` , `Client Site Name` , `Standard` , `Code`;

select 
    o.Id,
    o.Name,
	oli.Id,
    oli.Client_Site__c,
    p.name as 'Product',
    o.Proposed_Delivery_Date__c
from
    salesforce.opportunity o
        left join
    salesforce.opportunitylineitem oli ON oli.OpportunityId = o.Id
        left join
    salesforce.pricebookentry pbe ON pbe.Id = oli.PricebookEntryId
        left join
    salesforce.product2 p ON p.Id = pbe.Product2Id
where
    o.Name like 'Rutledge Engineering (Aust) Pty Ltd 14001 4801'
        and o.IsDeleted = 0
        and oli.Status__c = 'Active'
        and oli.Days__C > 0
order by o.Name , oli.Client_Site__c , p.Name;

select 
    Id, Name
from
    opportunity
where
    Name like '%Rutledge Engineering (Aust) Pty Ltd 14001 4801%';