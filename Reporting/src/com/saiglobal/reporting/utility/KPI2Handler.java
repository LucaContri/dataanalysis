package com.saiglobal.reporting.utility;

import java.sql.ResultSet;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Calendar;
import java.util.Collections;
import java.util.Date;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Set;

import org.apache.commons.lang.StringUtils;

import com.saiglobal.reporting.model.RegionFilterType;
import com.saiglobal.reporting.model.SLAData;
import com.saiglobal.reporting.model.SimpleParameter;
import com.saiglobal.sf.core.data.DbHelperConnPool;
import com.saiglobal.sf.core.model.Region;
import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;

public class KPI2Handler {
	private GlobalProperties gp = null;
	private HashMap<String, SLA> slas = null;
	private HashMap<String, DbHelperConnPool> dbs = null;
	private static final String analyticsDS = "analytics";
	private static final SimpleDateFormat mysqlDateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
	private static final long thresholdMs = 3456000000L;
	
	public KPI2Handler(GlobalProperties gp) throws Exception {
		this.gp = gp;
		init();
	}
	
	private void init() throws Exception {
		slas = new LinkedHashMap<String, SLA>();
		dbs = new HashMap<String, DbHelperConnPool>();
		dbs.put(analyticsDS, new DbHelperConnPool(gp, "jdbc/" + analyticsDS));
		ResultSet rs = dbs.get(analyticsDS).executeSelectThreadSafe("select * from sla order by `Reporting Order`", -1);
		while (rs.next()) {
			SLA sla = new SLA(
					rs.getString("Team"),
					rs.getString("Name"),
					rs.getString("Description"),
					rs.getString("SLA Unit"),
					rs.getString("Enlighten Activities"),
					rs.getString("Backlog Datasource"),
					rs.getString("command backlog"),
					rs.getString("Completed Datasource"),
					rs.getString("command completed"),
					rs.getDouble("SLA Target"),
					rs.getDouble("Activity Duration"),
					rs.getString("SLA Target Text"),
					rs.getString("Region Filter Type"),
					rs.getBoolean("Is MultiRegion"),
					rs.getInt("Reporting Order"));
			//sla.setTags(getTags(sla));
			slas.put(sla.getName(), sla);
			if(!dbs.containsKey(sla.getBacklogDatasource())) {
				dbs.put(sla.getBacklogDatasource(), new DbHelperConnPool(gp, "jdbc/" + sla.getBacklogDatasource()));
			}
			if(!dbs.containsKey(sla.getCompletedDataSource())) {
				dbs.put(sla.getCompletedDataSource(), new DbHelperConnPool(gp, "jdbc/" + sla.getCompletedDataSource()));
			}
		}
		dbs.get(analyticsDS).closeConnection();
	}
	
	public Set<String> getAvailableSLAs() {
		return slas.keySet();
	}
	
	public boolean hasSLA(String slaName) {
		for (String aSlaName : slas.keySet()) {
			if(aSlaName.equalsIgnoreCase(slaName))
				return true;
		}
		return false;
	}
	
	public String getPerformanceDataDetailsCsv(Region region, String slaName, Calendar from, Calendar to) throws Exception {
		if (!hasSLA(slaName))
			return null;
		SLA sla = slas.get(slaName);
		if (sla.getCompletedCommand()!=null && sla.getCompletedDataSource() != null) {
			
			String completedQuery = updateRegionWhere(getCompletedQuery(sla.getCompletedCommand()), sla.getRegionFilterFieldType(), region).replaceAll("@fromP",mysqlDateFormat.format(from.getTime())).replaceAll("@toP", mysqlDateFormat.format(to.getTime()));
			try {
				return Utility.resultSetToCsv(dbs.get(sla.getCompletedDataSource()).executeSelect(completedQuery, -1));
			} catch (Exception e) {
				throw e;
			} finally {
				dbs.get(sla.getCompletedDataSource()).closeConnection();
			}
		}
		
		return null;
	}
	
	public Object[][] getPerformanceDataDetailsArray(Region region, String slaName, Calendar from, Calendar to) throws Exception {
		if (!hasSLA(slaName))
			return null;
		SLA sla = slas.get(slaName);
		if (sla.getCompletedCommand()!=null && sla.getCompletedDataSource() != null) {
			
			String completedQuery = updateRegionWhere(getCompletedQuery(sla.getCompletedCommand()), sla.getRegionFilterFieldType(), region).replaceAll("@fromP",mysqlDateFormat.format(from.getTime())).replaceAll("@toP", mysqlDateFormat.format(to.getTime()));
			try {
				return Utility.resultSetToObjectArray(dbs.get(sla.getCompletedDataSource()).executeSelect(completedQuery, -1), true);
			} catch (Exception e) {
				throw e;
			} finally {
				dbs.get(sla.getCompletedDataSource()).closeConnection();
			}
		}
		
		return null;
	}
	
