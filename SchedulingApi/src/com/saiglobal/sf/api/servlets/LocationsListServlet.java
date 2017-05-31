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
import com.saiglobal.sf.api.utility.LocationCache;
import com.saiglobal.sf.api.utility.Utility;
import com.saiglobal.sf.core.utility.GlobalProperties;

public class LocationsListServlet extends HttpServlet {
	
	private static final long serialVersionUID = 1L;
	private static Logger logger = Logger.getLogger(LocationsListServlet.class);
	private static DbHelper db;
	private static final GlobalProperties gp;
	private static LocationCache locationCache;
	//private static List<SimpleParameter> revenueOwerships = new ArrayList<SimpleParameter>();
	private static List<SimpleParameter> timeframe = new ArrayList<SimpleParameter>();
	private static List<SimpleParameter> radii = new ArrayList<SimpleParameter>();
	
	static {
	// Initialise
		gp = GlobalProperties.getDefaultInstance();
		try {
			logger.info("static init");
			db = new DbHelper(gp);
			locationCache = LocationCache.getInstance(db);
			
			timeframe.add(new SimpleParameter("Current month", "P0"));
			timeframe.add(new SimpleParameter("Within 2 months", "P1"));
			timeframe.add(new SimpleParameter("Within 3 months", "P2"));
			timeframe.add(new SimpleParameter("Within 4 months", "P3"));
			timeframe.add(new SimpleParameter("Within 5 months", "P4"));
			timeframe.add(new SimpleParameter("Within 6 months", "P5"));
			timeframe.add(new SimpleParameter("Within 7 months", "P6"));
			timeframe.add(new SimpleParameter("Within 8 months", "P7"));
			timeframe.add(new SimpleParameter("Within 9 months", "P8"));
			timeframe.add(new SimpleParameter("Within 10 months", "P9"));
			timeframe.add(new SimpleParameter("Within 11 months", "P10"));
			timeframe.add(new SimpleParameter("Within 12 months", "P11"));
			
			radii.add(new SimpleParameter("Within 10 Km", "R10"));
			radii.add(new SimpleParameter("Within 50 Km", "R50"));
			radii.add(new SimpleParameter("Within 100 Km", "R100"));
			
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
		/*
		for (SimpleParameter ro: revenueOwerships) {
			if (ro.getName().toLowerCase().contains(q))
				result.add(ro);
		}
		*/
		for (SimpleParameter nm: timeframe) {
			if (nm.getName().toLowerCase().contains(q))
				result.add(nm);
		}
		
		for (SimpleParameter md: radii) {
			if (md.getName().toLowerCase().contains(q))
				result.add(md);
		}
		
		try {
			result.addAll(locationCache.getLocationsParameters(q));
			out.print(gson.toJson(result));
		} catch (Exception e) {
			com.saiglobal.sf.core.utility.Utility.handleError(gp, e);
		} finally {
			db.closeConnection();
		}
	  }
}
