SELECT 
    m.`Metric Group`,
    m.`Product Portfolio`,
    SUM(IF(m.Region = 'AMERICAs',md.SLA * md.Volume,0)) / SUM(IF(m.Region = 'AMERICAs', md.Volume, 0)) AS 'AMERICAs',
	SUM(IF(m.Region = 'AMERICAs',m.`SLA Target Amber`* md.Volume,0)) / SUM(IF(m.Region = 'AMERICAs', md.Volume, 0)) AS 'AMERICAs Target Amber',
	SUM(IF(m.Region = 'AMERICAs',m.`SLA Target Green`* md.Volume,0)) / SUM(IF(m.Region = 'AMERICAs', md.Volume, 0)) AS 'AMERICAs Target Green',
    SUM(IF(m.Region = 'APAC',md.SLA * md.Volume,0)) / SUM(IF(m.Region = 'APAC', md.Volume, 0)) AS 'APAC',
	SUM(IF(m.Region = 'APAC',m.`SLA Target Amber`* md.Volume,0)) / SUM(IF(m.Region = 'APAC', md.Volume, 0)) AS 'APAC Target Amber',
	SUM(IF(m.Region = 'APAC',m.`SLA Target Green`* md.Volume,0)) / SUM(IF(m.Region = 'APAC', md.Volume, 0)) AS 'APAC Target Green',
    SUM(IF(m.Region = 'EMEA',md.SLA * md.Volume,0)) / SUM(IF(m.Region = 'EMEA', md.Volume, 0)) AS 'EMEA',
	SUM(IF(m.Region = 'EMEA',m.`SLA Target Amber`* md.Volume,0)) / SUM(IF(m.Region = 'EMEA', md.Volume, 0)) AS 'EMEA Target Amber',
	SUM(IF(m.Region = 'EMEA',m.`SLA Target Green`* md.Volume,0)) / SUM(IF(m.Region = 'EMEA', md.Volume, 0)) AS 'EMEA Target Green',
    SUM(md.SLA * md.Volume) / SUM(md.Volume) AS 'Overall',
    SUM(m.`SLA Target Amber`* md.Volume) / SUM(md.Volume) AS 'Overall Target Amber',
    SUM(m.`SLA Target Green`* md.Volume) / SUM(md.Volume) AS 'Overall Target Green'
FROM
    metrics_data md
        INNER JOIN
    metrics m ON md.`Metric Id` = m.Id
WHERE
    `Period` >= '2015-06-01 00:00:00'
        AND `Period` <= '2015-06-01 00:00:00'
GROUP BY m.`Metric Group` , m.`Product Portfolio`;

# Statuses: 
#	0 = RED,
#	1 = AMBER,
#	2 = GREEN;

SELECT 
    m.`Metric Group`,
    m.`Product Portfolio`,
    SUM(IF(m.Region = 'AMERICAs',md.SLA * md.Volume,0)) / SUM(IF(m.Region = 'AMERICAs', md.Volume, 0)) AS 'AMERICAs',
	MIN(IF(m.Region = 'AMERICAs' and md.SLA<m.`SLA Target Amber`,0,IF(m.Region = 'AMERICAs' and md.SLA<m.`SLA Target Green`,1,2))) AS 'AMERICAs Status',
	SUM(IF(m.Region = 'APAC',md.SLA * md.Volume,0)) / SUM(IF(m.Region = 'APAC', md.Volume, 0)) AS 'APAC',
	MIN(IF(m.Region = 'APAC' and md.SLA<m.`SLA Target Amber`,0,IF(m.Region = 'APAC' and md.SLA<m.`SLA Target Green`,1,2))) AS 'APAC Status',
	SUM(IF(m.Region = 'EMEA',md.SLA * md.Volume,0)) / SUM(IF(m.Region = 'EMEA', md.Volume, 0)) AS 'EMEA',
    MIN(IF(m.Region = 'EMEA' and md.SLA<m.`SLA Target Amber`,0,IF(m.Region = 'EMEA' and md.SLA<m.`SLA Target Green`,1,2))) AS 'EMEA Status',
	SUM(md.SLA * md.Volume) / SUM(md.Volume) AS 'Overall',
    MIN(IF(md.SLA<m.`SLA Target Amber`,0,IF(md.SLA<m.`SLA Target Green`,1,2))) AS 'Overall Status'
FROM
    metrics_data md
        INNER JOIN
    metrics m ON md.`Metric Id` = m.Id
WHERE
    `Period` >= '2015-06-01 00:00:00'
        AND `Period` <= '2015-06-01 00:00:00'
GROUP BY m.`Metric Group` , m.`Product Portfolio`;


# Metrics Input Template
select t2.* from (
select t.`Metric Id`, t.`Target Id`, t.`Region`, t.`Product Portfolio`, t.`Metric Group`, t.`Metric`,t.`Team` as 'Business Unit', 'Oct 15' as 'Period', t.`Volume Definition`, t.`Volume Unit`, t.`Volume`, t.`SLA Definition`, t.`Target Amber`, t.`Target Green`, t.`SLA`,  t.`Prepared Date/Time`, t.`Prepared By` 
from (
select md.`Metric Id`, md.`Target Id`, m.`Product Portfolio`, md.`Region`,md.`SubRegion`, m.`Metric Group`, m.`Metric`, md.`Team`, md.`Period`, m.`Volume Definition`, m.`Volume Unit`, if(`Period`=date_format(date_add(now(),interval -1 month),'%Y-%m-01'),md.`Volume`,'') as 'Volume', m.`SLA Definition`, mt.`Target Amber`, mt.`Target Green`, if(`Period`=date_format(date_add(now(),interval -1 month),'%Y-%m-01'),md.`SLA`,'') as 'SLA',  if(`Period`=date_format(date_add(now(),interval -1 month),'%Y-%m-01'),md.`Prepared Date/Time`,'') as 'Prepared Date/Time', md.`Prepared By`
from analytics.metrics_data md
inner join analytics.metrics m on md.`Metric Id` = m.Id
inner join analytics.metrics_targets mt on md.`Target Id` = mt.Id
where 
not(m.`Metric`='ARG Rejection' and md.`Team`='EMEA Food Auditors') # Not longer using this as breaking down by country
and not (m.`Metric`='ARG process time' and md.`Team`='EMEA Food Ops') # Not longer using this as breaking down by country
order by `Metric Id`, `Team`,`Region`,`Target Id`, `Period` desc) t
group by `Metric Id`, `Team`,`Region`,`Target Id`) t2
where t2.`SLA` = ''
order by t2.`Region`, `Product Portfolio`, `Metric Group`, `Metric`;

