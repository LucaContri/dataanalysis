package com.saiglobal.reporting.model;

import java.util.HashMap;

public class ProcessQueue {
	public String name;
	public double quantity;
	public String quantityUnit;
	public double agingAvg;
	public double agingStdDev;
	public String agingUnit;
	public int withinSLA;
	public Object[][] details; // {id, Name, In Timestamp, Out Timestamp,
								// Created By, Submitted By, Assigned To, Link}
	private String agingName = "Aging (Days)";
	
	public ProcessQueue(String name, String quantityUnit, String agingUnit) {
		this.name = name;
		this.quantityUnit = quantityUnit;
		this.agingUnit = agingUnit;
	}
	
	public ProcessQueue(String name, String quantityUnit, String agingUnit, String agingName) {
		this.name = name;
		this.quantityUnit = quantityUnit;
		this.agingUnit = agingUnit;
		this.agingName = agingName;
	}
	
	public void setDetails(Object[][] details) {
		this.details = details;
		HashMap<String, Integer> headers = new HashMap<String, Integer>();
		double powerSum1 = 0;
		double powerSum2 = 0;
		this.agingAvg = 0;
		this.agingStdDev = 0;
		this.quantity = 0;
		this.withinSLA = 0;
		
		for (int i=0; i<details.length; i++) {
			if (i==0) {
				for (int j=0; j<details[i].length; j++) {
					headers.put(details[i][j].toString(), j);
				}
			} else {
			    powerSum1 += (Integer) details[i][headers.get(agingName)];
			    this.agingAvg = (this.agingAvg*this.quantity + (Integer) details[i][headers.get(agingName)])/(this.quantity+1);
			    powerSum2 += Math.pow((Integer) details[i][headers.get(agingName)], 2);
			    this.quantity++;
			    this.withinSLA += (Long) details[i][headers.get("WithinSLA")];
			}
		}
		this.agingStdDev = Math.sqrt(this.quantity*powerSum2 - Math.pow(powerSum1, 2))/this.quantity;
		if(Double.isNaN(this.agingStdDev))
			this.agingStdDev = 0;
	}
}
