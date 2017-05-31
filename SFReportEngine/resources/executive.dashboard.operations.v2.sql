drop function analytics.`getMetricWeight`;
DELIMITER $$
CREATE FUNCTION `analytics`.`getMetricWeight`(in_region enum('APAC','EMEA','AMERICAs'), metric_id integer) RETURNS DOUBLE(18,10)
BEGIN
	DECLARE weight DOUBLE(18,10) DEFAULT null;
    DECLARE metric_group enum('Utilisation','Quality','Timeliness','Retention') DEFAULT null;
    DECLARE product_portfolio enum('Assurance','Learning','Knowledge','Risk') DEFAULT null;
    SET metric_group = (SELECT m.`Metric Group` from analytics.metrics2 m where `Id` = metric_id);
    SET product_portfolio = (SELECT m.`Product Portfolio` from analytics.metrics2 m where `Id` = metric_id);
    
    SET weight = (SELECT 
					IF(metric_group in ('Quality','Timeliness'),
						# Weights based on relative revenues
                        (select sum(`Revenues`) from analytics.metrics_revenues where `Region` = in_region and `Product Portfolio` = product_portfolio and `IsCurrent` = 1)/
                        (select sum(`Revenues`) from analytics.metrics_revenues where `Region` = in_region and `IsCurrent` = 1 and `Product Portfolio` in (select distinct m3.`Product Portfolio` from analytics.metrics2 m3 inner join metrics_regions mr3 on m3.Id = mr3.`Metric Id` where mr3.`Region` = in_region and m3.`Metric Group` = metric_group))/
                        (select count(m.`Id`) from analytics.metrics2 m inner join metrics_regions mr on m.Id = mr.`Metric Id` where mr.`Region` = in_region and m.`Metric Group` = metric_group and m.`Product Portfolio` = product_portfolio),
                         # Weights based on headcount
                         0
					)
				 );
        
    RETURN weight;
 END$$
DELIMITER ;

drop function `analytics`.`getMetricDataWeight`;
DELIMITER $$
CREATE FUNCTION `analytics`.`getMetricDataWeight`(metricdata_id integer) RETURNS DOUBLE(18,10)
# Calculate metric data weight relative to the other metric data in the same region, metric group and period.
BEGIN
	DECLARE _region enum('AMERICAs', 'APAC', 'EMEA') DEFAULT null;
    DECLARE _metric_group enum('Utilisation','Quality','Timeliness','Retention', 'Productivity') DEFAULT null;
    DECLARE _period DATE DEFAULT null;
    DECLARE metric_weight_equivalent DOUBLE(18,10) DEFAULT null;
    DECLARE mdweight DOUBLE(18,10) DEFAULT null;
    SET _region = (SELECT md.`Region` from analytics.metrics_data2 md where md.Id=metricdata_id);
    SET _metric_group = (SELECT m.`Metric Group` from analytics.metrics2 m inner join analytics.metrics_data2 md on md.`Metric Id` = m.`Id` where md.Id = metricdata_id);
    SET _period = (SELECT md.`Period` from analytics.metrics_data2 md where md.Id=metricdata_id);
    SET metric_weight_equivalent = (
		select md2.`Weight`/(
			select sum(t.`Weight`) from (
			select `Metric Group`, `Metric Id`, `Weight` 
				from analytics.metrics_data2 md 
				inner join analytics.metrics2 m on md.`Metric Id`=m.`Id` 
				where m.`Metric Group` = _metric_group 
				and md.`Region` = _region 
				and md.`Period`= _period group by m.Id) t)
		from analytics.metrics_data2 md2 where md2.Id=metricdata_id);
	
    SET mdweight = (select metric_weight_equivalent*md.`Volume`/(select sum(`Volume`) from analytics.metrics_data2 where `Metric Id` = m.Id and `Region` = md.`Region` and `Period`=md.`Period`)
				from analytics.metrics_data2 md
                inner join analytics.metrics2 m on md.`Metric Id` = m.`Id`
                where md.Id = metricdata_id);
        
    RETURN mdweight;
 END$$
DELIMITER ;

drop function `analytics`.`getNormalisedServiceLevel`;
DELIMITER $$
CREATE FUNCTION `analytics`.`getNormalisedServiceLevel`(slaValue double(18,10), targetAmber double(18,10), targetGreen double(18,10) ) RETURNS DOUBLE(18,10)
BEGIN
	DECLARE norm_sla DOUBLE(18,10) DEFAULT null;
    DECLARE targetAmberEquivalent DOUBLE(18,10);
    DECLARE targetGreenEquivalent DOUBLE(18,10);
    SET targetAmberEquivalent = 0.855;
    SET targetGreenEquivalent = 0.900;
    SET norm_sla = (SELECT 
		if(slaValue<=targetAmber and targetAmber<targetGreen, 
			(targetAmberEquivalent - (targetAmber-slaValue)*targetAmberEquivalent/targetAmber),
			if (slaValue>=targetGreen,
				if (targetGreen=1,
					targetGreenEquivalent,
					(targetGreenEquivalent + (slaValue-targetGreen)*(1- targetGreenEquivalent)/(1 - targetGreen))
				),
				if (targetAmber=targetGreen,
					slaValue*targetAmberEquivalent,
					targetGreenEquivalent - (targetGreen-slaValue)*(targetGreenEquivalent-targetAmberEquivalent)/(targetGreen-targetAmber)
				)
			)
		)
	);
        
    RETURN norm_sla;
 END$$
DELIMITER ;

select mr.`Metric ID`, mr.`Region`, m.`Metric Group`, m.`Product Portfolio`, m.`Metric`, getMetricWeight(mr.Region, mr.`Metric Id`) as 'Weight',
(select 
(select sum(`Revenues`) from analytics.metrics_revenues where `Region` = mr.Region and `Product Portfolio` = m.`Product Portfolio` and `IsCurrent` = 1)/
(select sum(`Revenues`) from analytics.metrics_revenues where `Region` = mr.Region and `IsCurrent` = 1 and `Product Portfolio` in (select distinct m3.`Product Portfolio` from analytics.metrics2 m3 inner join metrics_regions mr3 on m3.Id = mr3.`Metric Id` where mr3.`Region` = mr.`Region` and m3.`Metric Group` = m.`Metric Group`))/
(select count(m2.`Id`) from analytics.metrics2 m2 inner join metrics_regions mr2 on m2.Id = mr2.`Metric Id` where mr2.`Region` = mr.`Region` and m2.`Metric Group` = m.`Metric Group` and m2.`Product Portfolio` = m.`Product Portfolio`) 
) as 'Weight 2'
from analytics.Metrics_Regions mr
inner join analytics.metrics m on mr.`Metric Id` = m.Id
where m.`Metric Group` not in ('Utilisation')
order by mr.Region, m.`Metric Group`, m.`Product Portfolio`;

select 
(select sum(`Revenues`) from analytics.metrics_revenues where `Region` = 'AMERICAs' and `Product Portfolio` = 'Learning' and `IsCurrent` = 1)/
(select sum(`Revenues`) from analytics.metrics_revenues where `Region` = 'AMERICAs' and `IsCurrent` = 1)/
(select count(m.`Id`) from analytics.metrics2 m inner join metrics_regions mr on m.Id = mr.`Metric Id` where mr.`Region` = 'AMERICAs' and m.`Metric Group` = 'Quality' and m.`Product Portfolio` = 'Learning') as 'weight';


CREATE TABLE `analytics`.`metrics_regions` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `Metric Id` int(11) NOT NULL ,
  `Region` enum('APAC','EMEA','AMERICAs'),
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

CREATE TABLE `analytics`.`metrics2` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `Function` enum('Operations','Finance','Commercial','HR','EPMO','Technology') NOT NULL DEFAULT 'Operations',
  `Product Portfolio` enum('Assurance','Learning','Knowledge','Risk') NOT NULL,
  `Metric Group` enum('Utilisation','Quality','Timeliness','Retention') NOT NULL,
  `Metric` varchar(128) NOT NULL,
  `Volume Definition` text NOT NULL,
  `Volume Unit` varchar(64) NOT NULL,
  `Currency` varchar(3) DEFAULT NULL,
  `SLA Definition` text NOT NULL,
  `Reporting Period` enum('Year','Quarter','Month','Week','Day') NOT NULL DEFAULT 'Month',
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB AUTO_INCREMENT=55 DEFAULT CHARSET=utf8;

CREATE TABLE `analytics`.`metrics_data2` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `Metric Id` int(11) NOT NULL,
  `Region` enum('APAC','EMEA','AMERICAs') NOT NULL DEFAULT 'APAC',
  `SubRegion` text NOT NULL,
  `Team` varchar(128) NOT NULL,
  `Business Owner` varchar(128) DEFAULT NULL,
  `Period` date NOT NULL,
  `Prepared By` varchar(128) NOT NULL,
  `Prepared Date/Time` datetime NOT NULL,
  `Volume` double(18,10) NOT NULL,
  `SLA` double(18,10) NOT NULL,
  `Target Amber` double(18,10) NOT NULL,
  `Target Green` double(18,10) NOT NULL,
  `Weight` double(18,10) DEFAULT NULL,
  PRIMARY KEY (`Id`),
  UNIQUE KEY `Metric Id` (`Metric Id`,`Period`,`Team`,`Region`,`SubRegion`(128))
) ENGINE=InnoDB AUTO_INCREMENT=7821 DEFAULT CHARSET=utf8;