select * from analytics.metrics_targets where Id = 4;
# Assurance - Quality - ARG Rejections
delete from analytics.metrics_data where `Metric Id` = 6 and `Prepared By` = 'Luca Contri';
insert into analytics.metrics_data
(select 
null as 'Id',
6 as `Metric Id`,
if (r.Reporting_Business_Units__c not like 'APAC%' and r.Reporting_Business_Units__c not like 'EMEA%' and r.Reporting_Business_Units__c like '%Food%',5,4) as `Target Id`,
if (r.Reporting_Business_Units__c like 'EMEA%', 'EMEA', 'APAC') as 'Region',
group_concat(distinct r.Reporting_Business_Units__c) as 'SubRegion',
if(r.Reporting_Business_Units__c like 'Asia%', 
	concat(substring_index(Reporting_Business_Units__c,'-',-1),' Auditors'), 
    if(r.Reporting_Business_Units__c like 'EMEA%', 
		#'EMEA Food Auditors',
        concat(substring_index(Reporting_Business_Units__c,'-',-1),' Food Auditors'), 
        if (r.Reporting_Business_Units__c like '%Food%',
			'Australia Food Auditors',
            if (r.Reporting_Business_Units__c like '%Product%',
				'Product Auditors',
                'Australia MS Auditors'
            )
		)
	)
) as 'Team',
if(r.Reporting_Business_Units__c like '%Product%', 
	'Richard Donarski', 
    if (r.Reporting_Business_Units__c like '%EMEA%', 
		'Phil Egan', 
        if (r.Reporting_Business_Units__c like 'ASIA%',
			'TBA',
            'Tony Hardy'    
        )
	)
) as 'Business Owner',
str_to_date(date_format(arg.CA_Approved__c, '%Y %m 01'),'%Y %m %d')  as 'Period',
'Luca Contri' as 'Prepared By',
now() as 'Prepared Date/Time',
count(distinct arg.Id) as 'Volume',
count(distinct if(ah.Status__c='Rejected', arg.Id, null))/count(distinct arg.Id)  as 'Value',
1 - count(distinct if(ah.Status__c='Rejected', arg.ID, null))/count(distinct arg.Id) as 'SLA'
from salesforce.approval_history__c ah 
inner join salesforce.audit_report_group__c arg on arg.Id = ah.RAudit_Report_Group__c
inner join salesforce.resource__c r on arg.RAudit_Report_Author__c = r.Id
where 
arg.CA_Approved__c< '2015-11-01'
and arg.CA_Approved__c>= '2015-10-01'
and r.Reporting_Business_Units__c not like '%Product%'
group by `Metric Id`, `Team`, `Period`);

# Assurance - Timeliness - ARG Process Time
delete from analytics.metrics_data where `Metric Id` = 4 and `Prepared By` = 'Luca Contri';
delete from analytics.metrics_data where `Metric Id` = 4 and `Prepared By` = 'Luca Contri' and Region = 'EMEA' and Period = '2015-09-01';

insert into analytics.metrics_data
(select 
null as 'Id', 
4 as 'Metric Id',
17 as 'Target Id',
if (t.Region like 'EMEA%', 'EMEA', 'APAC') as 'Region2',
if (t.Region like 'EMEA%', 'EMEA', 'APAC') as 'SubRegion',
	if(t.Region like 'Asia%', 
		concat(substring_index(t.Region,'-',-2), ' Ops'), 
		if(t.Region like 'EMEA%', 
			#'EMEA Food Auditors',
            concat(substring_index(t.Region,'-',-2), ' Food Ops'),
			if (t.Region like '%Food%',
				'Australia Food Ops',
				if (t.Region like '%Product%',
					'Product Services Ops',
					'Australia MS Ops'
				)
			)
		)
	) as 'Team',
    if(t.Region like '%Product%', 
		'Richard Donarski', 
		if (t.Region like '%EMEA%', 
			'Phil Egan', 
			if (t.Region like 'ASIA%',
				'TBA',
				'Tony Hardy, Heather Mahon, Zoe Quelch'    
			)
		)
	) as 'Business Owner',
    DATE_FORMAT(t.`To`, '%Y-%m-01') as 'Period',
    'Luca Contri' as 'Prepared By',
    now() as 'Prepared Date/Time',
    count(distinct t.`Id`) as 'Volume',
    AVG(DATEDIFF(t.`To`, t.`From`)) as 'Value',
    SUM(if(t.`To` <= t.`SLA Due`,1,0))/count(distinct t.`Id`) as 'SLA'    
from analytics.sla_arg_v2 t
where
t.`To` is not null 
and t.`Region` not like '%Product%'
and t.`Metric` in ('ARG Process Time (BRC)', 'ARG Process Time (Other)')
and DATE_FORMAT(t.`To`, '%Y-%m') in ('2015-10')
GROUP BY `Region2`, `Team`, `Period`);

# Assurance - Utilisation
delete from analytics.metrics_data where `Metric Id` in (16) and Region='APAC' and `Prepared By` = 'Luca Contri';
insert into analytics.metrics_data 
select 
	null as Id, 
	16 as 'Metric Id',
    9 as 'Target Id',
    'APAC' as 'Region',
    ftec.`Region` as 'SubRegion',
    'Australia Food Auditors' as 'Team',
    'Tony Hardy' as 'Business Owner',
	STR_TO_DATE(concat(ftec.`Period`, ' 01'), '%Y %m %d') as 'Period',
	'Luca Contri' as 'Prepared By',
	util.`Date` as 'Prepared Date/Time',
	ftec.`FTECount` as 'Volume',
	util.`Utilisation` as 'Value',
	util.`Utilisation` as 'SLA' from
