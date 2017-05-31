package com.saiglobal.reporting.utility;

import java.sql.ResultSet;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.HashMap;

import org.apache.commons.lang.StringUtils;

import com.saiglobal.reporting.model.KPIData;
import com.saiglobal.sf.core.data.DbHelper;

public class KPIProcessorScheduling extends AbstractKPIProcessor {
		
	public KPIProcessorScheduling(DbHelper db_certification, DbHelper db_tis,int periodsToReport) {
		super(db_certification, db_tis, periodsToReport);
	}
	
	public Object[][] getOnTargetRatios() throws Exception {
		Object[][] tableData = new Object[periodsToReport+1][5];
		String query = "select t.`Scheduled Period`, round(sum(if(t.`Scheduled - Target`=0,1,0))/count(t.id)*100,2) as 'On Target %', round(sum(if(t.`Scheduled - Target`=1,1,0))/count(t.id)*100,2)  as '1 month to Target %', round(sum(if(t.`Scheduled - Target`=2,1,0))/count(t.id)*100,2)  as '2 month to Target %', round(sum(if(t.`Scheduled - Target`>=3,1,0))/count(t.id)*100,2)  as '3+ month to Target %' from ( "
				+ "SELECT "
				+ "wi.id as 'id', "
				+ "DATE_FORMAT(wi.Work_Item_Date__c, '%Y %m') as 'Scheduled Period', "
				+ "DATE_FORMAT(wi.Service_target_date__c, '%Y %m') as 'Target Period', "
				+ "abs(round(datediff(date_format(wi.Work_Item_Date__c, '%Y-%m-01'), date_format(wi.Service_target_date__c,'%Y-%m-01'))/(365/12))) as 'Scheduled - Target' "
				+ "FROM `work_item__c` wi "
				+ "LEFT JOIN `recordtype` rt ON wi.RecordTypeId = rt.Id "
				+ "WHERE "
				+ "rt.Name = 'Audit' "
				+ "AND (wi.Revenue_Ownership__c LIKE 'AUS-Food%' OR wi.Revenue_Ownership__c LIKE 'AUS-Global%' OR wi.Revenue_Ownership__c LIKE 'AUS-Managed%' OR wi.Revenue_Ownership__c LIKE 'AUS-Direct%') "
				+ "and wi.Status__c NOT IN ('Open', 'Service Change', 'Cancelled', 'Budget') "
				+ "AND date_format(wi.Work_Item_Date__c, '%Y %m') >= date_format(date_add(now(), interval " + (-this.periodsToReport) + " month), '%Y %m') "
				+ "AND date_format(wi.Work_Item_Date__c, '%Y %m') <= date_format(date_add(now(), interval -1 month), '%Y %m') "
				+ ") t "
				+ "group by `Scheduled Period` "
				+ "order by `Scheduled Period`";
		ResultSet rs = db_certification.executeSelect(query, -1);
		tableData[0] = new Object[] {"Scheduled Period", "On Target %", "1 month to Target %", "2 month to Target %", "3+ month to Target %"};
		while (rs.next()) {
			tableData[rs.getRow()] = new Object[] {
					displayMonthFormat.format(mysqlPeriodFormat.parse(rs.getString("Scheduled Period"))), 
					rs.getDouble("On Target %"), 
					rs.getDouble("1 month to Target %"), 
					rs.getDouble("2 month to Target %"), 
					rs.getDouble("3+ month to Target %")};
		}
		return tableData;
	} 
	
	private String[] getAuditorsUtilisationPeriods() {
		String[] periods = new String[periodsToReport];
		Calendar aux = Calendar.getInstance();
		aux.add(Calendar.MONTH, -2);
		for (int i = 0; i < periodsToReport; i++) {
			periods[i] = mysqlPeriodFormat.format(aux.getTime());
			aux.add(Calendar.MONTH, 1);
		}
		return periods;
	}
	
