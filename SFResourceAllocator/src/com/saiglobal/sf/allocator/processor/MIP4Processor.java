package com.saiglobal.sf.allocator.processor;
/*
 * MIP3Processon + A new attempt to solve milk runs 
 */
import java.text.NumberFormat;
import java.text.ParseException;
import java.time.Period;
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

public class MIP4Processor extends AbstractProcessor {
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
	final int timeSlothours = 4;
	final int startHourBusinessDay = 9;
	final int endHourBusinessDay = 17;
	final int milkRunMaxDurationDays = 5;
	int no_of_time_slots_day = Math.floorDiv(endHourBusinessDay-startHourBusinessDay, timeSlothours);
	List<WorkItem> workItemListBatch = null;
	String solverType = null;
	String month = null;
	Calendar startPeriod = null;
	Calendar endPeriod = null;
    int num_audits = 0;
	int num_auditors = 0;
	int num_time_slots = 0;
	
	double[][][] costs = null;
	double[] resource_capacity = null;
	int[][] resource_availability = null;
	double[][][] audit_duration = null;
	TravelCostCalculationType travelCostCalculationType = TravelCostCalculationType.EMPIRICAL_UK;
	
	public MIP4Processor(DbHelper db, ScheduleParameters parameters) throws Exception {
		super(db, parameters);
	}