CREATE TABLE `analytics`.`metrics_revenues` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `Region` enum('APAC','EMEA','AMERICAs') NOT NULL DEFAULT 'APAC',
  `Product Portfolio` enum('Assurance','Learning','Knowledge','Risk') NOT NULL,
  `Business Line` varchar(64) NULL,
  `Revenues` DOUBLE (18,2) NOT NULL,
  `Last Updated` DATETIME NOT NULL,
  `IsCurrent` BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY (`Id`),
  UNIQUE KEY `Metric Revenue Id` (`Region`,`Product Portfolio`,`Business Line`,`Last Updated`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

insert into `analytics`.`metrics_revenues` VALUES (null, 'AMERICAs', 'Assurance', null,60.4,utc_timestamp(),1);
insert into `analytics`.`metrics_revenues` VALUES (null, 'AMERICAs', 'Learning', 'Assurance Training',6.4,utc_timestamp(),1);
insert into `analytics`.`metrics_revenues` VALUES (null, 'AMERICAs', 'Knowledge', null,6.6,utc_timestamp(),1);
insert into `analytics`.`metrics_revenues` VALUES (null, 'AMERICAs', 'Risk', 'Compliance',29.2,utc_timestamp(),1);
insert into `analytics`.`metrics_revenues` VALUES (null, 'AMERICAs', 'Risk', 'Cintellate',2.9,utc_timestamp(),1);
insert into `analytics`.`metrics_revenues` VALUES (null, 'AMERICAs', 'Learning', 'Risk Training',45.3,utc_timestamp(),1);
insert into `analytics`.`metrics_revenues` VALUES (null, 'APAC', 'Assurance', null,57.6,utc_timestamp(),1);
insert into `analytics`.`metrics_revenues` VALUES (null, 'APAC', 'Learning', 'Assurance Training',10.5,utc_timestamp(),1);
insert into `analytics`.`metrics_revenues` VALUES (null, 'APAC', 'Knowledge', null,56.3,utc_timestamp(),1);
insert into `analytics`.`metrics_revenues` VALUES (null, 'APAC', 'Risk', 'Compliance',4.9,utc_timestamp(),1);
insert into `analytics`.`metrics_revenues` VALUES (null, 'APAC', 'Risk', 'Cintellate',6.1,utc_timestamp(),1);
insert into `analytics`.`metrics_revenues` VALUES (null, 'APAC', 'Learning', 'Risk Learning',0.4,utc_timestamp(),1);
insert into `analytics`.`metrics_revenues` VALUES (null, 'EMEA', 'Assurance', null,51.5,utc_timestamp(),1);
insert into `analytics`.`metrics_revenues` VALUES (null, 'EMEA', 'Learning', 'Assurance Training',2.3,utc_timestamp(),1);
insert into `analytics`.`metrics_revenues` VALUES (null, 'EMEA', 'Knowledge', null,16.5,utc_timestamp(),1);
insert into `analytics`.`metrics_revenues` VALUES (null, 'EMEA', 'Risk', 'Compliance',0.4,utc_timestamp(),1);
insert into `analytics`.`metrics_revenues` VALUES (null, 'EMEA', 'Risk', 'Cintellate',1.2,utc_timestamp(),1);
insert into `analytics`.`metrics_revenues` VALUES (null, 'EMEA', 'Learning', 'Risk Training',9.2,utc_timestamp(),1);

# Metrics Input Template
set @target_period = '2016-12-01';
set @previous_target_period = '2016-11-01';
select t2.* from 
(select t.`Metric Id`, t.`Region`, t.`Product Portfolio`, t.`Metric Group`, t.`Metric`,t.`Team` as 'Business Unit', date_format(@target_period, '%b %y') as 'Period', t.`Volume Definition`, t.`Volume Unit`, t.`Volume`, t.`SLA Definition`, t.`Target Amber`, t.`Target Green`, t.`SLA`,  t.`Prepared Date/Time`, t.`Prepared By`, t.`Last Weight`
#,'=CONCATENATE("INSERT INTO analytics.metrics_data2 values (null,",[@[Metric Id]],",\'",[@Region],"\',\'n/a\', \'",[@[Business Unit]],"\', \'n/a\', \'",TEXT([@Period],"YYYY-MM-DD"),"\', \'",[@[Prepared By]],"\',\'",TEXT([@[Prepared Date/Time]],"YYYY-MM-DD"),"\',",[@Volume],",[@SLA],",[@[Target Amber]],",",[@[Target Green]],",",[@[Last Weight]],");")' as 'sql' 
from 
(select md.`Metric Id`, md.`Product Portfolio`, md.`Region`,md.`SubRegion`, m.`Metric Group`, m.`Metric`, md.`Team`, md.`Period`, m.`Volume Definition`, m.`Volume Unit`, if(`Period`=@target_period,md.`Volume`,'') as 'Volume', m.`SLA Definition`, md.`Target Amber`, md.`Target Green`, if(`Period`=@target_period,md.`SLA`,'') as 'SLA',  if(`Period`=@target_period,md.`Prepared Date/Time`,'') as 'Prepared Date/Time', md.`Prepared By`, md.`Weight` as 'Last Weight'
from analytics.metrics_data2 md
inner join analytics.metrics2 m on md.`Metric Id` = m.Id
where 
not(m.`Metric`='ARG Rejection' and md.`Team`='EMEA Food Auditors') # Not longer using this as breaking down by country
and not (m.`Metric`='ARG process time' and md.`Team`='EMEA Food Ops') # Not longer using this as breaking down by country
and md.`Period` in (@previous_target_period, @target_period)
order by `Metric Id`, `Team`,`Region`,`Period` desc) 
t group by `Metric Id`, `Team`,`Region`)
t2 
#where t2.`SLA` = ''
#and t2.`Prepared By` not like 'Luca Contri'
order by t2.`Region`, `Product Portfolio`, `Metric Group`, `Metric`;

set @period1 = '2016-08-01';
set @period2 = '2016-09-01';
# Metrics summary
select 
	m.Id,md.Id, m.`Metric Group`, md.`Region`, md.`Product Portfolio`, m.`Metric`, md.`Team` as 'Business Unit', 
	sum(if(md.`Period`=@period2, md.SLA,null)) as 'Service Level 2', sum(if(md.`Period`=@period2, md.`Target Green`,null)) as 'Target 2', max(if(md.`Period`=@period2, concat(round(md.`Volume`,0), ' ', m.`Volume Unit`),'')) as 'Volume 2', sum(if(md.`Period`=@period2, getNormalisedServiceLevel(md.`SLA`, md.`Target Amber`, md.`Target Green`),null)) as 'Norm Service Level 2', sum(if(md.`Period`=@period2, analytics.getMetricdataWeight(md.`Id`),0)) as 'Weight 2',#sum(if(md.`Period`=@period2, md.`Weight`*md.`Volume`/(select sum(`Volume`) from analytics.metrics_data2 where `Metric Id` = m.Id and `Region` = md.`Region` and `Period`=md.`Period`),null)) as 'Weight 2',sum(if(md.`Period`=@period2, md.`Weight`,0)),
    sum(if(md.`Period`=@period1, md.SLA,null)) as 'Service Level 1', sum(if(md.`Period`=@period1, md.`Target Green`,null)) as 'Target 1', max(if(md.`Period`=@period1, concat(round(md.`Volume`,0), ' ', m.`Volume Unit`),'')) as 'Volume 1', sum(if(md.`Period`=@period1, getNormalisedServiceLevel(md.`SLA`, md.`Target Amber`, md.`Target Green`),null)) as 'Norm Service Level 1', sum(if(md.`Period`=@period1, analytics.getMetricdataWeight(md.`Id`),0)) as 'Weight 1'#sum(if(md.`Period`=@period1, md.`Weight`*md.`Volume`/(select sum(`Volume`) from analytics.metrics_data2 where `Metric Id` = m.Id and `Region` = md.`Region` and `Period`=md.`Period`),null)) as 'Weight 1'
from analytics.metrics_data2 md
inner join analytics.metrics2 m on md.`Metric Id` = m.Id
where 
	md.`Region` in ('AMERICAs', 'APAC', 'EMEA')
	and m.`Metric Group` in ('Quality', 'Timeliness', 'Utilisation', 'Productivity')
    #and m.`Metric Group` in ('Productivity')
    and md.`Period` in (@period1, @period2)
group by md.`Region`, m.`Metric Group`, md.`Product Portfolio`, m.`Metric`, md.`Team`
order by field(md.`Region`,'AMERICAs', 'APAC', 'EMEA'), field(m.`Metric Group`, 'Quality', 'Timeliness', 'Utilisation', 'Productivity'), m.`Product Portfolio`, m.`Metric`, md.`Team`;

# Metrics summary
(select 
	md.Region, 
    m.`Metric Group`, 
    md.`Product Portfolio`, 
    date_format(md.`Period`,'%Y %m') as 'Period', 
    m.Metric, 
    md.SubRegion, 
    md.`Team`, 
    md.`Target Amber`, 
    md.`Target Green`, 
    md.`SLA` as 'Service Level',
    getNormalisedServiceLevel(md.`SLA`, md.`Target Amber`, md.`Target Green`) as 'Norm Service Level', 
    md.Weight, 
    md.Volume,
    md.Weight*md.Volume as 'WeightedVolume',
    getNormalisedServiceLevel(md.`SLA`, md.`Target Amber`, md.`Target Green`)*md.Weight*md.Volume as 'Weighted Norm Service Level'
from analytics.metrics_data2 md
inner join analytics.metrics2 m on md.`Metric Id` = m.Id
where 
	md.`Region` in ('AMERICAs', 'APAC', 'EMEA')
	and m.`Metric Group` in ('Quality', 'Timeliness', 'Utilisation', 'Productivity')
    and md.`Period`>='2015-07-01');

set @target_period = '2017-04-01';    
# Automated Metrics
# Assurance - Quality - ARG Rejections
insert into analytics.metrics_data2
(select 
null as 'Id',
6 as `Metric Id`,
r.`Region`,
'Assurance' as 'Product Portfolio',
group_concat(distinct r.Reporting_Business_Units__c) as 'SubRegion',
if(r.`Region` = 'EMEA',
	concat(r.`Country`, ' Food Auditors'),
    if(r.`Country` = 'Australia',
		if (r.Reporting_Business_Units__c like '%Food%', 'Australia Food Auditors', 'Australia MS Auditors'),
        concat(r.`Country`, ' Auditors')
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
date_format(str_to_date(r.`Period`,'%Y %m'), '%Y-%m-01') as '_Period',
'Luca Contri' as 'Prepared By',
utc_timestamp() as 'Prepared Date/Time',
sum(r.`Volume`) as 'Volume',
1 - sum(r.`Sum Value`)/sum(r.`Volume`) as 'SLA',
if (r.Reporting_Business_Units__c not like 'Asia%' and r.Reporting_Business_Units__c not like 'EMEA%' and r.Reporting_Business_Units__c like '%Food%',0.855,0.8740) as `Target Amber`,
if (r.Reporting_Business_Units__c not like 'Asia%' and r.Reporting_Business_Units__c not like 'EMEA%' and r.Reporting_Business_Units__c like '%Food%',0.9,0.92) as `Target Green`,
#(select md.`Weight` from analytics.metrics_data2 md where md.`Metric Id` = 6 and md.`Region` = r.`Region` order by md.Period desc limit 1) as 'Last Weight Used',
analytics.getMetricWeight(r.`Region`, 6) as 'Weight Calculated'
from analytics.global_ops_metrics_rejections_sub_v3 r 
where 
r.`Period` = date_format(@target_period, '%Y %m')
group by `Metric Id`, `Team`, `_Period`);

# Assurance - Timeliness - ARG Process Time
(select 
	null as 'Id',
    4 as 'Metric Id',
    t.`Region` as 'Region2',
    'Assurance' as 'Product Portfolio',
    analytics.getCountryFromRevenueOwnership(t.Revenue_Ownership__c) as 'SubRegion',
	concat(substring_index(analytics.getCountryFromRevenueOwnership(t.Revenue_Ownership__c), ' - ',-1), ' Food Ops') as 'Team',
    null as 'Business Owner',
    #DATE_FORMAT(t.`To`, '%Y-%m-01') as 'Period',
    str_to_date(concat(t.`Period`,' 01'), '%Y %m %d') as 'Period',
    'Luca Contri' as 'Prepared By',
    now() as 'Prepared Date/Time',
    count(distinct t.`Id`) as 'Volume',
    sum(if(t.`Sum Value`<=if(t.`Auto-Approved`,7,if(t.`Standards` like '%BRC%',42,21)),1,0))/count(distinct t.`Id`) as 'SLA',
		sum(if(t.`Sum Value`<=if(t.`Auto-Approved`,7,if(t.`Standards` like '%BRC%',42,21)),1,0)),
        count(distinct t.`Id`),
    0.9025 as 'Target Amber',
    0.95 as 'Target Green',
    analytics.getMetricWeight(if(t.Region like 'EMEA%', 'EMEA', 'APAC'), 4) as 'Weight Calculated'
    
from global_ops_metric_arg_end_to_end_2_v3_2 t
where str_to_date(concat(t.`Period`,' 01'), '%Y %m %d') = @target_period
#and analytics.getCountryFromRevenueOwnership(t.Revenue_Ownership__c) = 'UK'
and if(t.Standards like '%BRC%', t.Work_Item_Stages__c not like '%Follow%',true)
group by `Region`, `Team`, `Period`);

insert into analytics.metrics_data2
(select 
null as 'Id', 
4 as 'Metric Id',
if (t.Region like 'EMEA%', 'EMEA', 'APAC') as 'Region2',
'Assurance' as 'Product Portfolio',
if (t.Region like 'EMEA%', 'EMEA', 'APAC') as 'SubRegion',
	if(t.Region like 'Asia%', 
		concat(substring_index(t.Region,'-',-2), ' Ops'), 
		if(t.Region like 'EMEA%', 
			#'EMEA Food Auditors',
            concat(substring_index(t.Region,'-',-1), ' Food Ops'),
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
				'Tony Hardy, Heather Mahon, Carlie Compton'    
			)
		)
	) as 'Business Owner',
    DATE_FORMAT(t.`To`, '%Y-%m-01') as 'Period',
    'Luca Contri' as 'Prepared By',
    now() as 'Prepared Date/Time',
    count(distinct t.`Id`) as 'Volume',
    SUM(if(t.`To` <= t.`SLA Due`,1,0))/count(distinct t.`Id`) as 'SLA',
    0.9025 as 'Target Amber',
    0.95 as 'Target Green',
    #(select md.`Weight` from analytics.metrics_data2 md where md.`Metric Id` = 4 and md.`Region` = if(t.Region like 'EMEA%', 'EMEA', 'APAC') order by md.Period desc limit 1) as 'Last Weight Used',
	analytics.getMetricWeight(if(t.Region like 'EMEA%', 'EMEA', 'APAC'), 4) as 'Weight Calculated'
from analytics.sla_arg_v2 t
where
t.`To` is not null 
and t.`Region` not like '%Product%'
and t.`Metric` in ('ARG Process Time (BRC)', 'ARG Process Time (Other)')
and if(t.`Metric` in ('ARG Process Time (BRC)'), t.`Tags` not like '%Follow Up%', true)
and DATE_FORMAT(t.`To`, '%Y %m') = date_format(@target_period, '%Y %m')
GROUP BY `Region2`, `Team`, `Period`);

# Assurance - Utilisation
insert into analytics.metrics_data2 
select 
	null as Id, 
	16 as 'Metric Id',
    'APAC' as 'Region',
    'Assurance' as 'Product Portfolio',
    ftec.`Region` as 'SubRegion',
    'Australia Food Auditors' as 'Team',
    'Tony Hardy' as 'Business Owner',
	STR_TO_DATE(concat(ftec.`Period`, ' 01'), '%Y %m %d') as 'Period',
	'Luca Contri' as 'Prepared By',
	util.`Date` as 'Prepared Date/Time',
	ftec.`FTECount` as 'Volume',
	util.`Utilisation` as 'SLA', 
    0.7200000000 as 'Target Amber',
	0.8000000000 as 'Target Green',
    (select md.`Weight` from analytics.metrics_data2 md where md.`Metric Id` = 16 and md.`Region` = 'APAC' order by md.Period desc limit 1) as 'Last Weight Used'
    #.7005
from
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
            and `ColumnName` = date_format(@target_period, '%Y %m')
		order by Date desc) t
group by `Region`, `Period`) util on ftec.Region = util.Region and ftec.Period = util.Period
union
select 
	null as Id, 
	16 as 'Metric Id',
    'APAC' as 'Region',
    'Assurance' as 'Product Portfolio',
    ftec.`Region` as 'SubRegion',
    if (ftec.`Region`='Australia', 'Australia MS Auditors', concat(ftec.`Region`, ' Auditors')) as 'Team',
    if (ftec.`Region`='Australia', 'Tony Hardy', 'TBA') as 'Business Owner',
	STR_TO_DATE(concat(ftec.`Period`, ' 01'), '%Y %m %d') as 'Period',
	'Luca Contri' as 'Prepared By',
	util.`Date` as 'Prepared Date/Time',
	ftec.`FTECount` as 'Volume',
	util.`Utilisation` as 'SLA',
    0.7200000000 as 'Target Amber',
	0.8000000000 as 'Target Green',
    (select md.`Weight` from analytics.metrics_data2 md where md.`Metric Id` = 16 and md.`Region` = 'APAC' and md.`Product Portfolio` = 'Assurance' order by md.Period desc limit 1) as 'Last Weight Used'
    #.7005
from
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
            and `ColumnName` = date_format(@target_period, '%Y %m')
		order by Date desc) t
group by `Region`, `Period`) util on ftec.Region = util.Region and ftec.Period = util.Period;

select * from analytics.metrics_targets;
select * from analytics.metrics_data2 md where md.`Metric Id` = 16 and md.`Region` = 'APAC' and md.`Product Portfolio` = 'Assurance' order by md.Period desc limit 1;
# November 2015
# Enlighten Efficiency
INSERT INTO analytics.metrics_data2 values (null,1,'APAC','n/a', 'IS Production AUS', 'n/a', '2015-11-01', 'Luca Contri','2015-12-01',2,0.671, 0.6840000000, 0.7200000000, .1382);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC','n/a', 'News Services', 'n/a', '2015-11-01', 'Luca Contri','2015-12-01',12,0.764, 0.6840000000, 0.7200000000, .1382);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC','n/a', 'Reference Services', 'n/a', '2015-11-01', 'Luca Contri','2015-12-01',8,0.400,0.6840000000, 0.7200000000, .1382);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC','n/a', 'SH&E Services', 'n/a', '2015-11-01', 'Luca Contri','2015-12-01',5,0.686, 0.6840000000, 0.7200000000, .1382);

INSERT INTO analytics.metrics_data2 values (null,2,'APAC','n/a', 'CS - Administration', 'n/a', '2015-11-01', 'Luca Contri','2015-12-01',11,0.686,0.6840000000, 0.7200000000, .1060);
INSERT INTO analytics.metrics_data2 values (null,2,'APAC','n/a', 'Scheduling - MS', 'n/a', '2015-11-01', 'Luca Contri','2015-12-01',9,0.80,0.6840000000, 0.7200000000, .1060);
INSERT INTO analytics.metrics_data2 values (null,2,'APAC','n/a', 'Scheduling - PS', 'n/a', '2015-11-01', 'Luca Contri','2015-12-01',6,0.756,0.6840000000, 0.7200000000, .1060);

INSERT INTO analytics.metrics_data2 values (null,2,'EMEA','n/a', 'AS EMEA CS Administration', 'n/a', '2015-11-01', 'Luca Contri','2015-12-01',12,0.608,0.6840000000, 0.7200000000, .1852);
INSERT INTO analytics.metrics_data2 values (null,2,'EMEA','n/a', 'AS EMEA CS Scheduling', 'n/a', '2015-11-01', 'Luca Contri','2015-12-01',8,0.478,0.6840000000, 0.7200000000, .1852);
INSERT INTO analytics.metrics_data2 values (null,2,'EMEA','n/a', 'AS EMEA SCM Operations', 'n/a', '2015-11-01', 'Luca Contri','2015-12-01',7,0.5,0.6840000000, 0.7200000000, .1852);

INSERT INTO analytics.metrics_data2 values (null,16,'AMERICAs','n/a', 'Canada Operations', 'n/a', '2015-11-01', 'Liliana Niculae','2015-12-04',23,0.99,0.72,0.8,0.7125);
INSERT INTO analytics.metrics_data2 values (null,16,'AMERICAs','n/a', 'Mexico Operations', 'n/a', '2015-11-01', 'Liliana Niculae','2015-12-04',9,0.42,0.72,0.8,0.7125);
INSERT INTO analytics.metrics_data2 values (null,16,'AMERICAs','n/a', 'US Operations', 'n/a', '2015-11-01', 'Liliana Niculae','2015-12-04',28,0.69,0.72,0.8,0.7125);

# December 2015
# Enlighten Efficiency
INSERT INTO analytics.metrics_data2 values (null,1,'APAC','n/a', 'IS Production AUS', 'n/a', '2015-12-01', 'Luca Contri','2016-01-04',3,0.69, 0.684, 0.7200000000, .1422);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC','n/a', 'Legislation', 'n/a', '2015-12-01', 'Luca Contri','2016-01-04',17,0.496, 0.684, 0.7200000000, .1422);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC','n/a', 'Regulatory', 'n/a', '2015-12-01', 'Luca Contri','2016-01-04',6,0.822,0.684, 0.7200000000, .1422);

INSERT INTO analytics.metrics_data2 values (null,2,'APAC','n/a', 'CS - Administration', 'n/a', '2015-12-01', 'Luca Contri','2016-01-04',11,0.789,0.684, 0.7200000000, .1055);
INSERT INTO analytics.metrics_data2 values (null,2,'APAC','n/a', 'Scheduling - MS', 'n/a', '2015-12-01', 'Luca Contri','2016-01-04',9,0.781,0.684, 0.7200000000, .1055);
INSERT INTO analytics.metrics_data2 values (null,2,'APAC','n/a', 'Scheduling - PS', 'n/a', '2015-12-01', 'Luca Contri','2016-01-04',6,0.667,0.684, 0.7200000000, .1055);

INSERT INTO analytics.metrics_data2 values (null,2,'EMEA','n/a', 'AS EMEA CS Administration', 'n/a', '2015-12-01', 'Luca Contri','2016-01-04',12,0.579,0.684, 0.7200000000, .1852);
INSERT INTO analytics.metrics_data2 values (null,2,'EMEA','n/a', 'AS EMEA CS Scheduling', 'n/a', '2015-12-01', 'Luca Contri','2016-01-04',8,0.539,0.684, 0.7200000000, .1852);
INSERT INTO analytics.metrics_data2 values (null,2,'EMEA','n/a', 'AS EMEA SCM Operations', 'n/a', '2015-12-01', 'Luca Contri','2016-01-04',7,0.605,0.684, 0.7200000000, .1852);

INSERT INTO analytics.metrics_data2 values (null,14,'APAC','n/a', 'IS Production AUS', 'n/a', '2015-12-01', 'Sian Lindsay','2015-12-22',96,1,1,1,0.1648);
INSERT INTO analytics.metrics_data2 values (null,15,'APAC','n/a', 'IS Production AUS', 'n/a', '2015-12-01', 'Sian Lindsay','2015-12-22',87,1,1,1,0.1648);

INSERT INTO analytics.metrics_data2 values (null,9,'EMEA','n/a', 'Client Service - EMEA', 'n/a', '2015-12-01', 'Sam Edwards','2016-01-04',3,0.493,0.565,0.6,0.0158730159);

INSERT INTO analytics.metrics_data2 values (null,36,'APAC','n/a', 'News Services', 'n/a', '2015-12-01', 'Sam Elliott','2015-12-17',1,1,1,1,0.1648);
INSERT INTO analytics.metrics_data2 values (null,35,'APAC','n/a', 'News Services', 'n/a', '2015-12-01', 'Sam Elliott','2015-12-18',48,0.979,1,1,0.1648);
INSERT INTO analytics.metrics_data2 values (null,37,'APAC','n/a', 'SH&E Services', 'n/a', '2015-12-01', 'Sam Elliott','2015-12-22',4,1,1,1,0.1648);

INSERT INTO analytics.metrics_data2 values (null,9,'APAC','n/a', 'Client Service - APAC', 'n/a', '2015-12-01', 'Amanda Dunlop','2016-01-06',14,0.728,0.665,0.7,0.0553);

INSERT INTO analytics.metrics_data2 values (null,39,'AMERICAs','n/a', 'QA', 'n/a', '2015-12-01', 'Rebecca Turco','2016-01-05',392,0.966836734693878,0.95,1,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,40,'AMERICAs','n/a', 'QA', 'n/a', '2015-12-01', 'Rebecca Turco','2016-01-05',156,0.95,0.95,1,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,41,'AMERICAs','n/a', 'Project Management-English', 'n/a', '2015-12-01', 'Rebecca Turco','2016-01-05',392,0.98,0.95,1,0.116804636);
INSERT INTO analytics.metrics_data2 values (null,42,'AMERICAs','n/a', 'Project Management-Translations', 'n/a', '2015-12-01', 'Rebecca Turco','2016-01-05',156,0.96,0.95,1,0.116804636);

