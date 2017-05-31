select 'adp' as 'source', r.Id, r.Name,  
#adp.Total/7 as 'Days', date_format(adp.From_Date, '%Y-%m-%d') as 'From', date_format(adp.To_Date, '%Y-%m-%d') as 'To', 
adp.Leave_Type, 
wd.date
#, ph.date
from adp.absentee_payroll adp
inner join salesforce.resource__c r on r.Name = concat(adp.First_Name, ' ', adp.Last_Name)
left join salesforce.sf_working_days wd on wd.date <= adp.To_Date and wd.date >= adp.From_Date
left join 
(select bop.Resource__c, bop.From_Date__c, bop.To_Date__c, wd.date 
from salesforce.blackout_period__c bop
left join salesforce.sf_working_days wd on wd.date <= date_format(date_add(bop.To_Date__c, interval 11 hour), '%Y-%m-%d') and wd.date >= date_format(date_add(bop.From_Date__c,interval 11 hour), '%Y-%m-%d')
where bop.Resource_Blackout_Type__c = 'Public Holiday' and bop.IsDeleted=0) ph on ph.Resource__c = r.Id and ph.date = wd.date
where 
r.Resource_Type__c = 'Employee'
#and r.Id='a0nd0000000hAmLAAU'
and r.Resource_Capacitiy__c > 30
and ph.date is null
union
select 'sf' as 'source', r.Id, r.Name, bop.Resource_Blackout_Type__c, wd.date from  blackout_period__c bop 
inner join resource__c r on bop.Resource__c = r.Id
left join salesforce.sf_working_days wd on wd.date <= date_format(date_add(bop.To_Date__c, interval 11 hour), '%Y-%m-%d') and wd.date >= date_format(date_add(bop.From_Date__c, interval 11 hour), '%Y-%m-%d')
where 
r.Resource_Type__c = 'Employee'
and bop.From_Date__c >= '2014-11-01' 
and bop.From_Date__c <= '2015-01-31' 
and bop.Resource_Blackout_Type__c like '%leave%'
and bop.isDeleted=0
and r.Resource_Capacitiy__c > 30
#and r.Id='a0nd0000000hAmLAAU'
and wd.date is not null;

select r.Id, r.Name from resource__c r where r.Name like 'Troy%';