package com.saiglobal.sf.allocator.processor;

import java.text.NumberFormat;
import java.text.ParseException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Calendar;
import java.util.Comparator;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
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

public class MIP2Processor extends AbstractProcessor {
	static {
		// OR Tools
		// https://github.com/google/or-tools/releases/download/v5.1/or-tools_flatzinc_VisualStudio2015-64bit_v5.1.4045.zip
		// https://developers.google.com/optimization/
		System.loadLibrary("jniortools"); 
	}
	final double infinity = Double.MAX_VALUE;
	final Locale currentLocale = Locale.getDefault();
	final NumberFormat percentFormatter = NumberFormat.getPercentInstance(currentLocale);
	final NumberFormat currencyFormatter = NumberFormat.getCurrencyInstance(currentLocale);
	final long maxExecTime = 300000; // 5 minutes
	final int cost_of_not_performing = 50000;
	final int no_of_closest_auditors = 5;
	int timeSlothours = 4;
	int startHourBusinessDay = 9;
	int endHourBusinessDay = 17;
	int no_of_time_slots_day = Math.floorDiv(endHourBusinessDay-startHourBusinessDay, timeSlothours);
	List<WorkItem> workItemListBatch = null;
	String solverType = null;
	String period = null;
    int num_audits = 0;
	int num_auditors = 0;
	int num_time_slots = 0;
	
	double[][] costs = null;
	double[] resource_capacity = null;
	int[][] resource_availability = null;
	double[][] audit_duration = null;
	TravelCostCalculationType travelCostCalculationType = TravelCostCalculationType.EMPIRICAL_UK;
	
	public MIP2Processor(DbHelper db, ScheduleParameters parameters) throws Exception {
		super(db, parameters);
	}

	@Override
	public void execute() throws Exception {
		
		// Sort workItems
		Utility.startTimeCounter("MIP2Processor.execute");
		workItemList = sortWorkItems(workItemList);
		
		saveBatchDetails(this.parameters);
		// Break processing in sub-groups based on period
		List<String> periods = parameters.getPeriodsWorkingDays().keySet().stream().sorted().collect(Collectors.toList());
		for (String local_period : periods) {
			period = local_period;
			logger.info("Start processing batch " + period + ". Time: " + System.currentTimeMillis());
			workItemListBatch = workItemList.stream().filter(wi -> Utility.getPeriodformatter().format(wi.getTargetDate()).equalsIgnoreCase(period) && wi.isPrimary()).collect(Collectors.toList());
			List<Schedule> schedule = scheduleBatch();
			logger.info("Saving schedule for batch " + period + ". Time: " + System.currentTimeMillis());
			saveSchedule(schedule);
		}
		updateBatchDetails(this.parameters);
		Utility.stopTimeCounter("MIP2Processor.execute");
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
		return Logger.getLogger(MIP2Processor.class);
	}
	
