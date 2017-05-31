package com.saiglobal.reporting.servlets;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.ResultSet;
import java.text.SimpleDateFormat;
import java.util.HashSet;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.log4j.Logger;

import com.saiglobal.sf.core.data.DbHelper;
import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;


@SuppressWarnings("serial")
public class AuditDaysSumamryServlet extends HttpServlet {
	private static Logger logger = Logger.getLogger(AuditDaysSumamryServlet.class);
	private static DbHelper db;
	private static final GlobalProperties gp;
	private static final SimpleDateFormat periodFormatter = new SimpleDateFormat("yyyy MM");
	
	static {
	// Initialise
		gp = GlobalProperties.getDefaultInstance();
		try {
			logger.info("static init");
			db = new DbHelper(gp);
		} catch (Exception e) {
			logger.error(e);
			Utility.handleError(gp, e);
		}
	}
	
	public void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		Map<String, String[]> parameters;
		PrintWriter out = response.getWriter();
		boolean stacked = false;
		try {
			parameters = request.getParameterMap();
			try {
				
				if (parameters.containsKey("stacked"))
					stacked = Boolean.parseBoolean(parameters.get("stacked")[0]);
				
			} catch (Exception e) {
				Utility.handleError(gp, e);
			}
			

			
			
			String json = "";
			
			if (stacked) {
				String[] statuses = new String[]{"Budget", "Confirmed", "Scheduled", "Open"};
				String statusWhereClause = "RowName IN (";
				for (String status : statuses) {
					statusWhereClause+="'" + status + "',";
				}
				statusWhereClause = Utility.removeLastChar(statusWhereClause) + ") ";
				//String[] colors = new String[]{"LimeGreen", "LightGreen", "MediumSpringGreen", "LightSteelBlue ", "Steelblue", "Gold"};
				String[] colors = new String[]{"LightSteelBlue ", "Steelblue", "Gold"};
				json = "{"
						+ "\"header\": {\"x\":\"Period\", \"y\": ["; 
				for (String status : statuses) {
					if (!status.equalsIgnoreCase("Budget"))
						json += "\"" + status + "\","; 
				}
				json = Utility.removeLastChar(json) + "]},";
				
				json += "\"colors\": [";
				for (String color : colors) {
					json += "\"" + color + "\","; 
				}
				json = Utility.removeLastChar(json) + "],";
				
				json += "\"instances\": [";
				/*String query = "SELECT "
						//+ "'MS + Food' AS 'BusinessUnit',"
						+ "date, "
						+ "ColumnName AS 'Period',"
						+ "RowName AS 'Status',"
						+ "Sum(Value) AS 'Days' "
						+ "FROM " + db.getDBTableName("sf_report_history") + " "
						+ "WHERE "
						+ "ReportName = 'Planning Days Report' "
						+ "AND " + statusWhereClause
						+ "GROUP BY date, `Period`, `Status` "
						+ "ORDER BY date, `Period`, `Status`";
				*/
				String query ="select  t.date,"
						+ "t.Period,"
						+ "sum(t.Budget) as 'Budget',"
						+ "sum(t.Confirmed) as 'Confirmed',"
						+ "sum(t.NewBusiness) as 'NewBusiness',"
						+ "sum(t.Open) as 'Open',"
						+ "sum(t.Scheduled) as 'Scheduled',"
						+ "sum(t.ScheduledOffered) as 'ScheduledOffered',"
						+ "sum(t.ServiceChange) as 'ServiceChange' "
						+ "from "
						+ "(SELECT "
						+ "date,"
						+ "ColumnName AS 'Period',"
						+ "RowName,"
						+ "if(RowName = 'Budget', Sum(Value), 0) AS 'Budget',"
						+ "if(RowName = 'Confirmed', Sum(Value), 0) AS 'Confirmed',"
						+ "if(RowName = 'New Business', Sum(Value), 0) AS 'NewBusiness',"
						+ "if(RowName = 'Open', Sum(Value), 0) AS 'Open',"
						+ "if(RowName = 'Scheduled', Sum(Value), 0) AS 'Scheduled',"
						+ "if(RowName = 'Scheduled - Offered', Sum(Value), 0) AS 'ScheduledOffered',"
						+ "if(RowName = 'Service change', Sum(Value), 0) AS 'ServiceChange' "
						+ "FROM `sf_report_history` "
						+ "WHERE "
						+ "ReportName = 'Planning Days Report' "
						+ "AND " + statusWhereClause //RowName IN ('Confirmed' , 'New Business', 'Open', 'Scheduled', 'Scheduled - Offered', 'Service change') "
						+ "GROUP BY date , `Period` , `RowName`) t "
						+ "GROUP BY t.date , t.Period "
						+ "ORDER BY t.date , t.Period";
				query = "(SELECT "
						+ "t.date, "
						+ "t.Period, "
						+ "t.Budget AS 'Budget', "
						+ "SUM(t.Confirmed) AS 'Confirmed', "
						+ "SUM(t.Scheduled) AS 'Scheduled', "
						+ "SUM(t.Open) AS 'Open' "
						+ "FROM "
						+ "(SELECT "
						+ "date, "
						+ "ColumnName AS 'Period', "
						+ "trim(substring_index(`RowName`,'-',-(1))), "
						+ "budget.`days` AS 'Budget', "
						+ "IF(trim(substring_index(`RowName`,'-',-(1))) in ('Confirmed', 'In Progress', 'Submitted', 'Under Review', 'Under Review - Rejected', 'Support', 'Completed'), SUM(Value), 0) AS 'Confirmed', "
						+ "IF(trim(substring_index(`RowName`,'-',-(1))) like 'Scheduled%', SUM(Value), 0) AS 'Scheduled', "
						+ "IF(trim(substring_index(`RowName`,'-',-(1))) in ('Open', 'Service Change', 'Draft', 'Initiate Service'), SUM(Value), 0) AS 'Open' "
						+ "FROM "
						+ "`sf_report_history` rh "
						+ "left join (select "
						+ "date_format(RefDate, '%Y %m') as 'Period', "
						+ "sum(RefValue) as 'days' "
						+ "from salesforce.sf_data "
						+ "where "
						+ "DataType = 'Audit Days Budget' "
						+ "and RefDate between '2014-07-01' and '2017-06-30' "
						+ "and Region like '%Australia%' "
						+ "and current=1 "
						+ "group by `Period`) budget on rh.`ColumnName` = budget.`Period`"
						+ "WHERE "
						+ "ReportName = 'Audit Days Snapshot' "
						//+ "AND trim(substring_index(`RowName`,'-',-(1))) IN ('Budget' , 'Confirmed', 'Scheduled - Offered', 'Scheduled', 'Open', 'New Business', 'Service change') "
						//+ "and date_format(date, '%w') = 1 "
						+ "and date between '2015-07-01' and now() "
						+ "and ColumnName <= '2017 06' "
						+ "and ColumnName >= '2015 07' "
						+ "and `Region` like 'Australia%' "
						+ "and  cast(`Value` as decimal(10,2)) > 0 and  `Region` not like '%Product%' and  `Region` not like '%Unknown%' and  `RowName` like '%Audit%' and  `RowName` like '%Days%' and  `RowName` not like '%Pending%' "
						+ "GROUP BY date , `Period` , `RowName`) t "
						+ "GROUP BY t.date , t.Period "
						+ "ORDER BY t.date , t.Period);";
				ResultSet rs = db.executeSelect(query, -1);
				boolean first = true;
				String currentDate = "";
				String currentPeriod = "";
				String budget = "";
				HashSet<String> periods = new HashSet<String>();
				while (rs.next()) {
					if (!currentDate.startsWith(rs.getString("date"))) {
						if (!first) {
							json = Utility.removeLastChar(json) + "]]},";
						} else {
							first = false;
						}
						currentDate = rs.getString("date");
						json += json = "{\"date\": \"" + Utility.getShortdatedisplayformat().format(Utility.getMysqlutcdateformat().parse(rs.getString("date"))) + "\", \"data\": [[";
					}
					if (!currentPeriod.startsWith(rs.getString("Period"))) {
						if (!json.endsWith("[")) {
							json = Utility.removeLastChar(json) + "]," + "[";
						}
						json += "\"" + Utility.getSoqldateformat().format(periodFormatter.parse(rs.getString("Period"))) + "\",";
						currentPeriod = rs.getString("Period");
					}
					json += rs.getDouble("Confirmed") + ","+ rs.getDouble("Scheduled") + ","+ rs.getDouble("Open") + ",0,0,0,";
					
					if (!periods.contains(currentPeriod)) {
						periods.add(currentPeriod);
						budget += rs.getString("Budget") + ",";
					}
				}
				json = Utility.removeLastChar(json); 
				json +=  "]]}]";
				json += ", \"budget\":[" + Utility.removeLastChar(budget) + "]}";
				
			} else {
				String query = "SELECT "
						//+ "'MS + Food' AS 'BusinessUnit',"
						+ "date, "
						+ "ColumnName AS 'Period',"
						+ "Sum(Value) AS 'Days' "
						+ "FROM " + db.getDBTableName("sf_report_history") + " "
						+ "WHERE "
						+ "ReportName = 'Planning Days Report' "
						+ "GROUP BY date, `Period` "
						+ "ORDER BY date, `Period`";
				
				ResultSet rs = db.executeSelect(query, -1);
				boolean first = true;
				String currentDate = "";
				json = "[";
				while (rs.next()) {
					if (!currentDate.startsWith(rs.getString("date"))) {
						if (!first) {
							json = Utility.removeLastChar(json) + "]},";
						} else {
							first = false;
						}
						currentDate = rs.getString("date");
						json += json = "{\"date\": \"" + Utility.getShortdatedisplayformat().format(Utility.getMysqlutcdateformat().parse(rs.getString("date"))) + "\", \"data\": [";
					}
					json += "{\"period\": \"" + rs.getString("Period") + "\", \"value\": " + rs.getString("Days") + "},";
				}
				json = Utility.removeLastChar(json) + "]}]";
			}
			out.print(json);
			
			//return null;
		} catch (Exception e) {
			Utility.handleError(gp, e);
		}
	}
}