(select t.`Region`, t.ColumnName as 'Period', t.`Value` as 'FTECount', t.`Date`
	from (
		select * 
		from salesforce.sf_report_history 
		where 
			ReportName='Scheduling Auditors Metrics'
			and RowName = 'Food-FTECount'
			and `Region` in ('Australia')
		order by Date desc) t
group by `Region`, `Period`) ftec
inner join 
(select t.`Region`, t.ColumnName as 'Period', t.`Value` as 'Utilisation', t.`Date`
	from (
		select * 
		from salesforce.sf_report_history 
		where 
			ReportName='Scheduling Auditors Metrics'
			and RowName = 'Food-Utilisation'
			and `Region` in ('Australia')
            and `ColumnName` >= '2015 10'
            and `ColumnName` <= '2015 10'
		order by Date desc) t
group by `Region`, `Period`) util on ftec.Region = util.Region and ftec.Period = util.Period
union
#insert into analytics.metrics_data
select 
	null as Id, 
	16 as 'Metric Id',
    9 as 'Target Id',
    'APAC' as 'Region',
    ftec.`Region` as 'SubRegion',
    if (ftec.`Region`='Australia', 'Australia MS Auditors', concat(ftec.`Region`, ' Auditors')) as 'Team',
    if (ftec.`Region`='Australia', 'Tony Hardy', 'TBA') as 'Business Owner',
	STR_TO_DATE(concat(ftec.`Period`, ' 01'), '%Y %m %d') as 'Period',
	'Luca Contri' as 'Prepared By',
	util.`Date` as 'Prepared Date/Time',
	ftec.`FTECount` as 'Volume',
	util.`Utilisation` as 'Value',
	util.`Utilisation` as 'SLA' from
(select t.`Region`, t.ColumnName as 'Period', t.`Value` as 'FTECount', t.`Date`
	from (
		select * 
		from salesforce.sf_report_history 
		where 
			ReportName='Scheduling Auditors Metrics'
			and RowName = 'MS-FTECount'
			and `Region` in ('Australia','China','India', 'Indonesia', 'Thailand', 'Japan', 'Korea')
		order by Date desc) t
group by `Region`, `Period`) ftec
inner join 
(select t.`Region`, t.ColumnName as 'Period', t.`Value` as 'Utilisation', t.`Date`
	from (
		select * 
		from salesforce.sf_report_history 
		where 
			ReportName='Scheduling Auditors Metrics'
			and RowName = 'MS-Utilisation'
			and `Region` in ('Australia','China','India', 'Indonesia', 'Thailand', 'Japan', 'Korea')
            and `ColumnName` >= '2015 10'
            and `ColumnName` <= '2015 10'
		order by Date desc) t
group by `Region`, `Period`) util on ftec.Region = util.Region and ftec.Period = util.Period;
        
# APAC - Knowledge - Quality
SELECT * FROM analytics.metrics 
where Region = 'APAC'
and `Product Portfolio` = 'Knowledge'
and `Metric Group` = 'Timeliness';

# Knowledge	Quality	IS Production AUS	InfoStore pricing errors
insert into analytics.metrics_data values (null,14,'Australia','2015-05-01', 'Sian Lindsay','2015-07-15',54,0,1);
# Knowledge	Quality	IS Production AUS	Royalty reporting errors
insert into analytics.metrics_data values (null,15,'Australia','2015-05-01', 'Sian Lindsay','2015-07-15',54,0,1);

# Knowledge	Timeliness	IS CS Australia	Phone Waiting Time
insert into analytics.metrics_data values (null,27,'Australia','2015-05-01', 'Christine Kiely','2015-07-15',3675,null,0.791);
insert into analytics.metrics_data values (null,27,'Australia','2015-06-01', 'Christine Kiely','2015-07-15',3655,null,0.80);
# Knowledge	Timeliness	IS CS Australia	Phone Quality Survey
insert into analytics.metrics_data values (null,33,'Australia','2015-05-01', 'Christine Kiely','2015-07-15',3675,null,0.924);
insert into analytics.metrics_data values (null,33,'Australia','2015-06-01', 'Christine Kiely','2015-07-15',3655,null,0.941);

#APAC	Knowledge	Timeliness	Reference Services	Lawlex Error Rate
insert into analytics.metrics_data values (null,34,'Australia','2015-05-01', 'Brian McGettrick','2015-07-15',10456,0.0016258,0.9983741);
insert into analytics.metrics_data values (null,34,'Australia','2015-06-01', 'Brian McGettrick','2015-07-15',13353,0.0017973,0.9982027);

# APAC	Knowledge	Timeliness	News Services	Newsfeeds published
insert into analytics.metrics_data values (null,35,'Australia','2015-05-01', 'Joy Han','2015-07-15',64,64,1);
insert into analytics.metrics_data values (null,35,'Australia','2015-06-01', 'Joy Han','2015-07-15',64,64,1);

# APAC	Knowledge	Timeliness	News Services	Law Bulletin published
insert into analytics.metrics_data values (null,36,'Australia','2015-05-01', 'Joy Han','2015-07-15',1,1,0);
insert into analytics.metrics_data values (null,36,'Australia','2015-06-01', 'Joy Han','2015-07-15',1,1,1);

# APAC	Knowledge	Timeliness	SH&E	SHE Monitor Published
insert into analytics.metrics_data values (null,37,8,'APAC','Australia','SH&E Services','Brian McGettrick', '2015-05-01', 'Brian McGettrick','2015-07-15',4,4,1);
insert into analytics.metrics_data values (null,37,8,'APAC','Australia','SH&E Services','Brian McGettrick', '2015-06-01', 'Brian McGettrick','2015-07-15',4,4,1);
insert into analytics.metrics_data values (null,37,8,'APAC','Australia','SH&E Services','Maria Rechichi','2015-08-01', 'Maria Rechichi','2015-07-15',4,4,1);

# Risk - Utilisation 
#delete from analytics.metrics_data where `Metric Id` in (9,41,43,23,42,44);
insert into analytics.metrics_data values (null,9,'Australia','2015-06-01', 'Amanda Dunlop','2015-07-21',12,.711,.711);
insert into analytics.metrics_data values (null,41,'United Kingdom','2015-06-01', 'Amanda Dunlop','2015-07-21',3,.729,.641);
insert into analytics.metrics_data values (null,43,'US','2015-06-01', 'Amanda Dunlop','2015-07-21',6,.776,.846);

insert into analytics.metrics_data values (null,9,'Australia','2015-05-01', 'Amanda Dunlop','2015-07-21',12,.71,.71);
insert into analytics.metrics_data values (null,41,'United Kingdom','2015-05-01', 'Amanda Dunlop','2015-07-21',3,.729,.729);
insert into analytics.metrics_data values (null,43,'US','2015-05-01', 'Amanda Dunlop','2015-07-21',6,.776,.776);