INSERT INTO analytics.metrics_data2 values (null,48,'AMERICAs','n/a', 'Program Managers', 'n/a', '2015-12-01', 'Sandra Guadagnoli','2016-01-04',336,0.96,0.75,0.8,0.225);
INSERT INTO analytics.metrics_data2 values (null,44,'AMERICAs','n/a', 'Learning Support', 'n/a', '2015-12-01', 'Sandra Guadagnoli','2016-01-04',744,0.91,0.8,0.85,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,50,'AMERICAs','n/a', 'Program Managers', 'n/a', '2015-12-01', 'Sandra Guadagnoli','2016-01-04',336,0.96,0.8,0.85,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,49,'AMERICAs','n/a', 'Program Managers', 'n/a', '2015-12-01', 'Sandra Guadagnoli','2016-01-04',336,0.85,0.8,0.85,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,45,'AMERICAs','n/a', 'Program Managers/Program Specialists', 'n/a', '2015-12-01', 'Sandra Guadagnoli','2016-01-04',2599,0.87,0.8,0.85,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,46,'AMERICAs','n/a', 'Learning Support', 'n/a', '2015-12-01', 'Sandra Guadagnoli','2016-01-04',2559,0.87,0.8,0.95,0.116804636);
INSERT INTO analytics.metrics_data2 values (null,10,'AMERICAs','n/a', 'Client Service - EHS', 'n/a', '2015-12-01', 'Sandra Guadagnoli','2016-01-04',5,0.76,0.665,0.7,0.0625);
INSERT INTO analytics.metrics_data2 values (null,10,'AMERICAs','n/a', 'Client Service - GRC PS', 'n/a', '2015-12-01', 'Sandra Guadagnoli','2016-01-04',9,0.74,0.5,0.57,0.0625);
INSERT INTO analytics.metrics_data2 values (null,52,'AMERICAs','n/a', 'Professional Services Team', 'n/a', '2015-12-01', 'Sandra Guadagnoli','2016-01-04',122,0.95,0.8,0.85,0.1128328992);
INSERT INTO analytics.metrics_data2 values (null,51,'AMERICAs','n/a', 'Professional Services Team', 'n/a', '2015-12-01', 'Sandra Guadagnoli','2016-01-04',122,0.91,0.8,0.85,0.1128328992);
INSERT INTO analytics.metrics_data2 values (null,53,'AMERICAs','n/a', 'Professional Services Team', 'n/a', '2015-12-01', 'Sandra Guadagnoli','2016-01-04',3,1,0.85,0.95,0.0752219328);
INSERT INTO analytics.metrics_data2 values (null,54,'AMERICAs','n/a', 'Professional Services Team', 'n/a', '2015-12-01', 'Sandra Guadagnoli','2016-01-04',3,0.33,0.85,0.95,0.0752219328);
INSERT INTO analytics.metrics_data2 values (null,47,'AMERICAs','n/a', 'C360 Support', 'n/a', '2015-12-01', 'Sandra Guadagnoli','2016-01-04',419,0.75,0.8,0.95,0.0752219328);
INSERT INTO analytics.metrics_data2 values (null,52,'AMERICAs','n/a', 'Client Services - EHS', 'n/a', '2015-12-01', 'Sandra Guadagnoli','2016-01-04',22,1,0.8,0.85,0.1128328992);
INSERT INTO analytics.metrics_data2 values (null,51,'AMERICAs','n/a', 'Client Services - EHS', 'n/a', '2015-12-01', 'Sandra Guadagnoli','2016-01-04',22,0.72,0.8,0.85,0.1128328992);

INSERT INTO analytics.metrics_data2 values (null,16,'AMERICAs','n/a', 'Canada Operations', 'n/a', '2015-12-01', 'Liliana Niculae','2016-01-07',23,0.7362,0.72,0.8,0.7125);
INSERT INTO analytics.metrics_data2 values (null,16,'AMERICAs','n/a', 'Mexico Operations', 'n/a', '2015-12-01', 'Liliana Niculae','2016-01-07',9,0.575,0.72,0.8,0.7125);
INSERT INTO analytics.metrics_data2 values (null,16,'AMERICAs','n/a', 'US Operations', 'n/a', '2015-12-01', 'Liliana Niculae','2016-01-07',28,0.9596,0.72,0.8,0.7125);
INSERT INTO analytics.metrics_data2 values (null,6,'AMERICAs','n/a', 'AMERICA Auditors', 'n/a', '2015-12-01', 'Liliana Niculae','2016-01-06',491,0.556,0.874,0.92,0.4239202938);
INSERT INTO analytics.metrics_data2 values (null,4,'AMERICAs','n/a', 'Ops - Food', 'n/a', '2015-12-01', 'Liliana Niculae','2016-01-06',336,0.57,0.9025,0.95,0.4239202938);
INSERT INTO analytics.metrics_data2 values (null,4,'AMERICAs','n/a', 'Ops - MS', 'n/a', '2015-12-01', 'Liliana Niculae','2016-01-06',1073,0.59,0.9025,0.95,0.4239202938);

INSERT INTO analytics.metrics_data2 values (null,16,'EMEA','n/a', 'EMEA Food Auditors', 'n/a', '2015-12-01', 'Jessica Restall','2016-01-11',18,0.67,0.72,0.8,0.3214);

# Jan 2016
INSERT INTO analytics.metrics_data2 values (null,9,'APAC', 'Risk', 'n/a', 'Client Service - APAC', 'n/a', '2016-01-01', 'Amanda Dunlop','2016-02-03 11:30:00',14,0.71,0.665,0.7,0.0732);
INSERT INTO analytics.metrics_data2 values (null,14,'APAC', 'Knowledge', 'n/a', 'IS Production AUS', 'n/a', '2016-01-01', 'Sian Lindsay','2016-02-03 10:55:00',5,1,1,1,0.1648);
INSERT INTO analytics.metrics_data2 values (null,15,'APAC', 'Knowledge', 'n/a', 'IS Production AUS', 'n/a', '2016-01-01', 'Sian Lindsay','2016-02-03 10:55:00',3,1,1,1,0.1648);

INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Knowledge', 'n/a', 'IS Production AUS', 'n/a', '2016-01-01', 'Luca Contri','2016-02-03',3,0.612, 0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Knowledge', 'n/a', 'Legislation', 'n/a', '2016-01-01', 'Luca Contri','2016-02-03',6,0.639, 0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Knowledge', 'n/a', 'Regulatory', 'n/a', '2016-01-01', 'Luca Contri','2016-02-03',17,0.558,0.684, 0.7200000000, 1);

INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Assurance' ,'n/a', 'CS - Administration', 'n/a', '2016-01-01', 'Luca Contri','2016-02-03',9,0.731,0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Assurance' ,'n/a', 'Scheduling - MS', 'n/a', '2016-01-01', 'Luca Contri','2016-02-03',7,0.826,0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Assurance' ,'n/a', 'Scheduling - PS', 'n/a', '2016-01-01', 'Luca Contri','2016-02-03',6,0.828,0.684, 0.7200000000, 1);

INSERT INTO analytics.metrics_data2 values (null,1,'EMEA', 'Assurance' ,'n/a', 'AS EMEA CS Administration', 'n/a', '2016-01-01', 'Luca Contri','2016-02-03',12,0.579,0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'EMEA', 'Assurance' ,'n/a', 'AS EMEA CS Scheduling', 'n/a', '2016-01-01', 'Luca Contri','2016-02-03',8,0.535,0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'EMEA', 'Assurance' ,'n/a', 'AS EMEA SCM Operations', 'n/a', '2016-01-01', 'Luca Contri','2016-02-03',7,0.597,0.684, 0.7200000000, 1);

INSERT INTO analytics.metrics_data2 values (null,36,'APAC','Knowledge','n/a', 'News Services', 'n/a', '2016-01-01', 'Sam Elliott','2015-01-08',1,1,1,1,0.1648);
INSERT INTO analytics.metrics_data2 values (null,35,'APAC','Knowledge','n/a', 'News Services', 'n/a', '2016-01-01', 'Sam Elliott','2015-01-08',64,1,1,1,0.1648);
INSERT INTO analytics.metrics_data2 values (null,37,'APAC','Knowledge','n/a', 'SH&E Services', 'n/a', '2016-01-01', 'Sam Elliott','2015-01-08',4,1,1,1,0.1648);

INSERT INTO analytics.metrics_data2 values (null,1,'AMERICAs','Assurance','n/a', 'AS Americas Operations - AS Americas Scheduling', 'n/a', '2016-01-01', 'Andre Szkodzinski','2016-02-03',15,0.68,0.684,0.72,1);
INSERT INTO analytics.metrics_data2 values (null,1,'AMERICAs','Assurance','n/a', 'AS Corp Ops, Accreditation & Quality - AS Quality Americas', 'n/a', '2016-01-01', 'Andre Szkodzinski','2016-02-03',8,0.66,0.684,0.72,1);
INSERT INTO analytics.metrics_data2 values (null,1,'AMERICAs','Assurance','n/a', 'AS Corp Ops, Accreditation & Quality - AS Technical Managers Americas', 'n/a', '2016-01-01', 'Andre Szkodzinski','2016-02-03',9,0.66,0.684,0.72,1);
INSERT INTO analytics.metrics_data2 values (null,1,'AMERICAs','Assurance','n/a', 'AS Finance Americas', 'n/a', '2016-01-01', 'Andre Szkodzinski','2016-02-03',9,0.72,0.684,0.72,1);

INSERT INTO analytics.metrics_data2 values (null,1,'AMERICAs','Learning','n/a', 'Content Operations - Content QA', 'n/a', '2016-01-01', 'Andre Szkodzinski','2016-02-03',2,0.65,0.684,0.72,1);
INSERT INTO analytics.metrics_data2 values (null,1,'AMERICAs','Learning','n/a', 'Content Operations - Courseware Development', 'n/a', '2016-01-01', 'Andre Szkodzinski','2016-02-03',3,0.64,0.684,0.72,1);
INSERT INTO analytics.metrics_data2 values (null,1,'AMERICAs','Learning','n/a', 'Content Operations - Graphic Design', 'n/a', '2016-01-01', 'Andre Szkodzinski','2016-02-03',3,0.79,0.684,0.72,1);
INSERT INTO analytics.metrics_data2 values (null,1,'AMERICAs','Learning','n/a', 'Content Operations - Instructional Design', 'n/a', '2016-01-01', 'Andre Szkodzinski','2016-02-03',2,0.68,0.684,0.72,1);
INSERT INTO analytics.metrics_data2 values (null,1,'AMERICAs','Learning','n/a', 'Content Operations - Production Media', 'n/a', '2016-01-01', 'Andre Szkodzinski','2016-02-03',1,0.52,0.684,0.72,1);
INSERT INTO analytics.metrics_data2 values (null,1,'AMERICAs','Learning','n/a', 'Content Operations - Project Management', 'n/a', '2016-01-01', 'Andre Szkodzinski','2016-02-03',4,0.59,0.684,0.72,1);
INSERT INTO analytics.metrics_data2 values (null,1,'AMERICAs','Learning','n/a', 'Content Operations - Translation Services', 'n/a', '2016-01-01', 'Andre Szkodzinski','2016-02-03',2,0.62,0.684,0.72,1);

INSERT INTO analytics.metrics_data2 values (null,1,'AMERICAs','Learning','n/a', 'AS Learning Improvement Solutions  - AS Americas LIS Operations', 'n/a', '2016-01-01', 'Andre Szkodzinski','2016-02-03',2,0.67,0.684,0.72,1);
INSERT INTO analytics.metrics_data2 values (null,1,'AMERICAs','Learning','n/a', 'AS Learning Improvement Solutions  - AS LIS Team', 'n/a', '2016-01-01', 'Andre Szkodzinski','2016-02-03',1,0.66,0.684,0.72,1);
INSERT INTO analytics.metrics_data2 values (null,1,'AMERICAs','Risk','n/a', 'Compliance Client Services - C360 Support', 'n/a', '2016-01-01', 'Andre Szkodzinski','2016-02-03',5,0.5,0.684,0.72,1);
INSERT INTO analytics.metrics_data2 values (null,1,'AMERICAs','Risk','n/a', 'Compliance Client Services - GRC Professional Services', 'n/a', '2016-01-01', 'Andre Szkodzinski','2016-02-03',15,0.6,0.684,0.72,1);
INSERT INTO analytics.metrics_data2 values (null,1,'AMERICAs','Risk','n/a', 'Compliance Client Services - Learning Support', 'n/a', '2016-01-01', 'Andre Szkodzinski','2016-02-03',5,0.62,0.684,0.72,1);
INSERT INTO analytics.metrics_data2 values (null,1,'AMERICAs','Risk','n/a', 'Compliance Client Services - Program Services - CM', 'n/a', '2016-01-01', 'Andre Szkodzinski','2016-02-03',7,0.56,0.684,0.72,1);
INSERT INTO analytics.metrics_data2 values (null,1,'AMERICAs','Risk','n/a', 'Compliance Client Services - Program Services - LR', 'n/a', '2016-01-01', 'Andre Szkodzinski','2016-02-03',7,0.63,0.684,0.72,1);
INSERT INTO analytics.metrics_data2 values (null,1,'AMERICAs','Risk','n/a', 'Compliance Client Services - Program Services - MID', 'n/a', '2016-01-01', 'Andre Szkodzinski','2016-02-03',5,0.59,0.684,0.72,1);
INSERT INTO analytics.metrics_data2 values (null,1,'AMERICAs','Risk','n/a', 'Compliance Client Services - Program Specialists - DS', 'n/a', '2016-01-01', 'Andre Szkodzinski','2016-02-03',12,0.6,0.684,0.72,1);

INSERT INTO analytics.metrics_data2 values (null,39,'AMERICAs', 'Learning', 'n/a', 'QA', 'n/a', '2016-01-01', 'Rebecca Turco','2016-02-06',338,0.93,0.95,1,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,40,'AMERICAs', 'Learning', 'n/a', 'QA', 'n/a', '2016-01-01', 'Rebecca Turco','2016-02-06',127,0.99,0.95,1,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,41,'AMERICAs', 'Learning', 'n/a', 'Project Management-English', 'n/a', '2016-01-01', 'Rebecca Turco','2016-02-06',890,0.93,0.95,1,0.116804636);
INSERT INTO analytics.metrics_data2 values (null,42,'AMERICAs', 'Learning', 'n/a', 'Project Management-Translations', 'n/a', '2016-01-01', 'Rebecca Turco','2016-02-06',507,0.94,0.95,1,0.116804636);

INSERT INTO analytics.metrics_data2 values (null,6,'AMERICAs', 'Assurance', 'n/a', 'AMERICA Auditors', 'n/a', '2016-01-01', 'Liliana Niculae','2016-02-07',303,0.5875,0.874,0.92,0.4239202938);
INSERT INTO analytics.metrics_data2 values (null,4,'AMERICAs', 'Assurance', 'n/a', 'Ops - Food', 'n/a', '2016-01-01', 'Liliana Niculae','2016-02-07',271,0.5793,0.9025,0.95,0.4239202938);
INSERT INTO analytics.metrics_data2 values (null,4,'AMERICAs', 'Assurance', 'n/a', 'Ops - MS', 'n/a', '2016-01-01', 'Liliana Niculae','2016-02-07',844,0.6955,0.9025,0.95,0.4239202938);
INSERT INTO analytics.metrics_data2 values (null,16,'AMERICAs', 'Assurance', 'n/a', 'Canada Operations', 'n/a', '2016-01-01', 'Liliana Niculae','2016-02-07',23,0.7,0.72,0.8,0.7125);
INSERT INTO analytics.metrics_data2 values (null,16,'AMERICAs', 'Assurance', 'n/a', 'Mexico Operations', 'n/a', '2016-01-01', 'Liliana Niculae','2016-02-07',9,0.56,0.72,0.8,0.7125);
INSERT INTO analytics.metrics_data2 values (null,16,'AMERICAs', 'Assurance', 'n/a', 'US Operations', 'n/a', '2016-01-01', 'Liliana Niculae','2016-02-07',28,0.78,0.72,0.8,0.7125);

INSERT INTO analytics.metrics_data2 values (null,9,'EMEA','Risk','n/a', 'Client Service - EMEA', 'n/a', '2016-01-01', 'Sam Edwards','2016-02-08',3,0.55,0.565,0.6,0.0536);

