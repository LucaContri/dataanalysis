package com.saiglobal.sf.allocator.processor;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.stream.Collectors;

import org.apache.log4j.Logger;

import com.google.ortools.linearsolver.MPConstraint;
import com.google.ortools.linearsolver.MPObjective;
import com.google.ortools.linearsolver.MPSolver;
import com.google.ortools.linearsolver.MPVariable;
import com.google.ortools.linearsolver.MPSolver.ResultStatus;
import com.saiglobal.sf.allocator.data.DbHelper;
import com.saiglobal.sf.allocator.rules.ProcessorRule;
import com.saiglobal.sf.core.model.Resource;
import com.saiglobal.sf.core.model.ResourceEvent;
import com.saiglobal.sf.core.model.ResourceEventType;
import com.saiglobal.sf.core.model.Schedule;
import com.saiglobal.sf.core.model.ScheduleParameters;
import com.saiglobal.sf.core.model.ScheduleStatus;
import com.saiglobal.sf.core.model.ScheduleType;
import com.saiglobal.sf.core.model.TravelCostCalculationType;
import com.saiglobal.sf.core.model.WorkItem;
import com.saiglobal.sf.core.utility.Utility;

public class MIPProcessor extends AbstractProcessor {
	static {
		// OR Tools
		// https://github.com/google/or-tools/releases/download/v5.1/or-tools_flatzinc_VisualStudio2015-64bit_v5.1.4045.zip
		// https://developers.google.com/optimization/
		System.loadLibrary("jniortools"); 
	}
	double infinity = Double.MAX_VALUE;
	long maxExecTime = 3000000; // 5 minutes
	
	public MIPProcessor(DbHelper db, ScheduleParameters parameters) throws Exception {
		super(db, parameters);
	}

	@Override
	public void execute() throws Exception {
		
		// Sort workItems
		Utility.startTimeCounter("MIPProcessor.execute");
		workItemList = sortWorkItems(workItemList);
		
		// Break processing in sub-groups based on period
		List<String> periods = parameters.getPeriodsWorkingDays().keySet().stream().sorted().collect(Collectors.toList());
		saveBatchDetails(this.parameters);
		for (String period : periods) {	
			logger.info("Start processing batch " + period + ". Time: " + System.currentTimeMillis());
			List<WorkItem> workItemsBatch = workItemList.stream().filter(wi -> Utility.getPeriodformatter().format(wi.getStartDate()).equalsIgnoreCase(period)).collect(Collectors.toList());
			List<Schedule> schedule = schedule(workItemsBatch, resources);
			logger.info("Saving schedule for batch " + period + ". Time: " + System.currentTimeMillis());
			saveSchedule(schedule);
		}
		
		Utility.stopTimeCounter("MIPProcessor.execute");
		Utility.logAllProcessingTime();
		Utility.logAllEventCounter();
	}
	
	@Override
	public List<ProcessorRule> getRules() {
		return null;
	}

	@Override
	public int getBatchSize() {
		return 0;
	}

	@Override
	protected Logger initLogger() {
		return Logger.getLogger(MIPProcessor.class);
	}
	
	@Override
	protected List<WorkItem> sortWorkItems(List<WorkItem> workItemList) {
		// Sort WI by target date
		Utility.startTimeCounter("MIPProcessor.sortWorkItems");
		Comparator<WorkItem> byDate = (wi1, wi2) -> Long.compare(
	            wi1.getStartDate().getTime(), wi2.getStartDate().getTime());
		workItemList = workItemList.stream().sorted(byDate).collect(Collectors.toList());
		
		Utility.stopTimeCounter("MIPProcessor.sortWorkItems");
		return workItemList;
	}
	
	private static MPSolver createSolver (String solverType) {
	    try {
	      return new MPSolver("IntegerProgrammingExample", MPSolver.OptimizationProblemType.valueOf(solverType));
	    } catch (java.lang.IllegalArgumentException e) {
	      return null;
	    }
	}
	
