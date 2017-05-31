package com.saiglobal.sf.core.utility;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Set;

import org.apache.log4j.Logger;

public class GlobalProperties {

	private static final Logger logger = Logger.getLogger(GlobalProperties.class);
	
	// File name
	private String fileName;
	
	// Proxy properties
	private boolean enableProxy=false;
    private boolean isProxyAuthRequired=false;
	private String proxyHost;
    private String proxyPort;
    private String proxyUser;
    private String proxyPassword;
    
    // Salesforce properties
    private String sfUser;
    private String sfPassword;
    private String sfToken;
    private String sfEndpoint;
    private int sfReadTimeOut;
    private int sfConnectionTimeout;
    
	// Local db details - Used by SfResourceAllocator and SFReportEngine
    public static final String SALESFORCE_DATASOURCE = "salesforce";
    private String currentDataSource = "compass";
    private HashMap<String,String> jdbcName = new HashMap<String,String>();
    private HashMap<String,String> dbUser = new HashMap<String,String>();
    private HashMap<String,String> dbPassword = new HashMap<String,String>();
    private HashMap<String,String> dbHost = new HashMap<String,String>();
    private HashMap<String,String> dbSchema = new HashMap<String,String>();
    private HashMap<String,String> dbPrefix = new HashMap<String,String>();
    private HashMap<String,String> DbConnectionURL = new HashMap<String,String>();
    private HashMap<String,String> DbDriver = new HashMap<String,String>();
    private HashMap<String, Boolean> DblogError= new HashMap<String,Boolean>();
	private String sqlPath="c:\\temp\\salesforce\\sqls";
    private String sqlTablefile="sf_objects_create.sql";
    private String sqlRelationfile="sf_relations_create.sql";
    private boolean createLocalSqlfiles=false;
    private boolean createLocalTables=true;
    private boolean dropIfTableExists=false;
	private boolean populateDb=true;
	
    // Used only by SfReportEngine
    private String reportBuilderClass;
    private String reportEmails;
    private String reportFormat;
    private boolean includeTimeInName;
    private boolean saveDataToHistory;
    private String reportFolder;
	private String sftpServer;
	private int sftpPort;
	private String sftpUser;
    private String sftpPassword;
    
    // Used only by FABBL downloader
    private String FABBLsourceFile;
    private String FABBLdestinationFile;
    
    // Used only by Allocator
    private String allocatorImplementationClass = null;
    private Double scoreAvailabilityDayReward = null;
	private Double scoreCapabilityAuditPenalty = null;
    private Double scoreContractorPenalties = null;
    private Double scoreDistanceKmPenalty = null;
    private Boolean includePipeline = null;
    
    public String getAllocatorImplementationClass() {
		return allocatorImplementationClass;
	}

	public void setAllocatorImplementationClass(String allocatorImplementationClass) {
		this.allocatorImplementationClass = allocatorImplementationClass;
	}

	public Double getScoreAvailabilityDayReward() {
		return scoreAvailabilityDayReward;
	}

	public void setScoreAvailabilityDayReward(double scoreAvailabilityDayReward) {
		this.scoreAvailabilityDayReward = scoreAvailabilityDayReward;
	}
	
	public void setScoreAvailabilityDayReward(String scoreAvailabilityDayReward) {
		this.scoreAvailabilityDayReward = scoreAvailabilityDayReward==null?null:Double.parseDouble(scoreAvailabilityDayReward);
	}

	public Double getScoreCapabilityAuditPenalty() {
		return scoreCapabilityAuditPenalty;
	}

	public void setScoreCapabilityAuditPenalty(double scoreCapabilityAuditPenalty) {
		this.scoreCapabilityAuditPenalty = scoreCapabilityAuditPenalty;
	}
	
	public void setScoreCapabilityAuditPenalty(String scoreCapabilityAuditPenalty) {
		this.scoreCapabilityAuditPenalty = scoreCapabilityAuditPenalty==null?null:Double.parseDouble(scoreCapabilityAuditPenalty);
	}

	public Double getScoreContractorPenalties() {
		return scoreContractorPenalties;
	}