	public Object[][] getBacklogDataDetailsArray(Region region, String slaName) throws Exception {
		if (!hasSLA(slaName))
			return null;
		SLA sla = slas.get(slaName);
		if (sla.getBacklogCommand() != null && sla.getBacklogDatasource() != null) {
			String backlogQuery =  updateRegionWhere(getBacklogQuery(sla.getBacklogCommand()), sla.getRegionFilterFieldType(), region);
			try {
				return Utility.resultSetToObjectArray(dbs.get(sla.getBacklogDatasource()).executeSelect(backlogQuery, -1), true);
			} catch (Exception e) {
				throw e;
			} finally {
				dbs.get(sla.getBacklogDatasource()).closeConnection();
			}
		}
		return null;
	}
	
	public String getBacklogDataDetailsCsv(Region region, String slaName) throws Exception {
		if (!hasSLA(slaName))
			return null;
		SLA sla = slas.get(slaName);
		if (sla.getBacklogCommand() != null && sla.getBacklogDatasource() != null) {
			String backlogQuery =  updateRegionWhere(getBacklogQuery(sla.getBacklogCommand()), sla.getRegionFilterFieldType(), region);
			try {
				return Utility.resultSetToCsv(dbs.get(sla.getBacklogDatasource()).executeSelect(backlogQuery, -1));
			} catch (Exception e) {
				throw e;
			} finally {
				dbs.get(sla.getBacklogDatasource()).closeConnection();
			}
		}
		return null;
	}
	
	private String getCompletedQuery(String aQuery) {
		return "select "
				+ "`Team`, "
				+ "`Activity`, "
				+ "`Details`, "
				+ "`Region`, "
				+ "concat('<a href=\"https://na14.salesforce.com/', `Id`, '\" target=\"_blank\">', `Name`, '</a>') as `Compass Ref`, "
				+ "`Owner`, "
				+ "`TimeZone`, "
				+ "convert_tz(`From`, 'UTC', `TimeZone`) as 'Start Date/Time', "
				+ "convert_tz(`SLA Due`, 'UTC', `TimeZone`) as 'SLA Due Date/Time', "
				+ "convert_tz(`To`, 'UTC', `TimeZone`) as 'End Date/Time', "
				+ "`Tags`, "
				+ "if(`SLA Due`<`To`,1,0) as 'Over SLA' "
				+ "from (" + aQuery + ") w";
	}
	
	private String getBacklogQuery(String aQuery) {
		return "select "
				+ "`Team`, "
				+ "`Activity`, "
				+ "`Details`, "
				+ "`Region`, "
				+ "concat('<a href=\"https://na14.salesforce.com/', `Id`, '\" target=\"_blank\">', `Name`, '</a>') as `Compass Ref`, "
				+ "`Owner`, "
				+ "`TimeZone`, "
				+ "convert_tz(`From`, 'UTC', `TimeZone`) as 'Start Date/Time', "
				+ "convert_tz(`SLA Due`, 'UTC', `TimeZone`) as 'SLA Due Date/Time', "
				+ "null as 'End Date/Time', "
				+ "`Tags`, "
				+ "if(`SLA Due`<utc_timestamp(),1,0) as 'Over SLA' "
				+ "from (" + aQuery + ") w";
	}

