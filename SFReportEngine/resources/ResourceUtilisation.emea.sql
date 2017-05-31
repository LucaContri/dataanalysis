SELECT 
SUBSTRING_INDEX(i.`Business Unit`, '-', -(1)) as 'Country', 
i.`Manager`, 
i.`Name`, 
i.`Resource Capacitiy (%)`, 
i.`Period`, 
j.`Working Days`, 
i.`Audit Days`, 
i.`Travel Days`, 
i.`Holiday Days`, 
i.`Leave Days`, 
if(j.`Working Days`-(i.`Holiday Days`+i.`Leave Days`)=0,null, (i.`Audit Days`+i.`Travel Days`)/((j.`Working Days`-(i.`Holiday Days`+i.`Leave Days`))*i.`Resource Capacitiy (%)`/100)*100) as 'Utilisation %', 
i.`Other BOPs`,
i.`Other BOP Types`,
(j.`Working Days` - i.`Audit Days` - i.`Travel Days` - i.`Holiday Days` - i.`Leave Days` - i.`Other BOPs`) as 'Spare Capacity',
(j.`Working Days`-(i.`Holiday Days`+i.`Leave Days`))*(i.`Resource Capacitiy (%)`/100) as 'Days Avaialble',
(i.`Audit Days`+i.`Travel Days`) as 'Charged Days'
FROM         
	(SELECT                       
		t.Id, t.Name, t.Resource_Capacitiy__c as 'Resource Capacitiy (%)', t.Reporting_Business_Units__c as 'Business Unit', t.Manager, DATE_FORMAT(t.ActivityDate, '%Y %m') AS 'Period', SUM(IF(t.SubType = 'Audit', t.DurationDays, 0)) AS 'Audit Days', SUM(IF(t.SubType = 'Travel', t.DurationDays, 0)) AS 'Travel Days', SUM(IF(t.SubType = 'Public Holiday', t.DurationDays, 0)) AS 'Holiday Days', SUM(IF(t.SubType LIKE 'Leave%', t.DurationDays, 0)) AS 'Leave Days', SUM(IF(t.SubType not like 'Leave%' and t.Subtype not in ('Audit','Travel','Public Holiday'), t.DurationDays,0)) as 'Other BOPs',GROUP_CONCAT(DISTINCT IF(t.SubType not like 'Leave%' and t.Subtype not in ('Audit','Travel','Public Holiday'), t.Subtype ,null)) as 'Other BOP Types'     
        FROM 
			(SELECT r.Id, r.Name, r.Resource_Target_Days__c, r.Resource_Capacitiy__c, r.Resource_Type__c, r.Work_Type__c, r.Reporting_Business_Units__c, m.Name as 'Manager', rt.Name AS 'Type', IF(wir.Work_Item_Type__c IS NULL, bop.Resource_Blackout_Type__c, wir.Work_Item_Type__c) AS 'SubType', e.DurationInMinutes AS 'DurationMin', e.DurationInMinutes / 60 / 8 AS 'DurationDays', e.ActivityDate 
				FROM salesforce.resource__c r     
                INNER JOIN salesforce.user u ON u.Id = r.User__c     
                inner join salesforce.user m on u.ManagerId = m.Id     
                INNER JOIN salesforce.event e ON u.Id = e.OwnerId     
                INNER JOIN salesforce.recordtype rt ON e.RecordTypeId = rt.Id     
                LEFT JOIN salesforce.work_item_resource__c wir ON wir.Id = e.WhatId     
                LEFT JOIN salesforce.blackout_period__c bop ON bop.Id = e.WhatId     
                WHERE         
                ((DATE_FORMAT(e.ActivityDate, '%Y %m') >= DATE_FORMAT(DATE_ADD(NOW(), INTERVAL -6 MONTH), '%Y %m') 
					and DATE_FORMAT(e.ActivityDate, '%Y %m') <= DATE_FORMAT(DATE_ADD(NOW(), INTERVAL 6 MONTH), '%Y %m'))  OR e.Id IS NULL)             
                AND Resource_Type__c NOT IN ('Client Services')             
                AND r.Reporting_Business_Units__c LIKE 'EMEA%'  
                AND r.Active_User__c = 'Yes'             
                AND r.Resource_Type__c = 'Employee'             
                AND r.Resource_Capacitiy__c IS NOT NULL             
                AND r.Resource_Capacitiy__c >= 30             
                AND (e.IsDeleted = 0 OR e.Id IS NULL)) t     
                GROUP BY `Period` , t.Id) i     
			INNER JOIN 
				(SELECT DATE_FORMAT(wd.date, '%Y %m') AS 'Period', COUNT(wd.date) AS 'Working Days' 
				FROM salesforce.`sf_working_days` wd 
                WHERE
					DATE_FORMAT(wd.date, '%Y %m') >= DATE_FORMAT(DATE_ADD(NOW(), INTERVAL -6 MONTH), '%Y %m') 
                    AND DATE_FORMAT(wd.date, '%Y %m') <= DATE_FORMAT(DATE_ADD(NOW(), INTERVAL 6 MONTH), '%Y %m') 
				GROUP BY `Period`) j ON i.Period = j.Period     
			group by Id, i.Period;
            
               
            
