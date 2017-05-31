package com.saiglobal.sf.allocator.implementation;

import com.saiglobal.sf.allocator.data.DbHelper;
import com.saiglobal.sf.allocator.processor.Processor;
import com.saiglobal.sf.core.model.ScheduleParameters;
import com.saiglobal.sf.core.utility.GlobalProperties;

public interface Allocator {
	public ScheduleParameters getParameters(GlobalProperties cmd);
	public Processor getProcessor(DbHelper db, ScheduleParameters sp) throws Exception;
}