	public void setScoreContractorPenalties(double scoreContractorPenalties) {
		this.scoreContractorPenalties = scoreContractorPenalties;
	}
	
	public void setScoreContractorPenalties(String scoreContractorPenalties) {
		this.scoreContractorPenalties = scoreContractorPenalties==null?null:Double.parseDouble(scoreContractorPenalties);
	}

	public Double getScoreDistanceKmPenalty() {
		return scoreDistanceKmPenalty;
	}

	public void setScoreDistanceKmPenalty(double scoreDistanceKmPenalty) {
		this.scoreDistanceKmPenalty = scoreDistanceKmPenalty;
	}

	public void setScoreDistanceKmPenalty(String scoreDistanceKmPenalty) {
		this.scoreDistanceKmPenalty = scoreDistanceKmPenalty==null?null:Double.parseDouble(scoreDistanceKmPenalty);
	}
	
	public Boolean isIncludePipeline() {
		return includePipeline;
	}

	public void setIncludePipeline(boolean includePipeline) {
		this.includePipeline = includePipeline;
	}
	
	public void setIncludePipeline(String includePipeline) {
		this.includePipeline = includePipeline==null?null:Boolean.parseBoolean(includePipeline);
	}
	
    public String getFABBLsourceFile() {
		return FABBLsourceFile;
	}

	public void setFABBLsourceFile(String fABBLsourceFile) {
		FABBLsourceFile = fABBLsourceFile;
	}

	public String getFABBLdestinationFile() {
		return FABBLdestinationFile;
	}

	public void setFABBLdestinationFile(String fABBLdestinationFile) {
		FABBLdestinationFile = fABBLdestinationFile;
	}

	@SuppressWarnings("static-access")
	public boolean usingSalesforce() {
		return this.getCurrentDataSource().equalsIgnoreCase(this.SALESFORCE_DATASOURCE);
	}
	public String getCurrentDataSource() {
		return currentDataSource;
	}

	public void setCurrentDataSource(String currentDataSource) {
		this.currentDataSource = currentDataSource;
	}
	
    // Used only by Spark Java (Scheduling Api)
    private int schedulingApiPort;

    public boolean isSaveDataToHistory() {
		return saveDataToHistory;
	}

	public void setSaveDataToHistory(String saveDataToHistory) {
		this.saveDataToHistory = Boolean.parseBoolean(saveDataToHistory);
	}

	// Email properties
    private String mail_transport_protocol;
    private String mail_smtp_starttls_enable;
    private String mail_smtp_host;
    private String mail_smtp_port;
	private String mail_smtp_auth;
	private String mail_smtp_user;
	private String mail_smtp_from;
	private String mail_smtp_password;
	private String mail_smtp_log_error_to;
	private String mail_imaps_host;
	private String mail_imaps_port;
	private boolean mail_imaps_auth;
	private boolean mail_imaps_starttls_enable;
	private String mail_imaps_user;
	private String mail_imaps_password;
	
	// Tasks Specific Properties
	private String currentTask;
    private HashMap<String, TaskProperties> taskProperties;
    
    // Custom Properties - Anything else passed by command line and not recoginsed
    private HashMap<String, String> custom_properties;
    
	public HashMap<String, String> getCustom_properties() {
		return custom_properties;
	}

	public void setCustom_properties(HashMap<String, String> custom_properties) {
		this.custom_properties = custom_properties;
	}
	
	public void addCustom_property(String name, String value) {
		if (this.custom_properties == null)
			this.custom_properties = new HashMap<String, String>();
		
		this.custom_properties.put(name, value);
	}

	public boolean hasCustomParameter(String name) {
		if (custom_properties != null)
			return custom_properties.containsKey(name);
		return false;
	}
	
	public String getCustomParameter(String name) {
		if (custom_properties != null)
			return custom_properties.get(name);
		return null;
	}
	public GlobalProperties() {
		taskProperties = new HashMap<String, TaskProperties>();
	}

	public static GlobalProperties getDefaultInstance() {
		return Utility.getProperties();
	}
	
