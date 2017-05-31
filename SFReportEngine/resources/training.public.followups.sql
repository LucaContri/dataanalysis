use training;

select class.Id, class.Name, class.Class_Begin_Date__c, class.Placements_Available__c, class.Class_Location__c from
class__c class
inner join recordtype rt on class.recordtypeid = rt.Id
where rt.Name='Public Class'
and date_format(Class_Begin_Date__c, '%Y %m') in ('2014 09','2014 10') 
and Placements_Available__c>0
order by class.Name;

#Leads from Online feedback
create index lead_email_index on Lead (Email(100));
create index contact_email_index on contact (Email(100));
create index registration_attandee_index on registration__c(Attendee__c);
#explain
select l.Status, l.LeadSource, l.Name, l.Company, l.City, l.State, l.PostalCode, l.Phone, l.Email, l.Industry, date_format(l.CreatedDate, '%Y %m') as 'Created Period', l.Comments__c, l.Personal_Interest__c, l.Job_function__c, 
concat_ws(',',l.Proposed_Q1__c,l.Proposed_Q2__c,l.Proposed_Q3__c,l.Proposed_Q4__c,l.Proposed_Q5__c) as 'Interested in',
l.To_complete_next_training_in__c,
l.Survey_Type__c,
group_concat(class.Name) as 'Past Courses'
from Lead l
inner join recordtype rt on l.recordtypeid = rt.Id
left join contact a on l.Email = a.Email
left join registration__c r on r.Attendee__c = a.Id
left join class__c class on r.Class_Name__c = class.Id
where 
rt.Name like '%APAC%'
#and l.LeadSource='TIS Online Feedback'
and l.CreatedDate >= '2013-01-01'
#and To_complete_next_training_in__c in ('Immediately','3 months')
#and Course_1__c is not null
and l.IsDeleted=0 
#and l.Status in ('Open/Unqualified', '') 
group by l.Id limit 1000000;

select l.*
from Lead l
inner join recordtype rt on l.recordtypeid = rt.Id
where 
rt.Name = 'TIS APAC Lead Record Type'
#l.LeadSource='TIS Online Feedback'
and l.Status = 'Not Ready (Recycle)'
#and l.CreatedDate >= '2014-01-01'
#and To_complete_next_training_in__c in ('Immediately','3 months')
#and Course_1__c is not null
;
update sf_tables set ToSync=1, LastSyncDate='1970-01-01' where Id=151;

use training;
select * from sf_tables where TableName='Lead';
select count(*) from lead;

select * from sf_error;

SELECT DISTINCT TABLE_NAME 
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE COLUMN_NAME IN ('Information_Security__c')
        AND TABLE_SCHEMA='training';
describe lead;
SELECT TableName FROM SF_Tables WHERE ToSync=1 AND DATE_ADD(LastSyncDate, INTERVAL MinSecondsBetweenSyncs SECOND)<UTC_TIMESTAMP();
# Registrations Cancelled
select r.Id, a.Name, r.Status__c, r.Pending_Status__c, r.Status_Reason__c, r.Cancel_reason__c, c.Name, c.Class_Begin_Date__c, c.Class_Location__c
from registration__c r
inner join class__c c on r.Class_Name__c = c.Id
inner join contact a on r.Attendee__c = a.Id
where 
r.Status__c in ('Pended - Client Cancellation','Pended-SAI Cancellation')
and c.Class_Begin_Date__c>='2014-01-01';


select 
#class.Id, 
class.Name as 'Class Name', 
class.Class_Begin_Date__c as 'Class Start Date', 
class.Placements_Available__c as 'Placements Available', 
class.Class_Location__c as 'Location', 
class.Course_Base_Price__c as 'Base Price', 
t.* 
from
class__c class
inner join recordtype rt on class.recordtypeid = rt.Id
left join (
select 
#r.Id, 
a.Name as 'Contact', 
a.Phone as 'Phone', 
a.Email as 'Email',
r.Status__c as 'Reg. Status', 
#r.Pending_Status__c as 'Re', 
#r.Status_Reason__c, 
#r.Cancel_reason__c, 
c.Name, 
c.Class_Begin_Date__c as 'Orig. Class Date', 
c.Class_Location__c as 'Orig Class Location'
from registration__c r
inner join class__c c on r.Class_Name__c = c.Id
inner join contact a on r.Attendee__c = a.Id
where 
r.Status__c in ('Pended - Client Cancellation','Pended-SAI Cancellation')
and c.Class_Begin_Date__c>='2014-01-01') t on t.Name = class.Name and t.`Orig Class Location` = class.Class_Location__c
where rt.Name='Public Class'
and date_format(class.Class_Begin_Date__c, '%Y %m') in ('2014 09','2014 10') 
and class.Placements_Available__c>0
order by class.Name;