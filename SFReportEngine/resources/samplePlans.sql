explain
select c.Id, c.Name, c.Primary_client__c, c.Sample_Service__c, 
count(distinct wi.Id) as 'Work Items #', 
count(distinct sc.Id) as 'Site Cert. #', 
if (count(wi.Id)<count(distinct sc.Id), 1, 0) as 'Sample Service'
from salesforce.certification__c sc
left join salesforce.work_package__c wp on wp.Site_Certification__c = sc.Id
left join salesforce.work_item__c wi on wi.Work_Package__c = wp.Id
inner join salesforce.certification__c c on sc.Primary_Certification__c = c.Id
where (sc.Revenue_Ownership__c like 'AUS-Manage%' or sc.Revenue_Ownership__c like 'AUS-Direct%')
and (date_format(wi.Work_Item_Date__c, '%Y') = '2013' or wi.Id is null)
group by c.Id, c.Name, c.Primary_client__c, c.Sample_Service__c
limit 10;

select a.Name as 'Client', c.Id as 'Certification Id', c.Name as 'Certification Name', c.Sample_Service__c as 'Sample Service', 
count(sc.Id) as 'SiteCertNo', 
sum(if (cwi.WorkItemNo is null, 0,cwi.WorkItemNo)) as 'WorkItemNo',
if (sum(if (cwi.WorkItemNo is null, 0,cwi.WorkItemNo))<count(sc.Id),1,0) as 'Sample Service Guess'
from salesforce.certification__c sc
inner join salesforce.certification__c c on sc.Primary_Certification__c = c.Id
inner join salesforce.account a on c.Primary_client__c = a.Id
left join
(select sc.Id, count(wi.Id) as 'WorkItemNo' 
from salesforce.certification__c sc
inner join salesforce.work_package__c wp on wp.Site_Certification__c = sc.Id
inner join salesforce.work_item__c wi on wi.Work_Package__c = wp.Id
where (sc.Revenue_Ownership__c like 'AUS-Manage%' or sc.Revenue_Ownership__c like 'AUS-Direct%')
and date_format(wi.Work_Item_Date__c, '%Y') = '2013' 
and wi.Status__c not in ('Cancelled')
and wi.Work_Item_Stage__c not in ('Follow Up')
and sc.Status__c='Active'
group by sc.Id) cwi on sc.Id = cwi.Id
where sc.Status__c='Active'
and (sc.Revenue_Ownership__c like 'AUS-Manage%' or sc.Revenue_Ownership__c like 'AUS-Direct%')
group by c.Id
limit 100000;



select c.Id, c.Name, c.Primary_client__c, c.Sample_Service__c, 
sc.Id, sc.Name, wi.Id, wi.Name 
from salesforce.work_item__c wi
inner join salesforce.work_package__c wp on wi.Work_Package__c = wp.Id
inner join salesforce.certification__c sc on wp.Site_Certification__c = sc.Id
inner join salesforce.certification__c c on sc.Primary_Certification__c = c.Id
where (sc.Revenue_Ownership__c like 'AUS-Manage%' or sc.Revenue_Ownership__c like 'AUS-Direct%')
and date_format(wi.Work_Item_Date__c, '%Y') = '2013'
and c.Id='a1kd00000009CqLAAU'
limit 1000000;

select wi.Primary_Certification__c from salesforce.work_item__c wi;