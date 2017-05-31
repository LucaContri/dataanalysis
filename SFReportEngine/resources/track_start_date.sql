
#select t3.Revenue_Ownership__c, t3.`Period From`, t3.`Period To`, avg(t3.Changes), avg(t3.Movement) from (
(select if(t2.Revenue_Ownership__c like '%Food%', 'Food', if(t2.Revenue_Ownership__c like '%Product%', 'PS', 'MS')) as 'Stream', if(t2.Revenue_Ownership__c like 'AUS%', 'Australia', if(t2.Revenue_Ownership__c like 'Asia%', substring_index(t2.Revenue_Ownership__c,'-',2),substring_index(t2.Revenue_Ownership__c,'-',-2))) as 'Region',  
t2.Revenue_Ownership__c, t2.Id, t2.Name, ifnull(t2.`From`, t2.`To`) as 'From', date_format(ifnull(t2.`From`, t2.`To`), '%Y %m') as 'Period From', substring_index(group_concat(t2.`To`), ',',-1) as 'To', date_format(substring_index(group_concat(t2.`To`), ',',-1), '%Y %m') as 'Period To',count(t2.id) as 'Changes', sum(ifnull(t2.`Movement`,0)) as 'Movement' from (
select t.*, date_format(t.`From`, '%Y %m') as 'Period From', date_format(t.`To`, '%Y %m') as 'Period To',datediff(t.`To`, t.`From`) as 'Movement' from (
select wih.CreatedDate, wi.Id, wi.Name, wi.Revenue_Ownership__c, wih.OldValue, str_to_date(replace(replace(wih.OldValue,'AEDT ',''), 'AEST ',''), '%a %b %d 00:00:00 %Y') as 'From', wih.NewValue, str_to_date(replace(replace(wih.NewValue,'AEDT ',''), 'AEST ',''), '%a %b %d 00:00:00 %Y') as 'To' 
from salesforce.work_item__history wih
inner join salesforce.work_item__c wi on wih.ParentId = wi.Id
where Field='Track_Start_Date__c'
#and wi.Revenue_Ownership__c like 'Asia%'
#and wi.Id='a3Id0000000IT7JEAW'
order by wi.Id, wih.CreatedDate) t) t2
group by t2.Id)
#) t3
#where t3.`Changes` > 1
#group by t3.Revenue_Ownership__c, t3.`Period From`, t3.`Period To`;