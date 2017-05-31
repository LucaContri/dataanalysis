package com.saiglobal.reporting.model;

import java.util.Calendar;

import com.saiglobal.sf.core.model.Region;

public class MetricDetails {
	  
	  public static final double targetAmberEquivalent = 0.855;
	  public static final double targetGreenEquivalent = 0.900;
	  private int Id;
	  private Region region;
	  private Metric metric;
	  private String subRegion, preparedBy, team, businessOwner, regionDisplayName, productPortfolio;
	  private Calendar period, preparedDateTime;
	  private double volume, slaValue, slaValueEquivalent, weight, targetAmber, targetGreen;
	public MetricDetails(int id, Metric metric, String subRegion,
			String preparedBy, Calendar period, Calendar preparedDateTime,
			double volume, double slaValue, String team, String businessOwner, String region, String productPortfolio, double targetAmber, double targetGreen, double weight) {
		super();
		Id = id;
		setRegion(region);
		this.regionDisplayName = this.region.getName();
		this.setProductPortfolio(productPortfolio);
		this.metric = metric;
		this.subRegion = subRegion;
		this.preparedBy = preparedBy;
		this.period = period;
		this.preparedDateTime = preparedDateTime;
		this.volume = volume;
		this.slaValue = slaValue;
		this.weight = weight;
		this.team = team;
		this.businessOwner = businessOwner;
		this.targetAmber = targetAmber;
		this.targetGreen = targetGreen;
		
		this.slaValueEquivalent = calculateSlaValueEquivalent();
	}
	
	public double getTargetAmber() {
		return targetAmber;
	}

	public void setTargetAmber(double targetAmber) {
		this.targetAmber = targetAmber;
	}

	public double getTargetGreen() {
		return targetGreen;
	}

	public void setTargetGreen(double targetGreen) {
		this.targetGreen = targetGreen;
	}

	public Region getRegion() {
		return region;
	}

	public void setRegion(String region) {
		if (region.equalsIgnoreCase("APAC"))
			this.region = Region.APAC_ALL;
		if (region.equalsIgnoreCase("EMEA"))
			this.region = Region.EMEA_ALL;
		if (region.equalsIgnoreCase("AMERICAs"))
			this.region = Region.AMERICAs;
	}
	
	public String getRegionDisplayName() {
		return regionDisplayName;
	}

	public void setRegionDisplayName(String regionDisplayName) {
		this.regionDisplayName = regionDisplayName;
	}
	
	public String getTeam() {
		return team;
	}

	public void setTeam(String team) {
		this.team = team;
	}

	public String getBusinessOwner() {
		return businessOwner;
	}

	public void setBusinessOwner(String businessOwner) {
		this.businessOwner = businessOwner;
	}


	public double getWeight() {
		return weight;
	}

	public void setWeight(double weight) {
		this.weight = weight;
	}

	public String getMetricGroup() {
		if (this.metric != null)
			return this.metric.getMetricGroup();
		return null;
	}
	
	public int getMetricId() {
		if (this.metric != null)
			return this.metric.getId();
		return -1;
	}
	
	public String getMetricRegionId() {
		return getMetricId() + getRegionDisplayName();
	}
	
	/*
	 public String getProductPortfolio() {
	 	if (this.metric != null)
			return this.metric.getProductPortfolio();
		return null;
	}
	*/
	
	public double getSlaValueEquivalent() {
		return slaValueEquivalent;
	}

	public double getSlaValueEquivalentWeighted() {
		return slaValueEquivalent*weight;
	}

	public void setSlaValueEquivalent(double slaValueEquivalent) {
		this.slaValueEquivalent = slaValueEquivalent;
	}


	public double getTargetAmberEquivalent() {
		return targetAmberEquivalent;
	}

	public double getTargetGreenEquivalent() {
		return targetGreenEquivalent;
	}

	public Metric getMetric() {
		return metric;
	}

	public void setMetric(Metric metric) {
		this.metric = metric;
	}

	public int getId() {
		return Id;
	}
	public void setId(int id) {
		Id = id;
	}
	public String getSubRegion() {
		return subRegion;
	}
	public void setSubRegion(String subRegion) {
		this.subRegion = subRegion;
	}
	public String getPreparedBy() {
		return preparedBy;
	}
	public void setPreparedBy(String preparedBy) {
		this.preparedBy = preparedBy;
	}
	public Calendar getPeriod() {
		return period;
	}
	public void setPeriod(Calendar period) {
		this.period = period;
	}
	public Calendar getPreparedDateTime() {
		return preparedDateTime;
	}
	public void setPreparedDateTime(Calendar preparedDateTime) {
		this.preparedDateTime = preparedDateTime;
	}
	public double getVolume() {
		return volume;
	}
	public void setVolume(double volume) {
		this.volume = volume;
	}
	public double getSlaValue() {
		return slaValue;
	}
	public void setSlaValue(double slaValue) {
		this.slaValue = slaValue;
	}
	
	private double calculateSlaValueEquivalent() {
		if (slaValue<=targetAmber && targetAmber<targetGreen) {
			return targetAmberEquivalent - (targetAmber-slaValue)*targetAmberEquivalent/targetAmber;
		}
		if (slaValue>=targetGreen) {
			if (targetGreen==1) {
				return targetGreenEquivalent;
			} else {
				return targetGreenEquivalent + (slaValue-targetGreen)*(1- targetGreenEquivalent)/(1 - targetGreen);
			}
		}
		if (targetAmber==targetGreen) {
			return slaValue*targetAmberEquivalent;
		} else {
			return targetGreenEquivalent - (targetGreen-slaValue)*(targetGreenEquivalent-targetAmberEquivalent)/(targetGreen-targetAmber);
		}
	}

	public String getProductPortfolio() {
		return productPortfolio;
	}

	public void setProductPortfolio(String productPortfolio) {
		this.productPortfolio = productPortfolio;
	}
}