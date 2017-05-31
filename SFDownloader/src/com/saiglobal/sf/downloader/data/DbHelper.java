package com.saiglobal.sf.downloader.data;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

import org.apache.log4j.Logger;

import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.downloader.processor.PostDownloadDataProcessor;

public class DbHelper extends com.saiglobal.sf.core.data.DbHelper {

	private static final Logger logger = Logger.getLogger(DbHelper.class);
	private GlobalProperties cmd;
	
	 private static String SFTabbleCreateSql = 
			"CREATE TABLE IF NOT EXISTS SF_Tables ( Id INT AUTO_INCREMENT NOT NULL," +
			   "TableName VARCHAR(100), " +
			   "RowCount INT, "+
			   "UpdateValue DATETIME, "+
			   "LastSyncDate DATETIME, "+
			   "ToSync BOOLEAN NOT NULL DEFAULT 0, "
			   + "MinSecondsBetweenSyncs INT(10) UNSIGNED DEFAULT 3600, " +
			   "PRIMARY KEY (Id)"+
			   ") ENGINE = InnoDB ROW_FORMAT = DEFAULT;";
	
	
	private static String getSFTabbleCreateSql() {
		return SFTabbleCreateSql;
	}
	
	public DbHelper(GlobalProperties cmd) {
		super(cmd);
	}

	public List<String> GetTableNames(String prefix) throws InstantiationException, IllegalAccessException,
			ClassNotFoundException, SQLException {
		String query = "SELECT table_name,count(*) FROM information_schema.`COLUMNS` C " + "WHERE TABLE_SCHEMA = '"
				+ cmd.getDbSchema() + "' group by table_name order by 2 desc";
		List<String> tables = new ArrayList<String>();
		try {
			openConnection();
			logger.debug(query);			
			ResultSet rs = executeSelect(query, -1);
			while (rs.next()) {
				tables.add(rs.getString("table_name").replace(prefix.toLowerCase(), ""));
			}
			return tables;
		} finally {
			closeConnection();
		}
	}


	
	public void createLog(String tableName,String updatevalue,int rowCount) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException {
		String query;
		if(updatevalue != null) {
			query = "INSERT INTO SF_Tables (TableName,RowCount,UpdateValue,LastSyncDate) VALUES('" + tableName + "'," + rowCount + ",'"+ updatevalue + "', '1970-01-01 00:00:00');";
		}else {
			query = "INSERT INTO SF_Tables (TableName,RowCount,LastSyncDate) VALUES('" + tableName + "'," + rowCount + ", '1970-01-01 00:00:00');";
		}
		executeStatement(query);
	}
	
	public String[] getLoadedTables() throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException {
		
		executeStatement(getSFTabbleCreateSql());
		String query = "SELECT tableName FROM SF_Tables";
		ResultSet rs=this.executeSelect(query,-1);
		List<String> result = new ArrayList<String>();
		while (rs.next()) {
			result.add(rs.getString("tableName"));
		}
		rs.close();
		return result.toArray(new String[0]);
	}
	
	public String[] getIncludedObjects() throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException {
		//executeStatement(getSFTabbleCreateSql());
		String query = "SELECT tableName FROM SF_Tables WHERE ToSync=1";
		ResultSet rs=this.executeSelect(query,-1);
		List<String> result = new ArrayList<String>();
		while (rs.next()) {
			result.add(rs.getString("tableName"));
		}
		rs.close();
		return result.toArray(new String[0]);
	}
	
	public String[] getObjectsToBeSyncd() throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException {
		//executeStatement(getSFTabbleCreateSql());
		String query = "SELECT TableName FROM SF_Tables WHERE ToSync=1 AND DATE_ADD(LastSyncDate, INTERVAL MinSecondsBetweenSyncs SECOND)<UTC_TIMESTAMP()";
		ResultSet rs=this.executeSelect(query,-1);
		List<String> result = new ArrayList<String>();
		while (rs.next()) {
			result.add(rs.getString("tableName"));
		}
		rs.close();
		return result.toArray(new String[0]);
	}
	
	public PostDownloadDataProcessor[] getDataProcessorsToBeRun() throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException {
		String query = "SELECT ProcessorName, ProcessorClass FROM sf_data_processors WHERE DATE_ADD(LastExecDate, INTERVAL MinSecondsBetweenExec SECOND)<UTC_TIMESTAMP()";
		ResultSet rs=this.executeSelect(query,-1);
		List<PostDownloadDataProcessor> result = new ArrayList<PostDownloadDataProcessor>();
		while (rs.next()) {
			Class<?> processorCalss = Class.forName(rs.getString("ProcessorClass"));
			PostDownloadDataProcessor processor = (PostDownloadDataProcessor)processorCalss.newInstance();
			result.add(processor);
		}
		rs.close();
		return result.toArray(new PostDownloadDataProcessor[result.size()]);
	}
	
	public List<String> getTableFields(String tableName) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException {
		String query = "DESCRIBE " + tableName;
		ResultSet rs=this.executeSelect(query,-1);
		List<String> result = new ArrayList<String>();
		while (rs.next()) {
			result.add(rs.getString("Field"));
		}
		rs.close();
		return result;
	}

}