insert into analytics.metrics_data values (null,9,6,'EMEA','United Kingdom', 'Client Service - EMEA', 'Andy Gordon', '2015-07-01', 'Amanda Dunlop','2015-08-10',3,.583,.583);
insert into analytics.metrics_data values (null,9,6,'APAC','Australia', 'Client Service - APAC', 'Andy Gordon', '2015-07-01', 'Amanda Dunlop','2015-08-10',12,.68,.68);
insert into analytics.metrics_data values (null,9,6,'AMERICAs','US', 'Client Service - AMERICAs', 'Terry Matney', '2015-07-01', 'Terry Matney','2015-08-03',5,.731,.731);

insert into analytics.metrics_data values (null,9,6,'AMERICAs','US', 'Client Service - AMERICAs', 'Terry Matney', '2015-08-01', 'Terry Matney','2015-09-04',5,.8807,.8807);
insert into analytics.metrics_data values (null,9,6,'APAC','Australia', 'Client Service - APAC', 'Andy Gordon', '2015-08-01', 'Amanda Dunlop','2015-09-09',12,.7025,.7025);
insert into analytics.metrics_data values (null,9,6,'EMEA','United Kingdom', 'Client Service - EMEA', 'Andy Gordon', '2015-08-01', 'Amanda Dunlop','2015-09-11',3,.4506,.4506);

# EMEA - Auditors Chargability
insert into analytics.metrics_data values (null,16,9,'EMEA','EMEA', 'EMEA Food Auditors', 'Manish Patel', '2015-07-01', 'Jessica Restall','2015-08-19',20,.8,.8);
insert into analytics.metrics_data values (null,16,9,'EMEA','EMEA', 'EMEA Retail Auditors', 'Manish Patel', '2015-07-01', 'Jessica Restall','2015-08-19',70,1,1);
insert into analytics.metrics_data values (null,16,9,'EMEA','EMEA', 'EMEA Agri Auditors', 'Manish Patel', '2015-07-01', 'Jessica Restall','2015-08-19',59,.71,.71);
insert into analytics.metrics_data values (null,16,9,'EMEA','EMEA', 'EMEA SCM Auditors', 'Manish Patel', '2015-07-01', 'Jessica Restall','2015-08-19',2,.91,.91);

insert into analytics.metrics_data values (null,16,9,'EMEA','EMEA', 'EMEA Food Auditors', 'Manish Patel', '2015-08-01', 'Jessica Restall','2015-09-08',18,0.660000,0.660000);
insert into analytics.metrics_data values (null,16,9,'EMEA','EMEA', 'EMEA Retail Auditors', 'Manish Patel', '2015-08-01', 'Jessica Restall','2015-09-08',61,1,1);
insert into analytics.metrics_data values (null,16,9,'EMEA','EMEA', 'EMEA Agri Auditors', 'Manish Patel', '2015-08-01', 'Jessica Restall','2015-09-08',60,0.511111,0.511111);
insert into analytics.metrics_data values (null,16,9,'EMEA','EMEA', 'EMEA SCM Auditors', 'Manish Patel', '2015-08-01', 'Jessica Restall','2015-09-08',2,0.333333,0.333333);

# AMERICAs - Auditors Chargeability
insert into analytics.metrics_data values (null,16,9,'AMERICAs','Canada', 'Canada Operations', 'TBA', '2015-08-01', 'Liliana Niculae','2015-09-09',21,0.8199,0.8199);
insert into analytics.metrics_data values (null,16,9,'AMERICAs','US', 'US Operations', 'TBA', '2015-08-01', 'Liliana Niculae','2015-09-09',30,0.8991,0.8991);
insert into analytics.metrics_data values (null,16,9,'AMERICAs','Mexico', 'Mexico Operations', 'TBA', '2015-08-01', 'Liliana Niculae','2015-09-09',6,0.3022,0.3022);

# EMEA - Staff Enlighten Productivity
insert into analytics.metrics_data values (null,2,18,'EMEA','United Kingdom', 'AS EMEA CS Administration', 'Jessica Restall', '2015-07-01', 'Jessica Restall','2015-08-19',13,.59,.59);
insert into analytics.metrics_data values (null,2,18,'EMEA','United Kingdom', 'AS EMEA CS Scheduling', 'Liz Chung', '2015-07-01', 'Jessica Restall','2015-08-19',7,.5,.5);
insert into analytics.metrics_data values (null,2,18,'EMEA','United Kingdom', 'AS EMEA SCM Operations', 'Manish Patel', '2015-07-01', 'Jessica Restall','2015-08-19',9,.56,.56);
#insert into analytics.metrics_data values (null,2,18,'EMEA','United Kingdom', 'AS EMEA TIS', 'Manish Patel', '2015-07-01', 'Jessica Restall','2015-08-19',6,.6875,.6875);

insert into analytics.metrics_data values (null,2,18,'EMEA','United Kingdom', 'AS EMEA CS Administration', 'Jessica Restall', '2015-08-01', 'Jessica Restall','2015-09-08',13,0.618570,0.618570);
insert into analytics.metrics_data values (null,2,18,'EMEA','United Kingdom', 'AS EMEA CS Scheduling', 'Liz Chung', '2015-08-01', 'Jessica Restall','2015-09-08',7,0.45594,0.45594);
insert into analytics.metrics_data values (null,2,18,'EMEA','United Kingdom', 'AS EMEA SCM Operations', 'Manish Patel', '2015-08-01', 'Jessica Restall','2015-09-08',9,0.423292,0.423292);

# APAC - Staff Enlighten Productivity
insert into analytics.metrics_data values (null,2,18,'APAC','Australia', 'Scheduling - MS', 'Lily Liu', '2015-07-01', 'Luca Contri','2015-08-20',10,.71,.71);
insert into analytics.metrics_data values (null,2,18,'APAC','Australia', 'Scheduling - PS', 'Lily Liu', '2015-07-01', 'Luca Contri','2015-08-19',5,.715,.715);
insert into analytics.metrics_data values (null,2,18,'APAC','Australia', 'CS - Administration', 'Zoe Quelch', '2015-07-01', 'Luca Contri','2015-08-19',11,.445,.445);
insert into analytics.metrics_data values (null,1,18,'APAC','Australia', 'News Services', 'Joy Han', '2015-07-01', 'Luca Contri','2015-08-27',13,.71,.71);
insert into analytics.metrics_data values (null,1,18,'APAC','Australia', 'Reference Services', 'Maria Rechichi', '2015-07-01', 'Luca Contri','2015-08-27',5,.7475,.7475);
insert into analytics.metrics_data values (null,1,18,'APAC','Australia', 'SH&E Services', 'Maria Rechichi', '2015-07-01', 'Luca Contri','2015-08-27',5,.66,.66);
insert into analytics.metrics_data values (null,1,18,'APAC','Australia', 'IS Production AUS', 'Sian Lindsay', '2015-07-01', 'Luca Contri','2015-08-19',2,.5475,.5475);