INSERT INTO analytics.metrics_data2 values (null,44,'AMERICAs','Learning','n/a', 'Learning Support', 'n/a', '2016-01-01', 'Sandra Guadagnoli','2016-02-08',340,0.93,0.8,0.85,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,50,'AMERICAs','Learning','n/a', 'Program Managers', 'n/a', '2016-01-01', 'Sandra Guadagnoli','2016-02-08',340,0.97,0.8,0.85,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,49,'AMERICAs','Learning','n/a', 'Program Managers', 'n/a', '2016-01-01', 'Sandra Guadagnoli','2016-02-08',340,0.87,0.8,0.85,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,45,'AMERICAs','Learning','n/a', 'Program Managers/Program Specialists', 'n/a', '2016-01-01', 'Sandra Guadagnoli','2016-02-08',2648,0.87,0.8,0.85,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,46,'AMERICAs','Learning','n/a', 'Learning Support', 'n/a', '2016-01-01', 'Sandra Guadagnoli','2016-02-08',5228,0.95,0.8,0.95,0.116804636);
INSERT INTO analytics.metrics_data2 values (null,48,'AMERICAs','Learning','n/a', 'Program Managers', 'n/a', '2016-01-01', 'Sandra Guadagnoli','2016-02-08',340,0.97,0.75,0.8,0.225);
INSERT INTO analytics.metrics_data2 values (null,52,'AMERICAs','Risk','n/a', 'Client Services - EHS', 'n/a', '2016-01-01', 'Sandra Guadagnoli','2016-02-08',22,1,0.8,0.85,0.1128328992);
INSERT INTO analytics.metrics_data2 values (null,52,'AMERICAs','Risk','n/a', 'Professional Services Team', 'n/a', '2016-01-01', 'Sandra Guadagnoli','2016-02-08',121,0.97,0.8,0.85,0.1128328992);
INSERT INTO analytics.metrics_data2 values (null,51,'AMERICAs','Risk','n/a', 'Client Services - EHS', 'n/a', '2016-01-01', 'Sandra Guadagnoli','2016-02-08',22,0.73,0.8,0.85,0.1128328992);
INSERT INTO analytics.metrics_data2 values (null,51,'AMERICAs','Risk','n/a', 'Professional Services Team', 'n/a', '2016-01-01', 'Sandra Guadagnoli','2016-02-08',121,0.93,0.8,0.85,0.1128328992);
INSERT INTO analytics.metrics_data2 values (null,53,'AMERICAs','Risk','n/a', 'Professional Services Team', 'n/a', '2016-01-01', 'Sandra Guadagnoli','2016-02-08',13,0.46,0.65,0.7,0.0752219328);
INSERT INTO analytics.metrics_data2 values (null,54,'AMERICAs','Risk','n/a', 'Professional Services Team', 'n/a', '2016-01-01', 'Sandra Guadagnoli','2016-02-08',13,0.23,0.65,0.7,0.0752219328);
INSERT INTO analytics.metrics_data2 values (null,47,'AMERICAs','Risk','n/a', 'C360 Support', 'n/a', '2016-01-01', 'Sandra Guadagnoli','2016-02-08',549,0.82,0.8,0.95,0.0752219328);
INSERT INTO analytics.metrics_data2 values (null,10,'AMERICAs','Risk','n/a', 'Client Service - EHS', 'n/a', '2016-01-01', 'Sandra Guadagnoli','2016-02-08',5,0.73,0.665,0.7,0.0625);
INSERT INTO analytics.metrics_data2 values (null,10,'AMERICAs','Risk','n/a', 'Client Service - GRC PS', 'n/a', '2016-01-01', 'Sandra Guadagnoli','2016-02-08',11,0.59,0.5,0.57,0.0625);

# Feb 2016
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Knowledge', 'n/a', 'IS Production AUS', 'n/a', '2016-02-01', 'Luca Contri','2016-03-01',3,.596, 0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Knowledge', 'n/a', 'Legislation', 'n/a', '2016-02-01', 'Luca Contri','2016-03-01',6,0.643, 0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Knowledge', 'n/a', 'Regulatory', 'n/a', '2016-02-01', 'Luca Contri','2016-03-01',17,0.631,0.684, 0.7200000000, 1);

INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Assurance' ,'n/a', 'CS - Administration', 'n/a', '2016-02-01', 'Luca Contri','2016-03-01',9,0.715,0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Assurance' ,'n/a', 'Scheduling - MS', 'n/a', '2016-02-01', 'Luca Contri','2016-03-01',7,0.804,0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Assurance' ,'n/a', 'Scheduling - PS', 'n/a', '2016-02-01', 'Luca Contri','2016-03-01',6,0.869,0.684, 0.7200000000, 1);

INSERT INTO analytics.metrics_data2 values (null,1,'EMEA', 'Assurance' ,'n/a', 'AS EMEA CS Administration', 'n/a', '2016-02-01', 'Luca Contri','2016-03-01',12,0.587,0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'EMEA', 'Assurance' ,'n/a', 'AS EMEA CS Scheduling', 'n/a', '2016-02-01', 'Luca Contri','2016-03-01',8,0.555,0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'EMEA', 'Assurance' ,'n/a', 'AS EMEA SCM Operations', 'n/a', '2016-02-01', 'Luca Contri','2016-03-01',7,0.588,0.684, 0.7200000000, 1);

INSERT INTO analytics.metrics_data2 values (null,34,'APAC','Knowledge', 'n/a', 'Reference Services', 'n/a', '2016-02-01', 'Sam Elliott','2016-03-03',128,1,0.9998,0.9998,0.1648);
INSERT INTO analytics.metrics_data2 values (null,36,'APAC','Knowledge', 'n/a', 'News Services', 'n/a', '2016-02-01', 'Sam Elliott','2016-03-03',1,1,1,1,0.1648);
INSERT INTO analytics.metrics_data2 values (null,35,'APAC','Knowledge', 'n/a', 'News Services', 'n/a', '2016-02-01', 'Sam Elliott','2016-03-03',64,1,1,1,0.1648);
INSERT INTO analytics.metrics_data2 values (null,37,'APAC','Knowledge', 'n/a', 'SH&E Services', 'n/a', '2016-02-01', 'Sam Elliott','2016-03-03',4,1,1,1,0.1648);

INSERT INTO analytics.metrics_data2 values (null,14,'APAC','Knowledge', 'n/a', 'IS Production AUS', 'n/a', '2016-02-01', 'Sian Lindsay','2016-03-03',49,1,1,1,0.1648);
INSERT INTO analytics.metrics_data2 values (null,15,'APAC','Knowledge', 'n/a', 'IS Production AUS', 'n/a', '2016-02-01', 'Sian Lindsay','2016-03-03',28,1,1,1,0.1648);

INSERT INTO analytics.metrics_data2 values (null,9,'APAC','Risk','n/a', 'Client Service - APAC', 'n/a', '2016-02-01', 'Amanda Dunlop','2016-03-03',13,0.6791,0.665,0.7,0.0732);

INSERT INTO analytics.metrics_data2 values (null,48,'AMERICAs','Learning','n/a', 'Program Managers', 'n/a', '2016-02-01', 'Sandra Guadagnoli','2016-03-01',343,0.98,0.75,0.8,0.225);
INSERT INTO analytics.metrics_data2 values (null,44,'AMERICAs','Learning','n/a', 'Learning Support', 'n/a', '2016-02-01', 'Sandra Guadagnoli','2016-03-01',343,0.88,0.8,0.85,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,50,'AMERICAs','Learning','n/a', 'Program Managers', 'n/a', '2016-02-01', 'Sandra Guadagnoli','2016-03-01',343,0.98,0.8,0.85,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,49,'AMERICAs','Learning','n/a', 'Program Managers', 'n/a', '2016-02-01', 'Sandra Guadagnoli','2016-03-01',343,0.883381924198251,0.8,0.85,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,45,'AMERICAs','Learning','n/a', 'Program Managers/Program Specialists', 'n/a', '2016-02-01', 'Sandra Guadagnoli','2016-03-01',2736,0.878289473684211,0.8,0.85,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,46,'AMERICAs','Learning','n/a', 'Learning Support', 'n/a', '2016-02-01', 'Sandra Guadagnoli','2016-03-01',3979,0.942447851218899,0.8,0.95,0.116804636);
INSERT INTO analytics.metrics_data2 values (null,10,'AMERICAs','Risk','n/a', 'Client Service - EHS', 'n/a', '2016-02-01', 'Sandra Guadagnoli','2016-03-01',5,0.7,0.665,0.7,0.0625);
INSERT INTO analytics.metrics_data2 values (null,10,'AMERICAs','Risk','n/a', 'Client Service - GRC PS', 'n/a', '2016-02-01', 'Sandra Guadagnoli','2016-03-01',10,0.5622,0.5,0.57,0.0625);
INSERT INTO analytics.metrics_data2 values (null,52,'AMERICAs','Risk','n/a', 'Client Services - EHS', 'n/a', '2016-02-01', 'Sandra Guadagnoli','2016-03-01',23,1,0.8,0.85,0.1128328992);
INSERT INTO analytics.metrics_data2 values (null,52,'AMERICAs','Risk','n/a', 'Professional Services Team', 'n/a', '2016-02-01', 'Sandra Guadagnoli','2016-03-01',122,0.975409836065574,0.8,0.85,0.1128328992);
INSERT INTO analytics.metrics_data2 values (null,51,'AMERICAs','Risk','n/a', 'Client Services - EHS', 'n/a', '2016-02-01', 'Sandra Guadagnoli','2016-03-01',23,0.826086956521739,0.8,0.85,0.1128328992);
INSERT INTO analytics.metrics_data2 values (null,51,'AMERICAs','Risk','n/a', 'Professional Services Team', 'n/a', '2016-02-01', 'Sandra Guadagnoli','2016-03-01',122,0.926229508196721,0.8,0.85,0.1128328992);
INSERT INTO analytics.metrics_data2 values (null,53,'AMERICAs','Risk','n/a', 'Professional Services Team', 'n/a', '2016-02-01', 'Sandra Guadagnoli','2016-03-01',8,0.75,0.65,0.7,0.0752219328);
INSERT INTO analytics.metrics_data2 values (null,54,'AMERICAs','Risk','n/a', 'Professional Services Team', 'n/a', '2016-02-01', 'Sandra Guadagnoli','2016-03-01',6,0.333333333333333,0.65,0.7,0.0752219328);
INSERT INTO analytics.metrics_data2 values (null,47,'AMERICAs','Risk','n/a', 'C360 Support', 'n/a', '2016-02-01', 'Sandra Guadagnoli','2016-03-01',652,0.756134969325153,0.8,0.95,0.0752219328);

INSERT INTO analytics.metrics_data2 values (null,16,'AMERICAs','Assurance', 'n/a', 'Canada Operations', 'n/a', '2016-02-01', 'Liliana Niculae','2016-03-04',27,0.871697197622225,0.72,0.8,0.7125);
INSERT INTO analytics.metrics_data2 values (null,16,'AMERICAs','Assurance', 'n/a', 'Mexico Operations', 'n/a', '2016-02-01', 'Liliana Niculae','2016-03-04',6,0.569727891156463,0.72,0.8,0.7125);
INSERT INTO analytics.metrics_data2 values (null,16,'AMERICAs','Assurance', 'n/a', 'US Operations', 'n/a', '2016-02-01', 'Liliana Niculae','2016-03-04',31,0.951439670932358,0.72,0.8,0.7125);
INSERT INTO analytics.metrics_data2 values (null,6,'AMERICAs','Assurance', 'n/a', 'AMERICA Auditors', 'n/a', '2016-02-01', 'Liliana Niculae','2016-03-04',295,0.6373,0.874,0.92,0.4239202938);
INSERT INTO analytics.metrics_data2 values (null,4,'AMERICAs','Assurance', 'n/a', 'Ops - Food', 'n/a', '2016-02-01', 'Liliana Niculae','2016-03-04',253,0.6126,0.9025,0.95,0.4239202938);
INSERT INTO analytics.metrics_data2 values (null,4,'AMERICAs','Assurance', 'n/a', 'Ops - MS', 'n/a', '2016-02-01', 'Liliana Niculae','2016-03-04',695,0.6849,0.9025,0.95,0.4239202938);

INSERT INTO analytics.metrics_data2 values (null,39,'AMERICAs','Learning','n/a', 'QA', 'n/a', '2016-02-01', 'Rebecca Turco','2016-03-04',364,0.96,0.95,1,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,40,'AMERICAs','Learning','n/a', 'QA', 'n/a', '2016-02-01', 'Rebecca Turco','2016-03-04',164,0.92,0.95,1,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,41,'AMERICAs','Learning','n/a', 'Project Management-English', 'n/a', '2016-02-01', 'Rebecca Turco','2016-03-04',777,0.93,0.95,1,0.116804636);
INSERT INTO analytics.metrics_data2 values (null,42,'AMERICAs','Learning','n/a', 'Project Management-Translations', 'n/a', '2016-02-01', 'Rebecca Turco','2016-03-04',911,0.89,0.95,1,0.116804636);

# Mar 2016
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Knowledge', 'n/a', 'IS Production AUS', 'n/a', '2016-03-01', 'Luca Contri','2016-04-04',3,.792, 0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Knowledge', 'n/a', 'Legislation', 'n/a', '2016-03-01', 'Luca Contri','2016-04-04',6,0.645, 0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Knowledge', 'n/a', 'Regulatory', 'n/a', '2016-03-01', 'Luca Contri','2016-04-04',17,0.782,0.684, 0.7200000000, 1);

INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Assurance' ,'n/a', 'CS - Administration', 'n/a', '2016-03-01', 'Luca Contri','2016-04-04',9,0.786,0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Assurance' ,'n/a', 'Scheduling - MS', 'n/a', '2016-03-01', 'Luca Contri','2016-04-04',7,0.705,0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Assurance' ,'n/a', 'Scheduling - PS', 'n/a', '2016-03-01', 'Luca Contri','2016-04-04',6,0.967,0.684, 0.7200000000, 1);

INSERT INTO analytics.metrics_data2 values (null,1,'EMEA', 'Assurance' ,'n/a', 'AS EMEA CS Administration', 'n/a', '2016-03-01', 'Luca Contri','2016-04-04',12,0.640,0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'EMEA', 'Assurance' ,'n/a', 'AS EMEA CS Scheduling', 'n/a', '2016-03-01', 'Luca Contri','2016-04-04',8,0.564,0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'EMEA', 'Assurance' ,'n/a', 'AS EMEA SCM Operations', 'n/a', '2016-03-01', 'Luca Contri','2016-04-04',7,0.641,0.684, 0.7200000000, 1);

INSERT INTO analytics.metrics_data2 values (null,1,'AMERICAs','Assurance','n/a', 'AS Americas Operations - AS Americas Scheduling', 'n/a', '2016-03-01', 'Andre Szkodzinski','2016-04-04',15,0.74,0.684,0.72,1);
INSERT INTO analytics.metrics_data2 values (null,1,'AMERICAs','Assurance','n/a', 'AS Corp Ops, Accreditation & Quality - AS Quality Americas', 'n/a', '2016-03-01', 'Andre Szkodzinski','2016-04-04',9,0.78,0.684,0.72,1);
INSERT INTO analytics.metrics_data2 values (null,1,'AMERICAs','Assurance','n/a', 'AS Corp Ops, Accreditation & Quality - AS Technical Managers Americas', 'n/a', '2016-03-01', 'Andre Szkodzinski','2016-04-04',11,0.72,0.684,0.72,1);
INSERT INTO analytics.metrics_data2 values (null,1,'AMERICAs','Assurance','n/a', 'AS Finance Americas', 'n/a', '2016-03-01', 'Andre Szkodzinski','2016-04-04',10,0.74,0.684,0.72,1);
INSERT INTO analytics.metrics_data2 values (null,1,'AMERICAs','Learning','n/a', 'AS Learning Improvement Solutions â”¬Ã¡- AS Americas LIS Operations', 'n/a', '2016-03-01', 'Andre Szkodzinski','2016-04-04',2,0.69,0.684,0.72,1);
INSERT INTO analytics.metrics_data2 values (null,1,'AMERICAs','Learning','n/a', 'AS Learning Improvement Solutions â”¬Ã¡- AS LIS Team', 'n/a', '2016-03-01', 'Andre Szkodzinski','2016-04-04',3,0.7,0.684,0.72,1);

INSERT INTO analytics.metrics_data2 values (null,9,'APAC','Risk','n/a', 'Client Service - APAC', 'n/a', '2016-03-01', 'Amanda Dunlop','2016-04-05',14,0.7052,0.665,0.7,0.0732);

INSERT INTO analytics.metrics_data2 values (null,14,'APAC','Knowledge','n/a', 'IS Production AUS', 'n/a', '2016-03-01', 'Sian Lindsay','2016-04-05',39,1,1,1,0.1648);
INSERT INTO analytics.metrics_data2 values (null,15,'APAC','Knowledge','n/a', 'IS Production AUS', 'n/a', '2016-03-01', 'Sian Lindsay','2016-04-05',23,1,1,1,0.1648);

INSERT INTO analytics.metrics_data2 values (null,16,'AMERICAs','Assurance','n/a', 'Canada Operations', 'n/a', '2016-03-01', 'Naupreet Grewal','2016-04-05',27,0.8717,0.72,0.8,0.7125);
INSERT INTO analytics.metrics_data2 values (null,16,'AMERICAs','Assurance','n/a', 'Mexico Operations', 'n/a', '2016-03-01', 'Naupreet Grewal','2016-04-05',6,0.5697,0.72,0.8,0.7125);
INSERT INTO analytics.metrics_data2 values (null,16,'AMERICAs','Assurance','n/a', 'US Operations', 'n/a', '2016-03-01', 'Naupreet Grewal','2016-04-05',31,0.9514,0.72,0.8,0.7125);
INSERT INTO analytics.metrics_data2 values (null,6,'AMERICAs','Assurance','n/a', 'AMERICA Auditors', 'n/a', '2016-03-01', 'Naupreet Grewal','2016-04-04',335,0.6299,0.874,0.92,0.4239202938);
INSERT INTO analytics.metrics_data2 values (null,4,'AMERICAs','Assurance','n/a', 'Ops - Food', 'n/a', '2016-03-01', 'Naupreet Grewal','2016-04-04',282,0.6454,0.9025,0.95,0.4239202938);
INSERT INTO analytics.metrics_data2 values (null,4,'AMERICAs','Assurance','n/a', 'Ops - MS', 'n/a', '2016-03-01', 'Naupreet Grewal','2016-04-04',642,0.7399,0.9025,0.95,0.4239202938);

