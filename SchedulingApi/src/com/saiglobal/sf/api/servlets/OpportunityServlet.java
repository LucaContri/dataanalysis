package com.saiglobal.sf.api.servlets;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.log4j.Logger;

import com.saiglobal.sf.api.data.DbHelper;
import com.saiglobal.sf.api.handlers.HandlerOpportunity;
import com.saiglobal.sf.api.utility.ApiParameters;
import com.saiglobal.sf.api.utility.Utility;
import com.saiglobal.sf.core.utility.GlobalProperties;


public class OpportunityServlet extends HttpServlet {
	
	private static final long serialVersionUID = 1L;
	private static Logger logger = Logger.getLogger(OpportunityServlet.class);
	private static DbHelper db;
	private static final GlobalProperties gp;
	
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
		
	@Override
	  public void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		Map<String, String[]> parameters;
		PrintWriter out = response.getWriter();
		try {
			parameters = request.getParameterMap();
			boolean debug = false; 
			String opportunityName = null;
			String oppLineItemId = null;
			try {
				if (parameters.containsKey(ApiParameters.name.toString()))
					opportunityName = parameters.get(ApiParameters.name.toString())[0];
				if (parameters.containsKey(ApiParameters.id.toString()))
					oppLineItemId = parameters.get(ApiParameters.id.toString())[0];
				if (parameters.containsKey(ApiParameters.debug.toString()))
					debug = Boolean.parseBoolean(parameters.get(ApiParameters.debug.toString())[0]);
			} catch (Exception e) {
				
			}
			out.print(HandlerOpportunity.handle(request, response, oppLineItemId, opportunityName, db, debug));
			
			//return null;
		} catch (Exception e) {
			com.saiglobal.sf.core.utility.Utility.handleError(gp, e);
		} finally {
			db.closeConnection();
		}
		
	  }
}
