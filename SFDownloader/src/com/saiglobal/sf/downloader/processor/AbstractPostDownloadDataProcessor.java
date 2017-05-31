package com.saiglobal.sf.downloader.processor;

import java.sql.SQLException;

import org.apache.log4j.Logger;

import com.saiglobal.sf.core.utility.Utility;
import com.saiglobal.sf.downloader.data.DbHelper;

public abstract class AbstractPostDownloadDataProcessor implements PostDownloadDataProcessor {
	
	protected DbHelper db;
	protected static final Logger logger = Logger.getLogger(AbstractPostDownloadDataProcessor.class);
	
	public void setDb(DbHelper db) {
		this.db = db;
	}
	
	public void updateLastExecuted() throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException {
		String sql = "UPDATE sf_data_processors SET LastExecDate = UTC_TIMESTAMP() WHERE ProcessorName='" + this.getName() + "'";
		db.executeStatement(sql);
	}
	
	public void execute() throws Exception {
		Utility.startTimeCounter("DataProcessor:"+getName());
		executeInternal();
		Utility.stopTimeCounter("DataProcessor:"+getName());
		updateLastExecuted();
		logger.info("DataProcessor:"+getName()+";ExecTime:"+Utility.getTimeCounterMS("DataProcessor:"+getName()));
	}
	
	protected void executeInternal() throws Exception {
	
	}

}
