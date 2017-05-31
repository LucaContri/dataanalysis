use training;

#Timing of Registrations	
#explain
select t2.`Class Id`, t2.`Class Name`,t2.`Location`,t2.`Class_Status__c`, t2.`Final Attendees`, t2.`Min Attendees`,t2.`Class Begin Date`,
sum(if (t2.`Weeks To Class Start`>21,if(t2.Event='Created',1,-1),0))/t2.`Final Attendees` as '20+',
sum(if (t2.`Weeks To Class Start`>20,if(t2.Event='Created',1,-1),0))/t2.`Final Attendees` as '20',
sum(if (t2.`Weeks To Class Start`>19,if(t2.Event='Created',1,-1),0))/t2.`Final Attendees` as '19',
sum(if (t2.`Weeks To Class Start`>18,if(t2.Event='Created',1,-1),0))/t2.`Final Attendees` as '18',
sum(if (t2.`Weeks To Class Start`>17,if(t2.Event='Created',1,-1),0))/t2.`Final Attendees` as '17',
sum(if (t2.`Weeks To Class Start`>16,if(t2.Event='Created',1,-1),0))/t2.`Final Attendees` as '16',
sum(if (t2.`Weeks To Class Start`>15,if(t2.Event='Created',1,-1),0))/t2.`Final Attendees` as '15',
sum(if (t2.`Weeks To Class Start`>14,if(t2.Event='Created',1,-1),0))/t2.`Final Attendees` as '14',
sum(if (t2.`Weeks To Class Start`>13,if(t2.Event='Created',1,-1),0))/t2.`Final Attendees` as '13',
sum(if (t2.`Weeks To Class Start`>12,if(t2.Event='Created',1,-1),0))/t2.`Final Attendees` as '12',
sum(if (t2.`Weeks To Class Start`>11,if(t2.Event='Created',1,-1),0))/t2.`Final Attendees` as '11',
sum(if (t2.`Weeks To Class Start`>10,if(t2.Event='Created',1,-1),0))/t2.`Final Attendees` as '10',
sum(if (t2.`Weeks To Class Start`>9,if(t2.Event='Created',1,-1),0))/t2.`Final Attendees` as '9',
sum(if (t2.`Weeks To Class Start`>8,if(t2.Event='Created',1,-1),0))/t2.`Final Attendees` as '8',
sum(if (t2.`Weeks To Class Start`>7,if(t2.Event='Created',1,-1),0))/t2.`Final Attendees` as '7',
sum(if (t2.`Weeks To Class Start`>6,if(t2.Event='Created',1,-1),0))/t2.`Final Attendees` as '6',
sum(if (t2.`Weeks To Class Start`>5,if(t2.Event='Created',1,-1),0))/t2.`Final Attendees` as '5',
sum(if (t2.`Weeks To Class Start`>4,if(t2.Event='Created',1,-1),0))/t2.`Final Attendees` as '4',
sum(if (t2.`Weeks To Class Start`>3,if(t2.Event='Created',1,-1),0))/t2.`Final Attendees` as '3',
sum(if (t2.`Weeks To Class Start`>2,if(t2.Event='Created',1,-1),0))/t2.`Final Attendees` as '2',
sum(if (t2.`Weeks To Class Start`>1,if(t2.Event='Created',1,-1),0))/t2.`Final Attendees` as '1',
sum(if (t2.`Weeks To Class Start`>0,if(t2.Event='Created',1,-1),0))/t2.`Final Attendees` as '0',
sum(if(t2.Event='Created',1,-1))/t2.`Final Attendees` as '-1'
from (
select t.`Class Id`, t.`Class Name`,t.`Location`,t.`Registration Id`, t.`Status`, t.`Class_Status__c`, t.`Cancel_reason__c`, t.`Billing_Contact__c`, t.`Final Attendees`, t.`Min Attendees`,t.`Class Begin Date`,
t.Event, t.Date,
datediff(t.`Class Begin Date`,t.Date) as 'Days To Class Start',
round(datediff(t.`Class Begin Date`,t.Date)/7) as 'Weeks To Class Start'
#max(if (t.`Event` = 'Created', t.`Date`,null)) as 'Created',
#max(if (t.`Event` = 'Cancelled', t.`Date`,null)) as 'Cancelled/Transferred'
from (	
select 	
    c.Id as 'Class Id',	
    c.Name as 'Class Name',
    c.class_location__c as 'Location',
	r.Id as 'Registration Id',
    r.Status__c as 'Status',
    r.Cancel_reason__c,
    c.Class_Status__c,
    r.Billing_Contact__c,
	c.Number_of_Confirmed_Attendees__c as 'Final Attendees',
     c.Minimim_Attendee__c as 'Min Attendees',
	'Created' as 'Event',
	r.CreatedDate as 'Date',
	c.Class_Begin_Date__c as 'Class Begin Date'	
from training.class__c c	
inner join training.recordtype rt ON c.RecordTypeId = rt.Id	
inner join training.registration__c r ON r.Class_Name__c = c.Id	
where	
	c.Name not like '%DO NOT USE%'
    and r.IsDeleted=0
    and c.IsDeleted=0
	and rt.Name in ('Public Class')
	and c.class_location__c not in ('Online')
    and c.Class_Begin_Date__c<now()
	and c.Class_Status__c not in ('Cancelled')
	#and date_format(c.Class_Begin_Date__c, '%Y-%m') = '2014-11'
	#and r.Status__c = 'Pended - Client Cancellation'
    #and r.Id in ('a0k2000000As12sAAB')
    
union	
select	
	r.Class_Name__c as 'Class Id',
    c.Name as 'Class Name',
    c.class_location__c as 'Location',
	r.Id as 'Registration Id',
	r.Status__c as 'Status',
    r.Cancel_reason__c,
    c.Class_Status__c,
    r.Billing_Contact__c,
    c.Number_of_Confirmed_Attendees__c as 'Final Attendees',
    c.Minimim_Attendee__c as 'Min Attendees',
	'Cancelled' as 'Event',
	i.CreatedDate as 'Date',
    r.Class_Begin_Date__c as 'Class Begin Date'	
from training.invoice_ent__c i	
inner join training.registration__c r on r.Id = i.Registration__c 	
inner join training.class__c c on c.Id = r.Class_Name__c	
inner join training.recordtype rt ON c.RecordTypeId = rt.Id	
where i.Invoice_Type__c='ACR'	
	and i.IsDeleted=0
    and r.IsDeleted=0
	and c.IsDeleted=0
    and c.Name not like '%DO NOT USE%'
	and rt.Name in ('Public Class')
	and c.class_location__c not in ('Online')
	and c.Class_Begin_Date__c<now()
    and c.Class_Status__c not in ('Cancelled')
	#and date_format(c.Class_Begin_Date__c, '%Y-%m') = '2014-11'
    #and r.Id in ('a0k2000000As12sAAB')
    ) t
#group by t.`Registration Id`
order by t.`Class Id`, t.`Date` ) t2
group by t2.`Class Id`
limit 100000;

