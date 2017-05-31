select t.* from (
select
wi.Id, 
wi.Name as 'Work Item', 
wi.Status__c as 'Status', 
wi.work_Item_Stage__c as 'Type',
wi.Work_Item_Date__c as 'Sched. Date',
wi.Required_Duration__c as 'Duration',
wi.Cancellation_Reason__c as 'Canc. Reason',
wi.Service_Change_Reason__c,
max(if (wih.Field='Status__c' and wih.NewValue='Cancelled', wih.CreatedDate, null)) as 'Canc. Date',
max(if (wih.Field='Status__c' and wih.NewValue='Cancelled', cb.Name, null)) as 'Canc. By'
from work_item__c wi
inner join work_item__history wih on wih.ParentId = wi.Id
inner join User cb on wih.CreatedById = cb.Id
where wi.Status__c = 'Cancelled'
and (wi.Revenue_Ownership__c LIKE 'AUS-Food%' OR wi.Revenue_Ownership__c LIKE 'AUS-Global%' OR wi.Revenue_Ownership__c LIKE 'AUS-Managed%' OR wi.Revenue_Ownership__c LIKE 'AUS-Direct%')
group by wi.Id) t 
where date_format(date_add(t.`Canc. Date`, interval 11 hour), '%Y-%m-%d')='2014-12-15';

select wi.Id, wi.Work_Package__c from work_item__c wi where wi.Name='AU-289189';

select * from site_certification_lifecycle__c scl where scl.Work_Item__c='a3Id00000005aIREAY';

select * from site_certification_lifecycle__history sclh where sclh.ParentId = 'a2zd00000004vZcAAI'
