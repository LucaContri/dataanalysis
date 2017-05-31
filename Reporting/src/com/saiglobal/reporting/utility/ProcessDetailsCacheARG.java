package com.saiglobal.reporting.utility;

import java.sql.ResultSet;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;
import java.util.TimeZone;
import java.util.concurrent.Semaphore;

import org.apache.commons.lang.StringUtils;

import com.saiglobal.reporting.model.Performance;
import com.saiglobal.reporting.model.Process;
import com.saiglobal.reporting.model.ProcessDetails;
import com.saiglobal.reporting.model.ProcessPerformances;
import com.saiglobal.reporting.model.ProcessQueue;
import com.saiglobal.reporting.model.Queue;
import com.saiglobal.sf.core.data.DbHelper;
import com.saiglobal.sf.core.utility.Utility;

public class ProcessDetailsCacheARG {

	private static final SimpleDateFormat periodFormatter = new SimpleDateFormat("MMM yy");
	private DbHelper db = null;
	private static ProcessDetailsCacheARG reference = null;
	private Calendar lastUpdatedProcessTable;
	private int refreshIntervalHours = 24;
	private Semaphore update = new Semaphore(1);
	private static final TimeZone utc = TimeZone.getTimeZone("UTC");
	private ProcessDetailsCacheARG(DbHelper db) {
		this.db = db;
	}
	
	public static ProcessDetailsCacheARG getInstance(DbHelper db) {
		if (reference == null)
			reference = new ProcessDetailsCacheARG(db);
		
		return reference;
	}
	
	public ProcessDetails getProcessDetails(Process process, List<String> standardsIds, List<String> clientOwnerships, List<String> resourcesIds, List<String> tags, boolean forceRefresh) throws Exception {
		// Check refresh process table
		Calendar intervalBefore = Calendar.getInstance();
		intervalBefore.add(Calendar.HOUR, -refreshIntervalHours);
		
		try {
			update.acquire();
			if(lastUpdatedProcessTable == null || lastUpdatedProcessTable.before(intervalBefore) || forceRefresh) {
				refreshProcessTable();
				lastUpdatedProcessTable = Calendar.getInstance();
			}
		} catch (Exception e) {
			throw e;
		} finally {
			update.release();
		}
		ProcessDetails processDetails = new ProcessDetails(process.name());
		switch (process) {
			case ARG:
				processDetails.performances.add(getWorkItemsFinishedToARGSubmitted(standardsIds, clientOwnerships, resourcesIds,tags));
				processDetails.performances.add(getARGSubmittedToARGApproved(standardsIds, clientOwnerships, resourcesIds,tags));
				processDetails.performances.add(getARGApprovedToARGCompletedOrOnHold(standardsIds, clientOwnerships, resourcesIds,tags));
				processDetails.performances.add(getWorkItemsFinishedToARGCompletedOrOnHold(standardsIds, clientOwnerships, resourcesIds,tags));
				processDetails.performances.get(0).name = "Auditors";
				processDetails.performances.get(1).name = "PRC";
				processDetails.performances.get(2).name = "Admin";
				break;
			case AUDITORS:
				processDetails.queues.add(getWorkItemsFinishedNotSubmitted(standardsIds, clientOwnerships, resourcesIds,tags));
				processDetails.queues.add(getWorkItemsSubmittedNoARG(standardsIds, clientOwnerships, resourcesIds,tags));
				processDetails.queues.add(getARGRejectedToBeResubmitted(standardsIds, clientOwnerships, resourcesIds,tags));
				processDetails.queues.add(getWorkItemsSubmittedARGPending(standardsIds, clientOwnerships, resourcesIds,tags));
				processDetails.performances.add(getWorkItemsFinishedToARGSubmitted(standardsIds, clientOwnerships, resourcesIds,tags));
				break;
			case PRC:
				processDetails.queues.add(getARGSubmittedNotTaken(standardsIds, clientOwnerships, resourcesIds,tags));
				processDetails.queues.add(getARGTakenNotReviewed(standardsIds, clientOwnerships, resourcesIds,tags));
				processDetails.performances.add(getARGSubmittedToARGApproved(standardsIds, clientOwnerships, resourcesIds,tags));
				processDetails.performances.add(getARGSubmittedToARGApprovedWithRejections(standardsIds, clientOwnerships, resourcesIds,tags));
				processDetails.performances.add(getARGSubmittedToARGApprovedWithTA(standardsIds, clientOwnerships, resourcesIds,tags));
				break;
			case TR:
				break;	
			case ADMIN:
				processDetails.queues.add(getARGApprovedNotAdminAssigned(standardsIds, clientOwnerships, resourcesIds,tags));
				processDetails.queues.add(getARGAdminAssignedNotCompleted(standardsIds, clientOwnerships, resourcesIds,tags));
				processDetails.performances.add(getARGApprovedToARGCompletedOrOnHold(standardsIds, clientOwnerships, resourcesIds,tags));
				break;
			default:
				break;
		}
		processDetails.lastUpdated = getLastUpdated();
		return processDetails;
	}
	