	@Override
	protected List<WorkItem> sortWorkItems(List<WorkItem> workItemList) {
		// Sort WI by target date
		Utility.startTimeCounter("MIPProcessor.sortWorkItems");
		Comparator<WorkItem> byDate = (wi1, wi2) -> Long.compare(
	            wi1.getTargetDate().getTime(), wi2.getTargetDate().getTime());
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
	
	private double calculateSolutionCost(MPVariable[][][] x, TravelCostCalculationType travelCostCalculationType) throws Exception {
		
		double totalCost = 0;
		// The value of each variable in the solution.
		for (int i = 0; i < x.length; i++) {
			for (int j = 0; j < x[i].length; j++) {
				for (int t = 0; t < x[i][j].length; t++) {
					if (x[i][j][t] != null && x[i][j][t].solutionValue()>0) {	
						logger.debug("Worker " + i + " assigned to task " + j + " to be performed on: " + Utility.getActivitydateformatter().format(getTimeFromSlot(t, period).getTime()));
						if(i<resources.size())
							totalCost += Utility.calculateAuditCost(resources.get(i), workItemListBatch.get(j), workItemListBatch.get(j), travelCostCalculationType, db, false, true, true);
					}	
				}
			}
		}
		return totalCost;
	}
	
	private SolverResult solve(int[][][] constraints) throws Exception {
		
		boolean timeContrained = true;
		if(constraints[0][0].length==1)
			timeContrained = false;
		
		// Instantiate a mixed-integer solver
		MPSolver solver = createSolver(solverType);
	    if (solver == null) {
	      logger.error("Could not create solver " + solverType);
	      return null;
	    }
	    
		// Variables
		MPVariable[][][] x = new MPVariable[constraints.length][constraints[0].length][constraints[0][0].length];
		int num_variables = 0;
		for (int i = 0; i < constraints.length; i++) {
			for (int j = 0; j < constraints[i].length; j++) {
				for (int t = 0; t < constraints[i][j].length; t++) {
					if (constraints[i][j][t]==1) {
						num_variables++;
						x[i][j][t] = solver.makeIntVar(0, 1, "x["+i+","+j+","+t+"]");
					}
				}
			}
		}
		
		// Constraints
		
		// The total duration of the tasks each worker takes on in a month is at most his/her capacity in the month.
		for (int i = 0; i < constraints.length-1; i++) {
			MPConstraint ct = solver.makeConstraint(0, resource_capacity[i]);
			for (int j = 0; j < constraints[i].length; j++) {
				for (int t = 0; t < constraints[i][j].length; t++) {
					if (constraints[i][j][t]==1)
						ct.setCoefficient(x[i][j][t], audit_duration[i][j]);
				}
			}	
		} 
		
		if(timeContrained) {
			// The duration of each task each worker takes is at most his/her availability at the time it is taken
			for (int i = 0; i < constraints.length-1; i++) {
				for (int t = 0; t < constraints[i][0].length; t++) {
					MPConstraint ct = solver.makeConstraint(0, resource_availability[i][t]*timeSlothours);
					for (int j = 0; j < constraints[i].length; j++) {
						if (constraints[i][j][t]==1)
							ct.setCoefficient(x[i][j][t], audit_duration[i][j]);
					}
				}	
			}
			
			// No overlapping jobs
			for (int i = 0; i < constraints.length-1; i++) {
				// For each auditor
				for (int j = 0; j < constraints[i].length; j++) {
					for (int t = 0; t < constraints[i][j].length; t++) {
						if (constraints[i][j][t]==1) {
							// For each audit j starting at time t ...
							int audit_duration_timeslots = (int) Math.ceil(audit_duration[i][j]/timeSlothours);
							// ... there are no other audit j2 starting at t+s; for each 0 < s < audit_duration_timeslots
							for (int s = 0; s < audit_duration_timeslots; s++) {
								MPConstraint ct = solver.makeConstraint(0, 1);
								ct.setCoefficient(x[i][j][t], 1);
								if (t+s<num_time_slots) {
									for (int j2 = 0; j2 < constraints[i].length; j2++) {
										if(j2!=j && constraints[i][j2][t+s]==1) {
											ct.setCoefficient(x[i][j2][t+s], 1);
										}
									}
								}
							}
						}
					}
				}			
			}
		}
		
		// Each task is assigned to one worker in one time slot only.
		for (int j = 0; j < constraints[0].length; j++) {
			MPConstraint ct = solver.makeConstraint(1, 1);
			for (int i = 0; i < constraints.length; i++) {
				for (int t = 0; t < constraints[i][j].length; t++) {
					if (constraints[i][j][t]==1)
						ct.setCoefficient(x[i][j][t], 1);
				}
			}
		}
		
		// Objective: Minimise total cost
		MPObjective objective = solver.objective();
		for (int i = 0; i < constraints.length; i++) {
			for (int j = 0; j < constraints[i].length; j++) {
				for (int t = 0; t < constraints[i][j].length; t++) {
					if (constraints[i][j][t]==1)
						objective.setCoefficient(x[i][j][t], costs[i][j]);
				}
			}
		}
		
		logger.info("No audits:" + workItemListBatch.size());
		logger.info("No auditors:" + resources.size());
		logger.info("No. variables: " + solver.numVariables());
		logger.info("No. constraints: " + solver.numConstraints());
		
		//solver.enableOutput();
		solver.setTimeLimit(maxExecTime); 
		ResultStatus resultStatus = solver.solve();
		
		// Verify that the solution satisfies all constraints (when using solvers
		// others than GLOP_LINEAR_PROGRAMMING, this is highly recommended!).
		if (!solver.verifySolution(/*tolerance=*/1e-7, /*logErrors=*/true)) {
			logger.error("The solution returned by the solver violated the problem constraints by at least 1e-7");
			throw new Exception("The solution returned by the solver violated the problem constraints by at least 1e-7");
		}
		
		logger.debug("Problem solved in " + solver.wallTime() + " milliseconds");
		logger.debug("No. interations : " + solver.iterations());
		logger.debug("Problem solved in " + solver.nodes() + " branch-and-bound nodes");
		logger.debug("Optimal objective value = " + currencyFormatter.format(solver.objective().value()));
		logger.debug("Total cost: " + currencyFormatter.format(calculateSolutionCost(x, travelCostCalculationType)));
		
		SolverResult sr = new SolverResult();
		sr.setSolver(solver);
		sr.setResultStatus(resultStatus);
		sr.setVariables(x);
		
		return sr;
	}
	
	private void initBatchVariables() throws Exception {
		// SCIP_MIXED_INTEGER_PROGRAMMING - (http://scip.zib.de/)
		// GLPK_MIXED_INTEGER_PROGRAMMING - (https://www.gnu.org/software/glpk/)
		// CBC_MIXED_INTEGER_PROGRAMMING - (https://projects.coin-or.org/Cbc)
		solverType = "CBC_MIXED_INTEGER_PROGRAMMING";
	    
	    costs = getCostMatrix();

		// Maximum total of task sizes for any worker
		num_audits = workItemListBatch.size();
		num_auditors = resources.size()+1; // Add a fake auditor to assign impossible tasks
		num_time_slots = getPeriodSlots(period);
		
		resource_capacity = getResourceCapacityMatrix();
		resource_availability = getResourceAvailailityMatrix();
		audit_duration = getAuditDurationMatrix();
	}
	
	private int[][][] presolve() {
		/*
		 * Presolving. The purpose of presolving, which takes place
		 * before the tree search is started, is threefold: first, it reduces 
		 * the size of the model by removing irrelevant information 
		 * such as redundant constraints or fixed variables.
		 */

		int[][][] constraints = new int[num_auditors][num_audits][num_time_slots];
		for (int i = 0; i < num_auditors; i++) {
			for (int j = 0; j < num_audits; j++) {
				for (int t = 0; t < num_time_slots; t++) {
					// Deafult
					constraints[i][j][t] = 1;
					// Excludes auditors not capable of performing the audit
					if (i<num_auditors-1 && !resources.get(i).canPerform(workItemListBatch.get(j))) {
						constraints[i][j][t] = 0;
					}
					// Exclude not available dates
					if (i<num_auditors-1 && resource_availability[i][t]<Math.ceil(audit_duration[i][j]/timeSlothours)) {
						constraints[i][j][t] = 0;
					}
				}
			}
		}
		return constraints;
	}
	
	protected List<Schedule> scheduleBatch() throws Exception {
		
		initBatchVariables();		
		
		int[][][] constraints = presolve();
		
		// Solve relaxed problem excluding time slots constraints to find a lower bound (LB)
		int[][][] relaxedConstraints = new int[constraints.length][constraints[0].length][1];
		for (int i = 0; i < relaxedConstraints.length; i++) {
			for (int j = 0; j < relaxedConstraints[i].length; j++) {
				if (Arrays.stream(constraints[i][j]).sum()>0) 
					relaxedConstraints[i][j][0] = 1;
				else
					relaxedConstraints[i][j][0] = 0;
				
			}
		}
		SolverResult srRelaxed = solve(relaxedConstraints);
		ResultStatus resultStatusRelaxed = srRelaxed.getResultStatus();
		MPVariable[][][] xRelaxed = srRelaxed.getVariables();
		double lowerBound = -1;
		
		// Check that the problem has an optimal solution.
		if (resultStatusRelaxed != MPSolver.ResultStatus.OPTIMAL) {
			logger.error("Could not find an optimal solution to the relaxed problem in the time limit of " + maxExecTime/1000/60 + " minutes");
		} else {
			lowerBound = srRelaxed.getSolver().objective().value();
			logger.info("Found LB of cost: " + currencyFormatter.format(lowerBound) + " (" + currencyFormatter.format(calculateSolutionCost(xRelaxed, travelCostCalculationType)) +")");
		}
		
		SolverResult sr = null;
		ResultStatus resultStatus = null;
		MPVariable[][][] x = null;
		double obj = Double.MAX_VALUE;
		
		// Solve full problem
		sr = solve(constraints);
		resultStatus = sr.getResultStatus();
		obj = sr.getSolver().objective().value();
		
		if (resultStatus.equals(MPSolver.ResultStatus.OPTIMAL)) {
			x = sr.getVariables();
			logger.info("Found optimal Solution with objective value of " + currencyFormatter.format(obj));
		}
		
		if (resultStatus.equals(MPSolver.ResultStatus.FEASIBLE)) {
			x = sr.getVariables();
			if(lowerBound>0) 
				logger.info("Found feasable solution with objective value of " + currencyFormatter.format(obj) + " vs lower bound of " + currencyFormatter.format(lowerBound) + " (+" + percentFormatter.format((obj-lowerBound)/lowerBound) + ")");
			else
				logger.info("Found feasable solution with objective value of " + currencyFormatter.format(obj));
		}
		/* Relaxed problem
		 * For each audit limit the solution space to the closest no_of_closest_auditors 
		 
		relaxedConstraints = new int[constraints.length][constraints[0].length][constraints[0][0].length];
		for (int j = 0; j < relaxedConstraints[0].length; j++) {
			List<Integer> closestAuditors = getClosestAuditors(j);
			for (int i = 0; i < relaxedConstraints.length; i++) {
				for (int t = 0; t < relaxedConstraints[i][j].length; t++) {
					if (closestAuditors.contains(new Integer(i)) || i==(relaxedConstraints.length-1))
						relaxedConstraints[i][j][t] = constraints[i][j][t];
					else
						relaxedConstraints[i][j][t] = 0;
				}
			}
		}
		
		SolverResult sr2 = solve(relaxedConstraints);
		ResultStatus resultStatus2 = sr.getResultStatus();
		obj2 = sr2.getSolver().objective().value();
		
		if ((resultStatus2 == MPSolver.ResultStatus.OPTIMAL || resultStatus2 == MPSolver.ResultStatus.FEASIBLE) && obj2<obj1) {
			logger.info("Using the solution of the relaxed problem");
			x = sr2.getVariables();
		} else {
			logger.info("Using the solution of the full problem");
		}
		*/
		
		// Move unallocated to next month within target.
		Calendar auxStart = Calendar.getInstance();
		Calendar auxEnd = Calendar.getInstance();
		for (WorkItem wi : getUnallocated(x)) {
			WorkItem wil = getWorkItemFromList(wi.getId());
			if(resources.stream().filter(r -> r.canPerform(wil)).count()>0) {
				auxStart.setTimeInMillis(wil.getTargetDate().getTime());
				auxEnd.setTimeInMillis(wil.getEndAuditWindow().getTime());
				auxStart.add(Calendar.MONTH, 1);
				if (auxStart.before(auxEnd)) {
					logger.debug("Moving unallocated audit " + wil.getName() + " from " + Utility.getPeriodformatter().format(wil.getTargetDate()) + " to " + Utility.getPeriodformatter().format(auxStart.getTime()));
					wil.setTargetDate(new Date(auxStart.getTimeInMillis()));
					wil.setCostOfNotAllocating(wil.getCostOfNotAllocating()+cost_of_not_performing);
					wil.setLog(false);
				} else {
					wil.setLog(true);
					wil.setComment("Not allocated due to missing availability");
					logger.debug("Cannot allocate audit " + wil.getName() + " and cannot move to next period (" + Utility.getPeriodformatter().format(auxStart.getTime()) + ") as it is outside the audit window end date (" + Utility.getPeriodformatter().format(wil.getEndAuditWindow()) + ")");
				}
			} else {
				// Audit not allocated due to missing capability
				wil.setComment("Not allocated due to missing capability");
				wil.setLog(true);
				logger.debug("Cannot allocate audit " + wil.getName() + " due to missing capability");
			}
		}
		
		return populateSchedule(x);
	}
	
	private WorkItem getWorkItemFromList(String workItemId) {
		if (workItemId == null)
			return null;
		for (WorkItem wi : workItemList) {
			if (wi.getId().equalsIgnoreCase(workItemId))
				return wi;
		}
		return null;
	}
	
	private List<WorkItem> getUnallocated(MPVariable[][][] x) {
		List<WorkItem> unallocated = new ArrayList<WorkItem>();
	
		if (x == null)
			return unallocated;
		for (int j = 0; j < x[0].length; j++) {
			if (Arrays.stream(x[x.length-1][j]).mapToInt(t -> t==null?0:(int)t.solutionValue()).sum()>0) {
				unallocated.add(workItemListBatch.get(j));
			}
		}
		return unallocated;
	}
	
	@SuppressWarnings("unused")
	private List<Integer> getClosestAuditors(int j) {
		Comparator<Resource> byDistance = (r1, r2) -> Double.compare(
	            Utility.calculateDistanceKm(
	            		r1.getHome().getLatitude(), r1.getHome().getLongitude(), 
	            		workItemListBatch.get(j).getClientSite().getLatitude(), workItemListBatch.get(j).getClientSite().getLongitude()), 
	            Utility.calculateDistanceKm(
	            		r2.getHome().getLatitude(), r2.getHome().getLongitude(), 
	            		workItemListBatch.get(j).getClientSite().getLatitude(), workItemListBatch.get(j).getClientSite().getLongitude()));
		int[] closestAuditors = 
			resources.stream()
				.filter(r -> r.canPerform(workItemListBatch.get(j)))
				.sorted(byDistance)
				.limit(no_of_closest_auditors)
				.mapToInt(r -> getResourceIndex(r))
				.toArray();
		
		List<Integer> closestAuditorsList = new ArrayList<Integer>();
		for (int i = 0; i < closestAuditors.length; i++) {
			closestAuditorsList.add(closestAuditors[i]);
		}
		return closestAuditorsList;
	}

	private int getResourceIndex(Resource resource) {
		for (int i = 0; i < resources.size(); i++) {
			if (resources.get(i).getId().equals(resource.getId()))
				return i;
		}
		return -1;
	}
	
	@SuppressWarnings("unused")
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
	
	private double[][] getAuditDurationMatrix() {
		double[][] auditDurations = new double[resources.size()+1][workItemListBatch.size()];
		for (int i = 0; i <= resources.size(); i++) {
			for (int j = 0; j < workItemListBatch.size(); j++) {
				double distance = 0;
				if (!workItemListBatch.get(j).getServiceDeliveryType().equalsIgnoreCase("Off Site")) {
					try {
						distance = 2*Utility.calculateDistanceKm(workItemListBatch.get(j).getClientSite(), resources.get(i).getHome(), db);
					} catch (Exception e) {
						// Assume infinite distance
						distance = Double.MAX_VALUE;
					}
				}
				auditDurations[i][j] = 
						workItemListBatch.get(j).getRequiredDuration()
						+ workItemListBatch.get(j).getLinkedWorkItems().stream().mapToInt(wi -> (int) Math.ceil(wi.getRequiredDuration())).sum()
						// Cap travel time to 1/2 day each way in the UK
						+ Math.min(Utility.calculateTravelTimeHrs(distance, true),8);
			}
		}
		return auditDurations;
	}

	private int[][] getResourceAvailailityMatrix() throws ParseException {
		/* Returns a 2-dimensional array
		 * For each resource
		 *  For each time slot
		 *   -> no. of consecutive slots available.
		 */	
		
		int[][] resourceAvailability = new int[resources.size()+1][getPeriodSlots(period)];
		for(int t = 0; t < resourceAvailability[0].length; t++) {
			// For each time slot
			for (int i = 0; i < resourceAvailability.length-1; i++) {
				// For each resource
				Calendar tomorrow = Calendar.getInstance();
				tomorrow.add(Calendar.DATE, 1);
				Calendar date = getTimeFromSlot(t, period);
				if (date.before(tomorrow)) {
					// Can't schedule in the past !!!
					resourceAvailability[i][t] = 0;
				} else {
					//logger.info("Time slot " + t + " = " + Utility.getMysqldateformat().format(date.getTime()));
					Calendar firstWeekend = Calendar.getInstance();
					firstWeekend.setTime(date.getTime());
					firstWeekend.add(Calendar.DAY_OF_MONTH, Math.max(6-(date.get(Calendar.DAY_OF_WEEK)==1?7:date.get(Calendar.DAY_OF_WEEK)-1),0));
					firstWeekend.set(Calendar.HOUR_OF_DAY, startHourBusinessDay);
					//logger.info("First weekend = " + Utility.getMysqldateformat().format(firstWeekend.getTime()));
					Calendar firstEventAfterDate = Calendar.getInstance(); 
					firstEventAfterDate.setTime(resources.get(i).getCalender().getEvents().stream()
						.filter(e -> e.getEndDateTime().getTime()>date.getTimeInMillis())
						.map(e -> e.getStartDateTime()).min(Date::compareTo).orElse(firstWeekend.getTime()));
					
					//logger.info("First event after date= " + Utility.getMysqldateformat().format(firstEventAfterDate.getTime()));
					if (firstWeekend.before(firstEventAfterDate))
						firstEventAfterDate.setTime(firstWeekend.getTime());
					
					resourceAvailability[i][t] = 0;
					date.add(Calendar.HOUR_OF_DAY, timeSlothours);
					while (date.before(firstEventAfterDate)) {
						//logger.info("Time slot " + t + " = " + Utility.getMysqldateformat().format(date.getTime()));
						if(date.get(Calendar.HOUR_OF_DAY)-timeSlothours>=startHourBusinessDay && date.get(Calendar.HOUR_OF_DAY)<=endHourBusinessDay)
							resourceAvailability[i][t]++;
						date.add(Calendar.HOUR_OF_DAY, timeSlothours);
					}
					//logger.info("Slot available at date = " + resourceAvailability[i][t]);
				}
			}
			resourceAvailability[resourceAvailability.length-1][t] = Integer.MAX_VALUE;
		}
		
		return resourceAvailability;
	}
	
	private double[] getResourceCapacityMatrix() {
		
		HashMap<String, Integer> periodWorkingDays = parameters.getPeriodsWorkingDays();
		double[] resourceCapacity = new double[resources.size()+1];
		
		for (int i = 0; i < resourceCapacity.length-1; i++) {
			// For each resource
			double bopDays = (double) (Math.ceil(resources.get(i).getCalender().getEvents().stream().filter(e -> e.getPeriod().equalsIgnoreCase(period.toString()) && e.getType().equals(ResourceEventType.SF_BOP)).mapToDouble(ResourceEvent::getDurationWorkingDays).sum() * 2) / 2);
			double auditDays = (double) (Math.ceil(resources.get(i).getCalender().getEvents().stream().filter(e -> e.getPeriod().equalsIgnoreCase(period.toString()) && (e.getType().equals(ResourceEventType.ALLOCATOR_WIR)||e.getType().equals(ResourceEventType.SF_WIR)||e.getType().equals(ResourceEventType.ALLOCATOR_TRAVEL))).mapToDouble(ResourceEvent::getDurationWorkingDays).sum() * 2) / 2);
			resourceCapacity[i] = Math.max(((periodWorkingDays.get(period) - bopDays)*resources.get(i).getCapacity()/100 - auditDays)*8,0);				
		}
		resourceCapacity[resourceCapacity.length-1] = infinity;
		
		return resourceCapacity;
	}
	
	private Calendar getTimeFromSlot(int slotNo, String period) throws ParseException {
		Calendar periodC = Calendar.getInstance();
		periodC.setTime(Utility.getPeriodformatter().parse(period));
		return getTimeFromSlot(slotNo, periodC);
	}
	
	private Calendar getTimeFromSlot(int slotNo, Calendar period) {
		Calendar date = Calendar.getInstance();
		date.setTime(period.getTime());
		date.add(Calendar.DAY_OF_MONTH, slotNo/no_of_time_slots_day);
		date.set(Calendar.HOUR_OF_DAY, startHourBusinessDay + (slotNo%no_of_time_slots_day)*timeSlothours);
		return date;
	}
	
	private int getSlotFromTime(Calendar date) throws ParseException {
		Calendar start = Calendar.getInstance();
		start.setTime(Utility.getPeriodformatter().parse(period));
		int daysFromStart = (int) Math.floor((date.getTimeInMillis()-start.getTimeInMillis())/1000/60/60/24);
		return (daysFromStart)*no_of_time_slots_day 
				+ Math.max(date.get(Calendar.HOUR_OF_DAY)-startHourBusinessDay,0)/timeSlothours;
	}
	
	private int getSlotFromTime(Date date) throws ParseException {
		Calendar aux = Calendar.getInstance();
		aux.setTime(date);
		return getSlotFromTime(aux);
	}
	
	private int getPeriodSlots(Calendar period) {
		/* 1 Slot = 1/2 Day
		 * i.e. Period January 2017 
		 * slot 0 = 1/1/17 am
		 * slot 1 = 1/1/17 pm
		 * slot 2 = 2/1/17 am
		 * ...
		 * slot 61 = 31/1/17 pm
		 */
		int no_of_slots = period.getMaximum(Calendar.DAY_OF_MONTH)*2;
		return no_of_slots;
	}
	
	private int getPeriodSlots(Date period) {
		Calendar periodC = Calendar.getInstance();
		periodC.setTime(period);
		return getPeriodSlots(periodC);	
	}
	
	private int getPeriodSlots(String period) throws ParseException {
		Date periodD = Utility.getPeriodformatter().parse(period);
		return getPeriodSlots(periodD);	
	}
	
	private double[][] getCostMatrix() throws Exception {
		
		double[][] costs = new double[resources.size()+1][workItemListBatch.size()];
		
		for (int j = 0; j < workItemListBatch.size(); j++) {
			for (int i = 0; i < resources.size(); i++) {
				costs[i][j] = Utility.calculateAuditCost(resources.get(i), workItemListBatch.get(j), workItemListBatch.get(j),travelCostCalculationType, db, false, true, true);
			}
			// Cost of not performing the audit
			costs[resources.size()][j] = workItemListBatch.get(j).getCostOfNotAllocating();
		}
		
		return costs;
	}

	private List<Schedule> populateSchedule(MPVariable[][][] x) throws Exception {
		List<Schedule> returnSchedule = new ArrayList<Schedule>();
		if(x == null) 
			return returnSchedule;
		
		// The value of each variable in the solution.
		for (int i = 0; i < x.length; i++) {
			for (int j = 0; j < x[0].length; j++) {
				for (int t = 0; t < x[0][0].length; t++) {
					if (x[i][j][t] != null && x[i][j][t].solutionValue()>0) {
						// Initialise Schedule
						List<Schedule> schedules = Schedule.getSchedules(workItemListBatch.get(j));
						
						if (i<x.length-1) {
							// Assigned to actual resource. I.e. Allocated
							workItemListBatch.get(j).setLog(true);
							for (Schedule schedule : schedules) {
								schedule.setResourceId(resources.get(i).getId());
								schedule.setResourceName(resources.get(i).getName());
								schedule.setResourceType(resources.get(i).getType());
								schedule.setStatus(ScheduleStatus.ALLOCATED);
								schedule.setTotalCost(Utility.calculateAuditCost(resources.get(i), workItemListBatch.get(j), workItemListBatch.get(j), travelCostCalculationType, db, false, true, true));
								if (workItemListBatch.get(j).getServiceDeliveryType().equalsIgnoreCase("Off Site"))
									schedule.setDistanceKm(0);
								else
									schedule.setDistanceKm(2*Utility.calculateDistanceKm(workItemListBatch.get(j).getClientSite(), resources.get(i).getHome(), db));
								
								schedule.setTravelDuration(Math.min(Utility.calculateTravelTimeHrs(schedule.getDistanceKm(), true),8));
							}
							
							Schedule travelling = new Schedule(workItemListBatch.get(j));
							travelling.setType(ScheduleType.TRAVEL);
							travelling.setDistanceKm(schedules.get(0).getDistanceKm());
							travelling.setResourceId(schedules.get(0).getResourceId());
							travelling.setResourceName(schedules.get(0).getResourceName());
							travelling.setResourceType(schedules.get(0).getResourceType());
							travelling.setTravelDuration(schedules.get(0).getTravelDuration()/2);
							travelling.setDuration(schedules.get(0).getTravelDuration()/2);
							travelling.setStatus(ScheduleStatus.ALLOCATED);
							travelling.setNotes("Travel from " + resources.get(i).getHome().getCity() + " (" + resources.get(i).getHome().getPostCode() + ")" +" to " + workItemListBatch.get(j).getClientSite().getCity() + " (" + workItemListBatch.get(j).getClientSite().getPostCode() + ")");
							//postProcessTravel(returnSchedule, travelling);
							
							Schedule travellingReturn = new Schedule(workItemListBatch.get(j));
							travellingReturn.setType(ScheduleType.TRAVEL);
							travellingReturn.setDistanceKm(schedules.get(0).getDistanceKm());
							travellingReturn.setResourceId(schedules.get(0).getResourceId());
							travellingReturn.setResourceName(schedules.get(0).getResourceName());
							travellingReturn.setResourceType(schedules.get(0).getResourceType());
							travellingReturn.setTravelDuration(schedules.get(0).getTravelDuration()/2);
							travellingReturn.setDuration(schedules.get(0).getTravelDuration()/2);
							travellingReturn.setStatus(ScheduleStatus.ALLOCATED);
							travellingReturn.setNotes("Travel from " + workItemListBatch.get(j).getClientSite().getCity() + " (" + workItemListBatch.get(j).getClientSite().getPostCode() + ")" +" to " + resources.get(i).getHome().getCity() + " (" + resources.get(i).getHome().getPostCode() + ")");
							//postProcessTravel(returnSchedule, travellingReturn);
							
							// Set Start and End Dates for events
							int slotPointer = t;
							travelling.setStartDate(getTimeFromSlot(slotPointer, period).getTime());
							slotPointer += (int) Math.ceil(travelling.getTravelDuration()/timeSlothours);
							travelling.setEndDate(getTimeFromSlot(slotPointer, period).getTime());
							
							for (Schedule schedule : schedules) {
								schedule.setStartDate(getTimeFromSlot(slotPointer, period).getTime());
								slotPointer += (int) Math.ceil(schedule.getWorkItemDuration()/timeSlothours);
								schedule.setEndDate(getTimeFromSlot(slotPointer, period).getTime());
							}
							travellingReturn.setStartDate(getTimeFromSlot(slotPointer, period).getTime());
							slotPointer += (int) Math.ceil(travelling.getTravelDuration()/timeSlothours);
							travellingReturn.setEndDate(getTimeFromSlot(slotPointer, period).getTime());
							
							// Book resource for audit - One event for each time slot
							Resource resource = resources.get(i);
								
							slotPointer = t + (int) Math.ceil(travelling.getTravelDuration()/timeSlothours);;
							for (Schedule schedule : schedules) {
								for (int t1 = 0; t1 < (int) Math.ceil(schedule.getWorkItemDuration()/timeSlothours); t1++) {
									ResourceEvent eventToBook = new ResourceEvent();
									eventToBook.setType(ResourceEventType.ALLOCATOR_WIR);
									eventToBook.setStartDateTime(getTimeFromSlot(slotPointer, period).getTime());
									slotPointer++;
									eventToBook.setEndDateTime(getTimeFromSlot(slotPointer, period).getTime());
									resource.bookFor(eventToBook);
								}
							}
							// Book resource for travel
							ResourceEvent travelToBook = new ResourceEvent();
							travelToBook.setType(ResourceEventType.ALLOCATOR_TRAVEL);
							travelToBook.setStartDateTime(travelling.getStartDate());
							travelToBook.setEndDateTime(travelling.getEndDate());
							resource.bookFor(travelToBook);

							ResourceEvent travelToBookReturn = new ResourceEvent();
							travelToBookReturn.setType(ResourceEventType.ALLOCATOR_TRAVEL);
							travelToBookReturn.setStartDateTime(travellingReturn.getStartDate());
							travelToBookReturn.setEndDateTime(travellingReturn.getEndDate());
							resource.bookFor(travelToBookReturn);
							
							// Add to return schedule
							if(travelling.getDuration()>0)
								returnSchedule.add(travelling);
							if(travellingReturn.getDuration()>0)
								returnSchedule.add(travellingReturn);
						} else {
							final int j1 = j;
							schedules.stream().forEach(s -> s.setNotes(workItemListBatch.get(j1).getComment()));
							schedules.stream().forEach(s -> s.setTotalCost(workItemListBatch.get(j1).getCostOfNotAllocating()));
						}
						
						// Add unallocated only if needs to be logged.  Unallocated audits moved to next period are not logged to avoid duplications
						if(workItemListBatch.get(j).isLog()) {
							returnSchedule.addAll(schedules);
						}
						
					}
				}
			}
		}
		return scheduleToEvents(returnSchedule);
	}
	
	private List<Schedule> scheduleToEvents(List<Schedule> schedules) throws ParseException {
		List<Schedule> events = new ArrayList<Schedule>();
		for (Schedule schedule : schedules) {
			if (schedule.getStatus().equals(ScheduleStatus.NOT_ALLOCATED)) {
				events.add(schedule);
			} else {
				for(int t = getSlotFromTime(schedule.getStartDate()); t < getSlotFromTime(schedule.getStartDate()) + (int) Math.ceil(schedule.getDuration()/timeSlothours); t++) {
					Schedule event = new Schedule(schedule);
					event.setStartDate(new Date(getTimeFromSlot(t, period).getTimeInMillis()));
					event.setEndDate(new Date(getTimeFromSlot(t, period).getTimeInMillis()+timeSlothours*60*60*1000));
					event.setDuration(timeSlothours);
					events.add(event);
				}
			}
		}
		return events;
	}

	class SolverResult {
		private ResultStatus resultStatus = null;
		private MPVariable[][][] variables = null;
		private MPSolver solver = null;
		
		public ResultStatus getResultStatus() {
			return resultStatus;
		}
		public void setResultStatus(ResultStatus resultStatus) {
			this.resultStatus = resultStatus;
		}
		public MPVariable[][][] getVariables() {
			return variables;
		}
		public void setVariables(MPVariable[][][] variables) {
			this.variables = variables;
		}
		public MPSolver getSolver() {
			return solver;
		}
		public void setSolver(MPSolver solver) {
			this.solver = solver;
		}
		
	}

	@Override
	protected void postProcessWorkItemList() {
		final Calendar start = Calendar.getInstance();
		start.setTime(parameters.getStartDate());
		final Calendar end = Calendar.getInstance();
		end.setTime(parameters.getEndDate());
		
		if(parameters.getBoltOnStandards() != null) {
			for (WorkItem wi : workItemList) {
				if (parameters.getBoltOnStandards().contains(wi.getPrimaryStandard().getCompetencyName())) {
					logger.debug("Found Bolt-On audit " + wi.getName() + " (" + wi.getPrimaryStandard().getCompetencyName() + ")");
					wi.setPrimary(false);
					
					// Find primary wi and add the bolt-on to it
					WorkItem primaryWi = workItemList.stream().filter(wi2 -> 
							wi2.getClientSite().getFullAddress().equalsIgnoreCase(wi.getClientSite().getFullAddress()) && 
							//Utility.getPeriodformatter().format(wi2.getTargetDate()).equalsIgnoreCase(Utility.getPeriodformatter().format(wi.getTargetDate())) &&
							!wi2.getId().equals(wi.getId()))
						.findFirst()
						.orElse(null);
					
					if (primaryWi != null) {
						primaryWi.getLinkedWorkItems().add(wi);
						logger.debug("Added Bolt-On audit " + wi.getName() + " (" + Utility.getActivitydateformatter().format(wi.getTargetDate()) + ") to " + primaryWi.getName() + " (" + Utility.getActivitydateformatter().format(primaryWi.getTargetDate()) + ")");
					} else {
						logger.debug("Could not add Bolt-On audit " + wi.getName() + " (" + Utility.getActivitydateformatter().format(wi.getTargetDate()) + ") to any other audit in scope.");
					}
				}
			}
		}
		
		
		Calendar auxStart = Calendar.getInstance();
		Calendar auxEnd = Calendar.getInstance();
		for (WorkItem wi : workItemList) {
			// Default Audit Window = Target Month
			auxStart.setTime(wi.getTargetDate());
			auxEnd.setTime(wi.getTargetDate());
			auxStart.set(Calendar.DAY_OF_MONTH, 1);
			auxEnd.set(Calendar.DAY_OF_MONTH, auxEnd.getActualMaximum(Calendar.DAY_OF_MONTH));
			
			// Custom audit windows
			if (wi.getPrimaryStandard().getCompetencyName().contains("BRC") && wi.getType().getName().contains("Unannounced")) {
				// Unannounced BRC - Audit window from 4 months before to 1 month before target
				auxStart.add(Calendar.MONTH, -4);
				auxEnd.add(Calendar.MONTH, -1);
			}
			if (wi.getPrimaryStandard().getCompetencyName().contains("McDonalds")) {
				// All McDonalds - 1 month before to 1 month after target
				auxStart.add(Calendar.MONTH, -1);
				auxEnd.add(Calendar.MONTH, 1);
			}
			if (wi.getPrimaryStandard().getCompetencyName().contains("Quality British Turkey")) {
				// Quality British Turkey Processing - 2013 | Certification - 1 month before to 1 month after target
				auxStart.add(Calendar.MONTH, -1);
				auxEnd.add(Calendar.MONTH, 1);
			}
			if (wi.getPrimaryStandard().getCompetencyName().contains("British Quality Assured")) {
				// British Quality Assured Pork, Ham, Sausages - 1 month before to 1 month after target
				auxStart.add(Calendar.MONTH, -1);
				auxEnd.add(Calendar.MONTH, 1);
			}
			if (wi.getPrimaryStandard().getCompetencyName().contains("NACB")) {
				// NACB | Certification - 1 month before to 1 month after target
				auxStart.add(Calendar.MONTH, -1);
				auxEnd.add(Calendar.MONTH, 1);
			}
			if (wi.getPrimaryStandard().getCompetencyName().contains("SAI Safe & Legal")) {
				// SAI Safe & Legal - 1 month before to 1 month after target
				auxStart.add(Calendar.MONTH, -1);
				auxEnd.add(Calendar.MONTH, 1);
			}
			if (wi.getPrimaryStandard().getCompetencyName().contains("TGI")) {
				// TGI - 1 month before to 1 month after target
				auxStart.add(Calendar.MONTH, -1);
				auxEnd.add(Calendar.MONTH, 1);
			}
			if (wi.getPrimaryStandard().getCompetencyName().contains("CDG")) {
				// CDG - 1 month before to 1 month after target
				auxStart.add(Calendar.MONTH, -1);
				auxEnd.add(Calendar.MONTH, 1);
			}
			if (wi.getPrimaryStandard().getCompetencyName().contains("Nomad")) {
				// Nomad - 1 month before to 1 month after target
				auxStart.add(Calendar.MONTH, -1);
				auxEnd.add(Calendar.MONTH, 1);
			}
			if (wi.getPrimaryStandard().getCompetencyName().contains("Subway")) {
				// Subway - 1 month before to 1 month after target
				auxStart.add(Calendar.MONTH, -1);
				auxEnd.add(Calendar.MONTH, 1);
			}
			if (wi.getPrimaryStandard().getCompetencyName().contains("Red Tractor")) {
				// Red Tractor - 1 month before to 1 month after target
				auxStart.add(Calendar.MONTH, -1);
				auxEnd.add(Calendar.MONTH, 1);
			}
			if (wi.getPrimaryStandard().getCompetencyName().contains("West Country Beef")) {
				// West Country Beef - 1 month before to 1 month after target
				auxStart.add(Calendar.MONTH, -1);
				auxEnd.add(Calendar.MONTH, 1);
			}
			
			// Audit Window outside period - override
			if (auxStart.before(start)) 
				auxStart.set(Calendar.MONTH,start.get(Calendar.MONTH));
			if (auxEnd.before(start)) 
				auxEnd.set(Calendar.MONTH,start.get(Calendar.MONTH));
			if (auxStart.after(end)) 
				auxStart.set(Calendar.MONTH,end.get(Calendar.MONTH));
			if (auxEnd.after(end)) 
				auxEnd.set(Calendar.MONTH,end.get(Calendar.MONTH));
			
			wi.setTargetDate(new Date(auxStart.getTimeInMillis()));
			wi.setStartAuditWindow(new Date(auxStart.getTimeInMillis()));
			wi.setEndAuditWindow(new Date(auxEnd.getTimeInMillis()));
			
			wi.setCostOfNotAllocating(cost_of_not_performing);
		}
	}
}
