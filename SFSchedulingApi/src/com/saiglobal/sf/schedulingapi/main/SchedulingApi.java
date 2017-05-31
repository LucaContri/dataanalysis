package com.saiglobal.sf.schedulingapi.main;

import static spark.Spark.*;

import java.io.UnsupportedEncodingException;
import java.net.URLDecoder;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

import org.apache.log4j.Logger;

import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.schedulingapi.data.DbHelper;
import com.saiglobal.sf.schedulingapi.utility.Utility;

import spark.*;

public class SchedulingApi {
	
	private static Logger logger = Logger.getLogger(SchedulingApi.class);
	private static DbHelper db;
	private static final GlobalProperties gp;
	
	static {
	// Initialise
		gp = GlobalProperties.getDefaultInstance();
		try {
			db = new DbHelper(gp);
		} catch (Exception e) {
			logger.error(e);
			Utility.handleError(gp, e);
		}
	}
	
	public static void main(String[] args) {
		
		// set port
		setPort(gp.getSchedulingApiPort());
		
		// Static files
		externalStaticFileLocation("C:\\SAI\\www");
		
		get(new Route("/wi") {
			@Override
			public Object handle(Request request, Response response) {
				Map<String, String[]> parameters;
				try {
					parameters = request.raw().getParameterMap();
					boolean debug = false; 
					String workItemName = null;
					try {
						workItemName = parameters.get(ApiParameters.name.toString())[0];
						debug = Boolean.parseBoolean(parameters.get(ApiParameters.debug.toString())[0]);
					} catch (Exception e) {
						// Ignore and carry on.  If they can't spill true or flase ... bad duck
					}
					return HandlerWorkItem.handle(request, response, workItemName, db, debug);
					
					//return null;
				} catch (Exception e) {
					e.printStackTrace();
					return null;
				}
			}
		});
		
		get(new Route("/allocation") {
			@Override
			public Object handle(Request request, Response response) {
				Map<String, String[]> parameters;
				try {
					parameters = request.raw().getParameterMap();
					Date from = new Date();
					Date to = new Date();
					String businessUnit = parameters.get("businessUnits")==null?null:parameters.get("businessUnits")[0];
					try {
						from = Utility.getActivitydateformatter().parse(parameters.get("from")[0]);
						to = Utility.getActivitydateformatter().parse(parameters.get("to")[0]);
					} catch (Exception e) {
						return null;
					}
					return HandlerAllocation.handle(request, response, db, from, to, businessUnit);
					
					//return null;
				} catch (Exception e) {
					e.printStackTrace();
					return null;
				}
			}
		});
	}
	
	public static HashMap<String, String> parseParameters(String parametersString) throws UnsupportedEncodingException {
	    HashMap<String, String> query_pairs = new HashMap<String, String>();
	    String[] pairs = parametersString.split("&");
	    for (String pair : pairs) {
	        int idx = pair.indexOf("=");
	        query_pairs.put(URLDecoder.decode(pair.substring(0, idx), "UTF-8"), URLDecoder.decode(pair.substring(idx + 1), "UTF-8"));
	    }
	    return query_pairs;
	}
}
