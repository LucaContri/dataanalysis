DELIMITER $$
CREATE FUNCTION `getGlobalAccount`(Standard VARCHAR(128), FoS VARCHAR(512)) RETURNS varchar(64)
BEGIN
	DECLARE globalAccount VARCHAR(64) DEFAULT null;
    DECLARE allStandards VARCHAR(1024) DEFAULT null;
    SET allStandards = (SELECT concat(ifnull(Standard,''), ifnull(FoS,'')));
    SET globalAccount = (SELECT 
		if(allStandards like '%Woolworths%' or allStandards like '%WQA%', 'Woolworths',
        if(allStandards like '%Tesco%', 'Tesco',
        if(allStandards like '%McDonalds%', 'McDonalds',
        if(allStandards like '%Marks & Spencer%', 'Marks & Spencer',
        if(allStandards like '%BRC%', 'BRC',null
		))))));
        
    RETURN globalAccount;
 END$$
DELIMITER ;

# global_accounts_ops_metrics_v3. Itemised by Metric, Business Line, Country, Program, Global Account, Period
create or replace view global_accounts_ops_metrics_v3 as
#ARG rejection rate
(select
	t.`_Type`, 
	t.`_Metric`,
	t.`Business Line`,
	t.`Country`,
	t.`Program`,
	getGlobalAccount(t.`Standards`, t.`FoS`) as 'Global Account',
	t.`Period`,
	sum(t.`Volume`) as 'Volume',
	sum(t.`Sum Value`) as 'Sum Value', #distinct ah.Id means I am counting each rejection
	(sum(t.`Volume`) - sum(t.`Sum Value`)) as 'Volume within SLA',
	t.`Target`,
	null as 'Auto-Approved',
	null as 'With-Hold',
    null as 'With TR'
from global_ops_metrics_rejections_sub_v3 t
where ((t.`Standards` like '%Woolworths%' or t.`Standards` like '%WQA%' or t.`FoS` like '%Woolworths%' or t.`FoS` like '%WQA%')
	or (t.`Standards` like '%McDonalds%' or t.`FoS` like '%McDonalds%')
    or (t.`Standards` like '%Tesco%' or t.`FoS` like '%Tesco%')
    or (t.`Standards` like '%Marks & Spencer%' or t.`FoS` like '%Marks & Spencer%')
    or (t.`Standards` like '%BRC%' or t.`FoS` like '%BRC%')
    )
group by t.`_Type`, t.`_Metric`, t.`Business Line`, t.`Country`, t.`Program`, `Global Account`, t.`Period`, `Auto-Approved`, `With-Hold`, `With TR`
)

union
# ARG Performance and Backlog
(select 
	t.`_Type`, 
	t.`_Metric`, 
	t.`Business Line`,
	t.`Country`,
	t.`Program`,
	getGlobalAccount(t.`Standards`, t.`FoS`) as 'Global Account',
	t.`Period`, 
    sum(t.`Volume`) as 'Volume',
    sum(t.`Sum Value`) as 'Sum Value',
    sum(t.`Volume within SLA`) as 'Volume within SLA',
    t.`Target`,
    t.`Auto-Approved`,
    t.`With-Hold`,
    null as 'With TR'
from global_ops_arg_performance t
where t.`Standards` is not null
and ((t.`Standards` like '%Woolworths%' or t.`Standards` like '%WQA%' or t.`FoS` like '%Woolworths%' or t.`FoS` like '%WQA%')
	or (t.`Standards` like '%McDonalds%' or t.`FoS` like '%McDonalds%')
    or (t.`Standards` like '%Tesco%' or t.`FoS` like '%Tesco%')
    or (t.`Standards` like '%Marks & Spencer%' or t.`FoS` like '%Marks & Spencer%')
    or (t.`Standards` like '%BRC%' or t.`FoS` like '%BRC%')
    )
group by t.`_Type`, t.`_Metric`, t.`Business Line`, t.`Country`, t.`Program`, `Global Account`, t.`Period`, t.`Auto-Approved`, t.`With-Hold`, `With TR`)
union
(select `Type`,`Metric`,`Business Line`, `Country`, `Program`, `Global Account`, `Period`, `Volume`, `Sum Value`, `Volume within SLA`, `Target`, `Auto-Approved`, `With-Hold`, `With TR` from global_ops_dummy_records)
union

