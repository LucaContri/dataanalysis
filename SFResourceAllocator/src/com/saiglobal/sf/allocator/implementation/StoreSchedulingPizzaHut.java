package com.saiglobal.sf.allocator.implementation;

import com.saiglobal.sf.allocator.data.DbHelper;
import com.saiglobal.sf.allocator.processor.PizzaHutMIPProcessor;
import com.saiglobal.sf.allocator.processor.Processor;
import com.saiglobal.sf.core.model.ScheduleParameters;
import com.saiglobal.sf.core.utility.GlobalProperties;

public class StoreSchedulingPizzaHut implements Allocator {

	@Override
	public ScheduleParameters getParameters(GlobalProperties cmd) {
		return new ScheduleParameters();
	}

	@Override
	public Processor getProcessor(DbHelper db, ScheduleParameters sp) throws Exception {
		return new PizzaHutMIPProcessor();
	}

}