	// OVERALL PERFORMANCES
	private ProcessPerformances getWorkItemsFinishedToARGCompletedOrOnHold(List<String> standards, List<String> clientOwnerships, List<String> resources, List<String> tags) throws Exception {
		SimpleDateFormat mysqlDateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
		ProcessPerformances performance = new ProcessPerformances(Performance.WI_FINISHED_TO_ARG_COMPLETED_OR_HOLD.getName(), "ARG", "Days", "Period", 14.0, 0.99);
		performance.reportSlaOnly = true;
		List<String> optionalFilters = new ArrayList<String>();
		optionalFilters.add("t.type = 'Performance'");
		optionalFilters.add("t.Name = '" + Performance.WI_FINISHED_TO_ARG_COMPLETED_OR_HOLD+ "'");
		String query = "select concat('<a href=\"https://na14.salesforce.com/', t.`Record Id`, '\" target=\"_blank\">',t.`Record Name`,'</a>') as 'ARG', t.`Client Ownership`, t.`From` as 'WI Finished (UTC)', t.`To` as 'ARG Completed/OnHold (UTC)', t.`Duration`, t.`Owner`, t.`Executed By` as 'Author' "
				+ "from sf_business_process_details t " 
				+ getWhereClause(standards, clientOwnerships, resources, optionalFilters, tags)
				+ " order by `ARG Completed/OnHold (UTC)`";
		
		ResultSet rs = db.executeSelect(query, -1);
		performance.details = Utility.resultSetToObjectArray(rs, true);
		double powerSum1 = 0;
		double powerSum2 = 0;
		List<Double> avgs = new ArrayList<Double>();
		List<Double> stdDevs = new ArrayList<Double>();
		List<Integer> qtys = new ArrayList<Integer>();
		List<Integer> withinSLAs = new ArrayList<Integer>();
		List<String> groups = new ArrayList<String>();
		double avg = 0.0;
		double stdDev = 0.0;
		int qty = 0;
		int withinSLA = 0;
		String group = null;
		
		rs.beforeFirst();
		while (rs.next()) {
			String period = periodFormatter.format(mysqlDateFormat.parse(rs.getString("ARG Completed/OnHold (UTC)")));
			if (group == null)
				group = period;
			
			if (!period.equalsIgnoreCase(group)) {
				if(Double.isNaN(stdDev))
					stdDev = 0;
				avgs.add(avg);
				stdDevs.add(stdDev);
				qtys.add(qty);
				withinSLAs.add(withinSLA);
				groups.add(group);
				group = period;
				withinSLA = 0;
				qty = 0;
				stdDev = 0;
				avg = 0;
			}
			
		    powerSum1 += rs.getDouble("Duration");
		    avg = (avg*qty + rs.getDouble("Duration"))/(qty+1);
		    powerSum2 += Math.pow(rs.getDouble("Duration"), 2);
		    stdDev = Math.sqrt(qty*powerSum2 - Math.pow(powerSum1, 2))/qty;
		    if ((rs.getDouble("Duration")-Utility.calculateWeekendDays(mysqlDateFormat.parse(rs.getString("WI Finished (UTC)")), mysqlDateFormat.parse(rs.getString("ARG Completed/OnHold (UTC)")), utc))<=performance.SLA)
		    	withinSLA++;
		    qty++;
		}
		// Add Last
		if(Double.isNaN(stdDev))
			stdDev = 0;
		avgs.add(avg);
		stdDevs.add(stdDev);
		qtys.add(qty);
		withinSLAs.add(withinSLA);
		groups.add(group);
		
		performance.group = new String[groups.size()];
		performance.avg = new double[groups.size()];
		performance.stdDev = new double[groups.size()];
		performance.quantity= new int[groups.size()];
		performance.withinSLA = new int[groups.size()];
		for (int i = 0; i < groups.size(); i++) {
			performance.group[i] = groups.get(i);
			performance.avg[i] = avgs.get(i);
			performance.stdDev[i] = stdDevs.get(i);
			performance.quantity[i] = qtys.get(i);
			performance.withinSLA[i] = withinSLAs.get(i);
		}
		
		return performance;
	}
	
	// ADMIN QUEUES
	private ProcessQueue getARGApprovedNotAdminAssigned(List<String> standards, List<String> clientOwnerships, List<String> resources, List<String> tags) throws Exception {
		ProcessQueue queue = new ProcessQueue(Queue.ARG_APPROVED_NOT_ASSIGNED_ADMIN.getName(), "ARG", "Days");
		List<String> optionalFilters = new ArrayList<String>();
		optionalFilters.add("t.type = 'Queue'");
		optionalFilters.add("t.Name = '" + Queue.ARG_APPROVED_NOT_ASSIGNED_ADMIN + "'");
		String query = "select concat('<a href=\"https://na14.salesforce.com/', t.`Record Id`, '\" target=\"_blank\">',t.`Record Name`,'</a>') as 'ARG', t.`Client Ownership`, t.`From` as 'Approved (UTC)', t.`Duration` as 'Aging', t.`Owner` as 'Author' "
				+ "from sf_business_process_details t " 
				+ getWhereClause(standards, clientOwnerships, resources, optionalFilters, tags);
		
		ResultSet rs = db.executeSelect(query, -1);
		queue.details = Utility.resultSetToObjectArray(rs, true);
		double powerSum1 = 0;                                      
		double powerSum2 = 0;
		queue.agingAvg = 0;
		queue.agingStdDev = 0;
		queue.quantity = 0;
		
		rs.beforeFirst();
		while (rs.next()) {
		    powerSum1 += rs.getDouble("Aging");
		    queue.agingAvg = (queue.agingAvg*queue.quantity + rs.getDouble("Aging"))/(queue.quantity+1);
		    powerSum2 += Math.pow(rs.getDouble("Aging"), 2);
		    queue.agingStdDev = Math.sqrt(queue.quantity*powerSum2 - Math.pow(powerSum1, 2))/queue.quantity;
		    queue.quantity++;
		}
		if(Double.isNaN(queue.agingStdDev))
			queue.agingStdDev = 0;
		
		return queue;
	}
	