	private String getAuditorsUtilisationQuery(String stream) {
		String additionalWhere = "and RowName not like 'Food%' and RowName not like 'MS%' ";
		if (stream.equalsIgnoreCase(KPIData.MS)) {
			additionalWhere = "and RowName like 'MS%'";
		} else if (stream.equalsIgnoreCase(KPIData.FOOD)) {
			additionalWhere = "and RowName like 'Food%'";
		}
		
		return "select t2.ColumnName as 'Period',"
			+ "round(sum(if(t2.RowName like '%BlankDaysCount', t2.Value,0)),0) as 'BlankDaysCount',"
			+ "round(sum(if(t2.RowName like '%Utilisation', t2.Value,0))*100,2) as 'Utilisation',"
			+ "round(sum(if(t2.RowName like '%FTEDays%', t2.Value,0))*100,2) as 'FTEDays', "
			+ "round(100-sum(if(t2.RowName like '%FTEDays%', t2.Value,0))*100,2) as 'ContractorDays' "
			+ "from ("
			+ "select t.* from ("
			+ "select * from sf_report_history "
			+ "where ReportName='Scheduling Auditors Metrics' "
			+ "and Region = 'Australia' "
			+ additionalWhere
			+ "and ColumnName in ('" + StringUtils.join(getAuditorsUtilisationPeriods(), "','") + "') "
			+ "order by Date desc) t "
			+ "group by t.Region,t.ColumnName, RowName) t2 "
			+ "group by t2.Region,t2.ColumnName "
			+ "order by t2.Region,t2.ColumnName";
	}
	
	public HashMap<String, Object[][]> getAuditorsUtilisation() throws Exception {
		HashMap<String, Object[][]> returnValue = new HashMap<String, Object[][]>();
		Object[][] tableDataFood = new Object[periodsToReport+1][4];
		Object[][] tableDataMS = new Object[periodsToReport+1][4];
		Object[][] tableDataMSPlusFood = new Object[periodsToReport+1][4];
		tableDataFood[0] = new Object[] {"Period", "Employee %", "Contractors %", "Employee Utilisation %"};
		tableDataMS[0] = new Object[] {"Period", "Employee %", "Contractors %", "Employee Utilisation %"};
		tableDataMSPlusFood[0] = new Object[] {"Period", "FTE %", "Contractors %", "Employee Utilisation %"};
		
		String query = getAuditorsUtilisationQuery(KPIData.MS);
		ResultSet rs = db_certification.executeSelect(query, -1);
		while (rs.next()) {
			tableDataMS[rs.getRow()] = new Object[] {displayMonthFormat.format(mysqlPeriodFormat.parse(rs.getString("Period"))), rs.getDouble("FTEDays"), rs.getDouble("ContractorDays"), rs.getDouble("Utilisation")};
		}
		query = getAuditorsUtilisationQuery(KPIData.FOOD);
		rs = db_certification.executeSelect(query, -1);
		while (rs.next()) {
			tableDataFood[rs.getRow()] = new Object[] {displayMonthFormat.format(mysqlPeriodFormat.parse(rs.getString("Period"))), rs.getDouble("FTEDays"), rs.getDouble("ContractorDays"), rs.getDouble("Utilisation")};
		}
		query = getAuditorsUtilisationQuery(KPIData.MS_PLUS_FOOD);
		rs = db_certification.executeSelect(query, -1);
		while (rs.next()) {
			tableDataMSPlusFood[rs.getRow()] = new Object[] {displayMonthFormat.format(mysqlPeriodFormat.parse(rs.getString("Period"))), rs.getDouble("FTEDays"), rs.getDouble("ContractorDays"), rs.getDouble("Utilisation")};
		}
		returnValue.put(KPIData.FOOD, tableDataFood);
		returnValue.put(KPIData.MS, tableDataMS);
		returnValue.put(KPIData.MS_PLUS_FOOD, tableDataMSPlusFood);
		return returnValue;
	}
	
	public Calendar getAuditorsUtilisationLastUpdate() throws Exception {
		SimpleDateFormat mysqlDateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
		Calendar lastUpdate = Calendar.getInstance();
		String query = "select max(t2.Date) as 'LastUpdate' from ("
				+ "select t.* "
				+ "from ( "
				+ "select * from sf_report_history "
				+ "where ReportName='Scheduling Auditors Metrics' "
				+ "and Region = 'Australia' "
				+ "and ColumnName in ('" + StringUtils.join(getAuditorsUtilisationPeriods(), "','") + "') "
				+ "order by Date desc) t "
				+ "group by t.Region,t.ColumnName, RowName) t2";
		lastUpdate.setTime(mysqlDateFormat.parse(db_certification.executeScalar(query)));
		return lastUpdate;
	}
	
