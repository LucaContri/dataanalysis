package com.saiglobal.reporting.utility;

import java.sql.ResultSet;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Calendar;
import java.util.Collections;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collector;
import java.util.stream.Collectors;

import org.apache.commons.lang.StringUtils;

import com.saiglobal.reporting.model.Metric;
import com.saiglobal.reporting.model.MetricDetails;
import com.saiglobal.reporting.model.MetricDetailsSummary;
import com.saiglobal.reporting.model.MetricDetailsSummaryList;
import com.saiglobal.reporting.model.SimpleParameter;
import com.saiglobal.sf.core.data.DbHelperConnPool;
import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;

public class ExecutiveDashboardHandler {
	private GlobalProperties gp = null;
	private HashMap<Integer, Metric> metrics = null;
	private HashMap<String, DbHelperConnPool> dbs = null;
	private static final String analyticsDS = "analytics";
	public ExecutiveDashboardHandler(GlobalProperties gp) throws Exception {
		this.gp = gp;
		init();
	}
	
	private void init() throws Exception {
		metrics = new LinkedHashMap<Integer, Metric>();
		dbs = new HashMap<String, DbHelperConnPool>();
		dbs.put(analyticsDS, new DbHelperConnPool(gp, "jdbc/" + analyticsDS));
		ResultSet rs = dbs.get(analyticsDS).executeSelect("select m.* "
				+ "from metrics2 m ", -1);
		while (rs.next()) {
			Metric metric = new Metric(
					rs.getInt("Id"),
					//rs.getString("Product Portfolio"),
					rs.getString("Metric Group"),
					rs.getString("Metric"),
					rs.getString("Volume Definition"),
					rs.getString("Volume Unit"),
					rs.getString("SLA Definition")
					);
			metrics.put(metric.getId(), metric);
		}
		dbs.get(analyticsDS).closeConnection();
	}
	
	public Set<Integer> getAvailableMetrics() {
		return metrics.keySet();
	}
	
	public boolean hasMetric(String uniqueMetricName) {
		for (Metric metric : metrics.values()) {
			if(metric.getUniqueName().equalsIgnoreCase(uniqueMetricName))
				return true;
		}
		return false;
	}
	
	public MetricDetails[] getMetricsDataDetails(List<Integer> metricsDetailsIds) throws Exception {
		return getMetricsDataDetails(null, metricsDetailsIds, null, null);
	}