	private ProcessQueue getARGAdminAssignedNotCompleted(List<String> standards, List<String> clientOwnerships, List<String> resources, List<String> tags) throws Exception {
		ProcessQueue queue = new ProcessQueue(Queue.ARG_ASSIGNED_ADMIN_NOT_COMPLETED.getName(), "ARG", "Days");
		List<String> optionalFilters = new ArrayList<String>();
		optionalFilters.add("t.type = 'Queue'");
		optionalFilters.add("t.Name = '" + Queue.ARG_ASSIGNED_ADMIN_NOT_COMPLETED + "'");
		String query = "select concat('<a href=\"https://na14.salesforce.com/', t.`Record Id`, '\" target=\"_blank\">',t.`Record Name`,'</a>') as 'ARG', t.`Client Ownership`, t.`From` as 'Assigned (UTC)', t.`Duration` as 'Aging', t.`Owner` as 'Author', t.`Executed By` as 'Assigned Admin' "
				+ "from sf_business_process_details t " 
				+ getWhereClause(standards, clientOwnerships, resources, optionalFilters, tags);
		
		ResultSet rs = db.executeSelect(query, -1);
		queue.details = Utility.resultSetToObjectArray(rs, true);
		double powerSum1 = 0;                                      
		double powerSum2 = 0;
		queue.agingAvg = 0;
		queue.agingStdDev = 0;
		queue.quantity = 0;
		
		rs.beforeFirst();
		while (rs.next()) {
		    powerSum1 += rs.getDouble("Aging");
		    queue.agingAvg = (queue.agingAvg*queue.quantity + rs.getDouble("Aging"))/(queue.quantity+1);
		    powerSum2 += Math.pow(rs.getDouble("Aging"), 2);
		    queue.agingStdDev = Math.sqrt(queue.quantity*powerSum2 - Math.pow(powerSum1, 2))/queue.quantity;
		    queue.quantity++;
		}
		if(Double.isNaN(queue.agingStdDev))
			queue.agingStdDev = 0;
		
		return queue;
	}
	
	// ADMIN PERFORMANCES
	private ProcessPerformances getARGApprovedToARGCompletedOrOnHold(List<String> standards, List<String> clientOwnerships, List<String> resources, List<String> tags) throws Exception {
		SimpleDateFormat mysqlDateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
		ProcessPerformances performance = new ProcessPerformances(Performance.ARG_APPROVED_TO_ARG_COMPLETED_OR_HOLD.getName(), "ARG", "Days", "Period", 2.0, 0.99);
		
		List<String> optionalFilters = new ArrayList<String>();
		optionalFilters.add("t.type = 'Performance'");
		optionalFilters.add("t.Name = '" + Performance.ARG_APPROVED_TO_ARG_COMPLETED_OR_HOLD + "'");
		String query = "select concat('<a href=\"https://na14.salesforce.com/', t.`Record Id`, '\" target=\"_blank\">',t.`Record Name`,'</a>') as 'ARG', t.`Client Ownership`, t.`From` as 'ARG Approved (UTC)', t.`To` as 'ARG Completed/OnHold (UTC)', t.`Duration`, t.`Owner` as 'Author', t.`Executed By` as 'Assigned Admin' "
				+ "from sf_business_process_details t " 
				+ getWhereClause(standards, clientOwnerships, resources, optionalFilters, tags)
				+ " order by `ARG Completed/OnHold (UTC)`";
		
		ResultSet rs = db.executeSelect(query, -1);
		performance.details = Utility.resultSetToObjectArray(rs, true);
		double powerSum1 = 0;
		double powerSum2 = 0;
		List<Double> avgs = new ArrayList<Double>();
		List<Double> stdDevs = new ArrayList<Double>();
		List<Integer> qtys = new ArrayList<Integer>();
		List<Integer> withinSLAs = new ArrayList<Integer>();
		List<String> groups = new ArrayList<String>();
		double avg = 0.0;
		double stdDev = 0.0;
		int qty = 0;
		int withinSLA = 0;
		String group = null;
		
		
		rs.beforeFirst();
		while (rs.next()) {
			String period = periodFormatter.format(mysqlDateFormat.parse(rs.getString("ARG Completed/OnHold (UTC)")));
			if (group == null)
				group = period;
			
			if (!period.equalsIgnoreCase(group)) {
				if(Double.isNaN(stdDev))
					stdDev = 0;
				avgs.add(avg);
				stdDevs.add(stdDev);
				qtys.add(qty);
				withinSLAs.add(withinSLA);
				groups.add(group);
				group = period;
				qty = 0;
				withinSLA = 0;
				stdDev = 0;
				avg = 0;
			}
			
		    powerSum1 += rs.getDouble("Duration");
		    avg = (avg*qty + rs.getDouble("Duration"))/(qty+1);
		    powerSum2 += Math.pow(rs.getDouble("Duration"), 2);
		    stdDev = Math.sqrt(qty*powerSum2 - Math.pow(powerSum1, 2))/qty;
		    if ((rs.getDouble("Duration")-Utility.calculateWeekendDays(mysqlDateFormat.parse(rs.getString("ARG Approved (UTC)")), mysqlDateFormat.parse(rs.getString("ARG Completed/OnHold (UTC)")), utc))<=performance.SLA)
		    	withinSLA++;
		    qty++;
		}
		
		// Add Last
		if(Double.isNaN(stdDev))
			stdDev = 0;
		avgs.add(avg);
		stdDevs.add(stdDev);
		qtys.add(qty);
		withinSLAs.add(withinSLA);
		groups.add(group);
		
		performance.group = new String[groups.size()];
		performance.avg = new double[groups.size()];
		performance.stdDev = new double[groups.size()];
		performance.quantity = new int[groups.size()];
		performance.withinSLA = new int[groups.size()];
		for (int i = 0; i < groups.size(); i++) {
			performance.group[i] = groups.get(i);
			performance.avg[i] = avgs.get(i);
			performance.stdDev[i] = stdDevs.get(i);
			performance.quantity[i] = qtys.get(i);
			performance.withinSLA[i] = withinSLAs.get(i);
		}
		return performance;
	}
	