create or replace view registrations_timing as 
select 	
    c.Id as 'Class Id',	
    c.Name as 'Class Name',
    c.class_location__c as 'Location',
	r.Id as 'Registration Id',
    r.Status__c as 'Status',
    r.Cancel_reason__c,
    c.Class_Status__c,
	r.Billing_Contact__c,
	c.Number_of_Confirmed_Attendees__c as 'Final Attendees',
     c.Minimim_Attendee__c as 'Min Attendees',
	'Created' as 'Event',
	r.CreatedDate as 'Date',
	c.Class_Begin_Date__c as 'Class Begin Date'	
from training.class__c c	
inner join training.recordtype rt ON c.RecordTypeId = rt.Id	
inner join training.registration__c r ON r.Class_Name__c = c.Id	
where	
	c.Name not like '%DO NOT USE%'
    and r.IsDeleted=0
    and c.IsDeleted=0
	and rt.Name in ('Public Class')
	and c.Class_Status__c not in ('Cancelled')
    and c.Class_Begin_Date__c > '2014'
	and c.Class_Begin_Date__c < now()
union	
select	
	r.Class_Name__c as 'Class Id',
    c.Name as 'Class Name',
    c.class_location__c as 'Location',
	r.Id as 'Registration Id',
	r.Status__c as 'Status',
    r.Cancel_reason__c,
    c.Class_Status__c,
    r.Billing_Contact__c,
    c.Number_of_Confirmed_Attendees__c as 'Final Attendees',
    c.Minimim_Attendee__c as 'Min Attendees',
	'Cancelled' as 'Event',
	i.CreatedDate as 'Date',
    r.Class_Begin_Date__c as 'Class Begin Date'	
