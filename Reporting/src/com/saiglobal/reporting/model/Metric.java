package com.saiglobal.reporting.model;

@SuppressWarnings("rawtypes")
public class Metric implements Comparable {
	  private int Id;
	  private String metricGroup, metric, volumeDefinition, volumeUnit, slaDefinition;
	  
	@Override
	public int compareTo(Object arg0) {
		if (!(arg0 instanceof Metric))
			throw new ClassCastException();
		return getUniqueName().compareTo(((Metric)arg0).getUniqueName());
	}

	public Metric(int id, String metricGroup, String metric, String volumeDefinition, String volumeUnit,String slaDefinition) {
		super();
		Id = id;
		this.metricGroup = metricGroup;
		this.metric = metric;
		this.volumeDefinition = volumeDefinition;
		this.volumeUnit = volumeUnit;
		this.slaDefinition = slaDefinition;
	}

	public String getUniqueName() {
		return getMetricGroup() + "-" + getMetric() + "-" + getId();
	}
	
	public int getId() {
		return Id;
	}

	public void setId(int id) {
		Id = id;
	}

	public String getMetricGroup() {
		return metricGroup;
	}

	public void setMetricGroup(String metricGroup) {
		this.metricGroup = metricGroup;
	}

	public String getMetric() {
		return metric;
	}

	public void setMetric(String metric) {
		this.metric = metric;
	}

	public String getVolumeDefinition() {
		return volumeDefinition;
	}

	public void setVolumeDefinition(String volumeDefinition) {
		this.volumeDefinition = volumeDefinition;
	}

	public String getVolumeUnit() {
		return volumeUnit;
	}

	public void setVolumeUnit(String volumeUnit) {
		this.volumeUnit = volumeUnit;
	}

	public String getSlaDefinition() {
		return slaDefinition;
	}

	public void setSlaDefinition(String slaDefinition) {
		this.slaDefinition = slaDefinition;
	}
}