	// PRC QUEUES
	private ProcessQueue getARGSubmittedNotTaken(List<String> standards, List<String> clientOwnerships, List<String> resources, List<String> tags) throws Exception {
		ProcessQueue queue = new ProcessQueue(Queue.ARG_SUBMITTED_NOT_TAKEN.getName(), "ARG", "Days");
		List<String> optionalFilters = new ArrayList<String>();
		optionalFilters.add("t.type = 'Queue'");
		optionalFilters.add("t.Name = '" + Queue.ARG_SUBMITTED_NOT_TAKEN + "'");
		String query = "select concat('<a href=\"https://na14.salesforce.com/', t.`Record Id`, '\" target=\"_blank\">',t.`Record Name`,'</a>') as 'ARG', t.`Client Ownership`, t.`From` as 'ARG Submitted (UTC)', t.`Duration` as 'Aging', t.`Owner` as 'Author' "
				+ "from sf_business_process_details t " 
				+ getWhereClause(standards, clientOwnerships, resources, optionalFilters, tags);
		
		ResultSet rs = db.executeSelect(query, -1);
		queue.details = Utility.resultSetToObjectArray(rs, true);
		double powerSum1 = 0;
		double powerSum2 = 0;
		queue.agingAvg = 0;
		queue.agingStdDev = 0;
		queue.quantity = 0;
		
		rs.beforeFirst();
		while (rs.next()) {
		    powerSum1 += rs.getDouble("Aging");
		    queue.agingAvg = (queue.agingAvg*queue.quantity + rs.getDouble("Aging"))/(queue.quantity+1);
		    powerSum2 += Math.pow(rs.getDouble("Aging"), 2);
		    queue.agingStdDev = Math.sqrt(queue.quantity*powerSum2 - Math.pow(powerSum1, 2))/queue.quantity;
		    queue.quantity++;
		}
		if(Double.isNaN(queue.agingStdDev))
			queue.agingStdDev = 0;
		return queue;
	}
	
	private ProcessQueue getARGTakenNotReviewed(List<String> standards, List<String> clientOwnerships, List<String> resources, List<String> tags) throws Exception {
		ProcessQueue queue = new ProcessQueue(Queue.ARG_TAKEN_NOT_REVIEWED.getName(), "ARG", "Days");
		List<String> optionalFilters = new ArrayList<String>();
		optionalFilters.add("t.type = 'Queue'");
		optionalFilters.add("t.Name = '" + Queue.ARG_TAKEN_NOT_REVIEWED + "'");
		String query = "select concat('<a href=\"https://na14.salesforce.com/', t.`Record Id`, '\" target=\"_blank\">',t.`Record Name`,'</a>') as 'ARG', t.`Client Ownership`, t.`From` as 'ARG Taken (UTC)', t.`Duration` as 'Aging', t.`Owner` as 'Author', t.`Executed By` as 'Certification Approver' "
				+ "from sf_business_process_details t " 
				+ getWhereClause(standards, clientOwnerships, resources, optionalFilters, tags);
		
		ResultSet rs = db.executeSelect(query, -1);
		queue.details = Utility.resultSetToObjectArray(rs, true);
		double powerSum1 = 0;
		double powerSum2 = 0;
		queue.agingAvg = 0;
		queue.agingStdDev = 0;
		queue.quantity = 0;
		
		rs.beforeFirst();
		while (rs.next()) {
		    powerSum1 += rs.getDouble("Aging");
		    queue.agingAvg = (queue.agingAvg*queue.quantity + rs.getDouble("Aging"))/(queue.quantity+1);
		    powerSum2 += Math.pow(rs.getDouble("Aging"), 2);
		    queue.agingStdDev = Math.sqrt(queue.quantity*powerSum2 - Math.pow(powerSum1, 2))/queue.quantity;
		    queue.quantity++;
		}
		if(Double.isNaN(queue.agingStdDev))
			queue.agingStdDev = 0;
		return queue;
	}
	