	public void printArguments() {
		logger.debug("enableProxy ["+ enableProxy + "]");
	    
	    logger.debug("isProxyAuthRequired [" + isProxyAuthRequired+ "]");
	  
		logger.debug("proxyHost [" + proxyHost + "]");
	    logger.debug("proxyPort [" + proxyPort + "]");
	    logger.debug("proxyUser [" + proxyUser + "]");
	    logger.debug("proxyPassword [" + proxyPassword + "]");
	    
	    logger.debug("sfUser [" + sfUser + "]");
	    logger.debug("sfPassword [" + sfPassword + "]");
	    logger.debug("sfToken [" + sfToken + "]");
	    logger.debug("sfEndpoint [" + sfEndpoint + "]");
	    
	    logger.debug("dbUser [" + dbUser + "]");
	    logger.debug("dbPassword [" + dbPassword + "]");
	    logger.debug("dbHost [" + dbHost + "]");
	    logger.debug("dbSchema [" + dbSchema + "]");
	    logger.debug("dbPrefix [" + dbPrefix + "]");
	    
	    logger.debug("sqlPath [" + sqlPath + "]");
	    logger.debug("sqlTablefile [" + sqlTablefile + "]");
	    logger.debug("sqlRelationfile [" + sqlRelationfile + "]");
	    
	    logger.debug("createLocalSqlfiles [" + createLocalSqlfiles + "]");
	    logger.debug("createDbSchema [" + createLocalTables + "]");
	    logger.debug("populateDb [" + populateDb + "]");
	    
	    logger.debug("reportBuilderClass [" + reportBuilderClass +"]");
	    logger.debug("reportEmails [" + reportEmails + "]");
	    logger.debug("reportFormat [" + reportFormat +"]");
	}
	
	public String getJdbcName() {
		return getJdbcName(currentDataSource);
	}
	
	public String getJdbcName(String dataSourceName) {
		return jdbcName.get(dataSourceName);
	}
	
	public void setJdbcName(String jdbcName) {
		setJdbcName(currentDataSource, jdbcName);
	}
	
	public void setJdbcName(String dataSourceName, String jdbcName) {
		this.jdbcName.put(dataSourceName, jdbcName);
	}
	
	public String getMail_imaps_host() {
		return mail_imaps_host;
	}

	public void setMail_imaps_host(String mail_imaps_host) {
		this.mail_imaps_host = mail_imaps_host;
	}

	public String getMail_imaps_port() {
		return mail_imaps_port;
	}

	public void setMail_imaps_port(String mail_imaps_port) {
		this.mail_imaps_port = mail_imaps_port;
	}

	public boolean getMail_imaps_auth() {
		return mail_imaps_auth;
	}

	public void setMail_imaps_auth(String mail_imaps_auth) {
		this.mail_imaps_auth = Boolean.parseBoolean(mail_imaps_auth);
	}

	public boolean getMail_imaps_starttls_enable() {
		return mail_imaps_starttls_enable;
	}

	public void setMail_imaps_starttls_enable(String mail_imaps_starttls_enable) {
		this.mail_imaps_starttls_enable = Boolean.parseBoolean(mail_imaps_starttls_enable);
	}

	public String getMail_imaps_user() {
		return mail_imaps_user;
	}

	public void setMail_imaps_user(String mail_imaps_user) {
		this.mail_imaps_user = mail_imaps_user;
	}

	public String getMail_imaps_password() {
		return mail_imaps_password;
	}

	public void setMail_imaps_password(String mail_imaps_password) {
		this.mail_imaps_password = mail_imaps_password;
	}
	
	public Set<String> getAvailableDataSources() {
		Set<String> intersect = new HashSet<String>(dbHost.keySet());
		intersect.retainAll(dbUser.keySet());
		intersect.retainAll(dbPassword.keySet());
		return intersect;
	}
	
	public boolean isDblogError() {
		return isDblogError(currentDataSource);
	}

	public boolean isDblogError(String dataSourceName) {
		if (DblogError.containsKey(dataSourceName))
			return DblogError.get(dataSourceName);
		else
			return true;
	}
	
	public void setDblogError(String dblogError) {
		setDblogError(currentDataSource,dblogError);
	}
	
	public void setDblogError(String dataSourceName, String dblogError) {
		DblogError.put(dataSourceName, Boolean.parseBoolean(dblogError));
	}
	
