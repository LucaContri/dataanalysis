package com.saiglobal.reporting.model;

import java.util.List;

public class Report {
	private String name, description, datasource, query, group;
	private int id;
	private List<ReportFilter> reportFilters = null;
	
	public Report(int id, String name, String group, String description, String datasource, String query) {
		super();
		this.id = id;
		this.name = name;
		this.description = description;
		this.datasource = datasource;
		this.query = query;
		this.group = group;
	}

	public List<ReportFilter> getReportFilters() {
		return reportFilters;
	}

	public void setReportFilters(List<ReportFilter> reportFilters) {
		this.reportFilters = reportFilters;
	}

	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}


	public String getGroup() {
		return group;
	}

	public void setGroup(String group) {
		this.group = group;
	}

	public String getDatasource() {
		return datasource;
	}

	public void setDatasource(String datasource) {
		this.datasource = datasource;
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

	public String getQuery() {
		return query;
	}

	public void setQuery(String query) {
		this.query = query;
	}
	
}