	public Object[][] getAllSLADataSummary(Region region, Calendar from, Calendar to, boolean expandRegions) throws Exception {
		
		List<Object[]> allResults = new ArrayList<Object[]>();
		boolean addHeader = true;
		for (SLA sla: slas.values()) {
			if (!sla.isMultiRegion()) continue;
			String completedQuery1 = null, completedQuery2 = null, backlogQuery1 = null, backlogQuery2 = null;
			if (sla.getBacklogCommand()!=null && sla.getBacklogDatasource() != null) {
				String backlogCommand = updateRegionWhere(sla.getBacklogCommand(), sla.getRegionFilterFieldType(), region);
				backlogQuery1 = "(select '" + sla.getDescription() + "' as 'Description', '" + sla.getName() + "' as 'Metric', 'WIP' as 'Measure', ";
				backlogQuery2 = "(select '" + sla.getDescription() + "' as 'Description', '" + sla.getName() + "' as 'Metric', 'WIP (over SLA)' as 'Measure', ";
				for (Region countryRegion : Region.getCountryRegions(region)) {
					backlogQuery1 += " count(distinct if(t.`Region` in " + getRegionInClause(sla.getRegionFilterFieldType(), countryRegion) + ", Id, null)) as '" + countryRegion.getName() + "',";
					backlogQuery2 += " count(distinct if(t.`Region` in " + getRegionInClause(sla.getRegionFilterFieldType(), countryRegion) + " and utc_timestamp()>t.`SLA Due`, Id, null)) as '" + countryRegion.getName() + "',";
				}
				backlogQuery1 = Utility.removeLastChar(backlogQuery1);
				backlogQuery2 = Utility.removeLastChar(backlogQuery2);
				backlogQuery1 += " from (" + backlogCommand +") t)";
				backlogQuery2 += " from (" + backlogCommand +") t)";
			}
			if (sla.getCompletedCommand()!=null && sla.getCompletedDataSource() != null) {
				String completedCommand = updateRegionWhere(sla.getCompletedCommand(), sla.getRegionFilterFieldType(), region);
				completedQuery1 = "(select '" + sla.getDescription() + "' as 'Description', '" + sla.getName() + "' as 'Metric', 'Completed' as 'Measure',"; 
				completedQuery2 = "(select '" + sla.getDescription() + "' as 'Description', '" + sla.getName() + "' as 'Metric', 'Completed (over SLA)' as 'Measure',"; 
				for (Region countryRegion : Region.getCountryRegions(region)) {
					completedQuery1 += " count(distinct if(t.`Region` in " + getRegionInClause(sla.getRegionFilterFieldType(), countryRegion) + ", Id, null)) as '" + countryRegion.getName() + "',";
					completedQuery2 += " count(distinct if(t.`Region` in " + getRegionInClause(sla.getRegionFilterFieldType(), countryRegion) + " and t.`To`>t.`SLA Due`, Id, null)) as '" + countryRegion.getName() + "',";
				}
				completedQuery1 = Utility.removeLastChar(completedQuery1);
				completedQuery2 = Utility.removeLastChar(completedQuery2);
				completedQuery1 += " from (" + completedCommand.replaceAll("@fromP",mysqlDateFormat.format(from.getTime())).replaceAll("@toP", mysqlDateFormat.format(to.getTime())) +") t)";
				completedQuery2 += " from (" + completedCommand.replaceAll("@fromP",mysqlDateFormat.format(from.getTime())).replaceAll("@toP", mysqlDateFormat.format(to.getTime())) +") t)";
			}
			String slaQuery = (completedQuery1==null)?"":(completedQuery1 + " union " + completedQuery2); 
			slaQuery += ((slaQuery=="")?"":((backlogQuery1==null)?"":" union ")) + ((backlogQuery1==null)?"":(backlogQuery1 + " union " + backlogQuery2));
			if(slaQuery != "") {
				ResultSet rs = dbs.get(sla.getBacklogDatasource()).executeSelect(slaQuery, -1);
				allResults.addAll(Arrays.asList(Utility.resultSetToObjectArray(rs, addHeader)));
				addHeader = false;
			}
		}
		
		return allResults.toArray(new Object[allResults.size()][]);
	}
	
	public List<SLAData> getAllSLAData(Region region, Calendar from, Calendar to, boolean expandRegions) throws Exception {
		List<SLAData> slasData = new ArrayList<SLAData>();
		if (expandRegions && region.subRegions != null && region.subRegions.size()>0) {
			for (Region subRegion : region.subRegions) {
				slasData.addAll(getAllSLAData(subRegion, from, to, expandRegions));
			}
		} else {
			for (SLA sla : slas.values()) {
				if(!sla.isMultiRegion())
					continue;
				slasData.add(getSLAData(region, sla.getName(), from, to, false));
			}
		}
		return slasData;
	}
	