INSERT INTO analytics.metrics_data2 values (null,39,'AMERICAs','Learning','n/a', 'QA', 'n/a', '2016-03-01', 'Rebecca Turco','2016-04-06',437,0.96,0.95,1,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,40,'AMERICAs','Learning','n/a', 'QA', 'n/a', '2016-03-01', 'Rebecca Turco','2016-04-06',249,0.91,0.95,1,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,41,'AMERICAs','Learning','n/a', 'Project Management-English', 'n/a', '2016-03-01', 'Rebecca Turco','2016-04-06',923,0.97,0.95,1,0.116804636);
INSERT INTO analytics.metrics_data2 values (null,42,'AMERICAs','Learning','n/a', 'Project Management-Translations', 'n/a', '2016-03-01', 'Rebecca Turco','2016-04-06',844,0.97,0.95,1,0.116804636);

INSERT INTO analytics.metrics_data2 values (null,48,'AMERICAs','Learning','n/a', 'Program Managers', 'n/a', '2016-03-01', 'Sandra Guadagnoli','2016-04-05',340,0.99,0.75,0.8,0.225);
INSERT INTO analytics.metrics_data2 values (null,44,'AMERICAs','Learning','n/a', 'Learning Support', 'n/a', '2016-03-01', 'Sandra Guadagnoli','2016-04-05',546,0.88,0.8,0.85,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,50,'AMERICAs','Learning','n/a', 'Program Managers', 'n/a', '2016-03-01', 'Sandra Guadagnoli','2016-04-05',340,0.96,0.8,0.85,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,49,'AMERICAs','Learning','n/a', 'Program Managers', 'n/a', '2016-03-01', 'Sandra Guadagnoli','2016-04-05',340,0.88,0.8,0.85,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,45,'AMERICAs','Learning','n/a', 'Program Managers/Program Specialists', 'n/a', '2016-03-01', 'Sandra Guadagnoli','2016-04-05',2871,0.88,0.8,0.85,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,46,'AMERICAs','Learning','n/a', 'Learning Support', 'n/a', '2016-03-01', 'Sandra Guadagnoli','2016-04-05',1950,0.87,0.8,0.95,0.116804636);
INSERT INTO analytics.metrics_data2 values (null,10,'AMERICAs','Risk','n/a', 'Client Service - EHS', 'n/a', '2016-03-01', 'Sandra Guadagnoli','2016-04-05',5,0.76,0.665,0.7,0.0625);
INSERT INTO analytics.metrics_data2 values (null,10,'AMERICAs','Risk','n/a', 'Client Service - GRC PS', 'n/a', '2016-03-01', 'Sandra Guadagnoli','2016-04-05',11,0.63,0.5,0.57,0.0625);
INSERT INTO analytics.metrics_data2 values (null,52,'AMERICAs','Risk','n/a', 'Client Services - EHS', 'n/a', '2016-03-01', 'Sandra Guadagnoli','2016-04-05',25,1,0.8,0.85,0.1128328992);
INSERT INTO analytics.metrics_data2 values (null,52,'AMERICAs','Risk','n/a', 'Professional Services Team', 'n/a', '2016-03-01', 'Sandra Guadagnoli','2016-04-05',126,0.96,0.8,0.85,0.1128328992);
INSERT INTO analytics.metrics_data2 values (null,51,'AMERICAs','Risk','n/a', 'Client Services - EHS', 'n/a', '2016-03-01', 'Sandra Guadagnoli','2016-04-05',25,0.84,0.8,0.85,0.1128328992);
INSERT INTO analytics.metrics_data2 values (null,51,'AMERICAs','Risk','n/a', 'Professional Services Team', 'n/a', '2016-03-01', 'Sandra Guadagnoli','2016-04-05',125,0.9,0.8,0.85,0.1128328992);
INSERT INTO analytics.metrics_data2 values (null,53,'AMERICAs','Risk','n/a', 'Professional Services Team', 'n/a', '2016-03-01', 'Sandra Guadagnoli','2016-04-05',11,0.72,0.65,0.7,0.0752219328);
INSERT INTO analytics.metrics_data2 values (null,54,'AMERICAs','Risk','n/a', 'Professional Services Team', 'n/a', '2016-03-01', 'Sandra Guadagnoli','2016-04-05',5,0,0.65,0.7,0.0752219328);
INSERT INTO analytics.metrics_data2 values (null,47,'AMERICAs','Risk','n/a', 'C360 Support', 'n/a', '2016-03-01', 'Sandra Guadagnoli','2016-04-05',582,0.95,0.8,0.95,0.0752219328);

INSERT INTO analytics.metrics_data2 values (null,16,'EMEA','Assurance','n/a', 'EMEA Food Auditors', 'n/a', '2016-03-01', 'Luca Contri','2016-04-08',17,0.8598,0.72,0.8,0.3214);

INSERT INTO analytics.metrics_data2 values (null,9,'EMEA','Risk','n/a', 'Client Service - EMEA', 'n/a', '2016-03-01', 'Sam Edwards','2016-04-11',3,0.653,0.565,0.6,0.0536);

INSERT INTO analytics.metrics_data2 values (null,36,'APAC','Knowledge','n/a', 'News Services', 'n/a', '2016-03-01', 'Sam Elliott','2016-04-13',1,1,1,1,0.1648);
INSERT INTO analytics.metrics_data2 values (null,35,'APAC','Knowledge','n/a', 'News Services', 'n/a', '2016-03-01', 'Sam Elliott','2016-04-13',62,62/64,1,1,0.1648);
INSERT INTO analytics.metrics_data2 values (null,37,'APAC','Knowledge','n/a', 'SH&E Services', 'n/a', '2016-03-01', 'Sam Elliott','2016-04-13',4,4/4,1,1,0.1648);

# Apr 16
INSERT INTO analytics.metrics_data2 values (null,1,'AMERICAs','Assurance','n/a', 'AS Americas Operations - AS Americas Scheduling', 'n/a', '2016-04-01', 'Andre Szkodzinski','2016-05-02',11,0.74,0.684,0.72,1);
INSERT INTO analytics.metrics_data2 values (null,1,'AMERICAs','Assurance','n/a', 'AS Americas Operations - AS Canada Scheduling', 'n/a', '2016-04-01', 'Andre Szkodzinski','2016-05-02',3,0.64,0.684,0.72,1);
INSERT INTO analytics.metrics_data2 values (null,1,'AMERICAs','Assurance','n/a', 'AS Corp Ops, Accreditation & Quality - AS Quality Americas', 'n/a', '2016-04-01', 'Andre Szkodzinski','2016-05-02',9,0.76,0.684,0.72,1);
INSERT INTO analytics.metrics_data2 values (null,1,'AMERICAs','Assurance','n/a', 'AS Corp Ops, Accreditation & Quality - AS Technical Managers Americas', 'n/a', '2016-04-01', 'Andre Szkodzinski','2016-05-02',11,0.73,0.684,0.72,1);
INSERT INTO analytics.metrics_data2 values (null,1,'AMERICAs','Assurance','n/a', 'AS Finance Americas', 'n/a', '2016-04-01', 'Andre Szkodzinski','2016-05-02',10,0.75,0.684,0.72,1);
INSERT INTO analytics.metrics_data2 values (null,1,'AMERICAs','Learning','n/a', 'AS Learning Improvement Solutions â”¬Ã¡- AS Americas LIS Operations', 'n/a', '2016-04-01', 'Andre Szkodzinski','2016-05-02',2,0.64,0.684,0.72,1);
INSERT INTO analytics.metrics_data2 values (null,1,'AMERICAs','Learning','n/a', 'AS Learning Improvement Solutions â”¬Ã¡- AS LIS Team', 'n/a', '2016-04-01', 'Andre Szkodzinski','2016-05-02',3,0.74,0.684,0.72,1);

INSERT INTO analytics.metrics_data2 values (null,36,'APAC','Knowledge','n/a', 'News Services', 'n/a', '2016-04-01', 'Sam Elliott','2016-05-04',1,1,1,1,0.1648);
INSERT INTO analytics.metrics_data2 values (null,35,'APAC','Knowledge','n/a', 'News Services', 'n/a', '2016-04-01', 'Sam Elliott','2016-05-04',64,1,1,1,0.1648);
INSERT INTO analytics.metrics_data2 values (null,37,'APAC','Knowledge','n/a', 'SH&E Services', 'n/a', '2016-04-01', 'Sam Elliott','2016-05-04',4,1,1,1,0.1648);

INSERT INTO analytics.metrics_data2 values (null,39,'AMERICAs','Learning','n/a', 'QA', 'n/a', '2016-04-01', 'Rebecca Turco','2016-05-03',660,0.99,0.95,1,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,40,'AMERICAs','Learning','n/a', 'QA', 'n/a', '2016-04-01', 'Rebecca Turco','2016-05-03',182,0.97,0.95,1,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,41,'AMERICAs','Learning','n/a', 'Project Management-English', 'n/a', '2016-04-01', 'Rebecca Turco','2016-05-03',2137,0.91,0.95,1,0.116804636);
INSERT INTO analytics.metrics_data2 values (null,42,'AMERICAs','Learning','n/a', 'Project Management-Translations', 'n/a', '2016-04-01', 'Rebecca Turco','2016-05-03',1310,0.97,0.95,1,0.116804636);

INSERT INTO analytics.metrics_data2 values (null,14,'APAC','Knowledge','n/a', 'IS Production AUS', 'n/a', '2016-04-01', 'Sian Lindsay','2016-05-04',136,1,1,1,0.1648);
INSERT INTO analytics.metrics_data2 values (null,15,'APAC','Knowledge','n/a', 'IS Production AUS', 'n/a', '2016-04-01', 'Sian Lindsay','2016-05-04',111,1,1,1,0.1648);

INSERT INTO analytics.metrics_data2 values (null,16,'AMERICAs','Assurance','n/a', 'Canada Operations', 'n/a', '2016-04-01', 'Naupreet Grewal','2016-05-03',29,0.9839,0.72,0.8,0.7125);
INSERT INTO analytics.metrics_data2 values (null,16,'AMERICAs','Assurance','n/a', 'Mexico Operations', 'n/a', '2016-04-01', 'Naupreet Grewal','2016-05-03',4,0.6157,0.72,0.8,0.7125);
INSERT INTO analytics.metrics_data2 values (null,16,'AMERICAs','Assurance','n/a', 'US Operations', 'n/a', '2016-04-01', 'Naupreet Grewal','2016-05-03',31,0.7942,0.72,0.8,0.7125);
INSERT INTO analytics.metrics_data2 values (null,6,'AMERICAs','Assurance','n/a', 'AMERICA Auditors', 'n/a', '2016-04-01', 'Naupreet Grewal','2016-05-03',321,0.5857,0.874,0.92,0.4239202938);
INSERT INTO analytics.metrics_data2 values (null,4,'AMERICAs','Assurance','n/a', 'Ops - Food', 'n/a', '2016-04-01', 'Naupreet Grewal','2016-05-03',304,0.5526,0.9025,0.95,0.4239202938);
INSERT INTO analytics.metrics_data2 values (null,4,'AMERICAs','Assurance','n/a', 'Ops - MS', 'n/a', '2016-04-01', 'Naupreet Grewal','2016-05-03',720,0.7556,0.9025,0.95,0.4239202938);

INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Knowledge', 'n/a', 'IS Production AUS', 'n/a', '2016-04-01', 'Luca Contri','2016-05-04',3,.981, 0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Knowledge', 'n/a', 'Legislation', 'n/a', '2016-04-01', 'Luca Contri','2016-05-04',6,0.629, 0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Knowledge', 'n/a', 'Regulatory', 'n/a', '2016-04-01', 'Luca Contri','2016-05-04',17,0.777,0.684, 0.7200000000, 1);

INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Assurance' ,'n/a', 'CS - Administration', 'n/a', '2016-04-01', 'Luca Contri','2016-05-04',9,0.761,0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Assurance' ,'n/a', 'Scheduling - MS', 'n/a', '2016-04-01', 'Luca Contri','2016-05-04',7,0.617,0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Assurance' ,'n/a', 'Scheduling - PS', 'n/a', '2016-04-01', 'Luca Contri','2016-05-04',6,1,0.684, 0.7200000000, 1);

INSERT INTO analytics.metrics_data2 values (null,1,'EMEA', 'Assurance' ,'n/a', 'AS EMEA CS Administration', 'n/a', '2016-04-01', 'Luca Contri','2016-05-04',12,0.693,0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'EMEA', 'Assurance' ,'n/a', 'AS EMEA CS Scheduling', 'n/a', '2016-04-01', 'Luca Contri','2016-05-04',8,0.608,0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'EMEA', 'Assurance' ,'n/a', 'AS EMEA SCM Operations', 'n/a', '2016-04-01', 'Luca Contri','2016-05-04',7,0.617,0.684, 0.7200000000, 1);

INSERT INTO analytics.metrics_data2 values (null,9,'APAC','Risk','n/a', 'Client Service - APAC', 'n/a', '2016-04-01', 'Amanda Dunlop','2016-05-05',14,0.752,0.665,0.7,0.0732);

INSERT INTO analytics.metrics_data2 values (null,48,'AMERICAs','Learning','n/a', 'Program Managers', 'n/a', '2016-04-01', 'Sandra Guadagnoli','2015-05-03',338,0.97,0.75,0.8,0.225);
INSERT INTO analytics.metrics_data2 values (null,44,'AMERICAs','Learning','n/a', 'Learning Support', 'n/a', '2016-04-01', 'Sandra Guadagnoli','2015-05-03',430,0.89,0.8,0.85,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,50,'AMERICAs','Learning','n/a', 'Program Managers', 'n/a', '2016-04-01', 'Sandra Guadagnoli','2015-05-03',338,0.97,0.8,0.85,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,49,'AMERICAs','Learning','n/a', 'Program Managers', 'n/a', '2016-04-01', 'Sandra Guadagnoli','2015-05-03',338,0.89,0.8,0.85,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,45,'AMERICAs','Learning','n/a', 'Program Managers/Program Specialists', 'n/a', '2016-04-01', 'Sandra Guadagnoli','2015-05-03',2943,0.88,0.8,0.85,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,46,'AMERICAs','Learning','n/a', 'Learning Support', 'n/a', '2016-04-01', 'Sandra Guadagnoli','2015-05-03',1180,0.97,0.8,0.95,0.116804636);
INSERT INTO analytics.metrics_data2 values (null,10,'AMERICAs','Risk','n/a', 'Client Service - EHS', 'n/a', '2016-04-01', 'Sandra Guadagnoli','2015-05-03',5,0.83,0.665,0.7,0.0625);
INSERT INTO analytics.metrics_data2 values (null,10,'AMERICAs','Risk','n/a', 'Client Service - GRC PS', 'n/a', '2016-04-01', 'Sandra Guadagnoli','2015-05-03',11,0.53,0.5,0.57,0.0625);
INSERT INTO analytics.metrics_data2 values (null,52,'AMERICAs','Risk','n/a', 'Client Services - EHS', 'n/a', '2016-04-01', 'Sandra Guadagnoli','2015-05-03',26,0.96,0.8,0.85,0.1128328992);
INSERT INTO analytics.metrics_data2 values (null,52,'AMERICAs','Risk','n/a', 'Professional Services Team', 'n/a', '2016-04-01', 'Sandra Guadagnoli','2015-05-03',126,0.98,0.8,0.85,0.1128328992);
INSERT INTO analytics.metrics_data2 values (null,51,'AMERICAs','Risk','n/a', 'Client Services - EHS', 'n/a', '2016-04-01', 'Sandra Guadagnoli','2015-05-03',26,0.77,0.8,0.85,0.1128328992);
INSERT INTO analytics.metrics_data2 values (null,51,'AMERICAs','Risk','n/a', 'Professional Services Team', 'n/a', '2016-04-01', 'Sandra Guadagnoli','2015-05-03',126,0.92,0.8,0.85,0.1128328992);
INSERT INTO analytics.metrics_data2 values (null,53,'AMERICAs','Risk','n/a', 'Professional Services Team', 'n/a', '2016-04-01', 'Sandra Guadagnoli','2015-05-03',11,0.73,0.65,0.7,0.0752219328);
INSERT INTO analytics.metrics_data2 values (null,54,'AMERICAs','Risk','n/a', 'Professional Services Team', 'n/a', '2016-04-01', 'Sandra Guadagnoli','2015-05-03',5,0.2,0.65,0.7,0.0752219328);
INSERT INTO analytics.metrics_data2 values (null,47,'AMERICAs','Risk','n/a', 'C360 Support', 'n/a', '2016-04-01', 'Sandra Guadagnoli','2016-05-03',479,0.93,0.8,0.95,0.0752219328);

# May 2016
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Knowledge', 'n/a', 'IS Production AUS', 'n/a', '2016-05-01', 'Luca Contri','2016-06-06',3,.929, 0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Knowledge', 'n/a', 'Legislation', 'n/a', '2016-05-01', 'Luca Contri','2016-06-06',6,0.683, 0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Knowledge', 'n/a', 'Regulatory', 'n/a', '2016-05-01', 'Luca Contri','2016-06-06',17,0.858,0.684, 0.7200000000, 1);

INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Assurance' ,'n/a', 'CS - Administration', 'n/a', '2016-05-01', 'Luca Contri','2016-06-06',9,0.803,0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Assurance' ,'n/a', 'Scheduling - MS', 'n/a', '2016-05-01', 'Luca Contri','2016-06-06',7,0.671,0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Assurance' ,'n/a', 'Scheduling - PS', 'n/a', '2016-05-01', 'Luca Contri','2016-06-06',6,0.854,0.684, 0.7200000000, 1);

