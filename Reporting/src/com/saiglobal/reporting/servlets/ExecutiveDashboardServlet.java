package com.saiglobal.reporting.servlets;

import java.io.IOException;
import java.io.PrintWriter;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.List;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.log4j.Logger;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.saiglobal.reporting.model.ErrorType;
import com.saiglobal.reporting.model.ExecutiveDashboardRequestType;
import com.saiglobal.reporting.model.MetricFunctionType;
import com.saiglobal.reporting.utility.ExecutiveDashboardHandler;
import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;

public class ExecutiveDashboardServlet extends HttpServlet {
	private static final long serialVersionUID = 1L;
	private static Logger logger = Logger.getLogger(ExecutiveDashboardServlet.class);
	private static final GlobalProperties gp;
	private static ExecutiveDashboardHandler handler;
	private static final SimpleDateFormat dateFormat = new SimpleDateFormat("dd/MM/yyyy");
	
	static {
		// Initialise
		gp = GlobalProperties.getDefaultInstance();
		
		try {
			logger.debug("static init");
			handler = new ExecutiveDashboardHandler(gp);
		} catch (Exception e) {
			logger.error(e);
			Utility.handleError(gp, e);
		}
	}
		
	@Override
	public void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		Map<String, String[]> parameters;
		PrintWriter out = response.getWriter();
		response.setContentType("text/json");
		boolean forceRefresh = false;
		String queryMetrics = null;
		Calendar from = Calendar.getInstance();
		Calendar to = Calendar.getInstance();
		MetricFunctionType function = MetricFunctionType.NOT_DEFINED;
		ExecutiveDashboardRequestType requestType = ExecutiveDashboardRequestType.NOT_DEFINED;
		List<Integer> metricsIds = null;
		
		
		try {
			parameters = request.getParameterMap();			
			
			try {
				if (parameters.containsKey("forceRefresh"))
					forceRefresh = Boolean.parseBoolean(parameters.get("forceRefresh")[0]);
				
				if (parameters.containsKey("queryMetrics"))
					queryMetrics = parameters.get("queryMetrics")[0];

				if (parameters.containsKey("request"))
					try {
						requestType = ExecutiveDashboardRequestType.valueOf(parameters.get("request")[0]);
					} catch (Exception e) {
						// Ignore
					}
				
				if (parameters.containsKey("function")) {
					try {
						function = MetricFunctionType.valueOf(parameters.get("function")[0]);
					} catch (Exception e) {
						// Ignore. Use default
					}
				}
				
				if (parameters.containsKey("metricsIds")) {
					try {
						String[] metricsIdsString = parameters.get("metricsIds")[0].split(",");
						metricsIds = new ArrayList<Integer>(); 
						for (String metricIdString : metricsIdsString) {
							metricsIds.add(Integer.parseInt(metricIdString));
						}
					} catch (Exception e) {
						// Ignore.  Use default
					}
				}
				
				if (parameters.containsKey("fromDate")) {
					try {
						Date fromDate = dateFormat.parse(parameters.get("fromDate")[0]);
						from.setTime(fromDate);
						logger.info("fromDate: " + Utility.getMysqldateformat().format(from.getTime()));
					} catch (Exception e) {
						// Ignore
						e.printStackTrace();
					}
				}
					
				if (parameters.containsKey("toDate")) {
					try {
						Date toDate = dateFormat.parse(parameters.get("toDate")[0]);
						to.setTime(toDate);
						logger.info("toDate param: " + parameters.get("toDate")[0]);
						logger.info("toDate: " + Utility.getMysqldateformat().format(to.getTime()));
					} catch (Exception e) {
						// Ignore
						e.printStackTrace();
					}
				}
			} catch (Exception e) {
				//Ignore and use default
			}
			
			if (forceRefresh) {
				handler = new ExecutiveDashboardHandler(gp);
				out.print("{done}");
				return;
			}
			
			//Gson gson = new Gson();
			Gson gson = new GsonBuilder().setDateFormat("yyyy-MM-dd HH:mm:ss").create();
			String output = null;
			
			switch (requestType) {
				case QUERY_METRICS:
					if (queryMetrics != null) {
						output = gson.toJson(handler.getMatchingMetrics(queryMetrics));
					} else {
						output = ErrorType.MISSING_PARAMETER_METRIC_QUERY.toJson();
					}
					break;
				
				case SUMMARY:
					switch (function) {
						case OPERATIONS:
							output = gson.toJson(handler.getOperationsMetricsDataSummary3(from, to));
							break;
						case NOT_DEFINED:
							output = ErrorType.FUNCTION_NOT_DEFINED.toJson();
							break;
						default:
							output = ErrorType.FUNCTION_NOT_IMPLEMENTED.toJson();
					}
					break;
				
				case DETAILS:
					switch (function) {
						case OPERATIONS:
							output = gson.toJson(handler.getMetricsDataDetails(metricsIds));
							break;
						case NOT_DEFINED:
							output = ErrorType.FUNCTION_NOT_DEFINED.toJson();
							break;
						default:
							output = ErrorType.FUNCTION_NOT_IMPLEMENTED.toJson();
					}
					break;
				case NOT_DEFINED:
					output = ErrorType.REQUEST_NOT_IMPLEMENTED.toJson();
					break;
				default:
					output = ErrorType.REQUEST_NOT_DEFINED.toJson();
			}	
			out.print(output);
			
		} catch (Exception e) {
			Utility.handleError(gp, e);
		} finally {
			handler.closeConnections();
			Utility.logAllProcessingTime();
			Utility.resetAllTimeCounter();
		}		
	}
}