	// PRC PERFORMANCES
	private ProcessPerformances getARGSubmittedToARGApproved(List<String> standards, List<String> clientOwnerships, List<String> resources, List<String> tags) throws Exception {
		SimpleDateFormat mysqlDateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
		ProcessPerformances performance = new ProcessPerformances(Performance.ARG_SUBMITTED_TO_ARG_APPROVED.getName(), "ARG", "Days", "Period", 2.0, 0.99);
		
		List<String> optionalFilters = new ArrayList<String>();
		optionalFilters.add("t.type = 'Performance'");
		optionalFilters.add("t.Name = '" + Performance.ARG_SUBMITTED_TO_ARG_APPROVED + "'");
		String query = "select concat('<a href=\"https://na14.salesforce.com/', t.`Record Id`, '\" target=\"_blank\">',t.`Record Name`,'</a>') as 'ARG', t.`Client Ownership`, t.`From` as 'ARG Submitted (UTC)', t.`To` as 'ARG Approved (UTC)', t.`Duration`, t.`Owner` as 'Author', t.`Executed By` as 'Certification Approver' "
				+ "from sf_business_process_details t " 
				+ getWhereClause(standards, clientOwnerships, resources, optionalFilters, tags)
				+ " order by `ARG Approved (UTC)`";
		
		ResultSet rs = db.executeSelect(query, -1);
		performance.details = Utility.resultSetToObjectArray(rs, true);
		double powerSum1 = 0;
		double powerSum2 = 0;
		List<Double> avgs = new ArrayList<Double>();
		List<Double> stdDevs = new ArrayList<Double>();
		List<Integer> qtys = new ArrayList<Integer>();
		List<Integer> withinSLAs = new ArrayList<Integer>();
		List<String> groups = new ArrayList<String>();
		double avg = 0.0;
		double stdDev = 0.0;
		int qty = 0;
		int withinSLA = 0;
		String group = null;
		
		
		rs.beforeFirst();
		while (rs.next()) {
			String period = periodFormatter.format(mysqlDateFormat.parse(rs.getString("ARG Approved (UTC)")));
			if (group == null)
				group = period;
			
			if (!period.equalsIgnoreCase(group)) {
				if(Double.isNaN(stdDev))
					stdDev = 0;
				avgs.add(avg);
				stdDevs.add(stdDev);
				qtys.add(qty);
				withinSLAs.add(withinSLA);
				groups.add(group);
				group = period;
				qty = 0;
				withinSLA = 0;
				stdDev = 0;
				avg = 0;
			}
			
		    powerSum1 += rs.getDouble("Duration");
		    avg = (avg*qty + rs.getDouble("Duration"))/(qty+1);
		    powerSum2 += Math.pow(rs.getDouble("Duration"), 2);
		    stdDev = Math.sqrt(qty*powerSum2 - Math.pow(powerSum1, 2))/qty;
		    if ((rs.getDouble("Duration")-Utility.calculateWeekendDays(mysqlDateFormat.parse(rs.getString("ARG Submitted (UTC)")), mysqlDateFormat.parse(rs.getString("ARG Approved (UTC)")), utc))<=performance.SLA)
		    	withinSLA++;
		    qty++;
		}
		
		// Add Last
		if(Double.isNaN(stdDev))
			stdDev = 0;
		avgs.add(avg);
		stdDevs.add(stdDev);
		qtys.add(qty);
		withinSLAs.add(withinSLA);
		groups.add(group);
		
		performance.group = new String[groups.size()];
		performance.avg = new double[groups.size()];
		performance.stdDev = new double[groups.size()];
		performance.quantity= new int[groups.size()];
		performance.withinSLA = new int[groups.size()];
		for (int i = 0; i < groups.size(); i++) {
			performance.group[i] = groups.get(i);
			performance.avg[i] = avgs.get(i);
			performance.stdDev[i] = stdDevs.get(i);
			performance.quantity[i] = qtys.get(i);
			performance.withinSLA[i] = withinSLAs.get(i);
		}
		return performance;
	}
	
	private ProcessPerformances getARGSubmittedToARGApprovedWithRejections(List<String> standards, List<String> clientOwnerships, List<String> resources, List<String> tags) throws Exception {
		SimpleDateFormat mysqlDateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
		ProcessPerformances performance = new ProcessPerformances(Performance.ARG_SUBMITTED_TO_ARG_APPROVED_WITH_REJECTION.getName(), "ARG", "Days", "Period", 2.0, 0.99);
		List<String> optionalFilters = new ArrayList<String>();
		optionalFilters.add("t.type = 'Performance'");
		optionalFilters.add("t.Name = '" + Performance.ARG_SUBMITTED_TO_ARG_APPROVED_WITH_REJECTION + "'");
		String query = "select concat('<a href=\"https://na14.salesforce.com/', t.`Record Id`, '\" target=\"_blank\">',t.`Record Name`,'</a>') as 'ARG', t.`Client Ownership`, t.`From` as 'ARG Submitted (UTC)', t.`To` as 'ARG Approved (UTC)', t.`Duration`, t.`Owner` as 'Author', t.`Executed By` as 'Certification Approver' "
				+ "from sf_business_process_details t " 
				+ getWhereClause(standards, clientOwnerships, resources, optionalFilters, tags)
				+ " order by `ARG Approved (UTC)`";
		
		ResultSet rs = db.executeSelect(query, -1);
		performance.details = Utility.resultSetToObjectArray(rs, true);
		double powerSum1 = 0;
		double powerSum2 = 0;
		List<Double> avgs = new ArrayList<Double>();
		List<Double> stdDevs = new ArrayList<Double>();
		List<Integer> qtys = new ArrayList<Integer>();
		List<String> groups = new ArrayList<String>();
		double avg = 0.0;
		double stdDev = 0.0;
		int qty = 0;
		String group = null;
		
		
		rs.beforeFirst();
		while (rs.next()) {
			String period = periodFormatter.format(mysqlDateFormat.parse(rs.getString("ARG Approved (UTC)")));
			if (group == null)
				group = period;
			
			if (!period.equalsIgnoreCase(group)) {
				if(Double.isNaN(stdDev))
					stdDev = 0;
				avgs.add(avg);
				stdDevs.add(stdDev);
				qtys.add(qty);
				groups.add(group);
				group = period;
				qty = 0;
				stdDev = 0;
				avg = 0;
			}
			
		    powerSum1 += rs.getDouble("Duration");
		    avg = (avg*qty + rs.getDouble("Duration"))/(qty+1);
		    powerSum2 += Math.pow(rs.getDouble("Duration"), 2);
		    stdDev = Math.sqrt(qty*powerSum2 - Math.pow(powerSum1, 2))/qty;
		    qty++;
		}
		
		// Add Last
		if(Double.isNaN(stdDev))
			stdDev = 0;
		avgs.add(avg);
		stdDevs.add(stdDev);
		qtys.add(qty);
		groups.add(group);
		
		performance.group = new String[groups.size()];
		performance.avg = new double[groups.size()];
		performance.stdDev = new double[groups.size()];
		performance.quantity= new int[groups.size()];
		for (int i = 0; i < groups.size(); i++) {
			performance.group[i] = groups.get(i);
			performance.avg[i] = avgs.get(i);
			performance.stdDev[i] = stdDevs.get(i);
			performance.quantity[i] = qtys.get(i);
		}
		return performance;
	}
	
