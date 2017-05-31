drop table website_log;

CREATE TABLE `website_log` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `Landing Page` varchar(1024) NOT NULL,
  `Date` datetime NOT NULL,
  `Sessions` int,
  `New Users` int,
  `Bounce Rate` decimal(10,2),
  `Pages / Session` decimal(10,2),
  `Pages` int,
  `Avg. Session Duration` int,
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB AUTO_INCREMENT=2292 DEFAULT CHARSET=utf8;

truncate website_log;
load data local infile 'C:/Users/conluc0/Downloads/website.log.v2.csv' into table website_log fields terminated by ','
  enclosed by '"'
  lines terminated by '\n'
    (`Landing Page`,`Date`,`Sessions`,`New Users`,`Bounce Rate`,`Pages / Session`,`Pages`,`Avg. Session Duration`);


(select t.*, if(c1.Name is null, c2.Name, c1.Name) as 'Course Name', if(c1.Course_Type__c is null, c2.Course_Type__c, c1.Course_Type__c) as 'Course Type', if(c1.Course_Classification__c is null, c2.Course_Classification__c, c1.Course_Classification__c) as 'Course Classification' from (    
select 
`Landing Page`, 
date_format(`Date`, '%Y-%m') as 'Period',
`Pages`,
substring_index(substring_index(substring_index(`Landing Page`, '/', 2), '/',-1), '?', 1) as 'Root', 
substring_index(substring_index(substring_index(`Landing Page`, '/', 3),'/',-1), '?', 1) as 'SubRoot',
if((locate('?id=', `Landing Page`) or locate('&id=', `Landing Page`)) and substring_index(substring_index(`Landing Page`, '/', 2), '/',-1) in ('course', 'tis'), '1', '0') as 'HasSFId',
if((locate('?id=', `Landing Page`) or locate('&id=', `Landing Page`)) and substring_index(substring_index(`Landing Page`, '/', 2), '/',-1) in ('course', 'tis'), 
	substring_index(substring(`Landing Page` from 4+greatest(locate('?id=', `Landing Page`), locate('&id=', `Landing Page`) ) for 18), '&',1),
    null) as 'SFId',
if(locate('?cn=', `Landing Page`) or locate('?cn=', `Landing Page`), '1', '0') as 'HasCourseNumber',
if(locate('?cn=', `Landing Page`) or locate('&cn=', `Landing Page`), 
	substring_index(substring(`Landing Page` from 4+greatest(locate('?cn=', `Landing Page`), locate('&cn=', `Landing Page`) ) ), '&',1),
    null) as 'SFCourseNumber'
from website_log) t 
left join training.course__c c1 on locate(t.SFId,c1.Id)=1
left join training.course__c c2 on t.SFCourseNumber = c2.Course_Number__c
#where t.HasSFId or t.HasCourseNumber
);

select greatest('aaa', null);
select * from training.class__c where ID = 'a0c20000003pnQSAAY';