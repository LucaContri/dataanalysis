#Online
(select 
'Registrations-Online' as 'source',
date_format( r.CreatedDate, '%d/%m/%Y')  as 'date',
date_format( r.CreatedDate, '%Y %m') as 'period',
count(r.Id) as 'registration#',
sum(r.Total_Amount_ex_GST__c) as 'amount'
#,sum(r.Total_Amount__c) as 'Total_Amount__c'
#,sum(r.SubTotal_Amount__c) as 'SubTotal_Amount__c'
 from training.registration__c r
inner join training.class__c c on r.Class_Name__c = c.Id 
where r.Status__c='Confirmed' and r.IsDeleted=0 and r.Class_Type__c in ('Public Class', 'Generic Class')
#and c.In_house_Use__c not in ('Yes')
and r.Assessment_Type__c in ('Face to Face','Upgrade Kit','Credit Transfer','Self Paced,RPL','eLearning')
#and r.Confirmed_Report_Filter__c = 'TRUE'
and c.Class_Status__c not in ('Cancelled')
and r.Class_Begin_Date__c>= '2013-07-01' 
and r.Class_Begin_Date__c<= '2014-06-30'   
#and c.Class_Location__c not in ('Online')
and (r.Course_Number__c like '%OL%' or r.Course_Number__c like '%L%' or r.Course_Number__c like '%UGIAT%')
and (c.Name not like 'FY Actual%' and c.Name not like 'Budget%')
group by `source`, `date`)
union (
select 
'Registrations-Online-Budget' as 'source', 
r.Class_Begin_Date__c as 'date',  
date_format(r.Class_Begin_Date__c, '%Y %m') as 'period', 
1 as 'registration#',
r.Budget__c as 'amount' 
from training.registration__c r 
inner join training.course__c c on r.Course_Name__c = c.Id
inner join training.class__c class on class.Id = r.Class_Name__c
where c.Name in ('Budget - Public Training and Regional Roadshows - DO NOT USE') 
and class.Name in('Budget - Online Public - 2013/14 - DO NOT USE')
);

#Public
(select 'Registrations-Public' as 'source',
c.Class_Begin_Date__c as 'begin_date',
c.Class_End_Date__c as 'end_date',
date_format( c.Class_Begin_Date__c, '%Y %m') as 'start_period', 
sum(r.Total_Amount_ex_GST__c) as 'amount'
from training.registration__c r
inner join training.class__c c on r.Class_Name__c = c.Id 
where r.Status__c='Confirmed' and r.IsDeleted=0 and r.Class_Type__c in ('Public Class', 'Generic Class')
and c.In_house_Use__c not in ('Yes')
and r.Assessment_Type__c in ('Face to Face','Upgrade Kit','Credit Transfer','Self Paced,RPL','eLearning')
and r.Confirmed_Report_Filter__c = 'TRUE'
and c.Class_Status__c not in ('Cancelled')
and r.Class_End_Date__c>= '2013-07-01' 
and r.Class_Begin_Date__c<= '2014-06-30'   
and c.Class_Location__c not in ('Online')
and (c.Name not like 'FY Actuals%' and c.Name not like 'Budget%')  
group by `source`, c.Id)
UNION
(select 'Registrations-Public-Budget' as 'source', r.Class_Begin_Date__c as 'start_date', r.Class_End_Date__c as 'end_date', date_format(r.Class_Begin_Date__c, "%Y %m") as 'start_period', r.Budget__c as 'amount' from training.registration__c r 
inner join training.course__c c on r.Course_Name__c = c.Id
inner join training.class__c class on class.Id = r.Class_Name__c
where c.Name in ('Budget - Public Training and Regional Roadshows - DO NOT USE') 
and class.Name in('Budget - Management Systems  - 2013/14 - DO NOT USE'));

select c.Name from training.course__c c where c.Name like 'Bud%';

select 'Registrations-Public-Budget' as 'source', r.Class_Begin_Date__c as 'date', date_format(r.Class_Begin_Date__c, "%Y %m") as 'period', sum(r.Budget__c) as 'amount' from training.registration__c r 
inner join training.course__c c on r.Course_Name__c = c.Id
inner join training.class__c class on class.Id = r.Class_Name__c
where c.Name in ('Budget - Public Training and Regional Roadshows - DO NOT USE')
group by `period`; 


#In-house Events
(select 'Registrations-In-house' as 'source',
c.Class_Begin_Date__c as 'begin_date',
c.Class_End_Date__c as 'end_date',
date_format( c.Class_Begin_Date__c, '%Y %m') as 'start_period', 
sum(ihe.TOTAL_COURSE_TO_BE_INVOICED_ex_GST__c) as 'TOTAL_COURSE_TO_BE_INVOICED_ex_GST__c',
sum(ihe.Total_Amount_Invoiced__c) as 'Total_Amount_Invoiced__c'
from training.In_House_Event__c ihe
left join training.class__c c on ihe.Class__c = c.Id 
where
c.Class_Type__c in ('In House Class')
and ihe.Status__c not in ('Cancelled')
and c.Class_Status__c not in ('Cancelled')
and c.Class_End_Date__c>= '2013-07-01' 
and c.Class_Begin_Date__c<= '2014-06-30'   
and (c.Name not like 'FY Actuals%' and c.Name not like 'Budget%')  
and ihe.Invoicing_Complete__c=1
group by `source`, c.Id)
UNION 
(select 'Registrations-In-house-Budget' as 'source',
	ihe.Event_Date__c as 'begin_date',
	ihe.Event_Date__c as 'end_date',
	date_format(ihe.Event_Date__c, '%Y %m') as 'start_period',
	ihe.Budget__c as 'amount 1',
	ihe.Budget__c as 'amount 2'
from training.In_House_Event__c ihe
where ihe.Opportunity__c = '0062000000UEdIyAAL' #EOI-SAI Global-CDS - Budget -2013/14 - DO NOT USE
and ihe.Type_of_Budget__c is null
);

select ihe.Event_Date__c, 
c.Class_Begin_Date__c,
c.Class_End_Date__c,
ihe.IH_Event_Type__c, ihe.Type_of_Budget__c, ihe.Budget__c
from training.In_House_Event__c ihe
left join training.class__c c on ihe.Class__c = c.Id
where ihe.Opportunity__c = '0062000000UEdIyAAL'
and ihe.Type_of_Budget__c is null;



update training.sf_tables set ToSync=0 where Id=172;

select * from training.budgetopportunities;