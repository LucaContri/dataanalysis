select 
wi.Revenue_Ownership__c as 'Business Unit'
, u.Name as 'User'
#, wi.Name as 'Work Item'
, concat(wih.OldValue, '-',wih.NewValue) as 'Change'
, date_format(wih.CreatedDate, '%Y %m') as 'Period'
, count(wih.Id)
from salesforce.work_item__history wih
inner join salesforce.work_item__c wi on wi.Id = wih.ParentId
inner join salesforce.user u on wih.CreatedById=u.Id
where wih.Field IN ('Status__c')
#where wih.Field IN ('Open_Sub_Status__c', 'Status__c')
#and wih.CreatedDate >= date_sub(now(),INTERVAL 3 DAY);
GROUP BY `Business Unit`, `User`, `Change`, `Period`
LIMIT 1000000