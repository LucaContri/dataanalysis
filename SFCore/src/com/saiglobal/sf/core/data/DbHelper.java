package com.saiglobal.sf.core.data;


import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.text.DateFormat;
import java.text.DecimalFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Calendar;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.stream.Collectors;

import javax.sql.rowset.CachedRowSet;

import org.apache.commons.lang.StringUtils;
import org.apache.log4j.Logger;

import com.google.code.geocoder.model.LatLng;
import com.saiglobal.sf.core.exceptions.GeoCodeApiException;
import com.saiglobal.sf.core.model.Location;
import com.saiglobal.sf.core.model.Resource;
import com.saiglobal.sf.core.model.ResourceCalendar;
import com.saiglobal.sf.core.model.ResourceCalenderException;
import com.saiglobal.sf.core.model.ResourceEvent;
import com.saiglobal.sf.core.model.ResourceEventType;
import com.saiglobal.sf.core.model.ScheduleParameters;
import com.saiglobal.sf.core.model.CompassRevenueOwnership;
import com.saiglobal.sf.core.model.SfResourceCompetencyRankType;
import com.saiglobal.sf.core.model.SfResourceType;
import com.saiglobal.sf.core.model.SfSaigOffice;
import com.saiglobal.sf.core.model.WorkItem;
import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;

public class DbHelper {

	protected static final Logger logger = Logger.getLogger(DbHelper.class);
	private static String GeocodesTableName = "Saig_geocode_cache";	
	protected GlobalProperties cmd;
	protected Connection conn = null;
	protected ResultSet rs = null;
	protected Statement st = null;
	protected List<Location> airports;
	//protected static final Pattern nonASCII = Pattern.compile("[^\\x00-\\x7f]");
	protected static final String ReportHistoryTableName = "SF_Report_History";
	protected static final String DataTableName = "sf_data";
	private static final DecimalFormat doubleFormatter = new DecimalFormat("#.##########");
	
	private static String SFErrorTableCreateSql = 
			"CREATE TABLE IF NOT EXISTS SF_Error ( Id INT AUTO_INCREMENT NOT NULL," +
			   "TableName VARCHAR(100)," +
			   "Error TEXT,"+
			   "LastModifiedDate DATETIME NOT NULL,"+
			   "PRIMARY KEY (Id)"+
			   ") ENGINE = InnoDB ROW_FORMAT = DEFAULT;";
	
	protected static String SFTableReportHistorySql = 
			"CREATE TABLE IF NOT EXISTS " + ReportHistoryTableName + " ( " +
			   "Id INT AUTO_INCREMENT NOT NULL," +
			   "ReportName VARCHAR(100), " +
			   "Date DATETIME, "+
			   "RowName VARCHAR(100), " +
			   "ColumnName VARCHAR(100), " +
			   "Value VARCHAR(1024), " +
			   "PRIMARY KEY (Id)"+
			   ") ENGINE = InnoDB ROW_FORMAT = DEFAULT;";
	
	protected static String getSFTableReportHistorySql() {
		return SFTableReportHistorySql;
	}
	
	private static String getSFErrorTableCreateSql() {
		return SFErrorTableCreateSql;
	}
	
	public DbHelper() {
	
	}
	
	public DbHelper(GlobalProperties cmd) {
		this.cmd = cmd;
		//if (!this.validate()) {
		//	logger.error("Cannot validate database credentials");
		//}
	}
	
	protected boolean validate() {
		if(!this.testConnection())
			return false;
		
		return true;
	}
	
	public boolean testConnection() {
		try {
			logger.debug("Testing the connectivity to the local DB");
			openConnection();
			logger.debug("Successfully verified the local DB connectivity");
			return true;
		} catch (InstantiationException e) {
			logger.error("DB instantiation error", e);
			Utility.handleError(cmd, e);
		} catch (IllegalAccessException e) {
			logger.error("DB illegal Access Exception", e);
			Utility.handleError(cmd, e);
		} catch (ClassNotFoundException e) {
			logger.error("DB Class not found exception", e);
			Utility.handleError(cmd, e);
		} catch (SQLException e) {
			logger.error("SQL Exception", e);
			Utility.handleError(cmd, e);
		} catch (Exception e) {
			Utility.handleError(cmd, e);
		} finally {
			closeConnection();
		}
		return false;
	}

	public void openConnection() throws InstantiationException, IllegalAccessException, ClassNotFoundException, SQLException {
		if (!cmd.usingSalesforce()) {
			String URL = cmd.getDbConnectionURL().replaceAll("<DbHost>", cmd.getDbHost()).replaceAll("<DbSchema>", cmd.getDbSchema());
			//String URL = "jdbc:mysql://" + cmd.getDbHost() + "/" + cmd.getDbSchema()+"?jdbcCompliantTruncation=true";
			if (conn != null) {
				if (conn.isClosed()) {
					Class.forName(cmd.getDbDriver()).newInstance();
					conn = DriverManager.getConnection(URL, cmd.getDbUser(), cmd.getDbPassword());
				}
			} else {
				Class.forName(cmd.getDbDriver()).newInstance();
				conn = DriverManager.getConnection(URL, cmd.getDbUser(), cmd.getDbPassword());
			}
			logger.debug("DB Connection successfully established");
		} else {
			conn = new SFConnection(cmd);
		}
	}

	public void closeConnection() {
			if (rs != null) {
				try {
					rs.close();
				} catch (SQLException ignore) {
				}
			}
			if (st != null) {
				try {
					st.close();
				} catch (SQLException ignore) {
				}
			}
			if (conn != null) {
				try {
					conn.close();
				} catch (Exception ignore) { /* ignore close errors */
				}
			}
			logger.debug("DB Connection closed successfully");
	}
	
