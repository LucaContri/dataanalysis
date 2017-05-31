package com.saiglobal.reporting.servlets;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.ResultSet;
import java.text.SimpleDateFormat;
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
public class CopyOfAuditDaysSumamryServlet extends HttpServlet {
	private static Logger logger = Logger.getLogger(CopyOfAuditDaysSumamryServlet.class);
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
				String[] statuses = new String[]{"Cancelled","UnderReview","Completed", "Support", "InitiateService", "Submitted", "InProgress", "Confirmed", "Scheduled - Offered", "Scheduled", "Open", "Draft", "Service change"};
				String statusWhereClause = "RowName IN (";
				for (String status : statuses) {
					statusWhereClause+="'" + status + "',";
				}
				statusWhereClause = Utility.removeLastChar(statusWhereClause) + ") ";
				String[] colors = new String[]{"Red","DarkGreen","Green","MediumSpringGreen","Blue","LightGreen","LawnGreen","Lime","LimeGreen", "Chartreuse", "GreenYellow", "LightSteelBlue", "Gold", "Steelblue"};
				json = "{"
						+ "\"header\": {\"x\":\"Period\", \"y\": ["; 
				for (String status : statuses) {
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
						+ "sum(t.Confirmed) as 'Confirmed',"
						//+ "sum(t.NewBusiness) as 'NewBusiness',"
						+ "sum(t.Submitted) as 'Submitted',"
						+ "sum(t.Completed) as 'Completed',"
						+ "sum(t.Cancelled) as 'Cancelled',"
						+ "sum(t.Draft) as 'Draft',"
						+ "sum(t.InProgress) as 'InProgress',"
						+ "sum(t.InitiateService) as 'InitiateService',"
						+ "sum(t.Support) as 'Support',"
						+ "sum(t.UnderReview) as 'UnderReview',"
						+ "sum(t.Open) as 'Open',"
						+ "sum(t.Scheduled) as 'Scheduled',"
						+ "sum(t.ScheduledOffered) as 'ScheduledOffered',"
						+ "sum(t.ServiceChange) as 'ServiceChange' "
						+ "from "
						+ "(SELECT "
						+ "date,"
						+ "ColumnName AS 'Period',"
						+ "RowName,"
						+ "if(RowName = 'Confirmed', Sum(Value), 0) AS 'Confirmed',"
						+ "if(RowName = 'Draft', Sum(Value), 0) AS 'Draft',"
						+ "if(RowName = 'Completed', Sum(Value), 0) AS 'Completed',"
						+ "if(RowName = 'Cancelled', Sum(Value), 0) AS 'Cancelled',"
						+ "if(RowName = 'In Progress', Sum(Value), 0) AS 'InProgress',"
						+ "if(RowName = 'Initiate Service', Sum(Value), 0) AS 'InitiateService',"
						+ "if(RowName = 'Submitted', Sum(Value), 0) AS 'Submitted',"
						+ "if(RowName = 'Support', Sum(Value), 0) AS 'Support',"
						+ "if(RowName = 'Under Review', Sum(Value), 0) AS 'UnderReview',"
						//+ "if(RowName = 'New Business', Sum(Value), 0) AS 'NewBusiness',"
						+ "if(RowName = 'Open', Sum(Value), 0) AS 'Open',"
						+ "if(RowName = 'Scheduled', Sum(Value), 0) AS 'Scheduled',"
						+ "if(RowName = 'Scheduled - Offered', Sum(Value), 0) AS 'ScheduledOffered',"
						+ "if(RowName = 'Service change', Sum(Value), 0) AS 'ServiceChange' "
						+ "FROM `sf_report_history` "
						+ "WHERE "
						+ "ReportName = 'WorkItemsStatusHistory' "
						//+ "AND " + statusWhereClause //RowName IN ('Confirmed' , 'New Business', 'Open', 'Scheduled', 'Scheduled - Offered', 'Service change') "
						+ "and ColumnName >= '2013 07' and ColumnName <= '2014 06' "
						+ "GROUP BY date , `Period` , `RowName`) t "
						+ "GROUP BY t.date , t.Period "
						+ "ORDER BY t.date , t.Period";
				ResultSet rs = db.executeSelect(query, -1);
				boolean first = true;
				String currentDate = "";
				String currentPeriod = "";
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
					json += rs.getDouble("Cancelled") + "," + rs.getDouble("UnderReview") + "," + rs.getDouble("Completed") + "," + rs.getDouble("Support") + "," + rs.getDouble("InitiateService") + "," + rs.getDouble("Submitted") + "," + rs.getDouble("InProgress") + "," + rs.getDouble("Confirmed") + "," + rs.getDouble("ScheduledOffered") + ","+ rs.getDouble("Scheduled") + ","+ rs.getDouble("Open") + ","+ rs.getDouble("Draft") + "," + rs.getDouble("ServiceChange") + ",";
				}
				json = Utility.removeLastChar(json) + "]]}]}";
				
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
