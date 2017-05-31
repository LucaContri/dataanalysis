select 
    c.Id,
    c.Name,
    c.Course_Number_Name__c,
    c.Class_Begin_Date__c,
    date_format(c.Class_Begin_Date__c, '%Y %m'),
    co.Category__c,
    c.Pathway__c,
    c.Class_Status__c,
    c.Total_Estimated_Costs__c,
    c.Total_Actual_Costs__c,
    c.Net_Price__c,
    r.Id,
    r.Name,
    r.Total_Amount_ex_GST__c
from
    training.class__c c
        left join
    training.course__c co ON c.Course_Name__c = co.Id
        left join
    training.registration__c r ON r.Class_Name__c = c.Id
limit 1000000;

select * from (
select 
    c.Id,
    c.Name,
    c.Course_Number_Name__c,
    c.Class_Begin_Date__c,
    c.Pathway__c,
    c.Class_Status__c,
    c.Total_Estimated_Costs__c,
    c.Total_Actual_Costs__c,
    c.Net_Price__c as 'Revenues',
	c.Number_of_Confirmed_Attendees__c,
    sum(ce.Actual_Amount_Ex_GST__c ) as 'Amount',
    sum(ce.Estimated_Amount_Ex_GST__c) as 'EstAmount'
from
    training.class__c c
        left join
    training.class_expense_tis__c ce ON ce.Class__c = c.Id
where c.Class_Begin_Date__c > '2013-01-01' and c.Class_Begin_Date__c < '2013-12-31' and c.Class_Status__c not in ('Cancelled')
and c.Number_of_Confirmed_Attendees__c>0 and c.Name not like '%DO NOT USE%'
group by c.Id 
) t where t.Revenues=0
limit 1000000;

select * from training.class_expense_tis__c;