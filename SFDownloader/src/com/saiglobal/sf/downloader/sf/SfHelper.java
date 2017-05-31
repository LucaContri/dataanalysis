package com.saiglobal.sf.downloader.sf;

import org.apache.log4j.Logger;

import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;
import com.sforce.soap.partner.Connector;
import com.sforce.soap.partner.DescribeGlobalResult;
import com.sforce.soap.partner.DescribeSObjectResult;
import com.sforce.soap.partner.PartnerConnection;
import com.sforce.soap.partner.QueryResult;
import com.sforce.soap.partner.sobject.SObject;
import com.sforce.ws.ConnectionException;
import com.sforce.ws.ConnectorConfig;

public class SfHelper extends Utility {

	private static final Logger logger = Logger.getLogger(SfHelper.class);
	private PartnerConnection connection;
	private ConnectorConfig config;
	private GlobalProperties Cmd_;
	
	public SfHelper(GlobalProperties cmd) {
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
		config.setReadTimeout(Cmd_.getSfReadTimeOut());
		config.setConnectionTimeout(Cmd_.getSfConnectionTimeout());
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

	public DescribeSObjectResult describeObject(String object) {
		try {
			connect();
			return connection.describeSObject(object);
			
			
		} catch (Exception e) {
			logger.error("Error Occurred while connecting to salesforce.com",e);
			Utility.handleError(Cmd_, e);
		} finally{
			
		}
		
		return null;
	}
	
	public int count(String object) {
		try {
			QueryResult res = connection.query("select Count() from " + object);
			return res.getSize();
		} catch (Exception e) {
			Utility.handleError(Cmd_, e);
		}
		return -1;
	}
	
	public SObject[] executeQuery(String query) {
		try {
			return connection.queryAll(query).getRecords();
		} catch (Exception e) {
			Utility.handleError(Cmd_, e);
		}
		return null;
	}
	
	public DescribeGlobalResult describeGlobal() {
		try {
			return connection.describeGlobal();
			
			
		} catch (Exception e) {
			logger.error("Error Occurred while connecting to salesforce.com",e);
			Utility.handleError(Cmd_, e);
		} finally{
			
		}
		return null;
	}
}
