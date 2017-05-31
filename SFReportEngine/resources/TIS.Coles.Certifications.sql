use training;

#AFS History
select * from (
select a.Id, a.Name, group_concat(afs.CourseConference__c) as 'courses'
from AFS_History__c afs
inner join contact a on afs.Contact__C = a.Id
where (
	concat(afs.X1_Competency_Status__c,afs.X2_Competency_Status__c,afs.X3_Competency_Status__c,afs.X4_Competency_Status__c,afs.X5_Competency_Status__c,afs.X6_Competency_Status__c,afs.X7_Competency_Status__c,afs.X8_Competency_Status__c,afs.X9_Competency_Status__c,afs.X10_Competency_Status__c,afs.X11_Competency_Status__c,afs.X12_Competency_Status__c) is null 
	or concat(afs.X1_Competency_Status__c,afs.X2_Competency_Status__c,afs.X3_Competency_Status__c,afs.X4_Competency_Status__c,afs.X5_Competency_Status__c,afs.X6_Competency_Status__c,afs.X7_Competency_Status__c,afs.X8_Competency_Status__c,afs.X9_Competency_Status__c,afs.X10_Competency_Status__c,afs.X11_Competency_Status__c,afs.X12_Competency_Status__c) not like '%Not%')
group by a.Id) t
where t.courses like '%Food Legislation & Labelling%'
and t.courses like '%Internal Food Safety Auditor%'
and t.courses like '%Pest Control Management for Food Processors%'
and t.courses like '%Conducting Investigations and Problem Solving%'
and (t.courses like '%Principles and Applications of HACCP%' or t.courses like '%Principles and Applications of HACCP for Produce%')
;

select afs.CourseConference__c  from AFS_History__c afs group by afs.CourseConference__c;

#Salesforce
select c.id, c.Name, c.Course_Number__c from course__c c group by c.id;

select t2.AttendeeId, t2.Name, t2.courses, t2.coursesName from(
select t.AttendeeId, t.Name, group_concat(t.Course_Number__c) as 'courses', group_concat(t.Course_Name_Formula__c) as 'coursesName' from (
select a.Id as 'AttendeeId', a.Name, r.Course_Number__c, r.Course_Name_Formula__c, 
sum(if(ass.Name like '%Attainment%', 1, 0)) as 'Exam',
sum(if(ass.Name like '%Attainment%' and ass.Assessment_Status__c = 'Competent', 1, 0)) as 'Exam passed',
sum(if((ass.Name like '%Attendance%' or ass.Name like '%Achievement%') and ass.Assessment_Status__c = 'Competent', 1, 0)) as 'Attended', ass.id
from contact a
inner join Registration__c r on r.Attendee__c = a.Id
left join Assessment__c ass on ass.Attendee_ID__c = r.Id
where r.Status__c in ('Confirmed')
and r.Course_Number__c in ('F42', 'F24', 'F41', 'F44', 'A1', 'A2', 'F31', 'F33', 'F34', 'F42NZ', 'F24NZ', 'F41NZ', 'F44NZ', 'A1NZ', 'A2NZ', 'F31NZ', 'F33NZ', 'F34NZ')
group by r.id) t 
where 
(t.Exam >= 1 and t.`Exam Passed`=1) or (t.Exam = 0 and t.Attended >= 1)
group by t.AttendeeId limit 100000) t2
where t2.courses like '%F42%'
and t2.courses like '%F24%'
and t2.courses like '%F41%'
and t2.courses like '%F44%'
and t2.courses like '%A1%'
and t2.courses like '%A2%'
and (t2.courses like '%F31%' or t2.courses like '%F33%' or t2.courses like '%F34%');