	public String getDbConnectionURL() {
		return getDbConnectionURL(currentDataSource);
	}

	public String getDbConnectionURL(String dataSourceName) {
		return DbConnectionURL.get(dataSourceName);
	}
	
	public void setDbConnectionURL(String dbConnectionURL) {
		setDbConnectionURL(currentDataSource, dbConnectionURL);
	}

	public void setDbConnectionURL(String dataSourceName, String dbConnectionURL) {
		DbConnectionURL.put(dataSourceName, dbConnectionURL);
	}
	
	public String getDbDriver() {
		return getDbDriver(currentDataSource);
	}
	
	public String getDbDriver(String dataSourceName) {
		return DbDriver.get(dataSourceName);
	}

	public void setDbDriver(String dbDriver) {
		setDbDriver(currentDataSource, dbDriver);
	}

	public void setDbDriver(String dataSourceName, String dbDriver) {
		this.DbDriver.put(dataSourceName, dbDriver);
	}
	
	public String getDbUser() {
		return getDbUser(currentDataSource);
	}
	
	public String getDbUser(String dataSourceName) {
		return dbUser.get(dataSourceName);
	}

	public void setDbUser(String dbUser) {
		setDbUser(currentDataSource, dbUser);
	}
	
	public void setDbUser(String dataSourceName, String dbUser) {
		this.dbUser.put(dataSourceName, dbUser);
	}

	public String getDbPassword() {
		return getDbPassword(currentDataSource);
	}

	public String getDbPassword(String dataSourceName) {
		return dbPassword.get(dataSourceName);
	}
	
	public void setDbPassword(String dbPassword) {
		setDbPassword(currentDataSource, dbPassword);
	}

	public void setDbPassword(String dataSourceName, String dbPassword) {
		this.dbPassword.put(dataSourceName, dbPassword);
	}
	
	public String getDbHost() {
		return getDbHost(currentDataSource);
	}

	public String getDbHost(String dataSourceName) {
		return dbHost.get(dataSourceName);
	}
	
	public void setDbHost(String dbHost) {
		setDbHost(currentDataSource, dbHost);
	}

	public void setDbHost(String dataSourceName, String dbHost) {
		this.dbHost.put(dataSourceName, dbHost);
	}
	
	public String getDbSchema() {
		return getDbSchema(currentDataSource);
	}
	
	public String getDbSchema(String dataSourceName) {
		return dbSchema.get(dataSourceName);
	}

	public void setDbSchema(String dbSchema) {
		setDbSchema(currentDataSource, dbSchema);;
	}
	
	public void setDbSchema(String dataSourceName, String dbSchema) {
		this.dbSchema.put(dataSourceName, dbSchema);
	}
	
	public String getDbPrefix() {
		return getDbPrefix(currentDataSource);
	}

	public String getDbPrefix(String dataSourceName) {
		if(dbPrefix.containsKey(dataSourceName))
			return dbPrefix.get(dataSourceName);
		else
			return "";
	}
	
	public void setDbPrefix(String dbPrefix) {
		setDbPrefix(currentDataSource, dbPrefix);
	}

	public void setDbPrefix(String dataSourceName, String dbPrefix) {
		if (dbPrefix == null)
			this.dbPrefix.put(dataSourceName, "");
		else
			this.dbPrefix.put(dataSourceName, dbPrefix);
	}
	
	public String getReportBuilderClass() {
		return reportBuilderClass;
	}

	public void setReportBuilderClass(String reportBuilderClass) {
		this.reportBuilderClass = reportBuilderClass;
	}

	public String[] getReportEmails() {
		if (reportEmails == null)
			return null;
		return reportEmails.split(",");
	}

	public String getReportEmailsAsString() {
		if (reportEmails == null)
			return null;
		return reportEmails;
	}
	
	public void setReportEmails(String reportEmails) {
		this.reportEmails = reportEmails;
	}

	public String getReportFormat() {
		return reportFormat;
	}

	public void setReportFormat(String reportFormat) {
		this.reportFormat = reportFormat;
	}

	public boolean isEnableProxy() {
		return enableProxy;
	}