SELECT  		 SUBSTRING_INDEX(i.`Business Unit`, '-', -(1)) as 'Country', i.`Manager`, i.`Name`, i.`Resource Capacitiy (%)`, i.`Period`, j.`Working Days`, i.`Audit Days`, i.`Travel Days`, i.`Holiday Days`, i.`Leave Days`,         if(j.`Working Days`-(i.`Holiday Days`+i.`Leave Days`)=0,null, (i.`Audit Days`+i.`Travel Days`)/((j.`Working Days`-(i.`Holiday Days`+i.`Leave Days`))*i.`Resource Capacitiy (%)`/100)*100) as 'Utilisation %', i.`Other BOPs`,i.`Other BOP Types`,(j.`Working Days` - i.`Audit Days` - i.`Travel Days` - i.`Holiday Days` - i.`Leave Days` - i.`Other BOPs`) as 'Spare Capacity',(j.`Working Days`-(i.`Holiday Days`+i.`Leave Days`))*(i.`Resource Capacitiy (%)`/100) as 'Days Avaialble',(i.`Audit Days`+i.`Travel Days`) as 'Charged Days'     

FROM         (SELECT                       t.Id,             t.Name,             t.Resource_Capacitiy__c as 'Resource Capacitiy (%)',             t.Reporting_Business_Units__c as 'Business Unit',             t.Manager,             DATE_FORMAT(t.ActivityDate, '%Y %m') AS 'Period',             SUM(IF(t.SubType = 'Audit', t.DurationDays, 0)) AS 'Audit Days',             SUM(IF(t.SubType = 'Travel', t.DurationDays, 0)) AS 'Travel Days',             SUM(IF(t.SubType = 'Public Holiday', t.DurationDays, 0)) AS 'Holiday Days',             SUM(IF(t.SubType LIKE 'Leave%', t.DurationDays, 0)) AS 'Leave Days', SUM(IF(t.SubType not like 'Leave%' and t.Subtype not in ('Audit','Travel','Public Holiday'), t.DurationDays,0)) as 'Other BOPs',GROUP_CONCAT(DISTINCT IF(t.SubType not like 'Leave%' and t.Subtype not in ('Audit','Travel','Public Holiday'), t.Subtype ,null)) as 'Other BOP Types'     FROM         (SELECT          r.Id,             r.Name,             r.Resource_Target_Days__c,             r.Resource_Capacitiy__c,             r.Resource_Type__c,             r.Work_Type__c,             r.Reporting_Business_Units__c,             m.Name as 'Manager',             rt.Name AS 'Type',             IF(wir.Work_Item_Type__c IS NULL, bop.Resource_Blackout_Type__c, wir.Work_Item_Type__c) AS 'SubType',             e.DurationInMinutes AS 'DurationMin',             e.DurationInMinutes / 60 / 8 AS 'DurationDays',             e.ActivityDate     FROM         resource__c r     INNER JOIN user u ON u.Id = r.User__c     inner join user m on u.ManagerId = m.Id     INNER JOIN event e ON u.Id = e.OwnerId     INNER JOIN recordtype rt ON e.RecordTypeId = rt.Id     LEFT JOIN work_item_resource__c wir ON wir.Id = e.WhatId     LEFT JOIN blackout_period__c bop ON bop.Id = e.WhatId     WHERE         r.Reporting_Business_Units__c LIKE 'Asia%'             AND ((DATE_FORMAT(e.ActivityDate, '%Y %m') < DATE_FORMAT(DATE_ADD(NOW(), INTERVAL 7 MONTH), '%Y %m')             AND DATE_FORMAT(e.ActivityDate, '%Y %m') > DATE_FORMAT(DATE_ADD(NOW(), INTERVAL -6 MONTH), '%Y %m'))             OR e.Id IS NULL)             AND Resource_Type__c NOT IN ('Client Services')             AND r.Reporting_Business_Units__c LIKE 'Asia%'             AND r.Active_User__c = 'Yes'             AND r.Resource_Type__c = 'Employee'             AND r.Resource_Capacitiy__c IS NOT NULL             AND r.Resource_Capacitiy__c >= 30             AND (e.IsDeleted = 0 OR e.Id IS NULL)) t     GROUP BY `Period` , t.Id) i     INNER JOIN (SELECT          DATE_FORMAT(wd.date, '%Y %m') AS 'Period',             COUNT(wd.date) AS 'Working Days'     FROM         `sf_working_days` wd     WHERE         DATE_FORMAT(wd.date, '%Y %m') < DATE_FORMAT(DATE_ADD(NOW(), INTERVAL 7 MONTH), '%Y %m')             AND DATE_FORMAT(wd.date, '%Y %m') > DATE_FORMAT(DATE_ADD(NOW(), INTERVAL -6 MONTH), '%Y %m')     GROUP BY `Period`) j ON i.Period = j.Period     group by Id, i.Period;
                