package com.saiglobal.sf.allocator.main;

import java.util.Calendar;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.TimeZone;

import org.apache.log4j.Logger;

import com.saiglobal.sf.allocator.data.DbHelper;
import com.saiglobal.sf.core.model.ScheduleParameters;
import com.saiglobal.sf.core.model.CompassRevenueOwnership;
import com.saiglobal.sf.core.model.SfResourceCompetencyRankType;
import com.saiglobal.sf.core.model.SfResourceType;
import com.saiglobal.sf.core.model.SfWorkItemStatus;
import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;

public class ResourceAllocatorV2 {
	private static final Logger logger = Logger.getLogger(ResourceAllocatorV2.class);
	public static String taskName = "sfallocator";
	
	public static void main(String[] commandLineArguments) {
		
		// Initialisation
		logger.info("Starting SAI global - Resource Allocator" );
		
		GlobalProperties cmd = GlobalProperties.getDefaultInstance();
		cmd.setCurrentTask(taskName);
				
		// Input parameters
		ScheduleParameters parameters = new ScheduleParameters();
		parameters.setBatchId("TEST Dec 2013");
		parameters.setRevenueOwnership(new CompassRevenueOwnership[] {
				CompassRevenueOwnership.AUSManagedNSWACT,
				CompassRevenueOwnership.AUSManagedQLD,
				CompassRevenueOwnership.AUSManagedSANT,
				CompassRevenueOwnership.AUSManagedVICTAS,
				CompassRevenueOwnership.AUSManagedWA,
				CompassRevenueOwnership.AUSManagedPlusNSWACT,
				CompassRevenueOwnership.AUSManagedPlusQLD,
				CompassRevenueOwnership.AUSManagedPlusSANT,
				CompassRevenueOwnership.AUSManagedPlusVICTAS,
				CompassRevenueOwnership.AUSManagedPlusWA,
				CompassRevenueOwnership.AUSDirectNSWACT,
				CompassRevenueOwnership.AUSDirectQLD,
				CompassRevenueOwnership.AUSDirectSANT,
				CompassRevenueOwnership.AUSDirectVICTAS,
				CompassRevenueOwnership.AUSDirectWA,
				CompassRevenueOwnership.AUSFoodNSWACT,
				CompassRevenueOwnership.AUSFoodQLD,
				CompassRevenueOwnership.AUSFoodSANT,
				CompassRevenueOwnership.AUSFoodSANT,
				CompassRevenueOwnership.AUSFoodVICTAS,
				CompassRevenueOwnership.AUSFoodWA});
		/*
		parameters.setRepotingBusinessUnits(new CompassRevenueOwnership[] {
				CompassRevenueOwnership.AUSManagedNSWACT,
				CompassRevenueOwnership.AUSManagedQLD,
				CompassRevenueOwnership.AUSManagedROW,
				CompassRevenueOwnership.AUSManagedSANT,
				CompassRevenueOwnership.AUSManagedVICTAS,
				CompassRevenueOwnership.AUSManagedPlusWA});*/
		parameters.setRepotingBusinessUnits(parameters.getRevenueOwnership());
		parameters.setResourceTypes(new SfResourceType[] {SfResourceType.Employee, SfResourceType.Contractor});
		parameters.setLoadCalendar(true);
		parameters.setWorkItemsStatus(new SfWorkItemStatus[] {
				SfWorkItemStatus.Open, 
				//SfWorkItemStatus.Allocated,
				//SfWorkItemStatus.Complete,
				//SfWorkItemStatus.Completed,
				//SfWorkItemStatus.Confirmed,
				//SfWorkItemStatus.InProgress,
				//SfWorkItemStatus.Scheduled,
				//SfWorkItemStatus.ScheduledOffered,
				//SfWorkItemStatus.ServiceChange,
				//SfWorkItemStatus.Submitted,
				//SfWorkItemStatus.UnderReview,
				//SfWorkItemStatus.UnderReviewRejected
				});
		//parameters.setWorkItemsStatus(null);
		parameters.setResourceCompetencyRanks(new SfResourceCompetencyRankType[] {
				SfResourceCompetencyRankType.LeadAuditor, 
				SfResourceCompetencyRankType.Auditor
		});
		TimeZone tz = TimeZone.getTimeZone("Australia/Sydney");
		parameters.setTimeZone(tz);
		Calendar cal = new GregorianCalendar();
		cal.setTimeZone(tz);
		cal.set(2013, Calendar.DECEMBER, 1, 0, 0, 0);
		int offset = tz.getOffset(cal.getTimeInMillis());
		cal.set(Calendar.MILLISECOND, -offset);
		Date startDate = cal.getTime();
		parameters.setStartDate(startDate);
		
		cal.set(2013, Calendar.DECEMBER, 31, 23, 59, 59);
		offset = tz.getOffset(cal.getTimeInMillis());
		cal.set(Calendar.MILLISECOND, -offset);
		Date endDate = cal.getTime();
		parameters.setEndDate(endDate);
		
		try {
			@SuppressWarnings("unused")
			DbHelper db = new DbHelper(cmd);
			
			// 1) Generate Initial Population using random allocator (int populationSize)
			
			// 2) Selection (bottom x% dies, top x%survive) (double selectionPressure)
			
			// 3) Pairs and generate offspring 
				// 3a) pairing in order of objective function 
					// - Sort Solutions in order of objective function
					// - Pair first with second, third with fourth, etc...
				
				// For each pair of Solutions from 3a)
				// 3b) With probability Pc [0,1] => Create offspring using 1 point crossover
					// - Generate random r in [0,1] -> if (r>=Pc) continue
					// - Generate 2 offsprings
					// - For each offspring - with probability Pm => Apply shift mutation
					// - Add offsprings to population
					// - Remove parents from population
			
			// 4) 
				// - Calculate objective function for all Solutions in population and save
				// - Increase generation counter
			
			// 5) If generation > maxGeneration -> continue otherwise go to 2)
			
			// 6) Save best Solution
						
		} catch (Exception e) {
			logger.error("", e);
			Utility.handleError(cmd, e);
		}	}

}
