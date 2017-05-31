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
import com.saiglobal.reporting.utility.KPICache;
import com.saiglobal.sf.core.data.DbHelper;
import com.saiglobal.sf.core.data.DbHelperConnPool;
import com.saiglobal.sf.core.model.Region;
import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;

public class KPIServlet extends HttpServlet {
	private static final long serialVersionUID = 1L;
	private static Logger logger = Logger.getLogger(KPIServlet.class);
	private static DbHelper certification_db;
	private static DbHelper tis_db;
	private static final GlobalProperties certification_gp;
	//private static final GlobalProperties tis_gp;
	private static KPICache kpiCache;

	static {
		// Initialise
		certification_gp = GlobalProperties.getDefaultInstance();
		//tis_gp = Utility.getProperties("C:\\SAI\\Properties\\global.config.training.properties");
		
		try {
			logger.info("static init");
			certification_db = new DbHelperConnPool(certification_gp, "jdbc/compass");
			tis_db = new DbHelperConnPool(certification_gp, "jdbc/training");
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
		
		try {
			parameters = request.getParameterMap();			
			
			try {
				// Parse parameters
				if (parameters.containsKey("forceRefresh"))
					forceRefresh = Boolean.parseBoolean(parameters.get("forceRefresh")[0]);
				if (parameters.containsKey("region"))
					region = Region.valueOf(parameters.get("region")[0]);
			} catch (Exception e) {
				//Ignore and use default
			}
			kpiCache = KPICache.getInstance(certification_db, tis_db, region);
			KPIData data = kpiCache.getAllDataArray(forceRefresh);
			
			// Format as Json
			Gson gson = new Gson();
			out.print(gson.toJson(data));
			
		} catch (Exception e) {
			Utility.handleError(certification_gp, e);
		} finally {
			certification_db.closeConnection();
			tis_db.closeConnection();
			Utility.logAllProcessingTime();
			Utility.resetAllTimeCounter();
		}		
	}
}
