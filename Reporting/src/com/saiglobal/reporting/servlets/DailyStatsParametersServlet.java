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

import com.google.gson.Gson;
import com.saiglobal.sf.core.model.Region;
import com.saiglobal.sf.core.utility.Utility;

public class DailyStatsParametersServlet extends HttpServlet {
	private static final long serialVersionUID = 1L;
	//private static Logger logger = Logger.getLogger(DailyStatsParametersServlet.class);

	@Override
	public void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		Map<String, String[]> parameters;
		PrintWriter out = response.getWriter();
		response.setContentType("text/text");
		parameters = request.getParameterMap();	
		List<Region> reqRegion = new ArrayList<Region>();;
		
		try {
			// Parse parameters
			if (parameters.containsKey("region")) {
				for(String regionString : parameters.get("region")[0].split(",")) {
					reqRegion.add(Region.valueOf(regionString));
				}
			}
		} catch (Exception e) {
			//Ignore and use default
			//Utility.handleError(gp, e);
		}
		List<Object[]> regions = new ArrayList<Object[]>();
		//List<String> regionsNames = new ArrayList<String>();
		
		try {
			if (reqRegion.size()>0) {
				for (Region aRegion : reqRegion) 
					regions.add(getRegionArray(aRegion));
				//regionsNames.add(reqRegion.toString());
			} else {
				for (Region region : Region.getRegionsTree()) {
					if (region.isEnabled())
						regions.add(getRegionArray(region));
						//regionsNames.add(region.toString());
				}
			}
			Gson gson = new Gson();
			out.print(gson.toJson(regions));
		} catch (Exception e) {
			Utility.handleError(Utility.getProperties(), e);
		} finally {
			Utility.logAllProcessingTime();
			Utility.resetAllTimeCounter();
		}		
	}
	
	private Object[] getRegionArray(Region region) {
		if (!region.enabled)
			return null;
		if ((region.subRegions == null) || (region.subRegions.size()==0)) {
			return new Object[] {region.toString(), region.getName(), null};
		} else {
			List<Object[]> subregionsList = new ArrayList<Object[]>();
			for (Region subRegion : region.subRegions) {
				Object[] subRegionArray = getRegionArray(subRegion);
				if (subRegionArray != null)
					subregionsList.add(subRegionArray);
			}
			return new Object[] {region.toString(), region.getName(), subregionsList.size()==0?null:subregionsList.toArray(new Object[subregionsList.size()])};
		}
	}
}
