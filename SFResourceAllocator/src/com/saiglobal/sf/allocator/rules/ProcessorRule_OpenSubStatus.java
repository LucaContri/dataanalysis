package com.saiglobal.sf.allocator.rules;

import java.util.ArrayList;
import java.util.List;

import com.saiglobal.sf.allocator.data.DbHelper;
import com.saiglobal.sf.core.model.Resource;
import com.saiglobal.sf.core.model.ScheduleParameters;
import com.saiglobal.sf.core.model.WorkItem;

public class ProcessorRule_OpenSubStatus implements ProcessorRule {
	private String comment;
	private String name = "ProcessorRule_OpenSubStatus";
	
	@Override
	public List<Resource> filter(WorkItem workItem, List<Resource> resources, DbHelper db, ScheduleParameters parameters) throws Exception {
		if (workItem.getOpenStatusSubType() != null && 
				(workItem.getOpenStatusSubType().toLowerCase().contains("financial") || 
				workItem.getOpenStatusSubType().toLowerCase().contains("cancellation") ||
				workItem.getOpenStatusSubType().toLowerCase().contains("suspension")))
			return new ArrayList<Resource>();
		
		return resources;
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
