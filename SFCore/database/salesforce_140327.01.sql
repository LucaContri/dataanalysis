CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `luca`@`%` 
    SQL SECURITY DEFINER
VIEW `financial_visisbility` AS
    SELECT 
        `sf_report_history`.`Region` AS `Region`,
        DATE_FORMAT(`sf_report_history`.`Date`,
                '%d/%m/%Y - %T') AS `Report Date-Time`,
        IF((`sf_report_history`.`RowName` LIKE 'Food%'),
            'Food',
            IF((`sf_report_history`.`RowName` LIKE 'ProductService%'),
                'Product Service',
                IF((`sf_report_history`.`RowName` LIKE 'TIS%'),
                    'TIS',
                    IF((`sf_report_history`.`RowName` LIKE 'MS%'),
                        'MS',
                        '?')))) AS `Revenue Stream`,
        IF((`sf_report_history`.`RowName` LIKE '%Expenses%'),
            'Billable Expenses',
            IF((`sf_report_history`.`RowName` LIKE '%Audit%'),
                'Audit',
                IF((`sf_report_history`.`RowName` LIKE '%Fee%'),
                    'Fee',
                    IF((`sf_report_history`.`RowName` LIKE '%Public%'),
                        'Public Course',
                        IF((`sf_report_history`.`RowName` LIKE '%InHouse%'),
                            'InHouse',
                            '?'))))) AS `Source`,
        IF((`sf_report_history`.`RowName` LIKE '%Days%'),
            'Days',
            'Amount') AS `Type`,
        IF(((NOT ((`sf_report_history`.`RowName` LIKE '%Expenses%')))
                AND (`sf_report_history`.`RowName` LIKE '%Audit%')),
            TRIM(SUBSTRING_INDEX(`sf_report_history`.`RowName`, '-', -(1))),
            'n/a') AS `Audit Status`,
        IF(((NOT ((`sf_report_history`.`RowName` LIKE '%Expenses%')))
                AND (`sf_report_history`.`RowName` LIKE '%Audit%')),
            IF((TRIM(SUBSTRING_INDEX(TRIM(SUBSTRING_INDEX(`sf_report_history`.`RowName`, '-', -(2))),
                            '-',
                            1)) IN ('Days' , 'Under Review', '')),
                NULL,
                TRIM(SUBSTRING_INDEX(TRIM(SUBSTRING_INDEX(`sf_report_history`.`RowName`, '-', -(2))),
                            '-',
                            1))),
            'n/a') AS `Audit Open SubStatus`,
        `sf_report_history`.`ColumnName` AS `Period`,
        MONTHNAME(STR_TO_DATE(SUBSTRING_INDEX(`sf_report_history`.`ColumnName`,
                                ' ',
                                -(1)),
                        '%m')) AS `Month Name`,
        SUBSTRING_INDEX(`sf_report_history`.`ColumnName`,
                ' ',
                -(1)) AS `Month`,
        SUBSTRING_INDEX(`sf_report_history`.`ColumnName`, ' ', 1) AS `Year`,
        IF((SUBSTRING_INDEX(`sf_report_history`.`ColumnName`,
                    ' ',
                    -(1)) < '07'),
            CONCAT((DATE_FORMAT(STR_TO_DATE(SUBSTRING_INDEX(`sf_report_history`.`ColumnName`, ' ', 1),
                                    '%Y'),
                            '%Y') - 1),
                    '-',
                    DATE_FORMAT(STR_TO_DATE(SUBSTRING_INDEX(`sf_report_history`.`ColumnName`, ' ', 1),
                                    '%Y'),
                            '%Y')),
            CONCAT(DATE_FORMAT(STR_TO_DATE(SUBSTRING_INDEX(`sf_report_history`.`ColumnName`, ' ', 1),
                                    '%Y'),
                            '%Y'),
                    '-',
                    (DATE_FORMAT(STR_TO_DATE(SUBSTRING_INDEX(`sf_report_history`.`ColumnName`, ' ', 1),
                                    '%Y'),
                            '%Y') + 1))) AS `Financial Year`,
        CAST(`sf_report_history`.`Value` AS DECIMAL (10 , 2 )) AS `Value`
    FROM
        `sf_report_history`
    WHERE
        ((`sf_report_history`.`ReportName` = 'Audit Days Snapshot')
            AND (CAST(`sf_report_history`.`Value` AS DECIMAL (10 , 2 )) > 0));
            
            
CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `luca`@`%` 
    SQL SECURITY DEFINER