	private ProcessPerformances getARGSubmittedToARGApprovedWithTA(List<String> standards, List<String> clientOwnerships, List<String> resources, List<String> tags) throws Exception {
		SimpleDateFormat mysqlDateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
		ProcessPerformances performance = new ProcessPerformances(Performance.ARG_SUBMITTED_TO_ARG_APPROVED_WITH_TA.getName(), "ARG", "Days", "Period", 2.0, 0.99);
		List<String> optionalFilters = new ArrayList<String>();
		optionalFilters.add("t.type = 'Performance'");
		optionalFilters.add("t.Name = '" + Performance.ARG_SUBMITTED_TO_ARG_APPROVED_WITH_TA + "'");
		String query = "select concat('<a href=\"https://na14.salesforce.com/', t.`Record Id`, '\" target=\"_blank\">',t.`Record Name`,'</a>') as 'ARG', t.`Client Ownership`, t.`From` as 'ARG Submitted (UTC)', t.`To` as 'ARG Approved (UTC)', t.`Duration`, t.`Owner` as 'Author', t.`Executed By` as 'Certification Approver' "
				+ "from sf_business_process_details t " 
				+ getWhereClause(standards, clientOwnerships, resources, optionalFilters, tags)
				+ " order by `ARG Approved (UTC)`";
		
		ResultSet rs = db.executeSelect(query, -1);
		performance.details = Utility.resultSetToObjectArray(rs, true);
		double powerSum1 = 0;
		double powerSum2 = 0;
		List<Double> avgs = new ArrayList<Double>();
		List<Double> stdDevs = new ArrayList<Double>();
		List<Integer> qtys = new ArrayList<Integer>();
		List<String> groups = new ArrayList<String>();
		double avg = 0.0;
		double stdDev = 0.0;
		int qty = 0;
		String group = null;
		
		
		rs.beforeFirst();
		while (rs.next()) {
			String period = periodFormatter.format(mysqlDateFormat.parse(rs.getString("ARG Approved (UTC)")));
			if (group == null)
				group = period;
			
			if (!period.equalsIgnoreCase(group)) {
				if(Double.isNaN(stdDev))
					stdDev = 0;
				avgs.add(avg);
				stdDevs.add(stdDev);
				qtys.add(qty);
				groups.add(group);
				group = period;
				qty = 0;
				stdDev = 0;
				avg = 0;
			}
			
		    powerSum1 += rs.getDouble("Duration");
		    avg = (avg*qty + rs.getDouble("Duration"))/(qty+1);
		    powerSum2 += Math.pow(rs.getDouble("Duration"), 2);
		    stdDev = Math.sqrt(qty*powerSum2 - Math.pow(powerSum1, 2))/qty;
		    qty++;
		}
		
		// Add Last
		if(Double.isNaN(stdDev))
			stdDev = 0;
		avgs.add(avg);
		stdDevs.add(stdDev);
		qtys.add(qty);
		groups.add(group);
				
		performance.group = new String[groups.size()];
		performance.avg = new double[groups.size()];
		performance.stdDev = new double[groups.size()];
		performance.quantity= new int[groups.size()];
		for (int i = 0; i < groups.size(); i++) {
			performance.group[i] = groups.get(i);
			performance.avg[i] = avgs.get(i);
			performance.stdDev[i] = stdDevs.get(i);
			performance.quantity[i] = qtys.get(i);
		}
		return performance;
	}
	
	// AUDITORS QUEUES
	private ProcessQueue getWorkItemsSubmittedARGPending(List<String> standards, List<String> clientOwnerships, List<String> resources, List<String> tags) throws Exception {
		ProcessQueue queue = new ProcessQueue(Queue.WI_SUBMITTED_ARG_PENDING.getName(), "Work Item", "Days");
		List<String> optionalFilters = new ArrayList<String>();
		optionalFilters.add("t.type = 'Queue'");
		optionalFilters.add("t.Name = '" + Queue.WI_SUBMITTED_ARG_PENDING + "'");
		String query = "select concat('<a href=\"https://na14.salesforce.com/', t.`Record Id`, '\" target=\"_blank\">',t.`Record Name`,'</a>') as 'ARG', t.`Client Ownership`, t.`From` as 'ARG Created (UTC)', t.`Duration` as 'Aging', t.`Owner` "
				+ "from sf_business_process_details t " 
				+ getWhereClause(standards, clientOwnerships, resources, optionalFilters, tags);
		
		ResultSet rs = db.executeSelect(query, -1);
		queue.details = Utility.resultSetToObjectArray(rs, true);
		double powerSum1 = 0;
		double powerSum2 = 0;
		queue.agingAvg = 0;
		queue.agingStdDev = 0;
		queue.quantity = 0;
		
		rs.beforeFirst();
		while (rs.next()) {
		    powerSum1 += rs.getDouble("Aging");
		    queue.agingAvg = (queue.agingAvg*queue.quantity + rs.getDouble("Aging"))/(queue.quantity+1);
		    powerSum2 += Math.pow(rs.getDouble("Aging"), 2);
		    queue.agingStdDev = Math.sqrt(queue.quantity*powerSum2 - Math.pow(powerSum1, 2))/queue.quantity;
		    queue.quantity++;
		}
		if(Double.isNaN(queue.agingStdDev))
			queue.agingStdDev = 0;
		return queue;
	}
	
