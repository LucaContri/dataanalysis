package com.saiglobal.reporting.model;

import java.util.ArrayList;
import java.util.List;

public class MetricDetailsSummaryList {
	private List<MetricDetails> metricDetails = new ArrayList<MetricDetails>(); 
    
	private Double slaValueEquivalentSum = 0.0;
	private Double slaValueEquivalentWightedSum = 0.0;
	private Double weightSum = 0.0;
	private Double volumeSum = 0.0;
	private Double slaValueEquivalent =0.0;
	private int count = 0;
	
    public void add(MetricDetails md) {
    	metricDetails.add(md);
    	volumeSum += md.getVolume();
    	slaValueEquivalentSum += md.getSlaValueEquivalent();
    	slaValueEquivalentWightedSum += md.getSlaValueEquivalentWeighted();
    	weightSum += md.getWeight();
    	slaValueEquivalent = slaValueEquivalentWightedSum/weightSum;
    	count++;
    }

    public MetricDetailsSummaryList combine(MetricDetailsSummaryList mds) {
    	metricDetails.addAll(mds.getMetricDetails());
    	volumeSum += mds.getVolumeSum();
    	slaValueEquivalentSum += mds.getSlaValueEquivalent();
    	slaValueEquivalentWightedSum += mds.getSlaValueEquivalentWightedSum();
    	weightSum += mds.getWeightSum();
    	slaValueEquivalent = slaValueEquivalentWightedSum/weightSum;
    	count += mds.getCount();
        return this;
    }

	public Double getVolumeSum() {
		return volumeSum;
	}

	public void setVolumeSum(Double volumeSum) {
		this.volumeSum = volumeSum;
	}

	public List<MetricDetails> getMetricDetails() {
		return metricDetails;
	}

	public void setMetricDetails(List<MetricDetails> metricDetails) {
		this.metricDetails = metricDetails;
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