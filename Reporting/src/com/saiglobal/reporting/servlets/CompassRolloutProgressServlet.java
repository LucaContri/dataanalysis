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
import com.saiglobal.reporting.utility.ActiveSiteCertsCache;
import com.saiglobal.reporting.utility.ActiveSitesCache;
import com.saiglobal.reporting.utility.LoginHistoryCache;
import com.saiglobal.sf.core.data.DbHelperConnPool;
import com.saiglobal.sf.core.model.Region;
import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;

public class CompassRolloutProgressServlet extends HttpServlet {
	private static final long serialVersionUID = 1L;
	private static Logger logger = Logger.getLogger(CompassRolloutProgressServlet.class);
	private static DbHelperConnPool certification_db;
	private static final GlobalProperties certification_gp;

	static {
		// Initialise
		certification_gp = GlobalProperties.getDefaultInstance();
			
		try {
			logger.info("static init");
			certification_db = new DbHelperConnPool(certification_gp, "jdbc/compass");
		} catch (Exception e) {
			logger.error(e);
			Utility.handleError(certification_gp, e);
		}
	}
		
	@Override
	public void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		Map<String, String[]> parameters;
		PrintWriter out = response.getWriter();
		response.setContentType("text/text");
		boolean forceRefresh = false;
		Region region = Region.AUSTRALIA_2;
		String function = "activeSites"; 
		
		try {
			parameters = request.getParameterMap();			
			
			try {
				// Parse parameters
				if (parameters.containsKey("forceRefresh"))
					forceRefresh = Boolean.parseBoolean(parameters.get("forceRefresh")[0]);
				if (parameters.containsKey("region"))
					region = Region.valueOf(parameters.get("region")[0]);
				if (parameters.containsKey("function"))
					function = parameters.get("function")[0];
			} catch (Exception e) {
				//Ignore and use default
				logger.error(e);
			}
			
			Gson gson = new Gson();
			if (function.equalsIgnoreCase("activeSites"))
				out.print(gson.toJson(ActiveSitesCache.getInstance(certification_db, region).getActiveSites(forceRefresh)));
			else if (function.equalsIgnoreCase("activeSiteCerts"))
				out.print(gson.toJson(ActiveSiteCertsCache.getInstance(certification_db, region).getActiveSites(forceRefresh)));
			else if (function.equalsIgnoreCase("loginHistory"))
				out.print(gson.toJson(LoginHistoryCache.getInstance(certification_db, region).getActiveSites(forceRefresh)));
		} catch (Exception e) {
			Utility.handleError(certification_gp, e);
		} finally {
			certification_db.closeConnection();
			Utility.logAllProcessingTime();
			Utility.resetAllTimeCounter();
		}		
	}
}
