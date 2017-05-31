package com.saiglobal.sf.allocator.implementation;

import java.util.Calendar;
import java.util.GregorianCalendar;
import java.util.TimeZone;

import org.apache.log4j.Logger;

import com.saiglobal.sf.allocator.data.DbHelper;
import com.saiglobal.sf.allocator.processor.Processor;
import com.saiglobal.sf.allocator.processor.ProcessorUKFood;
import com.saiglobal.sf.core.model.ResourceEventType;
import com.saiglobal.sf.core.model.ScheduleParameters;
import com.saiglobal.sf.core.model.CompassRevenueOwnership;
import com.saiglobal.sf.core.model.SfResourceCompetencyRankType;
import com.saiglobal.sf.core.model.SfResourceType;
import com.saiglobal.sf.core.utility.GlobalProperties;

public class ResourceAllocatorUK implements Allocator {
	
	protected Logger logger = Logger.getLogger(ResourceAllocatorUK.class);
	
	@Override	
	public ScheduleParameters getParameters(GlobalProperties cmd) {
		
		// Input parameters
		ScheduleParameters parameters = new ScheduleParameters();
		parameters.setBatchId("UK Food Capacity Planning - 12 months");
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
				CompassRevenueOwnership.EMEATurkey
				});
		parameters.setAuditorsCountries(new String[] {"United Kingdom"});
		
		parameters.setRepotingBusinessUnits(new CompassRevenueOwnership[] {CompassRevenueOwnership.EMEAUK});
		parameters.setResourceTypes(new SfResourceType[] {SfResourceType.Employee, SfResourceType.Contractor});
		parameters.setLoadCalendar(false);
		parameters.setEventTypes(ResourceEventType.ALL);
		parameters.setLoadCompetencies(true);
		parameters.setExludeFollowups(true);
		//parameters.setWorkItemsStatus(new SfWorkItemStatus[] {
		//		SfWorkItemStatus.Open, SfWorkItemStatus.Servicechange
		//		});
		parameters.setWorkItemsStatus(null);
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
		cal.set(2017, Calendar.JANUARY, 1);
		parameters.setStartDate(cal.getTime());
		parameters.setCalendarStartDate(cal.getTime());
		
		cal.add(Calendar.MONTH, 12);
		cal.set(Calendar.DAY_OF_MONTH, cal.getActualMaximum(Calendar.DAY_OF_MONTH));

		parameters.setEndDate(cal.getTime());
		parameters.setCalendarEndDate(cal.getTime());
		
		parameters.setScoreAvailabilityDayReward(0);
		parameters.setScoreCapabilityAuditPenalty(0);
		parameters.setScoreContractorPenalties(500);
		parameters.setScoreDistanceKmPenalty(1);
		
		parameters.setIncludePipeline(false);
		
		//parameters.setResourceIds(new String[] {"a0nd0000000hAoHAAU"});
		//parameters.setWorkItemIds(new String[] {"a3Id0000000GzGPEA0"});

		return parameters;
	}

	@Override
	public Processor getProcessor(DbHelper db, ScheduleParameters sp) throws Exception {
		Processor processor = new ProcessorUKFood(db, sp);
		return processor;
	}
}