INSERT INTO analytics.metrics_data2 values (null,1,'EMEA', 'Assurance' ,'n/a', 'AS EMEA CS Administration', 'n/a', '2016-05-01', 'Luca Contri','2016-06-06',12,0.721,0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'EMEA', 'Assurance' ,'n/a', 'AS EMEA CS Scheduling', 'n/a', '2016-05-01', 'Luca Contri','2016-06-06',8,0.631,0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'EMEA', 'Assurance' ,'n/a', 'AS EMEA SCM Operations', 'n/a', '2016-05-01', 'Luca Contri','2016-06-06',7,0.566,0.684, 0.7200000000, 1);

INSERT INTO analytics.metrics_data2 values (null,16,'AMERICAs','Assurance','n/a', 'Canada Operations', 'n/a', '2016-05-01', 'Naupreet Grewal','2016-06-03',29,1.11302603036876,0.72,0.8,0.7125);
INSERT INTO analytics.metrics_data2 values (null,16,'AMERICAs','Assurance','n/a', 'Mexico Operations', 'n/a', '2016-05-01', 'Naupreet Grewal','2016-06-03',3,0.862003968253968,0.72,0.8,0.7125);
INSERT INTO analytics.metrics_data2 values (null,16,'AMERICAs','Assurance','n/a', 'US Operations', 'n/a', '2016-05-01', 'Naupreet Grewal','2016-06-03',32,0.961663971077918,0.72,0.8,0.7125);
INSERT INTO analytics.metrics_data2 values (null,6,'AMERICAs','Assurance','n/a', 'AMERICA Auditors', 'n/a', '2016-05-01', 'Naupreet Grewal','2016-06-01',364,0.5604,0.874,0.92,0.4239202938);
INSERT INTO analytics.metrics_data2 values (null,4,'AMERICAs','Assurance','n/a', 'Ops - Food', 'n/a', '2016-05-01', 'Naupreet Grewal','2016-06-01',1214,0.5659,0.9025,0.95,0.4239202938);
INSERT INTO analytics.metrics_data2 values (null,4,'AMERICAs','Assurance','n/a', 'Ops - MS', 'n/a', '2016-05-01', 'Naupreet Grewal','2016-06-01',3505,0.473,0.9025,0.95,0.4239202938);

INSERT INTO analytics.metrics_data2 values (null,9,'APAC','Risk','n/a', 'Client Service - APAC', 'n/a', '2016-05-01', 'Amanda Dunlop','2016-06-09',14,0.62,0.665,0.7,0.0732);

# June 2016
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Knowledge', 'n/a', 'IS Production AUS', 'n/a', '2016-06-01', 'Luca Contri','2016-07-04',3,.997, 0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Knowledge', 'n/a', 'Legislation', 'n/a', '2016-06-01', 'Luca Contri','2016-07-04',6,0.777, 0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Knowledge', 'n/a', 'Regulatory', 'n/a', '2016-06-01', 'Luca Contri','2016-07-04',17,0.972,0.684, 0.7200000000, 1);

INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Assurance' ,'n/a', 'CS - Administration', 'n/a', '2016-06-01', 'Luca Contri','2016-07-04',9,0.696,0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Assurance' ,'n/a', 'Scheduling - MS', 'n/a', '2016-06-01', 'Luca Contri','2016-07-04',7,0.639,0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Assurance' ,'n/a', 'Scheduling - PS', 'n/a', '2016-06-01', 'Luca Contri','2016-07-04',6,0.848,0.684, 0.7200000000, 1);

INSERT INTO analytics.metrics_data2 values (null,1,'EMEA', 'Assurance' ,'n/a', 'AS EMEA Food', 'n/a', '2016-06-01', 'Luca Contri','2016-07-04',8,0.430,0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'EMEA', 'Assurance' ,'n/a', 'AS EMEA Agriculture', 'n/a', '2016-06-01', 'Luca Contri','2016-07-04',6,0.67,0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'EMEA', 'Assurance' ,'n/a', 'AS EMEA SCM', 'n/a', '2016-06-01', 'Luca Contri','2016-07-04',9,0.566,0.609, 0.7200000000, 1);

INSERT INTO analytics.metrics_data2 values (null,14,'APAC','Knowledge','n/a', 'IS Production AUS', 'n/a', '2016-06-01', 'Sian Lindsay','2016-07-05',124,1,1,1,0.1648);
INSERT INTO analytics.metrics_data2 values (null,15,'APAC','Knowledge','n/a', 'IS Production AUS', 'n/a', '2016-06-01', 'Sian Lindsay','2016-07-05',58,1,1,1,0.1648);

INSERT INTO analytics.metrics_data2 values (null,36,'APAC','Knowledge','n/a', 'News Services', 'n/a', '2016-06-01', 'Sam Elliott','2016-07-07',1,1,1,1,0.1648);
INSERT INTO analytics.metrics_data2 values (null,35,'APAC','Knowledge','n/a', 'News Services', 'n/a', '2016-06-01', 'Sam Elliott','2016-07-07',64,1,1,1,0.1648);
INSERT INTO analytics.metrics_data2 values (null,37,'APAC','Knowledge','n/a', 'SH&E Services', 'n/a', '2016-06-01', 'Sam Elliott','2016-07-07',4,1,1,1,0.1648);

INSERT INTO analytics.metrics_data2 values (null,6,'AMERICAs','Assurance','n/a', 'AMERICA Auditors', 'n/a', '2016-06-01', 'Naupreet Grewal','2016-07-04',311,0.672025723472669,0.874,0.92,0.4239202938);
INSERT INTO analytics.metrics_data2 values (null,4,'AMERICAs','Assurance','n/a', 'Ops - Food', 'n/a', '2016-06-01', 'Naupreet Grewal','2016-07-04',787,0.52858958068615,0.9025,0.95,0.4239202938);
INSERT INTO analytics.metrics_data2 values (null,4,'AMERICAs','Assurance','n/a', 'Ops - MS', 'n/a', '2016-06-01', 'Naupreet Grewal','2016-07-04',2263,0.499779054352629,0.9025,0.95,0.4239202938);

INSERT INTO analytics.metrics_data2 values (null,44,'AMERICAs','Learning','n/a', 'Learning Support', 'n/a', '2016-06-01', 'Sandra Guadagnoli','2016-07-07',552,0.9,0.8,0.85,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,50,'AMERICAs','Learning','n/a', 'Program Managers', 'n/a', '2016-06-01', 'Sandra Guadagnoli','2016-07-07',337,0.97,0.8,0.85,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,49,'AMERICAs','Learning','n/a', 'Program Managers', 'n/a', '2016-06-01', 'Sandra Guadagnoli','2016-07-07',337,0.89,0.8,0.85,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,45,'AMERICAs','Learning','n/a', 'Program Managers/Program Specialists', 'n/a', '2016-06-01', 'Sandra Guadagnoli','2016-07-07',3404,0.88,0.8,0.85,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,52,'AMERICAs','Risk','n/a', 'Client Services - EHS', 'n/a', '2016-06-01', 'Sandra Guadagnoli','2016-07-07',27,0.97,0.8,0.85,0.1128328992);
INSERT INTO analytics.metrics_data2 values (null,52,'AMERICAs','Risk','n/a', 'Professional Services Team', 'n/a', '2016-06-01', 'Sandra Guadagnoli','2016-07-07',117,0.98,0.8,0.85,0.1128328992);
INSERT INTO analytics.metrics_data2 values (null,51,'AMERICAs','Risk','n/a', 'Client Services - EHS', 'n/a', '2016-06-01', 'Sandra Guadagnoli','2016-07-07',27,0.78,0.8,0.85,0.1128328992);
INSERT INTO analytics.metrics_data2 values (null,51,'AMERICAs','Risk','n/a', 'Professional Services Team', 'n/a', '2016-06-01', 'Sandra Guadagnoli','2016-07-07',117,0.91,0.8,0.85,0.1128328992);
INSERT INTO analytics.metrics_data2 values (null,46,'AMERICAs','Learning','n/a', 'Learning Support', 'n/a', '2016-06-01', 'Sandra Guadagnoli','2016-07-07',2017,0.88,0.8,0.95,0.116804636);
INSERT INTO analytics.metrics_data2 values (null,53,'AMERICAs','Risk','n/a', 'Professional Services Team', 'n/a', '2016-06-01', 'Sandra Guadagnoli','2016-07-07',13,0.62,0.65,0.7,0.0752219328);
INSERT INTO analytics.metrics_data2 values (null,54,'AMERICAs','Risk','n/a', 'Professional Services Team', 'n/a', '2016-06-01', 'Sandra Guadagnoli','2016-07-07',7,0.43,0.65,0.7,0.0752219328);
INSERT INTO analytics.metrics_data2 values (null,47,'AMERICAs','Risk','n/a', 'C360 Support', 'n/a', '2016-06-01', 'Sandra Guadagnoli','2016-07-07',557,0.85,0.8,0.95,0.0752219328);
INSERT INTO analytics.metrics_data2 values (null,48,'AMERICAs','Learning','n/a', 'Program Managers', 'n/a', '2016-06-01', 'Sandra Guadagnoli','2016-07-07',337,0.96,0.75,0.8,0.225);
INSERT INTO analytics.metrics_data2 values (null,10,'AMERICAs','Risk','n/a', 'Client Service - EHS', 'n/a', '2016-06-01', 'Sandra Guadagnoli','2016-07-07',5,0.76,0.665,0.7,0.0625);
INSERT INTO analytics.metrics_data2 values (null,10,'AMERICAs','Risk','n/a', 'Client Service - GRC PS', 'n/a', '2016-06-01', 'Sandra Guadagnoli','2016-07-07',11,0.75,0.5,0.57,0.0625);

INSERT INTO analytics.metrics_data2 values (null,9,'APAC','Risk','n/a', 'Client Service - APAC', 'n/a', '2016-06-01', 'Amanda Dunlop','2016-07-10',14,0.601,0.665,0.7,0.0732);

#July 2016
INSERT INTO analytics.metrics_data2 values (null,6,'AMERICAs','Assurance','n/a', 'AMERICA Auditors', 'n/a', '2016-07-01', 'Naupreet Grewal','2016-08-04',439,0.6105,0.874,0.92,0.4239202938);
INSERT INTO analytics.metrics_data2 values (null,4,'AMERICAs','Assurance','n/a', 'Ops - Food', 'n/a', '2016-07-01', 'Naupreet Grewal','2016-08-04',788,0.5368,0.9025,0.95,0.4239202938);
INSERT INTO analytics.metrics_data2 values (null,4,'AMERICAs','Assurance','n/a', 'Ops - MS', 'n/a', '2016-07-01', 'Naupreet Grewal','2016-08-04',2196,0.4781,0.9025,0.95,0.4239202938);

INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Knowledge', 'n/a', 'IS Production AUS', 'n/a', '2016-07-01', 'Luca Contri','2016-08-15',3,0.9663, 0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Knowledge', 'n/a', 'Legislation', 'n/a', '2016-07-01', 'Luca Contri','2016-08-15',6,0.8579, 0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Knowledge', 'n/a', 'Regulatory', 'n/a', '2016-07-01', 'Luca Contri','2016-08-15',17,0.8896,0.684, 0.7200000000, 1);

INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Assurance' ,'n/a', 'CS - Administration', 'n/a', '2016-07-01', 'Luca Contri','2016-08-15',9,0.5752,0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Assurance' ,'n/a', 'Scheduling - MS', 'n/a', '2016-07-01', 'Luca Contri','2016-08-15',7,0.7106,0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Assurance' ,'n/a', 'Scheduling - PS', 'n/a', '2016-07-01', 'Luca Contri','2016-08-15',6,0.8927,0.684, 0.7200000000, 1);

INSERT INTO analytics.metrics_data2 values (null,1,'EMEA', 'Assurance' ,'n/a', 'AS EMEA Food', 'n/a', '2016-07-01', 'Luca Contri','2016-08-15',10,0.5435,0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'EMEA', 'Assurance' ,'n/a', 'AS EMEA Agriculture', 'n/a', '2016-07-01', 'Luca Contri','2016-08-15',7,0.6520,0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'EMEA', 'Assurance' ,'n/a', 'AS EMEA SCM', 'n/a', '2016-07-01', 'Luca Contri','2016-08-15',9,0.566,0.6333, 0.7200000000, 1);

INSERT INTO analytics.metrics_data2 values (null,44,'AMERICAs','Learning','n/a', 'Learning Support', 'n/a', '2016-07-01', 'Sandra Guadagnoli','2016-08-11',487,0.92,0.8,0.85,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,50,'AMERICAs','Learning','n/a', 'Program Managers', 'n/a', '2016-07-01', 'Sandra Guadagnoli','2016-08-11',341,0.98,0.8,0.85,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,49,'AMERICAs','Learning','n/a', 'Program Managers', 'n/a', '2016-07-01', 'Sandra Guadagnoli','2016-08-11',341,0.9,0.8,0.85,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,45,'AMERICAs','Learning','n/a', 'Program Managers/Program Specialists', 'n/a', '2016-07-01', 'Sandra Guadagnoli','2016-08-11',3607,0.88,0.8,0.85,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,52,'AMERICAs','Risk','n/a', 'Client Services - EHS', 'n/a', '2016-07-01', 'Sandra Guadagnoli','2016-08-11',28,0.96,0.8,0.85,0.1128328992);
INSERT INTO analytics.metrics_data2 values (null,52,'AMERICAs','Risk','n/a', 'Professional Services Team', 'n/a', '2016-07-01', 'Sandra Guadagnoli','2016-08-11',123,0.98,0.8,0.85,0.1128328992);
INSERT INTO analytics.metrics_data2 values (null,51,'AMERICAs','Risk','n/a', 'Client Services - EHS', 'n/a', '2016-07-01', 'Sandra Guadagnoli','2016-08-11',28,0.79,0.8,0.85,0.1128328992);
INSERT INTO analytics.metrics_data2 values (null,51,'AMERICAs','Risk','n/a', 'Professional Services Team', 'n/a', '2016-07-01', 'Sandra Guadagnoli','2016-08-11',123,0.93,0.8,0.85,0.1128328992);
INSERT INTO analytics.metrics_data2 values (null,46,'AMERICAs','Learning','n/a', 'Learning Support', 'n/a', '2016-07-01', 'Sandra Guadagnoli','2016-08-11',1590,1.06,0.8,0.95,0.116804636);
INSERT INTO analytics.metrics_data2 values (null,53,'AMERICAs','Risk','n/a', 'Professional Services Team', 'n/a', '2016-07-01', 'Sandra Guadagnoli','2016-08-11',13,0.62,0.65,0.7,0.0752219328);
INSERT INTO analytics.metrics_data2 values (null,54,'AMERICAs','Risk','n/a', 'Professional Services Team', 'n/a', '2016-07-01', 'Sandra Guadagnoli','2016-08-11',4,0.75,0.65,0.7,0.0752219328);
INSERT INTO analytics.metrics_data2 values (null,47,'AMERICAs','Risk','n/a', 'C360 Support', 'n/a', '2016-07-01', 'Sandra Guadagnoli','2016-08-11',377,1.02,0.8,0.95,0.0752219328);
INSERT INTO analytics.metrics_data2 values (null,48,'AMERICAs','Learning','n/a', 'Program Managers', 'n/a', '2016-07-01', 'Sandra Guadagnoli','2016-08-11',341,0.96,0.75,0.8,0.225);
INSERT INTO analytics.metrics_data2 values (null,10,'AMERICAs','Risk','n/a', 'Client Service - EHS', 'n/a', '2016-07-01', 'Sandra Guadagnoli','2016-08-11',5,0.68,0.665,0.7,0.0625);
INSERT INTO analytics.metrics_data2 values (null,10,'AMERICAs','Risk','n/a', 'Client Service - GRC PS', 'n/a', '2016-07-01', 'Sandra Guadagnoli','2016-08-11',9,0.65,0.5,0.57,0.0625);

INSERT INTO analytics.metrics_data2 values (null,39,'AMERICAs','Learning','n/a', 'QA', 'n/a', '2016-07-01', 'Rebecca Turco','2016-08-11',396,0.97,0.95,1,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,40,'AMERICAs','Learning','n/a', 'QA', 'n/a', '2016-07-01', 'Rebecca Turco','2016-08-11',188,0.96,0.95,1,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,41,'AMERICAs','Learning','n/a', 'Project Management-English', 'n/a', '2016-07-01', 'Rebecca Turco','2016-08-11',1004,0.86,0.95,1,0.116804636);
INSERT INTO analytics.metrics_data2 values (null,42,'AMERICAs','Learning','n/a', 'Project Management-Translations', 'n/a', '2016-07-01', 'Rebecca Turco','2016-08-11',1204,0.91,0.95,1,0.116804636);

INSERT INTO analytics.metrics_data2 values (null,14,'APAC','Knowledge','n/a', 'IS Production AUS', 'n/a', '2016-07-01', 'Sian Lindsay','2016-08-16',39,1,1,1,0.1648);
INSERT INTO analytics.metrics_data2 values (null,15,'APAC','Knowledge','n/a', 'IS Production AUS', 'n/a', '2016-07-01', 'Sian Lindsay','2016-08-16',20,1,1,1,0.1648);

INSERT INTO analytics.metrics_data2 values (null,9,'APAC','Risk','n/a', 'Client Service - APAC', 'n/a', '2016-07-01', 'Amanda Dunlop','2016-08-18',15,0.526,0.665,0.7,0.0732);

