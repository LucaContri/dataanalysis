package com.saiglobal.reporting.servlets;

import java.io.IOException;
import java.io.PrintWriter;
//import java.util.Map;


import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.log4j.Logger;

import com.google.gson.Gson;
import com.saiglobal.reporting.model.KPIData;
import com.saiglobal.reporting.model.Report;
import com.saiglobal.reporting.utility.KPICache;
import com.saiglobal.reporting.utility.ReportHandler;
import com.saiglobal.sf.core.data.DbHelper;
import com.saiglobal.sf.core.data.DbHelperConnPool;
import com.saiglobal.sf.core.model.Region;
import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;

public class ReportServlet extends HttpServlet {
	private static final long serialVersionUID = 1L;
	private static Logger logger = Logger.getLogger(ReportServlet.class);
	private static final GlobalProperties gp;
	private static ReportHandler handler;
	
	static {
		// Initialise
		gp = GlobalProperties.getDefaultInstance();
		try {
			handler = new ReportHandler(gp);
		} catch (Exception e) {
			Utility.handleError(gp, e);
		}
	}
		
	@Override
	public void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		Map<String, String[]> parameters;
		PrintWriter out = response.getWriter();
		response.setContentType("text/json");
		
		boolean forceRefresh = false;
		boolean getReportsList = false;
		int reportId = -1;
		String query = null;
		String datasource = null;
		String action = null;
		
		try {
			parameters = request.getParameterMap();			
			
			try {
				// Parse parameters
				if (parameters.containsKey("forceRefresh"))
					forceRefresh = Boolean.parseBoolean(parameters.get("forceRefresh")[0]);
				
				if (parameters.containsKey("getReportsList"))
					getReportsList = Boolean.parseBoolean(parameters.get("getReportsList")[0]);

				if (parameters.containsKey("getReport")) {
					reportId = Integer.parseInt(parameters.get("getReport")[0]);
					action = "preview";
				}
				if (parameters.containsKey("query")) {
					query = parameters.get("query")[0];
				}
				if (parameters.containsKey("datasource")) {
					datasource = parameters.get("datasource")[0];
				}
				if (parameters.containsKey("action")) {
					action = parameters.get("action")[0];
				}
				if (parameters.containsKey("downloadReport")) {
					reportId = Integer.parseInt(parameters.get("downloadReport")[0]);
					action = "download";
				}
			} catch (Exception e) {
				//Ignore and use default
			}
			if (forceRefresh)
				handler = new ReportHandler(gp);
			
			Gson gson = new Gson();
			if (getReportsList) {
				out.print(gson.toJson(handler.getReportsList()));
			} else {
				if ((query != null) && (datasource != null)) {
					if (action!=null && action.equalsIgnoreCase("download") ) {
						response.setContentType("text/csv");
						response.setHeader("Content-Disposition", "attachment; fileName=report.csv");
						out.print(handler.downloadReport(query, datasource));
					} else {
						out.print(gson.toJson(handler.query(query, datasource)));
					}
				} else {
					if (action.equalsIgnoreCase("preview")) {
						out.print(gson.toJson(handler.getReportPreview(reportId)));
					} else if (action != null && action.equalsIgnoreCase("download")) {
						Report report = handler.getReportById(reportId);
						response.setContentType("text/csv");
						response.setHeader("Content-Disposition", "attachment; fileName=" + report.getName() + ".csv");
						out.print(handler.downloadReport(reportId));
					}
				}
			}
			
		} catch (Exception e) {
			Utility.handleError(gp, e);
		} finally {
			Utility.logAllProcessingTime();
			Utility.resetAllTimeCounter();
		}		
	}
}
