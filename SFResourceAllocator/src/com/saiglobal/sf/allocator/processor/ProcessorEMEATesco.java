package com.saiglobal.sf.allocator.processor;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

import org.apache.log4j.Logger;

import com.saiglobal.sf.allocator.data.DbHelper;
import com.saiglobal.sf.allocator.rules.ProcessorRule;
import com.saiglobal.sf.allocator.rules.ProcessorRule_Availability;
import com.saiglobal.sf.allocator.rules.ProcessorRule_Capability;
import com.saiglobal.sf.allocator.rules.ProcessorRule_Country_Tesco;
import com.saiglobal.sf.allocator.rules.ProcessorRule_Distance;
import com.saiglobal.sf.allocator.rules.ProcessorRule_OpenSubStatus;
import com.saiglobal.sf.core.model.Resource;
import com.saiglobal.sf.core.model.Schedule;
import com.saiglobal.sf.core.model.ScheduleParameters;
import com.saiglobal.sf.core.model.ScheduleType;
import com.saiglobal.sf.core.model.WorkItem;
import com.saiglobal.sf.core.utility.Utility;

public class ProcessorEMEATesco extends AbstractProcessor {
	private static List<ProcessorRule> rules = new ArrayList<ProcessorRule>(); 
	
	public ProcessorEMEATesco(DbHelper db, ScheduleParameters parameters) throws Exception {
		super(db, parameters);
		rules.add(new ProcessorRule_OpenSubStatus());
		rules.add(new ProcessorRule_Country_Tesco());
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
		Comparator<Resource> byScore = (r1, r2) -> Double.compare(
	            r1.getScore(), r2.getScore());
		resourceList = resourceList.stream().sorted(byScore.reversed()).collect(Collectors.toList());
		for (Resource resource : resourceList) {
			Utility.getLogger().debug("Resource: " + resource.getName() + ". Score: " + resource.getScore());
		}
		return resourceList;
	};
	
	@Override
	protected List<WorkItem> sortWorkItems(List<WorkItem> workItemList) {
		Utility.startTimeCounter("BasicProcessor.sortWorkItems");
		ProcessorRule_Capability p = new ProcessorRule_Capability();
		for (WorkItem aWorkItem : workItemList) {
			//aWorkItem.setFrequencyOfCapabilities(uniqueCompetencyMap.get(aWorkItem.getRequiredCompetenciesString()));
			try {
				aWorkItem.setFrequencyOfCapabilities(p.filter(aWorkItem, resources, db, parameters).size());
			} catch (Exception e) {
				// ignore
				aWorkItem.setFrequencyOfCapabilities(1);
				e.printStackTrace();
			}
		}

		@SuppressWarnings("unused")
		Comparator<WorkItem> byCustomStandard = (wi1, wi2) -> Long.compare(
	            wi1.getPrimaryStandard().getCompetencyName().startsWith("TGI Fridays")?0:1, 
	            wi2.getPrimaryStandard().getCompetencyName().startsWith("TGI Fridays")?0:1);
		Comparator<WorkItem> byDate = (wi1, wi2) -> Long.compare(
	            wi1.getTargetDate().getTime(), wi2.getTargetDate().getTime());
		Comparator<WorkItem> byComplexity = (wi1, wi2) -> Long.compare(
	            wi1.getFrequencyOfCapabilities(), wi2.getFrequencyOfCapabilities());
		workItemList = workItemList.stream().sorted(byDate.thenComparing(byComplexity)).collect(Collectors.toList());
		
		Utility.stopTimeCounter("BasicProcessor.sortWorkItems");
		return workItemList;
	}

	
	@Override
	protected Logger initLogger() {
		return Logger.getLogger(ProcessorEMEATesco.class.toString());
	}
	
	@Override
	public List<ProcessorRule> getRules() {
		return rules;
	};
	
	@Override
	public void init() throws Exception {
		super.init();

		// Group WI by location target date
		//Map<String, WorkItem> wiMap = workItemList.stream()
		//.collect(
		//		Collectors.groupingBy(WorkItem::getClientLocationAndTargetDate, 
		//		Collector.of( WorkItem::new, WorkItem::add, WorkItem::combine)));
		//
		//workItemList = new ArrayList<WorkItem>(wiMap.values());
	
	}
	
	@Override
	protected void postProcessTravel(List<Schedule> schedules, Schedule travel) throws Exception {
		// Heuristic Milk run
		// If travel distance is > 300 and resource have audits already scheduled in the same target month closer than 100km, then group them together
		double maxAuditDaysinMilkRun = 5;
		int maxSiteToSiteDistanceInMilkRun = 100;
		
		if(travel.getDistanceKm()>500) {
			Comparator<Schedule> byDistance = (s1, s2) -> Double.compare(
					Utility.calculateDistanceKm(s1.getLatitude(), s1.getLongitude(), travel.getLatitude(), travel.getLongitude()),
					Utility.calculateDistanceKm(s2.getLatitude(), s2.getLongitude(), travel.getLatitude(), travel.getLongitude()));
			
			Optional<Schedule> closer = schedules
				.stream()
				.filter(s -> s.getType().equals(ScheduleType.TRAVEL) && 
						s.getResourceId().equalsIgnoreCase(travel.getResourceId()) 
						&& s.getWorkItemCountry().equalsIgnoreCase(travel.getWorkItemCountry()) 
						&& s.getStartPeriod().equalsIgnoreCase(travel.getStartPeriod())
						)
				.sorted(byDistance)
				.findFirst();
			
			double auditDaysinMilkRun = 0;
			if (closer.isPresent() && schedules.stream().anyMatch(s -> s.getWorkItemGroup().equalsIgnoreCase(closer.get().getWorkItemGroup())))
				auditDaysinMilkRun = (schedules
						.stream()
						.filter(s -> s.getWorkItemGroup().equalsIgnoreCase(closer.get().getWorkItemGroup()))
						.mapToDouble(s -> s.getDuration()).sum() + travel.getWorkItemDuration())/8; 
			
			//if (closer.isPresent() && Utility.calculateDistanceKm(closer.get().getLatitude(), closer.get().getLongitude(), travel.getLatitude(), travel.getLongitude())<travel.getDistanceKm()) {
			if (auditDaysinMilkRun<=maxAuditDaysinMilkRun  && closer.isPresent() && Utility.calculateDistanceKm(closer.get().getLatitude(), closer.get().getLongitude(), travel.getLatitude(), travel.getLongitude())<maxSiteToSiteDistanceInMilkRun) {
				travel.setWorkItemGroup(closer.get().getWorkItemGroup());
				travel.setDistanceKm(Utility.calculateDistanceKm(closer.get().getLatitude(), closer.get().getLongitude(), travel.getLatitude(), travel.getLongitude()));
				travel.setComment("Travel from " + closer.get().getWorkItemName() + " to " + travel.getWorkItemName());
				//travel.setDuration(0);
			}
		}
	}

	@Override
	protected void postProcessWorkItemList() {
		// TODO Auto-generated method stub
		
	}
}
