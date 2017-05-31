SELECT 
    r.Name as 'ResourceName',
    r.Resource_Type__c,
    r.Reporting_Business_Units__c,
    scs.Name as 'State',
    um.Name as 'Manager',
    DATE_FORMAT(t.Date, '%Y-%m') as 'Period',
    t.Type,
    sum(t.DurationMin) as 'Minutes',
    count(distinct t.Date) as 'Days'
FROM
    `Resource__c` r
        INNER JOIN
    `User` u ON r.User__c = u.Id
        INNER JOIN
    `User` um ON u.ManagerId = um.Id
        LEFT JOIN
    `state_code_setup__c` scs ON r.Home_State_Province__c = scs.Id
        INNER JOIN
    (SELECT 
        r.Id as 'ResourceId',
            rt.Name as 'Type',
            wir.Work_Item_Type__c as 'SubType',
            e.DurationInMinutes as 'DurationMin',
            e.ActivityDate as 'Date'
    FROM
        `event` e
    INNER JOIN `user` u ON u.Id = e.OwnerId
    INNER JOIN `Resource__c` r ON u.Id = r.User__C
    INNER JOIN `recordtype` rt ON e.RecordTypeId = rt.Id
    LEFT JOIN `work_item_resource__c` wir ON wir.Id = e.WhatId
    WHERE
        e.IsDeleted = 0
            AND e.ActivityDate >= '2014-01-01'
            AND e.ActivityDate <= '2015-01-01'
            AND r.Reporting_Business_Units__c like 'AUS%') t ON t.ResourceId = r.Id
WHERE
    Reporting_Business_Units__c like 'AUS%'
        and r.Resource_Type__c = 'Contractor'
        and t.Type = 'Work Item Resource'
GROUP BY `ResourceName` , `Manager` , r.Resource_Type__c , r.Reporting_Business_Units__c , `State` , r.Resource_Target_Days__c , `Period` , t.Type
ORDER BY r.Reporting_Business_Units__c , `ResourceName` , `Period` , t.Type;

select 
    r.Name as 'ResourceName',
    r.Reporting_Business_Units__c,
    scs.Name as 'State',
    um.Name as 'Manager',
    DATE_FORMAT(tsli.Timesheet_Date__c, '%Y-%m') as 'Period',
    count(distinct tsli.Timesheet_Date__c) as 'Days'
from
    salesforce.timesheet_line_item__c tsli
         left join
	`User` u ON concat(u.FirstName, ' ', u.LastName) = tsli.Resource_Name__c 
		inner join
    salesforce.resource__c r ON  r.User__c = u.Id 
        INNER JOIN
    `User` um ON u.ManagerId = um.Id
        LEFT JOIN
    `state_code_setup__c` scs ON r.Home_State_Province__c = scs.Id
where
    tsli.Category__c = 'Audit'
        and r.Resource_Type__c = 'Contractor'
        AND tsli.Timesheet_Date__c >= '2013-07-01'
        AND tsli.Timesheet_Date__c <= '2014-01-09'
GROUP BY `ResourceName` , `Manager` , r.Reporting_Business_Units__c , `State` , `Period`;