from training.invoice_ent__c i	
inner join training.registration__c r on r.Id = i.Registration__c 	
inner join training.class__c c on c.Id = r.Class_Name__c	
inner join training.recordtype rt ON c.RecordTypeId = rt.Id	
where i.Invoice_Type__c='ACR'	
	and i.IsDeleted=0
    and r.IsDeleted=0
	and c.IsDeleted=0
    and c.Name not like '%DO NOT USE%'
	and rt.Name in ('Public Class')
    and c.Class_Status__c not in ('Cancelled')
    and c.Class_Begin_Date__c > '2014'
	and c.Class_Begin_Date__c < now();


select c.Id as 'Class Id', c.Name as 'Class Name', c.class_location__c as 'Location', date_format(c.Class_Begin_Date__c, '%d/%m/%Y') as 'Start Date', c.Number_of_Confirmed_Attendees__c as 'Current Attendees', c.Minimim_Attendee__c as 'Min Attendees',t3.`Avg Attendees`, c.Maximum_Attendee__c,
round(t3.`Avg 6wks Attendees %`*100,2) as 'Avg % Attendees 6wks out', t3.`#Classes` as '# Classes in Avg',
round(c.Number_of_Confirmed_Attendees__c/t3.`Avg 6wks Attendees %`,0) as 'Forcasted Final Attendees',
round(greatest(0,(c.Minimim_Attendee__c-c.Number_of_Confirmed_Attendees__c/t3.`Avg 6wks Attendees %`)/c.Minimim_Attendee__c)*100,2) as 'Risk Factor'
from class__c c 
inner join training.recordtype rt ON c.RecordTypeId = rt.Id	
inner join (select t2.`Class Name`, t2.`Location`, avg(t2.`6wks Attendees %`) as 'Avg 6wks Attendees %', count(t2.`Class Id`) as `#Classes`, avg(t2.`Final Attendees`) as 'Avg Attendees'
from (
select t.`Class Id`, t.`Class Name`,t.`Location`,t.`Class_Status__c`, t.`Final Attendees`, t.`Min Attendees`,t.`Class Begin Date`,
#sum(if(round(datediff(t.`Class Begin Date`,t.`Date`)/7) >= 6, if(t.Event='Created',1,-1),0))/t.`Final Attendees` as '6wks Attendees %'
sum(if(date_format(t.`Class Begin Date`,'%x-%v') > date_format(date_add(t.`Date`,interval 6*7 day), '%x-%v'), if(t.Event='Created',1,-1),0))/t.`Final Attendees` as '6wks Attendees %'
from registrations_timing t
group by t.`Class Id`) t2
group by t2.`Class Name`) t3 on t3.`Class Name` = c.Name #and t3.`Location` = c.class_location__c
where 
c.IsDeleted = 0
and c.Name not like '%DO NOT USE%'
and c.class_location__c not in ('Online')
and c.Class_Status__c not in ('Cancelled')
and rt.Name = 'Public Class'
and date_format(c.Class_Begin_Date__c,'%x-%v') = date_format(date_add(now(),interval 6*7 day), '%x-%v')
order by `Risk Factor` desc;