# ARG end-to-end process
(select 
	'Performance' as '_Type',
	t.`_Metric`, 
	t.`Business Line`,
	substring_index(t.`Country`, ' - ',-1) as '_Country',
	t.`Program`,
	getGlobalAccount(t.`Standards`, t.`FoS`) as 'Global Account',
	t.`Period`,
	sum(t.`Volume`) as 'Volume',
	sum(`Sum Value`) as 'Sum Value',
	null as 'Volume within SLA',
	null as 'Target',
	t.`Auto-Approved`,
	t.`With Hold`,
    t.`With TR`
from global_ops_metric_arg_end_to_end_1_v3_2 t
where t.`Period` >= '2015 07'
and ((t.`Standards` like '%Woolworths%' or t.`Standards` like '%WQA%' or t.`FoS` like '%Woolworths%' or t.`FoS` like '%WQA%')
	or (t.`Standards` like '%McDonalds%' or t.`FoS` like '%McDonalds%')
    or (t.`Standards` like '%Tesco%' or t.`FoS` like '%Tesco%')
    or (t.`Standards` like '%Marks & Spencer%' or t.`FoS` like '%Marks & Spencer%')
    or (t.`Standards` like '%BRC%' or t.`FoS` like '%BRC%')
    )
group by `_Type`, t.`_Metric`, t.`Business Line`, t.`Country`, t.`Program`, `Global Account`, t.`Period`, t.`Auto-Approved`, t.`With Hold`, t.`With TR`)
union
(select 
	'Performance' as '_Type',
	'ARG End-to-End'as '_Metric', 
	t.`Business Line`,
	substring_index(t.`Country`, ' - ',-1) as '_Country',
	t.`Program`,
	getGlobalAccount(t.`Standards`, t.`FoS`) as 'Global Account',
	t.`Period`,
    sum(t.`Volume`) as 'Volume',
	sum(t.`Sum Value`) as 'Sum Value',
	sum(if(t.`Sum Value`<=if(t.`Auto-Approved`,7,21),1,0)) as 'Volume within SLA',
	if(t.`Auto-Approved`,7,21) as 'Target',
    t.`Auto-Approved`,
    t.`With Hold`,
    t.`With TR`
from global_ops_metric_arg_end_to_end_2_v3_2 t
where t.`Period` >= '2015 07'
and ((t.`Standards` like '%Woolworths%' or t.`Standards` like '%WQA%' or t.`FoS` like '%Woolworths%' or t.`FoS` like '%WQA%')
	or (t.`Standards` like '%McDonalds%' or t.`FoS` like '%McDonalds%')
    or (t.`Standards` like '%Tesco%' or t.`FoS` like '%Tesco%')
    or (t.`Standards` like '%Marks & Spencer%' or t.`FoS` like '%Marks & Spencer%')
    or (t.`Standards` like '%BRC%' or t.`FoS` like '%BRC%')
    )
group by `_Type`, `_Metric`, t.`Business Line`, t.`Country`, t.`Program`, `Global Account`, t.`Period`, t.`Auto-Approved`, t.`With Hold`, t.`With TR`);

(select * from global_accounts_ops_metrics_v3);

# global_accounts_ops_metrics_details. Itemised by ARG, Metric
create or replace view global_accounts_ops_metrics_details as
#ARG rejection rate
(select
	t.`_Type`, 
	t.`_Metric`,
	t.`Business Line`,
	t.`Country`,
	t.`Owner`,
	t.`Program`,
	t.`Standards`,
    t.`Fos`,
    getGlobalAccount(t.`Standards`, t.`FoS`) as 'Global Account',
	t.`Period`,
	sum(t.`Volume`) as 'Volume',
	sum(t.`Sum Value`) as 'Sum Value', #distinct ah.Id means I am counting each rejection
	(sum(t.`Volume`) - sum(t.`Sum Value`)) as 'Volume within SLA',
	t.`Target`,
	ifnull(group_concat(t.`Items`),'') as 'Items',
	null as 'Auto-Approved',
	null as 'With-Hold',
    null as 'With TR'
from global_ops_metrics_rejections_sub_v3 t
where ((t.`Standards` like '%Woolworths%' or t.`Standards` like '%WQA%' or t.`FoS` like '%Woolworths%' or t.`FoS` like '%WQA%')
	or (t.`Standards` like '%McDonalds%' or t.`FoS` like '%McDonalds%')
    or (t.`Standards` like '%Tesco%' or t.`FoS` like '%Tesco%')
    or (t.`Standards` like '%Marks & Spencer%' or t.`FoS` like '%Marks & Spencer%')
    or (t.`Standards` like '%BRC%' or t.`FoS` like '%BRC%')
    )
    and t.`Period` >= '2015 07'
group by t.`Id`,t.`_Type`, t.`_Metric`, t.`Country`, t.`Owner`, t.`Standards`, t.`Target`, t.`Period`
)
union
(select * from global_ops_dummy_records)
union
# ARG Performance and Backlog
(select 
	t.`_Type`, 
	t.`_Metric`, 
	t.`Business Line`,
	t.`Country`,
	t.`_Owner`,
	t.`Program`,
	t.`Standards`,
    t.`FoS`,
    getGlobalAccount(t.`Standards`, t.`FoS`) as 'Global Account',
	t.`Period`, 
    sum(t.`Volume`) as 'Volume',
    sum(t.`Sum Value`) as 'Sum Value',
    sum(t.`Volume within SLA`) as 'Volume within SLA',
    t.`Target`,
    group_concat(t.`Items`) as 'Items',
    t.`Auto-Approved`,
    t.`With-Hold`,
    null as 'With TR'
from global_ops_arg_performance t
where t.`Standards` is not null
and ((t.`Standards` like '%Woolworths%' or t.`Standards` like '%WQA%' or t.`FoS` like '%Woolworths%' or t.`FoS` like '%WQA%')
	or (t.`Standards` like '%McDonalds%' or t.`FoS` like '%McDonalds%')
    or (t.`Standards` like '%Tesco%' or t.`FoS` like '%Tesco%')
    or (t.`Standards` like '%Marks & Spencer%' or t.`FoS` like '%Marks & Spencer%')
    or (t.`Standards` like '%BRC%' or t.`FoS` like '%BRC%')
    )
 and (t.`Period` >= '2015 07' or t.`Period` is null)
group by t.`Id`,t.`_Type`, t.`_Metric`, t.`Country`, t.`_Owner`, t.`Standards`, t.`Target`, t.`Period`)
union

