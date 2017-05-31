package com.saiglobal.sf.allocator.implementation;

import java.util.Calendar;
import java.util.GregorianCalendar;
import java.util.TimeZone;

import org.apache.log4j.Logger;

import com.saiglobal.sf.allocator.data.DbHelper;
import com.saiglobal.sf.allocator.processor.Processor;
import com.saiglobal.sf.allocator.processor.ProcessorEMEATesco;
import com.saiglobal.sf.core.model.ResourceEventType;
import com.saiglobal.sf.core.model.ScheduleParameters;
import com.saiglobal.sf.core.model.SfResourceCompetencyRankType;
import com.saiglobal.sf.core.model.SfResourceType;
import com.saiglobal.sf.core.utility.GlobalProperties;

public class ResourceAllocatorEMEATesco implements Allocator {
	
	protected Logger logger = Logger.getLogger(ResourceAllocatorEMEATesco.class);
	
	@Override	
	public ScheduleParameters getParameters(GlobalProperties cmd) {
		
		// Input parameters
		ScheduleParameters parameters = new ScheduleParameters();
		parameters.setBatchId("EMEA Tesco Capacity Planning - 2017");
		//parameters.setRevenueOwnership(new CompassRevenueOwnership[] {CompassRevenueOwnership.EMEASpain});
		parameters.setAuditorsCountries(new String[] {"France", "Germany", "Italy", "Spain", "Turkey", "Poland", "Czech Republic"});
		parameters.setWiCountries(new String[] {"France", "Spain","Italy","Germany","Greece","Denmark","Portugal","Turkey","Austria","Switzerland","Norway","Cyprus","Iceland"});
		
		//parameters.setRepotingBusinessUnits(new CompassRevenueOwnership[] {CompassRevenueOwnership.EMEASpain});
		parameters.setResourceTypes(new SfResourceType[] {SfResourceType.Employee, SfResourceType.Contractor});
		parameters.setLoadCalendar(false);
		parameters.setEventTypes(ResourceEventType.ALL);
		parameters.setLoadCompetencies(true);
		parameters.setExludeFollowups(true);
		//parameters.setWorkItemsStatus(new SfWorkItemStatus[] {
		//		SfWorkItemStatus.Open, SfWorkItemStatus.Servicechange
		//		});
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
		cal.set(2017, Calendar.JANUARY, 1);
		parameters.setStartDate(cal.getTime());
		parameters.setCalendarStartDate(cal.getTime());
		
		cal.add(Calendar.MONTH, 6);
		cal.set(Calendar.DAY_OF_MONTH, cal.getActualMaximum(Calendar.DAY_OF_MONTH));
		cal.set(2017, Calendar.DECEMBER, 31);
		parameters.setEndDate(cal.getTime());
		parameters.setCalendarEndDate(cal.getTime());
		
		parameters.setScoreAvailabilityDayReward(1);
		parameters.setScoreCapabilityAuditPenalty(0);
		parameters.setScoreContractorPenalties(0);
		parameters.setScoreDistanceKmPenalty(1);
		
		parameters.setIncludePipeline(false);
		parameters.setIncludeStandardNames(new String[] {
				"Tesco Produce Packhouse Standard Global - 2015 | Verification",
				"Tesco Produce Packhouse Standard Local - 2015 | Verification",
				"Tesco Produce Packhouse Standard Global - 2012 | Verification",
				"Tesco Produce Packhouse Standard Local - 2012 | Verification",
				"Tesco Food Manufacturing Standard Global - Version 6 | Verification",
				"Tesco Food Manufacturing Standard Local - Version 6 | Verification",
				"Tesco Food Manufacturing Standard Global - Version 5 | Verification",
				"Tesco Food Manufacturing Standard Local - Version 5 | Verification"
		});
		
		parameters.setFixedCapacity(new Double(100));
		parameters.setResourceIds(new String[] {
				// Spain
				"fake_resource_0001", // Esther 
				"fake_resource_0002", // Elise
				"fake_resource_0003", // Maribel
				"a0nd0000000hAzZAAU", // Christel Kaberghs
				"a0nd00000065otnAAA", // Yobana Bermudez
				"a0nd0000002GD39AAG", // Beata Biezunska
				// Germany
				"a0nd0000002HMLnAAO", // Franz Gropp
				// Czech Republic
				"a0nd0000002IHVuAAO", // Renata Chramostova
				// Poland
				"a0nd0000002IHU8AAO", // Joanna Rylko
				"a0nd0000002IHUhAAO", // Tatiana Wiktorowicz
				"a0nd0000002IHRvAAO", // Wojciech Kowalczyk
				// Italy
				"a0nd0000005YBNCAA4", // Enrico Girotto
				"a0nd0000004rxS3AAI", // Giulia Bughi Peruglia
				"a0nd0000000hAmbAAE", // Giulio Milan
				"a0nd0000004qXtGAAU", // Stefano Stefanucci
				// France
				"a0nd0000003Z7OQAA0", // Audrey Barbier"
				"a0nd0000005YBM4AAO", // Bruce Maurice
				"a0nd0000003Z7MNAA0", // Daniela Da Silva
				"a0nd0000002GD3XAAW", // Taghrid Paresys
			});
		
		//parameters.setWorkItemIds(new String[] {"a3Id0000000GzGPEA0"});

		return parameters;
	}

	@Override
	public Processor getProcessor(DbHelper db, ScheduleParameters sp) throws Exception {
		Processor processor = new ProcessorEMEATesco(db, sp);
		return processor;
	}
}