	public SLAData getSLAData(Region region, String slaName, Calendar from, Calendar to) throws Exception {
		return this.getSLAData(region, slaName, from, to, true);
	}
	public SLAData getSLAData(Region region, String slaName, Calendar from, Calendar to, boolean processedByPeriodDetails) throws Exception {
		
		if (!hasSLA(slaName))
			return null;
		SLA sla = slas.get(slaName);
		SLAData data = new SLAData();
		
		data.setSlaName(sla.getName());
		data.setTeam(sla.getTeam());
		data.setRegionName(region.getName());
		data.setSlaDescription(sla.getDescription());
		data.setSlaUnit(sla.getSlaUnit());
		data.setSlaTarget(sla.getSlaTarget());
		data.setFrom(from);
		data.setTo(to);
		data.setActivityDuration(sla.getActivityDurtion());
		data.setSlaTargetText(sla.getSlaTargetText());
		
		if (sla.getBacklogCommand()!=null && sla.getBacklogDatasource() != null) {
			// Populate qtyBacklog; qtyBacklogOverSLA; avgAgingTimeHrs;
			String backlogCommand = updateRegionWhere(sla.getBacklogCommand(), sla.getRegionFilterFieldType(), region);
			
			String backlogQuery = "select count(distinct Id) as 'backlog', count(distinct if (utc_timestamp()>t.`SLA Due`,Id, null)) as 'backlogOverSLA', avg(TIMESTAMPDIFF(HOUR,t.`From`, utc_timestamp())) as 'AverageAging (Hrs)' from (" + backlogCommand +") t";
			try {
				ResultSet rs = dbs.get(sla.getBacklogDatasource()).executeSelect(backlogQuery, -1);
				while (rs.next()) {
					data.setQtyBacklog(rs.getInt("backlog"));
					data.setQtyBacklogOverSLA(rs.getInt("backlogOverSLA"));
					data.setAvgAgingTimeHrs(rs.getDouble("AverageAging (Hrs)"));
				}
				data.setHasBacklog(true);
			} catch (Exception e) {
				throw e;
			} finally {
				dbs.get(sla.getBacklogDatasource()).closeConnection();
			}
		} else {
			data.setHasBacklog(false);
		}
		if (sla.getCompletedCommand()!=null && sla.getCompletedDataSource() != null) {
			// Populate qtyProcessed; qtyProcessedOverSLA; avgProcessingTimeHrs;
			String completedCommand = updateRegionWhere(sla.getCompletedCommand(), sla.getRegionFilterFieldType(), region);
			String completedQuery = "select count(distinct t.`Id`) as 'Processed', count(if (t.`To`>t.`SLA Due`,t.`Id`, null)) as 'ProcessedOverSLA', avg(TIMESTAMPDIFF(HOUR,t.`From`, t.`To`)) as 'avgProcessingTime (Hrs)' from (" + 
					completedCommand.replaceAll("@fromP",mysqlDateFormat.format(from.getTime())).replaceAll("@toP", mysqlDateFormat.format(to.getTime())) +
				") t;";
			try {
				ResultSet rs = dbs.get(sla.getCompletedDataSource()).executeSelect(completedQuery, -1);
				while (rs.next()) {
					data.setQtyProcessed(rs.getInt("Processed"));
					data.setQtyProcessedOverSLA(rs.getInt("ProcessedOverSLA"));
					data.setAvgProcessingTimeHrs(rs.getDouble("avgProcessingTime (Hrs)"));
				}
				if(processedByPeriodDetails) {
					String date_format = "%Y-%m";
					long timeDiffMs = to.getTimeInMillis()-from.getTimeInMillis(); 
					if (timeDiffMs<thresholdMs)
						date_format = "%Y-%m-%d";
					completedQuery = "select date_format(t.`To`, '" + date_format + "') as 'Period', count(distinct t.`Id`) as 'Processed', count(if (t.`To`>t.`SLA Due`,t.`Id`, null)) as 'ProcessedOverSLA', avg(TIMESTAMPDIFF(HOUR,t.`From`, t.`To`)) as 'avgProcessingTime (Hrs)' from (" + 
							completedCommand.replaceAll("@fromP", mysqlDateFormat.format(from.getTime())).replaceAll("@toP", mysqlDateFormat.format(to.getTime())) +
							") t group by `Period` order by `Period`;";
					rs = dbs.get(sla.getCompletedDataSource()).executeSelect(completedQuery, -1);
					data.processedByPeriod = Utility.resultSetToObjectArray(rs, true);
				}
				data.setHasProcessing(true);
			} catch (Exception e) {
				throw e;
			} finally {
				dbs.get(sla.getCompletedDataSource()).closeConnection();
			}
		} else {
			data.setHasProcessing(false);
		}
		return data;
	}
	
