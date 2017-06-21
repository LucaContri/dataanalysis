package com.saiglobal.sf.allocator.implementation;

import java.util.Calendar;
import java.util.GregorianCalendar;
import java.util.TimeZone;

import org.apache.log4j.Logger;

import com.saiglobal.sf.allocator.data.DbHelper;
import com.saiglobal.sf.allocator.processor.MIP2Processor;
import com.saiglobal.sf.allocator.processor.MIP3Processor;
import com.saiglobal.sf.allocator.processor.MIP4Processor;
import com.saiglobal.sf.allocator.processor.Processor;
import com.saiglobal.sf.core.model.ResourceEventType;
import com.saiglobal.sf.core.model.ScheduleParameters;
import com.saiglobal.sf.core.model.CompassRevenueOwnership;
import com.saiglobal.sf.core.model.SfResourceCompetencyRankType;
import com.saiglobal.sf.core.model.SfResourceType;
import com.saiglobal.sf.core.model.SfWorkItemStatus;
import com.saiglobal.sf.core.utility.GlobalProperties;

public class ResourceAllocatorMIPMilkRunsUK implements Allocator {
	
	protected Logger logger = Logger.getLogger(ResourceAllocatorMIPMilkRunsUK.class);
	
	@Override	
	public ScheduleParameters getParameters(GlobalProperties cmd) {
		
		// Input parameters
		ScheduleParameters parameters = new ScheduleParameters();
		parameters.setBatchId("UK Forward Planning Milk Runs");
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
		cal.set(2018, Calendar.JANUARY, 1);
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
		cal.set(2018, Calendar.JUNE, 30);
		
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
		parameters.setExcludeStandardNams(new String[] {"SMETA | Verification","SMETA BPG V4 2-Pillar : 2012 | Verification","SMETA BPG V4 4-Pillar : 2012 | Verification", "McDonalds Supplier Workplace Accountability - Europe : 2013 | Verification"});
		parameters.setBoltOnStandards(new String[] { "ASDA AA | Verification","ASDA AA | Certification","ASDA AA - Food V1 | Certification","ASDA Concession Audit V4 (2015) | Inspection","ASDA AA - Food V5.1 | Certification",
				"BRC Meat Supply Chain AVM 11 | Verification", 
				"McDonalds SQMS - 4.0 - GFSI Addendum Bolt On - Europe | Verification", "McDonalds SQMS - 4.0 -GFSI Addendum Bolt On : APMEA | Verification"
		});
		//parameters.setWorkItemIds(new String[] {"a3Id0000001lFfeEAE"});
		
		//parameters.setWorkItemIds(new String[] {"a3Id0000000cSxHEAU","a3Id0000000cU03EAE","a3Id0000000cU08EAE","a3Id0000000cU0DEAU","a3Id0000000cVdvEAE"});
		//parameters.setFixedCapacity(90.0);
		//parameters.setResourceIds(new String[] {"a0nd0000000hAmGAAU", "a0nd0000000hAoAAAU", "a0nd0000000hAoMAAU", "a0nd0000000hAqpAAE", "a0nd0000000hAtJAAU", "a0nd0000000hAtZAAU", "a0nd0000000hAuCAAU", "a0nd0000000hAvNAAU", "a0nd0000000hAvOAAU", "a0nd0000000hAvTAAU", "a0nd0000000hAw4AAE", "a0nd0000000hAx9AAE", "a0nd0000000hAyoAAE", "a0nd0000000hHk3AAE", "a0nd0000000w1WpAAI", "a0nd0000001rX6fAAE", "a0nd0000001sfNOAAY", "a0nd0000002GD2bAAG", "a0nd0000002GD2dAAG", "a0nd0000002GD2gAAG", "a0nd0000002GD2hAAG", "a0nd0000002GD2jAAG", "a0nd0000002GD2lAAG", "a0nd0000002GD2rAAG", "a0nd0000002GD2tAAG", "a0nd0000002GD2uAAG", "a0nd0000002GD2vAAG", "a0nd0000002GD2wAAG", "a0nd0000002GD35AAG", "a0nd0000002GD37AAG", "a0nd0000002GD3CAAW", "a0nd0000002GD3VAAW", "a0nd0000002GD3WAAW", "a0nd0000002GjSWAA0", "a0nd0000002GjYKAA0", "a0nd0000002GZHQAA4", "a0nd0000002GZI4AAO", "a0nd0000002GZIYAA4", "a0nd0000002IHPyAAO", "a0nd0000002pcCNAAY", "a0nd0000002pKeXAAU", "a0nd0000002pV00AAE", "a0nd0000002ZkazAAC", "a0nd0000002ZkZIAA0", "a0nd0000002ZXHaAAO", "a0nd0000004q3g7AAA", "a0nd0000004qJgdAAE", "a0nd0000004qmS2AAI", "a0nd0000004rnhPAAQ", "a0nd00000066ctwAAA", "a0nd00000067EpEAAU", "a0nd00000067HH7AAM"});
		//parameters.setResourceNames(new String[] {"Amanda Catto"});
		// Exclude EMEA UK Resources not used in the last six months except "Dylan Parsons"
		parameters.setExcludeResourceNames(new String[] {"Gabriella Molnar","Mandie Schofield","Per Ake Hallberg","Malcolm Needham","Miklos Pal Hajnal","Gilberto Borromeo","Chris McKirgan","Nick Lengden","Giulia Fantini","Maria Clarkson","Caroline Taylor","Gillian Hinchliffe","Liz Narborough","Adam Chappell","Jane Padfield","Minaxi Modi","Robin Levin","Harriet Simmonds","Abena Nkrumah","Alison Knox","Andrew Spooner","Janet Field","Julie Badger","Julie Ormerod","Philip Clifford","Scott Woodward","David Heath","Sarah McDougal","Andrew Baisley","Keri Richards","Malcolm Tune","Beverley Weare","Paul Greensmith","Hilary Willoughby","Caroline Blaydon","Francis Barimah","Derek Demmer","Julia Dullaway","Karen Wilmett","Richard Wynn","Neil East","Rachel Rose","Ricky Patel","Robert Clarke","Stephen Wealls","John Virgobrown","Sue Wallis","Amira Amin Rubio","John Casson","Anthony Murray","Karolina Jazlarz","Lisa Sugarman","Brian Taylor","Paul Clarke","Philip Reynolds","Paul Liebow","Michelle Elmes","Pauline Ervine","Neil Tranter","Jill Walker","Sarah Crisp","Robert Coote","Stephanie Franks","David Cox","Mark Liebow","Deborah Goldie","Reg Towler","Robin Postlethwaite","Mick Sheppard","Nick Hargrave","Angharad Simkiss","Hazel Marshall","Helen Phythian","David Williams","Isabel Hart","Laura Milverton","Neil Wright","Nicola Hedden","Lucy Blackwell","Sarah Cunningham","Geoff Marson","Stacy Thomas","Fay Griffiths","Victoria Watkins","Geoff Patten","John Pratt","Geoff Whitaker","Ken Park","Jackie Matthias","Paula Kelly","Vivien Masterton","Chris Talbot","Peter Smith","David Gair","Henrik Christensen","Jill Greenway","Kate Rowe","Amy Stark","Lisa Rundle2","Paul Bates","Jenny Bibb","Stuart Geggie","Kathryn Vaughan","Steven Jones","Allan Williams","Leanne Eyre","Bruce Cook","Tim Morgan","Jason Gale","Roger Brown","John Ryder","Sarah Hampshire","Mike Rawle","Donald Gilder","Colin Campbell","John Page","David Taylor","Martin Brooks","Gemma Clay","Peter Grice","Nicola McGuigan","Patrick Devane","Kathleen Moriarty","Suzanne Godden","Craig Stone","Barrie Taylor","Kim Armstrong","Simon Gregory","Josie Brown","Susan Baker","Ian Perigo","Simon Goldby","Aaron Day"});
		
		return parameters;
	}

	@Override
	public Processor getProcessor(DbHelper db, ScheduleParameters sp) throws Exception {
		Processor processor = new MIP3Processor(db, sp);
		return processor;
	}
}