insert into analytics.metrics_data values (null,2,18,'APAC','Australia', 'Scheduling - MS', 'Lily Liu', '2015-08-01', 'Luca Contri','2015-09-09',11,.594,.594);
insert into analytics.metrics_data values (null,2,18,'APAC','Australia', 'Scheduling - PS', 'Lily Liu', '2015-08-01', 'Luca Contri','2015-09-09',5,.742,.742);
insert into analytics.metrics_data values (null,2,18,'APAC','Australia', 'CS - Administration', 'Zoe Quelch', '2015-08-01', 'Luca Contri','2015-09-09',10,.39,.39);
insert into analytics.metrics_data values (null,1,18,'APAC','Australia', 'News Services', 'Joy Han', '2015-08-01', 'Luca Contri','2015-09-09',12,.688,.688);
insert into analytics.metrics_data values (null,1,18,'APAC','Australia', 'Reference Services', 'Maria Rechichi', '2015-08-01', 'Luca Contri','2015-09-09',4,.674,.674);
insert into analytics.metrics_data values (null,1,18,'APAC','Australia', 'SH&E Services', 'Maria Rechichi', '2015-08-01', 'Luca Contri','2015-09-09',5,.618,.618);
insert into analytics.metrics_data values (null,1,18,'APAC','Australia', 'IS Production AUS', 'Sian Lindsay', '2015-08-01', 'Luca Contri','2015-09-09',2,.544,.544);

# EMEA - ARG Rejections
insert into analytics.metrics_data values (null,6,4,'EMEA','EMEA', 'EMEA Retail Auditors', 'Dale Newitt / Manish Patel', '2015-07-01', 'Jessica Restall','2015-08-19',661,0.29,0.71);
insert into analytics.metrics_data values (null,6,4,'EMEA','EMEA', 'EMEA Agri Auditors', 'Dale Newitt / Manish Patel', '2015-07-01', 'Jessica Restall','2015-08-19',1276,0.10,0.90);

insert into analytics.metrics_data values (null,6,4,'EMEA','EMEA', 'EMEA Retail Auditors', 'Manish Patel', '2015-08-01', 'Jessica Restall','2015-09-08',900,0.132222,1-0.132222);
insert into analytics.metrics_data values (null,6,4,'EMEA','EMEA', 'EMEA Agri Auditors', 'Manish Patel', '2015-08-01', 'Jessica Restall','2015-09-08',735,0.121088,1-0.121088);

select * from analytics.metrics_data  where `Metric Id` = 6 and Region = 'EMEA';

# AMERICAS - Assurance ARG Rejections
insert into analytics.metrics_data values (null,6,4,'AMERICAs','AMERICAs', 'AMERICA Auditors', 'TBA', '2015-08-01', 'Liliana Niculae','2015-09-11',615,1-0.4991869918699187,0.4991869918699187);
insert into analytics.metrics_data values (null,6,4,'AMERICAs','AMERICAs', 'AMERICA Auditors', 'TBA', '2015-07-01', 'Liliana Niculae','2015-09-11',361,1- 206/361,206/361);

# AMERICAS - Timeliness
select * from analytics.metrics_data where `Metric Id` = 4;
insert into analytics.metrics_data values (null,4,17,'AMERICAs','US', 'Auditors - Food', 'TBA', '2015-08-01', 'Liliana Niculae','2015-09-08',622,36.49517685,0.2412);
insert into analytics.metrics_data values (null,4,17,'AMERICAs','US', 'Auditors - MS', 'TBA', '2015-08-01', 'Liliana Niculae','2015-09-08',3295,29.86919575,0.4734);

# AMERICAs - Learning
insert into analytics.metrics_data values (null,39,20,'AMERICAs','AMERICAs', 'QA', 'TBA', '2015-08-01', 'Rebecca Turco','2015-09-09',333,0.015015015,1-0.015015015);
insert into analytics.metrics_data values (null,40,20,'AMERICAs','AMERICAs', 'QA', 'TBA', '2015-08-01', 'Rebecca Turco','2015-09-09',122,0.024590164,1-0.024590164);
insert into analytics.metrics_data values (null,41,20,'AMERICAs','AMERICAs', 'Project Management-English', 'Mike Conklin', '2015-08-01', 'Rebecca Turco','2015-09-09',333,0.987987987987988,0.987987987987988);
insert into analytics.metrics_data values (null,42,20,'AMERICAs','AMERICAs', 'Project Management-Translations', 'Dominique Biliato', '2015-08-01', 'Rebecca Turco','2015-09-09',1671,0.998204667863555,0.998204667863555);

# September 2015
# Enlighten Efficiency
INSERT INTO analytics.metrics_data values (null,1,18,'APAC','n/a', 'IS Production AUS', 'n/a', '2015-09-01', 'Luca Contri','2015-10-01',2,0.651,0.651);
INSERT INTO analytics.metrics_data values (null,1,18,'APAC','n/a', 'News Services', 'n/a', '2015-09-01', 'Luca Contri','2015-10-01',13,0.694,0.694);
INSERT INTO analytics.metrics_data values (null,1,18,'APAC','n/a', 'Reference Services', 'n/a', '2015-09-01', 'Luca Contri','2015-10-01',8,0.761,0.761);
INSERT INTO analytics.metrics_data values (null,1,18,'APAC','n/a', 'SH&E Services', 'n/a', '2015-09-01', 'Luca Contri','2015-10-01',4,0.71,0.71);
INSERT INTO analytics.metrics_data values (null,2,18,'EMEA','n/a', 'AS EMEA CS Administration', 'n/a', '2015-09-01', 'Luca Contri','2015-10-01',12,0.571,0.571);
INSERT INTO analytics.metrics_data values (null,2,18,'EMEA','n/a', 'AS EMEA CS Scheduling', 'n/a', '2015-09-01', 'Luca Contri','2015-10-01',8,0.556,0.556);
INSERT INTO analytics.metrics_data values (null,2,18,'EMEA','n/a', 'AS EMEA SCM Operations', 'n/a', '2015-09-01', 'Luca Contri','2015-10-01',7,0.571,0.571);
INSERT INTO analytics.metrics_data values (null,2,18,'APAC','n/a', 'CS - Administration', 'n/a', '2015-09-01', 'Luca Contri','2015-10-01',11,0.5,0.5);
INSERT INTO analytics.metrics_data values (null,2,18,'APAC','n/a', 'Scheduling - MS', 'n/a', '2015-09-01', 'Luca Contri','2015-10-01',11,0.621,0.621);
INSERT INTO analytics.metrics_data values (null,2,18,'APAC','n/a', 'Scheduling - PS', 'n/a', '2015-09-01', 'Luca Contri','2015-10-01',5,0.671,0.671);

