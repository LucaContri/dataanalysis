package com.saiglobal.sf.core.model;

import java.util.Calendar;
import java.util.List;

import javax.xml.bind.annotation.XmlElement;

public class Certification extends GenericSfObject {
	@XmlElement(name = "WorkItem")
	public List<WorkItem> workItems;
	public List<BlackoutPeriod> bops;
	public List<BlackoutPeriod> getBops() {
		return bops;
	}
	public void setBops(List<BlackoutPeriod> bops) {
		this.bops = bops;
	}
	
	public boolean isAvailableForAudit(Calendar date) {
		for (BlackoutPeriod bop : bops) {
			if(bop.contains(date))
				return false;
		}
		return true;
	}
}
