use training;

select 
t.Name, 
sum(t.Net_Price__c) as 'Revenues', 
t.`Course daily rate`, t.`b/e attendees`, 
sum(if(t.`Class Period`='2014 01', Number_of_Confirmed_Attendees__c, null)) as 'Attendees 2014 01',
sum(if(t.`Class Period`='2014 02', Number_of_Confirmed_Attendees__c, null)) as 'Attendees 2014 02',
sum(if(t.`Class Period`='2014 03', Number_of_Confirmed_Attendees__c, null)) as 'Attendees 2014 03',
sum(if(t.`Class Period`='2014 04', Number_of_Confirmed_Attendees__c, null)) as 'Attendees 2014 04',
sum(if(t.`Class Period`='2014 05', Number_of_Confirmed_Attendees__c, null)) as 'Attendees 2014 05',
sum(if(t.`Class Period`='2014 06', Number_of_Confirmed_Attendees__c, null)) as 'Attendees 2014 06',
sum(if(t.`Class Period`='2014 07', Number_of_Confirmed_Attendees__c, null)) as 'Attendees 2014 07',
sum(if(t.`Class Period`='2014 08', Number_of_Confirmed_Attendees__c, null)) as 'Attendees 2014 08',
count(if(t.`Class Period`='2014 01', Id, null)) as 'Classes 2014 01',
count(if(t.`Class Period`='2014 02', Id, null)) as 'Classes 2014 02',
count(if(t.`Class Period`='2014 03', Id, null)) as 'Classes 2014 03',
count(if(t.`Class Period`='2014 04', Id, null)) as 'Classes 2014 04',
count(if(t.`Class Period`='2014 05', Id, null)) as 'Classes 2014 05',
count(if(t.`Class Period`='2014 06', Id, null)) as 'Classes 2014 06',
count(if(t.`Class Period`='2014 07', Id, null)) as 'Classes 2014 07',
count(if(t.`Class Period`='2014 08', Id, null)) as 'Classes 2014 08'
from (
select c.Id, lower(replace(replace(c.Name, 'OHS', 'WHS'), '&', 'and')) as 'Name', c.Product_Code__c, c.Pathway__c, c.Class_Location__c, c.Number_of_Confirmed_Attendees__c, c.Maximum_Attendee__c, 
c.Minimim_Attendee__c, 
ceil(c.Training_Days__c*(650+1200)/(c.Course_Base_Price__c-10)) as 'b/e attendees',
c.Course_Base_Price__c/c.Training_Days__c as 'course daily rate',
c.Training_Days__c,
c.Net_Price__c, c.Course_Base_Price__c,
c.Class_Begin_Date__c, c.Class_End_Date__c, date_format(c.Class_Begin_Date__c, '%Y %m') as 'Class Period',
t.Name as 'Trainer',
rt.Name as 'RecordType',
c.Class_Status__c,
c.Number_of_Confirmed_Attendees__c/c.Maximum_Attendee__c
from class__c c
inner join recordtype rt on rt.Id = c.RecordtypeId
left join contact t on t.Id = c.Trainer_1__c
where c.IsDeleted=0
and c.Product_Code__c not in ('RMS', 'NAR')
and c.Name not like '%Budget%'
and c.Name not like '%Actuals%'
and c.Name not like '%DO NOT USE%'
and c.Name not in ('HACCP Platinum Conference Sponsor')
and c.Name not like 'HACCP Conference%'
and rt.Name in ('Generic Class','Public Class')
and c.Class_Begin_Date__c >= '2013-01-01'
and c.Class_Begin_Date__c <= '2014-08-31'
#and c.Class_Status__c not in ('Cancelled')
and c.Class_Location__c in ('Melbourne')
limit 100000
) t group by t.Name order by `Revenues` desc;

select t2.*,
t2.Attendees/t2.`Classes`,
t2.Attendees/t2.`Classes Run`
from (
select 
t.semester,
sum(t.Net_Price__c) as 'Revenues', 
sum(Number_of_Confirmed_Attendees__c) as 'Attendees',
count(Id) as 'Classes',
sum(if(t.Class_Status__c='Cancelled',0,1)) as 'Classes Run',
sum(if(t.Class_Status__c='Cancelled',1,0)) as 'Classes Cancelled',
count(distinct t.Name) as 'Courses'
from (
select c.Id, lower(replace(replace(c.Name, 'OHS', 'WHS'), '&', 'and')) as 'Name', c.Product_Code__c, c.Pathway__c, c.Class_Location__c, c.Number_of_Confirmed_Attendees__c, c.Maximum_Attendee__c, 
c.Minimim_Attendee__c, 
ceil(c.Training_Days__c*(650+1200)/(c.Course_Base_Price__c-10)) as 'b/e attendees',
c.Course_Base_Price__c/c.Training_Days__c as 'course daily rate',
c.Training_Days__c,
c.Net_Price__c, c.Course_Base_Price__c,
c.Class_Begin_Date__c, c.Class_End_Date__c, date_format(c.Class_Begin_Date__c, '%Y %m') as 'Class Period',
concat(year(Class_Begin_Date__c), ' ', quarter(Class_Begin_Date__c)) as 'quarter',
concat(year(Class_Begin_Date__c), ' ', if(month(Class_Begin_Date__c)<=6,1,2)) as 'semester',
t.Name as 'Trainer',
rt.Name as 'RecordType',
c.Class_Status__c,
c.Number_of_Confirmed_Attendees__c/c.Maximum_Attendee__c
from class__c c
inner join recordtype rt on rt.Id = c.RecordtypeId
left join contact t on t.Id = c.Trainer_1__c
where c.IsDeleted=0
and c.Product_Code__c not in ('RMS', 'NAR')
and c.Name not like '%Budget%'
and c.Name not like '%Actuals%'
and c.Name not like '%DO NOT USE%'
and c.Name not in ('HACCP Platinum Conference Sponsor')
and c.Name not like 'HACCP Conference%'
and rt.Name in ('Generic Class','Public Class')
and c.Class_Begin_Date__c >= '2010-01-01'
and c.Class_Begin_Date__c <= '2014-12-31'
#and c.Class_Status__c not in ('Cancelled')
#and c.Class_Location__c in ('Melbourne')
limit 100000
) t group by semester) t2 where t2.semester like '%1';

