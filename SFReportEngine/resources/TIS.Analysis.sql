select 
    c.Id,
    date_format(c.Class_Begin_Date__c, '%Y') as 'year',
    rt.Name,
    c.Class_Status__c,
    c.Pathway__c,
    count(c.id),
    sum(c.Number_of_Confirmed_Attendees__c),
    sum(c.Number_of_Expenses__c),
    sum(c.Total_Actual_Costs__c),
    sum(c.Total_Estimated_Costs__c),
    sum(c.Net_Price__c)
from
    training.class__c c
        left join
    training.recordtype rt ON c.RecordTypeId = rt.Id
where
    c.Class_Status__c = 'Cancelled'
        and rt.Name = 'Public Class'
        and c.Name not like '%DO NOT USE%'
group by c.Id , rt.Name , c.Class_Status__c , `year` , c.Pathway__c
order by `year` , rt.Name , c.Class_Status__c , c.Pathway__c;

(select 
    'Class Expense' as 'Object',
    date_format(e.CreatedDate, '%Y') as 'year',
    rt.Name,
    u.Name,
    count(e.Id) as 'Count'
from
    training.class_expense_tis__c e
        left join
    training.user u ON u.Id = e.CreatedById
        left join
    training.recordtype rt ON e.RecordTypeId = rt.Id
group by e.CreatedById , `year` , rt.Name
order by `year` , rt.Name , count(e.Id)) UNION (select 
    'Class' as 'Object',
    date_format(c.CreatedDate, '%Y') as 'year',
    rt.Name,
    u.Name,
    count(c.Id) as 'Count'
from
    training.class__c c
        left join
    training.user u ON u.Id = c.CreatedById
        left join
    training.recordtype rt ON c.RecordTypeId = rt.Id
group by c.CreatedById , `year` , rt.Name
order by `year` , rt.Name , count(c.Id)) UNION (select 
    'Registration' as 'Object',
    date_format(c.CreatedDate, '%Y') as 'year',
    rt.Name,
    u.Name,
    count(c.Id) as 'Count'
from
    training.registration__c c
        left join
    training.user u ON u.Id = c.CreatedById
        left join
    training.recordtype rt ON c.RecordTypeId = rt.Id
group by c.CreatedById , `year` , rt.Name
order by `year` , rt.Name , count(c.Id)) UNION (select 
    'Assessment' as 'Object',
    date_format(c.CreatedDate, '%Y') as 'year',
    rt.Name,
    u.Name,
    count(c.Id) as 'Count'
from
    training.assessment__c c
        left join
    training.user u ON u.Id = c.CreatedById
        left join
    training.recordtype rt ON c.RecordTypeId = rt.Id
group by c.CreatedById , `year` , rt.Name
order by `year` , rt.Name , count(c.Id)) UNION (select 
    'In-House Event' as 'Object',
    date_format(c.CreatedDate, '%Y') as 'year',
    rt.Name,
    u.Name,
    count(c.Id) as 'Count'
from
    training.in_house_event__c c
        left join
    training.user u ON u.Id = c.CreatedById
        left join
    training.recordtype rt ON c.RecordTypeId = rt.Id
group by c.CreatedById , `year` , rt.Name
order by `year` , rt.Name , count(c.Id)) UNION (select 
    'Course' as 'Object',
    date_format(c.CreatedDate, '%Y') as 'year',
    rt.Name,
    u.Name,
    count(c.Id) as 'Count'
from
    training.course__c c
        left join
    training.user u ON u.Id = c.CreatedById
        left join
    training.recordtype rt ON c.RecordTypeId = rt.Id
group by c.CreatedById , `year` , rt.Name
order by `year` , rt.Name , count(c.Id)) UNION (select 
    'Contact' as 'Object',
    date_format(c.CreatedDate, '%Y') as 'year',
    rt.Name,
    u.Name,
    count(c.Id) as 'Count'
from
    training.contact c
        left join
    training.user u ON u.Id = c.CreatedById
        left join
    training.recordtype rt ON c.RecordTypeId = rt.Id
group by c.CreatedById , `year` , rt.Name
order by `year` , rt.Name , count(c.Id));

select 
    c.CreatedDate, c.Id, c.Name, ce.Id, ce.Name
from
    training.class__c c
        left join
    training.class_expense_tis__c ce ON ce.Class__c = c.Id
        left join
    training.recordtype rt ON c.RecordTypeId = rt.Id
where
    rt.Name = 'Public Class'
        and c.Class_Status__c in ('Cancelled')
        and ce.Id is not null
        and date_format(c.CreatedDate, '%Y') = '2013';

# Timing of Expenses
select 
    c.Id,
    c.Name,
    rt.Name,
    c.CreatedDate,
	ce.CreatedDate,
    c.Class_Begin_Date__c,
	if (ce.CreatedDate>c.Class_Begin_Date__c,1,0) as 'Expense after class start',
	datediff(ce.CreatedDate,c.CreatedDate) as 'Expense to class created days',
	datediff(ce.CreatedDate,c.Class_Begin_Date__c) as 'Expense to class start days',
    c.Class_Status__c

from training.class__c c
inner join training.recordtype rt ON c.RecordTypeId = rt.Id
inner join training.class_expense_tis__c ce ON ce.Class__c = c.Id
where
    rt.Name = 'Public Class'
        and c.Class_Status__c not in ('Cancelled')
        and date_format(c.Class_Begin_Date__c, '%Y') = '2013'
		and class_location__c not in ('Online')
		and c.Number_of_Expenses__c>0
limit 100000;

select 
	date_format(c.Class_Begin_Date__c, '%Y-%m') as 'period',
	count(distinct c.Id) as '# classes',
	sum(if (rt2.Name='Material Expense',1,0)) as '# material exp',
	sum(if (rt2.Name='Speaker Expense',1,0)) as '# speaker exp',
	sum(if (rt2.Name='Travel Expense',1,0)) as '# travel exp',
	sum(if (rt2.Name='Venue Expense',1,0)) as '# venue exp',
	sum(if (rt2.Name='General Expense',1,0)) as '# general exp'
from training.class__c c
inner join training.recordtype rt ON c.RecordTypeId = rt.Id
inner join training.class_expense_tis__c ce ON ce.Class__c = c.Id
inner join training.recordtype rt2 ON rt2.Id = ce.RecordTypeId
where
    rt.Name = 'Public Class'
        and c.Class_Status__c not in ('Cancelled')
		and class_location__c not in ('Online')		
group by `period`;

#Timing of Registrations
select 
    c.Id,
    c.Name,
    rt.Name,
	if (c.class_location__c='Online', 1,0) as 'Online',
    c.Class_Status__c,
	c.CreatedDate,
	r.CreatedDate,
    c.Class_Begin_Date__c,
	date_format(c.Class_Begin_Date__c, '%Y') as 'begin year',
	datediff(r.CreatedDate,c.CreatedDate) as 'Registration to class created days',
	datediff(r.CreatedDate,c.Class_Begin_Date__c) as 'Registartion to class start days',
    round(datediff(r.CreatedDate,c.CreatedDate)/7) as 'Registration to class created weeks',
	round(datediff(r.CreatedDate,c.Class_Begin_Date__c)/7) as 'Registartion to class start weeks'
from training.class__c c
inner join training.recordtype rt ON c.RecordTypeId = rt.Id
inner join training.registration__c r ON r.Class_Name__c = c.Id
where
		c.Name not like '%DO NOT USE%'
        and c.Class_Status__c not in ('Cancelled')
		and r.Status__c = 'Confirmed'
limit 1000000;