select t.* from
(select 	
    c.Id as 'Class Id',	
    c.Name as 'Class Name',
    c.class_location__c as 'Location',
	r.Id as 'Registration Id',
    r.Status__c as 'Status',
    r.Cancel_reason__c,
    c.Class_Status__c,
	r.Billing_Contact__c,
	c.Number_of_Confirmed_Attendees__c as 'Final Attendees',
     c.Minimim_Attendee__c as 'Min Attendees',
	'Created' as 'Event',
	r.CreatedDate as 'Date',
	c.Class_Begin_Date__c as 'Class Begin Date'	
from training.class__c c	
inner join training.recordtype rt ON c.RecordTypeId = rt.Id	
inner join training.registration__c r ON r.Class_Name__c = c.Id	
where	
	c.Name not like '%DO NOT USE%'
    and r.IsDeleted=0
    and c.IsDeleted=0
	and rt.Name in ('Public Class')
	#and c.Class_Status__c not in ('Cancelled')
	and c.Class_Begin_Date__c < now()
union	
select	
	r.Class_Name__c as 'Class Id',
    c.Name as 'Class Name',
    c.class_location__c as 'Location',
	r.Id as 'Registration Id',
	r.Status__c as 'Status',
    r.Cancel_reason__c,
    c.Class_Status__c,
    r.Billing_Contact__c,
    c.Number_of_Confirmed_Attendees__c as 'Final Attendees',
    c.Minimim_Attendee__c as 'Min Attendees',
	'Cancelled' as 'Event',
	i.CreatedDate as 'Date',
    r.Class_Begin_Date__c as 'Class Begin Date'	
from training.invoice_ent__c i	
inner join training.registration__c r on r.Id = i.Registration__c 	
inner join training.class__c c on c.Id = r.Class_Name__c	
inner join training.recordtype rt ON c.RecordTypeId = rt.Id	
where i.Invoice_Type__c='ACR'	
	and i.IsDeleted=0
    and r.IsDeleted=0
	and c.IsDeleted=0
    and c.Name not like '%DO NOT USE%'
	and rt.Name in ('Public Class')
    #and c.Class_Status__c not in ('Cancelled')
	and c.Class_Begin_Date__c < now()) t
limit 1000000;

