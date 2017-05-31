select c.Id
	, c.Name
	, c.CreatedDate
	, Month(c.CreatedDate) as 'CreateMonth'
	, Year(c.CreatedDate) as 'CreateYear'
	, date_format(c.CreatedDate, '%Y-%m') as 'CreatePeriod'
	, c.Class_Begin_Date__c
	, dayofweek(c.Class_Begin_Date__c) as 'BeginDayOfWeek'
	, Month(c.Class_Begin_Date__c) as 'BeginMonth'
	, Year(c.Class_Begin_Date__c) as 'BeginYear'
	, date_format(c.Class_Begin_Date__c, '%Y-%m') as 'BeginPeriod'
	, datediff(c.Class_Begin_Date__c, c.CreatedDate) as 'CreateToBeginDays'
	, c.Class_Location__c
	, v.Name as 'Venue'
	, c.Net_Price__c as 'Revenues'
	, c.Total_Estimated_Costs__c as 'EstimatedExpenses'
	, c.Class_Base_Price__c as 'ClassBasePrice'
	, t1.Name as 'Trainer1'
	, t2.Name as 'Trainer2'
	, c.Class_Status__c
	, if (c.Class_Status__c='Cancelled',0,1) as 'ClassRun'
	, c.Cancellation_Reason__c
	, c.Number_of_Confirmed_Attendees__c
from training.class__c c 
left join training.account v on v.Id=c.Venue__c
left join contact t1 on t1.Id = c.Trainer1__c
left join contact t2 on t2.Id = c.Trainer2__c
where c.Class_Location__c not in ('Online') 
and c.Class_Type__c='Public Class'
and c.Name not like '%DO NOT USE%'
and c.Class_Begin_Date__c<'2014-03-01'
order by c.Class_Begin_Date__c
limit 100000;

select datediff(now(), '2014-01-01' );