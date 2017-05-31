# Back office Activities Completed

# Admin
(SELECT 
	'Admin' AS `Team`,
	'New Business' AS `Activity`,
    `nb`.`Region` as `Region`,
    'Opp Business' as 'Region Type',
    `nb`.`Owner` AS `User`,
    date_format(`nb`.`To`, '%Y-%v') as 'Year-Week',
	COUNT(`nb`.`Id`) AS `Completed`
FROM `analytics`.`sla_admin_newbusiness` `nb`
#WHERE (`nb`.`To` > (UTC_TIMESTAMP() + INTERVAL -(1) DAY))
GROUP BY `Team`, `Activity`, `Region`, `User`, `Year-Week`)
union all
SELECT 
	'Admin' AS `Team`,
	'ARG Completed' AS `Activity`,
    arg.`Region` as `Region`,
    'Opp Business' as 'Region Type',
    arg.`Owner` AS `User`,
    date_format(arg.`To`, '%Y-%v') as 'Year-Week',
	COUNT(distinct arg.`Id`) AS `Completed`
FROM
	`analytics`.`sla_arg_v2` arg
WHERE
	arg.`Metric` = 'ARG Completion/Hold'
	AND arg.`To` is not null
GROUP BY `Team`, `Activity`, `Region`, `User`, `Year-Week`
union all
# Scheduling
(SELECT 
	'Scheduling' AS `Team`,
	`analytics`.`sla_scheduling_completed`.`Activity` AS `Activity`,
	`analytics`.`sla_scheduling_completed`.`Region`,
	'Sched. Ownership' as 'Region Type',
	`analytics`.`sla_scheduling_completed`.`Owner` AS `User`,
	date_format(`analytics`.`sla_scheduling_completed`.`To`, '%Y-%v') as 'Year-Week',
	COUNT(0) AS `Completed`
FROM `analytics`.`sla_scheduling_completed`
GROUP BY `Team`, `Activity`, `Region`, `User`, `Year-Week`)
union all
# PRC
(select 
	epa.`Team`,  
    epa.`Activity`, 
    epa.ClientOwnerShip as 'Region',
    'Client Ownership' as 'Region Type',
    epa.`User`,
    date_format(epa.`ActionDate/Time`, '%Y-%v') as 'Year-Week',
    sum(epa.`Completed`) as 'Completed'
    
from (SELECT 
        `t2`.`ARG_Id` AS `ARG_Id`,
        `t2`.`ARG_Name` AS `ARG_Name`,
        `t2`.`ARG_Status` AS `ARG_Status`,
        `t2`.`ClientOwnerShip` AS `ClientOwnerShip`,
        `t2`.`Assigned_CA__c` AS `Assigned_CA__c`,
        `t2`.`Assigned_Admin__c` AS `Assigned_Admin__c`,
        `t2`.`First_Submitted` AS `First_Submitted`,
        `t2`.`Last_Submitted` AS `Last_Submitted`,
        `t2`.`First_Taken` AS `First_Taken`,
        `t2`.`First_Rejected` AS `First_Rejected`,
        `t2`.`First_Reviewed` AS `First_Reviewed`,
        `t2`.`First_Reviewed_Admin` AS `First_Reviewed_Admin`,
        `t2`.`Rejections` AS `Rejections`,
        `t2`.`TR Requests` AS `TR Requests`,
        `t2`.`TR Approved` AS `TR Approved`,
        `t2`.`ActionedBy` AS `ActionedBy`,
        `t2`.`Reporting_Business_Units__c` AS `Reporting_Business_Units__c`,
        `t2`.`ActionDate/Time` AS `ActionDate/Time`,
        `t2`.`ActionId` AS `ActionId`,
        `t2`.`Action` AS `Action`,
        `t2`.`Assigned To` AS `Assigned To`,
        `t2`.`RevenueOwnerships` AS `RevenueOwnerships`,
        `t2`.`WorkItemsNo` AS `WorkItemsNo`,
        `t2`.`WorkItemTypes` AS `WorkItemTypes`,
        `t2`.`PrimaryStandards` AS `PrimaryStandards`,
        `t2`.`ProgramBusinessLines` AS `ProgramBusinessLines`,
        `t2`.`Standard Families` AS `Standard Families`,
        'PRC' AS `Team`,
        IF((`t2`.`Action` = 'Requested Technical Review'),
            `ca`.`Name`,
            `t2`.`ActionedBy`) AS `User`,
        IF((`t2`.`Action` = 'Requested Technical Review'),
            'Requested TR',
            IF(((`t2`.`Rejections` > 0)
                    AND (`t2`.`First_Rejected` <> `t2`.`ActionDate/Time`)),
                'Re-Submission',
                IF((`t2`.`RevenueOwnerships` LIKE '%Food%'),
                    IF((`t2`.`PrimaryStandards` LIKE '%BRC%'),
                        IF(((`t2`.`WorkItemTypes` LIKE '%Follow Up%')
                                OR (`t2`.`WorkItemTypes` LIKE '%Gap%')),
                            'BRC/SQF/FSSC Follow Up/Gap',
                            'BRC Cert/Recert'),
                        IF(((`t2`.`PrimaryStandards` LIKE '%SQF%')
                                OR (`t2`.`PrimaryStandards` LIKE '%FSSC%')),
                            IF(((`t2`.`WorkItemTypes` LIKE '%Follow Up%')
                                    OR (`t2`.`WorkItemTypes` LIKE '%Gap%')),
                                'BRC/SQF/FSSC Follow Up/Gap',
                                'SQF/FSSC Cert/Recert'),
                            IF((`t2`.`WorkItemTypes` LIKE '%Follow Up%'),
                                'Food - Follow Up',
                                IF((`t2`.`WorkItemsNo` < 3),
                                    'Food - Low Complexity',
                                    IF((`t2`.`WorkItemsNo` < 6),
                                        'Food - Medium Complexity',
                                        'Food - High Complexity'))))),
                    IF((`t2`.`PrimaryStandards` LIKE '%16949%'),
                        IF((`t2`.`WorkItemTypes` LIKE '%Follow Up%'),
                            'Automotive - Follow Up',
                            'Automotive'),
                        IF((`t2`.`WorkItemTypes` LIKE '%Follow Up%'),
                            'MS - Follow Up',
                            IF((`t2`.`WorkItemsNo` < 4),
                                'MS - Low Complexity',
                                IF((`t2`.`WorkItemsNo` < 12),
                                    'MS - Medium Complexity',
                                    'MS - High Complexity'))))))) AS `Activity`,
        COUNT(`t2`.`ARG_Id`) AS `Completed`,
        DATE_FORMAT(NOW(), '%d/%m/%Y') AS `Date/Time`,
        GROUP_CONCAT(`t2`.`ARG_Name`
            SEPARATOR ',') AS `ARG Names`
    FROM
        ((SELECT 
        `t`.`ARG_Id` AS `ARG_Id`,
        `t`.`ARG_Name` AS `ARG_Name`,
        `t`.`ARG_Status` AS `ARG_Status`,
        `t`.`ClientOwnerShip` AS `ClientOwnerShip`,
        `t`.`Assigned_CA__c` AS `Assigned_CA__c`,
        `t`.`Assigned_Admin__c` AS `Assigned_Admin__c`,
        `t`.`First_Submitted` AS `First_Submitted`,
        `t`.`Last_Submitted` AS `Last_Submitted`,
        `t`.`First_Taken` AS `First_Taken`,
        `t`.`First_Rejected` AS `First_Rejected`,
        `t`.`First_Reviewed` AS `First_Reviewed`,
        `t`.`First_Reviewed_Admin` AS `First_Reviewed_Admin`,
        `t`.`Rejections` AS `Rejections`,
        `t`.`TR Requests` AS `TR Requests`,
        `t`.`TR Approved` AS `TR Approved`,
        `r`.`Name` AS `ActionedBy`,
        `r`.`Reporting_Business_Units__c` AS `Reporting_Business_Units__c`,
        `ah`.`Timestamp__c` AS `ActionDate/Time`,
        `ah`.`Id` AS `ActionId`,
        `ah`.`Status__c` AS `Action`,
        `ah`.`Assigned_To__c` AS `Assigned To`,
        GROUP_CONCAT(DISTINCT `wi`.`Revenue_Ownership__c`
            SEPARATOR ',') AS `RevenueOwnerships`,
        COUNT(DISTINCT `wi`.`Id`) AS `WorkItemsNo`,
        GROUP_CONCAT(DISTINCT `wi`.`Work_Item_Stage__c`
            SEPARATOR ',') AS `WorkItemTypes`,
        GROUP_CONCAT(DISTINCT `wi`.`Primary_Standard__c`
            SEPARATOR ',') AS `PrimaryStandards`,
        GROUP_CONCAT(DISTINCT `stpr`.`Program_Business_Line__c`
            SEPARATOR ',') AS `ProgramBusinessLines`,
        GROUP_CONCAT(DISTINCT IF((`scsf`.`IsDeleted` OR `sp`.`IsDeleted`
                    OR `s`.`IsDeleted`),
                NULL,
                `s`.`Name`)
            SEPARATOR ',') AS `Standard Families`
    FROM
        (((((((((`salesforce`.`enlighten_prc_activity_sub` `t`
        JOIN `salesforce`.`approval_history__c` `ah` ON ((`ah`.`RAudit_Report_Group__c` = `t`.`ARG_Id`)))
        JOIN `salesforce`.`resource__c` `r` ON ((`ah`.`RApprover__c` = `r`.`Id`)))
        JOIN `salesforce`.`arg_work_item__c` `argwi` ON ((`argwi`.`RAudit_Report_Group__c` = `t`.`ARG_Id`)))
        JOIN `salesforce`.`work_item__c` `wi` ON ((`wi`.`Id` = `argwi`.`RWork_Item__c`)))
        JOIN `salesforce`.`site_certification_standard_program__c` `scsp` ON ((`wi`.`Site_Certification_Standard__c` = `scsp`.`Id`)))
        JOIN `salesforce`.`standard_program__c` `stpr` ON ((`scsp`.`Standard_Program__c` = `stpr`.`Id`)))
        LEFT JOIN `salesforce`.`site_certification_standard_family__c` `scsf` ON ((`scsf`.`Site_Certification_Standard__c` = `scsp`.`Id`)))
        LEFT JOIN `salesforce`.`standard_program__c` `sp` ON ((`scsf`.`Standard_Program__c` = `sp`.`Id`)))
        LEFT JOIN `salesforce`.`standard__c` `s` ON ((`sp`.`Standard__c` = `s`.`Id`)))
    WHERE
        ((`wi`.`IsDeleted` = 0)
            AND (`wi`.`Status__c` <> 'Cancelled')
            AND (`argwi`.`IsDeleted` = 0)
            AND (`ah`.`IsDeleted` = 0)
            AND (`ah`.`Status__c` IN ('Approved' , 'Rejected', 'Requested Technical Review')))
            #AND (`ah`.`Timestamp__c` <= UTC_TIMESTAMP())
            #AND (`ah`.`Timestamp__c` > (UTC_TIMESTAMP() + INTERVAL -(1) DAY)))
    GROUP BY `ah`.`Id`) `t2`
        LEFT JOIN `salesforce`.`resource__c` `ca` ON ((`t2`.`Assigned_CA__c` = `ca`.`Id`)))
    
    GROUP BY `t2`.`ActionDate/Time`) epa 
group by `Team`, `Activity`, `Region`, `User`, `Year-Week`);