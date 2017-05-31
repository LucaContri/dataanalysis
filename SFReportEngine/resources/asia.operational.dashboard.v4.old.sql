CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `luca`@`%` 
    SQL SECURITY DEFINER
VIEW `apac_ops_metrics_v4` AS
    (SELECT 
        `t`.`_Type` AS `_Type`,
        `t`.`_Metric` AS `_Metric`,
        `t`.`Business Line` AS `Business Line`,
        `t`.`Country` AS `Country`,
        '' AS `_Owner`,
        `t`.`Program` AS `Program`,
        '' AS `_Standards`,
        `t`.`Period` AS `Period`,
        SUM(`t`.`Volume`) AS `Volume`,
        SUM(`t`.`Sum Value`) AS `Sum Value`,
        (SUM(`t`.`Volume`) - SUM(`t`.`Sum Value`)) AS `Volume within SLA`,
        `t`.`Target` AS `Target`,
        '' AS `Items`,
        '' AS `Auto-Approved`,
        '' AS `With-Hold`,
        '' AS `With TR`,
        '' AS `With Waiting Client`,
        '' AS `Open_Sub_Status`,
        GETGLOBALACCOUNT(`t`.`Standards`, '') AS `Global Account`
    FROM
        `analytics`.`global_ops_metrics_rejections_sub_v3` `t`
    WHERE
        ((`t`.`Region` = 'APAC')
            AND (`t`.`Period` >= CONCAT((IF((MONTH(UTC_TIMESTAMP()) < 7),
                    YEAR(UTC_TIMESTAMP()),
                    (YEAR(UTC_TIMESTAMP()) + 1)) - 1),
                ' 07'))
            AND (`t`.`Period` <= CONCAT(IF((MONTH(UTC_TIMESTAMP()) < 7),
                    YEAR(UTC_TIMESTAMP()),
                    (YEAR(UTC_TIMESTAMP()) + 1)),
                ' 06')))
    GROUP BY `t`.`_Type` , `t`.`_Metric` , `t`.`Country` , `_Owner` , `t`.`Business Line` , `t`.`Program` , `_Standards` , `t`.`Period` , `Global Account`) UNION ALL (SELECT 
        `t`.`_Type` AS `_Type`,
        `t`.`_Metric` AS `_Metric`,
        `t`.`Business Line` AS `Business Line`,
        `t`.`Country` AS `Country`,
        '' AS `__Owner`,
        `t`.`Program` AS `Program`,
        '' AS `_Standards`,
        `t`.`Period` AS `Period`,
        SUM(`t`.`Volume`) AS `Volume`,
        SUM(`t`.`Sum Value`) AS `Sum Value`,
        SUM(`t`.`Volume within SLA`) AS `Volume within SLA`,
        `t`.`Target` AS `Target`,
        '' AS `Items`,
        '' AS `Auto-Approved`,
        '' AS `With-Hold`,
        '' AS `With TR`,
        '' AS `With Waiting Client`,
        '' AS `Open_Sub_Status`,
        GETGLOBALACCOUNT(`t`.`Standards`, '') AS `Global Account`
    FROM
        `analytics`.`global_ops_arg_performance` `t`
    WHERE
        ((`t`.`Standards` IS NOT NULL)
            AND (`t`.`Region` = 'APAC')
            AND ((`t`.`Period` >= CONCAT((IF((MONTH(UTC_TIMESTAMP()) < 7),
                    YEAR(UTC_TIMESTAMP()),
                    (YEAR(UTC_TIMESTAMP()) + 1)) - 1),
                ' 07'))
            OR ISNULL(`t`.`Period`))
            AND ((`t`.`Period` <= CONCAT(IF((MONTH(UTC_TIMESTAMP()) < 7),
                    YEAR(UTC_TIMESTAMP()),
                    (YEAR(UTC_TIMESTAMP()) + 1)),
                ' 06'))
            OR ISNULL(`t`.`Period`)))
    GROUP BY `t`.`_Type` , `t`.`_Metric` , `t`.`Country` , `__Owner` , `t`.`Business Line` , `t`.`Program` , `_Standards` , `t`.`Target` , `t`.`Period` , `Global Account`) UNION ALL (SELECT 
        'Performance' AS `_Type`,
        `t`.`_Metric` AS `_Metric`,
        `t`.`Business Line` AS `Business Line`,
        SUBSTRING_INDEX(`t`.`Country`, ' - ', -(1)) AS `_Country`,
        '' AS `_Owner`,
        `t`.`Program` AS `Program`,
        '' AS `_Standards`,
        `t`.`Period` AS `Period`,
        SUM(`t`.`Volume`) AS `Volume`,
        SUM(`t`.`Sum Value`) AS `Sum Value`,
        NULL AS `Volume within SLA`,
        NULL AS `Target`,
        '' AS `Items`,
        `t`.`Auto-Approved` AS `Auto-Approved`,
        `t`.`With Hold` AS `With Hold`,
        `t`.`With TR` AS `With TR`,
        `t`.`With Waiting Client` AS `With Waiting Client`,
        '' AS `Open_Sub_Status`,
        GETGLOBALACCOUNT(`t`.`Standards`, '') AS `Global Account`
    FROM
        `analytics`.`global_ops_metric_arg_end_to_end_1_v3_2` `t`
    WHERE
        ((`t`.`Region` = 'APAC')
            AND (`t`.`Period` >= CONCAT((IF((MONTH(UTC_TIMESTAMP()) < 7),
                    YEAR(UTC_TIMESTAMP()),
                    (YEAR(UTC_TIMESTAMP()) + 1)) - 1),
                ' 07'))
            AND (`t`.`Period` <= CONCAT(IF((MONTH(UTC_TIMESTAMP()) < 7),
                    YEAR(UTC_TIMESTAMP()),
                    (YEAR(UTC_TIMESTAMP()) + 1)),
                ' 06'))
            AND ((`t`.`Country` LIKE 'Australia')
            OR (`t`.`Country` LIKE 'Asia%')
            OR (`t`.`Country` LIKE '%Product%')))
    GROUP BY `_Type` , `t`.`_Metric` , `_Country` , `_Owner` , `t`.`Business Line` , `t`.`Program` , `_Standards` , `Target` , `t`.`Period` , `t`.`Auto-Approved` , `t`.`With Hold` , `t`.`With TR` , `Global Account`) UNION ALL (SELECT 
        'Performance' AS `_Type`,
        'ARG End-to-End' AS `_Metric`,
        `t`.`Business Line` AS `Business Line`,
        SUBSTRING_INDEX(`t`.`Country`, ' - ', -(1)) AS `_Country`,
        '' AS `_Owner`,
        `t`.`Program` AS `Program`,
        '' AS `_Standards`,
        `t`.`Period` AS `Period`,
        SUM(`t`.`Volume`) AS `Volume`,
        SUM(`t`.`Sum Value`) AS `Sum Value`,
        SUM(IF((`t`.`Sum Value` <= IF(`t`.`Auto-Approved`, 7, 21)),
            1,
            0)) AS `Volume within SLA`,
        IF(`t`.`Auto-Approved`, 7, 21) AS `Target`,
        '' AS `Items`,
        `t`.`Auto-Approved` AS `Auto-Approved`,
        `t`.`With Hold` AS `With Hold`,
        `t`.`With TR` AS `With TR`,
        `t`.`With Waiting Client` AS `With Waiting Client`,
        '' AS `Open_Sub_Status`,
        GETGLOBALACCOUNT(`t`.`Standards`, '') AS `Global Account`
    FROM
        `analytics`.`global_ops_metric_arg_end_to_end_2_v3_2` `t`
    WHERE
        ((`t`.`Region` = 'APAC')
            AND (`t`.`Period` >= CONCAT((IF((MONTH(UTC_TIMESTAMP()) < 7),
                    YEAR(UTC_TIMESTAMP()),
                    (YEAR(UTC_TIMESTAMP()) + 1)) - 1),
                ' 07'))
            AND (`t`.`Period` <= CONCAT(IF((MONTH(UTC_TIMESTAMP()) < 7),
                    YEAR(UTC_TIMESTAMP()),
                    (YEAR(UTC_TIMESTAMP()) + 1)),
                ' 06'))
            AND ((`t`.`Country` LIKE 'Australia')
            OR (`t`.`Country` LIKE 'Asia%')
            OR (`t`.`Country` LIKE '%Product%')))
    GROUP BY `_Type` , `_Metric` , `_Country` , `_Owner` , `t`.`Business Line` , `t`.`Program` , `_Standards` , `Target` , `t`.`Period` , `t`.`Auto-Approved` , `t`.`With Hold` , `t`.`With TR` , `Global Account`) UNION ALL (SELECT 
        'Performance' AS `_Type`,
        'Resource Utilisation' AS `_Metric`,
        'n/a' AS `Business Line`,
        `i`.`Country` AS `Country`,
        `i`.`Name` AS `_Owner`,
        '' AS `Program`,
        '' AS `_Standards`,
        `i`.`Period` AS `Period`,
        (((`j`.`Working Days` - (`i`.`Holiday Days` + `i`.`Leave Days`)) * `i`.`Resource Capacitiy (%)`) / 100) AS `Volume`,
        (`i`.`Audit Days` + `i`.`Travel Days`) AS `Sum Value`,
        IF((((`i`.`Audit Days` + `i`.`Travel Days`) / (((`j`.`Working Days` - (`i`.`Holiday Days` + `i`.`Leave Days`)) * `i`.`Resource Capacitiy (%)`) / 100)) >= 0.8),
            1,
            0) AS `Volume within SLA`,
        0.8 AS `Target`,
        '' AS `Items`,
        '' AS `Auto-Approved`,
        '' AS `With-Hold`,
        '' AS `With TR`,
        '' AS `With Waiting Client`,
        '' AS `Open_Sub_Status`,
        '' AS `Global Account`
    FROM
        (`analytics`.`global_ops_metrics_sub1_v3` `i`
        JOIN `analytics`.`global_ops_metrics_sub2` `j` ON ((`i`.`Period` = `j`.`Period`)))
    WHERE
        ((`j`.`Working Days` > (`i`.`Holiday Days` + `i`.`Leave Days`))
            AND (`i`.`Period` >= CONCAT((IF((MONTH(UTC_TIMESTAMP()) < 7),
                    YEAR(UTC_TIMESTAMP()),
                    (YEAR(UTC_TIMESTAMP()) + 1)) - 1),
                ' 07'))
            AND (`i`.`Period` <= CONCAT(IF((MONTH(UTC_TIMESTAMP()) < 7),
                    YEAR(UTC_TIMESTAMP()),
                    (YEAR(UTC_TIMESTAMP()) + 1)),
                ' 06'))
            AND (`i`.`Region` = 'APAC'))
    GROUP BY `i`.`Id` , `i`.`Period`) UNION ALL (SELECT 
        'Performance' AS `_Type`,
        'Contractor Usage' AS `_Metric`,
        `sp`.`Program_Business_Line__c` AS `Business Line`,
        IF((`wi`.`Revenue_Ownership__c` LIKE '%Product%'),
            'Product Services',
            IF((`wi`.`Revenue_Ownership__c` LIKE 'AUS%'),
                'Australia',
                SUBSTRING_INDEX(SUBSTRING_INDEX(`wi`.`Revenue_Ownership__c`, '-', 2),
                        '-',
                        -(1)))) AS `Country`,
        '' AS `_Owner`,
        `p`.`Name` AS `Program`,
        '' AS `_Standards`,
        DATE_FORMAT(`wi`.`Work_Item_Date__c`, '%Y %m') AS `Period`,
        SUM((`wi`.`Required_Duration__c` / 8)) AS `Volume`,
        SUM(IF((`r`.`Resource_Type__c` = 'Contractor'),
            (`wi`.`Required_Duration__c` / 8),
            0)) AS `Sum Value`,
        NULL AS `Volume within SLA`,
        0.2 AS `Target`,
        '' AS `Items`,
        '' AS `Auto-Approved`,
        '' AS `With-Hold`,
        '' AS `With TR`,
        '' AS `With Waiting Client`,
        '' AS `Open_Sub_Status`,
        GETGLOBALACCOUNT(`sp`.`Standard_Service_Type_Name__c`, '') AS `Global Account`
    FROM
        ((((`salesforce`.`work_item__c` `wi`
        JOIN `salesforce`.`resource__c` `r` ON ((`wi`.`RAudit_Report_Author__c` = `r`.`Id`)))
        JOIN `salesforce`.`site_certification_standard_program__c` `scsp` ON ((`wi`.`Site_Certification_Standard__c` = `scsp`.`Id`)))
        JOIN `salesforce`.`standard_program__c` `sp` ON ((`scsp`.`Standard_Program__c` = `sp`.`Id`)))
        JOIN `salesforce`.`program__c` `p` ON ((`sp`.`Program__c` = `p`.`Id`)))
    WHERE
        ((`wi`.`IsDeleted` = 0)
            AND (`wi`.`Status__c` NOT IN ('Cancelled' , 'Draft', 'Initiate Service', 'Budget'))
            AND ((`wi`.`Revenue_Ownership__c` LIKE 'AUS%')
            OR (`wi`.`Revenue_Ownership__c` LIKE 'Asia%'))
            AND (`wi`.`Work_Item_Stage__c` NOT IN ('Product Update' , 'Initial Project'))
            AND (`wi`.`Work_Item_Date__c` >= CONCAT((IF((MONTH(UTC_TIMESTAMP()) < 7),
                    YEAR(UTC_TIMESTAMP()),
                    (YEAR(UTC_TIMESTAMP()) + 1)) - 1),
                '-07-01'))
            AND (`wi`.`Work_Item_Date__c` <= CONCAT(IF((MONTH(UTC_TIMESTAMP()) < 7),
                    YEAR(UTC_TIMESTAMP()),
                    (YEAR(UTC_TIMESTAMP()) + 1)),
                '-06-30'))
            AND (`wi`.`Work_Item_Date__c` < '2016-07-01'))
    GROUP BY `_Type` , `_Metric` , `Country` , `_Owner` , `Business Line` , `Program` , `_Standards` , `Target` , `Period` , `Global Account`) UNION ALL (SELECT 
        'Backlog' AS `_Type`,
        'Change Request' AS `_Metric`,
        `p`.`Business_Line__c` AS `Business Line`,
        IF((`crb`.`Region` LIKE '%Product%'),
            'Product Services',
            IF((`crb`.`Region` LIKE 'AUS%'),
                'Australia',
                SUBSTRING_INDEX(`crb`.`Region`, '-', -(1)))) AS `Country`,
        '' AS `_Owner`,
        `p`.`Name` AS `Program`,
        '' AS `_Standards`,
        '' AS `Period`,
        COUNT(DISTINCT `crb`.`Id`) AS `Volume`,
        SUM(GETBUSINESSDAYS(`crb`.`From`, UTC_TIMESTAMP(), 'UTC')) AS `Sum Value`,
        COUNT(DISTINCT IF((GETBUSINESSDAYS(`crb`.`From`, UTC_TIMESTAMP(), 'UTC') <= GETTARGETARGAPAC('Change Request')),
                `crb`.`Id`,
                NULL)) AS `Volume within SLA`,
        GETTARGETARGAPAC('Change Request') AS `Target`,
        '' AS `Items`,
        '' AS `Auto-Approved`,
        '' AS `With-Hold`,
        '' AS `With TR`,
        '' AS `With Waiting Client`,
        '' AS `Open_Sub_Status`,
        GETGLOBALACCOUNT(`s`.`Name`, '') AS `Global Account`
    FROM
        ((((((`analytics`.`change_request_backlog_sub` `crb`
        JOIN `salesforce`.`change_request2__c` `cr` ON ((`crb`.`Id` = `cr`.`Id`)))
        JOIN `salesforce`.`work_item__c` `wi` ON ((`cr`.`Work_Item__c` = `wi`.`Id`)))
        JOIN `salesforce`.`site_certification_standard_program__c` `scsp` ON ((`wi`.`Site_Certification_Standard__c` = `scsp`.`Id`)))
        JOIN `salesforce`.`standard_program__c` `sp` ON ((`scsp`.`Standard_Program__c` = `sp`.`Id`)))
        JOIN `salesforce`.`standard__c` `s` ON ((`sp`.`Standard__c` = `s`.`Id`)))
        JOIN `salesforce`.`program__c` `p` ON ((`sp`.`Program__c` = `p`.`Id`)))
    WHERE
        ((`crb`.`Region` LIKE 'AUS%')
            OR (`crb`.`Region` LIKE 'Asia%'))
    GROUP BY `_Type` , `_Metric` , `Country` , `_Owner` , `Business Line` , `Program` , `_Standards` , `Target` , `Period` , `Global Account`) UNION ALL (SELECT 
        'Performance' AS `_Type`,
        'Change Request' AS `_Metric`,
        `p`.`Business_Line__c` AS `Business Line`,
        IF((`crc`.`Region` LIKE '%Product%'),
            'Product Services',
            IF((`crc`.`Region` LIKE 'AUS%'),
                'Australia',
                SUBSTRING_INDEX(`crc`.`Region`, '-', -(1)))) AS `Country`,
        '' AS `_Owner`,
        `p`.`Name` AS `Program`,
        '' AS `_Standards`,
        DATE_FORMAT(`crc`.`To`, '%Y %m') AS `Period`,
        COUNT(DISTINCT `crc`.`Id`) AS `Volume`,
        SUM(GETBUSINESSDAYS(`crc`.`From`, `crc`.`To`, 'UTC')) AS `Sum Value`,
        COUNT(DISTINCT IF((GETBUSINESSDAYS(`crc`.`From`, `crc`.`To`, 'UTC') <= GETTARGETARGAPAC('Change Request')),
                `crc`.`Id`,
                NULL)) AS `Volume within SLA`,
        GETTARGETARGAPAC('Change Request') AS `Target`,
        '' AS `Items`,
        '' AS `Auto-Approved`,
        '' AS `With-Hold`,
        '' AS `With TR`,
        '' AS `With Waiting Client`,
        '' AS `Open_Sub_Status`,
        GETGLOBALACCOUNT(`s`.`Name`, '') AS `Global Account`
    FROM
        ((((((`analytics`.`change_request_completed_sub` `crc`
        JOIN `salesforce`.`change_request2__c` `cr` ON ((`crc`.`Id` = `cr`.`Id`)))
        JOIN `salesforce`.`work_item__c` `wi` ON ((`cr`.`Work_Item__c` = `wi`.`Id`)))
        JOIN `salesforce`.`site_certification_standard_program__c` `scsp` ON ((`wi`.`Site_Certification_Standard__c` = `scsp`.`Id`)))
        JOIN `salesforce`.`standard_program__c` `sp` ON ((`scsp`.`Standard_Program__c` = `sp`.`Id`)))
        JOIN `salesforce`.`standard__c` `s` ON ((`sp`.`Standard__c` = `s`.`Id`)))
        JOIN `salesforce`.`program__c` `p` ON ((`sp`.`Program__c` = `p`.`Id`)))
    WHERE
        ((`crc`.`To` >= CONCAT((IF((MONTH(UTC_TIMESTAMP()) < 7),
                    YEAR(UTC_TIMESTAMP()),
                    (YEAR(UTC_TIMESTAMP()) + 1)) - 1),
                '-07-01'))
            AND (`crc`.`To` <= CONCAT(IF((MONTH(UTC_TIMESTAMP()) < 7),
                    YEAR(UTC_TIMESTAMP()),
                    (YEAR(UTC_TIMESTAMP()) + 1)),
                '-06-30'))
            AND ((`crc`.`Region` LIKE 'AUS%')
            OR (`crc`.`Region` LIKE 'Asia%')))
    GROUP BY `_Type` , `_Metric` , `Country` , `_Owner` , `Business Line` , `Program` , `_Standards` , `Target` , `Period` , `Global Account`) UNION ALL (SELECT 
        `t`.`Type` AS `_Type`,
        `t`.`Metric` AS `_Metric`,
        `t`.`Business Line` AS `Business Line`,
        `t`.`Country` AS `Country`,
        '' AS `_Owner`,
        `t`.`Program` AS `Program`,
        '' AS `_Standards`,
        `t`.`Period` AS `Period`,
        SUM(`t`.`Volume`) AS `Volume`,
        NULL AS `Sum Value`,
        SUM(`t`.`Volume within SLA`) AS `Volume within SLA`,
        NULL AS `Target`,
        '' AS `Items`,
        '' AS `Auto-Approved`,
        '' AS `With-Hold`,
        '' AS `With Waiting Client`,
        '' AS `With TR`,
        `t`.`Open_Sub_Status` AS `Open_Sub_Status`,
        GETGLOBALACCOUNT(`t`.`Standard`, '') AS `Global Account`
    FROM
        `analytics`.`global_ops_scheduling_backlog` `t`
    WHERE
        (`t`.`Region` = 'APAC')
    GROUP BY `_Type` , `_Metric` , `t`.`Country` , `_Owner` , `t`.`Business Line` , `t`.`Program` , `_Standards` , `Target` , `t`.`Period` , `t`.`Open_Sub_Status` , `Global Account`) UNION ALL (SELECT 
        `t`.`Type` AS `_Type`,
        `t`.`Metric` AS `_Metric`,
        `t`.`Business Line` AS `Business Line`,
        `t`.`Country` AS `Country`,
        '' AS `_Owner`,
        `t`.`Program` AS `Program`,
        '' AS `_Standards`,
        `t`.`Period` AS `Period`,
        SUM(`t`.`Volume`) AS `Volume`,
        SUM(`t`.`Sum Value`) AS `Sum Value`,
        SUM(`t`.`Volume within SLA`) AS `Volume within SLA`,
        GETTARGETARGAPAC('Confirmed WI') AS `Target`,
        '' AS `Items`,
        '' AS `Auto-Approved`,
        '' AS `With-Hold`,
        '' AS `With TR`,
        '' AS `With Waiting Client`,
        '' AS `Open_Sub_Status`,
        GETGLOBALACCOUNT(`t`.`Standard`, '') AS `Global Account`
    FROM
        `analytics`.`global_ops_scheduling_performance_by_confirmed_period` `t`
    WHERE
        ((`t`.`Region` = 'APAC')
            AND (`t`.`Period` >= CONCAT((IF((MONTH(UTC_TIMESTAMP()) < 7),
                    YEAR(UTC_TIMESTAMP()),
                    (YEAR(UTC_TIMESTAMP()) + 1)) - 1),
                ' 07'))
            AND (`t`.`Period` <= CONCAT(IF((MONTH(UTC_TIMESTAMP()) < 7),
                    YEAR(UTC_TIMESTAMP()),
                    (YEAR(UTC_TIMESTAMP()) + 1)),
                ' 06')))
    GROUP BY `_Type` , `_Metric` , `t`.`Country` , `_Owner` , `t`.`Business Line` , `t`.`Program` , `_Standards` , `Target` , `t`.`Period` , `Global Account`) UNION ALL (SELECT 
        `t`.`Type` AS `_Type`,
        `t`.`Metric` AS `_Metric`,
        `t`.`Business Line` AS `Business Line`,
        `t`.`Country` AS `Country`,
        `t`.`Owner` AS `_Owner`,
        `t`.`Program` AS `Program`,
        '' AS `_Standards`,
        `t`.`Period` AS `Period`,
        SUM(`t`.`# Confirmed`) AS `Volume`,
        SUM(`t`.`Days Confirmed to Start`) AS `Sum Value`,
        SUM(`t`.`Confirmed within SLA`) AS `Volume within SLA`,
        SUM(`t`.`# To Be Confirmed`) AS `Target`,
        '' AS `Items`,
        '' AS `Auto-Approved`,
        '' AS `With-Hold`,
        '' AS `With TR`,
        '' AS `With Waiting Client`,
        `t`.`Open_Sub_Status` AS `Open_Sub_Status`,
        GETGLOBALACCOUNT(`t`.`Standard`, '') AS `Global Account`
    FROM
        `analytics`.`global_ops_scheduling_performance_by_audit_period` `t`
    WHERE
        ((`t`.`Region` = 'APAC')
            AND (`t`.`Period` >= CONCAT((IF((MONTH(UTC_TIMESTAMP()) < 7),
                    YEAR(UTC_TIMESTAMP()),
                    (YEAR(UTC_TIMESTAMP()) + 1)) - 1),
                ' 07'))
            AND (`t`.`Period` <= CONCAT(IF((MONTH(UTC_TIMESTAMP()) < 7),
                    YEAR(UTC_TIMESTAMP()),
                    (YEAR(UTC_TIMESTAMP()) + 1)),
                ' 06')))
    GROUP BY `_Type` , `_Metric` , `t`.`Country` , `_Owner` , `t`.`Business Line` , `t`.`Program` , `_Standards` , `t`.`Period` , `Global Account` , `t`.`Open_Sub_Status`) UNION ALL (SELECT 
        `t`.`Type` AS `_Type`,
        'Confirmed by Audit Period vs Target' AS `_Metric`,
        `t`.`Business Line` AS `Business Line`,
        `t`.`Country` AS `Country`,
        '' AS `_Owner`,
        `t`.`Program` AS `Program`,
        '' AS `_Standards`,
        `t`.`Period` AS `Period`,
        SUM(`t`.`# Confirmed`) AS `Volume`,
        SUM(`t`.`# To Be Confirmed`) AS `Sum Value`,
        SUM(`t`.`Confirmed within SLA`) AS `Volume within SLA`,
        IF((`t`.`Period` = DATE_FORMAT((NOW() + INTERVAL -(1) MONTH), '%Y %m')),
            1,
            IF((`t`.`Period` = DATE_FORMAT(NOW(), '%Y %m')),
                0.95,
                IF((`t`.`Period` = DATE_FORMAT((NOW() + INTERVAL 1 MONTH), '%Y %m')),
                    0.8,
                    IF((`t`.`Period` = DATE_FORMAT((NOW() + INTERVAL 2 MONTH), '%Y %m')),
                        0.7,
                        IF((`t`.`Period` = DATE_FORMAT((NOW() + INTERVAL 3 MONTH), '%Y %m')),
                            0.5,
                            IF((`t`.`Period` = DATE_FORMAT((NOW() + INTERVAL 4 MONTH), '%Y %m')),
                                0.2,
                                IF((`t`.`Period` = DATE_FORMAT((NOW() + INTERVAL 5 MONTH), '%Y %m')),
                                    0.1,
                                    IF((`t`.`Period` = DATE_FORMAT((NOW() + INTERVAL 6 MONTH), '%Y %m')),
                                        0.05,
                                        0)))))))) AS `Target`,
        '' AS `Items`,
        '' AS `Auto-Approved`,
        '' AS `With-Hold`,
        '' AS `With TR`,
        '' AS `With Waiting Client`,
        '' AS `Open_Sub_Status`,
        GETGLOBALACCOUNT(`t`.`Standard`, '') AS `Global Account`
    FROM
        `analytics`.`global_ops_scheduling_performance_by_audit_period` `t`
    WHERE
        ((`t`.`Region` = 'APAC')
            AND (`t`.`Period` >= DATE_FORMAT((NOW() + INTERVAL -(1) MONTH), '%Y %m'))
            AND (`t`.`Period` <= DATE_FORMAT((NOW() + INTERVAL 6 MONTH), '%Y %m')))
    GROUP BY `_Type` , `_Metric` , `t`.`Country` , `_Owner` , `t`.`Business Line` , `t`.`Program` , `_Standards` , `Target` , `t`.`Period` , `Global Account`) UNION ALL (SELECT 
        `t`.`Type` AS `_Type`,
        `t`.`Metric` AS `_Metric`,
        `t`.`Business Line` AS `Business Line`,
        `t`.`Country` AS `Country`,
        IF((`t`.`# Scheduled` = 1),
            'Scheduled Once',
            IF((`t`.`# Scheduled` = 2),
                'Scheduled Twice',
                IF((`t`.`# Scheduled` = 3),
                    'Scheduled Thrice',
                    'Scheduled 4 more times'))) AS `_Owner`,
        `t`.`Program` AS `Program`,
        '' AS `_Standards`,
        `t`.`Period` AS `Period`,
        COUNT(DISTINCT `t`.`Items`) AS `Volume`,
        SUM(`t`.`# Scheduled`) AS `Sum Value`,
        0 AS `Volume within SLA`,
        0 AS `Target`,
        GROUP_CONCAT(`t`.`Items`
            SEPARATOR ',') AS `Items`,
        '' AS `Auto-Approved`,
        '' AS `With-Hold`,
        '' AS `With TR`,
        '' AS `With Waiting Client`,
        '' AS `Open_Sub_Status`,
        GETGLOBALACCOUNT(`t`.`Standard`, '') AS `Global Account`
    FROM
        `analytics`.`global_ops_scheduling_performance_rework` `t`
    WHERE
        ((`t`.`Region` = 'APAC')
            AND (`t`.`Period` >= CONCAT((IF((MONTH(UTC_TIMESTAMP()) < 7),
                    YEAR(UTC_TIMESTAMP()),
                    (YEAR(UTC_TIMESTAMP()) + 1)) - 1),
                ' 07'))
            AND (`t`.`Period` <= CONCAT(IF((MONTH(UTC_TIMESTAMP()) < 7),
                    YEAR(UTC_TIMESTAMP()),
                    (YEAR(UTC_TIMESTAMP()) + 1)),
                ' 06')))
    GROUP BY `_Type` , `_Metric` , `t`.`Country` , `_Owner` , `t`.`Business Line` , `t`.`Program` , `_Standards` , `Target` , `t`.`Period` , `Global Account`);