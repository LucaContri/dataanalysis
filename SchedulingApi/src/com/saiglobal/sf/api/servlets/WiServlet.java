package com.saiglobal.sf.api.servlets;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.log4j.Logger;

import com.saiglobal.sf.api.data.ApiRequest;
import com.saiglobal.sf.api.data.DbHelper;
import com.saiglobal.sf.api.handlers.HandlerWorkItem;
import com.saiglobal.sf.api.utility.ApiParameters;
import com.saiglobal.sf.api.utility.Utility;
import com.saiglobal.sf.core.utility.GlobalProperties;

public class WiServlet extends HttpServlet {
	
	private static final long serialVersionUID = 1L;
	private static Logger logger = Logger.getLogger(WiServlet.class);
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
		long startTime = System.currentTimeMillis();
		ApiRequest requestToLog = new ApiRequest();
		requestToLog.setRequest(request.getRequestURL()+"?"+ request.getQueryString());
		
		requestToLog.setClient(((request.getHeader("Remote_Addr")==null) || (request.getHeader("Remote_Addr")==""))?request.getHeader("HTTP_X_FORWARDED_FOR"):request.getHeader("Remote_Addr"));
		requestToLog.setOutcome("OK");
		try {
			parameters = request.getParameterMap();
			boolean debug = false; 
			String textSearch = null;
			String workItemId = null;
			int availabilityWindowAfterTarget = 2;
			int availabilityWindowBeforeTarget = 0;
			try {
				if (parameters.get(ApiParameters.name.toString())!=null)
					textSearch = parameters.get(ApiParameters.name.toString())[0];
				if (parameters.get(ApiParameters.id.toString())!=null)
					workItemId = parameters.get(ApiParameters.id.toString())[0];
				if (parameters.get(ApiParameters.debug.toString())!=null)
					debug = Boolean.parseBoolean(parameters.get(ApiParameters.debug.toString())[0]);
				if (parameters.get(ApiParameters.availabilityWindowAfterTarget.toString())!=null)
					availabilityWindowAfterTarget = Integer.parseInt(parameters.get(ApiParameters.availabilityWindowAfterTarget.toString())[0]);
				if (parameters.get(ApiParameters.availabilityWindowBeforeTarget.toString())!=null)
					availabilityWindowBeforeTarget = Integer.parseInt(parameters.get(ApiParameters.availabilityWindowBeforeTarget.toString())[0]);
			} catch (Exception e) {
				// Ignore and carry on.  If they can't spill true or flase ... bad duck
			}
			out.print(HandlerWorkItem.handle(request, response, textSearch, workItemId, db, debug, availabilityWindowBeforeTarget, availabilityWindowAfterTarget));
			requestToLog.setOutcome(String.valueOf(response.getStatus()));
			requestToLog.setTimeMs(System.currentTimeMillis()-startTime);
			db.logRequest(requestToLog);
			//return null;
		} catch (Exception e) {
			com.saiglobal.sf.core.utility.Utility.handleError(gp, e);
		} finally {
			db.closeConnection();
		}		
	  }
}