	public ResultSet executeSelectThreadSafe(String query, int maxRows) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException {
		Utility.startTimeCounter("executeSelect");

		Connection conni = this.getNewConnection();
		Statement sti = null;
		ResultSet rsi = null;
		logger.debug(query);
		try {
			sti = conni.createStatement();
			if (maxRows > 0) {
				sti.setMaxRows(maxRows);
			}
			Utility.startTimeCounter("executeSelect.query");
			rsi = sti.executeQuery(query);
			Utility.stopTimeCounter("executeSelect.query");
			Utility.stopTimeCounter("executeSelect");
			CachedRowSet result = new FixedCachedRowSetImpl();
			result.populate(rsi);
			return result;
		} catch (SQLException sqlEx) {
			LogError(null, Utility.addSlashes(query));
			throw sqlEx;
		} finally {
			 if (rsi != null) { 
				 try { rsi.close(); } catch (SQLException ignore) { } 
			 } 
			 if (sti != null) { 
				 try { sti.close(); } catch (SQLException ignore) { } 
			 } 
			 if (conni != null) { 
				 try { conni.close(); } catch (Exception ignore) { } 
			 } 
			 logger.debug("DB Connection closed successfully");
		}
	}
	
	public String executeScalar(String query) throws InstantiationException, IllegalAccessException, ClassNotFoundException, SQLException {
		openConnection();
		logger.debug(query);		
		try {
			st = conn.createStatement();
			st.setMaxRows(1);
			rs = st.executeQuery(query);
			if (rs.next()) {
				String retValue = rs.getString(1);;
				return retValue;
			}
		} catch (SQLException sqlEx){
			LogError(null, Utility.addSlashes(query));
			throw sqlEx;
		} finally {
			closeConnection();
		}
		return null;
	}
	
	public int executeScalarInt(String query) throws InstantiationException, IllegalAccessException, ClassNotFoundException, SQLException {
		openConnection();
		logger.debug(query);		
		try {
			st = conn.createStatement();
			st.setMaxRows(1);
			rs = st.executeQuery(query);
			if (rs.next()) {
				int retValue = rs.getInt(1); 
				return retValue;
			}
		} catch (SQLException sqlEx){
			LogError(null, Utility.addSlashes(query));
			throw sqlEx;
		} finally {
			closeConnection();
		}
		return -1;
	}
	
	public int executeStatement(String query) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException {
		openConnection();
		// Removing non-ASCII
		//query = nonASCII.matcher(query).replaceAll("");
		logger.debug(query);
		try {
			Statement s = conn.createStatement();
			int count;
			count = s.executeUpdate(query);
			s.close();
			return count;
		} catch (SQLException sqlEx){
			LogError(null, Utility.addSlashes(query));
			throw sqlEx;
		} finally {
			closeConnection();
		}
	}
	
	public int executeInsert(String query) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException {
		if (cmd.usingSalesforce()) 
			throw new UnsupportedOperationException("executeStatement on com.salesforce.soap.partners");
		openConnection();
		// Removing non-ASCII
		//query = nonASCII.matcher(query).replaceAll("");
		logger.debug(query);
		try {
			Statement s = conn.createStatement();
			int last_insert_id = -1;
			s.executeUpdate(query);
			rs = s.executeQuery("select last_insert_id()");
			while (rs.next()) {
				last_insert_id = rs.getInt(1);
			}
			s.close();
			return last_insert_id;
		} catch (SQLException sqlEx){
			LogError(null, Utility.addSlashes(query));
			throw sqlEx;
		} finally {
			closeConnection();
		}
	}

	public Connection getNewConnection() throws InstantiationException, IllegalAccessException, ClassNotFoundException, SQLException {
		Connection conn;
		if (!cmd.usingSalesforce()) {
			String URL = cmd.getDbConnectionURL().replaceAll("<DbHost>", cmd.getDbHost()).replaceAll("<DbSchema>", cmd.getDbSchema());
			Class.forName("com.mysql.jdbc.Driver").newInstance();
			conn = DriverManager.getConnection(URL, cmd.getDbUser(), cmd.getDbPassword());
			logger.debug("DB Connection successfully established");
		} else {
			conn = new SFConnection(cmd);
		}
		return conn;
	}
	
	public Connection getConnection() throws InstantiationException, IllegalAccessException, ClassNotFoundException, SQLException {
		openConnection();
		return conn;
	}
	
	public ResultSet executeSelect(String query, int maxRows) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException  {
		Utility.startTimeCounter("executeSelect");
		
		openConnection();
		logger.debug(query);
		try {
			st = conn.createStatement();
			if (maxRows > 0) {
				st.setMaxRows(maxRows);
			}
			Utility.startTimeCounter("executeSelect.query");
			rs = st.executeQuery(query);
			Utility.stopTimeCounter("executeSelect.query");
			Utility.stopTimeCounter("executeSelect");
			//CachedRowSet result = new CachedRowSetImpl();
			//result.populate(rs);
			return rs;
		} catch (SQLException sqlEx){
			LogError(null, Utility.addSlashes(query));
			throw sqlEx;
		} finally {
			//closeConnection();
		}
	}
	


	public String getWhereClause(List<String> whereClauseList) {
		String whereClause = "";
		boolean first = true;
		for (String aWhereClause : whereClauseList) {
			if ((aWhereClause!=null) && (aWhereClause != "")) {
				if (first) {
					whereClause = " WHERE " + aWhereClause;
					first = false;
				} else {
					whereClause += " AND " + aWhereClause;
				}
			}
		}
		whereClause += " ";
		return whereClause;
	}
	
	public String getDBTableName(String sfTableName) {
		if (sfTableName.startsWith("`")) {
			return this.cmd.getDbPrefix() + sfTableName;
		} else {
			return "`" + this.cmd.getDbPrefix() + sfTableName + "`";
		}
	}

