package com.saiglobal.sf.api.servlets;

import java.io.IOException;
import java.io.PrintWriter;
//import java.util.ArrayList;
//import java.util.List;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.log4j.Logger;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.saiglobal.sf.api.data.DbHelper;
import com.saiglobal.sf.api.handlers.HandlerWISearchByLocation;
//import com.saiglobal.sf.api.model.SimpleParameter;
import com.saiglobal.sf.api.utility.ParametersCache;
import com.saiglobal.sf.api.utility.Utility;
//import com.saiglobal.sf.core.model.SfBusinessUnit;
import com.saiglobal.sf.core.utility.GlobalProperties;

public class WISearchByLocationServlet extends HttpServlet {
	
	private static final long serialVersionUID = 1L;
	private static Logger logger = Logger.getLogger(WISearchServlet.class);
	private static DbHelper db;
	private static final GlobalProperties gp;
	private static final int DEFAULT_MAX_DISTANCE = 10;
	private static final int DEFAULT_NO_MONTHS = 1;
	//private static List<SimpleParameter> revenueOwerships = new ArrayList<SimpleParameter>();
	//private static List<String> aus_food = new ArrayList<String>();
	//private static List<String> aus_ms = new ArrayList<String>();
	
	static {
	// Initialise
		gp = GlobalProperties.getDefaultInstance();
		try {
			logger.info("static init");
			db = new DbHelper(gp);
			ParametersCache.getInstance(db);
			/*
			for (SfBusinessUnit ro: SfBusinessUnit.values()) {
				revenueOwerships.add(new SimpleParameter(ro.getName(), ro.getName()));
			}
			aus_food.add(SfBusinessUnit.AUSFoodNSWACT.getName());
			aus_food.add(SfBusinessUnit.AUSFoodQLD.getName());
			aus_food.add(SfBusinessUnit.AUSFoodROW.getName());
			aus_food.add(SfBusinessUnit.AUSFoodSANT.getName());
			aus_food.add(SfBusinessUnit.AUSFoodVICTAS.getName());
			aus_food.add(SfBusinessUnit.AUSFoodWA.getName());
			aus_ms.add(SfBusinessUnit.AUSDirectNSWACT.getName());
			aus_ms.add(SfBusinessUnit.AUSDirectQLD.getName());
			aus_ms.add(SfBusinessUnit.AUSDirectROW.getName());
			aus_ms.add(SfBusinessUnit.AUSDirectSANT.getName());
			aus_ms.add(SfBusinessUnit.AUSDirectVICTAS.getName());
			aus_ms.add(SfBusinessUnit.AUSDirectWA.getName());
			aus_ms.add(SfBusinessUnit.AUSGlobalNSWACT.getName());
			aus_ms.add(SfBusinessUnit.AUSGlobalQLD.getName());
			aus_ms.add(SfBusinessUnit.AUSGlobalROW.getName());
			aus_ms.add(SfBusinessUnit.AUSGlobalSANT.getName());
			aus_ms.add(SfBusinessUnit.AUSGlobalVICTAS.getName());
			aus_ms.add(SfBusinessUnit.AUSGlobalWA.getName());
			aus_ms.add(SfBusinessUnit.AUSManagedNSWACT.getName());
			aus_ms.add(SfBusinessUnit.AUSManagedQLD.getName());
			aus_ms.add(SfBusinessUnit.AUSManagedROW.getName());
			aus_ms.add(SfBusinessUnit.AUSManagedSANT.getName());
			aus_ms.add(SfBusinessUnit.AUSManagedVICTAS.getName());
			aus_ms.add(SfBusinessUnit.AUSManagedWA.getName());
			aus_ms.add(SfBusinessUnit.AUSManagedPlusNSWACT.getName());
			aus_ms.add(SfBusinessUnit.AUSManagedPlusQLD.getName());
			aus_ms.add(SfBusinessUnit.AUSManagedPlusROW.getName());
			aus_ms.add(SfBusinessUnit.AUSManagedPlusSANT.getName());
			aus_ms.add(SfBusinessUnit.AUSManagedPlusVICTAS.getName());
			aus_ms.add(SfBusinessUnit.AUSManagedPlusWA.getName());
			*/
		} catch (Exception e) {
			logger.error(e);
			Utility.handleError(gp, e);
		}
	}
		
	@Override
	  public void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		Map<String, String[]> parameters;
		PrintWriter out = response.getWriter();
		String locationId = null;
		//List<String> ro = new ArrayList<String>();
		int noOfMonths = -1;
		int maxDistance = -1;
		
		// Format as Json
		Gson gson = new GsonBuilder().setDateFormat("yyyy-MM-dd HH:mm").create();
					
		try {
			parameters = request.getParameterMap();
			
			if (parameters.containsKey("q") && parameters.get("q")[0] != "") {
				String[] ids = parameters.get("q")[0].split(",");
				for (String id: ids) {
					if (id.startsWith("P")) {
						try {
							int tmp = Integer.parseInt(id.replace("P", ""));
							noOfMonths = Math.max(tmp, noOfMonths);
							continue;
						} catch (NumberFormatException nfe) {
							// Ignore
						}
					}
					if (id.startsWith("R")) {
						try {
							int tmp = Integer.parseInt(id.replace("R", ""));
							maxDistance = Math.max(tmp, maxDistance);
							continue;
						} catch (NumberFormatException nfe) {
							// Ignore
						}
					}
					/*
					boolean isRo = false;
					
					// Check if it is a Revenue Ownership
					for (SimpleParameter aRo : revenueOwerships) {
						if (aRo.getId().contains(id)) {
							ro.add(aRo.getName());
							isRo = true;
							break;
						}
					}
					
					if (!isRo) {
						if (id.equalsIgnoreCase("AUS-MS-All"))
							ro.addAll(aus_ms);
						else if (id.equalsIgnoreCase("AUS-Food-All"))
							ro.addAll(aus_food);
						else
							locationId = id;
					}
					*/
					locationId = id;
				}
			} else {
				out.print(gson.toJson(new Object[0]));
				return;
			}
			
			if (locationId == null) {
				out.print(gson.toJson(new Object[0]));
				return;
			}
			if (noOfMonths<0)
				noOfMonths = DEFAULT_NO_MONTHS;
			if (maxDistance<0)
				maxDistance = DEFAULT_MAX_DISTANCE;
			//out.print(gson.toJson(HandlerWISearchByLocation.handle(request, response, locationId, ro.toArray(new String[ro.size()]), maxDistance, noOfMonths, db, false)));
			out.print(gson.toJson(HandlerWISearchByLocation.handle(request, response, locationId, maxDistance, noOfMonths, db, false)));
						
		} catch (Exception e) {
			Utility.handleError(gp, e);
		} finally {
			db.closeConnection();
			Utility.logAllProcessingTime();
			Utility.resetAllTimeCounter();
		}
	  }
}
