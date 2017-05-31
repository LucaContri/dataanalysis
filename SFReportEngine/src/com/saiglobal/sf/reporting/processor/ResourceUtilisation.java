package com.saiglobal.sf.reporting.processor;

public class ResourceUtilisation extends AbstractQueryReport {
	
	public static final int monthsBefore = 6;
	public static final int monthsAfter = 7;
	public static final int capacityThreshold = 30;
	
	public ResourceUtilisation() {
		this.setHeader(false);
		this.columnWidth = new int[] {50,80,150,150};
	}
	
	@Override
	protected String getQuery() {
		return "SELECT  " + 
 "		if(i.`Business Unit` like '%Food%', 'Food', 'MS') as 'Stream', SUBSTRING_INDEX(i.`Business Unit`, '-', -(1)) as 'State', i.`Manager`, i.`Name`, i.`Resource Capacitiy (%)`, i.`Period`, j.`Working Days`, i.`Audit Days`, i.`Travel Days`, i.`Holiday Days`, i.`Leave Days`, " + 
 "        if(j.`Working Days`-(i.`Holiday Days`+i.`Leave Days`)=0,null, (i.`Audit Days`+i.`Travel Days`)/((j.`Working Days`-(i.`Holiday Days`+i.`Leave Days`))*i.`Resource Capacitiy (%)`/100)*100) as 'Utilisation %', "
 + "i.`Other BOPs`,"
 + "i.`Other BOP Types`,"
 + "(j.`Working Days` - i.`Audit Days` - i.`Travel Days` - i.`Holiday Days` - i.`Leave Days` - i.`Other BOPs`) as 'Spare Capacity', "
 + "(j.`Working Days`-(i.`Holiday Days`+i.`Leave Days`))*(i.`Resource Capacitiy (%)`/100) as 'Days Avaialble',"
 + "(i.`Audit Days`+i.`Travel Days`) as 'Charged Days' " +
 "    FROM " + 
 "        (SELECT  " + 
 "         " + 
 "            t.Id, " + 
 "            t.Name, " + 
 "            t.Resource_Capacitiy__c as 'Resource Capacitiy (%)', " + 
 "            t.Reporting_Business_Units__c as 'Business Unit', " + 
 "            t.Manager, " + 
 "            DATE_FORMAT(t.ActivityDate, '%Y %m') AS 'Period', " + 
 "            SUM(IF(t.SubType = 'Audit', t.DurationDays, 0)) AS 'Audit Days', " + 
 "            SUM(IF(t.SubType = 'Travel', t.DurationDays, 0)) AS 'Travel Days', " + 
 "            SUM(IF(t.SubType = 'Public Holiday', t.DurationDays, 0)) AS 'Holiday Days', " + 
 "            SUM(IF(t.SubType LIKE 'Leave%', t.DurationDays, 0)) AS 'Leave Days', "
 + "SUM(IF(t.SubType not like 'Leave%' and t.Subtype not in ('Audit','Travel','Public Holiday'), t.DurationDays,0)) as 'Other BOPs',"
 + "GROUP_CONCAT(DISTINCT IF(t.SubType not like 'Leave%' and t.Subtype not in ('Audit','Travel','Public Holiday'), t.Subtype ,null)) as 'Other BOP Types' " + 
 "    FROM " + 
 "        (SELECT  " + 
 "        r.Id, " + 
 "            r.Name, " + 
 "            r.Resource_Target_Days__c, " + 
 "            r.Resource_Capacitiy__c, " + 
 "            r.Resource_Type__c, " + 
 "            r.Work_Type__c, " + 
 "            r.Reporting_Business_Units__c, " + 
 "            m.Name as 'Manager', " + 
 "            rt.Name AS 'Type', " + 
 "            IF(wir.Work_Item_Type__c IS NULL, bop.Resource_Blackout_Type__c, wir.Work_Item_Type__c) AS 'SubType', " + 
 "            e.DurationInMinutes AS 'DurationMin', " + 
 "            e.DurationInMinutes / 60 / 8 AS 'DurationDays', " + 
 "            e.ActivityDate " + 
 "    FROM " + 
 "        resource__c r " + 
 "    INNER JOIN user u ON u.Id = r.User__c " + 
 "    inner join user m on u.ManagerId = m.Id " + 
 "    INNER JOIN event e ON u.Id = e.OwnerId " + 
 "    INNER JOIN recordtype rt ON e.RecordTypeId = rt.Id " + 
 "    LEFT JOIN work_item_resource__c wir ON wir.Id = e.WhatId " + 
 "    LEFT JOIN blackout_period__c bop ON bop.Id = e.WhatId " + 
 "    WHERE " + 
 "        (r.Reporting_Business_Units__c LIKE 'AUS%' " + 
 "            OR r.Reporting_Business_Units__c LIKE 'ASS%') " + 
 "            AND ((DATE_FORMAT(e.ActivityDate, '%Y %m') < DATE_FORMAT(DATE_ADD(NOW(), INTERVAL " + monthsAfter + " MONTH), '%Y %m') " + 
 //"            AND ((DATE_FORMAT(e.ActivityDate, '%Y %m') <= '2015 06' " + 
 "            AND DATE_FORMAT(e.ActivityDate, '%Y %m') > DATE_FORMAT(DATE_ADD(NOW(), INTERVAL " + (-monthsBefore) + " MONTH), '%Y %m')) " +
 //"            AND DATE_FORMAT(e.ActivityDate, '%Y %m') >= '2014 07') " +
 "            OR e.Id IS NULL) " + 
 "            AND Resource_Type__c NOT IN ('Client Services') " + 
 "            AND r.Reporting_Business_Units__c NOT IN ('AUS-CSC' , 'AUS-MGT', 'AUS-OPS') " + 
 "            AND r.Reporting_Business_Units__c NOT LIKE 'AUS-Product%' " + 
 "            AND (r.Reporting_Business_Units__c LIKE '%AUS-Food%' OR r.Reporting_Business_Units__c LIKE '%AUS-Manage%' OR r.Reporting_Business_Units__c LIKE '%AUS-Direct%' or r.Reporting_Business_Units__c LIKE '%AUS-Global%') " + 
 "            AND r.Active_User__c = 'Yes' " + 
 "            AND r.Resource_Type__c = 'Employee' " + 
 "            AND r.Resource_Capacitiy__c IS NOT NULL " + 
 "            AND r.Resource_Capacitiy__c >= " + capacityThreshold + " " + 
 "            AND (e.IsDeleted = 0 OR e.Id IS NULL)) t " + 
 "    GROUP BY `Period` , t.Id) i " + 
 "    INNER JOIN (SELECT  " + 
 "        DATE_FORMAT(wd.date, '%Y %m') AS 'Period', " + 
 "            COUNT(wd.date) AS 'Working Days' " + 
 "    FROM " + 
 "        `sf_working_days` wd " + 
 "    WHERE " + 
 "        DATE_FORMAT(wd.date, '%Y %m') < DATE_FORMAT(DATE_ADD(NOW(), INTERVAL " + monthsAfter + " MONTH), '%Y %m') " + 
 //"        DATE_FORMAT(wd.date, '%Y %m') <= '2015 06' " + 
 "            AND DATE_FORMAT(wd.date, '%Y %m') > DATE_FORMAT(DATE_ADD(NOW(), INTERVAL " + (-monthsBefore) + " MONTH), '%Y %m') " + 
 //"            AND DATE_FORMAT(wd.date, '%Y %m') >= '2014 07' " + 
 "    GROUP BY `Period`) j ON i.Period = j.Period " + 
 "    group by Id, i.Period;";
	}

	@Override
	protected String getReportName() {
		return "Resource Planning\\Resource Utilisation\\Resource Utilisation";
	}
	
	@Override
	protected String getTitle() {
		return "Resource Utilisation";
	}
}
