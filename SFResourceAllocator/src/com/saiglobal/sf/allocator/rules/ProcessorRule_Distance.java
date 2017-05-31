package com.saiglobal.sf.allocator.rules;

import java.util.ArrayList;
import java.util.List;

import com.saiglobal.sf.allocator.data.DbHelper;
import com.saiglobal.sf.core.model.Resource;
import com.saiglobal.sf.core.model.ScheduleParameters;
import com.saiglobal.sf.core.model.WorkItem;
import com.saiglobal.sf.core.utility.Utility;

public class ProcessorRule_Distance implements ProcessorRule {
	
	private String comment;
	private String name = "ProcessorRule_Distance";
	@SuppressWarnings("unused")
	private DbHelper db;
	public ProcessorRule_Distance (DbHelper db) {
		this.db = db;
	}
	
	@Override
	public List<Resource> filter(WorkItem workItem, List<Resource> resources, DbHelper db, ScheduleParameters parameters) throws Exception {
		List<Resource> filteredResources = new ArrayList<Resource>();
		for (Resource resource : resources) {
			//double distance = Utility.calculateDistanceKm(workItem.getClientSite(), resource.getHome(), db);
			double distance = Utility.calculateDistanceKm(workItem.getClientSite().getLatitude(), workItem.getClientSite().getLongitude(), resource.getHome().getLatitude(), resource.getHome().getLongitude());
			if (distance<0) {
				Utility.getLogger().error("Error in calculating distance between: " + workItem.getClientSite().getFullAddress() + " and " + resource.getHome().getFullAddress());
				Utility.getLogger().error("Assuming distance 99999");
				distance = 99999;
			}
			resource.setScore(resource.getScore()-distance*parameters.getScoreDistanceKmPenalty());
			filteredResources.add(resource);
		}
		return filteredResources;
	}

	@Override
	public String getComment() {
		return comment;
	}

	@Override
	public String getName() {
		return name;
	}
}