	private ProcessQueue getWorkItemsFinishedNotSubmitted(List<String> standards, List<String> clientOwnerships, List<String> resources, List<String> tags) throws Exception {
		ProcessQueue queue = new ProcessQueue(Queue.WI_FINISHED_NOT_SUBMMITTED.getName(), "Work Item", "Days");
		List<String> optionalFilters = new ArrayList<String>();
		optionalFilters.add("t.type = 'Queue'");
		optionalFilters.add("t.Name = '" + Queue.WI_FINISHED_NOT_SUBMMITTED + "'");
		String query = "select concat('<a href=\"https://na14.salesforce.com/', t.`Record Id`, '\" target=\"_blank\">',t.`Record Name`,'</a>') as 'Work Item', t.`Client Ownership`, t.`From` as 'WI Finished (UTC)', t.`Duration` as 'Aging', t.`Owner` "
				+ "from sf_business_process_details t " 
				+ getWhereClause(standards, clientOwnerships, resources, optionalFilters, tags);
		
		ResultSet rs = db.executeSelect(query, -1);
		queue.details = Utility.resultSetToObjectArray(rs, true);
		double powerSum1 = 0;
		double powerSum2 = 0;
		queue.agingAvg = 0;
		queue.agingStdDev = 0;
		queue.quantity = 0;
		
		rs.beforeFirst();
		while (rs.next()) {
		    powerSum1 += rs.getDouble("Aging");
		    queue.agingAvg = (queue.agingAvg*queue.quantity + rs.getDouble("Aging"))/(queue.quantity+1);
		    powerSum2 += Math.pow(rs.getDouble("Aging"), 2);
		    queue.agingStdDev = Math.sqrt(queue.quantity*powerSum2 - Math.pow(powerSum1, 2))/queue.quantity;
		    queue.quantity++;
		}
		if(Double.isNaN(queue.agingStdDev))
			queue.agingStdDev = 0;
		return queue;
	}
	
	private ProcessQueue getWorkItemsSubmittedNoARG(List<String> standards, List<String> clientOwnerships, List<String> resources, List<String> tags) throws Exception {
		ProcessQueue queue = new ProcessQueue(Queue.WI_SUBMITTED_WITHOUT_ARG.getName(), "Work Item", "Days");
		List<String> optionalFilters = new ArrayList<String>();
		optionalFilters.add("t.type = 'Queue'");
		optionalFilters.add("t.Name = '" + Queue.WI_SUBMITTED_WITHOUT_ARG + "'");
		String query = "select concat('<a href=\"https://na14.salesforce.com/', t.`Record Id`, '\" target=\"_blank\">',t.`Record Name`,'</a>') as 'Work Item', t.`Client Ownership`, t.`From` as 'WI Finished (UTC)', t.`Duration` as 'Aging', t.`Owner` "
				+ "from sf_business_process_details t " 
				+ getWhereClause(standards, clientOwnerships, resources, optionalFilters, tags);
		
		ResultSet rs = db.executeSelect(query, -1);
		queue.details = Utility.resultSetToObjectArray(rs, true);
		double powerSum1 = 0;
		double powerSum2 = 0;
		queue.agingAvg = 0;
		queue.agingStdDev = 0;
		queue.quantity = 0;
		
		rs.beforeFirst();
		while (rs.next()) {
		    powerSum1 += rs.getDouble("Aging");
		    queue.agingAvg = (queue.agingAvg*queue.quantity + rs.getDouble("Aging"))/(queue.quantity+1);
		    powerSum2 += Math.pow(rs.getDouble("Aging"), 2);
		    queue.agingStdDev = Math.sqrt(queue.quantity*powerSum2 - Math.pow(powerSum1, 2))/queue.quantity;
		    queue.quantity++;
		}
		if(Double.isNaN(queue.agingStdDev))
			queue.agingStdDev = 0;
		
		return queue;
	}
	
	private ProcessQueue getARGRejectedToBeResubmitted(List<String> standards, List<String> clientOwnerships, List<String> resources, List<String> tags) throws Exception {
		ProcessQueue queue = new ProcessQueue(Queue.ARG_REJECTED_TO_BE_RESUBMITTED.getName(), "Work Item", "Days");
		List<String> optionalFilters = new ArrayList<String>();
		optionalFilters.add("t.type = 'Queue'");
		optionalFilters.add("t.Name = '" + Queue.ARG_REJECTED_TO_BE_RESUBMITTED + "'");
		String query = "select concat('<a href=\"https://na14.salesforce.com/', t.`Record Id`, '\" target=\"_blank\">',t.`Record Name`,'</a>') as 'ARG', t.`Client Ownership`, t.`From` as 'Rejected', t.`Duration` as 'Aging (Days)', t.`Owner` as 'Author' "
				+ "from sf_business_process_details t " 
				+ getWhereClause(standards, clientOwnerships, resources, optionalFilters, tags);
		
		ResultSet rs = db.executeSelect(query, -1);
		queue.details = Utility.resultSetToObjectArray(rs, true);
		double powerSum1 = 0;
		double powerSum2 = 0;
		queue.agingAvg = 0;
		queue.agingStdDev = 0;
		queue.quantity = 0;
		
		rs.beforeFirst();
		while (rs.next()) {
		    powerSum1 += rs.getDouble("Aging (Days)");
		    queue.agingAvg = (queue.agingAvg*queue.quantity + rs.getDouble("Aging (Days)"))/(queue.quantity+1);
		    powerSum2 += Math.pow(rs.getDouble("Aging (Days)"), 2);
		    queue.agingStdDev = Math.sqrt(queue.quantity*powerSum2 - Math.pow(powerSum1, 2))/queue.quantity;
		    queue.quantity++;
		}
		if(Double.isNaN(queue.agingStdDev))
			queue.agingStdDev = 0;
		
		return queue;
	}
	
