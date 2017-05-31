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
import com.google.gson.GsonBuilder;
import com.saiglobal.sf.api.data.DbHelper;
import com.saiglobal.sf.api.handlers.HandlerWISearch;
import com.saiglobal.sf.api.model.SimpleParameter;
import com.saiglobal.sf.api.utility.ParametersCache;
import com.saiglobal.sf.api.utility.Utility;
import com.saiglobal.sf.core.model.CompassRevenueOwnership;
import com.saiglobal.sf.core.utility.GlobalProperties;

public class WISearchServlet extends HttpServlet {
	
	private static final long serialVersionUID = 1L;
	private static Logger logger = Logger.getLogger(WISearchServlet.class);
	private static DbHelper db;
	private static final GlobalProperties gp;
	private static List<SimpleParameter> revenueOwerships = new ArrayList<SimpleParameter>();
	private static List<String> aus_food = new ArrayList<String>();
	private static List<String> aus_ms = new ArrayList<String>();
	
	static {
	// Initialise
		gp = GlobalProperties.getDefaultInstance();
		try {
			logger.info("static init");
			db = new DbHelper(gp);
			ParametersCache.getInstance(db);
			for (CompassRevenueOwnership ro: CompassRevenueOwnership.values()) {
				revenueOwerships.add(new SimpleParameter(ro.getName(), ro.getName()));
			}
			aus_food.add(CompassRevenueOwnership.AUSFoodNSWACT.getName());
			aus_food.add(CompassRevenueOwnership.AUSFoodQLD.getName());
			aus_food.add(CompassRevenueOwnership.AUSFoodROW.getName());
			aus_food.add(CompassRevenueOwnership.AUSFoodSANT.getName());
			aus_food.add(CompassRevenueOwnership.AUSFoodVICTAS.getName());
			aus_food.add(CompassRevenueOwnership.AUSFoodWA.getName());
			aus_ms.add(CompassRevenueOwnership.AUSDirectNSWACT.getName());
			aus_ms.add(CompassRevenueOwnership.AUSDirectQLD.getName());
			aus_ms.add(CompassRevenueOwnership.AUSDirectROW.getName());
			aus_ms.add(CompassRevenueOwnership.AUSDirectSANT.getName());
			aus_ms.add(CompassRevenueOwnership.AUSDirectVICTAS.getName());
			aus_ms.add(CompassRevenueOwnership.AUSDirectWA.getName());
			aus_ms.add(CompassRevenueOwnership.AUSGlobalNSWACT.getName());
			aus_ms.add(CompassRevenueOwnership.AUSGlobalQLD.getName());
			aus_ms.add(CompassRevenueOwnership.AUSGlobalROW.getName());
			aus_ms.add(CompassRevenueOwnership.AUSGlobalSANT.getName());
			aus_ms.add(CompassRevenueOwnership.AUSGlobalVICTAS.getName());
			aus_ms.add(CompassRevenueOwnership.AUSGlobalWA.getName());
			aus_ms.add(CompassRevenueOwnership.AUSManagedNSWACT.getName());
			aus_ms.add(CompassRevenueOwnership.AUSManagedQLD.getName());
			aus_ms.add(CompassRevenueOwnership.AUSManagedROW.getName());
			aus_ms.add(CompassRevenueOwnership.AUSManagedSANT.getName());
			aus_ms.add(CompassRevenueOwnership.AUSManagedVICTAS.getName());
			aus_ms.add(CompassRevenueOwnership.AUSManagedWA.getName());
			aus_ms.add(CompassRevenueOwnership.AUSManagedPlusNSWACT.getName());
			aus_ms.add(CompassRevenueOwnership.AUSManagedPlusQLD.getName());
			aus_ms.add(CompassRevenueOwnership.AUSManagedPlusROW.getName());
			aus_ms.add(CompassRevenueOwnership.AUSManagedPlusSANT.getName());
			aus_ms.add(CompassRevenueOwnership.AUSManagedPlusVICTAS.getName());
			aus_ms.add(CompassRevenueOwnership.AUSManagedPlusWA.getName());
		} catch (Exception e) {
			logger.error(e);
			Utility.handleError(gp, e);
		}
	}
		
	@Override
	  public void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		Map<String, String[]> parameters;
		PrintWriter out = response.getWriter();
		List<String> resourceIds = new ArrayList<String>();
		List<String> ro = new ArrayList<String>();
		int noOfMonths = -1;
		
		// Format as Json
		Gson gson = new GsonBuilder().setDateFormat("yyyy-MM-dd HH:mm").create();
					
		try {
			parameters = request.getParameterMap();
			
			if (parameters.containsKey("q") && parameters.get("q")[0] != "") {
				String[] ids = parameters.get("q")[0].split(",");
				for (String id: ids) {
					try {
						int tmp = Integer.parseInt(id);
						noOfMonths = Math.max(tmp, noOfMonths);
						continue;
					} catch (NumberFormatException nfe) {
						// Ignore
					}
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
							resourceIds.add(id);
					}
				}
			} else {
				out.print(gson.toJson(new Object[0]));
				return;
			}
			
			if (resourceIds.size()==0 || ro.size()==0) {
				out.print(gson.toJson(new Object[0]));
				return;
			}
			if (noOfMonths<0)
				noOfMonths = 5;
			out.print(gson.toJson(HandlerWISearch.handle(request, response, resourceIds.toArray(new String[resourceIds.size()]), ro.toArray(new String[ro.size()]), noOfMonths, db, false)));
						
		} catch (Exception e) {
			Utility.handleError(gp, e);
		} finally {
			db.closeConnection();
			Utility.logAllProcessingTime();
			Utility.resetAllTimeCounter();
		}
	  }
}