	public void setEnableProxy(String enableProxy) {
		this.enableProxy = Boolean.parseBoolean(enableProxy);
	}
	
	public boolean isProxyAuthRequired() {
		return isProxyAuthRequired;
	}

	public void setProxyAuthRequired(String isProxyAuthRequired) {
		this.isProxyAuthRequired = Boolean.parseBoolean(isProxyAuthRequired);
	}

	public String getProxyHost() {
		return proxyHost;
	}

	public void setProxyHost(String proxyHost) {
		this.proxyHost = proxyHost;
	}

	public int getProxyPort() {
		return Integer.parseInt(proxyPort);
	}

	public void setProxyPort(String proxyPort) {
		this.proxyPort = proxyPort;
	}

	public String getProxyUser() {
		return proxyUser;
	}

	public void setProxyUser(String proxyUser) {
		this.proxyUser = proxyUser;
	}

	public String getProxyPassword() {
		return proxyPassword;
	}

	public void setProxyPassword(String proxyPassword) {
		this.proxyPassword = proxyPassword;
	}

	public String getSfUser() {
		return sfUser;
	}

	public void setSfUser(String sfUser) {
		this.sfUser = sfUser;
	}

	public String getSfPassword() {
		return sfPassword;
	}

	public void setSfPassword(String sfPassword) {
		this.sfPassword = sfPassword;
	}

	public String getSfToken() {
		return sfToken;
	}

	public void setSfToken(String sfToken) {
		this.sfToken = sfToken;
	}

	public String getSfEndpoint() {
		return sfEndpoint;
	}

	public void setSfEndpoint(String sfEndpoint) {
		this.sfEndpoint = sfEndpoint;
	}

	public String getSqlPath() {
		return sqlPath;
	}

	public void setSqlPath(String sqlPath) {
		this.sqlPath = sqlPath;
	}

	public String getSqlTablefile() {
		return sqlTablefile;
	}

	public void setSqlTablefile(String sqlTablefile) {
		this.sqlTablefile = sqlTablefile;
	}

	public String getSqlRelationfile() {
		return sqlRelationfile;
	}

	public void setSqlRelationfile(String sqlRelationfile) {
		this.sqlRelationfile = sqlRelationfile;
	}

	public boolean isCreateLocalSqlfiles() {
		return createLocalSqlfiles;
	}

	public void setCreateLocalSqlfiles(String createLocalSqlfiles) {
		this.createLocalSqlfiles = Boolean.parseBoolean(createLocalSqlfiles);
	}

	public boolean isCreateLocalTables() {
		return createLocalTables;
	}

	public void setCreateLocalTables(String createLocalTables) {
		this.createLocalTables = Boolean.parseBoolean(createLocalTables);
	}

	public boolean isDropIfTableExists() {
		return dropIfTableExists;
	}

	public void setDropIfTableExists(String dropIfTableExists) {
		this.dropIfTableExists = Boolean.parseBoolean(dropIfTableExists);
	}

	public boolean isPopulateDb() {
		return populateDb;
	}

	public void setPopulateDb(String populateDb) {
		this.populateDb = Boolean.parseBoolean(populateDb);
	}
	
	public static Logger getLogger() {
		return logger;
	}

	public String getMail_transport_protocol() {
		return mail_transport_protocol;
	}

	public void setMail_transport_protocol(String mail_transport_protocol) {
		this.mail_transport_protocol = mail_transport_protocol;
	}

	public String getMail_smtp_starttls_enable() {
		return mail_smtp_starttls_enable;
	}

	public void setMail_smtp_starttls_enable(String mail_smtp_starttls_enable) {
		this.mail_smtp_starttls_enable = mail_smtp_starttls_enable;
	}

	public String getMail_smtp_host() {
		return mail_smtp_host;
	}

	public void setMail_smtp_host(String mail_smtp_host) {
		this.mail_smtp_host = mail_smtp_host;
	}

	public String getMail_smtp_port() {
		return mail_smtp_port;
	}

	public void setMail_smtp_port(String mail_smtp_port) {
		this.mail_smtp_port = mail_smtp_port;
	}

	public String getMail_smtp_auth() {
		return mail_smtp_auth;
	}