	@Override
	public void execute() throws Exception {
		
		// Sort workItems
		Utility.startTimeCounter("MIP3Processor.execute");
		workItemList = sortWorkItems(workItemList);
		
		saveBatchDetails(this.parameters);
		// Break processing in sub-groups based on period
		List<String> months = parameters.getPeriodsWorkingDays().keySet().stream().sorted().collect(Collectors.toList());
		for (String aMonth : months) {
			month = aMonth;
			logger.info("Start processing batch " + month + ". Time: " + System.currentTimeMillis());
			for (Calendar local_day : getWorkingDaysInMonth(month)) {
				startPeriod = local_day;
				endPeriod = Calendar.getInstance();
				endPeriod.setTime(startPeriod.getTime());
				endPeriod.add(Calendar.DATE, milkRunMaxDurationDays);
				logger.info("Start processing day " + Utility.getActivitydateformatter().format(startPeriod.getTime()) + ". Time: " + System.currentTimeMillis());
				workItemListBatch = workItemList.stream().filter(wi -> Utility.getActivitydateformatter().format(wi.getTargetDate()).equalsIgnoreCase(Utility.getActivitydateformatter().format(startPeriod.getTime())) && wi.isPrimary()).collect(Collectors.toList());
				if(workItemListBatch.size()==0)
					continue;
				List<Schedule> schedule = scheduleBatch();
				logger.info("Saving schedule for batch " + Utility.getActivitydateformatter().format(startPeriod.getTime()) + ". Time: " + System.currentTimeMillis());
				saveSchedule(schedule);
			}
		}
		updateBatchDetails(this.parameters);
		Utility.stopTimeCounter("MIP3Processor.execute");
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
		return Logger.getLogger(MIP4Processor.class);
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
	
	private double calculateSolutionCost(MPVariable[][][][] x, TravelCostCalculationType travelCostCalculationType) throws Exception {
		
		double totalCost = 0;
		// The value of each variable in the solution.
		for (int i = 0; i < x.length; i++) {
			for (int j = 0; j < x[i].length; j++) {
				for (int jp = 0; jp < x[i][j].length; jp++) {
					for (int t = 0; t < x[i][j][jp].length; t++) {
						if (x[i][j][jp][t] != null && x[i][j][jp][t].solutionValue()>0) {	
							if(i<resources.size()) {
								logger.debug(resources.get(i).getName() + " assigned to audit " + workItemListBatch.get(j).getName() + " to be performed on: " + Utility.getActivitydateformatter().format(getTimeFromSlot(t).getTime()) + (j==jp?"":(" as part of a milk run following audit" + workItemListBatch.get(jp).getName())));
								totalCost += Utility.calculateAuditCost(resources.get(i), workItemListBatch.get(j), workItemListBatch.get(jp), travelCostCalculationType, db, (j!=jp || getFollowingAuditInMilkRun(j, x)==-1), jp==j);
							} else {
								logger.debug("Audit " + workItemListBatch.get(j).getName() + " unallocated");
								//totalCost += workItemListBatch.get(j).getCostOfNotAllocating();
							}
						}	
					}
				}
			}
		}
		return totalCost;
	}
	
	private SolverResult solve(int[][][][] constraints) throws Exception {
		
		boolean timeConstrained = true;
		if(constraints[0][0][0].length==1)
			timeConstrained = false;
		
		// Instantiate a mixed-integer solver
		MPSolver solver = createSolver(solverType);
	    if (solver == null) {
	      logger.error("Could not create solver " + solverType);
	      return null;
	    }
	    
		// Variables
	    logger.debug("MPVariable[constraints.length][constraints[0].length][constraints[0][0].length][constraints[0][0][0].length = " + constraints.length * constraints[0].length * constraints[0][0].length *constraints[0][0][0].length);
		MPVariable[][][][] x = new MPVariable[constraints.length][constraints[0].length][constraints[0][0].length][constraints[0][0][0].length];
		for (int i = 0; i < constraints.length; i++) {
			for (int j = 0; j < constraints[i].length; j++) {
				for (int jp = 0; jp < constraints[i][j].length; jp++) {
					for (int t = 0; t < constraints[i][j][jp].length; t++) {
						if (constraints[i][j][jp][t]==1)
							x[i][j][jp][t] = solver.makeIntVar(0, 1, "x["+i+","+j+","+jp+","+t+"]");
					}
				}
			}
		}
		
		// Constraints
		
		// The total duration of the tasks each worker takes on in a month is at most his/her capacity in the month.
		for (int i = 0; i < constraints.length-1; i++) {
			MPConstraint ct1 = solver.makeConstraint(0, resource_capacity[i]);
			for (int j = 0; j < constraints[i].length; j++) {
				for (int jp = 0; jp < constraints[i][j].length; jp++) {
					for (int t = 0; t < constraints[i][j][jp].length; t++) {
						if (constraints[i][j][jp][t]==1) {
							ct1.setCoefficient(x[i][j][jp][t], audit_duration[i][j][jp]);
							
							// If auditor i* performs audit j* preceded by audit jp* at time t*, then auditor i* has to perform audit jp* at time (t*-audit_duration[i][jp][jp2])
							MPConstraint ct2 = solver.makeConstraint(0, 1);
							ct2.setCoefficient(x[i][j][jp][t], -1);
							for (int jp2 = 0; jp2 < constraints[i][jp].length; jp2++) {
								for (int t2 = 0; t2 < constraints[i][jp][jp2].length; t2++) {
									if (((t-(int)Math.ceil(audit_duration[i][jp][jp2]/timeSlothours)>=0) 
											&& (t2 == t-(int)Math.ceil(audit_duration[i][jp][jp2]/timeSlothours))) 
										|| !timeConstrained)
										ct2.setCoefficient(x[i][jp][jp2][t2], 1);
									else 
										ct2.setCoefficient(x[i][jp][jp2][t2], 0);
								}
							}
						}
					}
				}
			}	
		} 
		
		if(timeConstrained) {
			// The duration of each task each worker takes is at most his/her availability at the time it is taken
			for (int i = 0; i < constraints.length-1; i++) {
				for (int t = 0; t < constraints[i][0][0].length; t++) {
					MPConstraint ct = solver.makeConstraint(0, resource_availability[i][t]*timeSlothours);
					for (int j = 0; j < constraints[i].length; j++) {
						for (int jp = 0; jp < constraints[i][j].length; jp++) {
							if (constraints[i][j][jp][t]==1)
								ct.setCoefficient(x[i][j][jp][t], audit_duration[i][j][jp]);
						}
					}
				}	
			}
			
			// No overlapping jobs
			for (int i = 0; i < constraints.length-1; i++) {
				// For each auditor
				for (int j = 0; j < constraints[i].length; j++) {
					for (int jp = 0; jp < constraints[i][j].length; jp++) {
						for (int t = 0; t < constraints[i][j][jp].length; t++) {
							if (constraints[i][j][jp][t]==1) {
								// For each audit j preceded by audit jp starting at time t ...
								int audit_duration_timeslots = (int) Math.ceil(audit_duration[i][j][jp]/timeSlothours);
								// ... there are no other audit j2 starting at t+s; for each 0 < s < audit_duration_timeslots
								for (int s = 0; s < audit_duration_timeslots; s++) {
									MPConstraint ct = solver.makeConstraint(0, 1);
									ct.setCoefficient(x[i][j][jp][t], 1);
									if (t+s<num_time_slots) {
										for (int j2 = 0; j2 < constraints[i].length; j2++) {
											for (int jp2 = 0; jp2 < constraints[i][j2].length; jp2++) {
												if(j2!=j && constraints[i][j2][jp2][t+s]==1) {
													ct.setCoefficient(x[i][j2][jp2][t+s], 1);
												}
											}
										}
									}
								}
							}
						}
					}
				}			
			}
		}
		
		// Each task is assigned to one worker in one time slot only and preceded by one audit only.
		for (int j = 0; j < constraints[0].length; j++) {
			MPConstraint ct = solver.makeConstraint(1, 1);
			for (int i = 0; i < constraints.length; i++) {
				for (int jp = 0; jp < constraints[i][j].length; jp++) {
					for (int t = 0; t < constraints[i][j][jp].length; t++) {
						if (constraints[i][j][jp][t]==1)
							ct.setCoefficient(x[i][j][jp][t], 1);
					}
				}
			}
		}
		
		// Objective: Minimise total cost
		MPObjective objective = solver.objective();
		for (int i = 0; i < constraints.length; i++) {
			for (int j = 0; j < constraints[i].length; j++) {
				for (int jp = 0; jp < constraints[i][j].length; jp++) {
					for (int t = 0; t < constraints[i][j][jp].length; t++) {
						if (constraints[i][j][jp][t]==1)
							objective.setCoefficient(x[i][j][jp][t], costs[i][j][jp]);
					}
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
		
		logger.info("Problem solved in " + solver.wallTime() + " milliseconds");
		logger.info("No. interations : " + solver.iterations());
		logger.info("Problem solved in " + solver.nodes() + " branch-and-bound nodes");
		logger.info("Optimal objective value = " + currencyFormatter.format(solver.objective().value()));
		//logger.info("Total cost: " + currencyFormatter.format(calculateSolutionCost(x, travelCostCalculationType)));
		
		SolverResult sr = new SolverResult();
		sr.setSolver(solver);
		sr.setResultStatus(resultStatus);
		sr.setVariables(x);
		sr.setCostAllocated(calculateSolutionCost(x, travelCostCalculationType));
		
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
		num_time_slots = getPeriodSlots();
		
		resource_capacity = getResourceCapacityMatrix();
		resource_availability = getResourceAvailailityMatrix();
		audit_duration = getAuditDurationMatrix();
	}
	
	private int[][][][] presolve() {
		/*
		 * Presolving. The purpose of presolving, which takes place
		 * before the tree search is started, is threefold: first, it reduces 
		 * the size of the model by removing irrelevant information 
		 * such as redundant constraints or fixed variables.
		 */

		int[][][][] constraints = new int[num_auditors][num_audits][num_audits][num_time_slots];
		for (int i = 0; i < num_auditors; i++) {
			for (int j = 0; j < num_audits; j++) {
				boolean cannotPerform = (i<(num_auditors-1)) && !resources.get(i).canPerform(workItemListBatch.get(j));
				for (int jp = 0; jp < num_audits; jp++) {
					// Excludes auditors not capable of performing the audit
					if(!parameters.isMilkRuns() && j!=jp) {
						// If not doing milk runs excludes all j!=jp
						for (int t = 0; t < num_time_slots; t++) {
							constraints[i][j][jp][t] = 0;
						}
					} else {
						if (cannotPerform) {
							for (int t = 0; t < num_time_slots; t++) {
								constraints[i][j][jp][t] = 0;
							}
						} else {
							boolean cannotPerformjp = (i<(num_auditors-1)) && !resources.get(i).canPerform(workItemListBatch.get(jp));
							boolean heuristicExcludeAsNotGoodCandidateForMilkRun = false;
							
							if(!cannotPerform) {
								double distanceJToJp = Double.MAX_VALUE;
								double distanceHomeToJ = Double.MAX_VALUE;
								double distanceHomeToJp = Double.MAX_VALUE;
								try {
									distanceJToJp = Utility.calculateDistanceKm(workItemListBatch.get(j).getClientSite(), workItemListBatch.get(jp).getClientSite(), db);
								} catch (Exception e) {
									//Ignore.  Use default
								}
								try {
									distanceHomeToJp = Utility.calculateDistanceKm(resources.get(i).getHome(), workItemListBatch.get(jp).getClientSite(), db);
								} catch (Exception e) {
									//Ignore.  Use default
								}
								if(distanceJToJp>=distanceHomeToJp) {
									heuristicExcludeAsNotGoodCandidateForMilkRun = true;
								} else {
									try {
										distanceHomeToJ = Utility.calculateDistanceKm(resources.get(i).getHome(), workItemListBatch.get(j).getClientSite(), db);
									} catch (Exception e) {
										//Ignore.  Use default
									}
									double travelTime = Utility.calculateTravelTimeHrs(distanceHomeToJ, false);
									if (travelTime==0 && j!=jp) {
										// If travel time between auditor and audit is 0 (i.e. done within normal duty), the audit cannot be part of a milk run for this auditor at any time
										heuristicExcludeAsNotGoodCandidateForMilkRun = true;
									}
								}
							}
							
							for (int t = 0; t < num_time_slots; t++) {
								if (cannotPerformjp || heuristicExcludeAsNotGoodCandidateForMilkRun) {
									// Excludes auditors not capable of performing the previous audit or previous audit is not a good candidate for milk run
									constraints[i][j][jp][t] = 0;
								} else {
									double jpMinDuration = Arrays.stream(audit_duration[i][jp]).min().orElse(0);
									
									if (i<num_auditors-1 
										&& (
											(t - (int) Math.ceil(jpMinDuration)/timeSlothours<0)
											|| (resource_availability[i][t]<Math.ceil(audit_duration[i][j][jp]/timeSlothours))
											|| (resource_availability[i][t - (int) Math.ceil(jpMinDuration)/timeSlothours]<Math.ceil(jpMinDuration/timeSlothours)))) {
										// Exclude not available dates either for audit j starting at t or preceding audit jp starting at (t - (int) Math.ceil(jpMinDuration)/timeSlothours) 
										constraints[i][j][jp][t] = 0;
									} else {
										// Deafult
										constraints[i][j][jp][t] = 1;
									}
								}
							}
						}
					}
				}
			}
		}
		// TODO: Exclude assignments which will lead to auditor being away for longer than X days
		return constraints;
	}
	
	protected List<Schedule> scheduleBatch() throws Exception {
		
		initBatchVariables();		
		
		int[][][][] constraints = presolve();
		
		// Solve relaxed problem excluding time slots constraints to find a lower bound (LB)
		int[][][][] relaxedConstraints = new int[constraints.length][constraints[0].length][constraints[0][0].length][1];
		for (int i = 0; i < relaxedConstraints.length; i++) {
			for (int j = 0; j < relaxedConstraints[i].length; j++) {
				for (int jp = 0; jp < relaxedConstraints[i][j].length; jp++) {
					if (Arrays.stream(constraints[i][j][jp]).sum()>0) 
						relaxedConstraints[i][j][jp][0] = 1;
					else
						relaxedConstraints[i][j][jp][0] = 0;
				}
			}
		}
		SolverResult srRelaxed = solve(relaxedConstraints);
		ResultStatus resultStatusRelaxed = srRelaxed.getResultStatus();
		MPVariable[][][][] xRelaxed = srRelaxed.getVariables();
		double lowerBound = -1;
		
		// Check that the problem has an optimal solution.
		if (resultStatusRelaxed != MPSolver.ResultStatus.OPTIMAL) {
			logger.error("Could not find an optimal solution to the relaxed problem in the time limit of " + maxExecTime/1000/60 + " minutes");
		} else {
			lowerBound = srRelaxed.getSolver().objective().value();
			logger.info("Found LB of cost: " + currencyFormatter.format(lowerBound));// + " (" + currencyFormatter.format(calculateSolutionCost(xRelaxed, travelCostCalculationType)) +")");
		}
		
		SolverResult sr = null;
		ResultStatus resultStatus = null;
		MPVariable[][][][] x = null;
		double obj = Double.MAX_VALUE;
		
		// Solve full problem
		sr = solve(constraints);
		resultStatus = sr.getResultStatus();
		obj = sr.getSolver().objective().value();
		
		if (resultStatus.equals(MPSolver.ResultStatus.OPTIMAL)) {
			x = sr.getVariables();
			logger.info("Found optimal Solution with objective value of " + currencyFormatter.format(obj) + " (" + currencyFormatter.format(calculateSolutionCost(x, travelCostCalculationType)) +")");
		}
		
		if (resultStatus.equals(MPSolver.ResultStatus.FEASIBLE)) {
			x = sr.getVariables();
			if(lowerBound>0) 
				logger.info("Found feasable solution with objective value of " + currencyFormatter.format(obj) + " vs lower bound of " + currencyFormatter.format(lowerBound) + " (+" + percentFormatter.format((obj-lowerBound)/lowerBound) + ")");
			else
				logger.info("Found feasable solution with objective value of " + currencyFormatter.format(obj));
		}
		
		// Move unallocated to next period within target.
		Calendar auxStart = Calendar.getInstance();
		Calendar auxEnd = Calendar.getInstance();
		for (WorkItem wi : getUnallocated(x)) {
			WorkItem wil = getWorkItemFromList(wi.getId());
			if(resources.stream().filter(r -> r.canPerform(wil)).count()>0) {
				auxStart =  getNextWorkingDay(wil.getTargetDate());
				auxEnd.setTimeInMillis(wil.getEndAuditWindow().getTime());
				if (auxStart.before(auxEnd)) {
					logger.debug("Moving unallocated audit " + wil.getName() + " from " + Utility.getActivitydateformatter().format(wil.getTargetDate()) + " to " + Utility.getActivitydateformatter().format(auxStart.getTime()));
					wil.setTargetDate(new Date(auxStart.getTimeInMillis()));
					wil.setCostOfNotAllocating(wil.getCostOfNotAllocating()+cost_of_not_performing);
					wil.setLog(false);
				} else {
					wil.setLog(true);
					wil.setComment("Not allocated due to missing availability");
					logger.debug("Cannot allocate audit " + wil.getName() + " and cannot move to next period (" + Utility.getActivitydateformatter().format(auxStart.getTime()) + ") as it is outside the audit window end date (" + Utility.getActivitydateformatter().format(wil.getEndAuditWindow()) + ")");
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
	
	private Calendar getNextWorkingDay(Date day) {
		Calendar nextWorkingDay = Calendar.getInstance();
		nextWorkingDay.setTime(day);
		while (true) {
			nextWorkingDay.add(Calendar.DATE, 1);
			if (nextWorkingDay.get(Calendar.DAY_OF_WEEK) != Calendar.SATURDAY && nextWorkingDay.get(Calendar.DAY_OF_WEEK) != Calendar.SUNDAY)
				return nextWorkingDay;
		}
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
	
	private List<WorkItem> getUnallocated(MPVariable[][][][] x) {
		List<WorkItem> unallocated = new ArrayList<WorkItem>();
	
		if (x == null)
			return unallocated;
		for (int j = 0; j < x[0].length; j++) {
			if (Arrays.stream(x[x.length-1][j]).flatMap(x1 -> Arrays.stream(x1)).mapToInt(t -> t==null?0:(int)t.solutionValue()).sum()>0) {
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
	
	private double[][][] getAuditDurationMatrix() {
		double[][][] auditDurations = new double[resources.size()+1][workItemListBatch.size()][workItemListBatch.size()];
		for (int i = 0; i <= resources.size(); i++) {
			for (int j = 0; j < workItemListBatch.size(); j++) {
				for (int jp = 0; jp < workItemListBatch.size(); jp++) {					
					double distance = 0;
					if (!workItemListBatch.get(j).getServiceDeliveryType().equalsIgnoreCase("Off Site")) {
						try {
							if(j==jp) {
								distance = Utility.calculateDistanceKm(workItemListBatch.get(j).getClientSite(), resources.get(i).getHome(), db);
							} else {
								distance = Utility.calculateDistanceKm(workItemListBatch.get(jp).getClientSite(), workItemListBatch.get(j).getClientSite(), db);
							}
						} catch (Exception e) {
							// Assume infinite distance
							distance = Double.MAX_VALUE;
						}
					}
				auditDurations[i][j][jp] = 
						workItemListBatch.get(j).getRequiredDuration()
						+ workItemListBatch.get(j).getLinkedWorkItems().stream().mapToInt(wi -> (int) Math.ceil(wi.getRequiredDuration())).sum()
						// Cap travel time to 1/2 day each way in the UK
						+ Math.min(Utility.calculateTravelTimeHrs(distance, false),4);
				}
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
		
		int[][] resourceAvailability = new int[resources.size()+1][getPeriodSlots()];
		for(int t = 0; t < resourceAvailability[0].length; t++) {
			// For each time slot
			for (int i = 0; i < resourceAvailability.length-1; i++) {
				// For each resource
				Calendar tomorrow = Calendar.getInstance();
				tomorrow.add(Calendar.DATE, 1);
				Calendar date = getTimeFromSlot(t);
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
	
	private int getPeriodsWorkingDays() throws Exception {
		int periodWorkingDays = 0;
		Calendar aux = Calendar.getInstance();
		aux.setTime(startPeriod.getTime());
		while (aux.before(endPeriod)) {
			if(aux.get(Calendar.DAY_OF_WEEK)!=Calendar.SATURDAY && aux.get(Calendar.DAY_OF_WEEK)!=Calendar.SUNDAY)
				periodWorkingDays++;
			aux.add(Calendar.DATE, 1);
		}
		
		return periodWorkingDays;
	}
	
	private double[] getResourceCapacityMatrix() throws Exception {
		
		int periodWorkingDays = getPeriodsWorkingDays();
		double[] resourceCapacity = new double[resources.size()+1];
		
		for (int i = 0; i < resourceCapacity.length-1; i++) {
			// For each resource
			double bopDays = (double) (Math.ceil(resources.get(i).getCalender().getEvents().stream().filter(e -> e.getCalendarDate().after(startPeriod) && e.getCalendarDate().before(endPeriod) && e.getType().equals(ResourceEventType.SF_BOP)).mapToDouble(ResourceEvent::getDurationWorkingDays).sum() * 2) / 2);
			double auditDays = (double) (Math.ceil(resources.get(i).getCalender().getEvents().stream().filter(e -> e.getCalendarDate().after(startPeriod) && e.getCalendarDate().before(endPeriod) && (e.getType().equals(ResourceEventType.ALLOCATOR_WIR)||e.getType().equals(ResourceEventType.SF_WIR)||e.getType().equals(ResourceEventType.ALLOCATOR_TRAVEL))).mapToDouble(ResourceEvent::getDurationWorkingDays).sum() * 2) / 2);
			resourceCapacity[i] = Math.max(((periodWorkingDays - bopDays)*resources.get(i).getCapacity()/100 - auditDays)*8,0);				
		}
		resourceCapacity[resourceCapacity.length-1] = infinity;
		
		return resourceCapacity;
	}
	
	private Calendar getTimeFromSlot(int slotNo) {
		Calendar aux= Calendar.getInstance();
		aux.setTime(startPeriod.getTime());
		aux.add(Calendar.DAY_OF_MONTH, slotNo/no_of_time_slots_day);
		aux.set(Calendar.HOUR_OF_DAY, startHourBusinessDay + (slotNo%no_of_time_slots_day)*timeSlothours);
		return aux;
	}
	
	private int getSlotFromTime(Calendar date) throws ParseException {
		int daysFromStart = (int) Math.floor((date.getTimeInMillis()-startPeriod.getTimeInMillis())/1000/60/60/24);
		return (daysFromStart)*no_of_time_slots_day 
				+ Math.max(date.get(Calendar.HOUR_OF_DAY)-startHourBusinessDay,0)/timeSlothours;
	}
	
	private int getSlotFromTime(Date date) throws ParseException {
		Calendar aux = Calendar.getInstance();
		aux.setTime(date);
		return getSlotFromTime(aux);
	}
	
	private int getPeriodSlots() {
		return milkRunMaxDurationDays*2;
	}
	
	private Calendar[] getWorkingDaysInMonth(String period) throws Exception {
		List<Calendar> days = new ArrayList<Calendar>();
		Calendar aux = Calendar.getInstance();
		Calendar endPeriod = Calendar.getInstance();
		aux.setTime(Utility.getPeriodformatter().parse(period));
		endPeriod.setTime(aux.getTime());
		endPeriod.add(Calendar.MONTH, 1);
		while (aux.before(endPeriod)) {
			if (aux.get(Calendar.DAY_OF_WEEK) != Calendar.SATURDAY && aux.get(Calendar.DAY_OF_WEEK) != Calendar.SUNDAY) {
				Calendar aux2 = Calendar.getInstance();
				aux2.setTime(aux.getTime());
				days.add(aux2);
			}
			aux.add(Calendar.DATE, 1);
		}
		return days.toArray(new Calendar[days.size()]);
	}
	
	private double[][][] getCostMatrix() throws Exception {
		
		double[][][] costs = new double[resources.size()+1][workItemListBatch.size()][workItemListBatch.size()];
		
		for (int j = 0; j < workItemListBatch.size(); j++) {
			for (int jp = 0; jp < workItemListBatch.size(); jp++) {
				for (int i = 0; i < resources.size(); i++) {
					double distance = Double.MAX_VALUE;
					if (j==jp)
						distance = Utility.calculateDistanceKm(workItemListBatch.get(j).getClientSite(), resources.get(i).getHome(), db);
					else
						distance = Utility.calculateDistanceKm(workItemListBatch.get(jp).getClientSite(), workItemListBatch.get(j).getClientSite(), db);
					// At this point I do not know if the audit is the last in the milk run.  However, if we minimise the one way travel cost, we minimise the return travel cost.
					costs[i][j][jp] = Utility.calculateAuditCost(resources.get(i).getType(), resources.get(i).getHourlyRate(), workItemListBatch.get(j).getRequiredDuration() + workItemListBatch.get(j).getLinkedWorkItems().stream().mapToInt(wi -> (int) Math.ceil(wi.getRequiredDuration())).sum(), distance, travelCostCalculationType,  true, jp==j, workItemListBatch.get(j).isPrimary());
				}
				// Cost of not performing the audit
				costs[resources.size()][j][jp] = workItemListBatch.get(j).getCostOfNotAllocating();
			}
		}
		
		return costs;
	}

	private int getPreviousAuditInMilkRun(int currentAudit, MPVariable[][][][] solution) {
		for (int i = 0; i < solution.length; i++) 
			for (int jp = 0; jp < solution[0].length; jp++) 
					for (int t = 0; t < solution[0][0][0].length; t++) 
						if (solution[i][currentAudit][jp][t] != null && solution[i][currentAudit][jp][t].solutionValue()>0) 
							return jp;
		return -1; // This is an error. Every audit should have a predecessor. Even if itself.
	}
	
	private int getFollowingAuditInMilkRun(int currentAudit, MPVariable[][][][] solution) {
		for (int i = 0; i < solution.length; i++) 
			for (int j = 0; j < solution[0].length; j++) 
					for (int t = 0; t < solution[0][0][0].length; t++) 
						if (solution[i][j][currentAudit][t] != null && solution[i][j][currentAudit][t].solutionValue()>0) 
							return j;
		return -1; // Last Audit in milk run
	}
	
	private int getFirstAuditInMilkRun(int anAudit, MPVariable[][][][] solution) {
		int previousAudit = getPreviousAuditInMilkRun(anAudit, solution);
		if(previousAudit == anAudit)
			return anAudit;
		else 
			return getPreviousAuditInMilkRun(previousAudit, solution);
	}
	
	private String getMilkRunId(int anAudit, MPVariable[][][][] solution) {
		return workItemListBatch.get(getFirstAuditInMilkRun(anAudit, solution)).getId();
	}
	
	private List<Schedule> populateSchedule(MPVariable[][][][] x) throws Exception {
		List<Schedule> returnSchedule = new ArrayList<Schedule>();
		if(x == null) 
			return returnSchedule;
		
		// The value of each variable in the solution.
		for (int i = 0; i < x.length; i++) {
			for (int j = 0; j < x[0].length; j++) {
				for (int jp = 0; jp < x[0][0].length; jp++) {
					for (int t = 0; t < x[0][0][0].length; t++) {
						if (x[i][j][jp][t] != null && x[i][j][jp][t].solutionValue()>0) {
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
									schedule.setWorkItemGroup(getMilkRunId(j,x));
									schedule.setTotalCost(Utility.calculateAuditCost(resources.get(i), workItemListBatch.get(j), workItemListBatch.get(jp), travelCostCalculationType, db, (j!=jp || getFollowingAuditInMilkRun(j, x)!=-1 ), j==jp));
									if (workItemListBatch.get(j).getServiceDeliveryType().equalsIgnoreCase("Off Site"))
										schedule.setDistanceKm(0);
									else
										if (j==jp)
											schedule.setDistanceKm(Utility.calculateDistanceKm(workItemListBatch.get(j).getClientSite(), resources.get(i).getHome(), db));
										else
											schedule.setDistanceKm(Utility.calculateDistanceKm(workItemListBatch.get(jp).getClientSite(), workItemListBatch.get(j).getClientSite(), db));
									
									schedule.setTravelDuration(Math.min(Utility.calculateTravelTimeHrs(schedule.getDistanceKm(), false),4));
								}
								
								Schedule travelling = new Schedule(workItemListBatch.get(j));
								travelling.setType(ScheduleType.TRAVEL);
								travelling.setDistanceKm(schedules.get(0).getDistanceKm());
								travelling.setResourceId(schedules.get(0).getResourceId());
								travelling.setResourceName(schedules.get(0).getResourceName());
								travelling.setResourceType(schedules.get(0).getResourceType());
								travelling.setTravelDuration(schedules.get(0).getTravelDuration());
								travelling.setDuration(schedules.get(0).getTravelDuration());
								travelling.setStatus(ScheduleStatus.ALLOCATED);
								if (j==jp)
									travelling.setNotes("Travel from " + resources.get(i).getHome().getCity() + " (" + resources.get(i).getHome().getPostCode() + ")" +" to " + workItemListBatch.get(j).getClientSite().getCity() + " (" + workItemListBatch.get(j).getClientSite().getPostCode() + ")");
								else 
									travelling.setNotes("Travel from " + workItemListBatch.get(jp).getClientSite().getCity() + " (" + workItemListBatch.get(jp).getClientSite().getPostCode() + ")" +" to " + workItemListBatch.get(j).getClientSite().getCity() + " (" + workItemListBatch.get(j).getClientSite().getPostCode() + ")");
								//postProcessTravel(returnSchedule, travelling);
								
								Schedule travellingReturn = new Schedule(workItemListBatch.get(j));
								travellingReturn.setType(ScheduleType.TRAVEL);
								travellingReturn.setResourceId(schedules.get(0).getResourceId());
								travellingReturn.setResourceName(schedules.get(0).getResourceName());
								travellingReturn.setResourceType(schedules.get(0).getResourceType());
								travellingReturn.setStatus(ScheduleStatus.ALLOCATED);
								if (getFollowingAuditInMilkRun(jp, x)<0) {
									// This is the last audit in the milk run. Add travel return home.
									travellingReturn.setDistanceKm(Utility.calculateDistanceKm(workItemListBatch.get(j).getClientSite(), resources.get(i).getHome(), db));
									travellingReturn.setTravelDuration(Math.min(Utility.calculateTravelTimeHrs(travellingReturn.getDistanceKm(), false),4));
									travellingReturn.setDuration(travellingReturn.getTravelDuration());
								} else {
									travellingReturn.setDistanceKm(0);
									travellingReturn.setTravelDuration(0);
									travellingReturn.setDuration(0);
								}
								
								//postProcessTravel(returnSchedule, travellingReturn);
								// Set Start and End Dates for events
								int slotPointer = t;
								travelling.setStartDate(getTimeFromSlot(slotPointer).getTime());
								slotPointer += (int) Math.ceil(travelling.getTravelDuration()/timeSlothours);
								travelling.setEndDate(getTimeFromSlot(slotPointer).getTime());
								
								for (Schedule schedule : schedules) {
									schedule.setStartDate(getTimeFromSlot(slotPointer).getTime());
									slotPointer += (int) Math.ceil(schedule.getWorkItemDuration()/timeSlothours);
									schedule.setEndDate(getTimeFromSlot(slotPointer).getTime());
								}
								travellingReturn.setStartDate(getTimeFromSlot(slotPointer).getTime());
								slotPointer += (int) Math.ceil(travelling.getTravelDuration()/timeSlothours);
								travellingReturn.setEndDate(getTimeFromSlot(slotPointer).getTime());
								
								// Book resource for audit - One event for each time slot
								Resource resource = resources.get(i);
									
								slotPointer = t + (int) Math.ceil(travelling.getTravelDuration()/timeSlothours);;
								for (Schedule schedule : schedules) {
									for (int t1 = 0; t1 < (int) Math.ceil(schedule.getWorkItemDuration()/timeSlothours); t1++) {
										ResourceEvent eventToBook = new ResourceEvent();
										eventToBook.setType(ResourceEventType.ALLOCATOR_WIR);
										eventToBook.setStartDateTime(getTimeFromSlot(slotPointer).getTime());
										slotPointer++;
										eventToBook.setEndDateTime(getTimeFromSlot(slotPointer).getTime());
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
							}
							
							// Add unallocated only if needs to be logged.  Unallocated audits moved to next period are not logged to avoid duplications
							if(workItemListBatch.get(j).isLog()) {
								for (Schedule schedule : schedules) {
									schedule.setTotalCost(workItemListBatch.get(j).getCostOfNotAllocating());
								}
								returnSchedule.addAll(schedules);
							}
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
					event.setStartDate(new Date(getTimeFromSlot(t).getTimeInMillis()));
					event.setEndDate(new Date(getTimeFromSlot(t).getTimeInMillis()+timeSlothours*60*60*1000));
					event.setDuration(timeSlothours);
					events.add(event);
				}
			}
		}
		return events;
	}

	class SolverResult {
		private ResultStatus resultStatus = null;
		private MPVariable[][][][] variables = null;
		private MPSolver solver = null;
		private double costAllocated = 0;
		
		public ResultStatus getResultStatus() {
			return resultStatus;
		}
		public void setResultStatus(ResultStatus resultStatus) {
			this.resultStatus = resultStatus;
		}
		public MPVariable[][][][] getVariables() {
			return variables;
		}
		public void setVariables(MPVariable[][][][] variables) {
			this.variables = variables;
		}
		public MPSolver getSolver() {
			return solver;
		}
		public void setSolver(MPSolver solver) {
			this.solver = solver;
		}
		public double getCostAllocated() {
			return costAllocated;
		}
		public void setCostAllocated(double costAllocated) {
			this.costAllocated = costAllocated;
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
