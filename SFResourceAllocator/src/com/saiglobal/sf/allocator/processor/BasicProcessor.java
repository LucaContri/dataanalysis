package com.saiglobal.sf.allocator.processor;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;

import org.apache.log4j.Logger;

import com.saiglobal.sf.allocator.data.DbHelper;
import com.saiglobal.sf.allocator.rules.ProcessorRule;
import com.saiglobal.sf.allocator.rules.ProcessorRule_Availability;
import com.saiglobal.sf.allocator.rules.ProcessorRule_Capability;
import com.saiglobal.sf.allocator.rules.ProcessorRule_Distance;
import com.saiglobal.sf.core.model.Resource;
import com.saiglobal.sf.core.model.ScheduleParameters;
import com.saiglobal.sf.core.model.WorkItem;
import com.saiglobal.sf.core.utility.Utility;

public class BasicProcessor extends AbstractProcessor {
	private static List<ProcessorRule> rules = new ArrayList<ProcessorRule>(); 
	
	public BasicProcessor(DbHelper db, ScheduleParameters parameters) throws Exception {
		super(db, parameters);
		rules.add(new ProcessorRule_Capability());
		rules.add(new ProcessorRule_Availability());
		rules.add(new ProcessorRule_Distance(db));

	}
	
	@Override
	public int getBatchSize() {
		return 100000;
	}

	@Override
	protected List<Resource> sortResources(List<Resource> resourceList) {
		Utility.startTimeCounter("BasicProcessor.sortResources");
		Collections.sort(resourceList);
		Utility.stopTimeCounter("BasicProcessor.sortResources");
		return resourceList;
	};
	
	@Override
	protected List<WorkItem> sortWorkItems(List<WorkItem> workItemList) {
		Utility.startTimeCounter("BasicProcessor.sortWorkItems");
		// Sort work items in decreasing frequency of capabilities required
		HashMap<String, Integer> uniqueCompetencyMap = new HashMap<String, Integer>();
		for (WorkItem aWorkItem : workItemList) {
			String aCompetenciesString = aWorkItem.getRequiredCompetenciesString();
			if (uniqueCompetencyMap.containsKey(aCompetenciesString))
				uniqueCompetencyMap.put(aCompetenciesString, uniqueCompetencyMap.get(aCompetenciesString)+1);
			else
				uniqueCompetencyMap.put(aCompetenciesString, 1);
		}
		for (WorkItem aWorkItem : workItemList) {
			aWorkItem.setFrequencyOfCapabilities(uniqueCompetencyMap.get(aWorkItem.getRequiredCompetenciesString()));
		}
		Collections.sort(workItemList);
		Utility.stopTimeCounter("BasicProcessor.sortWorkItems");
		return workItemList;
	}

	@Override
	protected Logger initLogger() {
		return Logger.getLogger(BasicProcessor.class.toString());
	}
	
	@Override
	public List<ProcessorRule> getRules() {
		return rules;
	}

	@Override
	protected void postProcessWorkItemList() {
		// TODO Auto-generated method stub
		
	}
}
