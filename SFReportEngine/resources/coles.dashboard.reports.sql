use salesforce;
create or replace view coles_dashboard_data_last_month_sub as
select a.Name as 'Account Name', c.AccountId, c.Id, c.Name, c.FirstName, c.LastName, date_format(min(r.Class_Begin_Date__c ), '%Y-%m') as 'First Registration Period'
from training.registration__c r
inner join training.contact c on r.Attendee__c = c.Id
inner join training.account a on c.AccountId = a.Id
where r.Status__c = 'Confirmed'
and (r.Course_Number__c like '%a%' or r.Course_Number__c like '%f%')
and r.Course_Number__c not in ('f32','f30')
and (r.Coles__c = 1 or r.Coles_Brand_Employee__c = 1)
and r.Class_Begin_Date__c >= '2012-07-01'
#and date_format(r.Class_Begin_Date__c, '%Y-%m') in (date_format(date_add(now(), interval -1 month), '%Y-%m'), date_format(now(), '%Y-%m'))
group by a.Name;

create or replace view coles_dashboard_data_last_month as 
# Supplier Company Engagement
(select t.`First Registration Period` as 'Period', 'Supplier Company Engagement' as 'Metric', count(t.`Account Name`) as 'Value' 
from coles_dashboard_data_last_month_sub t 
where t.`First Registration Period` in (date_format(date_add(now(), interval 1 month), '%Y-%m'), date_format(date_add(now(), interval -1 month), '%Y-%m'), date_format(now(), '%Y-%m'))
group by t.`First Registration Period`
order by t.`First Registration Period` desc limit 3)
union
# Supplier Company Subscriptions
(select date_format(r.Class_Begin_Date__c, '%Y-%m') as 'Period', 'Supplier Company Subscriptions' as 'Metric', count(distinct ba.Name) as 'Value'
from training.registration__c r
inner join training.course__c c on r.Course_Name__c = c.Id
inner join training.account ba on r.Billing_Account__c = ba.Id
where 
c.CQA_Connect__c = 1
and r.Status__c = 'Confirmed'
and date_format(r.Class_Begin_Date__c, '%Y-%m') in (date_format(date_add(now(), interval 1 month), '%Y-%m'), date_format(date_add(now(), interval -1 month), '%Y-%m'), date_format(now(), '%Y-%m'))
group by `Period`)
union
# User Engagement
(select date_format((r.Class_Begin_Date__c ), '%Y-%m') as 'Period', 
if(r.Coles_Brand_Employee__c = 1, 'Staff Engagement', 'Supplier Engagement') as 'Metric',
count(r.Id) as 'Value'
from training.registration__c r
where r.Status__c = 'Confirmed'
and (r.Course_Number__c like '%a%' or r.Course_Number__c like '%f%')
and r.Course_Number__c not in ('f32','f30')
and (r.Coles__c = 1 or r.Coles_Brand_Employee__c = 1)
and date_format(r.Class_Begin_Date__c, '%Y-%m') in (date_format(date_add(now(), interval 1 month), '%Y-%m'), date_format(date_add(now(), interval -1 month), '%Y-%m'), date_format(now(), '%Y-%m'))
group by `Period`, `Metric`);


select * from salesforce.coles_dashboard_data_last_month;

select r.Name, r.Reporting_Business_Units__c from salesforce.resource__c r 
where 
r.Name like '%Lee%'
r.Reporting_Business_Units__c like 'AUS-Product%';
