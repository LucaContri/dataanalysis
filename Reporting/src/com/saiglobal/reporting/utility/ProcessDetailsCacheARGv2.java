package com.saiglobal.reporting.utility;

import java.sql.ResultSet;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;
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

public class ProcessDetailsCacheARGv2 {

	private DbHelper db = null;
	private static ProcessDetailsCacheARGv2 reference = null;
	private Calendar lastUpdatedProcessTable;
	private int refreshIntervalHours = 24;
	private Semaphore update = new Semaphore(1);
	private ProcessDetailsCacheARGv2(DbHelper db) {
		this.db = db;
	}
	
	public static ProcessDetailsCacheARGv2 getInstance(DbHelper db) {
		if (reference == null)
			reference = new ProcessDetailsCacheARGv2(db);
		
		return reference;
	}
	
	public ProcessDetails getProcessDetails(Process process, List<String> pathways, List<String> programs, List<String> standardsIds, List<String> revenueOwnerships, List<String> resourcesIds, List<String> tags, boolean forceRefresh) throws Exception {
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
				processDetails.performances.addAll(getARGOverallPerformace(pathways, programs, standardsIds, revenueOwnerships, resourcesIds,tags));
				processDetails.performances.add(getARGOverallPerformaceSLA(pathways, programs, standardsIds, revenueOwnerships, resourcesIds, tags));
				break;
			case AUDITORS:
				processDetails.queues.add(getWorkItemsFinishedNotSubmitted(pathways, programs, standardsIds, revenueOwnerships, resourcesIds,tags));
				processDetails.queues.add(getWorkItemsSubmittedNoARG(pathways, programs, standardsIds, revenueOwnerships, resourcesIds,tags));
				processDetails.queues.add(getARGRejectedToBeResubmitted(pathways, programs, standardsIds, revenueOwnerships, resourcesIds,tags));
				processDetails.queues.add(getWorkItemsSubmittedARGPending(pathways, programs, standardsIds, revenueOwnerships, resourcesIds,tags));
				processDetails.performances.add(getWorkItemsFinishedToARGSubmitted(pathways, programs, standardsIds, revenueOwnerships, resourcesIds,tags));
				processDetails.performances.add(getARGRejectedToARGReSubmitted(pathways, programs, standardsIds, revenueOwnerships, resourcesIds,tags));
				break;
			case PRC:
				processDetails.queues.add(getARGToBeReviewed(pathways, programs, standardsIds, revenueOwnerships, resourcesIds,tags));
				processDetails.queues.add(getARGToBeReviewedAfterResubmission(pathways, programs, standardsIds, revenueOwnerships, resourcesIds,tags));
				processDetails.performances.add(getARGRevisionFirst(pathways, programs, standardsIds, revenueOwnerships, resourcesIds,tags));
				processDetails.performances.add(getARGRevisionResubmission(pathways, programs, standardsIds, revenueOwnerships, resourcesIds,tags));
				break;
			case TR:
				break;	
			case ADMIN:
				processDetails.queues.add(getARGToBeCompleted(pathways, programs, standardsIds, revenueOwnerships, resourcesIds,tags));
				processDetails.queues.add(getARGHold(pathways, programs, standardsIds, revenueOwnerships, resourcesIds,tags));
				processDetails.performances.add(getARGApprovedToARGCompletedOrOnHold(pathways, programs, standardsIds, revenueOwnerships, resourcesIds,tags));
				processDetails.performances.add(getARGHoldToARGCompleted(pathways, programs, standardsIds, revenueOwnerships, resourcesIds,tags));
				break;
			default:
				break;
		}
		//processDetails.lastUpdated = getLastUpdated();
		return processDetails;
	}
	
	// OVERALL PERFORMANCES
	private ProcessPerformances getARGOverallPerformaceSLA(List<String> pathways, List<String>  programs, List<String> standards, List<String> revenueOwnerships, List<String> resources, List<String> tags) throws Exception {
		ProcessPerformances performance = new ProcessPerformances("Audit End to ARG Completed", "ARG", "Days", "Period", 21.0, 0.99);
		performance.reportSlaOnly = true;
		List<String> optionalFilters = new ArrayList<String>();
		optionalFilters.add("arg_completed.Audit_Report_Status__c = 'Completed'");
		optionalFilters.add("arg_completed.Admin_Closed__c >= '2015-07-01'");
		optionalFilters.add("arg_completed.IsDeleted = 0");
		optionalFilters.add("arg_completed.Work_Item_Stages__c not like ('%Product Update%')");
		optionalFilters.add("arg_completed.Work_Item_Stages__c not like ('%Initial Project%')");
		optionalFilters.add("t.`Metric` in ('ARG Submission - First','ARG Submission - Resubmission', 'CA Revision', 'TR Revision','ARG Completion/Hold', 'ARG Hold', 'ARG Submission - Waiting On Client')");
		String query = "(select t2.`Period`, "
				+ "count(distinct t2.Id) as 'Volume',"
				+ "sum(if(t2.`Duration`<=if(t2.`Auto-Approved`,7,if(t2.`Standards` like '%BRC%',42,21)),1,0)) as 'Volume Within SLA',"
				+ "avg(t2.`Duration`) as 'Average',"
				+ "stddev(t2.`Duration`) as 'Std Dev' "
				+ "from "
				+ "(select "
				+ "arg_completed.Id as 'Id',"
				+ "date_format(arg_completed.Admin_Closed__c, '%Y %m') as 'Period',"
				+ "count(distinct arg_completed.Id) as 'Volume',"
				+ "sum(timestampdiff(second, t.`From`, t.`To`)/3600/24) as 'Duration',"
				+ "if(count(t.Id)=1,1, 0) as 'Auto-Approved',"
				+ "t.`Standards` "
				+ "from salesforce.audit_report_group__c arg_completed "
				+ "inner join analytics.sla_arg_v2 t on arg_completed.Id = t.Id "
				+ getWhereClause(pathways, programs, standards, revenueOwnerships, resources, optionalFilters, tags)
				+ "group by arg_completed.Id) t2 "
				+ "group by t2.`Period`)";
		
		ResultSet rs = db.executeSelect(query, -1);
		rs.last();
		performance.group = new String[rs.getRow()];
		performance.quantity = new int[rs.getRow()];
		performance.avg = new double[rs.getRow()];
		performance.stdDev = new double[rs.getRow()];
		performance.withinSLA = new int[rs.getRow()];
		rs.beforeFirst();
		int i = 0;
		while (rs.next()) {
			performance.quantity[i] = rs.getInt("Volume");
			performance.avg[i] = rs.getDouble("Average");
			performance.stdDev[i] = rs.getDouble("Std Dev");
			performance.withinSLA[i] = rs.getInt("Volume Within SLA");
			performance.group[i] = rs.getString("Period");
			i++;
		}
		
		return performance;
	}
	
	private List<ProcessPerformances> getARGOverallPerformace(List<String> pathways, List<String>  programs, List<String> standards, List<String> revenueOwnerships, List<String> resources, List<String> tags) throws Exception {
		List<ProcessPerformances> performances = new ArrayList<ProcessPerformances>();
		
		List<String> optionalFilters = new ArrayList<String>();
		optionalFilters.add("arg_orig.Audit_Report_Status__c = 'Completed'");
		optionalFilters.add("arg_orig.Admin_Closed__c >= '2015-07-01'");
		optionalFilters.add("arg_orig.IsDeleted = 0");
		optionalFilters.add("arg_orig.Work_Item_Stages__c not like ('%Product Update%')");
		optionalFilters.add("arg_orig.Work_Item_Stages__c not like ('%Initial Project%')");
		optionalFilters.add("t.`Metric` in ('ARG Submission - First','ARG Submission - Resubmission', 'CA Revision', 'TR Revision','ARG Completion/Hold', 'ARG Hold', 'ARG Submission - Waiting On Client')");
		String query = "(select "
				+ "date_format(arg_orig.Admin_Closed__c, '%Y %m')  as 'Period',"
				+ "count(distinct t.Id) as 'Volume',"
				+ "sum(if(t.`Metric` in ('ARG Submission - Waiting On Client'), timestampdiff(second, t.`From`, t.`To`)/3600/24,null))/count(distinct t.Id) as 'Waiting Client (Avg Days)',"
				+ "sum(if(t.`Metric` in ('ARG Submission - First','ARG Submission - Resubmission'), timestampdiff(second, t.`From`, t.`To`)/3600/24,null))/count(distinct t.Id) as 'Auditor (Avg Days)',"
				+ "sum(if(t.`Metric` in ('CA Revision'), timestampdiff(second, t.`From`, t.`To`)/3600/24,null))/count(distinct t.Id) as 'Technical CA (Avg Days)',"
				+ "sum(if(t.`Metric` in ('TR Revision'), timestampdiff(second, t.`From`, t.`To`)/3600/24,null))/count(distinct t.Id) as 'Technical TR (Avg Days)',"
				+ "sum(if(t.`Metric` in ('ARG Completion/Hold'), timestampdiff(second, t.`From`, t.`To`)/3600/24,null))/count(distinct t.Id) as 'Admin (Avg Days)',"
				+ "sum(if(t.`Metric` in ('ARG Hold'), timestampdiff(second, t.`From`, t.`To`)/3600/24,null))/count(distinct t.Id) as 'Hold (Avg Days)',"
				+ "stddev(if(t.`Metric` in ('ARG Submission - Waiting On Client'), timestampdiff(second, t.`From`, t.`To`)/3600/24,null)) as 'Waiting Client (Var)',"
				+ "stddev(if(t.`Metric` in ('ARG Submission - First','ARG Submission - Resubmission'), timestampdiff(second, t.`From`, t.`To`)/3600/24,null)) as 'Auditor (Var)',"
				+ "stddev(if(t.`Metric` in ('CA Revision'), timestampdiff(second, t.`From`, t.`To`)/3600/24,null)) as 'Technical CA (Var)',"
				+ "stddev(if(t.`Metric` in ('TR Revision'), timestampdiff(second, t.`From`, t.`To`)/3600/24,null)) as 'Technical TR (Var)',"
				+ "stddev(if(t.`Metric` in ('ARG Completion/Hold'), timestampdiff(second, t.`From`, t.`To`)/3600/24,null)) as 'Admin (Var)',"
				+ "stddev(if(t.`Metric` in ('ARG Hold'), timestampdiff(second, t.`From`, t.`To`)/3600/24,null)) as 'Hold (Var)' "
				+ "from salesforce.audit_report_group__c arg_orig "
				+ "inner join analytics.sla_arg_v2 t on arg_orig.Id = t.Id "
				+ getWhereClause(pathways, programs, standards, revenueOwnerships, resources, optionalFilters, tags)
				+ "group by `Period` "
				+ "order by `Period`)";
		
		ProcessPerformances waitingOnClient = new ProcessPerformances("Waiting On Client", "ARG", "Days", "Period", 2.0, 0.99);
		ProcessPerformances auditor = new ProcessPerformances("Auditor", "ARG", "Days", "Period", 5.0, 0.99);
		ProcessPerformances technicalCA = new ProcessPerformances("Technical CA", "ARG", "Days", "Period", 5.0, 0.99);
		ProcessPerformances technicalTR = new ProcessPerformances("Technical TR", "ARG", "Days", "Period", 5.0, 0.99);
		ProcessPerformances admin = new ProcessPerformances("Admin", "ARG", "Days", "Period", 5.0, 0.99);
		ProcessPerformances hold = new ProcessPerformances("Hold", "ARG", "Days", "Period", 5.0, 0.99);
		ResultSet rs = db.executeSelect(query, -1);
		rs.last();
		String[] periods = new String[rs.getRow()];
		waitingOnClient.quantity = new int[rs.getRow()];
		waitingOnClient.avg = new double[rs.getRow()];
		waitingOnClient.stdDev = new double[rs.getRow()];
		auditor.quantity = new int[rs.getRow()];
		auditor.avg = new double[rs.getRow()];
		auditor.stdDev = new double[rs.getRow()];
		technicalCA.quantity = new int[rs.getRow()];
		technicalCA.avg = new double[rs.getRow()];
		technicalCA.stdDev = new double[rs.getRow()];
		technicalTR.quantity = new int[rs.getRow()];
		technicalTR.avg = new double[rs.getRow()];
		technicalTR.stdDev = new double[rs.getRow()];
		admin.quantity = new int[rs.getRow()];
		admin.avg = new double[rs.getRow()];
		admin.stdDev = new double[rs.getRow()];
		hold.quantity = new int[rs.getRow()];
		hold.avg = new double[rs.getRow()];
		hold.stdDev = new double[rs.getRow()];
		rs.beforeFirst();
		int i = 0;
		while (rs.next()) {
			waitingOnClient.quantity[i] = rs.getInt("Volume");
			waitingOnClient.avg[i] = rs.getDouble("Waiting Client (Avg Days)");
			waitingOnClient.stdDev[i] = rs.getDouble("Waiting Client (Var)");
			auditor.quantity[i] = rs.getInt("Volume");
			auditor.avg[i] = rs.getDouble("Auditor (Avg Days)");
			auditor.stdDev[i] = rs.getDouble("Auditor (Var)");
			technicalCA.quantity[i] = rs.getInt("Volume");
			technicalCA.avg[i] = rs.getDouble("Technical CA (Avg Days)");
			technicalCA.stdDev[i] = rs.getDouble("Technical CA (Var)");
			technicalTR.quantity[i] = rs.getInt("Volume");
			technicalTR.avg[i] = rs.getDouble("Technical TR (Avg Days)");
			technicalTR.stdDev[i] = rs.getDouble("Technical TR (Var)");
			admin.quantity[i] = rs.getInt("Volume");
			admin.avg[i] = rs.getDouble("Admin (Avg Days)");
			admin.stdDev[i] = rs.getDouble("Admin (Var)");
			hold.quantity[i] = rs.getInt("Volume");
			hold.avg[i] = rs.getDouble("Hold (Avg Days)");
			hold.stdDev[i] = rs.getDouble("Hold (Var)");
			
			periods[i] = rs.getString("Period");
			i++;
		}
		waitingOnClient.group = periods;
		auditor.group = periods;
		technicalCA.group = periods;
		technicalTR.group = periods;
		admin.group = periods;
		hold.group = periods;
		performances.add(waitingOnClient);
		performances.add(auditor);
		performances.add(technicalCA);
		performances.add(technicalTR);
		performances.add(admin);
		performances.add(hold);
		return performances;
	}
	
	// ADMIN QUEUES
	private ProcessQueue getARGHold(List<String> pathways, List<String>  programs, List<String> standards, List<String> revenueOwnerships, List<String> resources, List<String> tags) throws Exception {
		ProcessQueue queue = new ProcessQueue("ARG on Hold", "ARG", "Business Days", "Aging (Days)");
		List<String> optionalFilters = new ArrayList<String>();
		optionalFilters.add("t.`To` is null");
		optionalFilters.add("t.`Metric` = 'ARG Hold'");
		String query = "select concat('<a href=\"https://na14.salesforce.com/', t.`Id`, '\" target=\"_blank\">',t.`Name`,'</a>') as 'ARG', t.`Client`, t.`WI Type`,"
				+ "t.`Region` as 'Revenue Ownership', "
				+ "convert_tz(t.`From`,'utc',t.`TimeZone`) as 'Hold Date ', "
				+ "analytics.getBusinessDays(t.`From`, utc_timestamp(), t.`TimeZone`) as 'Aging (Days)', "
				+ "t.`Owner` as 'Assigned Admin', "
				+ "if(analytics.getBusinessDays(t.`From`, utc_timestamp(), t.`TimeZone`)<=analytics.getTargetARGGlobal(t.`Metric`, null),1,0) as 'WithinSLA' "
				+ "from analytics.sla_arg_v2 t " 
				+ getWhereClause(pathways, programs, standards, revenueOwnerships, resources, optionalFilters, tags);
		
		queue.setDetails(Utility.resultSetToObjectArray(db.executeSelect(query, -1), true));;
		
		return queue;
	}
	
	private ProcessQueue getARGToBeCompleted(List<String> pathways, List<String>  programs, List<String> standards, List<String> revenueOwnerships, List<String> resources, List<String> tags) throws Exception {
		ProcessQueue queue = new ProcessQueue("ARG to be Completed", "ARG", "Business Days", "Aging (Days)");
		List<String> optionalFilters = new ArrayList<String>();
		optionalFilters.add("t.`To` is null");
		optionalFilters.add("t.`Metric` = 'ARG Completion/Hold'");
		String query = "select concat('<a href=\"https://na14.salesforce.com/', t.`Id`, '\" target=\"_blank\">',t.`Name`,'</a>') as 'ARG', t.`Client`, t.`WI Type`,"
				+ "t.`Region` as 'Revenue Ownership', "
				+ "convert_tz(t.`From`,'utc',t.`TimeZone`) as 'Assigned ', "
				+ "analytics.getBusinessDays(t.`From`, utc_timestamp(), t.`TimeZone`) as 'Aging (Days)', "
				+ "t.`Owner` as 'Assigned Admin', "
				+ "if(analytics.getBusinessDays(t.`From`, utc_timestamp(), t.`TimeZone`)<=analytics.getTargetARGGlobal(t.`Metric`, null),1,0) as 'WithinSLA' "
				+ "from analytics.sla_arg_v2 t " 
				+ getWhereClause(pathways, programs, standards, revenueOwnerships, resources, optionalFilters, tags);
		
		queue.setDetails(Utility.resultSetToObjectArray(db.executeSelect(query, -1), true));;
		
		return queue;
	}
	
	// ADMIN PERFORMANCES
	private ProcessPerformances getARGApprovedToARGCompletedOrOnHold(List<String> pathways, List<String>  programs, List<String> standards, List<String> revenueOwnerships, List<String> resources, List<String> tags) throws Exception {
		ProcessPerformances performance = new ProcessPerformances(Performance.ARG_APPROVED_TO_ARG_COMPLETED_OR_HOLD.getName(), "ARG", "Business Days", "Period", 2.0, 0.99, "ARG Approved", "ARG Completed/OnHold");
		
		List<String> optionalFilters = new ArrayList<String>();
		optionalFilters.add("t.`To` is not null");
		optionalFilters.add("t.`Metric` = 'ARG Completion/Hold'");
		optionalFilters.add("t.`To` >= '2015-07-01'");
		String query = "select concat('<a href=\"https://na14.salesforce.com/', t.`Id`, '\" target=\"_blank\">',t.`Name`,'</a>') as 'ARG', t.`Client`, t.`WI Type`,"
				+ "t.`Region` as 'Rev. Ownership', "
				+ "convert_tz(t.`From`,'utc',t.`TimeZone`) as 'ARG Approved', "
				+ "convert_tz(t.`To`,'utc',t.`TimeZone`) as 'ARG Completed/OnHold', "
				+ "analytics.getBusinessDays(t.`From`, t.`To`, t.`TimeZone`) as 'Duration', "
				+ "t.`Owner` as 'Assigned Admin', "
				+ "if(analytics.getBusinessDays(t.`From`, t.`To`, t.`TimeZone`)<=analytics.getTargetARGGlobal(t.`Metric`, null),1,0) as 'WithinSLA' "
				+ "from analytics.sla_arg_v2 t " 
				+ getWhereClause(pathways, programs, standards, revenueOwnerships, resources, optionalFilters, tags)
				+ " order by `ARG Completed/OnHold`";
		
		performance.setDetails(Utility.resultSetToObjectArray(db.executeSelect(query, -1), true));
		
		return performance;
	}
	
	private ProcessPerformances getARGHoldToARGCompleted(List<String> pathways, List<String>  programs, List<String> standards, List<String> revenueOwnerships, List<String> resources, List<String> tags) throws Exception {
		ProcessPerformances performance = new ProcessPerformances("ARG Hold to ARG Completed", "ARG", "Business Days", "Period", 2.0, 0.99, "ARG Hold", "ARG Completed");
		
		List<String> optionalFilters = new ArrayList<String>();
		optionalFilters.add("t.`To` is not null");
		optionalFilters.add("t.`Metric` = 'ARG Hold'");
		optionalFilters.add("t.`To` >= '2015-07-01'");
		String query = "select concat('<a href=\"https://na14.salesforce.com/', t.`Id`, '\" target=\"_blank\">',t.`Name`,'</a>') as 'ARG', t.`Client`, t.`WI Type`,"
				+ "t.`Region` as 'Rev. Ownership', "
				+ "convert_tz(t.`From`,'utc',t.`TimeZone`) as 'ARG Hold', "
				+ "convert_tz(t.`To`,'utc',t.`TimeZone`) as 'ARG Completed', "
				+ "analytics.getBusinessDays(t.`From`, t.`To`, t.`TimeZone`) as 'Duration', "
				+ "t.`Owner` as 'Assigned Admin', "
				+ "if(analytics.getBusinessDays(t.`From`, t.`To`, t.`TimeZone`)<=analytics.getTargetARGGlobal(t.`Metric`, null),1,0) as 'WithinSLA' "
				+ "from analytics.sla_arg_v2 t " 
				+ getWhereClause(pathways, programs, standards, revenueOwnerships, resources, optionalFilters, tags)
				+ " order by `ARG Completed`";
		
		performance.setDetails(Utility.resultSetToObjectArray(db.executeSelect(query, -1), true));
		
		return performance;
	}
	
	// PRC QUEUES
	private ProcessQueue getARGToBeReviewedAfterResubmission(List<String> pathways, List<String>  programs, List<String> standards, List<String> revenueOwnerships, List<String> resources, List<String> tags) throws Exception {
		ProcessQueue queue = new ProcessQueue("ARG Resubmitted to be Reviewed", "ARG", "Business Days", "Aging (Days)");
		List<String> optionalFilters = new ArrayList<String>();
		optionalFilters.add("t.`To` is null");
		optionalFilters.add("t.`Metric` = 'ARG Revision - Resubmission'");
		String query = "select "
				+ "concat('<a href=\"https://na14.salesforce.com/', t.`Id`, '\" target=\"_blank\">',t.`Name`,'</a>') as 'ARG', t.`Client`, t.`WI Type`,"
				+ "t.`Region` as 'Rev. Ownership', "
				+ "convert_tz(t.`From`,'utc',t.`TimeZone`) as 'ARG Submitted', "
				+ "analytics.getBusinessDays(t.`From`, utc_timestamp(), t.`TimeZone`) as 'Aging (Days)', "
				+ "t.`Owner` as 'Certification Approver', "
				+ "if(analytics.getBusinessDays(t.`From`, utc_timestamp(), t.`TimeZone`)<=analytics.getTargetARGGlobal(t.`Metric`, null),1,0) as 'WithinSLA' "
				+ "from analytics.sla_arg_v2 t " 
				+ getWhereClause(pathways, programs, standards, revenueOwnerships, resources, optionalFilters, tags);
		
		queue.setDetails(Utility.resultSetToObjectArray(db.executeSelect(query, -1), true));
		
		return queue;
	}
	
	private ProcessQueue getARGToBeReviewed(List<String> pathways, List<String>  programs, List<String> standards, List<String> revenueOwnerships, List<String> resources, List<String> tags) throws Exception {
		ProcessQueue queue = new ProcessQueue("ARG Submitted to be Reviewed", "ARG", "Business Days", "Aging (Days)");
		List<String> optionalFilters = new ArrayList<String>();
		optionalFilters.add("t.`To` is null");
		optionalFilters.add("t.`Metric` = 'ARG Revision - First'");
		String query = "select "
				+ "concat('<a href=\"https://na14.salesforce.com/', t.`Id`, '\" target=\"_blank\">',t.`Name`,'</a>') as 'ARG', t.`Client`, t.`WI Type`,"
				+ "t.`Region` as 'Rev. Ownership', "
				+ "convert_tz(t.`From`,'utc',t.`TimeZone`) as 'ARG Submitted', "
				+ "analytics.getBusinessDays(t.`From`, utc_timestamp(), t.`TimeZone`) as 'Aging (Days)', "
				+ "t.`Owner` as 'Certification Approver', "
				+ "if(analytics.getBusinessDays(t.`From`, utc_timestamp(), t.`TimeZone`)<=analytics.getTargetARGGlobal(t.`Metric`, null),1,0) as 'WithinSLA' "
				+ "from analytics.sla_arg_v2 t " 
				+ getWhereClause(pathways, programs, standards, revenueOwnerships, resources, optionalFilters, tags);
		
		queue.setDetails(Utility.resultSetToObjectArray(db.executeSelect(query, -1), true));
		
		return queue;
	}
	
	// PRC PERFORMANCES
	private ProcessPerformances getARGRevisionFirst(List<String> pathways, List<String>  programs, List<String> standards, List<String> revenueOwnerships, List<String> resources, List<String> tags) throws Exception {
		ProcessPerformances performance = new ProcessPerformances("Technical Revision - First", "ARG", "Business Days", "Period", 5.0, 0.99, "ARG Submitted", "ARG Reviewed");
		List<String> optionalFilters = new ArrayList<String>();
		optionalFilters.add("t.`To` is not null");
		optionalFilters.add("t.`Metric` = 'ARG Revision - First'");
		optionalFilters.add("t.`To` >= '2015-07-01'");
		String query = "select concat('<a href=\"https://na14.salesforce.com/', t.`Id`, '\" target=\"_blank\">',t.`Name`,'</a>') as 'ARG', t.`Client`, t.`WI Type`,"
				+ "t.`Region` as 'Revenue Owenrship', "
				+ "convert_tz(t.`From`,'utc',t.`TimeZone`) as 'ARG Submitted', "
				+ "convert_tz(t.`To`,'utc',t.`TimeZone`) as 'ARG Reviewed', "
				+ "analytics.getBusinessDays(t.`From`, t.`To`, t.`TimeZone`) as 'Duration', "
				+ "t.`Owner` as 'Certification Approver', "
				+ "if(analytics.getBusinessDays(t.`From`, t.`To`, t.`TimeZone`)<=analytics.getTargetARGGlobal(t.`Metric`, null),1,0) as 'WithinSLA' "
				+ "from analytics.sla_arg_v2 t " 
				+ getWhereClause(pathways, programs, standards, revenueOwnerships, resources, optionalFilters, tags)
				+ " order by `ARG Reviewed`";
		
		performance.setDetails(Utility.resultSetToObjectArray(db.executeSelect(query, -1), true));
		
		return performance;
	}
	
	private ProcessPerformances getARGRevisionResubmission(List<String> pathways, List<String>  programs, List<String> standards, List<String> revenueOwnerships, List<String> resources, List<String> tags) throws Exception {
		ProcessPerformances performance = new ProcessPerformances("Technical Revision - Resubmission", "ARG", "Business Days", "Period", 2.0, 0.99, "ARG Resubmitted", "ARG Reviewed");
		List<String> optionalFilters = new ArrayList<String>();
		optionalFilters.add("t.`To` is not null");
		optionalFilters.add("t.`Metric` = 'ARG Revision - Resubmission'");
		optionalFilters.add("t.`To` >= '2015-07-01'");
		String query = "select concat('<a href=\"https://na14.salesforce.com/', t.`Id`, '\" target=\"_blank\">',t.`Name`,'</a>') as 'ARG', t.`Client`, t.`WI Type`,"
				+ "t.`Region` as 'Revenue Owenrship', "
				+ "convert_tz(t.`From`,'utc',t.`TimeZone`) as 'ARG Resubmitted', "
				+ "convert_tz(t.`To`,'utc',t.`TimeZone`) as 'ARG Reviewed', "
				+ "analytics.getBusinessDays(t.`From`, t.`To`, t.`TimeZone`) as 'Duration', "
				+ "t.`Owner` as 'Certification Approver', "
				+ "if(analytics.getBusinessDays(t.`From`, t.`To`, t.`TimeZone`)<=analytics.getTargetARGGlobal(t.`Metric`, null),1,0) as 'WithinSLA' "
				+ "from analytics.sla_arg_v2 t " 
				+ getWhereClause(pathways, programs, standards, revenueOwnerships, resources, optionalFilters, tags)
				+ " order by `ARG Reviewed`";
		
		performance.setDetails(Utility.resultSetToObjectArray(db.executeSelect(query, -1), true));
		
		return performance;
	}
	
	// AUDITORS QUEUES
	private ProcessQueue getWorkItemsSubmittedARGPending(List<String> pathways, List<String>  programs, List<String> standards, List<String> revenueOwnerships, List<String> resources, List<String> tags) throws Exception {
		ProcessQueue queue = new ProcessQueue(Queue.WI_SUBMITTED_ARG_PENDING.getName(), "Work Item", "Business Days", "Aging (Days)");
		List<String> optionalFilters = new ArrayList<String>();
		optionalFilters.add("t.`To` is null");
		optionalFilters.add("t.`Metric` = 'ARG Submission - First'");
		String query = "select concat('<a href=\"https://na14.salesforce.com/', t.`Id`, '\" target=\"_blank\">',t.`Name`,'</a>') as 'ARG', t.`Client`, t.`WI Type`,"
				+ "t.`Region` as 'Rev. Ownership', "
				+ "convert_tz(t.`From`,'utc',t.`TimeZone`) as 'WI Finished', "
				+ "analytics.getBusinessDays(t.`From`, utc_timestamp(), t.`TimeZone`) as 'Aging (Days)', "
				+ "t.`Owner` as 'Author', "
				+ "if(analytics.getBusinessDays(t.`From`, utc_timestamp(), t.`TimeZone`)<=analytics.getTargetARGGlobal(t.`Metric`, null),1,0) as 'WithinSLA' "
				+ "from analytics.sla_arg_v2 t "
				+ "inner join salesforce.arg_work_item__c argwi on t.Id = argwi.RAudit_Report_Group__c and argwi.IsDeleted=0 " 
				+ getWhereClause(pathways, programs, standards, revenueOwnerships, resources, optionalFilters, tags);
		
		queue.setDetails(Utility.resultSetToObjectArray(db.executeSelect(query, -1), true));
		
		return queue;
	}
	
	private ProcessQueue getWorkItemsFinishedNotSubmitted(List<String> pathways, List<String>  programs, List<String> standards, List<String> revenueOwnerships, List<String> resources, List<String> tags) throws Exception {
		ProcessQueue queue = new ProcessQueue(Queue.WI_FINISHED_NOT_SUBMMITTED.getName(), "Work Item", "Business Days", "Aging (Days)");
		List<String> optionalFilters = new ArrayList<String>();
		optionalFilters.add("t.`To` is null");
		optionalFilters.add("t.`Metric` = 'ARG Submission - Unsubmitted WI'");
		String query = "select "
				+ "concat('<a href=\"https://na14.salesforce.com/', t.`Id`, '\" target=\"_blank\">',t.`Name`,'</a>') as 'Work Item', t.`Client`, t.`WI Type`,"
				+ "t.`Region` as 'Rev. Ownership', "
				+ "convert_tz(t.`From`,'utc',t.`TimeZone`) as 'WI Finished', "
				+ "analytics.getBusinessDays(t.`From`, utc_timestamp(), t.`TimeZone`) as 'Aging (Days)', "
				+ "t.`Owner` as 'Author', "
				+ "if(analytics.getBusinessDays(t.`From`, utc_timestamp(), t.`TimeZone`)<=analytics.getTargetARGGlobal(t.`Metric`, null),1,0) as 'WithinSLA' "
				+ "from analytics.sla_arg_v2 t " 
				+ getWhereClause(pathways, programs, standards, revenueOwnerships, resources, optionalFilters, tags);
		
		queue.setDetails(Utility.resultSetToObjectArray(db.executeSelect(query, -1), true));
		
		return queue;
	}
	
	private ProcessQueue getWorkItemsSubmittedNoARG(List<String> pathways, List<String>  programs, List<String> standards, List<String> revenueOwnerships, List<String> resources, List<String> tags) throws Exception {
		ProcessQueue queue = new ProcessQueue(Queue.WI_SUBMITTED_WITHOUT_ARG.getName(), "Work Item", "Business Days", "Aging (Days)");
		List<String> optionalFilters = new ArrayList<String>();
		optionalFilters.add("t.`To` is null");
		optionalFilters.add("t.`Metric` = 'ARG Submission - Submitted WI No ARG'");
		String query = "select "
				+ "concat('<a href=\"https://na14.salesforce.com/', t.`Id`, '\" target=\"_blank\">',t.`Name`,'</a>') as 'Work Item', t.`Client`, t.`WI Type`,"
				+ "t.`Region` as 'Rev. Ownership', "
				+ "convert_tz(t.`From`,'utc',t.`TimeZone`) as 'WI Finished', "
				+ "analytics.getBusinessDays(t.`From`, utc_timestamp(), t.`TimeZone`) as 'Aging (Days)', "
				+ "t.`Owner` as 'Author', "
				+ "if(analytics.getBusinessDays(t.`From`, utc_timestamp(), t.`TimeZone`)<=analytics.getTargetARGGlobal(t.`Metric`, null),1,0) as 'WithinSLA' "
				+ "from analytics.sla_arg_v2 t " 
				+ getWhereClause(pathways, programs, standards, revenueOwnerships, resources, optionalFilters, tags);
		
		queue.setDetails(Utility.resultSetToObjectArray(db.executeSelect(query, -1), true));
		
		return queue;
	}
	
	private ProcessQueue getARGRejectedToBeResubmitted(List<String> pathways, List<String>  programs, List<String> standards, List<String> revenueOwnerships, List<String> resources, List<String> tags) throws Exception {
		ProcessQueue queue = new ProcessQueue(Queue.ARG_REJECTED_TO_BE_RESUBMITTED.getName(), "Work Item", "Business Days");
		List<String> optionalFilters = new ArrayList<String>();
		optionalFilters.add("t.`To` is null");
		optionalFilters.add("t.`Metric` = 'ARG Submission - Resubmission'");
		String query = "select "
				+ "concat('<a href=\"https://na14.salesforce.com/', t.`Id`, '\" target=\"_blank\">',t.`Name`,'</a>') as 'ARG', t.`Client`, t.`WI Type`,"
				+ "t.`Region` as 'Rev. Ownership', "
				+ "convert_tz(t.`From`,'utc',t.`TimeZone`) as 'Rejected', "
				+ "t.`TimeZone` as 'Timezone', "
				+ "analytics.getBusinessDays(t.`From`, utc_timestamp(), t.`TimeZone`) as 'Aging (Days)', "
				+ "t.`Owner` as 'Author', "
				+ "if(analytics.getBusinessDays(t.`From`, utc_timestamp(), t.`TimeZone`)<=analytics.getTargetARGGlobal(t.`Metric`, null),1,0) as 'WithinSLA' "
				+ "from analytics.sla_arg_v2 t " 
				+ getWhereClause(pathways, programs, standards, revenueOwnerships, resources, optionalFilters, tags);
		
		queue.setDetails(Utility.resultSetToObjectArray(db.executeSelect(query, -1), true));
		
		return queue;
	}
	
	// AUDITORS PERFORMANCES
	private ProcessPerformances getWorkItemsFinishedToARGSubmitted(List<String> pathways, List<String>  programs, List<String> standards, List<String> revenueOwnerships, List<String> resources, List<String> tags) throws Exception {
		
		ProcessPerformances performance = new ProcessPerformances(Performance.WI_FINISHED_TO_ARG_SUBMMITTED.getName(), "ARG", "Business Days", "Period", 5.0, 0.99, "WI Finished", "ARG Submitted");
		List<String> optionalFilters = new ArrayList<String>();
		optionalFilters.add("t.`To` is not null");
		optionalFilters.add("t.`Metric` = 'ARG Submission - First'");
		optionalFilters.add("t.`To` >= '2015-07-01'");
		String query = "select "
				+ "concat('<a href=\"https://na14.salesforce.com/', t.`Id`, '\" target=\"_blank\">',t.`Name`,'</a>') as 'ARG', t.`Client`, t.`WI Type`,"
				+ "t.`Region` as 'Rev. Ownership', "
				+ "convert_tz(t.`From`,'utc',t.`TimeZone`) as 'WI Finished', "
				+ "convert_tz(t.`To`, 'utc',t.`TimeZone`) as 'ARG Submitted', "
				+ "t.`TimeZone` as 'Timezone', "
				+ "analytics.getBusinessDays(t.`From`, t.`To`, t.`TimeZone`) as 'Duration', "
				+ "t.`Owner` as 'Auditor', "
				+ "if(analytics.getBusinessDays(t.`From`, t.`To`, t.`TimeZone`)<=analytics.getTargetARGGlobal(t.`Metric`, null),1,0) as 'WithinSLA' "
				+ "from analytics.sla_arg_v2 t " 
				+ getWhereClause(pathways, programs, standards, revenueOwnerships, resources, optionalFilters, tags)
				+ " order by `ARG Submitted`";
		
		performance.setDetails(Utility.resultSetToObjectArray(db.executeSelect(query, -1), true));
		
		return performance;
	}
	
	private ProcessPerformances getARGRejectedToARGReSubmitted(List<String> pathways, List<String>  programs, List<String> standards, List<String> revenueOwnerships, List<String> resources, List<String> tags) throws Exception {
		
		ProcessPerformances performance = new ProcessPerformances(Performance.ARG_REJECTED_TO_ARG_RESUBMITTED.getName(), "ARG", "Business Days", "Period", 2.0, 0.99, "ARG Rejected", "ARG Resubmitted");
		List<String> optionalFilters = new ArrayList<String>();
		optionalFilters.add("t.`To` is not null");
		optionalFilters.add("t.`Metric` = 'ARG Submission - Resubmission'");
		optionalFilters.add("t.`To` >= '2015-07-01'");
		String query = "select "
				+ "concat('<a href=\"https://na14.salesforce.com/', t.`Id`, '\" target=\"_blank\">',t.`Name`,'</a>') as 'ARG', t.`Client`, t.`WI Type`,"
				+ "t.`Region` as 'Rev. Ownership', "
				+ "convert_tz(t.`From`,'utc',t.`TimeZone`) as 'ARG Rejected', "
				+ "convert_tz(t.`To`, 'utc',t.`TimeZone`) as 'ARG Resubmitted', "
				+ "t.`TimeZone` as 'Timezone', "
				+ "analytics.getBusinessDays(t.`From`, t.`To`, t.`TimeZone`) as 'Duration', "
				+ "t.`Owner` as 'Auditor', "
				+ "if(analytics.getBusinessDays(t.`From`, t.`To`, t.`TimeZone`)<=analytics.getTargetARGGlobal(t.`Metric`, null),1,0) as 'WithinSLA' "
				+ "from analytics.sla_arg_v2 t " 
				+ getWhereClause(pathways, programs, standards, revenueOwnerships, resources, optionalFilters, tags)
				+ " order by `ARG Resubmitted`";
		
		performance.setDetails(Utility.resultSetToObjectArray(db.executeSelect(query, -1), true));
		
		return performance;
	}
	// UTILS
	private String getWhereClause(List<String> pathways, List<String>  programs, List<String> standards, List<String> revenueOwnerships, List<String> resources, List<String> optionals, List<String> tags) {
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
		
		if ((revenueOwnerships != null) && revenueOwnerships.size()>0) {
			whereClauses.add("t.`Region` in ('" + StringUtils.join(revenueOwnerships.toArray(new String[revenueOwnerships.size()]), "', '") + "')");
		}
		
		if ((pathways != null) && pathways.size()>0) {
			whereClauses.add("t.`Pathway` in ('" + StringUtils.join(pathways.toArray(new String[pathways.size()]), "', '") + "')");
		}
		
		if ((programs != null) && programs.size()>0) {
			whereClauses.add("t.`Program` in ('" + StringUtils.join(programs.toArray(new String[programs.size()]), "', '") + "')");
		}
		
		if ((resources != null) && resources.size()>0) {
			whereClauses.add("t.`Owner` in ('" + StringUtils.join(resources.toArray(new String[resources.size()]), "', '") + "') ");
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
