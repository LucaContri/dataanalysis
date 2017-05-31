package com.saiglobal.sf.allocator.rules;

import java.util.ArrayList;
import java.util.List;

import com.saiglobal.sf.allocator.data.DbHelper;
import com.saiglobal.sf.core.model.Resource;
import com.saiglobal.sf.core.model.ScheduleParameters;
import com.saiglobal.sf.core.model.WorkItem;

public class ProcessorRule_Capability implements ProcessorRule {
	private String comment;
	private String name = "ProcessorRule_Capability";
	
	@Override
	public List<Resource> filter(WorkItem workItem, List<Resource> resources, DbHelper db, ScheduleParameters parameters) throws Exception {
		List<Resource> filteredResources = new ArrayList<Resource>();
		this.comment = "";
		// Filter resources by capabilities
		for (Resource resource : resources) {
			if (resource.canPerform(workItem)) {
				resource.setScore(resource.getScore() - resource.getCompetencies().size()*parameters.getScoreCapabilityAuditPenalty());
				filteredResources.add(resource);
			}
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