INSERT INTO analytics.metrics_data values (null,9,6,'AMERICAs','n/a', 'Client Service - AMERICAs', 'n/a', '2015-09-01', 'Terry Matney','2015-10-02',5,0.8425,0.8425);

INSERT INTO analytics.metrics_data values (null,39,20,'AMERICAs','n/a', 'QA', 'n/a', '2015-09-01', 'Rebecca Turco','2015-10-02',317,0.97,0.97);
INSERT INTO analytics.metrics_data values (null,40,20,'AMERICAs','n/a', 'QA', 'n/a', '2015-09-01', 'Rebecca Turco','2015-10-02',117,0.97,0.97);
INSERT INTO analytics.metrics_data values (null,41,20,'AMERICAs','n/a', 'Project Management-English', 'n/a', '2015-09-01', 'Rebecca Turco','2015-10-02',952,0.96,0.96);
INSERT INTO analytics.metrics_data values (null,42,20,'AMERICAs','n/a', 'Project Management-Translations', 'n/a', '2015-09-01', 'Rebecca Turco','2015-10-02',702,0.96,0.96);

INSERT INTO analytics.metrics_data values (null,34,13,'APAC','n/a', 'Reference Services', 'n/a', '2015-09-01', 'Maria Rechichi','2015-10-01',6328,1,1);
INSERT INTO analytics.metrics_data values (null,36,8,'APAC','n/a', 'News Services', 'n/a', '2015-09-01', 'Sam Elliott','2015-10-06',1,1,1);
INSERT INTO analytics.metrics_data values (null,35,8,'APAC','n/a', 'News Services', 'n/a', '2015-09-01', 'Sam Elliott','2015-10-06',64,0.859375,0.859375);
INSERT INTO analytics.metrics_data values (null,37,8,'APAC','n/a', 'SH&E Services', 'n/a', '2015-09-01', 'Sam Elliott','2015-10-06',4,1,1);

INSERT INTO analytics.metrics_data values (null,9,6,'APAC','n/a', 'Client Service - APAC', 'n/a', '2015-09-01', 'Amanda Dunlop','2015-10-05',12,0.7337,0.7337);
INSERT INTO analytics.metrics_data values (null,9,6,'EMEA','n/a', 'Client Service - EMEA', 'n/a', '2015-09-01', 'Amanda Dunlop','2015-10-05',4,0.483,0.483);

INSERT INTO analytics.metrics_data values (null,14,8,'APAC','n/a', 'IS Production AUS', 'n/a', '2015-09-01', 'Sian Lindsay','2015-10-07',121,1,1);
INSERT INTO analytics.metrics_data values (null,15,8,'APAC','n/a', 'IS Production AUS', 'n/a', '2015-09-01', 'Sian Lindsay','2015-10-07',61,1,1);

INSERT INTO analytics.metrics_data values (null,16,9,'EMEA','n/a', 'EMEA Food Auditors', 'n/a', '2015-09-01', 'Jessica Restall','2015-10-07',18,0.78,0.78);
INSERT INTO analytics.metrics_data values (null,16,9,'EMEA','n/a', 'EMEA SCM Auditors', 'n/a', '2015-09-01', 'Jessica Restall','2015-10-07',2,0.96,0.96);

INSERT INTO analytics.metrics_data values (null,6,4,'AMERICAs','n/a', 'AMERICA Auditors', 'n/a', '2015-09-01', 'Liliana Niculae','2015-10-05',389,0.68,0.68);
INSERT INTO analytics.metrics_data values (null,4,17,'AMERICAs','n/a', 'Ops - Food', 'n/a', '2015-09-01', 'Liliana Niculae','2015-10-05',257,0.6848,0.6848);
INSERT INTO analytics.metrics_data values (null,4,17,'AMERICAs','n/a', 'Ops - MS', 'n/a', '2015-09-01', 'Liliana Niculae','2015-10-06',979,0.85,0.85);
INSERT INTO analytics.metrics_data values (null,16,9,'AMERICAs','n/a', 'Canada Operations', 'n/a', '2015-09-01', 'Liliana Niculae','2015-10-06',23,.82,.82);
INSERT INTO analytics.metrics_data values (null,16,9,'AMERICAs','n/a', 'Mexico Operations', 'n/a', '2015-09-01', 'Liliana Niculae','2015-10-06',9,.46,.46);
INSERT INTO analytics.metrics_data values (null,16,9,'AMERICAs','n/a', 'US Operations', 'n/a', '2015-09-01', 'Liliana Niculae','2015-10-06',28,.76,.76);
INSERT INTO analytics.metrics_data values (null,39,20,'AMERICAs','n/a', 'QA', 'n/a', '2015-09-01', 'Rebecca Turco','2015-10-02',317,0.97,0.97);
INSERT INTO analytics.metrics_data values (null,40,20,'AMERICAs','n/a', 'QA', 'n/a', '2015-09-01', 'Rebecca Turco','2015-10-02',117,0.97,0.97);
INSERT INTO analytics.metrics_data values (null,41,20,'AMERICAs','n/a', 'Project Management-English', 'n/a', '2015-09-01', 'Rebecca Turco','2015-10-02',952,0.96,0.96);
INSERT INTO analytics.metrics_data values (null,42,20,'AMERICAs','n/a', 'Project Management-Translations', 'n/a', '2015-09-01', 'Rebecca Turco','2015-10-02',702,0.96,0.96);