INSERT INTO analytics.metrics_data2 values (null,36,'APAC','Knowledge','n/a', 'News Services', 'n/a', '2016-07-01', 'Sam Elliott','2016-08-22',1,1,1,1,0.1648);
INSERT INTO analytics.metrics_data2 values (null,35,'APAC','Knowledge','n/a', 'News Services', 'n/a', '2016-07-01', 'Sam Elliott','2016-08-22',63,0.984375,1,1,0.1648);
INSERT INTO analytics.metrics_data2 values (null,37,'APAC','Knowledge','n/a', 'SH&E Services', 'n/a', '2016-07-01', 'Sam Elliott','2016-08-22',4,1,1,1,0.1648);

# August 2016
INSERT INTO analytics.metrics_data2 values (null,6,'AMERICAs','Assurance','n/a', 'AMERICA Auditors', 'n/a', '2016-08-01', 'Naupreet Grewal','2016-09-08',316,0.5443,0.874,0.92,0.4239202938);
INSERT INTO analytics.metrics_data2 values (null,4,'AMERICAs','Assurance','n/a', 'Ops - Food', 'n/a', '2016-08-01', 'Naupreet Grewal','2016-09-08',9991,0.8022,0.9025,0.95,0.4239202938);
INSERT INTO analytics.metrics_data2 values (null,4,'AMERICAs','Assurance','n/a', 'Ops - MS', 'n/a', '2016-08-01', 'Naupreet Grewal','2016-09-08',1560,0.5673,0.9025,0.95,0.4239202938);

INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Knowledge', 'n/a', 'IS Production AUS', 'n/a', '2016-08-01', 'Luca Contri','2016-09-09',3,1.0005, 0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Knowledge', 'n/a', 'Legislation', 'n/a', '2016-08-01', 'Luca Contri','2016-09-09',6,0.6447, 0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Knowledge', 'n/a', 'Regulatory', 'n/a', '2016-08-01', 'Luca Contri','2016-09-09',17,0.8362,0.684, 0.7200000000, 1);

INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Assurance' ,'n/a', 'CS - Administration', 'n/a', '2016-08-01', 'Luca Contri','2016-09-09',9,0.6075,0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Assurance' ,'n/a', 'Scheduling - MS', 'n/a', '2016-08-01', 'Luca Contri','2016-09-09',7,0.8304,0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Assurance' ,'n/a', 'Scheduling - PS', 'n/a', '2016-08-01', 'Luca Contri','2016-09-09',6,0.8534,0.684, 0.7200000000, 1);

INSERT INTO analytics.metrics_data2 values (null,1,'EMEA', 'Assurance' ,'n/a', 'AS EMEA Food', 'n/a', '2016-08-01', 'Luca Contri','2016-09-09',10,0.4685,0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'EMEA', 'Assurance' ,'n/a', 'AS EMEA Agriculture', 'n/a', '2016-08-01', 'Luca Contri','2016-09-09',7,0.6481,0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'EMEA', 'Assurance' ,'n/a', 'AS EMEA SCM', 'n/a', '2016-08-01', 'Luca Contri','2016-09-09',9,0.6136,0.6333, 0.7200000000, 1);

INSERT INTO analytics.metrics_data2 values (null,39,'AMERICAs','Learning','n/a', 'QA', 'n/a', '2016-08-01', 'Rebecca Turco','2016-09-09',189,0.95,0.95,1,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,40,'AMERICAs','Learning','n/a', 'QA', 'n/a', '2016-08-01', 'Rebecca Turco','2016-09-09',401,0.98,0.95,1,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,41,'AMERICAs','Learning','n/a', 'Project Management-English', 'n/a', '2016-08-01', 'Rebecca Turco','2016-09-09',869,0.91,0.95,1,0.116804636);
INSERT INTO analytics.metrics_data2 values (null,42,'AMERICAs','Learning','n/a', 'Project Management-Translations', 'n/a', '2016-08-01', 'Rebecca Turco','2016-09-09',1194,0.81,0.95,1,0.116804636);

INSERT INTO analytics.metrics_data2 values (null,48,'AMERICAs','Learning','n/a', 'Program Managers', 'n/a', '2016-08-01', 'Sandra Guadagnoli','2016-09-09',341,0.96,0.75,0.8,0.225);
INSERT INTO analytics.metrics_data2 values (null,44,'AMERICAs','Learning','n/a', 'Learning Support', 'n/a', '2016-08-01', 'Sandra Guadagnoli','2016-09-09',495,0.9,0.8,0.85,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,50,'AMERICAs','Learning','n/a', 'Program Managers', 'n/a', '2016-08-01', 'Sandra Guadagnoli','2016-09-09',341,0.97,0.8,0.85,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,49,'AMERICAs','Learning','n/a', 'Program Managers', 'n/a', '2016-08-01', 'Sandra Guadagnoli','2016-09-09',341,0.89,0.8,0.85,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,45,'AMERICAs','Learning','n/a', 'Program Managers/Program Specialists', 'n/a', '2016-08-01', 'Sandra Guadagnoli','2016-09-09',3766,0.89,0.8,0.85,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,46,'AMERICAs','Learning','n/a', 'Learning Support', 'n/a', '2016-08-01', 'Sandra Guadagnoli','2016-09-09',1771,1,0.8,0.95,0.116804636);
INSERT INTO analytics.metrics_data2 values (null,10,'AMERICAs','Risk','n/a', 'Client Service - EHS', 'n/a', '2016-08-01', 'Sandra Guadagnoli','2016-09-09',5,0.69,0.665,0.7,0.0625);
INSERT INTO analytics.metrics_data2 values (null,10,'AMERICAs','Risk','n/a', 'Client Service - GRC PS', 'n/a', '2016-08-01', 'Sandra Guadagnoli','2016-09-09',9,0.63,0.5,0.57,0.0625);
INSERT INTO analytics.metrics_data2 values (null,52,'AMERICAs','Risk','n/a', 'Client Services - EHS', 'n/a', '2016-08-01', 'Sandra Guadagnoli','2016-09-09',29,1,0.8,0.85,0.1128328992);
INSERT INTO analytics.metrics_data2 values (null,52,'AMERICAs','Risk','n/a', 'Professional Services Team', 'n/a', '2016-08-01', 'Sandra Guadagnoli','2016-09-09',123,0.99,0.8,0.85,0.1128328992);
INSERT INTO analytics.metrics_data2 values (null,51,'AMERICAs','Risk','n/a', 'Client Services - EHS', 'n/a', '2016-08-01', 'Sandra Guadagnoli','2016-09-09',29,0.83,0.8,0.85,0.1128328992);
INSERT INTO analytics.metrics_data2 values (null,51,'AMERICAs','Risk','n/a', 'Professional Services Team', 'n/a', '2016-08-01', 'Sandra Guadagnoli','2016-09-09',123,0.92,0.8,0.85,0.1128328992);
INSERT INTO analytics.metrics_data2 values (null,53,'AMERICAs','Risk','n/a', 'Professional Services Team', 'n/a', '2016-08-01', 'Sandra Guadagnoli','2016-09-09',14,0.57,0.65,0.7,0.0752219328);
INSERT INTO analytics.metrics_data2 values (null,54,'AMERICAs','Risk','n/a', 'Professional Services Team', 'n/a', '2016-08-01', 'Sandra Guadagnoli','2016-09-09',3,0.67,0.65,0.7,0.0752219328);
INSERT INTO analytics.metrics_data2 values (null,47,'AMERICAs','Risk','n/a', 'C360 Support', 'n/a', '2016-08-01', 'Sandra Guadagnoli','2016-09-09',377,1.02,0.8,0.95,0.0752219328);

INSERT INTO analytics.metrics_data2 values (null,9,'APAC','Risk','n/a', 'Client Service - APAC', 'n/a', '2016-08-01', 'Amanda Dunlop','2016-09-12',14,0.62,0.665,0.7,0.0732);

INSERT INTO analytics.metrics_data2 values (null,14,'APAC','Knowledge','n/a', 'IS Production AUS', 'n/a', '2016-08-01', 'Sian Lindsay','2016-09-12',43,1,1,1,0.1648);
INSERT INTO analytics.metrics_data2 values (null,15,'APAC','Knowledge','n/a', 'IS Production AUS', 'n/a', '2016-08-01', 'Sian Lindsay','2016-09-12',13,1,1,1,0.1648);

INSERT INTO analytics.metrics_data2 values (null,36,'APAC','Knowledge','n/a', 'News Services', 'n/a', '2016-08-01', 'Sam Elliott','2016-09-13',1,1,1,1,0.1648);
INSERT INTO analytics.metrics_data2 values (null,35,'APAC','Knowledge','n/a', 'News Services', 'n/a', '2016-08-01', 'Sam Elliott','2016-09-13',64,1,1,1,0.1648);
INSERT INTO analytics.metrics_data2 values (null,37,'APAC','Knowledge','n/a', 'SH&E Services', 'n/a', '2016-08-01', 'Sam Elliott','2016-09-13',3,0.75,1,1,0.1648);

# September 2016
INSERT INTO analytics.metrics_data2 values (null,39,'AMERICAs','Learning','n/a', 'QA', 'n/a', '2016-09-01', 'Rebecca Turco','2016-10-05',428,0.96,0.95,1,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,40,'AMERICAs','Learning','n/a', 'QA', 'n/a', '2016-09-01', 'Rebecca Turco','2016-10-05',217,0.96,0.95,1,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,41,'AMERICAs','Learning','n/a', 'Project Management-English', 'n/a', '2016-09-01', 'Rebecca Turco','2016-10-05',1152,0.85,0.95,1,0.116804636);
INSERT INTO analytics.metrics_data2 values (null,42,'AMERICAs','Learning','n/a', 'Project Management-Translations', 'n/a', '2016-09-01', 'Rebecca Turco','2016-10-05',1426,0.81,0.95,1,0.116804636);

INSERT INTO analytics.metrics_data2 values (null,6,'AMERICAs','Assurance','n/a', 'AMERICA Auditors', 'n/a', '2016-09-01', 'Naupreet Grewal','2016-10-04',310,0.5839,0.874,0.92,0.4239202938);
INSERT INTO analytics.metrics_data2 values (null,4,'AMERICAs','Assurance','n/a', 'Ops - Food', 'n/a', '2016-09-01', 'Naupreet Grewal','2016-10-05',1198,0.6018,0.9025,0.95,0.4239202938);
INSERT INTO analytics.metrics_data2 values (null,4,'AMERICAs','Assurance','n/a', 'Ops - MS', 'n/a', '2016-09-01', 'Naupreet Grewal','2016-10-05',2949,0.489,0.9025,0.95,0.4239202938);

INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Knowledge', 'n/a', 'IS Production AUS', 'n/a', '2016-09-01', 'Luca Contri','2016-10-06',3,0.9860, 0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Knowledge', 'n/a', 'Legislation', 'n/a', '2016-09-01', 'Luca Contri','2016-10-06',6,0.6770, 0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Knowledge', 'n/a', 'Regulatory', 'n/a', '2016-09-01', 'Luca Contri','2016-10-06',17,0.9123,0.684, 0.7200000000, 1);

INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Assurance' ,'n/a', 'CS - Administration', 'n/a', '2016-09-01', 'Luca Contri','2016-10-06',9,0.6232,0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Assurance' ,'n/a', 'Scheduling - MS', 'n/a', '2016-09-01', 'Luca Contri','2016-10-06',7,0.7859,0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Assurance' ,'n/a', 'Scheduling - PS', 'n/a', '2016-09-01', 'Luca Contri','2016-10-06',6,0.9278,0.684, 0.7200000000, 1);

INSERT INTO analytics.metrics_data2 values (null,1,'EMEA', 'Assurance' ,'n/a', 'AS EMEA Food', 'n/a', '2016-09-01', 'Luca Contri','2016-10-06',10,0.4812,0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'EMEA', 'Assurance' ,'n/a', 'AS EMEA Agriculture', 'n/a', '2016-09-01', 'Luca Contri','2016-10-06',7,0.6313,0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'EMEA', 'Assurance' ,'n/a', 'AS EMEA SCM', 'n/a', '2016-09-01', 'Luca Contri','2016-10-06',9,0.5948,0.6333, 0.7200000000, 1);

# October 2016
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Knowledge', 'n/a', 'IS Production AUS', 'n/a', '2016-10-01', 'Luca Contri','2017-01-06',3, .9818, 0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Knowledge', 'n/a', 'Legislation', 'n/a', '2016-10-01', 'Luca Contri','2017-01-06',6, .619, 0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Knowledge', 'n/a', 'Regulatory', 'n/a', '2016-10-01', 'Luca Contri','2017-01-06',17, .8786,0.684, 0.7200000000, 1);

INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Assurance' ,'n/a', 'CS - Administration', 'n/a', '2016-10-01', 'Luca Contri','2017-01-06',9, .6328,0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Assurance' ,'n/a', 'Scheduling - MS', 'n/a', '2016-10-01', 'Luca Contri','2017-01-06',7, .8455,0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Assurance' ,'n/a', 'Scheduling - PS', 'n/a', '2016-10-01', 'Luca Contri','2017-01-06',6, .9439,0.684, 0.7200000000, 1);

INSERT INTO analytics.metrics_data2 values (null,1,'EMEA', 'Assurance' ,'n/a', 'AS EMEA Food', 'n/a', '2016-10-01', 'Luca Contri','2017-01-06',10, .6062,0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'EMEA', 'Assurance' ,'n/a', 'AS EMEA Agriculture', 'n/a', '2016-10-01', 'Luca Contri','2017-01-06',7, .5743,0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'EMEA', 'Assurance' ,'n/a', 'AS EMEA SCM', 'n/a', '2016-10-01', 'Luca Contri','2017-01-06',9, .6346,0.6333, 0.7200000000, 1);



INSERT INTO analytics.metrics_data2 values (null,39,'AMERICAs','Learning','n/a', 'QA', 'n/a', '2016-10-01', 'Rebecca Turco','2016-11-12',379,0.95,0.95,1,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,40,'AMERICAs','Learning','n/a', 'QA', 'n/a', '2016-10-01', 'Rebecca Turco','2016-11-12',189,0.95,0.95,1,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,41,'AMERICAs','Learning','n/a', 'Project Management-English', 'n/a', '2016-10-01', 'Rebecca Turco','2016-11-12',957,0.98,0.95,1,0.116804636);
INSERT INTO analytics.metrics_data2 values (null,42,'AMERICAs','Learning','n/a', 'Project Management-Translations', 'n/a', '2016-10-01', 'Rebecca Turco','2016-11-12',981,0.98,0.95,1,0.116804636);

# November 2016
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Knowledge', 'n/a', 'IS Production AUS', 'n/a', '2016-11-01', 'Luca Contri','2017-01-06',3, .9952, 0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Knowledge', 'n/a', 'Legislation', 'n/a', '2016-11-01', 'Luca Contri','2017-01-06',6, .6642, 0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Knowledge', 'n/a', 'Regulatory', 'n/a', '2016-11-01', 'Luca Contri','2017-01-06',17, .9318,0.684, 0.7200000000, 1);

INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Assurance' ,'n/a', 'CS - Administration', 'n/a', '2016-11-01', 'Luca Contri','2017-01-06',9, .6335,0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Assurance' ,'n/a', 'Scheduling - MS', 'n/a', '2016-11-01', 'Luca Contri','2017-01-06',7, .8857,0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Assurance' ,'n/a', 'Scheduling - PS', 'n/a', '2016-11-01', 'Luca Contri','2017-01-06',6, .9137,0.684, 0.7200000000, 1);

INSERT INTO analytics.metrics_data2 values (null,1,'EMEA', 'Assurance' ,'n/a', 'AS EMEA Food', 'n/a', '2016-11-01', 'Luca Contri','2017-01-06',10, .6184,0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'EMEA', 'Assurance' ,'n/a', 'AS EMEA Agriculture', 'n/a', '2016-11-01', 'Luca Contri','2017-01-06',7, .6633,0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'EMEA', 'Assurance' ,'n/a', 'AS EMEA SCM', 'n/a', '2016-11-01', 'Luca Contri','2017-01-06',9, .6314,0.6333, 0.7200000000, 1);