VIEW `financial_visisbility_latest` AS
    SELECT 
     `sf_report_history`.`Region` AS `Region`,
        DATE_FORMAT(`sf_report_history`.`Date`,
                '%d/%m/%Y - %T') AS `Report Date-Time`,
        IF((`sf_report_history`.`RowName` LIKE 'Food%'),
            'Food',
            IF((`sf_report_history`.`RowName` LIKE 'Product Service%'),
                'Product Service',
                IF((`sf_report_history`.`RowName` LIKE 'TIS%'),
                    'TIS',
                    IF((`sf_report_history`.`RowName` LIKE 'MS%'),
                        'MS',
                        '?')))) AS `Revenue Stream`,
        IF((`sf_report_history`.`RowName` LIKE '%Expenses%'),
            'Billable Expenses',
            IF((`sf_report_history`.`RowName` LIKE '%Audit%'),
                'Audit',
                IF((`sf_report_history`.`RowName` LIKE '%Fee%'),
                    'Fee',
                    IF((`sf_report_history`.`RowName` LIKE '%Public%'),
                        'Public Course',
                        IF((`sf_report_history`.`RowName` LIKE '%InHouse%'),
                            'InHouse',
                            '?'))))) AS `Source`,
        IF((`sf_report_history`.`RowName` LIKE '%Days%'),
            'Days',
            'Amount') AS `Type`,
        IF(((NOT ((`sf_report_history`.`RowName` LIKE '%Expenses%')))
                AND (`sf_report_history`.`RowName` LIKE '%Audit%')),
            TRIM(SUBSTRING_INDEX(`sf_report_history`.`RowName`, '-', -(1))),
            'n/a') AS `Audit Status`,
        IF(((NOT ((`sf_report_history`.`RowName` LIKE '%Expenses%')))
                AND (`sf_report_history`.`RowName` LIKE '%Audit%')),
            IF((TRIM(SUBSTRING_INDEX(TRIM(SUBSTRING_INDEX(`sf_report_history`.`RowName`, '-', -(2))),
                            '-',
                            1)) IN ('Days' , 'Under Review', '')),
                NULL,
                TRIM(SUBSTRING_INDEX(TRIM(SUBSTRING_INDEX(`sf_report_history`.`RowName`, '-', -(2))),
                            '-',
                            1))),
            'n/a') AS `Audit Open SubStatus`,
        `sf_report_history`.`ColumnName` AS `Period`,
        MONTHNAME(STR_TO_DATE(SUBSTRING_INDEX(`sf_report_history`.`ColumnName`,
                                ' ',
                                -(1)),
                        '%m')) AS `Month Name`,
        SUBSTRING_INDEX(`sf_report_history`.`ColumnName`,
                ' ',
                -(1)) AS `Month`,
        SUBSTRING_INDEX(`sf_report_history`.`ColumnName`, ' ', 1) AS `Year`,
        IF((SUBSTRING_INDEX(`sf_report_history`.`ColumnName`,
                    ' ',
                    -(1)) < '07'),
            CONCAT((DATE_FORMAT(STR_TO_DATE(SUBSTRING_INDEX(`sf_report_history`.`ColumnName`, ' ', 1),
                                    '%Y'),
                            '%Y') - 1),
                    '-',
                    DATE_FORMAT(STR_TO_DATE(SUBSTRING_INDEX(`sf_report_history`.`ColumnName`, ' ', 1),
                                    '%Y'),
                            '%Y')),
            CONCAT(DATE_FORMAT(STR_TO_DATE(SUBSTRING_INDEX(`sf_report_history`.`ColumnName`, ' ', 1),
                                    '%Y'),
                            '%Y'),
                    '-',
                    (DATE_FORMAT(STR_TO_DATE(SUBSTRING_INDEX(`sf_report_history`.`ColumnName`, ' ', 1),
                                    '%Y'),
                            '%Y') + 1))) AS `Financial Year`,
        CAST(`sf_report_history`.`Value` AS DECIMAL (10 , 2 )) AS `Value`
    FROM
        `sf_report_history`
    WHERE
        ((`sf_report_history`.`ReportName` = 'Audit Days Snapshot')
            AND `sf_report_history`.`Date` IN (SELECT 
                MAX(`sf_report_history`.`Date`)
            FROM
                `sf_report_history`
            WHERE
                (`sf_report_history`.`ReportName` = 'Audit Days Snapshot'))
            AND (CAST(`sf_report_history`.`Value` AS DECIMAL (10 , 2 )) > 0));
            
            
CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `luca`@`%` 
    SQL SECURITY DEFINER
VIEW `financial_visisbility_latest_days` AS
    SELECT 
        `t`.`Region` AS `Region`,
        `t`.`Report Date-Time` AS `Report Date-Time`,
        `t`.`Revenue Stream` AS `Revenue Stream`,
        `t`.`Source` AS `Source`,
        `t`.`Type` AS `Type`,
        `t`.`Audit Status` AS `Audit Status`,
        `t`.`Audit Open SubStatus` AS `Audit Open SubStatus`,
        `t`.`Period` AS `Period`,
        `t`.`Month Name` AS `Month Name`,
        `t`.`Month` AS `Month`,
        `t`.`Year` AS `Year`,
        `t`.`Financial Year` AS `Financial Year`,
        `t`.`Value` AS `Value`,
        IF((`t`.`Audit Status` IN ('Completed' , 'Submitted',
                'Support',
                'Under Review',
                'Rejected')),
            'Completing',
            IF((`t`.`Audit Status` IN ('Open' , 'Service Change')),
                'Open',
                `t`.`Audit Status`)) AS `Simple Status`
    FROM
        `financial_visisbility_latest` `t`
    WHERE
        (`t`.`Type` = 'Days');