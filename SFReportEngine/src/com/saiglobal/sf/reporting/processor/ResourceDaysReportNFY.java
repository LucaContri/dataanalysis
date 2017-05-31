package com.saiglobal.sf.reporting.processor;

import java.util.Date;
import java.util.GregorianCalendar;

import com.saiglobal.sf.core.utility.Utility;

public class ResourceDaysReportNFY extends ResourceDaysReport {
	
	public ResourceDaysReportNFY() {
		super();
		
		startFY = new GregorianCalendar(currentFY+1,6,1);
		endFY = new GregorianCalendar(currentFY+2,5,30);
		
		startPeriod = startFY;
		endPeriod = endFY;
		
		periods = getAllPeriods();
	}
	
	@Override
	public String[] getReportNames() {
		return new String[] {
				"Resource Days Summary\\" + Utility.getPeriodformatter().format(new Date()) + "\\" + getFileReportNames()[0], 
				"Resource Days Summary\\" + Utility.getPeriodformatter().format(new Date()) + "\\" + getFileReportNames()[1]
				};
	}
	
	@Override
	public String[] getFileReportNames() {
		return new String[] {
				"Resource Days Report NFY - Summary", 
				"Resource Days Report NFY - Details"
				};
	}
}
