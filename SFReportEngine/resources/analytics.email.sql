DROP TABLE `analytics`.`email_queue`;
CREATE TABLE `analytics`.`email_queue` (
  `Id` INT NOT NULL AUTO_INCREMENT,
  `createdBy` VARCHAR(128) NOT NULL,
  `createdDate` DATETIME NOT NULL,
  `from` VARCHAR(128) NOT NULL,
  `to` TEXT NOT NULL,
  `subject` TEXT,
  `body` TEXT,
  `attachments` TEXT,
  `last_send_try` DATETIME,
  `last_send_error` TEXT,
  `is_sent` BOOLEAN NOT NULL DEFAULT 0,
  `tries` INT NOT NULL DEFAULT 0,
  PRIMARY KEY (`Id`));

SET SQL_SAFE_UPDATES = 0;
delete from analytics.email_queue where is_sent=0 and createdBy='AP00212W7N';
select * from analytics.email_queue where is_sent=0;
select * from analytics.email_queue  where createdBy='AUSYDHQ-COTAP07';
delete from analytics.email_queue where  id = 3961;
update analytics.email_queue set Is_Sent=0 where Id=2855;
select date_format(createdDate, '%Y-%m-%d') as 'Date', count(id) as 'Count', sum(tries) as 'Tries', avg(timestampdiff(second,createdDate, last_send_try )) as 'TTS' 
from analytics.email_queue 
where is_sent=1
group by `Date`;

select date_format(min(createdDate), '%Y-%m-%d') as 'Since', count(id) as 'Sent', sum(tries) as 'Tries', avg(timestampdiff(second,createdDate, last_send_try )) as 'TTS' 
from analytics.email_queue 
where is_sent=1;
