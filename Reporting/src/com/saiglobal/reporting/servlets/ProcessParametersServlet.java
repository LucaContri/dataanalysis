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
import com.saiglobal.reporting.utility.ProcessParameterCache;
import com.saiglobal.sf.core.data.DbHelperConnPool;
import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;
import com.saiglobal.sf.downloader.sf.SfHelper;

public class ProcessParametersServlet extends HttpServlet {
	
	private static final long serialVersionUID = 1L;
	private static Logger logger = Logger.getLogger(ProcessParametersServlet.class);
	private static DbHelperConnPool db;
	private static SfHelper sf;
	private static final GlobalProperties gp;
	private static ProcessParameterCache parametersCache;
	static {
	// Initialise
		gp = GlobalProperties.getDefaultInstance();
		try {
			logger.info("static init");
			db = new DbHelperConnPool(gp, "jdbc/compass");
			sf = new SfHelper(gp);
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
		parametersCache = ProcessParameterCache.getInstance(db, sf);
		try {
			out.print(gson.toJson(parametersCache.getParameters(q)));
		} catch (Exception e) {
			Utility.handleError(gp, e);
		} finally {
			db.closeConnection();
			Utility.logAllProcessingTime();
			Utility.resetAllTimeCounter();
		}
	  }
}
