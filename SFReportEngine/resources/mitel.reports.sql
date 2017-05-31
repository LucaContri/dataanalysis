use salesforce;

describe sf_data;

alter table sf_data modify column DataSubType varchar(50);

select DataSubType, count(Id) from sf_data where DataType='Mitel' group by DataSubType;

select 
date_format(RefDate, '%Y %m') as 'Period',
RefNAme,
round(sum(if (DataSubType='ACD calls handled', refValue,0)),0) as 'ACD calls handled',
round(sum(if (DataSubType='ACD calls offered', refValue,0)),0) as 'ACD calls offered',
avg(if (DataSubType='Average ACD handling time (hh:mm:ss)', refValue,null)) as 'Average ACD handling time (sec)',
avg(if (DataSubType='Average speed of answer (hh:mm:ss)', refValue,null)) as 'Average speed of answer (sec)'
from sf_data 
where DataType='Mitel'
and RefDAte='2014-08-01'
group by `Period`, RefName;

select t2.*,
round(t2.`Total Handling Time`/t2.`ACD calls handled`,0) as 'Avg Handling Time',
round(t2.`Total Answering Time`/t2.`ACD calls handled`,0) as 'Avg Answering Time'
from (
select t.`Period`,
round(sum(t.`ACD calls offered`),0) as 'ACD calls offered',
round(sum(t.`ACD calls handled`),0) as 'ACD calls handled',
round(sum(t.`Average ACD handling time (sec)`*t.`ACD calls handled`),0) as 'Total Handling Time',
round(sum(t.`Average speed of answer (sec)`*t.`ACD calls handled`),0) as 'Total Answering Time' from (
select 
RefDate,
RefName,
date_format(RefDate, '%Y %m') as 'Period',
sum(if (DataSubType='ACD calls handled', refValue,0)) as 'ACD calls handled',
sum(if (DataSubType='ACD calls offered', refValue,0)) as 'ACD calls offered',
sum(if (DataSubType='Average speed of answer (hh:mm:ss)', refValue,null))/0.00001144080897 as 'Average speed of answer (sec)',
sum(if (DataSubType='Average ACD handling time (hh:mm:ss)', refValue,null))/0.00001144080897 as 'Average ACD handling time (sec)'
from sf_data 
where DataType='Mitel'
and RefName in ('Public Training','In-House','Online Learning','Recognition')
and date_format(RefDate, '%Y %m') <= date_format(now(), '%Y %m')
and date_format(RefDate, '%Y %m') >= date_format(date_add(now(), interval -5 month), '%Y %m')
group by RefDate, RefName) t
group by t.`Period`) t2;

use salesforce;
select max(RefDate)
from sf_data 
where DataType='Mitel';

