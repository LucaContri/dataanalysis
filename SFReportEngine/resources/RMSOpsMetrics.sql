set @period = (select date_format(date_add(utc_timestamp(), interval -1 month), '%Y-%m'));
select @period;
# Direct Labour (%) 

# Chargeability (%) 

# Overhead FTE / Audit Days 

(SELECT
	analytics.getRegionFromCountry(analytics.getBUFromReportingBusinessUnit(i.`Business Unit`)) as 'Region',
	analytics.getBUFromReportingBusinessUnit(i.`Business Unit`) as 'Country',
	i.`Manager`, 
	i.`Name`, 
	i.`Resource Capacitiy (%)` as 'Resource Capacitiy (%)', 
	i.`Period`, 
	j.`Working Days`, 
	i.`Audit Days`, 
	i.`Travel Days`, 
	i.`Holiday Days`, 
	i.`Leave Days`, 
	if(j.`Working Days`-(i.`Holiday Days`+i.`Leave Days`)=0,null, (i.`Audit Days`+i.`Travel Days`)/((j.`Working Days`-(i.`Holiday Days`+i.`Leave Days`))*i.`Resource Capacitiy (%)`/100)*100) as 'Utilisation %', 
	i.`Other BOPs`,
    0 as 'Overhead Count',
	i.`Other BOP Types`,
	(j.`Working Days` - i.`Audit Days` - i.`Travel Days` - i.`Holiday Days` - i.`Leave Days` - i.`Other BOPs`) as 'Spare Capacity',
	(j.`Working Days`-(i.`Holiday Days`+i.`Leave Days`))*(i.`Resource Capacitiy (%)`/100) as 'Days Avaialble',
	i.`Billable` as 'Charged Days',
    i.`Non Billable`
FROM         
	(SELECT                       
	  t.Id, 
	  t.Name, 
	  t.Resource_Capacitiy__c as 'Resource Capacitiy (%)', 
	  t.Reporting_Business_Units__c as 'Business Unit', 
	  t.Manager, 
	  DATE_FORMAT(t.ActivityDate, '%Y %m') AS 'Period', 
	  SUM(IF(t.SubType = 'Audit', t.DurationDays, 0)) AS 'Audit Days', 
	  SUM(IF(t.SubType = 'Travel', t.DurationDays, 0)) AS 'Travel Days', 
	  SUM(IF(t.SubType = 'Public Holiday', t.DurationDays, 0)) AS 'Holiday Days', 
	  SUM(IF(t.SubType LIKE 'Leave%', t.DurationDays, 0)) AS 'Leave Days', 
	  SUM(IF(t.SubType not like 'Leave%' and t.Subtype not in ('Audit','Travel','Public Holiday'), t.DurationDays,0)) as 'Other BOPs',
      SUM(IF(t.Billable like 'Non Billable', 0, t.DurationDays)) as 'Billable',
      SUM(IF(t.Billable like 'Non Billable', t.DurationDays,0)) as 'Non Billable',
	  GROUP_CONCAT(DISTINCT IF(t.SubType not like 'Leave%' and t.Subtype not in ('Audit','Travel','Public Holiday'), t.Subtype ,null)) as 'Other BOP Types'
	FROM 
	   (SELECT 
			r.Id, 
			r.Name, 
			r.Resource_Capacitiy__c, 
			r.Resource_Type__c, 
			r.Work_Type__c, 
			r.Reporting_Business_Units__c, 
			m.Name as 'Manager', 
			#'Work Item Resource' AS 'Type', 
			tsli.Category__c as 'SubType',
            tsli.Billable__c as 'Billable',
			tsli.Actual_Hours__c*60 AS 'DurationMin', 
			tsli.Actual_Hours__c / 8 AS 'DurationDays', 
			tsli.Timesheet_Date__c as 'ActivityDate'
		FROM salesforce.resource__c r     
			INNER JOIN salesforce.user u ON u.Id = r.User__c     
			inner join salesforce.user m on u.ManagerId = m.Id
            left join salesforce.timesheet_line_item__c tsli on tsli.Resource_Name__c = r.Name and tsli.IsDeleted = 0 and date_format(tsli.Timesheet_Date__c, '%Y-%m') = @period 
		WHERE         
			Resource_Type__c NOT IN ('Client Services')             
            AND r.Reporting_Business_Units__c not like '%Product%'
			AND r.Status__c = 'Active'             
			AND r.Resource_Type__c = 'Employee'             
			AND r.Resource_Capacitiy__c IS NOT NULL             
			AND r.Resource_Capacitiy__c >= 30
		UNION
        SELECT 
			r.Id, 
			r.Name, 
			r.Resource_Capacitiy__c, 
			r.Resource_Type__c, 
			r.Work_Type__c, 
			r.Reporting_Business_Units__c, 
			m.Name as 'Manager', 
			#'Blackout Period Resource' AS 'Type', 
			bop.Resource_Blackout_Type__c as 'SubType',
            'Non Billable' as 'Billable',
			e.DurationInMinutes AS 'DurationMin', 
			e.DurationInMinutes / 60 / 8 AS 'DurationDays', 
			e.ActivityDate 
		FROM salesforce.resource__c r     
			INNER JOIN salesforce.user u ON u.Id = r.User__c     
			inner join salesforce.user m on u.ManagerId = m.Id     
			left JOIN salesforce.event e ON u.Id = e.OwnerId and e.IsDeleted = 0 and DATE_FORMAT(e.ActivityDate, '%Y-%m') = @period and e.RecordTypeId = '012900000003IjqAAE' # 'Blackout Period Resource'
			LEFT JOIN salesforce.blackout_period__c bop ON bop.Id = e.WhatId
		WHERE         
			r.Reporting_Business_Units__c not like '%Product%'
			AND r.Status__c = 'Active'             
			AND r.Resource_Type__c = 'Employee'             
			AND r.Resource_Capacitiy__c IS NOT NULL             
			AND r.Resource_Capacitiy__c >= 30) t     
	GROUP BY `Period` , t.Id) i
	INNER JOIN 
    (SELECT 
		DATE_FORMAT(wd.date, '%Y %m') AS 'Period', 
        COUNT(wd.date) AS 'Working Days' 
    FROM salesforce.`sf_working_days` wd 
    WHERE DATE_FORMAT(wd.date, '%Y-%m') = @period 
    GROUP BY `Period`) j ON i.Period = j.Period     
group by Id, i.Period);