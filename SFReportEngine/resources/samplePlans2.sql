
select sc.CreatedById , u.Name, sc.Id, sc.Name, sc.Client_Site__c ,count(scl.Id) 
from salesforce.certification__c sc 
left join salesforce.site_certification_lifecycle__c scl on scl.Site_Certification__c = sc.Id
left join salesforce.work_item__c wi on scl.Work_Item__c = wi.Id
left join salesforce.user u on sc.CreatedById = u.Id
where scl.Status__c='Active'
and sc.Mandatory_Site__c=false
and wi.Status__c not in ('Cancelled')
and sc.FSample_Site__c='<img src="/img/checkbox_checked.gif" alt=" " border="0"/>'
and sc.CreatedById not in ('00590000000HPi4AAG')
group by sc.Id
limit 1000000;