	public void setMail_smtp_auth(String mail_smtp_auth) {
		this.mail_smtp_auth = mail_smtp_auth;
	}

	public String getMail_smtp_user() {
		return mail_smtp_user;
	}

	public void setMail_smtp_user(String mail_smtp_user) {
		this.mail_smtp_user = mail_smtp_user;
	}

	public String getMail_smtp_password() {
		return mail_smtp_password;
	}

	public void setMail_smtp_password(String mail_smtp_password) {
		this.mail_smtp_password = mail_smtp_password;
	}

	public String getMail_smtp_from() {
		return mail_smtp_from;
	}

	public void setMail_smtp_from(String mail_smtp_from) {
		this.mail_smtp_from = mail_smtp_from;
	}

	public String getMail_smtp_log_error_to() {
		return mail_smtp_log_error_to;
	}

	public void setMail_smtp_log_error_to(String mail_smtp_log_error_to) {
		this.mail_smtp_log_error_to = mail_smtp_log_error_to;
	}

	public HashMap<String, TaskProperties> getTasksProperties() {
		return taskProperties;
	}

	
	public void setTasksProperties(HashMap<String, TaskProperties> taskProperties) {
		this.taskProperties = taskProperties;
	}
	
	public void setTaskProperty(TaskProperties taskProperties) {
		this.taskProperties.put(taskProperties.getName(), taskProperties);
	}

	public String getCurrentTask() {
		return currentTask;
	}

	public void setCurrentTask(String currentTask) {
		this.currentTask = currentTask;
	}
	
	public TaskProperties getTaskProperties() {
		if (currentTask!=null)
			return taskProperties.get(currentTask);
		return null;
	}

	public String getFileName() {
		return fileName;
	}

	public void setFileName(String fileName) {
		this.fileName = fileName;
	}

	public boolean isIncludeTimeInName() {
		return includeTimeInName;
	}

	public void setIncludeTimeInName(String includeTimeInName) {
		this.includeTimeInName = Boolean.parseBoolean(includeTimeInName);
	}

	public int getSchedulingApiPort() {
		return schedulingApiPort;
	}

	public void setSchedulingApiPort(int schedulingApiPort) {
		this.schedulingApiPort = schedulingApiPort;
	}

	public String getReportFolder() {
		return reportFolder;
	}

	public void setReportFolder(String reportFolder) {
		this.reportFolder = reportFolder;
	}
	
	public void setSftpDetails(String sftpDetails) throws Exception {
		if ((sftpDetails != null) && (sftpDetails.split(",").length == 4)) {
			String[] details = sftpDetails.split(","); 
			this.sftpServer = details[0];
			try {
				this.sftpPort = Integer.parseInt(details[1]);
			} catch (NumberFormatException nfe) {
				// Use default port 22
				this.sftpPort = 22;
			}
			this.sftpUser = details[2];
			this.sftpPassword = details[3];
		} else {
			throw new Exception("SFTP Details are comma separated server,port,user,password");
		}
	}
	
	public String getSftpServer() {
		return sftpServer;
	}

	public int getSftpPort() {
		return sftpPort;
	}
	
	public String getSftpUser() {
		return sftpUser;
	}

	public String getSftpPassword() {
		return sftpPassword;
	}
	
	public boolean sftpReports() {
		return ((this.sftpServer != null) && (sftpUser!=null) && (sftpPassword!=null));
	}

	public int getSfReadTimeOut() {
		return sfReadTimeOut;
	}

	public void setSfReadTimeOut(int sfReadTimeOut) {
		this.sfReadTimeOut = sfReadTimeOut;
	}

	public void setSfReadTimeOut(String sfReadTimeOut) {
		this.sfReadTimeOut = Integer.parseInt(sfReadTimeOut);
	}
	
	public int getSfConnectionTimeout() {
		return sfConnectionTimeout;
	}

	public void setSfConnectionTimeout(int sfConnectionTimeout) {
		this.sfConnectionTimeout = sfConnectionTimeout;
	}
	
	public void setSfConnectionTimeout(String sfConnectionTimeout) {
		this.sfConnectionTimeout = Integer.parseInt(sfConnectionTimeout);
	}
	
}
