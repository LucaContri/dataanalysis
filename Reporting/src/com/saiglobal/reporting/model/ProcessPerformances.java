package com.saiglobal.reporting.model;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

public class ProcessPerformances {
	public String name;
	public int[] quantity;
	public int[] withinSLA;
	public String quantityUnit;
	public double[] avg;
	public double[] stdDev;
	public String unit;
	public String[] group; // e.g. Jan, Feb, etc...
	public String groupType; // e.g. Period
	public double SLA; // e.g. 2 days
	public double confidence; // e.g. 99.7%
	public Object[][] details;
	public boolean reportSlaOnly = false;
	private String fromName = "From";
	private String toName = "To";
	
	public ProcessPerformances(String name, String qtyUnit, String measureUnit, String groupType, double SLA, double confidence) {
		this.name = name;
		this.quantityUnit = qtyUnit;
		this.unit = measureUnit;
		this.groupType = groupType;
		this.SLA = SLA;
		this.confidence = confidence;
	}
	
	public ProcessPerformances(String name, String qtyUnit, String measureUnit, String groupType, double SLA, double confidence, String fromName, String toName) {
		this.name = name;
		this.quantityUnit = qtyUnit;
		this.unit = measureUnit;
		this.groupType = groupType;
		this.SLA = SLA;
		this.confidence = confidence;
		this.fromName = fromName;
		this.toName = toName;
	}
	
	public void setDetails(Object[][] details) throws ParseException {
		this.details = details;
		HashMap<String, Integer> headers = new HashMap<String, Integer>();
		SimpleDateFormat mysqlDateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
		SimpleDateFormat periodFormatter = new SimpleDateFormat("MMM yy");
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
		
		
		for (int i=0; i<details.length; i++) {
			if (i==0) {
				for (int j=0; j<details[i].length; j++) {
					headers.put(details[i][j].toString(), j);
				}
			} else {
				String period = periodFormatter.format(mysqlDateFormat.parse(details[i][headers.get(toName)].toString()));
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
				
			    powerSum1 += (Integer)details[i][headers.get("Duration")];
			    avg = (avg*qty + (Integer)details[i][headers.get("Duration")])/(qty+1);
			    powerSum2 += Math.pow((Integer)details[i][headers.get("Duration")], 2);
			    stdDev = Math.sqrt(qty*powerSum2 - Math.pow(powerSum1, 2))/qty;
			    withinSLA += (Long) details[i][headers.get("WithinSLA")];
			    qty++;
			}
		}
		// Add Last
		if(Double.isNaN(stdDev))
			stdDev = 0;
		avgs.add(avg);
		stdDevs.add(stdDev);
		qtys.add(qty);
		withinSLAs.add(withinSLA);
		groups.add(group);
		
		this.group = new String[groups.size()];
		this.avg = new double[groups.size()];
		this.stdDev = new double[groups.size()];
		this.quantity= new int[groups.size()];
		this.withinSLA = new int[groups.size()];
		for (int i = 0; i < groups.size(); i++) {
			this.group[i] = groups.get(i);
			this.avg[i] = avgs.get(i);
			this.stdDev[i] = stdDevs.get(i);
			this.quantity[i] = qtys.get(i);
			this.withinSLA[i] = withinSLAs.get(i);
		}
	}
}
