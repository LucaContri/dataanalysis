set @year = '2017';

#use training;
#create index class_trainer1_index on training.class__c(Trainer_1__c);

#explain
(SELECT
	t.Name as 'Trainer',
    #t.MailingCity as 'Trainer City',
    t.MailingState as 'Trainer State',
    #t.`Venue`,
	t.`Month` as 'Period',
    ifnull(group_concat(distinct if(date_format(t.`date`, '%d')='01',concat(t.Product_Code__c, ' ',t.Class_Location__c, ' (',t.Class_Status__c,')', if(t.`TrainerType`='T2', ' (T2)','')), null) separator '\n'), '') as '01',
    ifnull(group_concat(distinct if(date_format(t.`date`, '%d')='02',concat(t.Product_Code__c, ' ',t.Class_Location__c, ' (',t.Class_Status__c,')', if(t.`TrainerType`='T2', ' (T2)','')), null)  separator '\n'), '') as '02',
    ifnull(group_concat(distinct if(date_format(t.`date`, '%d')='03',concat(t.Product_Code__c, ' ',t.Class_Location__c, ' (',t.Class_Status__c,')', if(t.`TrainerType`='T2', ' (T2)','')), null)  separator '\n'), '') as '03',
    ifnull(group_concat(distinct if(date_format(t.`date`, '%d')='04',concat(t.Product_Code__c, ' ',t.Class_Location__c, ' (',t.Class_Status__c,')', if(t.`TrainerType`='T2', ' (T2)','')), null)  separator '\n'), '') as '04',
    ifnull(group_concat(distinct if(date_format(t.`date`, '%d')='05',concat(t.Product_Code__c, ' ',t.Class_Location__c, ' (',t.Class_Status__c,')', if(t.`TrainerType`='T2', ' (T2)','')), null)  separator '\n'), '') as '05',
    ifnull(group_concat(distinct if(date_format(t.`date`, '%d')='06',concat(t.Product_Code__c, ' ',t.Class_Location__c, ' (',t.Class_Status__c,')', if(t.`TrainerType`='T2', ' (T2)','')), null)  separator '\n'), '') as '06',
    ifnull(group_concat(distinct if(date_format(t.`date`, '%d')='07',concat(t.Product_Code__c, ' ',t.Class_Location__c, ' (',t.Class_Status__c,')', if(t.`TrainerType`='T2', ' (T2)','')), null)  separator '\n'), '') as '07',
    ifnull(group_concat(distinct if(date_format(t.`date`, '%d')='08',concat(t.Product_Code__c, ' ',t.Class_Location__c, ' (',t.Class_Status__c,')', if(t.`TrainerType`='T2', ' (T2)','')), null)  separator '\n'), '') as '08',
    ifnull(group_concat(distinct if(date_format(t.`date`, '%d')='09',concat(t.Product_Code__c, ' ',t.Class_Location__c, ' (',t.Class_Status__c,')', if(t.`TrainerType`='T2', ' (T2)','')), null)  separator '\n'), '') as '09',
    ifnull(group_concat(distinct if(date_format(t.`date`, '%d')='10',concat(t.Product_Code__c, ' ',t.Class_Location__c, ' (',t.Class_Status__c,')', if(t.`TrainerType`='T2', ' (T2)','')), null)  separator '\n'), '') as '10',
    ifnull(group_concat(distinct if(date_format(t.`date`, '%d')='11',concat(t.Product_Code__c, ' ',t.Class_Location__c, ' (',t.Class_Status__c,')', if(t.`TrainerType`='T2', ' (T2)','')), null)  separator '\n'), '') as '11',
    ifnull(group_concat(distinct if(date_format(t.`date`, '%d')='12',concat(t.Product_Code__c, ' ',t.Class_Location__c, ' (',t.Class_Status__c,')', if(t.`TrainerType`='T2', ' (T2)','')), null)  separator '\n'), '') as '12',
    ifnull(group_concat(distinct if(date_format(t.`date`, '%d')='13',concat(t.Product_Code__c, ' ',t.Class_Location__c, ' (',t.Class_Status__c,')', if(t.`TrainerType`='T2', ' (T2)','')), null)  separator '\n'), '') as '13',
    ifnull(group_concat(distinct if(date_format(t.`date`, '%d')='14',concat(t.Product_Code__c, ' ',t.Class_Location__c, ' (',t.Class_Status__c,')', if(t.`TrainerType`='T2', ' (T2)','')), null)  separator '\n'), '') as '14',
    ifnull(group_concat(distinct if(date_format(t.`date`, '%d')='15',concat(t.Product_Code__c, ' ',t.Class_Location__c, ' (',t.Class_Status__c,')', if(t.`TrainerType`='T2', ' (T2)','')), null)  separator '\n'), '') as '15',
    ifnull(group_concat(distinct if(date_format(t.`date`, '%d')='16',concat(t.Product_Code__c, ' ',t.Class_Location__c, ' (',t.Class_Status__c,')', if(t.`TrainerType`='T2', ' (T2)','')), null)  separator '\n'), '') as '16',
    ifnull(group_concat(distinct if(date_format(t.`date`, '%d')='17',concat(t.Product_Code__c, ' ',t.Class_Location__c, ' (',t.Class_Status__c,')', if(t.`TrainerType`='T2', ' (T2)','')), null)  separator '\n'), '') as '17',
    ifnull(group_concat(distinct if(date_format(t.`date`, '%d')='18',concat(t.Product_Code__c, ' ',t.Class_Location__c, ' (',t.Class_Status__c,')', if(t.`TrainerType`='T2', ' (T2)','')), null)  separator '\n'), '') as '18',
    ifnull(group_concat(distinct if(date_format(t.`date`, '%d')='19',concat(t.Product_Code__c, ' ',t.Class_Location__c, ' (',t.Class_Status__c,')', if(t.`TrainerType`='T2', ' (T2)','')), null)  separator '\n'), '') as '19',
    ifnull(group_concat(distinct if(date_format(t.`date`, '%d')='20',concat(t.Product_Code__c, ' ',t.Class_Location__c, ' (',t.Class_Status__c,')', if(t.`TrainerType`='T2', ' (T2)','')), null)  separator '\n'), '') as '20',
    ifnull(group_concat(distinct if(date_format(t.`date`, '%d')='21',concat(t.Product_Code__c, ' ',t.Class_Location__c, ' (',t.Class_Status__c,')', if(t.`TrainerType`='T2', ' (T2)','')), null)  separator '\n'), '') as '21',
    ifnull(group_concat(distinct if(date_format(t.`date`, '%d')='22',concat(t.Product_Code__c, ' ',t.Class_Location__c, ' (',t.Class_Status__c,')', if(t.`TrainerType`='T2', ' (T2)','')), null)  separator '\n'), '') as '22',
    ifnull(group_concat(distinct if(date_format(t.`date`, '%d')='23',concat(t.Product_Code__c, ' ',t.Class_Location__c, ' (',t.Class_Status__c,')', if(t.`TrainerType`='T2', ' (T2)','')), null)  separator '\n'), '') as '23',
    ifnull(group_concat(distinct if(date_format(t.`date`, '%d')='24',concat(t.Product_Code__c, ' ',t.Class_Location__c, ' (',t.Class_Status__c,')', if(t.`TrainerType`='T2', ' (T2)','')), null)  separator '\n'), '') as '24',
    ifnull(group_concat(distinct if(date_format(t.`date`, '%d')='25',concat(t.Product_Code__c, ' ',t.Class_Location__c, ' (',t.Class_Status__c,')', if(t.`TrainerType`='T2', ' (T2)','')), null)  separator '\n'), '') as '25',
    ifnull(group_concat(distinct if(date_format(t.`date`, '%d')='26',concat(t.Product_Code__c, ' ',t.Class_Location__c, ' (',t.Class_Status__c,')', if(t.`TrainerType`='T2', ' (T2)','')), null)  separator '\n'), '') as '26',
    ifnull(group_concat(distinct if(date_format(t.`date`, '%d')='27',concat(t.Product_Code__c, ' ',t.Class_Location__c, ' (',t.Class_Status__c,')', if(t.`TrainerType`='T2', ' (T2)','')), null)  separator '\n'), '') as '27',
    ifnull(group_concat(distinct if(date_format(t.`date`, '%d')='28',concat(t.Product_Code__c, ' ',t.Class_Location__c, ' (',t.Class_Status__c,')', if(t.`TrainerType`='T2', ' (T2)','')), null)  separator '\n'), '') as '28',
    ifnull(group_concat(distinct if(date_format(t.`date`, '%d')='29',concat(t.Product_Code__c, ' ',t.Class_Location__c, ' (',t.Class_Status__c,')', if(t.`TrainerType`='T2', ' (T2)','')), null)  separator '\n'), '') as '29',
    ifnull(group_concat(distinct if(date_format(t.`date`, '%d')='30',concat(t.Product_Code__c, ' ',t.Class_Location__c, ' (',t.Class_Status__c,')', if(t.`TrainerType`='T2', ' (T2)','')), null)  separator '\n'), '') as '30',
    ifnull(group_concat(distinct if(date_format(t.`date`, '%d')='31',concat(t.Product_Code__c, ' ',t.Class_Location__c, ' (',t.Class_Status__c,')', if(t.`TrainerType`='T2', ' (T2)','')), null)  separator '\n'), '') as '31'
from (
	select 
		t1.Name,
		t1.MailingCity,
        t1.MailingState,
        'T1' as 'TrainerType',
		year(wd.date) as 'Year',
		date_format(wd.date, '%Y %m') as 'Month',
		wd.date,
        c.Product_Code__c,
        c.Class_Location__c,
        c.Class_Status__c,
        v.Name as 'Venue'
	from training.class__c c
	inner join training.recordtype rt on c.RecordTypeId = rt.Id
	left join training.account v ON v.Id = c.Venue__c
	inner join training.contact t1 ON t1.Id = c.Trainer_1__c
	left join salesforce.sf_working_days wd on wd.date between c.Class_Begin_Date__c and c.Class_End_Date__c
	where
		c.Class_Location__c NOT IN ('Online', 'E-Learning')
		and c.IsDeleted = 0
		and rt.Name in ('In House Class','Public Class')
		and c.Name not like '%DO NOT USE%'
        and c.Product_Code__c not in ('Q5.1', 'E4.1', 'H5.2')
		and year(c.Class_Begin_Date__c) = @year
		and c.Class_Status__c not in ('Cancelled')
	union all
    select 
		t2.Name,
		t2.MailingCity,
        t2.MailingState,
        'T2' as 'TrainerType',
		year(wd.date) as 'Year',
		date_format(wd.date, '%Y %m') as 'Month',
		wd.date,
        c.Product_Code__c,
        c.Class_Location__c,
        c.Class_Status__c,
        v.Name as 'Venue'
	from training.class__c c
	inner join training.recordtype rt on c.RecordTypeId = rt.Id
	left join training.account v ON v.Id = c.Venue__c
	inner join training.contact t2 ON t2.Id = c.Trainer2__c
	left join salesforce.sf_working_days wd on wd.date between c.Class_Begin_Date__c and c.Class_End_Date__c
	where
		c.Class_Location__c not in ('Online', 'E-Learning')
		and c.IsDeleted = 0
		and rt.Name in ('In House Class','Public Class')
		and c.Name not like '%DO NOT USE%'
		and c.Product_Code__c not in ('Q5.1', 'E4.1', 'H5.2')
        and year(c.Class_Begin_Date__c) = @year
		and c.Class_Status__c not in ('Cancelled')
	union all
	select 
		t3.Name,
		t3.MailingCity,
        t3.MailingState,
        'T1' as 'TrainerType',
		year(wd.date) as 'Year',
		date_format(wd.date, '%Y %m') as 'Month',
		wd.date,
        'Blockout',
        '',
        '',
        ''
	from training.blockout__c bo
		inner join training.contact t3 on bo.Tutor__c = t3.Id
        inner join salesforce.sf_working_days wd on wd.date between bo.From_Date__c and bo.To_Date__c
	where
		bo.IsDeleted = 0
		and year(bo.From_Date__c) = @year
	) t
group by t.`Name`, t.`Year`, t.`Month`
order by t.`Year`, t.`Month`, t.`MailingCity`, t.`Name`);

describe training.blockout__c;

update training.sf_tables set ToSync = 1 where TableName='blockout__c' and Id = 156592;

select * from training.sf_tables where TableName='blockout__c' and Id = 156592;

select count(*) from training.BlockOut__c;