describe coles_plr ;
# AFS plus Assessment table
#select t.AttendeeId, t.Name, group_concat(t.coursesName) from (
(select null as 'AttendeeId', cplr.Full_Name as 'Name', cplr.Course as 'coursesName' from coles_plr cplr where cplr.Result = 'C') 
union
(select t.AttendeeId, t.Name, 
t.Course_Name_Formula__c as 'coursesName'
#group_concat(t.Course_Name_Formula__c) as 'coursesName' 
from (
select a.Id as 'AttendeeId', a.Name, r.Course_Number__c, r.Course_Name_Formula__c, 
sum(if(ass.Name like '%Attainment%', 1, 0)) as 'Exam',
sum(if(ass.Name like '%Attainment%' and ass.Assessment_Status__c = 'Competent', 1, 0)) as 'Exam passed',
sum(if((ass.Name like '%Attendance%' or ass.Name like '%Achievement%') and ass.Assessment_Status__c = 'Competent', 1, 0)) as 'Attended', ass.id
from contact a
inner join Registration__c r on r.Attendee__c = a.Id
left join Assessment__c ass on ass.Attendee_ID__c = r.Id
where r.Status__c in ('Confirmed')
and r.Course_Number__c in ('F42', 'F24', 'F41', 'F44', 'A1', 'A2', 'F31', 'F33', 'F34', 'F42NZ', 'F24NZ', 'F41NZ', 'F44NZ', 'A1NZ', 'A2NZ', 'F31NZ', 'F33NZ', 'F34NZ')
group by r.id) t 
where 
(t.Exam >= 1 and t.`Exam Passed`=1) or (t.Exam = 0 and t.Attended >= 1)
group by t.AttendeeId)
union (
select a.Id, a.Name, 
afs.CourseConference__c
#group_concat(afs.CourseConference__c) as 'courses'
from AFS_History__c afs
inner join contact a on afs.Contact__C = a.Id
where (
	concat(afs.X1_Competency_Status__c,afs.X2_Competency_Status__c,afs.X3_Competency_Status__c,afs.X4_Competency_Status__c,afs.X5_Competency_Status__c,afs.X6_Competency_Status__c,afs.X7_Competency_Status__c,afs.X8_Competency_Status__c,afs.X9_Competency_Status__c,afs.X10_Competency_Status__c,afs.X11_Competency_Status__c,afs.X12_Competency_Status__c) is null 
	or concat(afs.X1_Competency_Status__c,afs.X2_Competency_Status__c,afs.X3_Competency_Status__c,afs.X4_Competency_Status__c,afs.X5_Competency_Status__c,afs.X6_Competency_Status__c,afs.X7_Competency_Status__c,afs.X8_Competency_Status__c,afs.X9_Competency_Status__c,afs.X10_Competency_Status__c,afs.X11_Competency_Status__c,afs.X12_Competency_Status__c) not like '%Not%')
);#group by a.Id);# ) t
#group by t.AttendeeId limit 100000;

select a.Id, a.Name, group_concat(afs.CourseConference__c) as 'courses'
from AFS_History__c afs
inner join contact a on afs.Contact__C = a.Id
where (
	concat(afs.X1_Competency_Status__c,afs.X2_Competency_Status__c,afs.X3_Competency_Status__c,afs.X4_Competency_Status__c,afs.X5_Competency_Status__c,afs.X6_Competency_Status__c,afs.X7_Competency_Status__c,afs.X8_Competency_Status__c,afs.X9_Competency_Status__c,afs.X10_Competency_Status__c,afs.X11_Competency_Status__c,afs.X12_Competency_Status__c) is null 
	or concat(afs.X1_Competency_Status__c,afs.X2_Competency_Status__c,afs.X3_Competency_Status__c,afs.X4_Competency_Status__c,afs.X5_Competency_Status__c,afs.X6_Competency_Status__c,afs.X7_Competency_Status__c,afs.X8_Competency_Status__c,afs.X9_Competency_Status__c,afs.X10_Competency_Status__c,afs.X11_Competency_Status__c,afs.X12_Competency_Status__c) not like '%Not%')
and a.Id='0032000000wPuYQAA0'
group by a.Id;


select a.Id, a.Name, plr.Full_Name, plr.Course, afs.CourseConference__c 
from coles_plr plr 
left join contact a on plr.Full_Name = a.Name 
left join AFS_History__c afs on afs.Contact__C = a.Id and plr.Course = afs.CourseConference__c
group by plr.Full_Name;

drop table coles_plr;