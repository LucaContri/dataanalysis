package com.saiglobal.sf.allocator.processor;

import java.util.List;

import com.saiglobal.sf.allocator.data.DbHelper;
import com.saiglobal.sf.allocator.rules.ProcessorRule;
import com.saiglobal.sf.core.model.ScheduleParameters;

public interface Processor {
	public List<ProcessorRule> getRules();
	
	public int getBatchSize();

	public void execute() throws Exception;
	
	public void setDbHelper(DbHelper db);
	
	public void setParameters(ScheduleParameters sp);
	
	public void init() throws Exception;
	
}
