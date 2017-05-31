package com.saiglobal.sf.allocator.implementation;

import java.util.Calendar;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.TimeZone;

import org.apache.log4j.Logger;

import com.saiglobal.sf.allocator.data.DbHelper;
import com.saiglobal.sf.allocator.processor.Processor;
import com.saiglobal.sf.allocator.processor.ProcessorProductServices;
import com.saiglobal.sf.core.model.ResourceEventType;
import com.saiglobal.sf.core.model.ScheduleParameters;
import com.saiglobal.sf.core.model.CompassRevenueOwnership;
import com.saiglobal.sf.core.model.SfResourceCompetencyRankType;
import com.saiglobal.sf.core.model.SfResourceType;
import com.saiglobal.sf.core.model.SfWorkItemStatus;
import com.saiglobal.sf.core.utility.GlobalProperties;

public class PSBacklogResourceAllocator implements Allocator {
	
	protected Logger logger = Logger.getLogger(PSBacklogResourceAllocator.class);
	
	@Override
	public ScheduleParameters getParameters(GlobalProperties cmd) {

		// Input parameters
		ScheduleParameters parameters = new ScheduleParameters();
		parameters.setBatchId("PS Open Backlog All");
		parameters.setRevenueOwnership(new CompassRevenueOwnership[] {
				CompassRevenueOwnership.AUSProductServicesNSWACT,
				CompassRevenueOwnership.AUSProductServicesQLD,
				CompassRevenueOwnership.AUSProductServicesROW,
				CompassRevenueOwnership.AUSProductServicesSANT,
				CompassRevenueOwnership.AUSProductServicesVICTAS,
				CompassRevenueOwnership.AUSProductServicesWA});
		//parameters.setAuditorsCountries(new String[] {"China"});
		parameters.setWiCountries(new String[] {
				"Austria","Cyprus","Denmark","Greece", "Belgium","Czech Republic","France","Germany","Italy","Lithuania", "Luxembourg", "Monaco","Netherlands", "Norway","Poland","Portugal","Romania","Russian Federation","Slovakia","Slovenia", "Spain", "Sweden","Switzerland","Turkey", "United Kingdom", //Europe
				"China","India","Indonesia","Japan", "Korea, South","Malaysia","Pakistan","Singapore","Sri Lanka", "Taiwan","Thailand","Viet Nam" // Asia
				});
		//parameters.setRepotingBusinessUnits(new CompassRevenueOwnership[] {
		//		CompassRevenueOwnership.AUSProductServicesNSWACT,
		//		CompassRevenueOwnership.AUSProductServicesQLD,
		//		CompassRevenueOwnership.AUSProductServicesROW,
		//		CompassRevenueOwnership.AUSProductServicesSANT,
		//		CompassRevenueOwnership.AUSProductServicesVICTAS,
		//		CompassRevenueOwnership.AUSProductServicesWA});
		//parameters.setRepotingBusinessUnits(null);
		parameters.setResourceTypes(new SfResourceType[] {SfResourceType.Employee, SfResourceType.Contractor});
		parameters.setLoadCalendar(true);
		parameters.setEventTypes(ResourceEventType.ALL);
		parameters.setLoadCompetencies(true);
		parameters.setWorkItemsStatus(new SfWorkItemStatus[] {
				SfWorkItemStatus.Open
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
		cal.set(2016, Calendar.NOVEMBER, 1, 0, 0, 0);
		cal2.set(2014, Calendar.JANUARY, 1, 0, 0, 0);
		int offset = tz.getOffset(cal.getTimeInMillis());
		cal.set(Calendar.MILLISECOND, -offset);
		Date startDate = cal.getTime();
		Date startDate2 = cal2.getTime();
		parameters.setStartDate(startDate2);
		parameters.setCalendarStartDate(startDate);
		
		cal.set(2017, Calendar.JUNE, 30, 23, 59, 59);
		cal2.set(2017, Calendar.JUNE, 30, 23, 59, 59);
		offset = tz.getOffset(cal.getTimeInMillis());
		//cal.set(Calendar.MILLISECOND, -offset);
		Date endDate = cal.getTime();
		Date endDate2 = cal2.getTime();
		parameters.setEndDate(endDate2);
		parameters.setCalendarEndDate(endDate);
		
		parameters.setScoreAvailabilityDayReward(0);
		parameters.setScoreCapabilityAuditPenalty(0);
		parameters.setScoreContractorPenalties(0);
		parameters.setScoreDistanceKmPenalty(1);
		parameters.setResourceIds(new String[] {
				//"a0nd0000000hAk2AAE", //Janet Hoh
				//"a0nd0000000hAkDAAU", //Osvaldo Marques
				//"a0nd0000000hAkFAAU", //Raymond Ng
				//"a0nd0000000hAkgAAE", //Sylvia Butcher
				//"a0nd0000000hAksAAE", //Sigit Yulianto
				//"a0nd0000000hAkZAAU", //John Webster
				//"a0nd0000000hAl1AAE", //Minnie Rong
				//"a0nd0000000hAmOAAU", //Richard Bickle
				"a0nd0000000hAmrAAE", //David Tseng
				//"a0nd0000000hAmuAAE", //Scott Trevitt
				//"a0nd0000000hAn0AAE", //Simon Fraser
				"a0nd0000000hAomAAE", //Jim Li
				//"a0nd0000000hAotAAE", //Anthony Alberts
				//"a0nd0000000hAoVAAU", //Lina Zhao
				//"a0nd0000000hApFAAU", //Roger Marriott
				//"a0nd0000000hApIAAU", //Ranganathan Raghavan
				"a0nd0000000hApQAAU", //Gordon Walton
				"a0nd0000000hAvFAAU", //Diego Piazzano
				"a0nd0000000hAvsAAE", //Matthew Slater
				//"a0nd0000000hAvSAAU", //David Connelly
				//"a0nd0000000hAwbAAE", //Graeme Kitto
				//"a0nd0000000hAwfAAE", //Davy Wei
				//"a0nd0000000hAzXAAU", //Wendy Lim
				//"a0nd0000000hB07AAE", //Mark Hazeldine
				//"a0nd0000000hB08AAE", //Colin Marchant
				//"a0nd0000000hB09AAE", //Mark Saxon
				//"a0nd0000000hB0CAAU", //Richard Donarski
				"a0nd0000000hB0DAAU", //Giuliano Franzosi
				//"a0nd0000000hB0EAAU", //Julia Arbanas
				//"a0nd0000000hB0FAAU", //Norman Thomas
				"a0nd0000000hPw4AAE", //Christian Halford
				"a0nd0000000jUhnAAE", //Jenny Tang
				//"a0nd0000000tAz7AAE", //Jason Friedrich
				//"a0nd0000000tiqvAAA", //Qiaoli Meng
				//"a0nd0000000wM6VAAU", //David (Dawei) Lu
				//"a0nd00000013TRIAA2", //Bill Iskander
				//"a0nd0000001WXrSAAW", //George Liu
				//"a0nd0000001XPZsAAO", //Jeffery Judd
				//"a0nd0000001YGzuAAG", //Cher Seong Phang
				//"a0nd0000002ahYtAAI", //William Wang
				//"a0nd0000002G5WWAA0", //Aaron Carson
				//"a0nd0000002p6pHAAQ", //Graham Blucher
				"a0nd0000003vy81AAA", //Geoff White
				//"a0nd0000003wFszAAE", //David Barnes
				//"a0nd0000003yM4YAAU", //Rebecca Searcy
				//"a0nd0000004qNHoAAM", //Thomas Guan
				//"a0nd0000004qNHtAAM", //Barak Mizrachi
				//"a0nd0000005YxZrAAK", //Kin Shing Chan
				//"a0nd0000005Znr3AAC", //Tony Liu
				//"a0nd0000005ZntEAAS", //Gautam Yadav
				//"a0nd0000000hAkXAAU", //Edward Waloch
				//"a0nd0000000hAkKAAU", //Ismael Parra
				//"a0nd0000000hAmSAAU", //Gerry Pisani
				//"a0nd0000000hAkPAAU", //Mike Ryan
				//"a0nd0000000hAo2AAE", //Jessica Zhong
				//"a0nd0000000hAoIAAU", //Sechul Kim
				//"a0nd0000000hAohAAE", //Nambi Narasimhan Manohar
				//"a0nd0000002FPFpAAO", //Arun Kumar Sinha
				//"a0nd0000000hAktAAE", //Setyo Sutadiono
				//"a0nd0000000hAk5AAE", //David Kershaw				
		});
		
		parameters.setExcludeStandardNams(new String[] {"9001:2008 | Certification", "9001:2015 | Certification"});
		
		return parameters;
	}
	
	@Override
	public Processor getProcessor(DbHelper db, ScheduleParameters sp) throws Exception {
		Processor processor = new ProcessorProductServices(db, sp);
		return processor;
	}
}