#elect t.Class_Location__c, sum(t.Net_Price__c), count(t.Id), sum(t.Net_Price__c)/count(t.Id), sum(Number_of_Confirmed_Attendees__c), sum(Number_of_Confirmed_Attendees__c)/count(t.Id) from (
select c.Id, 
replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(lower(c.Name),' - pilot class',''), 'ohs', 'whs'),'an whs','a whs'), '&', 'and'),'vital tool', 'vital 2 tool'),'allergen management for food manufacturers and vital 2 tool','allergen management for food manufacturers and allergen labelling vital 2 tool'),' - pilot',''),'coles auditor training','coles auditor'),'darwin gtnt: ',''),'internal auditor training','internal auditor'),'regional darwin ','') as 'Name', 
c.Product_Code__c, 
c.Pathway__c, 
if (c.Class_Location__c in ('Sydney','Parramatta'), 'Sydney metro', c.Class_Location__c) as 'Location metro',
c.Class_Location__c, 
c.Number_of_Confirmed_Attendees__c, 
c.Maximum_Attendee__c, 
c.Minimim_Attendee__c, 
ceil(c.Training_Days__c*(650+1200)/(c.Course_Base_Price__c-10)) as 'b/e attendees',
c.Course_Base_Price__c/c.Training_Days__c as 'course daily rate',
c.Training_Days__c,
c.Net_Price__c, c.Course_Base_Price__c, course.Early_Bird_Price__c,
c.Class_Begin_Date__c, c.Class_End_Date__c, date_format(c.Class_Begin_Date__c, '%Y %m') as 'Class Period',
concat(year(Class_Begin_Date__c), ' ', quarter(Class_Begin_Date__c)) as 'quarter',
concat(year(Class_Begin_Date__c), ' ', if(month(Class_Begin_Date__c)<=6,1,2)) as 'semester',
t.Name as 'Trainer',
rt.Name as 'RecordType',

c.Class_Status__c,
if (c.Class_Status__c='Cancelled',1,0) as 'Cancelled',
c.Number_of_Confirmed_Attendees__c/c.Maximum_Attendee__c
from class__c c
inner join course__c course on c.Course_Name__c = course.Id
inner join recordtype rt on rt.Id = c.RecordtypeId
left join contact t on t.Id = c.Trainer_1__c
where c.IsDeleted=0
and c.Product_Code__c not in ('RMS', 'NAR')
and c.Name not like '%Budget%'
and c.Name not like '%Actuals%'
and c.Name not like '%DO NOT USE%'
and lower(c.Name) not in ('haccp platinum conference sponsor','haccp awards dinner table of ten')
and c.Name not like 'HACCP Conference%'
and c.Name not like 'CQA%'
and c.Name not like '%Medicare%'
and rt.Name in ('Generic Class','Public Class')
and c.Class_Begin_Date__c >= '2010-01-01'
and c.Class_Begin_Date__c <= '2014-06-30'
#and c.Class_Status__c not in ('Cancelled')
#and c.Class_Location__c in ('Sydney')
limit 100000;
#) t group by t.Class_Location__c;


select t.`class semester`, t.Registration_Method__c, count(t.Id) from (
select r.Id, r.Status__c, r.Registration_Method__c, 
date_format(r.CreatedDate, '%Y %m') as 'Reg. Period',
concat(year(r.Class_Begin_Date__c), ' ', if(month(r.Class_Begin_Date__c)<=6,1,2)) as 'class semester' 
from registration__c r
inner join class__c c on r.Class_Name__c = c.Id
inner join recordtype rt on c.recordtypeid = rt.id
where r.Status__c in ('Confirmed', 'Transferred')
and c.Class_Status__c not in ('Cancelled')
and rt.Name in ('Generic Class','Public Class')
) t group by t.`class semester`, t.Registration_Method__c;