INSERT INTO analytics.metrics_data values (null,49,20,'AMERICAs','n/a', 'Program Managers', 'n/a', '2015-09-01', 'Paul Hands/ Sandra Guadagnoli','2015-10-02',341,0.979472140762463,0.979472140762463);
INSERT INTO analytics.metrics_data values (null,50,25,'AMERICAs','n/a', 'Program Managers', 'n/a', '2015-09-01', 'Paul Hands/ Sandra Guadagnoli','2015-10-02',341,0.86217008797654,0.86217008797654);
INSERT INTO analytics.metrics_data values (null,44,21,'AMERICAs','n/a', 'Learning Support', 'n/a', '2015-09-01', 'Paul Hands/ Sandra Guadagnoli','2015-10-02',494,0.921052631578947,0.921052631578947);
INSERT INTO analytics.metrics_data values (null,45,20,'AMERICAs','n/a', 'Program Managers/Program Specialists', 'n/a', '2015-09-01', 'Paul Hands/ Sandra Guadagnoli','2015-10-02',248,0.931451612903226,0.931451612903226);
INSERT INTO analytics.metrics_data values (null,51,20,'AMERICAs','n/a', 'Professional Services Team', 'n/a', '2015-09-01', 'Paul Hands/ Sandra Guadagnoli','2015-10-02',128,0.96875,0.96875);
INSERT INTO analytics.metrics_data values (null,52,25,'AMERICAs','n/a', 'Professional Services Team', 'n/a', '2015-09-01', 'Paul Hands/ Sandra Guadagnoli','2015-10-02',128,0.96875,0.96875);
INSERT INTO analytics.metrics_data values (null,46,22,'AMERICAs','n/a', 'Learning Support', 'n/a', '2015-09-01', 'Paul Hands/ Sandra Guadagnoli','2015-10-02',2195,0.769476082004556,0.769476082004556);
INSERT INTO analytics.metrics_data values (null,47,23,'AMERICAs','n/a', 'C360 Support', 'n/a', '2015-09-01', 'Paul Hands/ Sandra Guadagnoli','2015-10-02',360,0.977777777777778,0.977777777777778);
INSERT INTO analytics.metrics_data values (null,48,24,'AMERICAs','n/a', 'Program Managers', 'n/a', '2015-09-01', 'Paul Hands/ Sandra Guadagnoli','2015-10-02',341,0.94,0.94);
INSERT INTO analytics.metrics_data values (null,53,20,'AMERICAs','n/a', 'Professional Services Team', 'n/a', '2015-09-01', 'Paul Hands/ Sandra Guadagnoli','2015-10-02',13,0.368421052631579,0.368421052631579);
INSERT INTO analytics.metrics_data values (null,54,20,'AMERICAs','n/a', 'Professional Services Team', 'n/a', '2015-09-01', 'Paul Hands/ Sandra Guadagnoli','2015-10-02',6,0.714285714285714,0.714285714285714);

# October 2015
# Enlighten Efficiency
INSERT INTO analytics.metrics_data values (null,1,18,'APAC','n/a', 'IS Production AUS', 'n/a', '2015-10-01', 'Luca Contri','2015-11-02',2,0.667,0.667);
INSERT INTO analytics.metrics_data values (null,1,18,'APAC','n/a', 'News Services', 'n/a', '2015-10-01', 'Luca Contri','2015-11-02',12,0.715,0.715);
INSERT INTO analytics.metrics_data values (null,1,18,'APAC','n/a', 'Reference Services', 'n/a', '2015-10-01', 'Luca Contri','2015-11-02',8,0.414,0.414);
INSERT INTO analytics.metrics_data values (null,1,18,'APAC','n/a', 'SH&E Services', 'n/a', '2015-10-01', 'Luca Contri','2015-11-02',5,0.652,0.652);
INSERT INTO analytics.metrics_data values (null,2,18,'EMEA','n/a', 'AS EMEA CS Administration', 'n/a', '2015-10-01', 'Luca Contri','2015-11-02',12,0.571,0.571);
INSERT INTO analytics.metrics_data values (null,2,18,'EMEA','n/a', 'AS EMEA CS Scheduling', 'n/a', '2015-10-01', 'Luca Contri','2015-11-02',8,0.568,0.568);
INSERT INTO analytics.metrics_data values (null,2,18,'EMEA','n/a', 'AS EMEA SCM Operations', 'n/a', '2015-10-01', 'Luca Contri','2015-11-02',7,0.552,0.552);
INSERT INTO analytics.metrics_data values (null,2,18,'APAC','n/a', 'CS - Administration', 'n/a', '2015-10-01', 'Luca Contri','2015-11-02',11,0.56,0.56);
INSERT INTO analytics.metrics_data values (null,2,18,'APAC','n/a', 'Scheduling - MS', 'n/a', '2015-10-01', 'Luca Contri','2015-11-02',9,0.672,0.672);
INSERT INTO analytics.metrics_data values (null,2,18,'APAC','n/a', 'Scheduling - PS', 'n/a', '2015-10-01', 'Luca Contri','2015-11-02',6,0.742,0.742);

INSERT INTO analytics.metrics_data values (null,39,20,'AMERICAs','n/a', 'QA', 'n/a', '2015-10-01', 'Rebecca Turco','2015-11-02',411,0.97,0.97);
INSERT INTO analytics.metrics_data values (null,40,20,'AMERICAs','n/a', 'QA', 'n/a', '2015-10-01', 'Rebecca Turco','2015-11-02',153,0.97,0.97);
INSERT INTO analytics.metrics_data values (null,41,20,'AMERICAs','n/a', 'Project Management-English', 'n/a', '2015-10-01', 'Rebecca Turco','2015-11-02',891,0.96,0.96);
INSERT INTO analytics.metrics_data values (null,42,20,'AMERICAs','n/a', 'Project Management-Translations', 'n/a', '2015-10-01', 'Rebecca Turco','2015-11-02',782,0.96,0.96);

INSERT INTO analytics.metrics_data values (null,9,6,'APAC','n/a', 'Client Service - APAC', 'n/a', '2015-10-01', 'Amanda Dunlop','2015-11-03',13,0.72,0.72);
INSERT INTO analytics.metrics_data values (null,9,6,'EMEA','n/a', 'Client Service - EMEA', 'n/a', '2015-10-01', 'Amanda Dunlop','2015-11-03',3,0.376,0.376);