	// AUDITORS PERFORMANCES
	private ProcessPerformances getWorkItemsFinishedToARGSubmitted(List<String> standards, List<String> clientOwnerships, List<String> resources, List<String> tags) throws Exception {
		SimpleDateFormat mysqlDateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
		ProcessPerformances performance = new ProcessPerformances(Performance.WI_FINISHED_TO_ARG_SUBMMITTED.getName(), "ARG", "Days", "Period", 5.0, 0.99);
		List<String> optionalFilters = new ArrayList<String>();
		optionalFilters.add("t.type = 'Performance'");
		optionalFilters.add("t.Name = '" + Performance.WI_FINISHED_TO_ARG_SUBMMITTED + "'");
		String query = "select concat('<a href=\"https://na14.salesforce.com/', t.`Record Id`, '\" target=\"_blank\">',t.`Record Name`,'</a>') as 'ARG', t.`Client Ownership`, t.`From` as 'WI Finished (UTC)', t.`To` as 'ARG Submitted (UTC)', t.`Duration`, t.`Owner`, t.`Executed By` as 'Author' "
				+ "from sf_business_process_details t " 
				+ getWhereClause(standards, clientOwnerships, resources, optionalFilters, tags)
				+ " order by `ARG Submitted (UTC)`";
		
		
		ResultSet rs = db.executeSelect(query, -1);
		performance.details = Utility.resultSetToObjectArray(rs, true);
		double powerSum1 = 0;
		double powerSum2 = 0;
		List<Double> avgs = new ArrayList<Double>();
		List<Double> stdDevs = new ArrayList<Double>();
		List<Integer> qtys = new ArrayList<Integer>();
		List<Integer> withinSLAs = new ArrayList<Integer>();
		List<String> groups = new ArrayList<String>();
		double avg = 0.0;
		double stdDev = 0.0;
		int qty = 0;
		int withinSLA = 0;
		String group = null;
		
		rs.beforeFirst();
		while (rs.next()) {
			String period = periodFormatter.format(mysqlDateFormat.parse(rs.getString("ARG Submitted (UTC)")));
			if (group == null)
				group = period;
			
			if (!period.equalsIgnoreCase(group)) {
				if(Double.isNaN(stdDev))
					stdDev = 0;
				avgs.add(avg);
				stdDevs.add(stdDev);
				qtys.add(qty);
				withinSLAs.add(withinSLA);
				groups.add(group);
				group = period;
				withinSLA = 0;
				qty = 0;
				stdDev = 0;
				avg = 0;
			}
			
		    powerSum1 += rs.getDouble("Duration");
		    avg = (avg*qty + rs.getDouble("Duration"))/(qty+1);
		    powerSum2 += Math.pow(rs.getDouble("Duration"), 2);
		    stdDev = Math.sqrt(qty*powerSum2 - Math.pow(powerSum1, 2))/qty;
		    if ((rs.getDouble("Duration")-Utility.calculateWeekendDays(mysqlDateFormat.parse(rs.getString("WI Finished (UTC)")), mysqlDateFormat.parse(rs.getString("ARG Submitted (UTC)")), utc))<=performance.SLA)
			    withinSLA++;
		    qty++;
		}
		// Add Last
		if(Double.isNaN(stdDev))
			stdDev = 0;
		avgs.add(avg);
		stdDevs.add(stdDev);
		qtys.add(qty);
		withinSLAs.add(withinSLA);
		groups.add(group);
		
		performance.group = new String[groups.size()];
		performance.avg = new double[groups.size()];
		performance.stdDev = new double[groups.size()];
		performance.quantity= new int[groups.size()];
		performance.withinSLA = new int[groups.size()];
		for (int i = 0; i < groups.size(); i++) {
			performance.group[i] = groups.get(i);
			performance.avg[i] = avgs.get(i);
			performance.stdDev[i] = stdDevs.get(i);
			performance.quantity[i] = qtys.get(i);
			performance.withinSLA[i] = withinSLAs.get(i);
		}
		
		return performance;
	}
		
	// UTILS
	private String getWhereClause(List<String> standards, List<String> clientOwnerships, List<String> resources, List<String> optionals, List<String> tags) {
		List<String> whereClauses = new ArrayList<String>();
		
		if ((optionals != null) && optionals.size()>0 ) {
			whereClauses.addAll(optionals);
		}
		
		if ((standards != null) && standards.size()>0) {
			List<String> standardsWhereClauses = new ArrayList<>();
			for (String standard : standards) {
				standardsWhereClauses.add("replace(replace(t.`Standards`, '|', ''), '-','') like '%" + standard.replaceAll("-", "") + "%'");
				standardsWhereClauses.add("replace(replace(t.`Standard Families`, '|', ''), '-','') like '%" + standard.replaceAll("-", "") + "%'");
			}
			whereClauses.add("(" + StringUtils.join(standardsWhereClauses.toArray(new String[standardsWhereClauses.size()]), " OR ") + ")");
		}
		
		if ((clientOwnerships != null) && clientOwnerships.size()>0) {
			whereClauses.add("t.`Client Ownership` in ('" + StringUtils.join(clientOwnerships.toArray(new String[clientOwnerships.size()]), "', '") + "')");
		}
		
		if ((resources != null) && resources.size()>0) {
			whereClauses.add("(t.`Owner` in ('" + StringUtils.join(resources.toArray(new String[resources.size()]), "', '") + "') or t.`Executed By` in ('" + StringUtils.join(resources.toArray(new String[resources.size()]), "', '") + "'))");
		}
		
		if ((tags != null) && tags.size()>0) {
			for (String tag : tags) {
				whereClauses.add("(t.`Tags` like '%;" + tag + ";%' or t.`Tags` like '" + tag + ";%')");
			}
		}
		
		return whereClauses.size()>0?"WHERE " + StringUtils.join(whereClauses.toArray(new String[whereClauses.size()]), " AND "):"";
	}
	
	// PROCESS TABLE
	private void refreshProcessTable() throws Exception {
		// Done by separate scheduled process.
		return;
	}
	
	private Calendar getLastUpdated() throws Exception {
		SimpleDateFormat mysqlDateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
		Calendar retValue = Calendar.getInstance();
		try {
			retValue.setTime(mysqlDateFormat.parse(db.executeScalar("select LastSyncDate from sf_tables where TableName = 'sf_business_process_details'")));
		} catch (Exception e) {
			throw e;
		}
		
		return retValue;
	}
}
