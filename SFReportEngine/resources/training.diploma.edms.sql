use training;

select c.id, c.Name, c.Course_Number__c from course__c c where c.Name like 'Incident Investigation%';
select c.id, c.Name, c.Course_Number__c from course__c c where c.Course_Number__c like '%H3.1%';
#Lead Auditor in WHS Management Systems	H5.2
#Lead Auditor in Quality Management Systems	Q5
#Lead Auditor in Environmental Management Systems	E4
#Integrated Governance, Risk Management and Compliance	R49
#Management Systems Leadership	P15
#WHS Risk Management	H3.1
#Implementing a WHS Management System	H4.2
#Incident Investigation and Due Diligence	H10.2

#BSB51607 Diploma of Quality Auditing: Work Health & Safety Management Systems
select t.AttendeeId, t.Name, t.Email, t.Courses,
if(t.Courses like '%H5.2%' 
	and t.Courses like '%R49%' 
    and (t.Courses not like '%P15%' and t.Courses not like '%H3.1%'), 1,0 ) as 'Missing Only Management Systems Leadership or WHS Risk Management',
if(t.Courses like '%H5.2%' 
	and t.Courses not like '%R49%' 
    and (t.Courses like '%P15%' or t.Courses like '%H3.1%'), 1,0 ) as 'Missing Only Integrated Governance, Risk Management & Compliance',
if(t.Courses not like '%H5.2%' 
	and t.Courses like '%R49%' 
    and (t.Courses like '%P15%' or t.Courses like '%H3.1%'), 1,0 ) as 'Missing Only Lead Auditor in WHS Management Systems'
from (
select a.Id as 'AttendeeId', a.Name, a.Email, group_concat(distinct r.Course_Number__c order by r.Course_Number__c) as 'Courses'#, group_concat(r.Course_Name_Formula__c)#, ass.id, count(distinct r.Id), count(distinct ass.Id)
from contact a
inner join Registration__c r on r.Attendee__c = a.Id
inner join Assessment__c ass on ass.Attendee_ID__c = r.Id
where 
#r.Status__c in ('Confirmed') and 
ass.Name = 'Statement of Attainment'
and ass.Assessment_Status__c = 'Competent'
and r.Course_Number__c in ('H5.2','R49', 'P15','H3.1')
#and a.Id='0032000000bfTtlAAE'
group by a.id) t limit 100000;

#BSB51607 Diploma of Quality Auditing: Quality Management Systems
select t.AttendeeId, t.Name, t.Email, t.Courses,
if(t.Courses like '%Q5%' 
	and t.Courses like '%R49%' 
    and (t.Courses not like '%P15%' and t.Courses not like '%H3.1%'), 1,0 ) as 'Missing Only Management Systems Leadership or WHS Risk Management',
if(t.Courses like '%Q5%' 
	and t.Courses not like '%R49%' 
    and (t.Courses like '%P15%' or t.Courses like '%H3.1%'), 1,0 ) as 'Missing Only Integrated Governance, Risk Management & Compliance',
if(t.Courses not like '%Q5%' 
	and t.Courses like '%R49%' 
    and (t.Courses like '%P15%' or t.Courses like '%H3.1%'), 1,0 ) as 'Missing Only Lead Auditor in Quality Management Systems'
from (
select a.Id as 'AttendeeId', a.Name, a.Email, group_concat(distinct r.Course_Number__c order by r.Course_Number__c) as 'Courses'#, group_concat(r.Course_Name_Formula__c)#, ass.id, count(distinct r.Id), count(distinct ass.Id)
from contact a
inner join Registration__c r on r.Attendee__c = a.Id
inner join Assessment__c ass on ass.Attendee_ID__c = r.Id
where 
#r.Status__c in ('Confirmed') and 
ass.Name = 'Statement of Attainment'
and ass.Assessment_Status__c = 'Competent'
and r.Course_Number__c in ('Q5','R49', 'P15','H3.1')
group by a.id) t limit 100000;

# BSB51607 Diploma of Quality Auditing: Environmental Management Systems
select t.AttendeeId, t.Name, t.Email, t.Courses,
if(t.Courses like '%E4%' 
	and t.Courses like '%R49%' 
    and (t.Courses not like '%P15%' and t.Courses not like '%H3.1%'), 1,0 ) as 'Missing Only Management Systems Leadership or WHS Risk Management',
if(t.Courses like '%E4%' 
	and t.Courses not like '%R49%' 
    and (t.Courses like '%P15%' or t.Courses like '%H3.1%'), 1,0 ) as 'Missing Only Integrated Governance, Risk Management & Compliance',
if(t.Courses not like '%E4%' 
	and t.Courses like '%R49%' 
    and (t.Courses like '%P15%' or t.Courses like '%H3.1%'), 1,0 ) as 'Missing Only Lead Auditor in Environmental Management Systems'
from (
select a.Id as 'AttendeeId', a.Name, a.Email, group_concat(distinct r.Course_Number__c order by r.Course_Number__c) as 'Courses'#, group_concat(r.Course_Name_Formula__c)#, ass.id, count(distinct r.Id), count(distinct ass.Id)
from contact a
inner join Registration__c r on r.Attendee__c = a.Id
inner join Assessment__c ass on ass.Attendee_ID__c = r.Id
where 
ass.Name = 'Statement of Attainment'
and ass.Assessment_Status__c = 'Competent'
and r.Course_Number__c in ('E4','R49', 'P15','H3.1')
group by a.id) t limit 100000;

# BSB51312 Diploma of Work Health and Safety
select t.AttendeeId, t.Name, t.Email, t.Courses,
if(t.Courses like '%H3.1%' 
	and t.Courses like '%H4.2%' 
    and t.Courses not like '%H10.2%', 1,0 ) as 'Missing Only Incident Investigation and Due Diligence',
if(t.Courses like '%H3.1%' 
	and t.Courses not like '%H4.2%' 
    and t.Courses like '%H10.2%', 1,0 ) as 'Missing Only Implementing a WHS Management System',
if(t.Courses not like '%H3.1%' 
	and t.Courses like '%H4.2%' 
    and t.Courses like '%H10.2%', 1,0 ) as 'Missing Only WHS Risk Management'
from (
select a.Id as 'AttendeeId', a.Name, a.Email, group_concat(distinct r.Course_Number__c order by r.Course_Number__c) as 'Courses'#, group_concat(r.Course_Name_Formula__c)#, ass.id, count(distinct r.Id), count(distinct ass.Id)
from contact a
inner join Registration__c r on r.Attendee__c = a.Id
inner join Assessment__c ass on ass.Attendee_ID__c = r.Id
where 
#r.Status__c in ('Confirmed') and 
ass.Name = 'Statement of Attainment'
and ass.Assessment_Status__c = 'Competent'
and r.Course_Number__c in ('H3.1','H4.2','H10.2')
group by a.id) t;