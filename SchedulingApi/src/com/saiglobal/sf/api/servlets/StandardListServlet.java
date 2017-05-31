package com.saiglobal.sf.api.servlets;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.log4j.Logger;

import com.google.gson.Gson;
import com.saiglobal.sf.api.data.DbHelper;
import com.saiglobal.sf.api.utility.CapabilityCache;
import com.saiglobal.sf.api.utility.Utility;
import com.saiglobal.sf.core.utility.GlobalProperties;

public class StandardListServlet extends HttpServlet {
	
	private static final long serialVersionUID = 1L;
	private static Logger logger = Logger.getLogger(StandardListServlet.class);
	private static DbHelper db;
	private static final GlobalProperties gp;
	private static CapabilityCache capabilityCache;
	static {
	// Initialise
		gp = GlobalProperties.getDefaultInstance();
		try {
			logger.info("static init");
			db = new DbHelper(gp);
			capabilityCache = CapabilityCache.getInstance(db);
		} catch (Exception e) {
			logger.error(e);
			Utility.handleError(gp, e);
		}
	}
		
	@Override
	  public void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		PrintWriter out = response.getWriter();
		Map<String, String[]> parameters = request.getParameterMap();
		String q = "";
		try {
			if (parameters.get("q")!=null) {
				q = parameters.get("q")[0];
			}
		} catch (Exception e) {
			// Ignore and carry on.
		}
		
		Gson gson = new Gson();
		response.setContentType("text/html");
		try {
			out.print(gson.toJson(capabilityCache.getStandards(q)));
		} catch (Exception e) {
			com.saiglobal.sf.core.utility.Utility.handleError(gp, e);
		} finally {
			db.closeConnection();
		}
	  }
}