	@Override
	protected List<Schedule> schedule(List<WorkItem> workItemListBatch, List<Resource> resources) throws Exception {
		// SCIP_MIXED_INTEGER_PROGRAMMING - (http://scip.zib.de/)
		// GLPK_MIXED_INTEGER_PROGRAMMING - (https://www.gnu.org/software/glpk/)
		// CBC_MIXED_INTEGER_PROGRAMMING - (https://projects.coin-or.org/Cbc)
		String solverType = "CBC_MIXED_INTEGER_PROGRAMMING";
		
		// Instantiate a mixed-integer solver
		MPSolver solver = createSolver(solverType);
	    if (solver == null) {
	      logger.error("Could not create solver " + solverType);
	      return null;
	    }
	    
	    final double[][] costs = getCostMatrix(workItemListBatch);

		// Maximum total of task sizes for any worker
		int[] audits_periods_pointers = getNumAuditsByPeriod(workItemListBatch);
		int num_auditors = resources.size()+1; // Add a fake auditor to assign impossible tasks
		
		double[][] resource_capacity = getResourceCapacityMatrix(audits_periods_pointers, workItemListBatch);
		double[][] audit_duration = getAuditDurationMatrix(workItemListBatch);
		
		// Variables
		MPVariable[][] x = new MPVariable[num_auditors][audits_periods_pointers[audits_periods_pointers.length-1]];
		for (int i = 0; i < x.length; i++) {
			for (int j = 0; j < x[0].length; j++) {
				x[i][j] = solver.makeIntVar(0, 1, "x["+i+","+j+"]");
			}
		}
		
		// Constraints
		
		// The total duration of the tasks each worker takes on in a month is at most its capacity in the month.
		for (int i = 0; i < num_auditors-1; i++) {
			for (int p = 1; p < audits_periods_pointers.length; p++) {
				MPConstraint ct = solver.makeConstraint(0, resource_capacity[i][p-1]);
				for (int j = audits_periods_pointers[p-1]; j < audits_periods_pointers[p]; j++) {
					ct.setCoefficient(x[i][j], audit_duration[i][j]);
				}
			}
		} 
		
		// Each task is assigned to at least one worker.
		for (int j = 0; j < audits_periods_pointers[audits_periods_pointers.length-1]; j++) {
			MPConstraint ct = solver.makeConstraint(1, 1);
			for (int i = 0; i < num_auditors; i++) {
				ct.setCoefficient(x[i][j], 1);
			}
		}
		
		// Excludes auditors not capable of performing the audit
		for (int j = 0; j < audits_periods_pointers[audits_periods_pointers.length-1]; j++) {
			for (int i = 0; i < num_auditors-1; i++) {
				if (!resources.get(i).canPerform(workItemListBatch.get(j))) {
					MPConstraint ct = solver.makeConstraint(0, 0);
					ct.setCoefficient(x[i][j], 1);
				}
			}
		}
	
		// Objective: Minimise total cost
		MPObjective objective = solver.objective();
		for (int i = 0; i < num_auditors; i++) {
			for (int j = 0; j < audits_periods_pointers[audits_periods_pointers.length-1]; j++) {
				objective.setCoefficient(x[i][j], costs[i][j]);
			}
		}
		
		logger.info("No. variables: " + solver.numVariables());
		logger.info("No. constraints: " + solver.numConstraints());
		
		//solver.enableOutput();
		solver.setTimeLimit(maxExecTime); 
		ResultStatus resultStatus = solver.solve();
		
		// Check that the problem has an optimal solution.
		if (resultStatus != MPSolver.ResultStatus.OPTIMAL) {
			logger.error("Could not find an optimal solution in the time limit of " + maxExecTime/1000/60 + " minutes");
		}
		
		// Verify that the solution satisfies all constraints (when using solvers
		// others than GLOP_LINEAR_PROGRAMMING, this is highly recommended!).
		if (!solver.verifySolution(/*tolerance=*/1e-7, /*logErrors=*/true)) {
			logger.error("The solution returned by the solver violated the problem constraints by at least 1e-7");
			throw new Exception("The solution returned by the solver violated the problem constraints by at least 1e-7");
		}
		
		logger.info("Problem solved in " + solver.wallTime() + " milliseconds");
		logger.info("No. interations : " + solver.iterations());
		logger.info("Problem solved in " + solver.nodes() + " branch-and-bound nodes");
		logger.info("Optimal objective value = " + solver.objective().value());
		
		double totalCost = 0;
		// The value of each variable in the solution.
		for (int i = 0; i < num_auditors; i++) {
			for (int j = 0; j < audits_periods_pointers[audits_periods_pointers.length-1]; j++) {
				if (x[i][j].solutionValue()>0) {
					logger.debug("Worker " + i + " assigned to task " + j);
					if(i<resources.size())
						totalCost += Utility.calculateAuditCost(resources.get(i), workItemListBatch.get(j), workItemListBatch.get(j), TravelCostCalculationType.EMPIRICAL_UK, db, false, true);
				}
			}
		}
		
		logger.info("Total cost: " + totalCost);
		
		return populateSchedule(x, workItemListBatch);
	}
	
