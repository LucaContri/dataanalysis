create database enlighten;
use enlighten;

CREATE TABLE `activity_standard` (
  `activity_standard_id` int(11) NOT NULL AUTO_INCREMENT,
  `activity_code` varchar(64) NOT NULL,
  `activity_name` varchar(255) DEFAULT NULL,
  `uph` decimal(12,2) DEFAULT NULL,
  `effective_date` datetime DEFAULT NULL,
  `time_only` varchar(64) DEFAULT NULL,
  `until_date` datetime DEFAULT NULL,
  `stopped_date` datetime DEFAULT NULL,
  PRIMARY KEY (`activity_standard_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1236 DEFAULT CHARSET=utf8;

CREATE TABLE `org_charts_relationships` (
  `org_charts_relationships_id` int(11) NOT NULL AUTO_INCREMENT,
  `parent_org_chart_entry` varchar(255) NOT NULL,
  `org_chart_entry` varchar(255) DEFAULT NULL,
  `effective_date` datetime DEFAULT NULL,
  `until_date` datetime DEFAULT NULL,
  `stopped_date` datetime DEFAULT NULL,
  PRIMARY KEY (`org_charts_relationships_id`)
) ENGINE=InnoDB AUTO_INCREMENT=192 DEFAULT CHARSET=utf8;
truncate org_charts_relationships;

drop table volume_completion;
CREATE TABLE `volume_completion` (
  #`volume_completion_id` int(11) NOT NULL AUTO_INCREMENT,
  `date_completed` datetime DEFAULT NULL,
  `activity_code` varchar(64) DEFAULT NULL,
  `activity_name` varchar(255) DEFAULT NULL,
  `org_chart_entry_name` varchar(255) DEFAULT NULL,
  `last_name` varchar(64) DEFAULT NULL,
  `first_name` varchar(64) DEFAULT NULL,
  `units` int(11) NOT NULL,
  `uncommitted_units` int(11) NOT NULL
  #PRIMARY KEY (`volume_completion_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;

#truncate enlighten.volume_completion;
create index volume_completion_org_chart_index on enlighten.volume_completion(org_chart_entry_name);
create index activity_standard_activity_code_index on enlighten.activity_standard(activity_code);
create index org_charts_relationships_index on enlighten.org_charts_relationships(org_chart_entry);

#explain
(select vc.activity_code, vc.activity_name, vc.date_completed, concat(vc.first_name,' ', vc.last_name) as 'Resource', vc.org_chart_entry_name, vc.units*60/acs.uph as 'Duration (min)' from enlighten.volume_completion vc
left join enlighten.activity_standard acs on vc.activity_code = acs.activity_code and vc.date_completed>=acs.effective_date
left join enlighten.org_charts_relationships oc on vc.org_chart_entry_name = oc.org_chart_entry

where oc.org_chart_entry is null
group by vc.org_chart_entry_name );

select substring_index('1,2,3,4',',',1), substring_index(substring_index('-,2,3,4',',',2),',',-1), substring_index('1,2,3,4',',',-3), substring_index('1,2,3,4',',',-2), substring_index('1,2,3,4',',',-1);

#explain
(select 
	t.*, 
	substring_index(t.`Org Chart Name Full Name`,',',1) as 'Level 1',
	substring_index(substring_index(t.`Org Chart Name Full Name`,',',2),',',-1) as 'Level 2',
	substring_index(substring_index(t.`Org Chart Name Full Name`,',',3),',',-1) as 'Level 3',
	substring_index(substring_index(t.`Org Chart Name Full Name`,',',4),',',-1) as 'Level 4',
	substring_index(substring_index(t.`Org Chart Name Full Name`,',',5),',',-1) as 'Level 5',
	substring_index(substring_index(t.`Org Chart Name Full Name`,',',6),',',-1) as 'Level 6'
from
	(select 
		date_format(vc.date_completed, '%Y-%m') as 'Period', 
		concat(
			ifnull(concat(gggpoc.parent_org_chart_entry ,','),''),
			ifnull(concat(ggpoc.parent_org_chart_entry,','),''),
			ifnull(concat(gpoc.parent_org_chart_entry,','),''),
			ifnull(concat(poc.parent_org_chart_entry ,','),''),
            ifnull(concat(oc.parent_org_chart_entry ,','),''),
			ifnull(concat(oc.org_chart_entry,','),'')) as 'Org Chart Name Full Name', 
		vc.activity_code, 
        vc.activity_name, 
		concat(vc.first_name, ' ', vc.last_name) as 'Full Name',
		sum(vc.units*60/acs.uph) as 'Duration (min)' 
	from enlighten.volume_completion vc
		inner join enlighten.activity_standard acs on vc.activity_code = acs.activity_code and vc.date_completed>=acs.effective_date and vc.date_completed<ifnull(acs.until_date , '9999-12-31')
		inner join enlighten.org_charts_relationships oc on vc.org_chart_entry_name = oc.org_chart_entry
		left join enlighten.org_charts_relationships poc on oc.parent_org_chart_entry = poc.org_chart_entry
		left join enlighten.org_charts_relationships gpoc on poc.parent_org_chart_entry = gpoc.org_chart_entry
		left join enlighten.org_charts_relationships ggpoc on gpoc.parent_org_chart_entry = ggpoc.org_chart_entry
		left join enlighten.org_charts_relationships gggpoc on ggpoc.parent_org_chart_entry = gggpoc.org_chart_entry
	group by `Period`, vc.org_chart_entry_name, `Full Name`, vc.activity_code) t
);