package com.saiglobal.sf.downloader.sf;

import java.io.IOException;
import java.util.HashMap;
import java.sql.SQLException;

import org.apache.log4j.Logger;

import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;
import com.saiglobal.sf.downloader.data.DbHelper;
import com.saiglobal.sf.downloader.processor.PostDownloadDataProcessor;
import com.sforce.soap.partner.Connector;
import com.sforce.soap.partner.DescribeGlobalResult;
import com.sforce.soap.partner.DescribeGlobalSObjectResult;
import com.sforce.soap.partner.PartnerConnection;
import com.sforce.ws.ConnectionException;
import com.sforce.ws.ConnectorConfig;

public class SfDownloader extends Utility {

	private static final Logger logger = Logger.getLogger(SfDownloader.class);
	private PartnerConnection connection;
	private ConnectorConfig config;
	private GlobalProperties Cmd_;
	
	public SfDownloader(GlobalProperties cmd) {
		Cmd_ = cmd;
		this.testConnectivity();
	}
	
	private void connect() throws ConnectionException {
		config = new ConnectorConfig();
		config.setUsername(Cmd_.getSfUser());
		config.setPassword(Cmd_.getSfPassword()+Cmd_.getSfToken());
		if (Cmd_.isEnableProxy()) {
			config.setProxy(Cmd_.getProxyHost(), Cmd_.getProxyPort());
			if (Cmd_.isProxyAuthRequired()){
				config.setProxyUsername(Cmd_.getProxyUser());
				config.setProxyPassword(Cmd_.getProxyPassword());
			}
		}
		config.setAuthEndpoint(Cmd_.getSfEndpoint());
		config.setReadTimeout(180000);
		config.setConnectionTimeout(180000);
		connection=Connector.newConnection(config);
	}
	
	public boolean testConnectivity() {
		try {
			connect();
			logger.debug("Trying to connect to sforce.com");
			logger.debug("Salesforce.com auth endPoint is [" + config.getAuthEndpoint() + "]");
			logger.debug("Salesforce.com service endPoint ["	+ config.getServiceEndpoint() + "]");
			logger.debug("Salesforce.com username [" + config.getUsername() + "]");
			logger.debug("Salesforce.com sessionId [" + config.getSessionId() + "]");
			logger.debug("Successfully verified the salesforce.com connectivity");
			return true;
		} catch (ConnectionException e) {
			logger.error("Error Occurred while connecting to salesforce.com",e);
			Utility.handleError(Cmd_, e);
		}
		return false;
	}

	public void execute() {
		DescribeGlobalResult dgResult;
		DbHelper dbHelper=new DbHelper(Cmd_);
		try {
			connect();
			dgResult = connection.describeGlobal();
			DescribeGlobalSObjectResult[] soResults = dgResult.getSobjects();
			HashMap<String, DescribeGlobalSObjectResult> sfObjects = new HashMap<String, DescribeGlobalSObjectResult>();
			int maxBatchSize = dgResult.getMaxBatchSize();
			logger.debug("Max batch size for your Organization is " + maxBatchSize);
			dbHelper.openConnection();
			SfObject sfo;
			String[] existingTables = dbHelper.getLoadedTables();
			String[] specialObjects = dbHelper.getIncludedObjects();
			for(DescribeGlobalSObjectResult soResult : soResults ) {
				sfObjects.put(soResult.getName(), soResult);
				if(!Utility.inArray(existingTables, Cmd_.getDbPrefix()+soResult.getName())) {
					sfo = new SfObject(connection, soResult, Cmd_,specialObjects);
					if (Cmd_.isCreateLocalTables()) {
						logger.info("Start creating local object [" + soResult.getName() + "]");
						sfo.createTable(dbHelper);
						logger.info("Finished creating local object [" + soResult.getName() + "]");
					}
					if (Cmd_.isCreateLocalSqlfiles()) {
						sfo.writeTableScript();
					}
					sfo = null;
				}
			}
			boolean cleanEvents = false;
			for (String table : dbHelper.getObjectsToBeSyncd()) {
				DescribeGlobalSObjectResult soResult = sfObjects.get(table);
				if (table.equalsIgnoreCase("work_item_resource__c"))
					cleanEvents = true;
				if (soResult == null)
					continue;
				logger.debug("Starting sync of object [" + soResult.getName() + "]");
				Utility.startTimeCounter("LoadingObject");
				sfo = new SfObject(connection, soResult, Cmd_,specialObjects);
				Utility.stopTimeCounter("LoadingObject");
				if(Cmd_.isPopulateDb()) {
					Utility.startTimeCounter("upsertSfDataIntoDB");
					sfo.upsertSfDataIntoDB(dbHelper, maxBatchSize);
					Utility.stopTimeCounter("upsertSfDataIntoDB");
				}
				logger.debug("Finished sync of object [" + soResult.getName() + "]");
				sfo = null;
			}
			
			// Post Download Data Processors
			for (PostDownloadDataProcessor processor : dbHelper.getDataProcessorsToBeRun()) {
				if (processor.getName().startsWith("EventCleaner") && !cleanEvents)
					 continue;
				logger.debug("Starting data processor [" + processor.getName() + "]");
				Utility.startTimeCounter(processor.getName());
				try {
					processor.setDb(dbHelper);
					processor.execute();
				} catch (Exception e) {
					Utility.handleError(Cmd_, e);
				}
				Utility.stopTimeCounter(processor.getName());
				logger.debug("Finished data processor [" + processor.getName() + "]");
			}
			
		} catch (ConnectionException e) {
			logger.error("Error Occurred while connecting to salesforce.com",e);
			Utility.handleError(Cmd_, e);
		} catch (InstantiationException e) {
			logger.error("DB Error Occurred while connecting to local db",e);
			Utility.handleError(Cmd_, e);
		} catch (IllegalAccessException e) {
			logger.error("DB Error Occurred while connecting to local db",e);
			Utility.handleError(Cmd_, e);
		} catch (ClassNotFoundException e) {
			logger.error("DB Error Occurred while connecting to local db",e);
			Utility.handleError(Cmd_, e);
		} catch (SQLException e) {
			logger.error("DB Error Occurred while connecting to local db",e);
			Utility.handleError(Cmd_, e);
		} catch (IOException e) {
			logger.error("File IO error",e);
			Utility.handleError(Cmd_, e);
		}
		finally{
			dbHelper.closeConnection();
		}
	}

}