	private int[] getNumAuditsByPeriod(List<WorkItem> workItemList) {
		// Return an array of x elements where x is the no. of periods and each element contains a pointer to the first audit in the period
		List<Integer> aux = new ArrayList<Integer>();
		// Work Items are already sorted by start date
		String currentPeriod = Utility.getPeriodformatter().format(workItemList.get(0).getStartDate());
		aux.add(0);
		for (int i = 0; i < workItemList.size(); i++) {
			if (!Utility.getPeriodformatter().format(workItemList.get(i).getStartDate()).equalsIgnoreCase(currentPeriod)) {
				currentPeriod = Utility.getPeriodformatter().format(workItemList.get(i).getStartDate());
				aux.add(i);
			}
		}
		aux.add(workItemList.size());
		
		int[] retValue = new int[aux.size()];
		for (int i = 0; i < aux.size(); i++) {
			retValue[i] = aux.get(i).intValue();
		}
		return retValue;
	}
	
	private double[][] getAuditDurationMatrix(List<WorkItem> workItemList) {
		double[][] auditDurations = new double[resources.size()+1][workItemList.size()];
		for (int i = 0; i <= resources.size(); i++) {
			for (int j = 0; j < workItemList.size(); j++) {
				double distance = 0;
				if (!workItemList.get(j).getServiceDeliveryType().equalsIgnoreCase("Off Site")) {
					try {
						distance = 2*Utility.calculateDistanceKm(workItemList.get(j).getClientSite(), resources.get(i).getHome(), db);
					} catch (Exception e) {
						// Assume infinite distance
						distance = Double.MAX_VALUE;
					}
				}
				auditDurations[i][j] = workItemList.get(j).getRequiredDuration() + Utility.calculateTravelTimeHrs(distance, true);
			}
		}
		return auditDurations;
	}

