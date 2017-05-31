use training;

select c.id, c.Name, c.Course_Number__c from course__c c where c.Course_Number__c in ('H3.1','H4.2',
	'H5.2','H15.2',
	'H7','R49','P14','R47') group by c.id;

select t.AttendeeId, t.Name, t.Email, t.Courses,
#if(t.Courses like '%H3.1%' and t.Courses like '%H4.2%' 
#	and (t.Courses like '%H5.2%' or t.Courses like '%H15.2%' ) 
#	and (t.Courses like '%H7%' or t.Courses like '%R49%' or t.Courses like '%P14%' or t.Courses like '%R47%'), 1,0 ) as 'AdvancedDiplomaWHS',
if(t.Courses like '%H3.1%' and t.Courses like '%H4.2%' 
	and (t.Courses like '%H5.2%' or t.Courses like '%H15.2%' ) 
	and (t.Courses not like '%H7%' and t.Courses not like '%R49%' and t.Courses not like '%P14%' and t.Courses not like '%R47%'), 1,0 ) as 'Missing Only Group 2 Electives',
if(t.Courses like '%H3.1%' and t.Courses like '%H4.2%' 
	and (t.Courses not like '%H5.2%' and t.Courses not like '%H15.2%' ) 
	and (t.Courses like '%H7%' or t.Courses like '%R49%' or t.Courses like '%P14%' or t.Courses like '%R47%'), 1,0 ) as 'Missing Only Group 1 Electives',
if(t.Courses like '%H3.1%' and t.Courses not like '%H4.2%' 
	and (t.Courses like '%H5.2%' or t.Courses like '%H15.2%' ) 
	and (t.Courses like '%H7%' or t.Courses like '%R49%' or t.Courses like '%P14%' or t.Courses like '%R47%'), 1,0 ) as 'Missing Only Implementing a WHS Management System',
if(t.Courses not like '%H3.1%' and t.Courses like '%H4.2%' 
	and (t.Courses like '%H5.2%' or t.Courses like '%H15.2%' ) 
	and (t.Courses like '%H7%' or t.Courses like '%R49%' or t.Courses like '%P14%' or t.Courses like '%R47%'), 1,0 ) as 'Missing Only WHS Risk Management'
from (
select a.Id as 'AttendeeId', a.Name, a.Email, group_concat(distinct r.Course_Number__c order by r.Course_Number__c) as 'Courses'#, group_concat(r.Course_Name_Formula__c)#, ass.id, count(distinct r.Id), count(distinct ass.Id)
from contact a
inner join Registration__c r on r.Attendee__c = a.Id
inner join Assessment__c ass on ass.Attendee_ID__c = r.Id
where 
#r.Status__c in ('Confirmed') and 
ass.Name = 'Statement of Attainment'
and ass.Assessment_Status__c = 'Competent'
and r.Course_Number__c in ('H3.1','H4.2',
	'H5.2','H15.2',
	'H7','R49','P14','R47')
group by a.id) t;

