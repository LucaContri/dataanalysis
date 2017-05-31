select sc.Revenue_Ownership__c, scsp.Id, scsp.Name, scsp.CreatedDate, scsp.Status__c, wi.Id, wi.Name, wi.Work_Item_Date__c, wi.Status__c, wi.Primary_Standard__c, wi.Required_Duration__c, av.*, sc.Opportunity_Created_From__c, c.Opportunity_Created_From__c
from salesforce.site_certification_standard_program__c scsp
inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
inner join salesforce.certification__c c on sc.Primary_Certification__c = c.Id
inner join salesforce.work_item__c wi on wi.Site_Certification_Standard__c = scsp.Id and wi.IsDeleted = 0 and wi.Status__c not in ('Cancelled') and wi.Work_Item_Date__c <= date_add(scsp.CreatedDate, interval 1 year)
left join analytics.audit_values av on wi.Id = av.`Work Item Id`
where 
sc.Revenue_Ownership__c like 'AUS%'
and sc.Revenue_Ownership__c not like '%Product%'
and scsp.CreatedDate >= '2015-07-01';


(select sc.Revenue_Ownership__c, scsp.Id, scsp.Name, scsp.CreatedDate, scsp.Status__c, wi.Id, wi.Name, wi.Work_Item_Date__c, wi.Status__c, wi.Primary_Standard__c, wi.Required_Duration__c, av.*, sc.Opportunity_Created_From__c, c.Opportunity_Created_From__c, scsp.Transferred_From__c
from salesforce.site_certification_standard_program__c scsp
inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
inner join salesforce.certification__c c on sc.Primary_Certification__c = c.Id
inner join salesforce.work_item__c wi on wi.Site_Certification_Standard__c = scsp.Id and wi.IsDeleted = 0 and wi.Status__c not in ('Cancelled') and wi.Work_Item_Date__c <= date_add(scsp.CreatedDate, interval 1 year)
left join salesforce.opportunity o on o.Id = c.Opportunity_Created_From__c
left join analytics.audit_values av on wi.Id = av.`Work Item Id`
where 
sc.Revenue_Ownership__c like 'AUS%'
and sc.Revenue_Ownership__c not like '%Product%'
and scsp.CreatedDate >= '2015-07-01'
and scsp.Transferred_From__c is null
#and o.Type like '%retention%'
);

truncate salesforce.opportunity;
update salesforce.sf_tables set LastSyncDate='1970-01-01' where TableNAme='opportunity' and Id=314