select t3.`Class Name`,t3.`Location`,t3.`Min Attendees`,
avg(t3.`20+`) as '20+',
avg(t3.`20`) as '20',
avg(t3.`19`) as '19',
avg(t3.`18`) as '18',
avg(t3.`17`) as '17',
avg(t3.`16`) as '16',
avg(t3.`15`) as '15',
avg(t3.`14`) as '14',
avg(t3.`13`) as '13',
avg(t3.`12`) as '12',
avg(t3.`11`) as '11',
avg(t3.`10`) as '10',
avg(t3.`9`) as '9',
avg(t3.`8`) as '8',
avg(t3.`7`) as '7',
avg(t3.`6`) as '6',
avg(t3.`5`) as '5',
avg(t3.`4`) as '4',
avg(t3.`3`) as '3',
avg(t3.`2`) as '2',
avg(t3.`1`) as '1',
avg(t3.`0`) as '0',
avg(t3.`-1`) as '-1'
from (
select t2.`Class Id`, t2.`Class Name`,t2.`Location`,t2.`Class_Status__c`, t2.`Final Attendees`, t2.`Min Attendees`,t2.`Class Begin Date`,
sum(if (t2.`Weeks To Class Start`>21,if(t2.Event='Created',1,-1),0)) as '20+',
sum(if (t2.`Weeks To Class Start`>20,if(t2.Event='Created',1,-1),0)) as '20',
sum(if (t2.`Weeks To Class Start`>19,if(t2.Event='Created',1,-1),0)) as '19',
sum(if (t2.`Weeks To Class Start`>18,if(t2.Event='Created',1,-1),0)) as '18',
sum(if (t2.`Weeks To Class Start`>17,if(t2.Event='Created',1,-1),0)) as '17',
sum(if (t2.`Weeks To Class Start`>16,if(t2.Event='Created',1,-1),0)) as '16',
sum(if (t2.`Weeks To Class Start`>15,if(t2.Event='Created',1,-1),0)) as '15',
sum(if (t2.`Weeks To Class Start`>14,if(t2.Event='Created',1,-1),0)) as '14',
sum(if (t2.`Weeks To Class Start`>13,if(t2.Event='Created',1,-1),0)) as '13',
sum(if (t2.`Weeks To Class Start`>12,if(t2.Event='Created',1,-1),0)) as '12',
sum(if (t2.`Weeks To Class Start`>11,if(t2.Event='Created',1,-1),0)) as '11',
sum(if (t2.`Weeks To Class Start`>10,if(t2.Event='Created',1,-1),0)) as '10',
sum(if (t2.`Weeks To Class Start`>9,if(t2.Event='Created',1,-1),0)) as '9',
sum(if (t2.`Weeks To Class Start`>8,if(t2.Event='Created',1,-1),0)) as '8',
sum(if (t2.`Weeks To Class Start`>7,if(t2.Event='Created',1,-1),0)) as '7',
sum(if (t2.`Weeks To Class Start`>6,if(t2.Event='Created',1,-1),0)) as '6',
sum(if (t2.`Weeks To Class Start`>5,if(t2.Event='Created',1,-1),0)) as '5',
sum(if (t2.`Weeks To Class Start`>4,if(t2.Event='Created',1,-1),0)) as '4',
sum(if (t2.`Weeks To Class Start`>3,if(t2.Event='Created',1,-1),0)) as '3',
sum(if (t2.`Weeks To Class Start`>2,if(t2.Event='Created',1,-1),0)) as '2',
sum(if (t2.`Weeks To Class Start`>1,if(t2.Event='Created',1,-1),0)) as '1',
sum(if (t2.`Weeks To Class Start`>0,if(t2.Event='Created',1,-1),0)) as '0',
sum(if(t2.Event='Created',1,-1)) as '-1'
from (
select t.`Class Id`, t.`Class Name`,t.`Location`,t.`Registration Id`, t.`Status`, t.`Class_Status__c`, t.`Cancel_reason__c`, t.`Billing_Contact__c`, t.`Final Attendees`, t.`Min Attendees`,t.`Class Begin Date`,
t.Event, t.Date,
datediff(t.`Class Begin Date`,t.Date) as 'Days To Class Start',
round(datediff(t.`Class Begin Date`,t.Date)/7) as 'Weeks To Class Start'
#max(if (t.`Event` = 'Created', t.`Date`,null)) as 'Created',
#max(if (t.`Event` = 'Cancelled', t.`Date`,null)) as 'Cancelled/Transferred'
from (	
select 	
    c.Id as 'Class Id',	
    c.Name as 'Class Name',
    c.class_location__c as 'Location',
	r.Id as 'Registration Id',
    r.Status__c as 'Status',
    r.Cancel_reason__c,
    c.Class_Status__c,
    r.Billing_Contact__c,
	c.Number_of_Confirmed_Attendees__c as 'Final Attendees',
     c.Minimim_Attendee__c as 'Min Attendees',
	'Created' as 'Event',
	r.CreatedDate as 'Date',
	c.Class_Begin_Date__c as 'Class Begin Date'	
from training.class__c c	
inner join training.recordtype rt ON c.RecordTypeId = rt.Id	
inner join training.registration__c r ON r.Class_Name__c = c.Id	
where	
	c.Name not like '%DO NOT USE%'
    and r.IsDeleted=0
    and c.IsDeleted=0
	and rt.Name in ('Public Class')
	and c.class_location__c in ('Melbourne')
    and c.Name = 'Demystifying ISO 9001'
	and c.Class_Status__c not in ('Cancelled')
	and c.Class_Begin_Date__c> '2014'
	and c.Class_Begin_Date__c<now()
    and r.Status__c not in ('Pending')
    #and r.Id in ('a0k2000000As12sAAB')
    
union	
select	
	r.Class_Name__c as 'Class Id',
    c.Name as 'Class Name',
    c.class_location__c as 'Location',
	r.Id as 'Registration Id',
	r.Status__c as 'Status',
    r.Cancel_reason__c,
    c.Class_Status__c,
    r.Billing_Contact__c,
    c.Number_of_Confirmed_Attendees__c as 'Final Attendees',
    c.Minimim_Attendee__c as 'Min Attendees',
	'Cancelled' as 'Event',
	i.CreatedDate as 'Date',
    r.Class_Begin_Date__c as 'Class Begin Date'	
from training.invoice_ent__c i	
inner join training.registration__c r on r.Id = i.Registration__c 	
inner join training.class__c c on c.Id = r.Class_Name__c	
inner join training.recordtype rt ON c.RecordTypeId = rt.Id	
where i.Invoice_Type__c='ACR'	
	and i.IsDeleted=0
    and r.IsDeleted=0
	and c.IsDeleted=0
    and c.Name not like '%DO NOT USE%'
	and rt.Name in ('Public Class')
	and c.class_location__c in ('Melbourne')
    and c.Name = 'Demystifying ISO 9001'
	and c.Class_Status__c not in ('Cancelled')
	and c.Class_Begin_Date__c> '2014'
	and c.Class_Begin_Date__c<now()
    ) t
#group by t.`Registration Id`
order by t.`Class Id`, t.`Date` ) t2
group by t2.`Class Id`) t3;