	public List<SimpleParameter> getMatchingSLAs(String query, boolean multiRegion) {
		String localQuery = query.toLowerCase();
		List<SimpleParameter> retValue = new ArrayList<SimpleParameter>();
		List<SLA> slasToBeReturned = new ArrayList<SLA>();
		for (SLA sla: slas.values()) {
			if (sla.getName().toLowerCase().contains(localQuery) && (multiRegion?sla.isMultiRegion():true)) {
				slasToBeReturned.add(sla);
			}
		}
		//Collections.sort(slasToBeReturned);
		for (SLA sla2 : slasToBeReturned) {
			retValue.add(new SimpleParameter(sla2.getName(), sla2.getName()));
		}
		return retValue;
	}
	
	public List<SimpleParameter> getMatchingTags(String query, boolean multiRegion) {
		String localQuery = query.toLowerCase();
		Set<String> tagsToBeReturned = new HashSet<String>();
		
		for (SLA sla: slas.values()) {
			if (multiRegion?sla.isMultiRegion():true) {
				// Query metric for tags
				for (String tag : sla.getTags()) {
					if(tag.contains(localQuery))
						tagsToBeReturned.add(tag);
				}
			}
		}
		List<SimpleParameter> retValue = new ArrayList<SimpleParameter>();
		for (String tag : tagsToBeReturned) {
			retValue.add(new SimpleParameter(tag, tag));
		}
		Collections.sort(retValue);
		return retValue;
	}
	
	public List<SimpleParameter> getMatchingRegions(String query) {
		String localQuery = query.toLowerCase();
		List<SimpleParameter> retValue = new ArrayList<SimpleParameter>();
		for (Region region: Region.values()) {
			if (region.getName().toLowerCase().contains(localQuery) && region.isEnabled() && !region.isBaseRegion()) {
				retValue.add(new SimpleParameter(region.getName(),region.toString()));
			}
		}
		Collections.sort(retValue);
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
	
	private String getRegionInClause(RegionFilterType type, Region region) {
		switch (type) {
		case AdministrationOwnership:
			return "('" + StringUtils.join(region.getAdministrationOwnerships(), "','") + "')";
		case SchedulingOwner:
			return "('" + StringUtils.join(region.getSchedulingOwnerships(), "','") + "')";
		case RevenueOwnership:
			return "('" + StringUtils.join(region.getRevenueOwnerships(), "','") + "')";
		case ClientOwnership:
			return "('" + StringUtils.join(region.getClientOwnerships(), "','") + "')";
		case Unknown:
			// Do noting
			return "";
		default:
			return "";
		}
	}
	
	private String updateRegionWhere(String query, RegionFilterType type, Region region) {
		return query.replace("@regions", getRegionInClause(type, region));
	}
	
	private Set<String> getTags(SLA sla) {
		Set<String> tagsStrings = new HashSet<String>();
		try {
			if (sla.getCompletedCommand() != null && sla.getCompletedDataSource() != null) {
				if(sla.getName().contains("ARG")) {
					System.out.println(sla.getName());
				}
				ResultSet rs = dbs.get(sla.getCompletedDataSource()).executeSelect(
						updateRegionWhere("select distinct lower(t2.`Tags`) as 'Tags' from (" + sla.getCompletedCommand() + ") t2", sla.getRegionFilterFieldType(), Region.GLOBAL).replaceAll("@fromP","1970-01-01").replaceAll("@toP", Utility.getActivitydateformatter().format(new Date())), -1);
				while (rs.next()) {
					String tagsString = rs.getString("Tags");
					if (tagsString != null) {
						for (String tag : tagsString.split(";")) {
							tagsStrings.add(tag);
						}
					}
				}
			}
			if (sla.getBacklogCommand() != null && sla.getBacklogDatasource() != null) {
				ResultSet rs = dbs.get(sla.getBacklogDatasource()).executeSelect(
						updateRegionWhere("select distinct lower(t2.`Tags`) as 'Tags' from (" + sla.getBacklogCommand() + ") t2", sla.getRegionFilterFieldType(), Region.GLOBAL), -1);
				while (rs.next()) {
					String tagsString = rs.getString("Tags");
					if (tagsString != null) {
						for (String tag : tagsString.split(";")) {
							tagsStrings.add(tag);
						}
					}
				}
			}
		} catch(Exception e) {
			e.printStackTrace();
		}
		return tagsStrings;
	}
}

@SuppressWarnings("rawtypes")
class SLA implements Comparable {
	  private String team,name,description,slaUnit,enlightenActivities,backlogDatasource,backlogCommand,completedDataSource,completedCommand,slaTargetText;
	  private RegionFilterType regionFilterFieldType;
	  private double slaTarget,activityDurtion;
	  private boolean multiRegion;
	  private int reportingOrder;
	  private Set<String> tags;
	  
