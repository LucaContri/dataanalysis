package com.saiglobal.sf.allocator.rules;

import java.util.ArrayList;
import java.util.List;

import com.saiglobal.sf.allocator.data.DbHelper;
import com.saiglobal.sf.core.model.Resource;
import com.saiglobal.sf.core.model.ScheduleParameters;
import com.saiglobal.sf.core.model.SfResourceType;
import com.saiglobal.sf.core.model.WorkItem;

public class ProcessorRule_ResourceType implements ProcessorRule {
	private String comment;
	private String name = "ProcessorRule_ResourceType";
	
	@Override
	public List<Resource> filter(WorkItem workItem, List<Resource> resources, DbHelper db, ScheduleParameters parameters) throws Exception {
		List<Resource> filteredResources = new ArrayList<Resource>();
		for (Resource resource : resources) {
			if (resource.getType().equals(SfResourceType.Employee)) {
				resource.setScore(resource.getScore());
			} else {
				resource.setScore(resource.getScore()-parameters.getScoreContractorPenalties());
			}
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
