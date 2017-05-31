package com.saiglobal.reporting.model;

public class ReportFilter {
	private String name, fieldName;
	private String[] possibleValues;
	private ReportFilterType filterType;
	public String getName() {
		return name;
	}
	public void setName(String name) {
		this.name = name;
	}
	public String getFieldName() {
		return fieldName;
	}
	public void setFieldName(String fieldName) {
		this.fieldName = fieldName;
	}
	public String[] getPossibleValues() {
		return possibleValues;
	}
	public void setPossibleValues(String[] possibleValues) {
		this.possibleValues = possibleValues;
	}
	public ReportFilterType getFilterType() {
		return filterType;
	}
	public void setFilterType(ReportFilterType filterType) {
		this.filterType = filterType;
	}
	public ReportFilter(String name, String fieldName, String[] possibleValues,
			ReportFilterType filterType) {
		super();
		this.name = name;
		this.fieldName = fieldName;
		this.possibleValues = possibleValues;
		this.filterType = filterType;
	}
}
