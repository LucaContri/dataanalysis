package com.saiglobal.reporting.servlets;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.log4j.Logger;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.saiglobal.reporting.model.AllocatorOutputDetails;
import com.saiglobal.reporting.utility.AllocatorOutputCache;
import com.saiglobal.sf.core.data.DbHelperConnPool;
import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;

public class AllocatorOutputServlet extends HttpServlet {
	private static final long serialVersionUID = 1L;
	private static Logger logger = Logger.getLogger(AllocatorOutputServlet.class);
	private static DbHelperConnPool db;
	private static final GlobalProperties gp;
	private static AllocatorOutputCache cache;
	
	static {
	// Initialise
		gp = GlobalProperties.getDefaultInstance();
		try {
			logger.info("static init");
			db = new DbHelperConnPool(gp, "jdbc/compass");
		} catch (Exception e) {
			logger.error(e);
			Utility.handleError(gp, e);
		}
	}
	
	public void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		Map<String, String[]> parameters;
		PrintWriter out = response.getWriter();
		boolean forceRefresh = false;
		String batchId = null;
		int pageNo = 0;
		int pageSize = 100;
		
		try {
			parameters = request.getParameterMap();
			try {
				if (parameters.containsKey("forceRefresh") && parameters.get("forceRefresh")[0] != "")
					forceRefresh = Boolean.valueOf(parameters.get("forceRefresh")[0]);
				if (parameters.containsKey("batchId") && parameters.get("batchId")[0] != "")
					batchId = parameters.get("batchId")[0];
				if (parameters.containsKey("pageNo") && parameters.get("pageNo")[0] != "")
					pageNo = Integer.parseInt(parameters.get("pageNo")[0]);
				if (parameters.containsKey("pageSize") && parameters.get("pageSize")[0] != "")
					pageSize = Integer.parseInt(parameters.get("pageSize")[0]);
			} catch (Exception e) {
			}
			
			cache = AllocatorOutputCache.getInstance(db, batchId);
			
			AllocatorOutputDetails data = cache.getAllocatorOutputDetails(forceRefresh, pageNo, pageSize);
			
			// Format as Json
			Gson gson = new GsonBuilder().setDateFormat("yyyy-MM-dd HH:mm").create();
			out.print(gson.toJson(data));
						
		} catch (Exception e) {
			Utility.handleError(gp, e);
		} finally {
			db.closeConnection();
			Utility.logAllProcessingTime();
			Utility.resetAllTimeCounter();
		}
	}
}
