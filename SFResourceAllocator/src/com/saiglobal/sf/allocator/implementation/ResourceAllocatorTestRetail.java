package com.saiglobal.sf.allocator.implementation;

import java.util.Calendar;
import java.util.GregorianCalendar;
import java.util.TimeZone;

import org.apache.log4j.Logger;

import com.saiglobal.sf.allocator.data.DbHelper;
import com.saiglobal.sf.allocator.processor.MIP3RetailProcessor;
import com.saiglobal.sf.allocator.processor.Processor;
import com.saiglobal.sf.core.model.ResourceEventType;
import com.saiglobal.sf.core.model.ScheduleParameters;
import com.saiglobal.sf.core.model.CompassRevenueOwnership;
import com.saiglobal.sf.core.model.SfResourceCompetencyRankType;
import com.saiglobal.sf.core.model.SfResourceType;
import com.saiglobal.sf.core.model.SfWorkItemStatus;
import com.saiglobal.sf.core.utility.GlobalProperties;

public class ResourceAllocatorTestRetail implements Allocator {
	
	protected Logger logger = Logger.getLogger(ResourceAllocatorTestRetail.class);
	
	@Override	
	public ScheduleParameters getParameters(GlobalProperties cmd) {
		
		// Input parameters
		ScheduleParameters parameters = new ScheduleParameters();
		parameters.setBatchId("Retail Test");
		//parameters.setRevenueOwnership(new CompassRevenueOwnership[] {
		//		CompassRevenueOwnership.EMEAUK,
		//});
		parameters.setSchedulingOwnership(new String[] {"EMEA - UK"});
		parameters.setAuditorsCountries(new String[] {"United Kingdom"});
		parameters.setWiCountries(new String[] {"United Kingdom"});
		
		parameters.setRepotingBusinessUnits(new CompassRevenueOwnership[] {CompassRevenueOwnership.EMEAUK});
		parameters.setResourceTypes(new SfResourceType[] {SfResourceType.Employee, SfResourceType.Contractor});
		parameters.setLoadCalendar(true);
		parameters.setEventTypes(ResourceEventType.ALL);
		parameters.setLoadCompetencies(true);
		parameters.setExludeFollowups(true);
		parameters.setWorkItemsStatus(new SfWorkItemStatus[] {
				SfWorkItemStatus.Open,
				//SfWorkItemStatus.Scheduled
				});
		parameters.setExcludeOpenPendingCancellationorSuspension(true);
		//parameters.setWorkItemsStatus(null);
		parameters.setResourceCompetencyRanks(new SfResourceCompetencyRankType[] {
				SfResourceCompetencyRankType.LeadAuditor,
				SfResourceCompetencyRankType.Auditor
		});
		TimeZone tz = TimeZone.getTimeZone("UTC");
		parameters.setTimeZone(tz);
		Calendar cal = new GregorianCalendar();
		cal.setTimeZone(tz);
		cal.set(Calendar.DAY_OF_MONTH, 1);
		cal.set(Calendar.HOUR, 0);
		cal.set(Calendar.MINUTE, 0);
		cal.set(Calendar.SECOND, 0);
		cal.set(Calendar.MILLISECOND, 0);
		int offset = tz.getOffset(cal.getTimeInMillis());
		cal.set(Calendar.MILLISECOND, -offset);
		cal.set(2017, Calendar.FEBRUARY, 1);
		parameters.setStartDate(cal.getTime());
		// Add some slack to load previous events
		cal.add(Calendar.DATE, -10);
		parameters.setCalendarStartDate(cal.getTime());
		cal.add(Calendar.DATE, 10);
		
		int no_of_months = 12;
		if (cmd.getCustomParameter("noOfMonth") != null) {
			try {
				no_of_months = Integer.parseInt(cmd.getCustomParameter("noOfMonth"));
			} catch (Exception e) {
				// Ignore - Use default
			}
		}
		cal.add(Calendar.MONTH, no_of_months);
		cal.set(Calendar.DAY_OF_MONTH, cal.getActualMaximum(Calendar.DAY_OF_MONTH));
		cal.set(2017, Calendar.FEBRUARY, 28);
		
		parameters.setEndDate(cal.getTime());
		// Add some slack to load following events
		cal.add(Calendar.DATE, 10);
		parameters.setCalendarEndDate(cal.getTime());
		
		parameters.setIncludePipeline(false);
		
		if (cmd.getCustomParameter("milkRuns") != null) {
			try {
				boolean milkRuns = Boolean.parseBoolean(cmd.getCustomParameter("milkRuns"));
				parameters.setMilkRuns(milkRuns);
			} catch (Exception e) {
				// Ignore - Use default
			}
		}
		
		// Exclude Ethical Standards SMEATA
		// Exclude BRC bolt-on: ASDa and AVM 11
		parameters.setResourceNames(new String[] {"Philip Clifford"});
		
		return parameters;
	}

	@Override
	public Processor getProcessor(DbHelper db, ScheduleParameters sp) throws Exception {
		Processor processor = new MIP3RetailProcessor(db, sp);
		return processor;
	}
}
