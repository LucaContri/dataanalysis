# Audit Days in the system
(select 
if(wi.Revenue_Ownership__c like '%Food%', 'Food','MS') as 'Stream',
sc.Id,
sc.Name,
wi.Id,
wi.Name,
wi.Work_Item_Date__c,
date_format(wi.Work_Item_Date__c, '%Y-%m') as 'Period',
year(wi.Work_Item_Date__c) as 'Year',
month(wi.Work_Item_Date__c) as 'Month',
if(month(wi.Work_Item_Date__c)<7,concat(year(wi.Work_Item_Date__c)-1,'-', year(wi.Work_Item_Date__c)),concat(year(wi.Work_Item_Date__c),'-', year(wi.Work_Item_Date__c)+1)) as 'Financial Year',
wi.Status__c,
wi.Required_Duration__c,
wi.Required_Duration__c/8 as 'Days',
wi.Sample_Site__c,
wi.Revenue_Ownership__c,
wi.Work_Package_Type__c,
wi.Work_Item_Stage__c
from salesforce.work_item__c wi
inner join salesforce.work_package__c wp on wi.Work_Package__c = wp.Id
inner join salesforce.certification__c sc on wp.Site_Certification__c = sc.Id
where wi.IsDeleted = 0
and wi.Status__c not in ('Budget','Cancelled')
and wi.Revenue_Ownership__c like 'AUS%'
and wi.Revenue_Ownership__c not like '%Product%'
and wi.Work_Item_Date__c<'2017-07-01');

#New Business
select
date_format(o.CloseDate, '%Y-%m') as 'Period', sum(oli.Days__c) as 'Days', sum(oli.TotalPrice)
from salesforce.opportunity o
inner join salesforce.opportunitylineitem oli on oli.OpportunityId = o.Id and oli.IsDeleted = 0 and oli.Days__c>0 and oli.First_Year_Revenue__c=1
where 
o.Business_1__c = 'Australia'
and o.IsDeleted = 0
and o.CloseDate >= '2015-04-01'
and o.StageName = 'Closed Won'
and o.Status__c = 'Active'
and o.Type not like '%Retention%'
group by `Period`;


# Audit Days in the system
(select 
if(wi.Revenue_Ownership__c like '%Food%', 'Food','MS') as 'Stream',
wi.Client_Name_No_Hyperlink__c,
c.Id,
c.Name,
sc.Id,
sc.Name,
 scsp.Status__c, scsp.De_registered_Type__c, scsp.Site_Certification_Status_Reason__c, scsp.Site_Originally_Registered__c,
wi.Id,
wi.Name,
wi.Work_Item_Date__c,
date_format(wi.Work_Item_Date__c, '%Y-%m') as 'Period',
year(wi.Work_Item_Date__c) as 'Year',
month(wi.Work_Item_Date__c) as 'Month',
if(month(wi.Work_Item_Date__c)<7,concat(year(wi.Work_Item_Date__c)-1,'-', year(wi.Work_Item_Date__c)),concat(year(wi.Work_Item_Date__c),'-', year(wi.Work_Item_Date__c)+1)) as 'Financial Year',
wi.Status__c,
wi.Required_Duration__c,
wi.Required_Duration__c/8 as 'Days',
wi.Sample_Site__c,
wi.Revenue_Ownership__c,
wi.Work_Package_Type__c,
wi.Work_Item_Stage__c,
sc.Sample_Service__c
from salesforce.work_item__c wi
inner join salesforce.work_package__c wp on wi.Work_Package__c = wp.Id
inner join salesforce.certification__c sc on wp.Site_Certification__c = sc.Id
inner join salesforce.site_certification_standard_program__c scsp on scsp.Site_Certification__c = sc.Id
inner join salesforce.certification__c c on sc.Primary_Certification__c = c.Id
where wi.IsDeleted = 0
and wi.Status__c not in ('Budget','Cancelled')
and wi.Revenue_Ownership__c like 'AUS%'
and wi.Revenue_Ownership__c not like '%Product%'
and wi.Work_Item_Date__c<'2017-07-01'
#and wi.Sample_Site__c='Yes'
and c.Sample_Service__c=1);
