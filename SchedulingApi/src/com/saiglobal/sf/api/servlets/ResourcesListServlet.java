package com.saiglobal.sf.api.servlets;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.log4j.Logger;

import com.google.gson.Gson;
import com.saiglobal.sf.api.data.DbHelper;
import com.saiglobal.sf.api.model.SimpleParameter;
import com.saiglobal.sf.api.utility.ResourceCache;
import com.saiglobal.sf.api.utility.Utility;
import com.saiglobal.sf.core.model.CompassRevenueOwnership;
import com.saiglobal.sf.core.utility.GlobalProperties;

public class ResourcesListServlet extends HttpServlet {
	
	private static final long serialVersionUID = 1L;
	private static Logger logger = Logger.getLogger(ResourcesListServlet.class);
	private static DbHelper db;
	private static final GlobalProperties gp;
	private static ResourceCache resourceCache;
	private static List<SimpleParameter> revenueOwerships = new ArrayList<SimpleParameter>();
	private static List<SimpleParameter> timeframe = new ArrayList<SimpleParameter>();
	
	static {
	// Initialise
		gp = GlobalProperties.getDefaultInstance();
		try {
			logger.info("static init");
			db = new DbHelper(gp);
			resourceCache = ResourceCache.getInstance(db);
			for (CompassRevenueOwnership ro: CompassRevenueOwnership.values()) {
				revenueOwerships.add(new SimpleParameter(ro.getName(), ro.getName()));
			}
			// Add custom
			revenueOwerships.add(new SimpleParameter("AUS-Food-All", "AUS-Food-All"));
			revenueOwerships.add(new SimpleParameter("AUS-MS-All", "AUS-MS-All"));
			
			timeframe.add(new SimpleParameter("Current month", "0"));
			timeframe.add(new SimpleParameter("Within 2 months", "1"));
			timeframe.add(new SimpleParameter("Within 3 months", "2"));
			timeframe.add(new SimpleParameter("Within 4 months", "3"));
			timeframe.add(new SimpleParameter("Within 5 months", "4"));
			timeframe.add(new SimpleParameter("Within 6 months", "5"));
			timeframe.add(new SimpleParameter("Within 7 months", "6"));
			timeframe.add(new SimpleParameter("Within 8 months", "7"));
			timeframe.add(new SimpleParameter("Within 9 months", "8"));
			timeframe.add(new SimpleParameter("Within 10 months", "9"));
			timeframe.add(new SimpleParameter("Within 11 months", "10"));
			timeframe.add(new SimpleParameter("Within 12 months", "11"));
			
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
		Gson gson = new Gson();
		response.setContentType("text/html");
		
		try {
			if (parameters.get("q")!=null) {
				q = parameters.get("q")[0].toLowerCase();
			}
		} catch (Exception e) {
			// Ignore and carry on.
		}
		
		List<SimpleParameter> result = new ArrayList<SimpleParameter>();
		for (SimpleParameter ro: revenueOwerships) {
			if (ro.getName().toLowerCase().contains(q))
				result.add(ro);
		}
		for (SimpleParameter nm: timeframe) {
			if (nm.getName().toLowerCase().contains(q))
				result.add(nm);
		}
		
		try {
			result.addAll(resourceCache.getResourcesParameters(q));
			out.print(gson.toJson(result));
		} catch (Exception e) {
			com.saiglobal.sf.core.utility.Utility.handleError(gp, e);
		} finally {
			db.closeConnection();
		}
	  }
}
