package com.saiglobal.reporting.utility;

import java.nio.file.FileVisitOption;
import java.sql.ResultSet;
import java.sql.SQLException;
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
import java.util.ServiceLoader;
import java.util.Set;

import org.apache.commons.lang.StringUtils;

import com.saiglobal.reporting.model.RegionFilterType;
import com.saiglobal.reporting.model.Report;
import com.saiglobal.reporting.model.ReportFilter;
import com.saiglobal.reporting.model.ReportFilterType;
import com.saiglobal.reporting.model.SLAData;
import com.saiglobal.reporting.model.SimpleParameter;
import com.saiglobal.sf.core.data.DbHelperConnPool;
import com.saiglobal.sf.core.model.Region;
import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;

public class ReportHandler {
	private GlobalProperties gp = null;
	private List<Report> reports = null;
	private HashMap<String, DbHelperConnPool> dbs = null;
	private static final String analyticsDS = "analytics";
	private static final SimpleDateFormat mysqlDateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
	private static final long thresholdMs = 3456000000L;
	
	public ReportHandler(GlobalProperties gp) throws Exception {
		this.gp = gp;
		init();
	}
	
	private void init() throws Exception {
		reports = new ArrayList<Report>();
		dbs = new HashMap<String, DbHelperConnPool>();
		dbs.put(analyticsDS, new DbHelperConnPool(gp, "jdbc/" + analyticsDS));
		ResultSet rs = dbs.get(analyticsDS).executeSelectThreadSafe("select * from reports", -1);
		while (rs.next()) {
			Report report = new Report(rs.getInt("id"), rs.getString("name"), rs.getString("group"), rs.getString("description"), rs.getString("datasource"), rs.getString("query"));
			if(!dbs.containsKey(report.getDatasource())) {
				dbs.put(report.getDatasource(), new DbHelperConnPool(gp, "jdbc/" + report.getDatasource()));
			}
			report.setReportFilters(getReportFilters(report, rs.getString("filters")));
			reports.add(report);
		}
		
		dbs.get(analyticsDS).closeConnection();
	}
	
	private List<ReportFilter> getReportFilters(Report report, String filtersString) throws Exception {
		if (filtersString == null)
			return null;
		List<ReportFilter> list = new ArrayList<ReportFilter>();
		String[] filtersArray = filtersString.split(";");
		for (String filterString : filtersArray) {
			String[] filterParts = filterString.split(",");
			if (filterParts.length != 3)
				continue;
			String fieldName = filterParts[0];
			String displayName = filterParts[1];
			ReportFilterType type = ReportFilterType.valueOf(filterParts[2]);
			String[] possibleValues = null;
			if (type.equals(ReportFilterType.LIST)) 
				possibleValues = getPossibleValues(report, fieldName);
			
			ReportFilter filter = new ReportFilter(displayName, fieldName, possibleValues, type);
			list.add(filter);
		}
		return list;
	}
	
	private String[] getPossibleValues(Report report, String fieldName) throws Exception {
		int from  = report.getQuery().toLowerCase().indexOf("from");
		int to = report.getQuery().toLowerCase().lastIndexOf("group by");
		if (to<0)
			to = report.getQuery().length();
		String query = "select group_concat(distinct " + fieldName + ") as 'valuesList' " + report.getQuery().substring(from,to);
		ResultSet rs = dbs.get(report.getDatasource()).executeSelect(query, -1);
		while (rs.next()) {
			return rs.getString("valuesList").split(",");
		}
		return null;
	}
	
	public List<Report> getReports() {
		return reports;
	}
	
	public List<Report> getReportsList() {
		List<Report> retValue = new ArrayList<Report>();
		for (Report report : reports) {
			Report copy = new Report(report.getId(),report.getName(), report.getGroup(),report.getDescription(), null, null);
			retValue.add(copy);
		}
		return retValue;
	}
	
	public HashMap<String, Object> getReportPreview(int reportId) throws Exception {
		Report report = getReportById(reportId);
		if (report != null) {
			HashMap<String, Object> retValue = new HashMap<String, Object>();
			retValue.put("report", report);
			ResultSet rs = dbs.get(report.getDatasource()).executeSelect(report.getQuery(), -1);
			retValue.put("preview", Utility.resultSetToObjectArray(rs,true));
			return retValue;
		}
		return null;
	}
	public HashMap<String, Object> query(String query, String datasource) throws Exception {
		Report report = new Report(-1, "User Query", "Custom", "None", datasource, query);
		if (report != null) {
			HashMap<String, Object> retValue = new HashMap<String, Object>();
			retValue.put("report", report);
			ResultSet rs = dbs.get(report.getDatasource()).executeSelect(report.getQuery(), -1);
			retValue.put("preview", Utility.resultSetToObjectArray(rs,true));
			return retValue;
		}
		return null;
	}
	
	public String downloadReport(String query, String datasource) throws Exception {
		Report report = new Report(-1, "User Query", "Custom", "None", datasource, query);
		if (report != null) {
			ResultSet rs = dbs.get(report.getDatasource()).executeSelect(report.getQuery(), -1);
			return Utility.resultSetToCsv(rs);
		}
		return "";
	}
	
	public String downloadReport(int reportId) throws Exception {
		Report report = getReportById(reportId);
		if (report != null) {
			ResultSet rs = dbs.get(report.getDatasource()).executeSelect(report.getQuery(), -1);
			return Utility.resultSetToCsv(rs);
		}
		return "";
	}
	
	public Report getReportById(int id) {
		for (Report report : reports) {
			if (report.getId()==id)
				return report;
		}
		return null;
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