INSERT INTO analytics.metrics_data values (null,14,8,'APAC','n/a', 'IS Production AUS', 'n/a', '2015-10-01', 'Sian Lindsay','2015-11-04',45,1,1);
INSERT INTO analytics.metrics_data values (null,15,8,'APAC','n/a', 'IS Production AUS', 'n/a', '2015-10-01', 'Sian Lindsay','2015-11-04',18,1,1);

INSERT INTO analytics.metrics_data values (null,10,6,'AMERICAs','n/a', 'Client Service - EHS', 'n/a', '2015-10-01', 'Terry Matney','2015-11-04',5,0.78,0.78);

INSERT INTO analytics.metrics_data values (null,6,4,'AMERICAs','n/a', 'AMERICA Auditors', 'n/a', '2015-10-01', 'Liliana Niculae','2015-11-05',423,0.61,0.61);
INSERT INTO analytics.metrics_data values (null,4,17,'AMERICAs','n/a', 'Ops - Food', 'n/a', '2015-10-01', 'Liliana Niculae','2015-11-05',341,0.69,0.69);
INSERT INTO analytics.metrics_data values (null,4,17,'AMERICAs','n/a', 'Ops - MS', 'n/a', '2015-10-01', 'Liliana Niculae','2015-11-05',1182,0.84,0.84);

INSERT INTO analytics.metrics_data values (null,49,26,'AMERICAs','n/a', 'Program Managers', 'n/a', '2015-10-01', 'Paul Hands/ Sandra Guadagnoli','2015-11-05',339,0.85,0.85);
INSERT INTO analytics.metrics_data values (null,50,27,'AMERICAs','n/a', 'Program Managers', 'n/a', '2015-10-01', 'Paul Hands/ Sandra Guadagnoli','2015-11-05',339,0.98,0.98);
INSERT INTO analytics.metrics_data values (null,44,21,'AMERICAs','n/a', 'Learning Support', 'n/a', '2015-10-01', 'Paul Hands/ Sandra Guadagnoli','2015-11-05',655,0.88,0.88);
INSERT INTO analytics.metrics_data values (null,45,25,'AMERICAs','n/a', 'Program Managers/Program Specialists', 'n/a', '2015-10-01', 'Paul Hands/ Sandra Guadagnoli','2015-11-05',2384,0.87,0.87);
INSERT INTO analytics.metrics_data values (null,51,26,'AMERICAs','n/a', 'Professional Services Team', 'n/a', '2015-10-01', 'Paul Hands/ Sandra Guadagnoli','2015-11-05',128,0.93,0.93);
INSERT INTO analytics.metrics_data values (null,52,27,'AMERICAs','n/a', 'Professional Services Team', 'n/a', '2015-10-01', 'Paul Hands/ Sandra Guadagnoli','2015-11-05',128,0.97,0.97);
INSERT INTO analytics.metrics_data values (null,53,25,'AMERICAs','n/a', 'Professional Services Team', 'n/a', '2015-10-01', 'Paul Hands/ Sandra Guadagnoli','2015-11-05',19,0.21,0.21);
INSERT INTO analytics.metrics_data values (null,54,25,'AMERICAs','n/a', 'Professional Services Team', 'n/a', '2015-10-01', 'Paul Hands/ Sandra Guadagnoli','2015-11-05',9,0,0);
INSERT INTO analytics.metrics_data values (null,46,22,'AMERICAs','n/a', 'Learning Support', 'n/a', '2015-10-01', 'Paul Hands/ Sandra Guadagnoli','2015-11-05',2171,1.16,1.16);
INSERT INTO analytics.metrics_data values (null,47,22,'AMERICAs','n/a', 'C360 Support', 'n/a', '2015-10-01', 'Paul Hands/ Sandra Guadagnoli','2015-11-05',538,1.15,1.15);
INSERT INTO analytics.metrics_data values (null,9,6,'AMERICAs','n/a', 'Client Service - GRC PS', 'n/a', '2015-10-01', 'Brent Jones','2015-11-05',9,0.68,0.68);
INSERT INTO analytics.metrics_data values (null,48,24,'AMERICAs','n/a', 'Program Managers', 'n/a', '2015-10-01', 'Paul Hands/ Sandra Guadagnoli','2015-11-05',339,0.95,0.95);

INSERT INTO analytics.metrics_data values (null,16,9,'EMEA','n/a', 'EMEA Agri Auditors', 'n/a', '2015-10-01', 'Jessica Restall','2015-11-09',60,0.734090909090909,0.734090909090909);
INSERT INTO analytics.metrics_data values (null,16,9,'EMEA','n/a', 'EMEA Food Auditors', 'n/a', '2015-10-01', 'Jessica Restall','2015-11-09',18,0.779527559055118,0.779527559055118);
INSERT INTO analytics.metrics_data values (null,16,9,'EMEA','n/a', 'EMEA Retail Auditors', 'n/a', '2015-10-01', 'Jessica Restall','2015-11-09',61,1,1);
INSERT INTO analytics.metrics_data values (null,16,9,'EMEA','n/a', 'EMEA SCM Auditors', 'n/a', '2015-10-01', 'Jessica Restall','2015-11-09',0,0,0);
INSERT INTO analytics.metrics_data values (null,6,4,'EMEA','n/a', 'EMEA Agri Auditors', 'n/a', '2015-10-01', 'Jessica Restall','2015-11-09',1320,1-0.0909090909090909,0.0909090909090909);
INSERT INTO analytics.metrics_data values (null,6,4,'EMEA','n/a', 'EMEA Retail Auditors', 'n/a', '2015-10-01', 'Jessica Restall','2015-11-09',1225,1-0.229387755102041,0.229387755102041);

INSERT INTO analytics.metrics_data values (null,16,9,'AMERICAs','n/a', 'Canada Operations', 'n/a', '2015-10-01', 'Liliana Niculae','2015-11-09',23,0.9718,0.9718);
INSERT INTO analytics.metrics_data values (null,16,9,'AMERICAs','n/a', 'Mexico Operations', 'n/a', '2015-10-01', 'Liliana Niculae','2015-11-09',9,0.55,0.55);
INSERT INTO analytics.metrics_data values (null,16,9,'AMERICAs','n/a', 'US Operations', 'n/a', '2015-10-01', 'Liliana Niculae','2015-11-09',28,0.9279,0.9279);

select * from analytics.metrics;

update analytics.metrics set 
`Value Definition` = '(# Clients in Green Status/total clients)*100',
`SLA Definition` = '(# Clients in Green Status/total clients)*100'
where Id in (51);