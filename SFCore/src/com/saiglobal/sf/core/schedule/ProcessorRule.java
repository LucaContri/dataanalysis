package com.saiglobal.sf.core.schedule;

import java.util.HashMap;

import com.saiglobal.sf.core.model.Resource;
import com.saiglobal.sf.core.model.WorkItem;

	public interface ProcessorRule {
		//public HashMap<String, Resource> filter(WorkItem workItem, HashMap<String, Resource> resourceIdWithScore, HashMap<String, Resource> resourceData) throws Exception;
		public HashMap<String, Resource> filter(WorkItem workItem, HashMap<String, Resource> resourceIdWithScore) throws Exception;
	}
