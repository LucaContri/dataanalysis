package com.saiglobal.scrapers.processors;

import com.saiglobal.scrapers.model.ProcessorOutput;
import com.saiglobal.sf.core.data.DbHelper;
import com.saiglobal.sf.core.utility.GlobalProperties;

public interface ScraperProcessor {
	
	public void init(GlobalProperties gp, DbHelper db) throws Exception, Throwable;
	
	public ProcessorOutput getCertifiedOrganisations() throws Exception;
	
	public String[] getTrackHistoryFields();
	
	public ProcessorDetails getDetails();
	
}