	public static String[] getKeywords() {
		String[] keywords = { "ADD", "ALL", "ALTER", "ANALYZE", "AND", "AS", "ASC", "ASENSITIVE", "AUTO_INCREMENT",
				"BDB", "BEFORE", "BERKELEYDB", "BETWEEN", "BIGINT", "BINARY", "BLOB", "BOTH", "BY", "CALL", "CASCADE",
				"CASE", "CHANGE", "CHAR", "CHARACTER", "CHECK", "COLLATE", "COLUMN", "COLUMNS", "CONDITION",
				"CONNECTION", "CONSTRAINT", "CONTINUE", "CREATE", "CROSS", "CURRENT_DATE", "CURRENT_TIME",
				"CURRENT_TIMESTAMP", "CURSOR", "DATABASE", "DATABASES", "DAY_HOUR", "DAY_MICROSECOND", "DAY_MINUTE",
				"DAY_SECOND", "DEC DECIMAL", "DECLARE", "DEFAULT", "DELAYED", "DELETE", "DESC", "DESCRIBE",
				"DETERMINISTIC", "DISTINCT", "DISTINCTROW", "DIV", "DOUBLE", "DROP", "ELSE", "ELSEIF", "ENCLOSED",
				"ESCAPED", "EXISTS", "EXIT", "EXPLAIN", "FALSE", "FETCH", "FIELDS", "FLOAT", "FOR", "FORCE", "FOREIGN",
				"FOUND", "FRAC_SECOND", "FROM", "FULLTEXT", "GRANT", "GROUP", "HAVING", "HIGH_PRIORITY",
				"HOUR_MICROSECOND", "HOUR_MINUTE", "HOUR_SECOND", "IF", "IGNORE", "IN", "INDEX", "INFILE", "INNER",
				"INNODB", "INOUT", "INSENSITIVE", "INSERT", "INT", "INTEGER", "INTERVAL", "INTO", "IO_THREAD", "IS",
				"ITERATE", "JOIN", "KEY KEYS", "KILL", "LEADING", "LEAVE", "LEFT", "LIKE", "LIMIT", "LINES", "LOAD",
				"LOCALTIME", "LOCALTIMESTAMP", "LOCK", "LONG", "LONGBLOB", "LONGTEXT", "LOOP", "LOW_PRIORITY",
				"MASTER_SERVER_ID", "MATCH", "MEDIUMBLOB", "MEDIUMINT", "MEDIUMTEXT", "MIDDLEINT",
				"MINUTE_MICROSECOND", "MINUTE_SECOND", "MOD", "NATURAL", "NOT", "NO_WRITE_TO_BINLOG", "NULL",
				"NUMERIC", "ON", "OPTIMIZE", "OPTION", "OPTIONALLY", "OR", "ORDER", "OUT", "OUTER", "OUTFILE",
				"PRECISION", "PRIMARY", "PRIVILEGES", "PROCEDURE", "PURGE", "READ", "REAL", "REFERENCES", "REGEXP",
				"RENAME", "REPEAT", "REPLACE", "REQUIRE", "RESTRICT", "RETURN", "REVOKE", "RIGHT", "RLIKE",
				"SECOND_MICROSECOND", "SELECT", "SENSITIVE", "SEPARATOR", "SET", "SHOW", "SMALLINT", "SOME", "SONAME",
				"SPATIAL", "SPECIFIC", "SQL", "SQLEXCEPTION", "SQLSTATE", "SQLWARNING", "SQL_BIG_RESULT",
				"SQL_CALC_FOUND_ROWS", "SQL_SMALL_RESULT", "SQL_TSI_DAY", "SQL_TSI_FRAC_SECOND", "SQL_TSI_HOUR",
				"SQL_TSI_MINUTE", "SQL_TSI_MONTH", "SQL_TSI_QUARTER", "SQL_TSI_SECOND", "SQL_TSI_WEEK", "SQL_TSI_YEAR",
				"SSL", "STARTING", "STRAIGHT_JOIN", "STRIPED", "TABLE", "TABLES", "TERMINATED", "THEN", "TIMESTAMPADD",
				"TIMESTAMPDIFF", "TINYBLOB", "TINYINT", "TINYTEXT", "TO", "TRAILING", "TRUE", "UNDO", "UNION",
				"UNIQUE", "UNLOCK", "UNSIGNED", "UPDATE", "USAGE", "USE", "USER_RESOURCES", "USING UTC_DATE",
				"UTC_TIME", "UTC_TIMESTAMP", "VALUES", "VARBINARY", "VARCHAR", "VARCHARACTER", "VARYING", "WHEN",
				"WHERE", "WHILE", "WITH", "WRITE", "XOR", "YEAR_MONTH", "ZEROFILL" };
		return keywords;
	}

	public void LogError(String tableName,String msg) {
		if (!cmd.isDblogError())
			return;
		if (tableName == null)
			tableName="";
		if (msg == null)
			msg="";
		try {
			executeStatement(getSFErrorTableCreateSql());
			String str = "INSERT INTO SF_Error (TableName,Error,LastModifiedDate) VALUES (?, ?, ?)";
			PreparedStatement query = getConnection().prepareStatement(str);
			query.setString(1, tableName);
			query.setString(2, msg);
			query.setDate(3, new java.sql.Date(new Date().getTime()));
			query.executeUpdate();
			
			//String query = "INSERT INTO SF_Error (TableName,Error,LastModifiedDate) VALUES('" + tableName + "','" + msg + "', now());";
			//executeStatement(query);
		} catch (Exception e) {
			logger.error("Error in loggin an error", e);
		}
	}
	
	protected List<Location> loadAirports() throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException {
		List<Location> airports = new ArrayList<Location>(); 
		ResultSet rs = executeSelectThreadSafe("SELECT DestinationAirport, AirportName, Latitude, Longitude FROM " + getDBTableName("saig_travel_airports") + " group by AirportName order by AirportName", -1);
		while (rs.next()) {
			Location anAirport = new Location();
			anAirport.setCity(rs.getString("DestinationAirport"));
			anAirport.setCountry("Australia");
			anAirport.setLatitude(rs.getDouble("Latitude"));
			anAirport.setLongitude(rs.getDouble("Longitude"));
			anAirport.setName(rs.getString("AirportName"));
			airports.add(anAirport);
		}
		return airports;
	}

	public List<Location> getAirports() {
		return airports;
	}
	
	public double getFlyingTimeMin(String AirportName, SfSaigOffice office) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException {
		String officeString = office.toString();
		if (officeString=="Australia_WestMelbourne")
			officeString="Australia_Melbourne";
		ResultSet rs = executeSelectThreadSafe("SELECT FlyingTimeForwardMin, FlyingTimeReturnMin FROM " + getDBTableName("saig_travel_airports") + " WHERE Office='" + officeString + "' AND AirportName='" + AirportName + "'", -1);
		while (rs.next()) {
			return rs.getDouble("FlyingTimeReturnMin") + rs.getDouble("FlyingTimeForwardMin");
		}
		// Negative flying time if can't match the airport and office
		return -1;
	}
	