	public MetricDetails[] getMetricsDataDetails(List<Integer> metricsIds, List<Integer> metricsDetailsIds, Calendar from, Calendar to) throws Exception {
		String select = "SELECT md.* "
				+ "FROM metrics_data2 md "
				+ "where 1=1 "
				+ ((from != null)?(" and `Period` >= '" + Utility.getMysqldateformat().format(from.getTime())):" ")
				+ ((to != null)?("' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "' "):" ")
				+ (metricsIds!=null?("and md.`Metric Id` in (" + StringUtils.join(metricsIds, ", ") + ") "):"")
				+ (metricsDetailsIds!=null?("and md.`Id` in (" + StringUtils.join(metricsDetailsIds, ", ") + ") "):"")
				+ "order by `subRegion`"; 
		ResultSet rs = dbs.get(analyticsDS).executeSelect(select, -1);
		List<MetricDetails> metricDetails = new ArrayList<MetricDetails>();
		while (rs.next()) {
			Calendar period = Calendar.getInstance();
			Calendar preparedDateTime = Calendar.getInstance();
			period.setTime(Utility.getActivitydateformatter().parse(rs.getString("Period")));
			int metricId = rs.getInt("Metric Id");
			Metric metric = metrics.get(metricId);
			preparedDateTime.setTime(Utility.getMysqldateformat().parse(rs.getString("Prepared Date/Time")));
			metricDetails.add(new MetricDetails(
					rs.getInt("Id"), 
					metric, 
					rs.getString("SubRegion"), 
					rs.getString("Prepared By"), 
					period, preparedDateTime, 
					rs.getDouble("Volume"), 
					rs.getDouble("SLA"), 
					rs.getString("Team"),
					rs.getString("Business Owner"),
					rs.getString("Region"),
					rs.getString("Product Portfolio"),
					rs.getDouble("Target Amber"),
					rs.getDouble("Target Green"),
					rs.getDouble("Weight")));
		}
		// Adjust Weights for Metric Details with same metric Id based on Volumes processed
		Map<String, MetricDetailsSummaryList> metricIdGroup =  metricDetails.stream().collect(
				Collectors.groupingBy(MetricDetails::getMetricRegionId, 
				Collector.of( MetricDetailsSummaryList::new, MetricDetailsSummaryList::add, MetricDetailsSummaryList::combine)));
		
		for (MetricDetailsSummaryList mds : metricIdGroup.values()) {
			for (MetricDetails md : mds.getMetricDetails()) {
				md.setWeight(md.getWeight()*md.getVolume()/mds.getVolumeSum());
			}
		}
		return metricDetails.toArray(new MetricDetails[metricDetails.size()]);
	}

	public MetricDetails[] getMetricsDataDetails(Calendar from, Calendar to) throws Exception {
		return getMetricsDataDetails(null, null, from, to);
	}
	
	public Object[][] getOperationsMetricsDataSummary(Calendar from, Calendar to) throws Exception {
		
		SimpleDateFormat periodFormat = new SimpleDateFormat("MMM YY");
		
		Calendar previousFrom = Calendar.getInstance();
		Calendar previousTo = Calendar.getInstance();
		previousFrom.setTime(from.getTime());
		previousTo.setTime(to.getTime());
		previousFrom.add(Calendar.MONTH, -1);
		previousTo.add(Calendar.MONTH, -1);
		String select = "SELECT * FROM ("
				+ "SELECT m.`Metric Group`, m.`Product Portfolio`,"
				+ "SUM(IF(md.Region = 'AMERICAs' and `Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "',md.SLA * md.Volume,0)) / SUM(IF(md.Region = 'AMERICAs' and `Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "', md.Volume, 0)) AS 'AMERICAs (" + periodFormat.format(previousFrom.getTime()) + ")',"
				+ "MIN(IF(md.Region = 'AMERICAs' and `Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "' and md.SLA<m.`SLA Target Amber`,0,IF(md.Region = 'AMERICAs' and `Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "' and md.SLA<m.`SLA Target Green`,1,2))) AS 'AMERICAs Status Previous',"
				+ "SUM(IF(md.Region = 'AMERICAs' and `Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "',md.SLA * md.Volume,0)) / SUM(IF(md.Region = 'AMERICAs' and `Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "', md.Volume, 0)) AS 'AMERICAs (" + periodFormat.format(from.getTime()) + ")',"
				+ "MIN(IF(md.Region = 'AMERICAs' and `Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "' and md.SLA<m.`SLA Target Amber`,0,IF(md.Region = 'AMERICAs' and `Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "' and md.SLA<m.`SLA Target Green`,1,2))) AS 'AMERICAs Status',"
				+ "GROUP_CONCAT(DISTINCT IF(md.Region = 'AMERICAs',m.Id,null)) as 'AMERICAs MetricIds',"
				
				+ "SUM(IF(md.Region = 'APAC' and `Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "',md.SLA * md.Volume,0)) / SUM(IF(md.Region = 'APAC' and `Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "', md.Volume, 0)) AS 'APAC (" + periodFormat.format(previousFrom.getTime()) + ")',"
				+ "MIN(IF(md.Region = 'APAC' and `Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "' and md.SLA<m.`SLA Target Amber`,0,IF(md.Region = 'APAC' and `Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "' and md.SLA<m.`SLA Target Green`,1,2))) AS 'APAC Status Previous',"
				+ "SUM(IF(md.Region = 'APAC' and `Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "',md.SLA * md.Volume,0)) / SUM(IF(md.Region = 'APAC' and `Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "', md.Volume, 0)) AS 'APAC (" + periodFormat.format(from.getTime()) + ")',"
				+ "MIN(IF(md.Region = 'APAC' and `Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "' and md.SLA<m.`SLA Target Amber`,0,IF(md.Region = 'APAC' and `Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "' and md.SLA<m.`SLA Target Green`,1,2))) AS 'APAC Status',"
				+ "GROUP_CONCAT(DISTINCT IF(md.Region = 'APAC',m.Id,null)) as 'APAC MetricIds',"
				
				+ "SUM(IF(md.Region = 'EMEA' and `Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "',md.SLA * md.Volume,0)) / SUM(IF(md.Region = 'EMEA' and `Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "', md.Volume, 0)) AS 'EMEA (" + periodFormat.format(previousFrom.getTime()) + ")',"
				+ "MIN(IF(md.Region = 'EMEA' and `Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "' and md.SLA<m.`SLA Target Amber`,0,IF(md.Region = 'EMEA' and `Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "' and md.SLA<m.`SLA Target Green`,1,2))) AS 'EMEA Status Previous',"
				+ "SUM(IF(md.Region = 'EMEA' and `Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "',md.SLA * md.Volume,0)) / SUM(IF(md.Region = 'EMEA' and `Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "', md.Volume, 0)) AS 'EMEA (" + periodFormat.format(from.getTime()) + ")',"
				+ "MIN(IF(md.Region = 'EMEA' and `Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "' and md.SLA<m.`SLA Target Amber`,0,IF(md.Region = 'EMEA' and `Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "' and md.SLA<m.`SLA Target Green`,1,2))) AS 'EMEA Status',"
				+ "GROUP_CONCAT(DISTINCT IF(md.Region = 'EMEA',m.Id,null)) as 'EMEA MetricIds',"
				
				+ "SUM(IF(`Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "',md.SLA * md.Volume,0)) / SUM(IF(`Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "', md.Volume, 0)) AS 'Overall (" + periodFormat.format(previousFrom.getTime()) + ")',"
				+ "MIN(IF(`Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "' and md.SLA<m.`SLA Target Amber`,0,IF(md.SLA<m.`SLA Target Green` and `Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "',1,2))) AS 'Overall Status Previous',"
				+ "SUM(IF(`Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "',md.SLA * md.Volume,0)) / SUM(IF(`Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "', md.Volume, 0)) AS 'Overall (" + periodFormat.format(from.getTime()) + ")',"
				+ "MIN(IF(`Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "' and md.SLA<m.`SLA Target Amber`,0,IF(md.SLA<m.`SLA Target Green` and `Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "',1,2))) AS 'Overall Status',"
				+ "GROUP_CONCAT(DISTINCT m.Id) as 'Overall MetricIds' "
				+ "FROM metrics_data md "
				+ "inner join metrics m on md.`Metric Id` = m.Id "
				+ "where ((`Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' "
				+ "and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "') or "
				+ "(`Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' "
				+ "and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "')) "
				+ "and `Function` = 'Operations' "
				+ "group by m.`Metric Group`, m.`Product Portfolio`"
				+ " UNION "
				+ "SELECT m.`Metric Group`, 'Overall' as 'Product Portfolio',"
				+ "SUM(IF(md.Region = 'AMERICAs' and `Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "',md.SLA * md.Volume,0)) / SUM(IF(md.Region = 'AMERICAs' and `Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "', md.Volume, 0)) AS 'AMERICAs (" + periodFormat.format(previousFrom.getTime()) + ")',"
				+ "MIN(IF(md.Region = 'AMERICAs' and `Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "' and md.SLA<m.`SLA Target Amber`,0,IF(md.Region = 'AMERICAs' and `Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "' and md.SLA<m.`SLA Target Green`,1,2))) AS 'AMERICAs Status Previous',"
				+ "SUM(IF(md.Region = 'AMERICAs' and `Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "',md.SLA * md.Volume,0)) / SUM(IF(md.Region = 'AMERICAs' and `Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "', md.Volume, 0)) AS 'AMERICAs (" + periodFormat.format(from.getTime()) + ")',"
				+ "MIN(IF(md.Region = 'AMERICAs' and `Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "' and md.SLA<m.`SLA Target Amber`,0,IF(md.Region = 'AMERICAs' and `Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "' and md.SLA<m.`SLA Target Green`,1,2))) AS 'AMERICAs Status',"
				+ "GROUP_CONCAT(DISTINCT IF(md.Region = 'AMERICAs',m.Id,null)) as 'AMERICAs MetricIds',"
				
				+ "SUM(IF(md.Region = 'APAC' and `Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "',md.SLA * md.Volume,0)) / SUM(IF(md.Region = 'APAC' and `Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "', md.Volume, 0)) AS 'APAC (" + periodFormat.format(previousFrom.getTime()) + ")',"
				+ "MIN(IF(md.Region = 'APAC' and `Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "' and md.SLA<m.`SLA Target Amber`,0,IF(md.Region = 'APAC' and `Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "' and md.SLA<m.`SLA Target Green`,1,2))) AS 'APAC Status Previous',"
				+ "SUM(IF(md.Region = 'APAC' and `Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "',md.SLA * md.Volume,0)) / SUM(IF(md.Region = 'APAC' and `Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "', md.Volume, 0)) AS 'APAC (" + periodFormat.format(from.getTime()) + ")',"
				+ "MIN(IF(md.Region = 'APAC' and `Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "' and md.SLA<m.`SLA Target Amber`,0,IF(md.Region = 'APAC' and `Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "' and md.SLA<m.`SLA Target Green`,1,2))) AS 'APAC Status',"
				+ "GROUP_CONCAT(DISTINCT IF(md.Region = 'APAC',m.Id,null)) as 'APAC MetricIds',"
				
				+ "SUM(IF(md.Region = 'EMEA' and `Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "',md.SLA * md.Volume,0)) / SUM(IF(md.Region = 'EMEA' and `Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "', md.Volume, 0)) AS 'EMEA (" + periodFormat.format(previousFrom.getTime()) + ")',"
				+ "MIN(IF(md.Region = 'EMEA' and `Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "' and md.SLA<m.`SLA Target Amber`,0,IF(md.Region = 'EMEA' and `Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "' and md.SLA<m.`SLA Target Green`,1,2))) AS 'EMEA Status Previous',"
				+ "SUM(IF(md.Region = 'EMEA' and `Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "',md.SLA * md.Volume,0)) / SUM(IF(md.Region = 'EMEA' and `Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "', md.Volume, 0)) AS 'EMEA (" + periodFormat.format(from.getTime()) + ")',"
				+ "MIN(IF(md.Region = 'EMEA' and `Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "' and md.SLA<m.`SLA Target Amber`,0,IF(md.Region = 'EMEA' and `Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "' and md.SLA<m.`SLA Target Green`,1,2))) AS 'EMEA Status',"
				+ "GROUP_CONCAT(DISTINCT IF(md.Region = 'EMEA',m.Id,null)) as 'EMEA MetricIds',"
				
				+ "SUM(IF(`Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "',md.SLA * md.Volume,0)) / SUM(IF(`Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "', md.Volume, 0)) AS 'Overall (" + periodFormat.format(previousFrom.getTime()) + ")',"
				+ "MIN(IF(`Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "' and md.SLA<m.`SLA Target Amber`,0,IF(md.SLA<m.`SLA Target Green` and `Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "',1,2))) AS 'Overall Status Previous',"
				+ "SUM(IF(`Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "',md.SLA * md.Volume,0)) / SUM(IF(`Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "', md.Volume, 0)) AS 'Overall (" + periodFormat.format(from.getTime()) + ")',"
				+ "MIN(IF(`Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "' and md.SLA<m.`SLA Target Amber`,0,IF(md.SLA<m.`SLA Target Green` and `Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "',1,2))) AS 'Overall Status',"
				+ "GROUP_CONCAT(DISTINCT m.Id) as 'Overall MetricIds' "
				+ "FROM metrics_data md "
				+ "inner join metrics m on md.`Metric Id` = m.Id "
				+ "where ((`Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' "
				+ "and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "') or "
				+ "(`Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' "
				+ "and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "')) "
				+ "and `Function` = 'Operations' "
				+ "group by m.`Metric Group`) t "
				+ "order by `Metric Group`";
		ResultSet rs = dbs.get(analyticsDS).executeSelect(select, -1);
		return Utility.resultSetToObjectArray(rs, true);
	}
	
	public Object[][] getOperationsMetricsDataSummary2(Calendar from, Calendar to) throws Exception {
		
		SimpleDateFormat periodFormat = new SimpleDateFormat("MMM YY");
		
		Calendar previousFrom = Calendar.getInstance();
		Calendar previousTo = Calendar.getInstance();
		previousFrom.setTime(from.getTime());
		previousTo.setTime(to.getTime());
		previousFrom.add(Calendar.MONTH, -1);
		previousTo.add(Calendar.MONTH, -1);
		String select = "SELECT * FROM ("
				+ "SELECT m.`Metric Group`, m.`Product Portfolio`,"
				+ "SUM(IF(md.Region = 'AMERICAs' and `Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "' and md.SLA >= m.`SLA Target Green`,1,0)) / SUM(IF(md.Region = 'AMERICAs' and `Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "', 1, 0)) AS 'AMERICAs (" + periodFormat.format(previousFrom.getTime()) + ")',"
				+ "null AS 'AMERICAs Status Previous',"
				+ "SUM(IF(md.Region = 'AMERICAs' and `Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "' and md.SLA >= m.`SLA Target Green`,1,0)) / SUM(IF(md.Region = 'AMERICAs' and `Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "', 1, 0)) AS 'AMERICAs (" + periodFormat.format(from.getTime()) + ")',"
				+ "null AS 'AMERICAs Status',"
				+ "GROUP_CONCAT(DISTINCT IF(md.Region = 'AMERICAs',m.Id,null)) as 'AMERICAs MetricIds',"
				
				+ "SUM(IF(md.Region = 'APAC' and `Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "' and md.SLA >= m.`SLA Target Green`,1,0)) / SUM(IF(md.Region = 'APAC' and `Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "', 1, 0)) AS 'APAC (" + periodFormat.format(previousFrom.getTime()) + ")',"
				+ "null AS 'APAC Status Previous',"
				+ "SUM(IF(md.Region = 'APAC' and `Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "' and md.SLA >= m.`SLA Target Green`,1,0)) / SUM(IF(md.Region = 'APAC' and `Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "', 1, 0)) AS 'APAC (" + periodFormat.format(from.getTime()) + ")',"
				+ "null AS 'APAC Status',"
				+ "GROUP_CONCAT(DISTINCT IF(md.Region = 'APAC',m.Id,null)) as 'APAC MetricIds',"
				
				+ "SUM(IF(md.Region = 'EMEA' and `Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "' and md.SLA >= m.`SLA Target Green`,1,0)) / SUM(IF(md.Region = 'EMEA' and `Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "', 1, 0)) AS 'EMEA (" + periodFormat.format(previousFrom.getTime()) + ")',"
				+ "null AS 'EMEA Status Previous',"
				+ "SUM(IF(md.Region = 'EMEA' and `Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "' and md.SLA >= m.`SLA Target Green`,1,0)) / SUM(IF(md.Region = 'EMEA' and `Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "', 1, 0)) AS 'EMEA (" + periodFormat.format(from.getTime()) + ")',"
				+ "null AS 'EMEA Status',"
				+ "GROUP_CONCAT(DISTINCT IF(md.Region = 'EMEA',m.Id,null)) as 'EMEA MetricIds',"
				
				+ "SUM(IF(`Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "' and md.SLA >= m.`SLA Target Green`,1,0)) / SUM(IF(`Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "', 1, 0)) AS 'Overall (" + periodFormat.format(previousFrom.getTime()) + ")',"
				+ "null AS 'Overall Status Previous',"
				+ "SUM(IF(`Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "' and md.SLA >= m.`SLA Target Green`,1,0)) / SUM(IF(`Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "', 1, 0)) AS 'Overall (" + periodFormat.format(from.getTime()) + ")',"
				+ "null AS 'Overall Status',"
				+ "GROUP_CONCAT(DISTINCT m.Id) as 'Overall MetricIds' "
				+ "FROM metrics_data md "
				+ "inner join metrics m on md.`Metric Id` = m.Id "
				+ "where ((`Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' "
				+ "and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "') or "
				+ "(`Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' "
				+ "and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "')) "
				+ "and `Function` = 'Operations' "
				+ "group by m.`Metric Group`, m.`Product Portfolio`"
				+ " UNION "
				+ "SELECT m.`Metric Group`, 'Overall' as 'Product Portfolio',"
				+ "SUM(IF(md.Region = 'AMERICAs' and `Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "' and md.SLA >= m.`SLA Target Green`,1,0)) / SUM(IF(md.Region = 'AMERICAs' and `Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "', 1, 0)) AS 'AMERICAs (" + periodFormat.format(previousFrom.getTime()) + ")',"
				+ "null AS 'AMERICAs Status Previous',"
				+ "SUM(IF(md.Region = 'AMERICAs' and `Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "' and md.SLA >= m.`SLA Target Green`,1,0)) / SUM(IF(md.Region = 'AMERICAs' and `Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "', 1, 0)) AS 'AMERICAs (" + periodFormat.format(from.getTime()) + ")',"
				+ "null AS 'AMERICAs Status',"
				+ "GROUP_CONCAT(DISTINCT IF(md.Region = 'AMERICAs',m.Id,null)) as 'AMERICAs MetricIds',"
				
				+ "SUM(IF(md.Region = 'APAC' and `Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "' and md.SLA >= m.`SLA Target Green`,1,0)) / SUM(IF(md.Region = 'APAC' and `Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "', 1, 0)) AS 'APAC (" + periodFormat.format(previousFrom.getTime()) + ")',"
				+ "null AS 'APAC Status Previous',"
				+ "SUM(IF(md.Region = 'APAC' and `Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "' and md.SLA >= m.`SLA Target Green`,1,0)) / SUM(IF(md.Region = 'APAC' and `Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "', 1, 0)) AS 'APAC (" + periodFormat.format(from.getTime()) + ")',"
				+ "null AS 'APAC Status',"
				+ "GROUP_CONCAT(DISTINCT IF(md.Region = 'APAC',m.Id,null)) as 'APAC MetricIds',"
				
				+ "SUM(IF(md.Region = 'EMEA' and `Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "' and md.SLA >= m.`SLA Target Green`,1,0)) / SUM(IF(md.Region = 'EMEA' and `Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "', 1, 0)) AS 'EMEA (" + periodFormat.format(previousFrom.getTime()) + ")',"
				+ "null AS 'EMEA Status Previous',"
				+ "SUM(IF(md.Region = 'EMEA' and `Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "' and md.SLA >= m.`SLA Target Green`,1,0)) / SUM(IF(md.Region = 'EMEA' and `Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "', 1, 0)) AS 'EMEA (" + periodFormat.format(from.getTime()) + ")',"
				+ "null AS 'EMEA Status',"
				+ "GROUP_CONCAT(DISTINCT IF(md.Region = 'EMEA',m.Id,null)) as 'EMEA MetricIds',"
				
				+ "SUM(IF(`Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "' and md.SLA >= m.`SLA Target Green`,1,0)) / SUM(IF(`Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "', 1, 0)) AS 'Overall (" + periodFormat.format(previousFrom.getTime()) + ")',"
				+ "null AS 'Overall Status Previous',"
				+ "SUM(IF(`Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "' and md.SLA >= m.`SLA Target Green`,1,0)) / SUM(IF(`Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "', 1, 0)) AS 'Overall (" + periodFormat.format(from.getTime()) + ")',"
				+ "null AS 'Overall Status',"
				+ "GROUP_CONCAT(DISTINCT m.Id) as 'Overall MetricIds' "
				+ "FROM metrics_data md "
				+ "inner join metrics m on md.`Metric Id` = m.Id "
				+ "where ((`Period` >= '" + Utility.getMysqldateformat().format(from.getTime()) + "' "
				+ "and `Period` <= '" + Utility.getMysqldateformat().format(to.getTime()) + "') or "
				+ "(`Period` >= '" + Utility.getMysqldateformat().format(previousFrom.getTime()) + "' "
				+ "and `Period` <= '" + Utility.getMysqldateformat().format(previousTo.getTime()) + "')) "
				+ "and `Function` = 'Operations' "
				+ "group by m.`Metric Group`) t "
				+ "order by `Metric Group`";
		ResultSet rs = dbs.get(analyticsDS).executeSelect(select, -1);
		return Utility.resultSetToObjectArray(rs, true);
	}
	 
	public Object getOperationsMetricsDataSummary3(Calendar from, Calendar to) throws Exception {
		List<MetricDetails> metricDetailsCurrentPeriod = Arrays.asList(getMetricsDataDetails(from, to));
		Calendar fromPreviousPeriod = Calendar.getInstance();
		Calendar toPreviousPeriod = Calendar.getInstance();
		fromPreviousPeriod.setTime(from.getTime());
		toPreviousPeriod.setTime(to.getTime());
		fromPreviousPeriod.add(Calendar.MONTH, -1);
		toPreviousPeriod.add(Calendar.MONTH, -1);
		List<MetricDetails> metricDetailsPreviousPeriod = Arrays.asList(getMetricsDataDetails(fromPreviousPeriod, toPreviousPeriod));
		
		Map<String, Map<String, Map<String, MetricDetailsSummary>>> regionmgpp = metricDetailsCurrentPeriod.stream()
				//.sorted((md1, md2) -> md1.getMetricGroup().compareTo(md2.getMetricGroup()))
				.collect(
						Collectors.groupingBy(MetricDetails::getMetricGroup, 
						Collectors.groupingBy(MetricDetails::getProductPortfolio, 
						Collectors.groupingBy(MetricDetails::getRegionDisplayName, 
						Collector.of( MetricDetailsSummary::new, MetricDetailsSummary::add, MetricDetailsSummary::combine)))));
		
		Map<String, Map<String, MetricDetailsSummary>> regionmg = metricDetailsCurrentPeriod.stream()
				.collect(
						Collectors.groupingBy(MetricDetails::getMetricGroup, 
						Collectors.groupingBy(MetricDetails::getRegionDisplayName,  
						Collector.of( MetricDetailsSummary::new, MetricDetailsSummary::add, MetricDetailsSummary::combine))));
		Map<String, Map<String, MetricDetailsSummary>> mgpp = metricDetailsCurrentPeriod.stream()
				.collect(
						Collectors.groupingBy(MetricDetails::getMetricGroup, 
						Collectors.groupingBy(MetricDetails::getProductPortfolio,  
						Collector.of( MetricDetailsSummary::new, MetricDetailsSummary::add, MetricDetailsSummary::combine))));
		Map<String, MetricDetailsSummary> mg = metricDetailsCurrentPeriod.stream()
				.collect(
						Collectors.groupingBy(MetricDetails::getMetricGroup, 
						Collector.of( MetricDetailsSummary::new, MetricDetailsSummary::add, MetricDetailsSummary::combine)));
		
		Map<String, Map<String, Map<String, MetricDetailsSummary>>> regionmgppPP = metricDetailsPreviousPeriod.stream()
				.collect(
						Collectors.groupingBy(MetricDetails::getMetricGroup, 
						Collectors.groupingBy(MetricDetails::getProductPortfolio, 
						Collectors.groupingBy(MetricDetails::getRegionDisplayName, 
						Collector.of( MetricDetailsSummary::new, MetricDetailsSummary::add, MetricDetailsSummary::combine)))));
		Map<String, Map<String, MetricDetailsSummary>> regionmgPP = metricDetailsPreviousPeriod.stream()
				.collect(
						Collectors.groupingBy(MetricDetails::getMetricGroup, 
						Collectors.groupingBy(MetricDetails::getRegionDisplayName,  
						Collector.of( MetricDetailsSummary::new, MetricDetailsSummary::add, MetricDetailsSummary::combine))));
		Map<String, Map<String, MetricDetailsSummary>> mgppPP = metricDetailsPreviousPeriod.stream()
				.collect(
						Collectors.groupingBy(MetricDetails::getMetricGroup, 
						Collectors.groupingBy(MetricDetails::getProductPortfolio,  
						Collector.of( MetricDetailsSummary::new, MetricDetailsSummary::add, MetricDetailsSummary::combine))));
		Map<String, MetricDetailsSummary> mgPP = metricDetailsPreviousPeriod.stream()
				.collect(
						Collectors.groupingBy(MetricDetails::getMetricGroup, 
						Collector.of( MetricDetailsSummary::new, MetricDetailsSummary::add, MetricDetailsSummary::combine)));
		
		
		Map<String, Object> summaryCurrentPeriod = new HashMap<String, Object>();
		summaryCurrentPeriod.put("metric_product_region", regionmgpp);
		summaryCurrentPeriod.put("metric_region", regionmg);
		summaryCurrentPeriod.put("metric_product", mgpp);
		summaryCurrentPeriod.put("metric", mg);
		Map<String, Object> summaryPreviousPeriod = new HashMap<String, Object>();
		summaryPreviousPeriod.put("metric_product_region", regionmgppPP);
		summaryPreviousPeriod.put("metric_region", regionmgPP);
		summaryPreviousPeriod.put("metric_product", mgppPP);
		summaryPreviousPeriod.put("metric", mgPP);
		Map<String, Object> summary = new HashMap<String, Object>();
		summary.put("current", summaryCurrentPeriod);
		summary.put("previous", summaryPreviousPeriod);
		summary.put("targetAmberEquivalent", MetricDetails.targetAmberEquivalent);
		summary.put("targetGreenEquivalent", MetricDetails.targetGreenEquivalent);

		return summary;
	}
	
	@SuppressWarnings("unchecked")
	public List<SimpleParameter> getMatchingMetrics(String query) {
		String localQuery = query.toLowerCase();
		List<SimpleParameter> retValue = new ArrayList<SimpleParameter>();
		List<Metric> slasToBeReturned = new ArrayList<Metric>();
		for (Metric sla: metrics.values()) {
			if (sla.getUniqueName().toLowerCase().contains(localQuery)) {
				slasToBeReturned.add(sla);
			}
		}
		Collections.sort(slasToBeReturned);
		for (Metric sla2 : slasToBeReturned) {
			retValue.add(new SimpleParameter(sla2.getUniqueName(), "" + sla2.getId()));
		}
		return retValue;
	}
		
	@Override
	public void finalize() throws Throwable {
		closeConnections();
		super.finalize();
	}
	
	public void closeConnections() {
		for (DbHelperConnPool db : dbs.values()) {
			db.closeConnection();
		}
	}
}