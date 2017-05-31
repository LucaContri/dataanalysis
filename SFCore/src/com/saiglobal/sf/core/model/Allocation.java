package com.saiglobal.sf.core.model;

import java.util.Date;
import java.util.HashMap;
import java.util.List;

public class Allocation {

	private Date from;
	private Date to;
	// Summary variables
	private List<Summary> summary;
	private HashMap<String, Double> totals;
	
	private List<Schedule> allocation;
	
	public HashMap<String, Double> getTotals() {
		return totals;
	}
	public void setTotals(HashMap<String, Double> totals) {
		this.totals = totals;
	}
	
	public Date getFrom() {
		return from;
	}
	public void setFrom(Date from) {
		this.from = from;
	}
	public Date getTo() {
		return to;
	}
	public void setTo(Date to) {
		this.to = to;
	}
	public List<Summary> getSummary() {
		return summary;
	}
	public void setSummary(List<Summary> summary) {
		this.summary = summary;
	}
	public List<Schedule> getAllocation() {
		return allocation;
	}
	public void setAllocation(List<Schedule> allocation) {
		this.allocation = allocation;
	}
	
}

class Summary {
	String name;
	double value;
	public String getName() {
		return name;
	}
	public void setName(String name) {
		this.name = name;
	}
	public double getValue() {
		return value;
	}
	public void setValue(double value) {
		this.value = value;
	}
	
}