	  public SLA(String team, String name, String description, String slaUnit,
			String enlightenActivities, String backlogDatasource,
			String backlogCommand, String completedDataSource,
			String completedCommand, double slaTarget,double activityDuration, String slaTargetText, String regionFilterFieldType, boolean multiRegion, int reportingOrder) {
		super();
		this.team = team;
		this.name = name;
		this.description = description;
		this.slaUnit = slaUnit;
		this.enlightenActivities = enlightenActivities;
		this.backlogDatasource = backlogDatasource;
		this.backlogCommand = backlogCommand;
		this.completedDataSource = completedDataSource;
		this.completedCommand = completedCommand;
		this.slaTarget = slaTarget;
		this.activityDurtion = activityDuration;
		this.slaTargetText = slaTargetText;
		if (regionFilterFieldType != null)
			this.regionFilterFieldType = RegionFilterType.getValueForName(regionFilterFieldType);
		else
			this.regionFilterFieldType = RegionFilterType.Unknown;
		this.multiRegion = multiRegion;
		this.reportingOrder = reportingOrder;
	
	}
	
	public Set<String> getTags() {
		return tags;
	}


	public void setTags(Set<String> tags) {
		this.tags = tags;
	}

	public int getReportingOrder() {
		return reportingOrder;
	}


	public void setReportingOrder(int reportingOrder) {
		this.reportingOrder = reportingOrder;
	}


	public boolean isMultiRegion() {
		return multiRegion;
	}


	public void setMultiRegion(boolean multiRegion) {
		this.multiRegion = multiRegion;
	}


	public String getSlaTargetText() {
		return slaTargetText;
	}


	public void setSlaTargetText(String slaTargetText) {
		this.slaTargetText = slaTargetText;
	}


	public double getActivityDurtion() {
		return activityDurtion;
	}
	public void setActivityDurtion(double activityDurtion) {
		this.activityDurtion = activityDurtion;
	}
	public String getTeam() {
		return team;
	}
	public void setTeam(String team) {
		this.team = team;
	}
	public String getName() {
		return name;
	}
	public void setName(String name) {
		this.name = name;
	}
	public String getDescription() {
		return description;
	}
	public void setDescription(String description) {
		this.description = description;
	}
	public String getSlaUnit() {
		return slaUnit;
	}
	public void setSlaUnit(String slaUnit) {
		this.slaUnit = slaUnit;
	}
	public String getEnlightenActivities() {
		return enlightenActivities;
	}
	public void setEnlightenActivities(String enlightenActivities) {
		this.enlightenActivities = enlightenActivities;
	}
	public String getBacklogDatasource() {
		return backlogDatasource;
	}
	public void setBacklogDatasource(String backlogDatasource) {
		this.backlogDatasource = backlogDatasource;
	}
	public String getBacklogCommand() {
		return backlogCommand;
	}
	public void setBacklogCommand(String backlogCommand) {
		this.backlogCommand = backlogCommand;
	}
	public String getCompletedDataSource() {
		return completedDataSource;
	}
	public void setCompletedDataSource(String completedDataSource) {
		this.completedDataSource = completedDataSource;
	}
	public String getCompletedCommand() {
		return completedCommand;
	}
	public void setCompletedCommand(String completedCommand) {
		this.completedCommand = completedCommand;
	}
	public double getSlaTarget() {
		return slaTarget;
	}
	public void setSlaTarget(double slaTarget) {
		this.slaTarget = slaTarget;
	}

	public RegionFilterType getRegionFilterFieldType() {
		return regionFilterFieldType;
	}

	public void setRegionFilterFieldType(RegionFilterType regionFilterFieldType) {
		this.regionFilterFieldType = regionFilterFieldType;
	}

	public String getId() {
		return this.getTeam()+" - "+this.getName();
	}
	
	@Override
	public int compareTo(Object arg0) {
		if (!(arg0 instanceof SLA))
			throw new ClassCastException();
		return (this.reportingOrder - ((SLA)arg0).reportingOrder);
	}
}