	private double[][] getResourceCapacityMatrix(int[] num_audits_period, List<WorkItem> workItemList) {
		HashMap<String, Integer> periodWorkingDays = parameters.getPeriodsWorkingDays();
		double[][] resourceCapacity = new double[resources.size()+1][num_audits_period.length-1];
		
		for (int p = 0; p < num_audits_period.length-1; p++) {
			String period = Utility.getPeriodformatter().format(workItemList.get(num_audits_period[p]).getStartDate());
		
		//for (Object period : periodWorkingDays.keySet().stream().sorted().toArray()) {
			for (int i = 0; i < resourceCapacity.length-1; i++) {
				// For each resource
				double bopDays = (double) (Math.ceil(resources.get(i).getCalender().getEvents().stream().filter(e -> e.getPeriod().equalsIgnoreCase(period.toString()) && e.getType().equals(ResourceEventType.SF_BOP)).mapToDouble(ResourceEvent::getDurationWorkingDays).sum() * 2) / 2);
				double auditDays = (double) (Math.ceil(resources.get(i).getCalender().getEvents().stream().filter(e -> e.getPeriod().equalsIgnoreCase(period.toString()) && (e.getType().equals(ResourceEventType.ALLOCATOR_WIR)||e.getType().equals(ResourceEventType.SF_WIR)||e.getType().equals(ResourceEventType.ALLOCATOR_TRAVEL))).mapToDouble(ResourceEvent::getDurationWorkingDays).sum() * 2) / 2);
				resourceCapacity[i][p] = Math.max(((periodWorkingDays.get(period) - bopDays)*resources.get(i).getCapacity()/100 - auditDays)*8,0);				
			}
			resourceCapacity[resourceCapacity.length-1][p] = infinity;
		}
		return resourceCapacity;
	}
	
	private double[][] getCostMatrix(List<WorkItem> workItemList) throws Exception {
		
		double[][] costs = new double[resources.size()+1][workItemList.size()];
		
		for (int j = 0; j < workItemList.size(); j++) {
			for (int i = 0; i < resources.size(); i++) {
				costs[i][j] = Utility.calculateAuditCost(resources.get(i), workItemList.get(j), workItemList.get(j), TravelCostCalculationType.EMPIRICAL_UK, db, false, true);
			}
			costs[resources.size()][j] = 999999;
		}
		
		return costs;
	}

