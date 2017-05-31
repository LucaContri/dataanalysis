package com.saiglobal.sf.allocator.data;

import java.sql.SQLException;

import com.saiglobal.sf.core.utility.GlobalProperties;


public class DbHelper extends com.saiglobal.sf.core.data.DbHelper {

	
	private static String ScheduleTableName = "Allocator_Schedule";	
	private static String ScheduleBatchTableName = "Allocator_Schedule_Batch";	
	
	
	public DbHelper(GlobalProperties cmd) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException {
		super(cmd);
		airports = loadAirports();
	}	
	
	public String getCreateScheduleTableSql() {
		return "CREATE TABLE IF NOT EXISTS " + getScheduleTableName() + " ( " +
				   "Id INT AUTO_INCREMENT NOT NULL," +
				   "BatchId VARCHAR(100) NOT NULL, " +
				   "SubBatchId INT NOT NULL, " +
				   "WorkItemId VARCHAR(20), " +
				   "WorkItemName VARCHAR(20), " +
				   "WorkItemCountry VARCHAR(20), " +
				   "WorkItemState VARCHAR(20), " +
				   "ResourceId VARCHAR(20), " +
				   "ResourceName VARCHAR(255), " +
				   "ResourceType VARCHAR(30), " +
				   "StartDate DATETIME, " +
				   "EndDate DATETIME, " +
				   "Duration DECIMAL(5,2), " +
				   "Status VARCHAR(20), " +
				   "Type VARCHAR(20), " +
				   "PrimaryStandard VARCHAR(255), " +
				   "Competencies VARCHAR(1000), " +
				   "Comment VARCHAR(255), " +
				   "PRIMARY KEY (Id)"+
				   ") ENGINE = InnoDB ROW_FORMAT = DEFAULT;";
	}
	
	public String getCreateScheduleBatchTableSql() {
		return "CREATE TABLE IF NOT EXISTS " + getScheduleBatchTableName() + " ( " +
				   "Id INT AUTO_INCREMENT NOT NULL," +
				   "BatchId VARCHAR(100) NOT NULL, " +
				   "SubBatchId INT NOT NULL, " +
				   "RevenueOwnership VARCHAR(1000), " +
				   "ReportingBusinessUnits VARCHAR(1000), " +
				   "WorkItemStatuses VARCHAR(1000), " +
				   "ResourceTypes VARCHAR(1000), " +
				   "StartDate DATETIME, "+
				   "EndDate DATETIME, "+
				   "Comment VARCHAR(1000), " +
				   "PRIMARY KEY (Id)"+
				   ") ENGINE = InnoDB ROW_FORMAT = DEFAULT;";
	}
	
	public String getScheduleTableName() {
		return getDBTableName(ScheduleTableName);
	}
	public String getScheduleBatchTableName() {
		return getDBTableName(ScheduleBatchTableName);
	}
}