INSERT INTO analytics.metrics_data2 values (null,48,'AMERICAs','Learning','n/a', 'Program Managers', 'n/a', '2016-11-01', 'Sandra Guadagnoli','2016-12-06',336,0.99,0.75,0.8,0.225);
INSERT INTO analytics.metrics_data2 values (null,44,'AMERICAs','Learning','n/a', 'Learning Support', 'n/a', '2016-11-01', 'Sandra Guadagnoli','2016-12-06',794,0.87,0.8,0.85,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,50,'AMERICAs','Learning','n/a', 'Program Managers', 'n/a', '2016-11-01', 'Sandra Guadagnoli','2016-12-06',336,0.96,0.8,0.85,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,49,'AMERICAs','Learning','n/a', 'Program Managers', 'n/a', '2016-11-01', 'Sandra Guadagnoli','2016-12-06',336,0.89,0.8,0.85,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,45,'AMERICAs','Learning','n/a', 'Program Managers/Program Specialists', 'n/a', '2016-11-01', 'Sandra Guadagnoli','2016-12-06',4406,0.85,0.8,0.85,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,46,'AMERICAs','Learning','n/a', 'Learning Support', 'n/a', '2016-11-01', 'Sandra Guadagnoli','2016-12-06',2557,1.05,0.8,0.95,0.116804636);
INSERT INTO analytics.metrics_data2 values (null,10,'AMERICAs','Risk','n/a', 'Client Service - EHS', 'n/a', '2016-11-01', 'Sandra Guadagnoli','2016-12-06',5,0.77,0.665,0.7,0.0625);
INSERT INTO analytics.metrics_data2 values (null,10,'AMERICAs','Risk','n/a', 'Client Service - GRC PS', 'n/a', '2016-11-01', 'Sandra Guadagnoli','2016-12-06',7,0.73,0.5,0.57,0.0625);
INSERT INTO analytics.metrics_data2 values (null,52,'AMERICAs','Risk','n/a', 'Client Services - EHS', 'n/a', '2016-11-01', 'Sandra Guadagnoli','2016-12-06',38,1,0.8,0.85,0.1128328992);
INSERT INTO analytics.metrics_data2 values (null,52,'AMERICAs','Risk','n/a', 'Professional Services Team', 'n/a', '2016-11-01', 'Sandra Guadagnoli','2016-12-06',120,0.98,0.8,0.85,0.1128328992);
INSERT INTO analytics.metrics_data2 values (null,51,'AMERICAs','Risk','n/a', 'Client Services - EHS', 'n/a', '2016-11-01', 'Sandra Guadagnoli','2016-12-06',38,0.87,0.8,0.85,0.1128328992);
INSERT INTO analytics.metrics_data2 values (null,51,'AMERICAs','Risk','n/a', 'Professional Services Team', 'n/a', '2016-11-01', 'Sandra Guadagnoli','2016-12-06',120,0.93,0.8,0.85,0.1128328992);
INSERT INTO analytics.metrics_data2 values (null,53,'AMERICAs','Risk','n/a', 'Professional Services Team', 'n/a', '2016-11-01', 'Sandra Guadagnoli','2016-12-06',9,0.55,0.65,0.7,0.0752219328);
INSERT INTO analytics.metrics_data2 values (null,54,'AMERICAs','Risk','n/a', 'Professional Services Team', 'n/a', '2016-11-01', 'Sandra Guadagnoli','2016-12-06',9,0.9,0.65,0.7,0.0752219328);
INSERT INTO analytics.metrics_data2 values (null,47,'AMERICAs','Risk','n/a', 'C360 Support', 'n/a', '2016-11-01', 'Sandra Guadagnoli','2016-12-06',640,0.82,0.8,0.95,0.0752219328);

INSERT INTO analytics.metrics_data2 values (null,39,'AMERICAs','Learning','n/a', 'QA', 'n/a', '2016-11-01', 'Rebecca Turco','2016-12-07',423,0.97,0.95,1,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,40,'AMERICAs','Learning','n/a', 'QA', 'n/a', '2016-11-01', 'Rebecca Turco','2016-12-07',137,0.97,0.95,1,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,41,'AMERICAs','Learning','n/a', 'Project Management-English', 'n/a', '2016-11-01', 'Rebecca Turco','2016-12-07',929,0.98,0.95,1,0.116804636);
INSERT INTO analytics.metrics_data2 values (null,42,'AMERICAs','Learning','n/a', 'Project Management-Translations', 'n/a', '2016-11-01', 'Rebecca Turco','2016-12-07',882,0.96,0.95,1,0.116804636);

# December 2016
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Knowledge', 'n/a', 'IS Production AUS', 'n/a', '2016-12-01', 'Luca Contri','2017-01-06',3, 1.0057, 0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Knowledge', 'n/a', 'Legislation', 'n/a', '2016-12-01', 'Luca Contri','2017-01-06',6, .8676, 0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Knowledge', 'n/a', 'Regulatory', 'n/a', '2016-12-01', 'Luca Contri','2017-01-06',17, .8960,0.684, 0.7200000000, 1);

INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Assurance' ,'n/a', 'CS - Administration', 'n/a', '2016-12-01', 'Luca Contri','2017-01-06',9, .7655,0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Assurance' ,'n/a', 'Scheduling - MS', 'n/a', '2016-12-01', 'Luca Contri','2017-01-06',7, .8799,0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'APAC', 'Assurance' ,'n/a', 'Scheduling - PS', 'n/a', '2016-12-01', 'Luca Contri','2017-01-06',6, .8922,0.684, 0.7200000000, 1);

INSERT INTO analytics.metrics_data2 values (null,1,'EMEA', 'Assurance' ,'n/a', 'AS EMEA Food', 'n/a', '2016-12-01', 'Luca Contri','2017-01-06',10, .5861,0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'EMEA', 'Assurance' ,'n/a', 'AS EMEA Agriculture', 'n/a', '2016-12-01', 'Luca Contri','2017-01-06',7, .6702,0.684, 0.7200000000, 1);
INSERT INTO analytics.metrics_data2 values (null,1,'EMEA', 'Assurance' ,'n/a', 'AS EMEA SCM', 'n/a', '2016-12-01', 'Luca Contri','2017-01-06',9, .6004,0.6333, 0.7200000000, 1);

INSERT INTO analytics.metrics_data2 values (null,48,'AMERICAs','Learning','n/a', 'Program Managers', 'n/a', '2016-12-01', 'Sandra Guadagnoli','2017-01-04',334,0.99,0.75,0.8,0.225);
INSERT INTO analytics.metrics_data2 values (null,44,'AMERICAs','Learning','n/a', 'Learning Support', 'n/a', '2016-12-01', 'Sandra Guadagnoli','2017-01-04',485,0.91,0.8,0.85,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,50,'AMERICAs','Learning','n/a', 'Program Managers', 'n/a', '2016-12-01', 'Sandra Guadagnoli','2017-01-04',334,0.96,0.8,0.85,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,49,'AMERICAs','Learning','n/a', 'Program Managers', 'n/a', '2016-12-01', 'Sandra Guadagnoli','2017-01-04',334,0.88,0.8,0.85,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,45,'AMERICAs','Learning','n/a', 'Program Managers/Program Specialists', 'n/a', '2016-12-01', 'Sandra Guadagnoli','2017-01-04',4648,0.85,0.8,0.85,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,46,'AMERICAs','Learning','n/a', 'Learning Support', 'n/a', '2016-12-01', 'Sandra Guadagnoli','2017-01-04',2275,1.04,0.8,0.95,0.116804636);
INSERT INTO analytics.metrics_data2 values (null,10,'AMERICAs','Risk','n/a', 'Client Service - EHS', 'n/a', '2016-12-01', 'Sandra Guadagnoli','2017-01-04',5,0.75,0.665,0.7,0.0625);
INSERT INTO analytics.metrics_data2 values (null,10,'AMERICAs','Risk','n/a', 'Client Service - GRC PS', 'n/a', '2016-12-01', 'Sandra Guadagnoli','2017-01-04',7,0.73,0.5,0.57,0.0625);
INSERT INTO analytics.metrics_data2 values (null,52,'AMERICAs','Risk','n/a', 'Client Services - EHS', 'n/a', '2016-12-01', 'Sandra Guadagnoli','2017-01-04',39,1,0.8,0.85,0.1128328992);
INSERT INTO analytics.metrics_data2 values (null,52,'AMERICAs','Risk','n/a', 'Professional Services Team', 'n/a', '2016-12-01', 'Sandra Guadagnoli','2017-01-04',130,0.98,0.8,0.85,0.1128328992);
INSERT INTO analytics.metrics_data2 values (null,51,'AMERICAs','Risk','n/a', 'Client Services - EHS', 'n/a', '2016-12-01', 'Sandra Guadagnoli','2017-01-04',39,0.87,0.8,0.85,0.1128328992);
INSERT INTO analytics.metrics_data2 values (null,51,'AMERICAs','Risk','n/a', 'Professional Services Team', 'n/a', '2016-12-01', 'Sandra Guadagnoli','2017-01-04',130,0.92,0.8,0.85,0.1128328992);
INSERT INTO analytics.metrics_data2 values (null,53,'AMERICAs','Risk','n/a', 'Professional Services Team', 'n/a', '2016-12-01', 'Sandra Guadagnoli','2017-01-04',7,0.72,0.65,0.7,0.0752219328);
INSERT INTO analytics.metrics_data2 values (null,54,'AMERICAs','Risk','n/a', 'Professional Services Team', 'n/a', '2016-12-01', 'Sandra Guadagnoli','2017-01-04',5,0.8,0.65,0.7,0.0752219328);
INSERT INTO analytics.metrics_data2 values (null,47,'AMERICAs','Risk','n/a', 'C360 Support', 'n/a', '2016-12-01', 'Sandra Guadagnoli','2017-01-04',640,0.82,0.8,0.95,0.0752219328);

INSERT INTO analytics.metrics_data2 values (null,39,'AMERICAs','Learning','n/a', 'QA', 'n/a', '2016-12-01', 'Rebecca Turco','2017-01-05',328,0.96,0.95,1,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,40,'AMERICAs','Learning','n/a', 'QA', 'n/a', '2016-12-01', 'Rebecca Turco','2017-01-05',112,0.98,0.95,1,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,41,'AMERICAs','Learning','n/a', 'Project Management-English', 'n/a', '2016-12-01', 'Rebecca Turco','2017-01-05',750,0.95,0.95,1,0.116804636);
INSERT INTO analytics.metrics_data2 values (null,42,'AMERICAs','Learning','n/a', 'Project Management-Translations', 'n/a', '2016-12-01', 'Rebecca Turco','2017-01-05',756,0.93,0.95,1,0.116804636);

#Jan 2017
INSERT INTO analytics.metrics_data2 values (null,48,'AMERICAs','Learning','n/a', 'Program Managers', 'n/a', '2017-01-01', 'Sandra Guadagnoli','2017-02-03',331,0.99,0.75,0.8,0.225);
INSERT INTO analytics.metrics_data2 values (null,44,'AMERICAs','Learning','n/a', 'Learning Support', 'n/a', '2017-01-01', 'Sandra Guadagnoli','2017-02-03',539,0.88,0.8,0.85,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,50,'AMERICAs','Learning','n/a', 'Program Managers', 'n/a', '2017-01-01', 'Sandra Guadagnoli','2017-02-03',331,0.95,0.8,0.85,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,49,'AMERICAs','Learning','n/a', 'Program Managers', 'n/a', '2017-01-01', 'Sandra Guadagnoli','2017-02-03',331,0.87,0.8,0.85,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,45,'AMERICAs','Learning','n/a', 'Program Managers/Program Specialists', 'n/a', '2017-01-01', 'Sandra Guadagnoli','2017-02-03',3924,0.99,0.8,0.85,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,46,'AMERICAs','Learning','n/a', 'Learning Support', 'n/a', '2017-01-01', 'Sandra Guadagnoli','2017-02-03',4431,0.54,0.8,0.95,0.116804636);
INSERT INTO analytics.metrics_data2 values (null,10,'AMERICAs','Risk','n/a', 'Client Service - EHS', 'n/a', '2017-01-01', 'Sandra Guadagnoli','2017-02-03',5,0.79,0.665,0.7,0.0625);
INSERT INTO analytics.metrics_data2 values (null,10,'AMERICAs','Risk','n/a', 'Client Service - GRC PS', 'n/a', '2017-01-01', 'Sandra Guadagnoli','2017-02-03',10,0.49,0.5,0.57,0.0625);
INSERT INTO analytics.metrics_data2 values (null,52,'AMERICAs','Risk','n/a', 'Client Services - EHS', 'n/a', '2017-01-01', 'Sandra Guadagnoli','2017-02-03',39,1,0.8,0.85,0.1128328992);
INSERT INTO analytics.metrics_data2 values (null,52,'AMERICAs','Risk','n/a', 'Professional Services Team', 'n/a', '2017-01-01', 'Sandra Guadagnoli','2017-02-03',133,0.97,0.8,0.85,0.1128328992);
INSERT INTO analytics.metrics_data2 values (null,51,'AMERICAs','Risk','n/a', 'Client Services - EHS', 'n/a', '2017-01-01', 'Sandra Guadagnoli','2017-02-03',39,0.87,0.8,0.85,0.1128328992);
INSERT INTO analytics.metrics_data2 values (null,51,'AMERICAs','Risk','n/a', 'Professional Services Team', 'n/a', '2017-01-01', 'Sandra Guadagnoli','2017-02-03',133,0.92,0.8,0.85,0.1128328992);
INSERT INTO analytics.metrics_data2 values (null,53,'AMERICAs','Risk','n/a', 'Professional Services Team', 'n/a', '2017-01-01', 'Sandra Guadagnoli','2017-02-03',12,0.42,0.65,0.7,0.0752219328);
INSERT INTO analytics.metrics_data2 values (null,54,'AMERICAs','Risk','n/a', 'Professional Services Team', 'n/a', '2017-01-01', 'Sandra Guadagnoli','2017-02-03',5,0.8,0.65,0.7,0.0752219328);
INSERT INTO analytics.metrics_data2 values (null,47,'AMERICAs','Risk','n/a', 'C360 Support', 'n/a', '2017-01-01', 'Sandra Guadagnoli','2017-02-03',640,0.82,0.8,0.95,0.0752219328);

INSERT INTO analytics.metrics_data2 values (null,39,'AMERICAs','Learning','n/a', 'QA', 'n/a', '2017-01-01', 'Rebecca Turco','2017-02-09',290,0.96,0.95,1,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,40,'AMERICAs','Learning','n/a', 'QA', 'n/a', '2017-01-01', 'Rebecca Turco','2017-02-09',124,0.95,0.95,1,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,41,'AMERICAs','Learning','n/a', 'Project Management-English', 'n/a', '2017-01-01', 'Rebecca Turco','2017-02-09',812,0.95,0.95,1,0.116804636);
INSERT INTO analytics.metrics_data2 values (null,42,'AMERICAs','Learning','n/a', 'Project Management-Translations', 'n/a', '2017-01-01', 'Rebecca Turco','2017-02-09',875,1,0.95,1,0.116804636);

# Feb 2017
INSERT INTO analytics.metrics_data2 values (null,48,'AMERICAs','Learning','n/a', 'Program Managers', 'n/a', '2017-02-01', 'Sandra Guadagnoli','2017-03-06',330,0.8,0.75,0.8,0.225);
INSERT INTO analytics.metrics_data2 values (null,44,'AMERICAs','Learning','n/a', 'Learning Support', 'n/a', '2017-02-01', 'Sandra Guadagnoli','2017-03-06',1679,0.8,0.8,0.85,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,50,'AMERICAs','Learning','n/a', 'Program Managers', 'n/a', '2017-02-01', 'Sandra Guadagnoli','2017-03-06',330,0.95,0.8,0.85,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,49,'AMERICAs','Learning','n/a', 'Program Managers', 'n/a', '2017-02-01', 'Sandra Guadagnoli','2017-03-06',330,0.87,0.8,0.85,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,45,'AMERICAs','Learning','n/a', 'Program Managers/Program Specialists', 'n/a', '2017-02-01', 'Sandra Guadagnoli','2017-03-06',3924,0.99,0.8,0.85,0.058402318);
INSERT INTO analytics.metrics_data2 values (null,46,'AMERICAs','Learning','n/a', 'Learning Support', 'n/a', '2017-02-01', 'Sandra Guadagnoli','2017-03-06',5482,0.97,0.8,0.95,0.116804636);
INSERT INTO analytics.metrics_data2 values (null,10,'AMERICAs','Risk','n/a', 'Client Service - EHS', 'n/a', '2017-02-01', 'Sandra Guadagnoli','2017-03-06',5,0.81,0.665,0.7,0.0625);
INSERT INTO analytics.metrics_data2 values (null,10,'AMERICAs','Risk','n/a', 'Client Service - GRC PS', 'n/a', '2017-02-01', 'Sandra Guadagnoli','2017-03-06',9.5,0.67,0.5,0.57,0.0625);
INSERT INTO analytics.metrics_data2 values (null,52,'AMERICAs','Risk','n/a', 'Client Services - EHS', 'n/a', '2017-02-01', 'Sandra Guadagnoli','2017-03-06',37,1,0.8,0.85,0.1128328992);
INSERT INTO analytics.metrics_data2 values (null,52,'AMERICAs','Risk','n/a', 'Professional Services Team', 'n/a', '2017-02-01', 'Sandra Guadagnoli','2017-03-06',136,0.97,0.8,0.85,0.1128328992);
INSERT INTO analytics.metrics_data2 values (null,51,'AMERICAs','Risk','n/a', 'Client Services - EHS', 'n/a', '2017-02-01', 'Sandra Guadagnoli','2017-03-06',37,0.92,0.8,0.85,0.1128328992);
INSERT INTO analytics.metrics_data2 values (null,51,'AMERICAs','Risk','n/a', 'Professional Services Team', 'n/a', '2017-02-01', 'Sandra Guadagnoli','2017-03-06',136,0.92,0.8,0.85,0.1128328992);
INSERT INTO analytics.metrics_data2 values (null,53,'AMERICAs','Risk','n/a', 'Professional Services Team', 'n/a', '2017-02-01', 'Sandra Guadagnoli','2017-03-06',8,0.2,0.65,0.7,0.0752219328);
INSERT INTO analytics.metrics_data2 values (null,54,'AMERICAs','Risk','n/a', 'Professional Services Team', 'n/a', '2017-02-01', 'Sandra Guadagnoli','2017-03-06',5,1,0.65,0.7,0.0752219328);
INSERT INTO analytics.metrics_data2 values (null,47,'AMERICAs','Risk','n/a', 'C360 Support', 'n/a', '2017-02-01', 'Sandra Guadagnoli','2017-03-06',963,1.03,0.8,0.95,0.0752219328);

