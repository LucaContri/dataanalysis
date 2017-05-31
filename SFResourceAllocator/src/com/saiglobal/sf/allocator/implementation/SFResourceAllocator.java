package com.saiglobal.sf.allocator.implementation;

import java.util.Calendar;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.TimeZone;

import org.apache.log4j.Logger;

import com.saiglobal.sf.allocator.data.DbHelper;
import com.saiglobal.sf.allocator.processor.BasicProcessor;
import com.saiglobal.sf.allocator.processor.Processor;
import com.saiglobal.sf.core.model.ResourceEventType;
import com.saiglobal.sf.core.model.ScheduleParameters;
import com.saiglobal.sf.core.model.CompassRevenueOwnership;
import com.saiglobal.sf.core.model.SfResourceCompetencyRankType;
import com.saiglobal.sf.core.model.SfResourceType;
import com.saiglobal.sf.core.model.SfWorkItemStatus;
import com.saiglobal.sf.core.utility.GlobalProperties;

public class SFResourceAllocator implements Allocator {

	protected Logger logger = Logger.getLogger(SFResourceAllocator.class);
	
	@Override
	public ScheduleParameters getParameters(GlobalProperties cmd) {
		
		// Input parameters
		ScheduleParameters parameters = new ScheduleParameters();
		parameters.setBatchId("UK 2015-2016 All");
		parameters.setWiCountries(new String[] {"United Kingdom"});
		parameters.setRevenueOwnership(new CompassRevenueOwnership[] {
				CompassRevenueOwnership.EMEAUK,
				CompassRevenueOwnership.EMEACzechRepublic,
				CompassRevenueOwnership.EMEAEgypt, 
				CompassRevenueOwnership.EMEAFrance,
				CompassRevenueOwnership.EMEAGermany,
				CompassRevenueOwnership.EMEAIreland,
				CompassRevenueOwnership.EMEAItaly,
				CompassRevenueOwnership.EMEAPoland,
				CompassRevenueOwnership.EMEARussia,
				CompassRevenueOwnership.EMEASouthAfrica,
				CompassRevenueOwnership.EMEASpain,
				CompassRevenueOwnership.EMEASweden,
				CompassRevenueOwnership.EMEATurkey,
				CompassRevenueOwnership.RBUEMEAMS,
				CompassRevenueOwnership.RBUMSEMEA});
		parameters.setAuditorsCountries(new String[] {"United Kingdom"});
		parameters.setRepotingBusinessUnits(new CompassRevenueOwnership[] {CompassRevenueOwnership.EMEAUK,CompassRevenueOwnership.RBUEMEAMS, CompassRevenueOwnership.RBUMSEMEA});
		parameters.setResourceTypes(new SfResourceType[] {SfResourceType.Employee, SfResourceType.Contractor});
		parameters.setLoadCalendar(true);
		parameters.setEventTypes(ResourceEventType.ALL);
		parameters.setLoadCompetencies(true);
		parameters.setWorkItemsStatus(new SfWorkItemStatus[] {
				SfWorkItemStatus.Open, 
				SfWorkItemStatus.Allocated,
				SfWorkItemStatus.Complete,
				SfWorkItemStatus.Completed,
				SfWorkItemStatus.Confirmed,
				SfWorkItemStatus.InProgress,
				SfWorkItemStatus.Scheduled,
				SfWorkItemStatus.ScheduledOffered,
				SfWorkItemStatus.Servicechange,
				SfWorkItemStatus.Submitted,
				SfWorkItemStatus.UnderReview,
				SfWorkItemStatus.UnderReviewRejected,
				SfWorkItemStatus.Support
				});
		//parameters.setWorkItemsStatus(null);
		parameters.setResourceCompetencyRanks(new SfResourceCompetencyRankType[] {
				SfResourceCompetencyRankType.LeadAuditor,
				SfResourceCompetencyRankType.Auditor
		});
		TimeZone tz = TimeZone.getTimeZone("United Kingdom/London");
		parameters.setTimeZone(tz);
		Calendar cal = new GregorianCalendar();
		Calendar cal2 = new GregorianCalendar();
		cal.setTimeZone(tz);
		cal.set(2015, Calendar.JANUARY, 1, 0, 0, 0);
		cal2.set(2015, Calendar.JANUARY, 1, 0, 0, 0);
		int offset = tz.getOffset(cal.getTimeInMillis());
		cal.set(Calendar.MILLISECOND, -offset);
		Date startDate = cal.getTime();
		Date startDate2 = cal2.getTime();
		parameters.setStartDate(startDate2);
		parameters.setCalendarStartDate(startDate);
		
		cal.set(2016, Calendar.DECEMBER, 29, 23, 59, 59);
		cal2.set(2016, Calendar.DECEMBER, 29, 23, 59, 59);
		offset = tz.getOffset(cal.getTimeInMillis());
		//cal.set(Calendar.MILLISECOND, -offset);
		Date endDate = cal.getTime();
		Date endDate2 = cal2.getTime();
		parameters.setEndDate(endDate2);
		parameters.setCalendarEndDate(endDate);
		
		parameters.setScoreAvailabilityDayReward(50);
		parameters.setScoreCapabilityAuditPenalty(0);
		parameters.setScoreContractorPenalties(200);
		parameters.setScoreDistanceKmPenalty(0);
		// parameters.setWorkItemIds(new String[] {"a3Id0000000IdbDEAS"});
		// parameters.setResourceIds(new String[] {"a0nd0000002GZI4AAO"});

		return parameters;
	}

	@Override
	public Processor getProcessor(DbHelper db, ScheduleParameters sp) throws Exception {
		Processor processor = new BasicProcessor(db, sp);
		return processor;
	}
}