	public void storeGeocodeCached(String address, LatLng coordinates) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException {
		//Utility.startTimeCounter();
		if ((coordinates != null) && (coordinates.getLat()!=null) && (coordinates.getLng()!=null)) {
			executeStatement("INSERT INTO " + getDBTableName(getGeocodeTableName()) + " (`Address`, `Latitude`, `Longitude`) VALUES ('" + Utility.addSlashes(address) + "', " + coordinates.getLat().doubleValue() + ", " + coordinates.getLng().doubleValue() + ")");
		}
		//Utility.stopTimeCounter();
	}
	
	public LatLng getGeocodeCached(String address) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException {
		//Utility.startTimeCounter();
		ResultSet rs = executeSelectThreadSafe("SELECT Latitude, Longitude FROM " + getDBTableName(getGeocodeTableName()) + " WHERE Address='" + Utility.addSlashes(address) + "'", -1);
		while (rs.next()) {
			LatLng coordinates = new LatLng();
			coordinates.setLat(new BigDecimal(rs.getDouble("Latitude")));
			coordinates.setLng(new BigDecimal(rs.getDouble("Longitude")));
			//Utility.stopTimeCounter();
			return coordinates;
		}
		//Utility.stopTimeCounter();
		return null;
	}
	
	public String getCreateGeocodesTableSql() {
		return "CREATE TABLE IF NOT EXISTS " + getGeocodeTableName() + " ( " +
				   "Id INT AUTO_INCREMENT NOT NULL," +
				   "Address VARCHAR(255) NOT NULL, " +
				   "Latitude DOUBLE(18,10) NOT NULL, " +
				   "Longitude DOUBLE(18,10) NOT NULL, " +
				   "PRIMARY KEY (Id)"+
				   ") ENGINE = InnoDB ROW_FORMAT = DEFAULT;";
	}
	
	public String getGeocodeTableName() {
		return getDBTableName(GeocodesTableName);
	}
	
	public List<String> getWorkItemIdsBatch(ScheduleParameters parameters) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException {
		return getWorkItemIdsBatch(getWhereClause(getWhereClauseListForWorkItemsQuery(parameters)));
	}
	
	private List<String> getWhereClauseListForWorkItemsQuery(ScheduleParameters parameters) {
		List<String> whereClauseList = new ArrayList<String>();
		DateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
		whereClauseList.add("wi.IsDeleted = 0");
		
		if(parameters.getIncludeSiteIds() != null && parameters.getIncludeSiteIds().length > 0) 
			whereClauseList.add("site.Id IN ('" + StringUtils.join(parameters.getIncludeSiteIds(), "','") + "')");
		
		if(parameters.getIncludeStandardNames() != null && parameters.getIncludeStandardNames().length > 0) 
			whereClauseList.add("sp.Standard_Service_Type_Name__c IN ('" + StringUtils.join(parameters.getIncludeStandardNames(), "','") + "')");
		
		if(parameters.getSchedulingOwnership() != null && parameters.getSchedulingOwnership().length > 0) 
			whereClauseList.add("wi.Scheduling_Ownership__c IN ('" + StringUtils.join(parameters.getSchedulingOwnership(), "','") + "')");
		
		if(parameters.getExcludeStandardNames() != null && parameters.getExcludeStandardNames().length>0) 
			whereClauseList.add("sp.Standard_Service_Type_Name__c NOT IN ('" + StringUtils.join(parameters.getExcludeStandardNames(), "','") + "')");
		
		if(parameters.getIncludeCodeIds() != null && parameters.getIncludeCodeIds().length>0) 
			whereClauseList.add("code.Id IN ('" + StringUtils.join(parameters.getIncludeCodeIds(), "','") + "')");
		
		if ((parameters.getWorkItemsStatus() != null) && (parameters.getWorkItemsStatus().length>0)) 
			whereClauseList.add("wi.Status__c IN ('" + Arrays.stream(parameters.getWorkItemsStatus()).map(s -> s.getName()).collect(Collectors.joining("','")) + "')");

		if (parameters.isExludeFollowups()) 
			whereClauseList.add("wi.Work_Item_Stage__c not in ('Follow Up')");
		
		if (parameters.isExcludeOpenPendingCancellationorSuspension()) 
			whereClauseList.add("(not (wi.Status__c in ('Open') and wi.Open_Sub_Status__c in ('Pending Cancellation','Pending Suspension') and wi.Open_Sub_Status__c is not null))");

		if (parameters.getBusinessLine() != null && !parameters.getBusinessLine().equalsIgnoreCase("")) 
			whereClauseList.add("sp.Program_Business_Line__c = '" + parameters.getBusinessLine() + "'");
		
		if ((parameters.getRevenueOwnership() != null) && (parameters.getRevenueOwnership().length>0)) 
			whereClauseList.add("wi.Revenue_Ownership__c IN ('" + Arrays.stream(parameters.getRevenueOwnership()).map(ro -> ro.getName()).collect(Collectors.joining("','")) + "')");

		if ((parameters.getWiCountries() != null) && (parameters.getWiCountries().length>0)) 
			whereClauseList.add("ccs.Name IN ('" + StringUtils.join(parameters.getWiCountries(), "','") + "')");

		if (parameters.getStartDate() != null) 
			whereClauseList.add("wi.Work_Item_Date__c>='" + sdf.format(parameters.getStartDate()) + "'");

		if (parameters.getEndDate() != null) 
			whereClauseList.add("wi.Work_Item_Date__c<='" + sdf.format(parameters.getEndDate()) + "'");
		
		if ((parameters.getWorkItemIds() != null) && (parameters.getWorkItemIds().length>0)) 
			whereClauseList.add("wi.Id IN ('" + StringUtils.join(parameters.getWorkItemIds(), "','") + "')");
		
		if(parameters.getExcludeWorkItemIds() != null && parameters.getExcludeWorkItemIds().length>0) 
			whereClauseList.add("wi.Id NOT IN ('" + StringUtils.join(parameters.getExcludeWorkItemIds(), "','") + "')");
		
		if ((parameters.getWorkItemNames() != null) && (parameters.getWorkItemNames().length>0)) 
			whereClauseList.add("wi.Name IN ('" + StringUtils.join(parameters.getWorkItemNames(), "','") + "')");
		
		return whereClauseList;
	}
	
