package com.saiglobal.reporting.model;

import java.util.HashSet;
import java.util.Set;

public class MetricDetailsSummary {
	private Double slaValueEquivalentSum = 0.0;
	private Double slaValueEquivalentWightedSum = 0.0;
	private Double weightSum = 0.0;
	private Double slaValueEquivalent =0.0;
	private Set<Integer> metricIds = new HashSet<Integer>();
	private int count = 0;
	
    public void add(MetricDetails md) {
    	//System.out.println(md.getMetric().getMetricGroup());
    	if(md.getMetric().getMetricGroup().equalsIgnoreCase("Utilisation"))
    		System.out.println(md.getRegionDisplayName() + " weight:" + md.getWeight());
    	slaValueEquivalentSum += md.getSlaValueEquivalent();
    	slaValueEquivalentWightedSum += md.getSlaValueEquivalentWeighted();
    	weightSum += md.getWeight();
    	metricIds.add(md.getId());
    	slaValueEquivalent = slaValueEquivalentWightedSum/weightSum;
    	count++;
    }

    public MetricDetailsSummary combine(MetricDetailsSummary mds) {
    	slaValueEquivalentSum += mds.getSlaValueEquivalent();
    	slaValueEquivalentWightedSum += mds.getSlaValueEquivalentWightedSum();
    	weightSum += mds.getWeightSum();
    	metricIds.addAll(mds.getMetricIds());
    	slaValueEquivalent = slaValueEquivalentWightedSum/weightSum;
    	count += mds.getCount();
        return this;
    }
	
    
    public Set<Integer> getMetricIds() {
		return metricIds;
	}

	public void setMetricIds(Set<Integer> metricIds) {
		this.metricIds = metricIds;
	}

	public Double getSlaValueEquivalentSum() {
		return slaValueEquivalentSum;
	}

	public Double getSlaValueEquivalentWightedSum() {
		return slaValueEquivalentWightedSum;
	}

	public void setSlaValueEquivalentWightedSum(Double slaValueEquivalentWightedSum) {
		this.slaValueEquivalentWightedSum = slaValueEquivalentWightedSum;
	}

	public void setSlaValueEquivalentSum(Double slaValueEquivalentSum) {
		this.slaValueEquivalentSum = slaValueEquivalentSum;
	}

	public Double getWeightSum() {
		return weightSum;
	}

	public void setWeightSum(Double weightSum) {
		this.weightSum = weightSum;
	}

	public Double getSlaValueEquivalent() {
		return slaValueEquivalent;
	}

	public void setSlaValueEquivalent(Double slaValueEquivalent) {
		this.slaValueEquivalent = slaValueEquivalent;
	}

	public int getCount() {
		return count;
	}

	public void setCount(int count) {
		this.count = count;
	}
}