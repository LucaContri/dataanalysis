use training;

select * from (
(select t.`Date` as 'Class_Begin_Date__c', t.`Date` as 'Class_End_Date__c', sum(t.Amount) as 'Amount' from (
select 
date_format(date_add(max(if(ih.Field='Processed__c' and ih.NewValue='true', ih.CreatedDate, i.CreatedDate)), INTERVAL 10 HOUR), '%Y-%m-%d') as 'Date', 
i.PSoft_Inv_Amt__c/1.1 as 'Amount' 
from registration__c r 
inner join invoice_ent__c i ON i.Registration__c = r.Id 
left join invoice_ent__history ih on ih.ParentId = i.id 
where 
(r.Course_Type__c not in ('eLearning') or i.Accounting__c is null) 
and i.Bill_Type__c = 'ADF' 
and r.NZ_AFS__c = 0 
and r.Coles_Brand_Employee__c = 0 
and r.Error__c = 0 
and r.Status__c not in ('Pending') 
and i.Processed__c = 1 
and (i.Accounting__c not like ('PRC_HACCP%') or i.Accounting__c is null) 
group by i.Id) t 
where 
t.`Date`>= '2015-01-01' 
and t.`Date`<= '2015-02-28' 
and t.`Amount` is not null 
group by t.`Date` 
order by t.`Date`) 
union (select t.`Date` as 'Class_Begin_Date__c', t.`Date` as 'Class_End_Date__c', sum(t.Amount) as 'Amount' from ( 
select 
date_format(date_add(max(if(ih.Field='Processed__c' and ih.NewValue='true', ih.CreatedDate, i.CreatedDate)), INTERVAL 10 HOUR), '%Y-%m-%d') as 'Date', 
if(i.From_Date__c is null, r.Class_Begin_Date__c, i.From_Date__c ) as 'Class_Begin_Date__c', 
if(i.To_Date__c is null, r.Class_End_Date__c, i.To_Date__c) as 'Class_End_Date__c', 
if(i.GST_Exempt__c, i.PSoft_Inv_Amt__c, i.PSoft_Inv_Amt__c/1.1) as 'Amount' 
from registration__c r 
inner join invoice_ent__c i ON i.Registration__c = r.Id 
left join invoice_ent__history ih on ih.ParentId = i.id 
where 
(r.Course_Type__c not in ('eLearning') or i.Accounting__c is null) 
and i.Bill_Type__c not in ('ADF') 
and r.NZ_AFS__c = 0 
and r.Coles_Brand_Employee__c = 0 
and r.Error__c = 0 
and r.Status__c not in ('Pending') 
and i.Processed__c = 1 
and (i.Accounting__c not like ('PRC_HACCP%') or i.Accounting__c is null) 
group by i.Id) t 
where 
t.`Date`>= '2015-01-01' 
and t.`Date`<= '2015-02-28' 
and (t.`Date` >= t.Class_Begin_Date__c or t.Class_Begin_Date__c is null) 
and t.`Amount` is not null 
group by t.`Date` 
order by t.`Date`
) union 
(select t.Class_Begin_Date__c, t.Class_End_Date__c, sum(t.Amount) as 'Amount' from ( 
select 
date_format(date_add(max(if(ih.Field='Processed__c' and ih.NewValue='true', ih.CreatedDate, i.CreatedDate)), INTERVAL 10 HOUR), '%Y-%m-%d') as 'Date', 
if(i.From_Date__c is null, r.Class_Begin_Date__c, i.From_Date__c ) as 'Class_Begin_Date__c', 
if(i.To_Date__c is null, r.Class_End_Date__c, i.To_Date__c) as 'Class_End_Date__c', 
if(i.GST_Exempt__c, i.PSoft_Inv_Amt__c, i.PSoft_Inv_Amt__c/1.1) as 'Amount' 
from registration__c r 
inner join invoice_ent__c i ON i.Registration__c = r.Id 
left join invoice_ent__history ih on ih.ParentId = i.id 
where 
(r.Course_Type__c not in ('eLearning') or i.Accounting__c is null) 
and i.Bill_Type__c not in ('ADF') 
and r.NZ_AFS__c = 0 
and r.Coles_Brand_Employee__c = 0 
and r.Error__c = 0 
and r.Status__c not in ('Pending') 
and i.Processed__c = 1 
and (i.Accounting__c not like ('PRC_HACCP%') or i.Accounting__c is null) 
group by i.Id) t 
where 
t.`Date` < t.Class_Begin_Date__c 
and t.Class_Begin_Date__c <= '2015-02-28' 
and t.Class_End_Date__c >= '2015-01-01' 
and t.`Amount` is not null 
group by t.Class_Begin_Date__c, t.Class_End_Date__c 
order by t.Class_Begin_Date__c)) t2 
order by t2.Class_Begin_Date__c;

#In House
select 
1 as 'Invoicing_Complete__c', 
sum(if(ihe.Invoicing_Complete__c=1,ihe.Total_Amount_Invoiced__c, ihe.TOTAL_COURSE_TO_BE_INVOICED_ex_GST__c)) as 'Amount', 
date_format(date_add(c.Class_Begin_Date__c, interval 11 hour),'%Y-%m-%d') as 'Class_Begin_Date__c', 
date_format(date_add(c.Class_End_Date__c, interval 11 hour),'%Y-%m-%d') as 'Class_End_Date__c' 
from In_House_Event__c ihe 
left join training.class__c c on ihe.Class__c = c.Id 
where 
ihe.Status__c not in ('Cancelled','Postponed') 
and c.Class_Status__c not in ('Cancelled','Postponed') 
and date_format(date_add(c.Class_End_Date__c, interval 11 hour),'%Y-%m-%d') >= '2015-01-01' 
and date_format(date_add(c.Class_Begin_Date__c, interval 11 hour),'%Y-%m-%d') <= '2015-02-28' 
and (c.Name not like '%Actual%' and c.Name not like '%Budget%') 
group by ihe.id 
order by c.Class_Begin_Date__c;