# Backlog
SELECT 
        'Admin EMEA' AS `Team`,
        '' AS `User`,
        'Reprocess Certificate in Compass (ASEMAdmin 70)' AS `Activity`,
        COUNT(DISTINCT `t`.`Id`) AS `WIP`,
        DATE_FORMAT(NOW(), '%d/%m/%Y') AS `Date/Time`
    FROM
        `analytics`.`sla_arg_v2` `t`
    WHERE
		`t`.`Standards` NOT LIKE '%BRC%'
        AND `t`.`Standards` NOT LIKE '%WQA%'
		AND `t`.`Standards` NOT LIKE '%Woolworths%'
		AND (`t`.`Standard Families` NOT LIKE '%WQA%' or `t`.`Standard Families` is null)
		AND (`t`.`Standard Families` NOT LIKE '%Woolworths%' or `t`.`Standard Families` is null)
        AND `t`.`To` is null
        AND `t`.`Region` like 'EMEA-UK'
        AND t.`Metric` = 'ARG Completion/Hold'
    GROUP BY `Team` , `User` , `Activity`
UNION
SELECT 
        'Admin EMEA' AS `Team`,
        '' AS `User`,
        'Produce Certificate Approval (ASEMAdmin 17)' AS `Activity`,
        COUNT(DISTINCT `t`.`Id`) AS `WIP`,
        DATE_FORMAT(NOW(), '%d/%m/%Y') AS `Date/Time`
    FROM
        `analytics`.`sla_arg_v2` `t`
    WHERE
		`t`.`Standards` LIKE '%BRC%'
        AND `t`.`Standards` NOT LIKE '%WQA%'
		AND `t`.`Standards` NOT LIKE '%Woolworths%'
		AND (`t`.`Standard Families` NOT LIKE '%WQA%' or `t`.`Standard Families` is null)
		AND (`t`.`Standard Families` NOT LIKE '%Woolworths%' or `t`.`Standard Families` is null)
        AND `t`.`To` is null
        AND `t`.`Region` like 'EMEA-UK'
        AND t.`Metric` = 'ARG Completion/Hold'
    GROUP BY `Team` , `User` , `Activity`
UNION
SELECT 
        'Admin EMEA' AS `Team`,
        '' AS `User`,
        'Print Certificate  - Food (ASEMAdmin 18)' AS `Activity`,
        COUNT(DISTINCT `t`.`Id`) AS `WIP`,
        DATE_FORMAT(NOW(), '%d/%m/%Y') AS `Date/Time`
    FROM
        `analytics`.`sla_arg_v2` `t`
    WHERE
		`t`.`Standards` LIKE '%BRC%'
        AND `t`.`Standards` NOT LIKE '%WQA%'
		AND `t`.`Standards` NOT LIKE '%Woolworths%'
		AND (`t`.`Standard Families` NOT LIKE '%WQA%' or `t`.`Standard Families` is null)
		AND (`t`.`Standard Families` NOT LIKE '%Woolworths%' or `t`.`Standard Families` is null)
        AND `t`.`To` is null
        AND `t`.`Region` like 'EMEA-UK'
        AND t.`Metric` = 'ARG Completion/Hold'
    GROUP BY `Team` , `User` , `Activity`;

# Activities Completed
SELECT 
        'Admin EMEA' AS `Team`,
        t.`Owner` AS `User`,
        'Reprocess Certificate in Compass (ASEMAdmin 70)' AS `Activity`,
        COUNT(DISTINCT `t`.`Id`) AS `Completed`,
        DATE_FORMAT(NOW(), '%d/%m/%Y') AS `Date/Time`
    FROM
        `analytics`.`sla_arg_v2` `t`
    WHERE
		`t`.`Standards` NOT LIKE '%BRC%'
        AND `t`.`Standards` NOT LIKE '%WQA%'
		AND `t`.`Standards` NOT LIKE '%Woolworths%'
		AND (`t`.`Standard Families` NOT LIKE '%WQA%' or `t`.`Standard Families` is null)
		AND (`t`.`Standard Families` NOT LIKE '%Woolworths%' or `t`.`Standard Families` is null)
        AND `t`.`To` is not null
        AND `t`.`To` >= date_add(utc_timestamp(), interval -24 hour)
        AND `t`.`Region` like 'EMEA-UK'
        AND t.`Metric` = 'ARG Completion/Hold'
    GROUP BY `Team` , `User` , `Activity`
UNION
SELECT 
        'Admin EMEA' AS `Team`,
        `t`.`Owner` AS `User`,
        'Produce Certificate Approval (ASEMAdmin 17)' AS `Activity`,
        COUNT(DISTINCT `t`.`Id`) AS `WIP`,
        DATE_FORMAT(NOW(), '%d/%m/%Y') AS `Date/Time`
    FROM
        `analytics`.`sla_arg_v2` `t`
    WHERE
		`t`.`Standards` LIKE '%BRC%'
        AND `t`.`Standards` NOT LIKE '%WQA%'
		AND `t`.`Standards` NOT LIKE '%Woolworths%'
		AND (`t`.`Standard Families` NOT LIKE '%WQA%' or `t`.`Standard Families` is null)
		AND (`t`.`Standard Families` NOT LIKE '%Woolworths%' or `t`.`Standard Families` is null)
        AND `t`.`To` is not null
        AND `t`.`To` >= date_add(utc_timestamp(), interval -24 hour)
        AND `t`.`Region` like 'EMEA-UK'
        AND t.`Metric` = 'ARG Completion/Hold'
    GROUP BY `Team` , `User` , `Activity`
UNION
SELECT 
        'Admin EMEA' AS `Team`,
        `t`.`Owner` AS `User`,
        'Print Certificate  - Food (ASEMAdmin 18)' AS `Activity`,
        COUNT(DISTINCT `t`.`Id`) AS `WIP`,
        DATE_FORMAT(NOW(), '%d/%m/%Y') AS `Date/Time`
    FROM
        `analytics`.`sla_arg_v2` `t`
    WHERE
		`t`.`Standards` LIKE '%BRC%'
        AND `t`.`Standards` NOT LIKE '%WQA%'
		AND `t`.`Standards` NOT LIKE '%Woolworths%'
		AND (`t`.`Standard Families` NOT LIKE '%WQA%' or `t`.`Standard Families` is null)
		AND (`t`.`Standard Families` NOT LIKE '%Woolworths%' or `t`.`Standard Families` is null)
        AND `t`.`To` is not null
        AND `t`.`To` >= date_add(utc_timestamp(), interval -24 hour)
        AND `t`.`Region` like 'EMEA-UK'
        AND t.`Metric` = 'ARG Completion/Hold'
    GROUP BY `Team` , `User` , `Activity`;
    
    
SELECT 
        *
    FROM
        `analytics`.`sla_arg_v2` `t`
    WHERE
		#`t`.`Standards` LIKE '%BRC%' AND 
        `t`.`Standards` NOT LIKE '%WQA%'
		AND `t`.`Standards` NOT LIKE '%Woolworths%'
		AND (`t`.`Standard Families` NOT LIKE '%WQA%' or `t`.`Standard Families` is null)
		AND (`t`.`Standard Families` NOT LIKE '%Woolworths%' or `t`.`Standard Families` is null)
        AND `t`.`To` is null
        AND `t`.`Region` like 'EMEA-UK'
        AND t.`Metric` = 'ARG Completion/Hold'
        and t.`Tags` not like '%Follow Up%'
    ;