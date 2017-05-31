CREATE TABLE `analytics`.`log_report_engine` (
  `Id` INT NOT NULL AUTO_INCREMENT,
  `createdBy` VARCHAR(128) NOT NULL,
  `createdDate` DATETIME NOT NULL,
  `class` VARCHAR(128) NOT NULL,
  `reportName` VARCHAR(512) NOT NULL,
  `emailedTo` TEXT,
  `sftpTo` VARCHAR(512),
  `processingTime` INT,
  PRIMARY KEY (`Id`));
  
  
  select class, sum(ProcessingTime), count(class) from analytics.log_report_engine group by class;
  
  select * from analytics.log_report_engine where date_format(createdDate, '%Y-%m-%d')='2015-05-26';
  
  select t.`Date`, 
  sum(if(t.`metric` = '# Reports Run', t.`Value`, 0)) as '# Reports Run/day',
  sum(if(t.`metric` = '# reports sftp', t.`Value`, 0)) as '# reports sftp/day',
  sum(if(t.`metric` = '# reports emailed', t.`Value`, 0)) as '# reports emailed/day' from (
  (select date_format(createdDate, '%Y-%m-%d') as 'Date', '# Reports Run' as 'metric', count(class) as 'value' from analytics.log_report_engine group by `Date` order by `Date` desc)
  union
  (select date_format(createdDate, '%Y-%m-%d') as 'Date', '# reports sftp' as 'metric', count(class) as 'value' from analytics.log_report_engine where sftpTo is not null group by `Date` order by `Date` desc)
  union
  (select date_format(createdDate, '%Y-%m-%d') as 'Date', '# reports emailed' as 'metric', count(id) as 'value' from analytics.email_queue where is_sent=1 group by `Date` order by `Date` desc) ) t group by t.`Date` order by t.`Date` desc;

select date_format(t2.`Date`, '%Y-%m') as 'Period', avg(t2.`# Reports Run`) as 'Avg # Reports Run/Day', avg(t2.`# reports sftp`) as 'Avg # Reports sftp/Day', avg(t2.`# reports emailed`) as 'Avg # Reports emailed/Day', max(t2.`# individual email addresses`) as '# individual email addresses' from (
  select t.`Date`, 
  sum(if(t.`metric` = '# Reports Run', t.`Value`, 0)) as '# Reports Run',
  sum(if(t.`metric` = '# reports sftp', t.`Value`, 0)) as '# reports sftp',
  sum(if(t.`metric` = '# reports emailed', t.`Value`, 0)) as '# reports emailed',
  sum(if(t.`metric` = '# individual email addresses', t.`Value`, 0)) as '# individual email addresses' from (
  (select date_format(createdDate, '%Y-%m-%d') as 'Date', '# Reports Run' as 'metric', count(class) as 'value' from analytics.log_report_engine group by `Date` order by `Date` desc)
  union
  (select date_format(createdDate, '%Y-%m-%d') as 'Date', '# reports sftp' as 'metric', count(class) as 'value' from analytics.log_report_engine where sftpTo is not null group by `Date` order by `Date` desc)
  union
  (select date_format(createdDate, '%Y-%m-01') as 'Date', '# individual email addresses' as 'metric', count(distinct `to`) as 'value' from analytics.email_queue where is_sent=1 group by `Date` desc)
  union
  (select date_format(createdDate, '%Y-%m-%d') as 'Date', '# reports emailed' as 'metric', count(id) as 'value' from analytics.email_queue where is_sent=1 group by `Date` order by `Date` desc) ) t group by t.`Date` order by t.`Date` desc ) t2
group by `Period`;
  
  select date_format(createdDate, '%Y-%m-01') as 'Date', count(distinct `to`) from analytics.email_queue where is_sent=1 group by `Date`;
  
  select * from analytics.log_report_engine order by id desc;
  
  
select sp_name, date_add(max(exec_time), interval 10 hour) as 'Last Update' 
from analytics.sp_log 
group by sp_name
order by `Last Update` asc; 
