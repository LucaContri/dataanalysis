package com.saiglobal.sf.core.model;

import java.util.HashMap;
import java.util.List;

import javax.xml.bind.annotation.XmlElement;
import javax.xml.bind.annotation.XmlTransient;

public class ClientSite extends GenericSfObject {
	@XmlTransient
	private Location location;
	@XmlTransient
	private List<Certification> siteCertifications;
	@XmlTransient
	private Location closestAirport;
	@XmlTransient
	private double distanceToClosestAirport;
	@XmlTransient
	private HashMap<String, Double> flyingTimes;
	
	public Location getClosestAirport() {
		return closestAirport;
	}
	public void setClosestAirport(Location closestAirport) {
		this.closestAirport = closestAirport;
	}
	
	@XmlTransient
	public double getDistanceToClosestAirport() {
		return distanceToClosestAirport;
	}
	public void setDistanceToClosestAirport(double distanceToClosestAirport) {
		this.distanceToClosestAirport = distanceToClosestAirport;
	}
	
	@XmlTransient
	public HashMap<String, Double> getFlyingTimes() {
		return flyingTimes;
	}
	public void setFlyingTimes(HashMap<String, Double> flyingTimes) {
		this.flyingTimes = flyingTimes;
	}
	
	@XmlElement(name="Location")
	public Location getLocation() {
		return location;
	}
	public void setLocation(Location location) {
		this.location = location;
	}
	
	@XmlElement(name="SiteCertification")
	public List<Certification> getSiteCertifications() {
		return siteCertifications;
	}
	public void setSiteCertifications(List<Certification> siteCertifications) {
		this.siteCertifications = siteCertifications;
	}
}