	/*
	 * Returns Scheduled/Available, Confirmed/Available and Open/Available ratios
	 * Scheduled as 'Scheduled' + 'Scheduled - Offered'
	 * Open as 'Open' excluding work items with Open_Sub_Status__c
	 * Confirmed all Statuses excluding 'Cancelled', 'Budget', 'Open', 'Scheduled', 'Scheduled - Offered'
	 * Available as Confirmed, Scheduled, Open as above defined
	 */
	public HashMap<String, Object[][]> getConfirmedOpenRatios() throws Exception {
		Object[][] tableDataFood = new Object[periodsToReport+1][5];
		Object[][] tableDataMS = new Object[periodsToReport+1][5];
		Object[][] tableDataPS = new Object[periodsToReport+1][5];
		
		HashMap<String, Object[][]> returnValue = new HashMap<String, Object[][]>();
		String query = "select t2.Stream, t2.Period, "
				+ "ROUND((t2.Confirmed + t2.Open + t2.Scheduled)) as 'Available',"
				+ "ROUND(t2.Confirmed/(t2.Confirmed + t2.Open + t2.Scheduled)*100,2) as 'Confirmed %',"
				+ "ROUND(t2.Scheduled/(t2.Confirmed + t2.Open + t2.Scheduled)*100,2) as 'Scheduled %',"
				+ "ROUND(t2.Open/(t2.Confirmed + t2.Open + t2.Scheduled)*100,2) as 'Open %' "
				+ "from ("
				+ "select t.Period, "
				+ "t.Stream, "
				+ "sum(if(t.Status='Confirmed',t.Days,0)) as 'Confirmed',"
				+ "sum(if(t.Status='Scheduled',t.Days,0)) as 'Scheduled',"
				+ "sum(if(t.Status='Open',t.Days,0)) as 'Open' from "
				+ "((SELECT "
				+ "if (wi.Revenue_Ownership__c like '%Food%', 'Food', if (wi.Revenue_Ownership__c like '%Product%', 'PS', 'MS')) as 'Stream', "
				+ "wi.Status__c AS 'Status', "
				+ "DATE_FORMAT(wi.Work_Item_Date__c, '%Y %m') as 'Period', "
				+ "SUM(wi.Required_Duration__c)/8 as 'Days' "
				+ "FROM `work_item__c` wi "
				+ "LEFT JOIN `recordtype` rt ON wi.RecordTypeId = rt.Id "
				+ "WHERE "
				+ "rt.Name = 'Audit' "
				+ "and wi.IsDeleted=0 "
				+ "and wi.Status__c ='Open' "
				+ "and wi.Open_Sub_Status__c is null "
				//+ "AND (wi.Revenue_Ownership__c LIKE 'AUS-Food%' OR wi.Revenue_Ownership__c LIKE 'AUS-Global%' OR wi.Revenue_Ownership__c LIKE 'AUS-Managed%' OR wi.Revenue_Ownership__c LIKE 'AUS-Direct%') "
				+ "AND wi.Revenue_Ownership__c LIKE 'AUS%' "
				+ "AND date_format(wi.Work_Item_Date__c, '%Y %m') >= date_format(date_add(now(), interval -1 month), '%Y %m') "
				+ "AND date_format(wi.Work_Item_Date__c, '%Y %m') <= date_format(date_add(now(), interval " + (this.periodsToReport-2) + " month), '%Y %m') "
				+ "GROUP BY `Stream`, `Status`, `Period` "
				+ ") UNION ( "
				+ "SELECT "
				+ "if (wi.Revenue_Ownership__c like '%Food%', 'Food', if (wi.Revenue_Ownership__c like '%Product%', 'PS', 'MS')) as 'Stream', "
				+ "if (wi.Status__c in ('Scheduled - Offered', 'Scheduled'), 'Scheduled', if(wi.Status__c = 'Service Change', 'Open','Confirmed')) AS 'Status', "
				+ "DATE_FORMAT(wird.FStartDate__c, '%Y %m') as 'Period', "
				+ "sum(if(Budget_Days__c is null, wird.Scheduled_Duration__c / 8, wird.Scheduled_Duration__c / 8 + Budget_Days__c)) AS 'Value' "
				+ "FROM `work_item__c` wi "
				+ "LEFT JOIN `work_item_resource__c` wir ON wir.work_item__c = wi.Id "
				+ "LEFT JOIN `work_item_resource_day__c` wird ON wird.Work_Item_Resource__c = wir.Id "
				+ "LEFT JOIN `recordtype` rt ON wi.RecordTypeId = rt.Id "
				+ "WHERE "
				+ "rt.Name = 'Audit' "
				+ "AND wir.IsDeleted = 0 "
				+ "AND wird.IsDeleted = 0 "
				+ "AND wir.Work_Item_Type__c IN ('Audit' , 'Audit Planning', 'Client Management', 'Budget') "
				//+ "AND (wi.Revenue_Ownership__c LIKE 'AUS-Food%' OR wi.Revenue_Ownership__c LIKE 'AUS-Global%' OR wi.Revenue_Ownership__c LIKE 'AUS-Managed%' OR wi.Revenue_Ownership__c LIKE 'AUS-Direct%') "
				+ "AND wi.Revenue_Ownership__c LIKE 'AUS%' "
				+ "AND wir.Role__c NOT IN ('Observer' , 'Verifying Auditor', 'Verifier') "
				+ "and wi.Status__c NOT IN ('Open', 'Cancelled', 'Budget') "
				+ "AND date_format(wird.FStartDate__c, '%Y %m') >= date_format(date_add(now(), interval -1 month), '%Y %m') "
				+ "AND date_format(wird.FStartDate__c, '%Y %m') <= date_format(date_add(now(), interval " + (this.periodsToReport-2) + " month), '%Y %m') "
				+ "GROUP BY `Stream`, `Status`, `Period`)) t "
				+ "group by t.Stream, t.Period "
				+ ") t2 order by t2.Period, t2.Stream";
		
		ResultSet rs = db_certification.executeSelect(query, -1);
		tableDataFood[0] = new Object[] {"Period", "Available", "Confirmed %", "Scheduled %", "Open %"};
		tableDataMS[0] = new Object[] {"Period", "Available", "Confirmed %", "Scheduled %", "Open %"};
		tableDataPS[0] = new Object[] {"Period", "Available", "Confirmed %", "Scheduled %", "Open %"};
		int row = 3;
		while (rs.next()) {
			if (rs.getString("Stream").equalsIgnoreCase("Food"))
				tableDataFood[row/3] = new Object[] {displayMonthFormat.format(mysqlPeriodFormat.parse(rs.getString("Period"))), rs.getDouble("Available"), rs.getDouble("Confirmed %"), rs.getDouble("Scheduled %"), rs.getDouble("Open %")};
			else if (rs.getString("Stream").equalsIgnoreCase("MS"))
				tableDataMS[row/3] = new Object[] {displayMonthFormat.format(mysqlPeriodFormat.parse(rs.getString("Period"))), rs.getDouble("Available"), rs.getDouble("Confirmed %"), rs.getDouble("Scheduled %"), rs.getDouble("Open %")};
			else
				tableDataPS[row/3] = new Object[] {displayMonthFormat.format(mysqlPeriodFormat.parse(rs.getString("Period"))), rs.getDouble("Available"), rs.getDouble("Confirmed %"), rs.getDouble("Scheduled %"), rs.getDouble("Open %")};
			row++;
		}
		returnValue.put(KPIData.FOOD, tableDataFood);
		returnValue.put(KPIData.MS, tableDataMS);
		returnValue.put(KPIData.PS, tableDataPS);
		return returnValue;
	}
	