	private List<Schedule> populateSchedule(MPVariable[][] x, List<WorkItem> workItemList) throws Exception {
		List<Schedule> returnSchedule = new ArrayList<Schedule>();
		// The value of each variable in the solution.
		for (int i = 0; i < x.length; i++) {
			for (int j = 0; j < x[0].length; j++) {
				if (x[i][j].solutionValue()>0) {
					// Initialise Schedule
					Schedule aSchedule = new Schedule();
					aSchedule.setWorkItemId(workItemList.get(j).getId());
					aSchedule.setWorkItemGroup(workItemList.get(j).getId()); // No milk run with MIP scheduling yet
					aSchedule.setWorkItemName(workItemList.get(j).getName());
					aSchedule.setStartDate(workItemList.get(j).getTargetDate());
					aSchedule.setWorkItemSource(workItemList.get(j).getWorkItemSource());
					aSchedule.setWorkItemCountry(workItemList.get(j).getClientSite().getCountry());
					aSchedule.setWorkItemState(workItemList.get(j).getClientSite().getState());
					aSchedule.setWorkItemTimeZone(workItemList.get(j).getClientSite().getTimeZone().getID());
					aSchedule.setLatitude(workItemList.get(j).getClientSite().getLatitude());
					aSchedule.setLongitude(workItemList.get(j).getClientSite().getLongitude());
					aSchedule.setType(ScheduleType.AUDIT);
					aSchedule.setDuration(workItemList.get(j).getRequiredDuration());
					aSchedule.setWorkItemDuration(workItemList.get(j).getRequiredDuration());
					aSchedule.setPrimaryStandard(workItemList.get(j).getPrimaryStandard());
					aSchedule.setCompetencies(workItemList.get(j).getRequiredCompetenciesString());
					
					if (i==x.length-1) {
						// Assigned to last "fake" resource. I.e. Not Allocated
						aSchedule.setStatus(ScheduleStatus.NOT_ALLOCATED);
					} else {						
						//Resource resource = resources.get(i);
						//ResourceEvent eventToBook = new ResourceEvent();
						//eventToBook.setType(ResourceEventType.ALLOCATOR_WIR);
						//eventToBook.setStartDateTime(workItemList.get(j).getStartDate());
						//eventToBook.setEndDateTime(cal.getTime());
						//resource.bookFor(eventToBook);
						// Not doing scheduling yet.  
						// StartDate and EndDate are stored only to record duration of the WI and allow proper recording of resource utilization
						//aSchedule.setStartDate(workItemList.get(j).getStartDate());
						//Calendar cal = Calendar.getInstance();
						//cal.setTime(workItemList.get(j).getStartDate());
						//cal.add(Calendar.HOUR_OF_DAY, (int) workItemList.get(j).getRequiredDuration());
						//aSchedule.setEndDate(cal.getTime());
						aSchedule.setResourceId(resources.get(i).getId());
						aSchedule.setResourceName(resources.get(i).getName());
						aSchedule.setResourceType(resources.get(i).getType());
						aSchedule.setStatus(ScheduleStatus.ALLOCATED);
						
						if (workItemList.get(j).getServiceDeliveryType().equalsIgnoreCase("Off Site"))
							aSchedule.setDistanceKm(0);
						else
							aSchedule.setDistanceKm(2*Utility.calculateDistanceKm(workItemList.get(j).getClientSite(), resources.get(i).getHome(), db));
						
						aSchedule.setTravelDuration(Utility.calculateTravelTimeHrs(aSchedule.getDistanceKm(), true));
						
						/*
						Schedule travelling = new Schedule();
						travelling.setWorkItemId(workItemList.get(j).getId());
						travelling.setWorkItemName(workItemList.get(j).getName());
						travelling.setWorkItemSource(workItemList.get(j).getWorkItemSource());
						travelling.setWorkItemCountry(workItemList.get(j).getClientSite().getCountry());
						travelling.setWorkItemState(workItemList.get(j).getClientSite().getState());
						travelling.setWorkItemDuration(workItemList.get(j).getRequiredDuration());
						travelling.setLatitude(workItemList.get(j).getClientSite().getLatitude());
						travelling.setLongitude(workItemList.get(j).getClientSite().getLongitude());
						travelling.setStatus(ScheduleStatus.ALLOCATED);
						travelling.setType(ScheduleType.TRAVEL);
						travelling.setDistanceKm(aSchedule.getDistanceKm());
						travelling.setStartDate(workItemList.get(j).getTargetDate());
						travelling.setPrimaryStandard(workItemList.get(j).getPrimaryStandard());
						travelling.setCompetencies(workItemList.get(j).getRequiredCompetenciesString());
						travelling.setResourceId(resource.getId());
						travelling.setResourceName(resource.getName());
						travelling.setResourceType(resource.getType());
						travelling.setStatus(ScheduleStatus.ALLOCATED);
						//travelling.setComment("Actual travel time: " + travelTime + ".  Travel time + WI duration: " + aWorkItem.getRequiredDuration() + travelTime + " Total Equivalent Travel Hrs" + totalEquivalentTravelHrs);
						postProcessTravel(returnSchedule, travelling);
						aSchedule.setWorkItemGroup(travelling.getWorkItemGroup());
						cal.setTime(workItemList.get(j).getTargetDate());
						cal.add(Calendar.HOUR_OF_DAY, (int) travelling.getDuration());
						travelling.setEndDate(cal.getTime());
	
						// Book resource for travel
						ResourceEvent travelToBook = new ResourceEvent();
						travelToBook.setType(ResourceEventType.ALLOCATOR_TRAVEL);
						travelToBook.setStartDateTime(workItemList.get(j).getTargetDate());
						travelToBook.setEndDateTime(cal.getTime());
						
						resource.bookFor(travelToBook);
						// Add to return schedule
						returnSchedule.add(travelling);
						*/
					}
					returnSchedule.add(aSchedule);
				}
			}
		}
		return returnSchedule;
	}

	@Override
	protected void postProcessWorkItemList() {
		// TODO Auto-generated method stub
		
	}
}