	public List<WorkItem> getWorkItemBatch(ScheduleParameters parameters) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException, GeoCodeApiException {
		return this.getWorkItembatch(getWhereClause(getWhereClauseListForWorkItemsQuery(parameters)));
	}

	protected List<String> getWorkItemIdsBatch(String whereClause) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException {
		String query = "SELECT wi.Id FROM " + getDBTableName("Work_Item__c") + " wi " + whereClause;
		ResultSet rs=this.executeSelectThreadSafe(query,-1);
		List<String> result = new ArrayList<String>();
		if (rs.last()) {
			logger.debug("Returned " + rs.getRow() + " work items");
			rs.beforeFirst();
			while (rs.next()) {
				result.add(rs.getString("wi.Id"));
			}
		}
		rs.close();
		return result;
	}
	
	protected List<WorkItem> getWorkItembatch(String whereClause) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException, GeoCodeApiException {
		
		Utility.startTimeCounter("DbHelper.getWorkItembatch");
		String query = "SELECT "
				+ "group_concat(distinct concat(contact.Name,' (',contact.Title, ' - ',contact.Email, ' - ', contact.Phone, ')')) as 'SiteContacts', "
				+ "contact.Name as 'contact_name', "
				+ "contact.Phone as 'contact_phone', "
				+ "contact.Title as 'contact_title', "
				+ "contact.Email as 'contact_email', "
				+ "wi.Id as 'wi_id', "
				+ "wi.Name as 'wi_name', "
				+ "wi.LastModifiedDate as 'wi_LastModifiedDate', "
				+ "wi.Service_Delivery_Type__c as 'wi_Service_Delivery_Type__c', "
				+ "wi.Status__c as 'wi_status__c', "
				+ "wi.Revenue_Ownership__c as 'wi_Revenue_Ownership__c', "
				+ "wi.Service_target_date__c as 'wi_Service_target_date__c', "
				+ "wi.Required_Duration__c as 'wi_Required_Duration__c', "
				+ "wi.Work_Item_Date__c as 'wi_Work_Item_Date__c', "
				+ "wi.Open_Sub_Status__c as 'wi_Open_Sub_Status__c', "
				+ "wi.Revenue_Ownership__c as 'wi_Revenue_Ownership__c', "
				+ "wi.Work_Item_Stage__c as 'wi_Work_Item_Stage__c', "
				+ " wi.Comments__c as 'wi_Comments__c', "
				+ "wp.Id as 'wp_id', "
				+ "sc.Id as 'sc_id', "
				+ "sc.Name as 'sc_name', "
				+ "us.Name as 'SchedulerName', "
				+ "sc.Preferred_Resource_1__c as 'sc_Preferred_Resource_1__c', "
				+ "sc.Preferred_Resource_2__c as 'sc_Preferred_Resource_2__c', "
				+ "sc.Preferred_Resource_3__c as 'sc_Preferred_Resource_3__c', "
				+ "sc.Operational_Ownership__c as 'sc_Operational_Ownership__c', "
				+ "client.Id as 'client_id', "
				+ "client.Name as 'client_name', "
				+ "site.Id as 'site_id', "
				+ "site.Name as 'site_name', "
				+ "site.Business_Address_1__c as 'site_Business_Address_1__c', "
				+ "site.Business_Address_2__c as 'site_Business_Address_2__c', "
				+ "site.Business_Address_3__c as 'site_Business_Address_3__c', "
				+ "site.Business_City__c as 'site_Business_City__c', "
				+ "ccs.Name as 'site_country', "
				+ "scs.Name as 'site_state', "
				+ "scs.State_Code_c__c as 'site_state_description', "
				+ "site.Business_Zip_Postal_Code__c as 'site_Business_Zip_Postal_Code__c', "
				+ "site.Latitude__c as 'site_latitude__c', "
				+ "site.Longitude__c as 'site_longitude__c', "
				+ "site.Time_Zone__c as 'site_Time_Zone__c', "
				+ "geocache.latitude as 'c_latitude', "
				+ "geocache.longitude as 'c_longitude', "
				+ "sp.Standard__c as 'PrimaryStandardId', "
				+ "sp.Standard_Service_Type_Name__c as 'PrimaryStandard', "
				+ "group_concat(distinct spf.Standard__c order by spf.Standard__c ) as 'FoSIds', "
				+ "group_concat(distinct spf.Standard_Service_Type_Name__c order by spf.Standard__c ) as 'FoS', "
				+ "group_concat(distinct code.Id order by code.Id) as 'CodesIds', "
				+ "group_concat(distinct code.name order by code.Id) as 'Codes' "
				+ "FROM `salesforce`.`Work_Item__c` wi "
				+ "INNER JOIN `salesforce`.`work_package__c` wp on wi.Work_Package__c=wp.Id "
				+ "INNER JOIN `salesforce`.`certification__c` sc on wp.Site_Certification__c=sc.Id "
				+ "INNER JOIN salesforce.site_certification_standard_program__c scsp on scsp.Site_Certification__c = sc.Id "
				+ "inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id "
				+ "left join salesforce.site_certification_standard_family__c scspf on scspf.Site_Certification_Standard__c = scsp.Id and scspf.IsDeleted = 0 "
				+ "left join salesforce.standard_program__c spf on scspf.Standard_Program__c = spf.Id "
				+ "left join salesforce.site_cert_standard_program_code__c scspc on scspc.Site_Certification_Standard_Program__c = scsp.ID and scspc.IsDeleted = 0 "
				+ "left join salesforce.code__c code on scspc.Code__c = code.Id "
				+ "INNER JOIN `salesforce`.`Account` site on sc.Primary_client__c = site.Id "
				+ "INNER JOIN `salesforce`.`Account` client on site.ParentId = client.Id "
				+ "LEFT JOIN `salesforce`.`Contact` contact on contact.AccountId = site.id "
				+ "LEFT JOIN `salesforce`.`User` us on sc.Scheduler__c=us.id "
				+ "LEFT JOIN `salesforce`.`country_code_setup__c` ccs on site.Business_Country2__c=ccs.Id "
				+ "LEFT JOIN `salesforce`.`State_Code_Setup__c` scs on site.Business_State__c=scs.Id "
				+ "LEFT JOIN salesforce.saig_geocode_cache geocache on geocache.Address = concat("
					+ "ifnull(concat(site.Business_Address_1__c,' '),''),"
					+ "ifnull(concat(site.Business_Address_2__c,' '),''),"
					+ "ifnull(concat(site.Business_Address_3__c,' '),''),"
					+ "ifnull(concat(site.Business_City__c,' '),''),"
					+ "ifnull(concat(scs.Name,' '),''),"
					+ "ifnull(concat(ccs.Name,' '),''),"
					+ "ifnull(concat(site.Business_Zip_Postal_Code__c,' '),''))"
				+ whereClause 
				+ "group by wi.id;";
		ResultSet rs=this.executeSelectThreadSafe(query,-1);
		List<WorkItem> result = new ArrayList<WorkItem>();
		if (rs.last()) {
			logger.debug("Returned " + rs.getRow() + " work items");
			rs.beforeFirst();
			while (rs.next()) {
				WorkItem aWorkItem = new WorkItem(rs, this);
				result.add(aWorkItem);
				logger.debug(aWorkItem.toString());
			}
		}
		rs.close();
		Utility.stopTimeCounter("DbHelper.getWorkItembatch");
		return result;
	}
	