# ARG end-to-end process
(select 
	'Performance' as '_Type',
	t.`_Metric`, 
	t.`Business Line`,
	substring_index(t.`Country`, ' - ',-1) as '_Country',
	null as 'Owner',
	t.`Program`,
	t.`Standards`,
    t.`Fos`,
    getGlobalAccount(t.`Standards`, t.`FoS`) as 'Global Account',
	t.`Period`,
	sum(t.`Volume`) as 'Volume',
	sum(`Sum Value`) as 'Sum Value',
	null as 'Volume within SLA',
	null as 'Target',
	group_concat(t.`Items`) as 'Items',
    t.`Auto-Approved`,
	t.`With Hold`,
    t.`With TR`
from global_ops_metric_arg_end_to_end_1_v3_2 t
where t.`Period` >= '2015 07'
and ((t.`Standards` like '%Woolworths%' or t.`Standards` like '%WQA%' or t.`FoS` like '%Woolworths%' or t.`FoS` like '%WQA%')
	or (t.`Standards` like '%McDonalds%' or t.`FoS` like '%McDonalds%')
    or (t.`Standards` like '%Tesco%' or t.`FoS` like '%Tesco%')
    or (t.`Standards` like '%Marks & Spencer%' or t.`FoS` like '%Marks & Spencer%')
    or (t.`Standards` like '%BRC%' or t.`FoS` like '%BRC%')
    )
group by t.`Id`,`_Type`, t.`_Metric`, `_Country`, `Owner`, `Standards`, `Target`, `Period`, `Auto-Approved`, `With Hold`, `With TR`)
union
(select 
	'Performance' as '_Type',
	'ARG End-to-End'as '_Metric', 
	t.`Business Line`,
	substring_index(t.`Country`, ' - ',-1) as '_Country',
	null as '_Owner',
	t.`Program`,
	t.`Standards`,
    t.`Fos`,
    getGlobalAccount(t.`Standards`, t.`FoS`) as 'Global Account',
	t.`Period`,
    sum(t.`Volume`) as 'Volume',
	sum(t.`Sum Value`) as 'Sum Value',
	sum(if(t.`Sum Value`<=if(t.`Auto-Approved`,7,21),1,0)) as 'Volume within SLA',
	if(t.`Auto-Approved`,7,21) as 'Target',
    group_concat(distinct t.`Items`) as 'Items',
    t.`Auto-Approved`,
    t.`With Hold`,
    t.`With TR`
from global_ops_metric_arg_end_to_end_2_v3_2 t
where t.`Period` >= '2015 07'
and ((t.`Standards` like '%Woolworths%' or t.`Standards` like '%WQA%' or t.`FoS` like '%Woolworths%' or t.`FoS` like '%WQA%')
	or (t.`Standards` like '%McDonalds%' or t.`FoS` like '%McDonalds%')
    or (t.`Standards` like '%Tesco%' or t.`FoS` like '%Tesco%')
    or (t.`Standards` like '%Marks & Spencer%' or t.`FoS` like '%Marks & Spencer%')
    or (t.`Standards` like '%BRC%' or t.`FoS` like '%BRC%')
    )
group by t.`Id`, `_Type`, `_Metric`, `_Country`, `_Owner`, `Standards`, `Target`, `Period`, `Auto-Approved`, `With Hold`, `With TR`);