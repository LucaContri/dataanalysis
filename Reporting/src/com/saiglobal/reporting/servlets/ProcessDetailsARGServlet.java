package com.saiglobal.reporting.servlets;

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
import com.google.gson.GsonBuilder;
import com.saiglobal.reporting.model.Process;
import com.saiglobal.reporting.model.ProcessDetails;
import com.saiglobal.reporting.model.SimpleParameter;
import com.saiglobal.reporting.utility.ProcessDetailsCacheARG;
import com.saiglobal.reporting.utility.ProcessDetailsCacheARGv2;
import com.saiglobal.reporting.utility.ProcessParameterCache;
import com.saiglobal.sf.core.data.DbHelperConnPool;
import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;
import com.saiglobal.sf.downloader.sf.SfHelper;

public class ProcessDetailsARGServlet extends HttpServlet {
	private static final long serialVersionUID = 1L;
	private static Logger logger = Logger.getLogger(ProcessDetailsARGServlet.class);
	private static DbHelperConnPool db;
	private static SfHelper sf;
	private static final GlobalProperties gp;
	private static ProcessDetailsCacheARG argProcessCache;
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
	
	public void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		Map<String, String[]> parameters;
		PrintWriter out = response.getWriter();
		Process process = Process.ARG;
		boolean forceRefresh = false;
		List<String> resources = new ArrayList<String>();
		List<String> clientOwnerships = new ArrayList<String>();
		List<String> standards = new ArrayList<String>();
		List<String> tags = new ArrayList<String>();
		
		try {
			parameters = request.getParameterMap();
			try {
				if (parameters.containsKey("forceRefresh") && parameters.get("forceRefresh")[0] != "")
					forceRefresh = Boolean.valueOf(parameters.get("forceRefresh")[0]);
				
				if (parameters.containsKey("process") && parameters.get("process")[0] != "")
					process = Process.valueOf(parameters.get("process")[0]);
				
				if (parameters.containsKey("q") && (parameters.get("q")[0] != "")) {
					parametersCache = ProcessParameterCache.getInstance(db, sf);
					
					String[] qs = parameters.get("q")[0].split(",");
					logger.info(parameters.get("q")[0]);
					for (String q : qs) {
						if (parametersCache.isClientOwnership(q)) {
							clientOwnerships.add(q);
							continue;
						}
						if (parametersCache.isTag(q)) {
							tags.add(q);
							continue;
						}
						SimpleParameter resource = parametersCache.getResourceById(q);
						if (resource != null) {
							resources.add(resource.getName());
							continue;
						}
						SimpleParameter standard = parametersCache.getStandardById(q);
						if (standard != null) {
							standards.add(standard.getName());
							continue;
						}
					}
				}
			} catch (Exception e) {
			}
			
			argProcessCache = ProcessDetailsCacheARG.getInstance(db);
			
			ProcessDetails data = argProcessCache.getProcessDetails(process, standards, clientOwnerships, resources, tags, forceRefresh);
			
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