	private String getResourceRankWhereClause(ScheduleParameters parameters) {
		String capabilitiesWhereClause = "";
		if ((parameters.getResourceCompetencyRanks() != null) && (parameters.getResourceCompetencyRanks().length>0)) {
			boolean first = true;
			for (SfResourceCompetencyRankType aRank : parameters.getResourceCompetencyRanks()) {
				if (first) {
					capabilitiesWhereClause += " AND (rc.Rank__c LIKE '%" + aRank.getName() + "%'";
					first = false;
				} else {
					capabilitiesWhereClause += " OR rc.Rank__c LIKE '%" + aRank.getName() + "%'";
				}
			}
			// Rank apply to standard only???
			capabilitiesWhereClause += " OR rc.Code__c IS NOT NULL)";
			
			capabilitiesWhereClause += " AND rc.IsDeleted = 0 ";
			capabilitiesWhereClause += " and rc.Status__c = 'Active' ";
		}
		return capabilitiesWhereClause;
	}
	
	private String getResourceCalendarWhereClause(ScheduleParameters parameters) {
		String calendarWhereClause = "";
		DateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
		if ((parameters.getCalendarStartDate() != null) && (parameters.getCalendarEndDate() != null)) {
			calendarWhereClause = " AND e.IsDeleted = 0 AND ((e.StartDateTime >= '" + sdf.format(parameters.getCalendarStartDate()) + "' AND e.StartDateTime <= '" + sdf.format(parameters.getCalendarEndDate()) + "') OR (e.EndDateTime >= '" + sdf.format(parameters.getCalendarStartDate()) + "' AND e.EndDateTime <= '" + sdf.format(parameters.getCalendarEndDate()) + "'))";
		}
		return calendarWhereClause;
	}
	
	private List<String> getResourceBatchWhereClauseList(ScheduleParameters parameters) {
		List<String> whereClauseList = new ArrayList<String>();
		whereClauseList.add("r.IsDeleted = 0");
		whereClauseList.add("r.Status__c = 'Active'");
		whereClauseList.add("(r.Job_Family__c like '%Auditing%' or r.Job_Family__c like '%Testing%')");
		if ((parameters.getReportingBusinessUnits() != null) && (parameters.getReportingBusinessUnits().length>0)) {
			String busiunessUnitString = "";
			boolean first = true;
			for (CompassRevenueOwnership aBusinessUnit : parameters.getReportingBusinessUnits()) {
				if (first) {
					busiunessUnitString += "'" + aBusinessUnit.getName() + "'";
					first = false;
				} else {
					busiunessUnitString += ", '" + aBusinessUnit.getName() + "'";
				}
			}
			whereClauseList.add("r.Reporting_Business_Units__c IN (" + busiunessUnitString + ")");
		}
		if ((parameters.getAuditorsCountries() != null) && (parameters.getAuditorsCountries().length>0)) {
			String auditorsCountriesString = "";
			boolean first = true;
			for (String aCountry : parameters.getAuditorsCountries()) {
				if (first) {
					auditorsCountriesString += "'" + aCountry + "'";
					first = false;
				} else {
					auditorsCountriesString += ", '" + aCountry + "'";
				}
			}
			whereClauseList.add("ccs.Name IN (" + auditorsCountriesString + ")");
		}
		if ((parameters.getResourcesStates() != null) && (parameters.getResourcesStates().length>0)) {
			String statesString = "";
			boolean first = true;
			for (String aState : parameters.getResourcesStates()) {
				if (first) {
					statesString += "'" + aState + "'";
					first = false;
				} else {
					statesString += ", '" + aState + "'";
				}
			}
			whereClauseList.add("r.Home_State_Province__c IN (" + statesString + ")");
		}
		
		if ((parameters.getResourceTypes() != null) && (parameters.getResourceTypes().length>0)) {
			String resourceTypesString = "";
			boolean first = true;
			for (SfResourceType aResourceType : parameters.getResourceTypes()) {
				if (first) {
					resourceTypesString += "'" + aResourceType.getName() + "'";
					first = false;
				} else {
					resourceTypesString += ", '" + aResourceType.getName() + "'";
				}
			}
			whereClauseList.add("r.Resource_Type__c IN (" + resourceTypesString + ")");
		}
		if ((parameters.getResourceNames() != null) && (parameters.getResourceNames().length>0)) {
			String resourceNameString = "";
			boolean first = true;
			for (String aResourceName : parameters.getResourceNames()) {
				if (first) {
					resourceNameString += "'" + aResourceName + "'";
					first = false;
				} else {
					resourceNameString += ", '" + aResourceName + "'";
				}
			}
			whereClauseList.add("r.Name IN (" + resourceNameString + ")");
		}
		if ((parameters.getResourceIds() != null) && (parameters.getResourceIds().length>0)) {
			String resourceIdsString = "";
			boolean first = true;
			for (String aResourceId : parameters.getResourceIds()) {
				if (first) {
					resourceIdsString += "'" + aResourceId + "'";
					first = false;
				} else {
					resourceIdsString += ", '" + aResourceId + "'";
				}
			}
			whereClauseList.add("r.Id IN (" + resourceIdsString + ")");
		}
		
		if ((parameters.getExcludeResourceIds() != null) && (parameters.getExcludeResourceIds().length>0)) 
			whereClauseList.add("r.Id NOT IN ('" + StringUtils.join(parameters.getExcludeResourceIds(),"', '") + "')");
		
		if ((parameters.getExcludeResourceNames() != null) && (parameters.getExcludeResourceNames().length>0)) 
			whereClauseList.add("r.Name NOT IN ('" + StringUtils.join(parameters.getExcludeResourceNames(),"', '") + "')");
		
		return whereClauseList;
	}
	
