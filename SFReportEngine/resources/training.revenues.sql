use training;
create index invoice_history_index on invoice_ent__history (ParentId);


# All PeopleSoft Records
select 
i.Name as 'Invoice Name',
i.Id as 'Invoice Id',
i.Original_Invoice__c as 'Original Invoice No',
i.Payment_Status__c as 'Invoice Status',
i.Total_Amount__c as 'Amount',
if (i.PSoft_Inv_Amt__c is null, 0, if(i.GST_Exempt__c, i.PSoft_Inv_Amt__c, i.PSoft_Inv_Amt__c/1.1)) as 'Calculated Amount',
i.Invoice_exGST_Amount__c as 'Amount Ex Tax',
i.Invoice_Type__c as 'Invoice Type',
i.Payment_Date__c as 'Invoice Payment Date',
date_format(i.Payment_Date__c, '%Y %m') as 'Payment Period', 
i.CreatedDate as 'Invoice Created Date',
date_format(i.CreatedDate, '%Y %m') as 'Invoice Created Period',
i.Processed__c,
i.Bill_Type__c as 'Invoice Bill Type',
i.From_Date__c as 'Invoice From Date',
date_format(i.From_Date__c, '%Y %m') as 'Invoice From Period',
i.To_Date__c as 'Invoice To Date',
r.Id as 'Registration Id',
r.CreatedDate as 'Registration Created Date',
date_format(r.CreatedDate, '%Y %m') as 'Registration Created Period',
r.Status__c as 'Registration Status',
r.Class_Begin_Date__c  as 'Class Begin Date',
r.Class_End_Date__c as 'Class End Date',
r.Course_Type__c as 'Course Type',
c.Name as 'Class Name',
a.Name as 'Billing Account'
from invoice_ent__c i 
INNER join registration__c r ON i.Registration__c = r.Id
left join account a on a.id = r.Billing_Account__c
left join class__C c on r.Class_Name__c = c.Id  
where 
r.IsDeleted=0
and r.NZ_AFS__c = 0
and r.Coles_Brand_Employee__c = 0
and r.Error__c = 0
and i.CreatedDate>='2014-01-01'
and i.CreatedDate<'2014-08-11'
and i.IsDeleted=0
and i.Total_Amount__c is not null
limit 100000;

# Public online revenues
select t.Date, sum(t.Amount) as 'Amount' from (
select 
date_format(date_add(max(ih.CreatedDate), INTERVAL 10 HOUR), '%Y-%m-%d') as 'Date', 
if(i.GST_Exempt__c, i.PSoft_Inv_Amt__c, i.PSoft_Inv_Amt__c/1.1) as 'Amount' 
from registration__c r 
inner join invoice_ent__c i ON i.Registration__c = r.Id 
inner join invoice_ent__history ih on ih.ParentId = i.id 
where 
r.Course_Type__c = 'eLearning' # Could it be something like i.Accounting like 'OL%' or i.Accounting like 'EL%'
and ih.Field='Processed__c' and ih.NewValue='true' 
and r.NZ_AFS__c = 0
and r.Coles_Brand_Employee__c = 0
and r.Error__c = 0
and r.Status__c not in ('Pending')
and i.Processed__c = 1
group by i.Id) t 
where t.Date >= '2014-08-01' 
and t.Date <= '2014-08-31' 
group by t.`Date` order by t.`Date`;

