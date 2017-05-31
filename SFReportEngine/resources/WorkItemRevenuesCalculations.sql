select * from (
select
t.Operational_Ownership__c as 'BusinessUnit',  
t.SiteCertification,
t.Period,
t.WorkItemId as 'WorkItemId',
t.WorkItemName as 'WorkItem',
t.Service_target_date__c as 'TargetDate',
t.RequiredDays,
t.WorkItemStatus,
t.Work_Item_Stage__c as 'Reason',
t.Work_Package_Type__c as 'WorkPackageType',
t.SampleSite,
#p.Standard__c, 
#p.Category__c, 
#p.Product_Type__c, 
p.Id as 'ProductId',
p.Name as 'ProductName', 
#p.Audit_Days__c, 
p.UOM__c as 'Unit',
if (p.UOM__c='DAY',t.Days,if(p.UOM__c='HFD', t.HalfDays, t.Hours)) as 'Quantity',
#t.Site_Certification__c, p.Id, 
pbe.UnitPrice as 'ListPrice', 
if (cep.New_Price__c is null, pbe.UnitPrice, cep.New_Price__c) as 'EffectivePrice'
#cp.Product_List_Price__c, 
#cep.New_Start_Date__c, 
#cep.New_End_Date__c
from product2 p
inner join (select 
floor(wi.Required_Duration__c/8) as 'Days' , 
floor((wi.Required_Duration__c - 8*floor(wi.Required_Duration__c/8))/4) as 'HalfDays',
(wi.Required_Duration__c - 8*floor(wi.Required_Duration__c/8) - 4*floor((wi.Required_Duration__c - 8*floor(wi.Required_Duration__c/8))/4)) as 'Hours',
wi.Primary_Standard__c, s.Id, sp.Name, sp.Id as 'StandardId' , wp.Site_Certification__c , wi.Work_Item_Date__c, wi.Id as 'WorkItemId', wi.Name as 'WorkItemName',
c.Operational_Ownership__c, 
c.Name as "SiteCertification",
DATE_FORMAT(wi.Work_Item_Date__c, '%Y %m') AS 'Period',
wi.Service_target_date__c,
wi.Work_Item_Stage__c,
wi.Work_Package_Type__c,
wi.Required_Duration__c / 8 AS 'RequiredDays',
wi.Status__c as 'WorkItemStatus',
if (c.FSample_Site__c like '%checkbox_checked%', true, false) as 'SampleSite'
from salesforce.work_item__c wi 
inner join salesforce.standard__c s on s.Name = wi.Primary_Standard__c
inner join salesforce.standard__c sp on sp.Id = s.Parent_Standard__c
inner join salesforce.work_package__c wp on wp.Id = wi.Work_Package__c
INNER JOIN recordtype rt ON wi.RecordTypeId = rt.Id
INNER JOIN certification__c c ON c.Id = wp.Site_Certification__c
#where wi.Id='a3Id00000005B6FEAU'
where 
	wi.Work_Item_Date__c>='2015-02-01' 
	and wi.Work_Item_Date__c<='2015-02-28'
	and rt.Name = 'Audit'
	AND c.Operational_Ownership__c IN ('AUS - Management Systems' , 'AUS - Food', 'AUS - Product Services')
	#AND wi.Work_Package_Type__c != 'Initial'
	AND c.Status__c = 'Active'
	AND wi.Status__c NOT IN ( 'Cancelled')
) t on t.Work_Item_Stage__c = p.Product_Type__c and t.StandardId = p.Standard__c
inner join salesforce.pricebookentry pbe on pbe.Product2Id = p.Id
left join salesforce.certification_pricing__c cp on cp.Product__c = p.Id and cp.Certification__c=t.Site_Certification__c
left join salesforce.certification_effective_price__c cep on cp.Id = cep.Certification_Pricing__c
Where p.Category__c = 'Audit'
and pbe.Pricebook2Id='01s90000000568BAAQ'
and (cp.Status__c ='Active' or cp.Status__c is null)
and (if (cep.New_Start_Date__c is not null,cep.New_Start_Date__c<=t.Work_Item_Date__c,1))
and (if (cep.New_End_Date__c is not null,cep.New_End_Date__c>=t.Work_Item_Date__c,1))
and if (p.UOM__c='DAY',t.Days,if(p.UOM__c='HFD', t.HalfDays, t.Hours))>0
order by `WorkItemId`, `ProductId`, cep.LastModifiedDate desc
) t2
group by `WorkItemId`, `ProductId`
limit 1000000;

select Name, Id,  FSample_Site__c, Sample_Service__c, Primary_Certification__c 
from certification__c 
where Primary_Certification__c is not null
and FSample_Site__c like '%checkbox_checked%';