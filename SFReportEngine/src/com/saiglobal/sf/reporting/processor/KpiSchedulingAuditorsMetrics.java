package com.saiglobal.sf.reporting.processor;

public class KpiSchedulingAuditorsMetrics extends AbstractQueryReport {
	
	private static final String MS = "MS";
	private static final String Food = "Food";
	private static final String MSPlusFood = "MSPlusFood";
	
	public KpiSchedulingAuditorsMetrics() {
		setExecuteStatement(true);
	}
	private String getSubQuery(String type, int resource_min_capacity, boolean onlyCurrentAndFuturePeriods) {
		String additionalWhere = "";
		String[] rowNames = new String[] {"FTEDays%", "BlankDaysCount", "Utilisation","FTECount"};
		if (type.equalsIgnoreCase(MS)) {
			additionalWhere = "and r.Reporting_Business_Units__c not like '%AUS-Food%' ";
			rowNames = new String[] {"MS-FTEDays%", "MS-BlankDaysCount", "MS-Utilisation", "MS-FTECount"};
		} else if (type.equalsIgnoreCase(Food)) {
			additionalWhere = "and r.Reporting_Business_Units__c like '%AUS-Food%' ";
			rowNames = new String[] {"Food-FTEDays%", "Food-BlankDaysCount", "Food-Utilisation", "Food-FTECount"};
		} 
		String query = "select * from ("
		+ "select "
		+ "null as 'Id',"
		+ "'Scheduling Auditors Metrics' as 'Report Name',"
		+ "now() as 'Date',"
		+ "'Australia' as 'Region',"
		+ "'" + rowNames[0] + "' as 'RowName',"
		+ "t.Period as 'ColumnName', "
		+ "t.FTEDays/(t.FTEDays + t.ContractorDays) as 'Value' from ("
		+ "select date_format(e.ActivityDate, '%Y %m') as 'Period',sum(if(r.Resource_Type__c='Employee', e.DurationInMinutes/60/8, null)) as 'FTEDays', sum(if(r.Resource_Type__c='Contractor', e.DurationInMinutes/60/8, null)) as 'ContractorDays' "
		+ "from resource__c r "
		+ "INNER JOIN user u on u.Id = r.User__c "
		+ "INNER JOIN event e on u.Id = e.OwnerId "
		+ "INNER JOIN recordtype rt on e.RecordTypeId = rt.Id "
		+ "INNER JOIN work_item_resource__c wir on wir.Id = e.WhatId "
		+ "where (r.Reporting_Business_Units__c like 'AUS%' or r.Reporting_Business_Units__c like 'ASS%') "
		+ "and date_format(e.ActivityDate, '%Y %m') < date_format(date_add(now(), interval 5 month), '%Y %m')" + (onlyCurrentAndFuturePeriods?" and date_format(e.ActivityDate, '%Y %m') >= date_format(now(), '%Y %m') ":" ")
		+ "and Resource_Type__c not in ('Client Services') "
		+ "and r.Reporting_Business_Units__c not in ('AUS-CSC','AUS-MGT', 'AUS-OPS') "
		+ "and r.Reporting_Business_Units__c not like '%Product%' "
		+ additionalWhere
		+ "and e.IsDeleted=0 "
		+ "and wir.Work_Item_Type__c = 'Audit' "
		+ "and rt.Name = 'Work Item Resource' "
		+ "group by `Period`) t "
		+ "union "
		
		+ "(select "
		+ "null as 'Id',"
		+ "'Scheduling Auditors Metrics' as 'Report Name',"
		+ "now() as 'Date',"
		+ "'Australia' as 'Region',"
		+ "'" + rowNames[1] + "' as 'RowName',"
		+ "date_format(i.date, '%Y %m') as 'ColumnName',"
		+ "count(i.date) as 'Value' "
		+ "FROM "
		+ "(SELECT wd.date, r.Id "
		+ "FROM `sf_working_days` wd, resource__c r "
		+ "WHERE  "
		+ "r.Id in (select r.Id from resource__c r where (r.Reporting_Business_Units__c like 'AUS%' or r.Reporting_Business_Units__c like 'ASS%') and r.Reporting_Business_Units__c not like 'AUS-Product%' and Resource_Type__c not in ('Client Services') and r.Reporting_Business_Units__c not in ('AUS-CSC','AUS-MGT', 'AUS-OPS') and r.Active_User__c = 'Yes' "
			+ additionalWhere
			+ "and r.Resource_Capacitiy__c > " + resource_min_capacity + ") "
		+ "and date_format(wd.date, '%Y %m') < date_format(date_add(now(), interval 5 month), '%Y %m')" + (onlyCurrentAndFuturePeriods?" and date_format(wd.date, '%Y %m') >= date_format(now(), '%Y %m')":" ") + " ) i "
		+ "LEFT JOIN "
		+ "(SELECT r.Id, e.ActivityDate "
		+ "FROM `event` e "
		+ "INNER JOIN `resource__c` r ON r.User__c = e.OwnerId "
		+ "WHERE "
		+ "(r.Reporting_Business_Units__c like 'AUS%' or r.Reporting_Business_Units__c like 'ASS%') "
		+ "and r.Reporting_Business_Units__c not like 'AUS-Product%' "
		+ additionalWhere
		+ "and r.Resource_Type__c not in ('Client Services') "
		+ "and r.Reporting_Business_Units__c not in ('AUS-CSC','AUS-MGT', 'AUS-OPS') "
		+ "and r.Resource_Capacitiy__c > " + resource_min_capacity + " "
		+ "and r.Active_User__c = 'Yes' "
		+ "and date_format(e.ActivityDate, '%Y %m') < date_format(date_add(now(), interval 5 month), '%Y %m')" + (onlyCurrentAndFuturePeriods?" and date_format(e.ActivityDate, '%Y %m') >= date_format(now(), '%Y %m') ":" ") + " ) t ON t.ActivityDate = i.date AND t.id = i.Id "
		+ "WHERE  t.Id is NULL "
		+ "GROUP BY `ColumnName`) "
		+ "union "
		+ "(select "
		+ "null as 'Id',"
		+ "'Scheduling Auditors Metrics' as 'Report Name',"
		+ "now() as 'Date',"
		+ "'Australia' as 'Region',"
		+ "'" + rowNames[2] + "' as 'RowName',"
		+ "k.Period as 'ColumnName', "
		//+ "sum(if(k.`Resource_Target_Days__c`>" + resource_target_threshold_full_time_auditors + ",k.AuditPlusTravelDays,0))/(sum(if(k.`Resource_Target_Days__c`>" + resource_target_threshold_full_time_auditors + ",k.`Working Days`*k.`Resource_Target_Days__c`/180,0))-sum(if(k.`Resource_Target_Days__c`>" + resource_target_threshold_full_time_auditors + ",k.`LeavePlusHolidayDays`,0))) as 'Value' "
		+ "sum(if(k.`Resource_Capacitiy__c`>" + resource_min_capacity + ",k.AuditPlusTravelDays,0))/(sum(if(k.`Resource_Capacitiy__c`>" + resource_min_capacity + ",(k.`Working Days` - k.`LeavePlusHolidayDays`)* k.`Resource_Capacitiy__c`/100, 0)))  AS 'Value' "
		+ "from "
		+ "(select i.*, j.`Working Days` from "
		+ "(select date_format(t.ActivityDate, '%Y %m') as 'Period', t.Id, t.Name, t.Resource_Target_Days__c, t.Resource_Capacitiy__c, "
		+ "sum(if(t.SubType = 'Audit' or t.SubType = 'Travel', t.DurationDays,0)) as 'AuditPlusTravelDays', "
		+ "sum(if(t.SubType like 'Leave%' or t.SubType='Public Holiday', t.DurationDays,0)) as 'LeavePlusHolidayDays' "
		+ "from ( "
		+ "select r.Id, r.Name, r.Resource_Target_Days__c, r.Resource_Capacitiy__c, r.Resource_Type__c, r.Work_Type__c, rt.Name as 'Type', if (wir.Work_Item_Type__c is null, bop.Resource_Blackout_Type__c , wir.Work_Item_Type__c) as 'SubType', e.DurationInMinutes as 'DurationMin', e.DurationInMinutes/60/8 as 'DurationDays', e.ActivityDate "
		+ "from resource__c r "
		+ "INNER JOIN user u on u.Id = r.User__c "
		+ "inner join event e on u.Id = e.OwnerId "
		+ "INNER JOIN recordtype rt on e.RecordTypeId = rt.Id "
		+ "LEFT JOIN work_item_resource__c wir on wir.Id = e.WhatId "
		+ "LEFT JOIN blackout_period__c bop on bop.Id = e.WhatId "
		+ "where (r.Reporting_Business_Units__c like 'AUS%' or r.Reporting_Business_Units__c like 'ASS%') "
		+ "and ((date_format(e.ActivityDate, '%Y %m') < date_format(date_add(now(), interval 5 month), '%Y %m')" + (onlyCurrentAndFuturePeriods?" and date_format(e.ActivityDate, '%Y %m') >= date_format(now(), '%Y %m') ":" ") + " ) or e.Id is null) "
		+ "and Resource_Type__c not in ('Client Services') "
		+ "and r.Reporting_Business_Units__c not in ('AUS-CSC','AUS-MGT', 'AUS-OPS') "
		+ "and r.Reporting_Business_Units__c not like 'AUS-Product%' "
		+ additionalWhere
		+ "and r.Active_User__c = 'Yes' "
		+ "and r.Resource_Type__c = 'Employee' "
		+ "and r.Resource_Capacitiy__c is not null "
		+ "and r.Resource_Capacitiy__c > "  + resource_min_capacity + " "
		+ "and (e.IsDeleted=0 or e.Id is null)) t "
		+ "group by `Period`, t.Id) i "
		+ "inner join (SELECT date_format(wd.date, '%Y %m') as 'Period', count(wd.date) as 'Working Days' "
		+ "FROM `sf_working_days` wd "
		+ "WHERE  "
		+ "date_format(wd.date, '%Y %m') < date_format(date_add(now(), interval 5 month), '%Y %m')" + (onlyCurrentAndFuturePeriods?" and date_format(wd.date, '%Y %m') >= date_format(now(), '%Y %m')  ":" ")
		+ "group by `Period`) j on i.Period = j.Period) k "
		+ "group by `ColumnName`)"
		+ "union "
		+ "(select "
		+ "null as 'Id',"
		+ "'Scheduling Auditors Metrics' as 'Report Name',"
		+ "now() as 'Date',"
		+ "'Australia' as 'Region',"
		+ "'" + rowNames[3] + "' as 'RowName',"
		+ "k.Period as 'ColumnName', "
		+ "count(distinct k.Id) as 'Value' "
		+ "from "
		+ "(select i.*, j.`Working Days` from "
		+ "(select date_format(t.ActivityDate, '%Y %m') as 'Period', t.Id, t.Name, t.Resource_Target_Days__c, t.Resource_Capacitiy__c, "
		+ "sum(if(t.SubType = 'Audit' or t.SubType = 'Travel', t.DurationDays,0)) as 'AuditPlusTravelDays', "
		+ "sum(if(t.SubType like 'Leave%' or t.SubType='Public Holiday', t.DurationDays,0)) as 'LeavePlusHolidayDays' "
		+ "from ( "
		+ "select r.Id, r.Name, r.Resource_Target_Days__c, r.Resource_Capacitiy__c, r.Resource_Type__c, r.Work_Type__c, rt.Name as 'Type', if (wir.Work_Item_Type__c is null, bop.Resource_Blackout_Type__c , wir.Work_Item_Type__c) as 'SubType', e.DurationInMinutes as 'DurationMin', e.DurationInMinutes/60/8 as 'DurationDays', e.ActivityDate "
		+ "from resource__c r "
		+ "INNER JOIN user u on u.Id = r.User__c "
		+ "inner join event e on u.Id = e.OwnerId "
		+ "INNER JOIN recordtype rt on e.RecordTypeId = rt.Id "
		+ "LEFT JOIN work_item_resource__c wir on wir.Id = e.WhatId "
		+ "LEFT JOIN blackout_period__c bop on bop.Id = e.WhatId "
		+ "where (r.Reporting_Business_Units__c like 'AUS%' or r.Reporting_Business_Units__c like 'ASS%') "
		+ "and ((date_format(e.ActivityDate, '%Y %m') < date_format(date_add(now(), interval 5 month), '%Y %m')" + (onlyCurrentAndFuturePeriods?" and date_format(e.ActivityDate, '%Y %m') >= date_format(now(), '%Y %m') ":" ") + " ) or e.Id is null) "
		+ "and Resource_Type__c not in ('Client Services') "
		+ "and r.Reporting_Business_Units__c not in ('AUS-CSC','AUS-MGT', 'AUS-OPS') "
		+ "and r.Reporting_Business_Units__c not like 'AUS-Product%' "
		+ additionalWhere
		+ "and r.Active_User__c = 'Yes' "
		+ "and r.Resource_Type__c = 'Employee' "
		+ "and r.Resource_Capacitiy__c is not null "
		+ "and r.Resource_Capacitiy__c > "  + resource_min_capacity + " "
		+ "and (e.IsDeleted=0 or e.Id is null)) t "
		+ "group by `Period`, t.Id) i "
		+ "inner join (SELECT date_format(wd.date, '%Y %m') as 'Period', count(wd.date) as 'Working Days' "
		+ "FROM `sf_working_days` wd "
		+ "WHERE  "
		+ "date_format(wd.date, '%Y %m') < date_format(date_add(now(), interval 5 month), '%Y %m')" + (onlyCurrentAndFuturePeriods?" and date_format(wd.date, '%Y %m') >= date_format(now(), '%Y %m')  ":" ")
		+ "group by `Period`) j on i.Period = j.Period) k "
		+ "group by `ColumnName`) "
		+ ") ";
		return query;
	}
	@Override
	protected String getQuery() {
		int resource_min_capacity = 27;
		boolean onlyCurrentAndFuturePeriods = true;
		String query = "INSERT INTO sf_report_history ("
				+ getSubQuery(MS, resource_min_capacity, onlyCurrentAndFuturePeriods)
				+ "f);"
				+ "INSERT INTO sf_report_history ("
				+ getSubQuery(Food, resource_min_capacity, onlyCurrentAndFuturePeriods)
				+ "f);"
				+ "INSERT INTO sf_report_history ("
				+ getSubQuery(MSPlusFood, resource_min_capacity, onlyCurrentAndFuturePeriods)
				+ "f);";
		return query;
	}

	@Override
	protected String getReportName() {
		return null;
	}
}
