package com.saiglobal.sf.downloader.processor;

public class DataProcessor_EventCleaner extends
		AbstractPostDownloadDataProcessor {

	@Override
	public void executeInternal() throws Exception {
		// Clean up event table
		logger.debug("Cleaning up event table...");
		String update = "update " + db.getDBTableName("event") + " e left join " + db.getDBTableName("work_item_resource__c") + " wir on e.WhatId=wir.Id set e.IsDeleted=1 where wir.IsDeleted=1 and e.IsDeleted=0";
		int rowsAffected = db.executeStatement(update);
		logger.debug("Set " + rowsAffected + " event records to IsDeleted=1");
	}

	@Override
	public String getName() {
		return "EventCleaner";
	}

}