# Public (not online) revenues
select * from (
# IF Invoice Bill type = ADF => Recognise by invoiced processed date
(select t.`Date` as 'Class_Begin_Date__c', t.`Date` as 'Class_End_Date__c', sum(t.Amount) as 'Amount' from (
select
date_format(date_add(max(if(ih.Field='Processed__c' and ih.NewValue='true', ih.CreatedDate, i.CreatedDate)), INTERVAL 10 HOUR), '%Y-%m-%d') as 'Date',
#if(i.GST_Exempt__c, i.PSoft_Inv_Amt__c, i.PSoft_Inv_Amt__c/1.1) as 'Amount'
i.PSoft_Inv_Amt__c/1.1 as 'Amount' # ADF attracts GST regardless of the GST Exempt flag which refers to the course
from registration__c r 
inner join invoice_ent__c i ON i.Registration__c = r.Id 
left join invoice_ent__history ih on ih.ParentId = i.id 
where
(r.Course_Type__c not in ('eLearning') or i.Accounting__c is null) # Could it be something like i.Accounting not like 'OL%' or i.Accounting not like 'EL%'
#and ih.Field='Processed__c' and ih.NewValue='true'
and i.Bill_Type__c = 'ADF'
and r.NZ_AFS__c = 0
and r.Coles_Brand_Employee__c = 0
and r.Error__c = 0
and r.Status__c not in ('Pending')
and i.Processed__c = 1
and (i.Accounting__c not like ('PRC_HACCP%') or i.Accounting__c is null)
group by i.Id
) t 
where 
t.`Date`>= '2014-07-01'
and t.`Date`<= '2014-07-31'
and t.`Amount` is not null
group by t.`Date`
order by t.`Date`)
union
# If Invoice Bill type != ADF and Class Begin Date <= Invoice Processed Date => Recognise by Invoice Processed Date
(select t.`Date` as 'Class_Begin_Date__c', t.`Date` as 'Class_End_Date__c', sum(t.Amount) as 'Amount' from (
select
date_format(date_add(max(if(ih.Field='Processed__c' and ih.NewValue='true', ih.CreatedDate, i.CreatedDate)), INTERVAL 10 HOUR), '%Y-%m-%d') as 'Date',
if(i.From_Date__c is null, r.Class_Begin_Date__c, i.From_Date__c ) as 'Class_Begin_Date__c',
if(i.To_Date__c is null, r.Class_End_Date__c, i.To_Date__c) as 'Class_End_Date__c',     
if(i.GST_Exempt__c, i.PSoft_Inv_Amt__c, i.PSoft_Inv_Amt__c/1.1) as 'Amount' 
from registration__c r 
inner join invoice_ent__c i ON i.Registration__c = r.Id 
left join invoice_ent__history ih on ih.ParentId = i.id 
where
(r.Course_Type__c not in ('eLearning') or i.Accounting__c is null) # Could it be something like i.Accounting not like 'OL%' or i.Accounting not like 'EL%'
and i.Bill_Type__c not in ('ADF')
and r.NZ_AFS__c = 0
and r.Coles_Brand_Employee__c = 0
and r.Error__c = 0
and r.Status__c not in ('Pending')
and i.Processed__c = 1
and (i.Accounting__c not like ('PRC_HACCP%') or i.Accounting__c is null)
group by i.Id
) t 
where 
t.`Date`>= '2014-07-01'
and t.`Date`<= '2014-07-31'
and (t.`Date` >= t.Class_Begin_Date__c  # Could it be t.`Date` >= conact(date_format(t.Class_Begin_Date__c, '%Y-%m-'),'31')
	or t.Class_Begin_Date__c is null)
and t.`Amount` is not null
group by t.`Date`
order by t.`Date`
) union
# If Invoice Bill type != ADF and Class Begin Date > Invoice Processed Date => Recognise by Class Dates
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
(r.Course_Type__c not in ('eLearning') or i.Accounting__c is null) # Could it be something like i.Accounting not like 'OL%' or i.Accounting not like 'EL%'
and i.Bill_Type__c not in ('ADF')
and r.NZ_AFS__c = 0
and r.Coles_Brand_Employee__c = 0
and r.Error__c = 0
and r.Status__c not in ('Pending')
and i.Processed__c = 1
and (i.Accounting__c not like ('PRC_HACCP%') or i.Accounting__c is null)
group by i.Id
) t 
where 
t.`Date` < t.Class_Begin_Date__c #concat(date_format(t.Class_Begin_Date__c, '%Y-%m-'),'31')
and t.Class_Begin_Date__c <= '2014-07-31'
and t.Class_End_Date__c >= '2014-07-01'
and t.`Amount` is not null
group by t.Class_Begin_Date__c, t.Class_End_Date__c
order by t.Class_Begin_Date__c)) t2
order by t2.Class_Begin_Date__c;

# In House Revenues

select 
ihe.Id,
ihe.Name,
ihe.Invoice_Validating__c,
ihe.Invoicing_Complete__c, 
ihe.Total_Course_Base_Price__c,
if(ihe.Invoicing_Complete__c=1,ihe.Total_Amount_Invoiced__c, ihe.TOTAL_COURSE_TO_BE_INVOICED_ex_GST__c) as 'Amount', #Total Amount Invoiced or TOTAL COURSE TO BE INVOICED
c.Class_Begin_Date__c, 
c.Class_End_Date__c 
from In_House_Event__c ihe 
left join training.class__c c on ihe.Class__c = c.Id 
where 
ihe.Status__c not in ('Cancelled') 
and c.Class_Status__c not in ('Cancelled') 
and c.Class_End_Date__c >= '2014-07-01' 
and c.Class_Begin_Date__c <= '2014-07-31' 
and (c.Name not like '%Actual%' and c.Name not like '%Budget%') 
group by ihe.id
order by c.Class_Begin_Date__c
limit 1000000;

select 
group_concat(ihe.Name),
1 as 'Invoicing_Complete__c', 
sum(if(ihe.Invoicing_Complete__c=1,ihe.Total_Amount_Invoiced__c, ihe.TOTAL_COURSE_TO_BE_INVOICED_ex_GST__c)) as 'Amount', 
c.Class_Begin_Date__c, 
c.Class_End_Date__c 
from In_House_Event__c ihe 
left join training.class__c c on ihe.Class__c = c.Id 
where 
ihe.Status__c not in ('Cancelled','Postponed') 
and c.Class_Status__c not in ('Cancelled','Postponed') 
and c.Class_End_Date__c >= '2014-07-01' 
and c.Class_Begin_Date__c <= '2014-07-31' 
and (c.Name not like '%Actual%' and c.Name not like '%Budget%') 
group by ihe.Id
order by c.Class_Begin_Date__c

