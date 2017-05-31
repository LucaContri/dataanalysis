use training;

select c.Id, c.Name, c.Class_Status__c, c.Class_Begin_Date__c, date_format(c.Class_Begin_Date__c, '%Y-%m') as 'Period', date_format(c.Class_Begin_Date__c, '%Y') as 'Year', c.Class_End_Date__c, c.Number_of_Confirmed_Attendees__c 
from class__c c 
inner join course__c co on co.Id = c.Course_Name__c
where 
co.Exam_Required__c = 1
and c.Class_Status__c not in ('Cancelled')
and c.Number_of_Confirmed_Attendees__c >0
limit 100000;