	/*
	 * Returns SiteCertifications not in ('Application Unpaid','Applicant','De-registered','Concluded','Transferred') 
	 * 	by validated flag (i.e. Lifecycle_Validated__c * Data_Enrichment_Review_complete__c) by Revenue Stream
	 * tableData[0] => Food
	 * tableData[1] => MS
	 * tableData[2] => PS
	 */
	public HashMap<String, Object[][]> getDataValidated() throws Exception {
		Object[][] tableDataFood = new Object[periodsToReport+1][3];
		Object[][] tableDataMS = new Object[periodsToReport+1][3];
		Object[][] tableDataPS = new Object[periodsToReport+1][3];
		HashMap<String, Object[][]> returnValue = new HashMap<String, Object[][]>();
		String query = "select t.Period,"
				+ "sum(if(t.`Data Validated` and t.Stream='Food', 1, 0)) as 'Food-Validated', sum(if(not(t.`Data Validated`) and t.Stream='Food', 1, 0)) as 'Food-Not Validated',"
				+ "sum(if(t.`Data Validated` and t.Stream='MS', 1, 0)) as 'MS-Validated', sum(if(not(t.`Data Validated`) and t.Stream='MS', 1, 0)) as 'MS-Not Validated',"
				+ "sum(if(t.`Data Validated` and t.Stream='PS', 1, 0)) as 'PS-Validated', sum(if(not(t.`Data Validated`) and t.Stream='PS', 1, 0)) as 'PS-Not Validated' from ("
				+ "select date_format(sc.CreatedDate,'%Y %m') as 'Period',"
				+ "if (sc.Operational_Ownership__c like '%Food%', 'Food', if (Operational_Ownership__c like '%Product%', 'PS', 'MS')) as 'Stream',"
				+ "sc.Lifecycle_Validated__c,"
				+ "sc.Data_Enrichment_Review_complete__c,"
				+ "sc.Lifecycle_Validated__c*sc.Data_Enrichment_Review_complete__c as 'Data Validated' "
				+ "from certification__c sc "
				+ "inner join site_certification_standard_program__c scsp on scsp.Site_Certification__c = sc.Id "
				+ "where "
				+ "sc.IsDeleted = 0 "
				+ "and scsp.IsDeleted = 0 "
				+ "and scsp.Status__c not in ('Application Unpaid','Applicant','De-registered','Concluded','Transferred') "
				+ "and sc.Primary_Certification__c is not null "
				+ "and sc.Status__c = 'Active' "
				+ "and (sc.Mandatory_Site__c=1 or (sc.Mandatory_Site__c=0 and sc.FSample_Site__c like '%unchecked%')) "
				+ "and scsp.Administration_Ownership__c like 'AUS%' "
				+ "and date_format(sc.CreatedDate,'%Y %m') >= date_format(date_add(now(), interval " + (1-this.periodsToReport) + " month), '%Y %m') "
				+ "and date_format(sc.CreatedDate,'%Y %m') <= date_format(now(), '%Y %m') "
				+ "group by sc.id ) t "
				+ "group by t.Period";
		
		ResultSet rs = db_certification.executeSelect(query, -1);
		tableDataFood[0] = new Object[] {"Period", "Validated", "Not Validated"};
		tableDataMS[0] = new Object[] {"Period", "Validated", "Not Validated"};
		tableDataPS[0] = new Object[] {"Period", "Validated", "Not Validated"};
		for (int i = 1; i<tableDataFood.length; i++) {
			tableDataFood[i] = new Object[] {"",0.0,0.0};
			tableDataMS[i] = new Object[] {"",0.0,0.0};
			tableDataPS[i] = new Object[] {"",0.0,0.0};
		}
		
		while (rs.next()) {
			tableDataFood[rs.getRow()] = new Object[] {displayMonthFormat.format(mysqlPeriodFormat.parse(rs.getString("Period"))), rs.getDouble("Food-Validated"), rs.getDouble("Food-Not Validated")};
			tableDataMS[rs.getRow()] = new Object[] {displayMonthFormat.format(mysqlPeriodFormat.parse(rs.getString("Period"))), rs.getDouble("MS-Validated"), rs.getDouble("MS-Not Validated")};
			tableDataPS[rs.getRow()] = new Object[] {displayMonthFormat.format(mysqlPeriodFormat.parse(rs.getString("Period"))), rs.getDouble("PS-Validated"), rs.getDouble("PS-Not Validated")};
		}
		returnValue.put(KPIData.FOOD, tableDataFood);
		returnValue.put(KPIData.MS, tableDataMS);
		returnValue.put(KPIData.PS, tableDataPS);
		return returnValue;
	}
}