	public List<Resource> getResourceBatch(ScheduleParameters parameters) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException, ResourceCalenderException, GeoCodeApiException {	
		return this.getResourcesBatch(getWhereClause(getResourceBatchWhereClauseList(parameters)), getResourceCalendarWhereClause(parameters), getResourceRankWhereClause(parameters), parameters);
	}

	public List<String> getResourceIdsBatch(ScheduleParameters parameters) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException, ResourceCalenderException {	
		return this.getResourcesIdsBatch(getWhereClause(getResourceBatchWhereClauseList(parameters)));
	}
	
	protected List<String> getResourcesIdsBatch(String whereClause) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException, ResourceCalenderException {
		
		String query = "SELECT r.Id FROM " + getDBTableName("resource__c") + " r " + whereClause;
		ResultSet rs=this.executeSelectThreadSafe(query,-1);
		List<String> result = new ArrayList<String>();
		if (rs.last()) {
			logger.debug("Returned " + rs.getRow() + " resources ");
			rs.beforeFirst();
			while (rs.next()) {
				result.add(rs.getString("r.Id"));
			}
		}
		return result;
	}
	protected List<Resource> getResourcesBatch(String whereClause, String calendarWhereClause, String capabilitiesWhereClause, ScheduleParameters parameters) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException, ResourceCalenderException, GeoCodeApiException {
		
		String query = "(select t3.* from ( "
				+ "select t2.*, ar.value/ct.ConversionRate as 'HourlyRateAUD' from ( "
				+ "SELECT t.*, "
				+ "group_concat(e.Id order by e.Id) as 'e_Ids', "
				+ "group_concat(rt.Name order by e.Id) as 'e_RecordTypes', "
				+ "GROUP_CONCAT(convert_tz(e.StartDateTime, 'UTC', t.`u_TimeZoneSidKey` ) ORDER BY e.Id) AS 'e_StartDates',"
				+ "GROUP_CONCAT(convert_tz(e.EndDateTime, 'UTC', t.`u_TimeZoneSidKey` ) ORDER BY e.Id) AS 'e_EndDates',"
				+ "group_concat(ifnull(wi.Work_Item_Stage__c, 'NotAWorkItem') order by e.Id) as 'e_wi_stages' "
				//+ "group_concat(e.Subject order by e.Id) as 'e_Subjects' "
				+ " from ("
				+ "SELECT "
				 + "s.Name as 'ResourceCoordinatorName', "
				 + "r.Id as 'r_Id', "
				 + "r.Name as 'r_name', "
				 + "r.LastModifiedDate as 'r_LastModifiedDate', "
				 + "r.Reporting_Business_Units__c as 'r_Reporting_Business_Units__c', "
				 + "u.Id as 'u_Id', "
				 + "u.TimeZoneSidKey as 'u_TimeZoneSidKey', "
				 + "um.Name as 'um_Name', "
				 + "um.Id as 'um_Id', "
				 + "r.Resource_Type__c as 'r_Resource_Type__c', "
				 + "ifnull(r.Resource_Target_Days__c,-1) as 'r_Resource_Target_Days__c', "
				 + ((parameters.getFixedCapacity() == null)?
						"ifnull(r.Resource_Capacitiy__c,-1) ":
						"" + parameters.getFixedCapacity() + " ")
						+"as 'r_Resource_Capacitiy__c', "
				 + "r.Managing_Office__c as 'r_Managing_Office__c', "
				 + "ccs.Name as 'r_country', "
				 + "scs.Name as 'r_state', "
				 + "r.Home_Address_1__c as 'r_Home_Address_1__c', "
				 + "r.Home_Address_2__c as 'r_Home_Address_2__c', "
				 + "r.Home_Address_3__c as 'r_Home_Address_3__c', "
				 + "r.Home_City__c as 'r_Home_City__c', "
				 + "r.Home_Postcode__c as 'r_Home_Postcode__c', "
				 + "r.Latitude__c as 'r_Latitude__c', "
				 + "r.Longitude__c as 'r_Longitude__c', "
				 + "geocache.Latitude as 'c_Latitude', "
				 + "geocache.Longitude as 'c_Longitude', "
				 + "group_concat(rc.Code__c order by rc.Code__c ) as 'CodeIds', "
				 + "group_concat(if(rc.Code__c is not null, rc.Standard_or_code__c, null) order by rc.Code__c ) as 'Codes', "
				 + "GROUP_CONCAT(IF(rc.Code__c IS NOT NULL, ifnull(rc.Code_Expiry_Work_Item__c,'null'), NULL) ORDER BY rc.Code__c) AS 'CodesWorkItems', "
				 + "GROUP_CONCAT(IF(rc.Code__c IS NOT NULL, ifnull(rc.Code_Expiry_Date__c,'null'), NULL) ORDER BY rc.Code__c) AS 'CodesWorkItemsExpiry', "
				 + "group_concat(rc.Standard__c order by rc.Standard__c) as 'StandardIds', "
				 + "group_concat(if(rc.Standard__c is not null, rc.Standard_or_code__c, null) order by rc.Standard__c) as 'Standards', "
				 + "group_concat(if(rc.Standard__c is not null, rc.Rank__c, null) order by rc.Standard__c) as 'Ranks' "
				 + "FROM `salesforce`.`resource__c` r "
				 + "LEFT JOIN `salesforce`.`user` u on r.User__c=u.Id "
				 + "LEFT JOIN `salesforce`.`user` um on u.ManagerId=um.Id "
				 + "LEFT JOIN `salesforce`.`user` s on r.Scheduler__c=s.Id "
				 + "LEFT JOIN `salesforce`.`country_code_setup__c` ccs on r.Home_Country1__c=ccs.Id "
				 + "LEFT JOIN `salesforce`.`State_Code_Setup__c` scs on r.Home_State_Province__c=scs.Id "
				 + "left join salesforce.resource_competency__c rc on rc.Resource__c = r.Id " + capabilitiesWhereClause 
				 + "left join salesforce.`Saig_geocode_cache` geocache on geocache.Address = concat("
					 + "ifnull(concat(r.Home_Address_1__c,' '),''),"
					 + "ifnull(concat(r.Home_Address_2__c,' '),''),"
					 + "ifnull(concat(r.Home_Address_3__c,' '),''),"
					 + "ifnull(concat(r.Home_City__c,' '),''),"
					 + "ifnull(concat(scs.Name,' '),''),"
					 + "ifnull(concat(ccs.Name,' '),''),"
					 + "ifnull(concat(r.Home_Postcode__c,' '),'')) "
				 + whereClause
				 + "group by r.Id) t "
				 + "LEFT JOIN salesforce.event e on e.OwnerId=t.u_Id " + (calendarWhereClause==null?"":calendarWhereClause) + " "
				 + "LEFT JOIN salesforce.recordType rt ON e.RecordTypeId = rt.Id "
				 + "LEFT JOIN salesforce.work_item_resource__c wir on e.WhatId = wir.Id "
				 + "LEFT JOIN salesforce.work_item__c wi on wir.Work_Item__c = wi.Id "
				 + "GROUP BY t.r_id ) t2 "
				 + "left join analytics.auditor_rates_2 ar on ar.`Resource Id` = t2.r_id "
				 + "left join salesforce.currencytype ct on ar.currency_iso_code = ct.IsoCode "
				 + "order by t2.r_id, field(ar.`type`, 'Actual', 'Average'), ar.`period` desc) t3 "
				 + "group by t3.r_id)";

		ResultSet rs=this.executeSelectThreadSafe(query,-1);
		HashMap<String, Resource> resourceMap = new HashMap<String, Resource>();
		if (rs.last()) {
			logger.debug("Returned " + rs.getRow() + " resources ");
			
			rs.beforeFirst();
			while (rs.next()) {
				Resource aResource = new Resource(rs, this);
				
				// Get Bop and WI assigned to resource to initialise Calendar
				ResourceCalendar resourceCalendar = new ResourceCalendar(aResource, parameters.getCalendarStartDate(), parameters.getCalendarEndDate());
				if (parameters.loadCalendar() && rs.getString("e_Ids") != null) {
					String[] eventIds = rs.getString("e_Ids").split(",");
					String[] eventStartDates = rs.getString("e_StartDates").split(",");
					String[] eventEndDates = rs.getString("e_EndDates").split(",");
					String[] eventRecordTypes = rs.getString("e_RecordTypes").split(",");
					String[] eventWorkItemTypes = rs.getString("e_wi_stages").split(",");
					int index = 0;
					for (String recordType : eventRecordTypes) {
						ResourceEvent anEvent = new ResourceEvent(eventIds[index], null, null);
						try {
							anEvent.setStartDateTime(Utility.getMysqldateformat().parse(eventStartDates[index]));
							anEvent.setEndDateTime(Utility.getMysqldateformat().parse(eventEndDates[index]));
						} catch (ParseException e) {
							anEvent.setStartDateTime(null);
							anEvent.setEndDateTime(null);
						}
						
						if (recordType.contains("Blackout")) 
							anEvent.setType(ResourceEventType.SF_BOP);
						else 
							anEvent.setType(ResourceEventType.SF_WIR);
						
						if(parameters.getEventTypes().equals(ResourceEventType.ALL) || parameters.getEventTypes().equals(anEvent.getType()))
							if (!(parameters.isExludeFollowups() && eventWorkItemTypes[index].equalsIgnoreCase("Follow Up")))
								resourceCalendar.bookFor(anEvent, false);
						index++;
					}
				}
				aResource.setCalendar(resourceCalendar);
				aResource.init(parameters);
				resourceMap.put(aResource.getId(), aResource);
			}
		}
		rs.close();

		return new ArrayList<Resource>(resourceMap.values());
	}
	
	public void addToHistory(String reportName, Calendar date, String region, String rowName, String columnName, String value) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException {
		String insert = "INSERT INTO " + getDBTableName(ReportHistoryTableName) + 
				" VALUES (null, '" + reportName + "', '" + Utility.getMysqldateformat().format(date.getTime()) + "', '" + region + "', '" + rowName + "', '" + columnName + "', '" + value + "') ";
		executeStatement(insert);
	}
	
	public void addToData(String region, String dataType, String dataSubType, String refName, Calendar refDate, double refValue, String refValurText, boolean current) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException {
		String insert = "INSERT INTO " + getDBTableName(DataTableName) + 
				" VALUES (null, now(),'" + region + "', '" + dataType + "','" + dataSubType + "','" + refName + "','" + Utility.getMysqldateformat().format(refDate.getTime()) + "', " + doubleFormatter.format(refValue) + ", '" + refValurText + "'," + (current?"1":"0") + ")";
		executeStatement(insert);
	}
}
