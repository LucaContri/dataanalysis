package com.saiglobal.sf.downloader.sf;

import java.io.IOException;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.GregorianCalendar;
import java.util.List;

import org.apache.log4j.Logger;

import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;
import com.saiglobal.sf.downloader.data.DbHelper;

import java.util.Date;

import com.sforce.soap.partner.ChildRelationship;
import com.sforce.soap.partner.DeletedRecord;
import com.sforce.soap.partner.DescribeGlobalSObjectResult;
import com.sforce.soap.partner.DescribeSObjectResult;
import com.sforce.soap.partner.Field;
import com.sforce.soap.partner.PartnerConnection;
import com.sforce.soap.partner.QueryResult;
import com.sforce.soap.partner.fault.ExceptionCode;
import com.sforce.soap.partner.fault.InvalidSObjectFault;
import com.sforce.soap.partner.fault.UnexpectedErrorFault;
import com.sforce.soap.partner.sobject.SObject;
import com.sforce.ws.ConnectionException;

public class SfObject {

	private String Name_;
	private List<SfField> Fields_ = new ArrayList<SfField>();
	private static final Logger logger = Logger.getLogger(SfObject.class);
	private GlobalProperties Cmd_;
	private DescribeGlobalSObjectResult DgsObject_;
	private DescribeSObjectResult DsObjectResult_;
	private PartnerConnection Connection_;
	private boolean HasLastModified_;
	private boolean HasCreatedDate_;
	private String[] SpecialObjects_;
	
	public SfObject(PartnerConnection connection,DescribeGlobalSObjectResult dgsObject,GlobalProperties cmd,String[] spo) throws ConnectionException {
		this.Connection_=connection;
		Name_=dgsObject.getName();
		this.DgsObject_=dgsObject;
		this.Cmd_ = cmd;
		this.SpecialObjects_=spo;
		DsObjectResult_ = connection.describeSObject(this.Name_);
		if (DsObjectResult_ != null) {
			Field[] fields = DsObjectResult_.getFields();
			logger.debug(this.Name_ + ":" + fields.length);
			if (fields != null) {
				for(Field field : fields){
					Fields_.add(new SfField(field));
					if (field.getName().toLowerCase().equals("lastmodifieddate")) {
						this.HasLastModified_=true;
					}
					if (field.getName().toLowerCase().equals("createddate")) {
						this.HasCreatedDate_=true;
					}
				}
			}
		}
	}
	
	/**
	 * @return the specialObject
	 */
	public boolean isSpecialObject() {
		return Utility.inArray(SpecialObjects_, this.Name_);
	}
	
	/**
	 * @return the hasLastModified_
	 */
	public boolean hasLastModifiedDate() {
		return HasLastModified_;
	}
	
	public boolean hasCreatedDate() {
		return HasCreatedDate_;
	}
	
	public String getDBTableName() {
		if ((Cmd_.getDbPrefix()==null) || (Cmd_.getDbPrefix().equalsIgnoreCase(""))) {
			//if (Utility.inArray(DbHelper.getKeywords(),this.Name_)) 
				return  "`" + this.Name_ + "`";
		}
		return Cmd_.getDbPrefix()+"`" + this.Name_ + "`";
	}
	
	public String getDBTableNameUnquoted() {
		if ((Cmd_.getDbPrefix()==null) || (Cmd_.getDbPrefix().equalsIgnoreCase(""))) {
			//if (Utility.inArray(DbHelper.getKeywords(),this.Name_)) 
				return  this.Name_;
		}
		return Cmd_.getDbPrefix()+this.Name_;
	}
	
	public String getObjectName() {
		return this.Name_;
	}
	
	public String getRelationshipScript() {
		StringBuilder relationships = new StringBuilder();
		String relationship=null;
		if (DsObjectResult_.getChildRelationships() != null)
		{
				// if multiple objects returned
				for(int i =0;i<DsObjectResult_.getChildRelationships().length;i++)
				{
					ChildRelationship cr = DsObjectResult_.getChildRelationships()[i];
					relationship = "ALTER TABLE `" + Cmd_.getDbPrefix() + cr.getChildSObject()+ "` ADD INDEX (" +cr.getField()+ ");\n";
					relationships.append(relationship);
					relationship = "ALTER TABLE " + Cmd_.getDbPrefix() + cr.getChildSObject()+ "\n";
					relationship += " ADD FOREIGN KEY (" + cr.getField() + ")";
					relationship += " REFERENCES " + Cmd_.getDbPrefix() + this.DgsObject_.getName() + " (Id);\n";
					relationships.append(relationship);
				}
		}
		return relationships.toString();
	}
	
	public void writeTableScript() throws IOException {
		Utility.writeSforceObject(getTableScript(), Cmd_);
	}
	
	public void writeRelationScript() throws IOException {
		Utility.writeSforceRelation(getRelationshipScript(), Cmd_);
	}
	
	public void updateTable(DbHelper dbHelper) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException {
		List<String> localFields = dbHelper.getTableFields(this.getDBTableName());
		// Early exit.  If object has more than 600 fields - Do not update as we can't keep it sync'd with SF
		// TODO: Test and Deploy.  Also remove fields from local Opportunity table to restart proper sync.
		if (localFields.size()>600)
			return;
		List<SfField> fieldsToBeAdded = new ArrayList<SfField>();
		for (SfField aSfField : this.Fields_) {
			if (!localFields.contains(aSfField.getName())) {
				// New field to be added
				fieldsToBeAdded.add(aSfField);
			}
		}
		if (fieldsToBeAdded.size()>0) {
			for (SfField aSfField : fieldsToBeAdded) {
				StringBuilder alterTableQuery = new StringBuilder();
				alterTableQuery.append("ALTER TABLE ");
				alterTableQuery.append(this.getDBTableName());
				alterTableQuery.append(" ADD COLUMN " + Utility.removeLastChar(aSfField.getCreateScript()));
				dbHelper.executeStatement(alterTableQuery.toString());
			}
		}
	}
	
	public void createTable(DbHelper dbHelper) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException {
		if (Cmd_.isDropIfTableExists()) {
			//dbHelper.executeStatement(getDropScript());
		}
		dbHelper.executeStatement(getTableScript());
		dbHelper.createLog(this.Name_, null,0);
		logger.debug("Table [" + this.getDBTableName() + "] created/already exists");
	}

	public void upsertSfDataIntoDB(DbHelper dbHelper, int batchSize)  {
		try {
			if (this.isSpecialObject()) {
				boolean done = false;
				this.updateTable(dbHelper);
				Date startSync = new Date();
				Utility.startTimeCounter(getDBTableName());
				boolean retry = true;
				QueryResult qr = null;
				while (retry) {
					try {
						qr=getQueryResult(getSoql(dbHelper, startSync), batchSize);
						retry = false;
					} catch (UnexpectedErrorFault ex) {
						if ((ex.getExceptionCode() == ExceptionCode.OPERATION_TOO_LARGE) || (ex.getExceptionCode() == ExceptionCode.QUERY_TIMEOUT)) {
							// Narrow down the scope by halving the timeframe.
							Date lastSync = getLastSynced(dbHelper);
							startSync.setTime((startSync.getTime() - lastSync.getTime())/2 + lastSync.getTime());
							logger.info("Excpetion " + ex.getExceptionCode().name() + " for object " + this.Name_ + ".  Narrowing down scope from: " + lastSync + " to " + startSync);
							
						}
					}  
				}
				logger.debug("Total new/modified records found is "+ qr.getSize());
				logger.debug("Now downloading data from Salesforce.com......");
				int rcds=0;
				if (qr.getSize()>0){
					SObject[] sfrecords=null;
					while(! done) {
						sfrecords = qr.getRecords();
						rcds += storeInDB(sfrecords,dbHelper);
						if (rcds % 1000 == 0) {
							logger.debug("[" + rcds + "]Records loaded into table [" + getDBTableName() + "]");
						}
						if (qr.isDone()) {
							logger.debug("Inserted all the records");
							done = true;
						} else {
							logger.debug("Getting next batch from sfdc");
							qr = getQueryMore(qr);
						}
						sfrecords=null;
					}
				}
				// Get Deleted records
				Calendar deletedFrom = new GregorianCalendar();
				Calendar deletedTo = new GregorianCalendar();
				Calendar oldestFrom = new GregorianCalendar();
				deletedFrom.setTime(getLastSynced(dbHelper));
				deletedTo.setTime(Utility.getUtcNow());
				oldestFrom = deletedTo;
				oldestFrom.add(Calendar.DAY_OF_YEAR, -29);
				if (deletedFrom.before(oldestFrom)) {
					deletedFrom = oldestFrom;
				}
				DeletedRecord[] deleted = null;
				try {
					deleted = Connection_.getDeleted(this.getDBTableNameUnquoted(), oldestFrom, deletedTo).getDeletedRecords();
				} catch (ConnectionException ce) {
					System.out.println(ce);
					if ((ce instanceof InvalidSObjectFault) && ((InvalidSObjectFault)ce).getExceptionCode().equals(ExceptionCode.INVALID_TYPE)) {
						// Ignore
					} else {
						throw ce;
					}
				}
				int deletedCount = 0;
				if (deleted != null) {
					deletedCount = deleted.length;
					logger.debug("Total deleted records found is "+ deletedCount);
					for (DeletedRecord deletedRecord : deleted) {
						String deleteStatement = "DELETE IGNORE FROM " + this.getDBTableName()+ " WHERE Id='" + deletedRecord.getId() + "'"; 
						dbHelper.executeStatement(deleteStatement); 
					}
				}
				
				this.setLastSynced(dbHelper, startSync);
				Utility.stopTimeCounter(getDBTableName());
				logger.info("Table:" + getDBTableName() + ";New/Modified:" + rcds + ";Deleted:"+deletedCount+";SyncTime:"+ Utility.getTimeCounterMS(getDBTableName()));
				Utility.resetTimeCounter(getDBTableName());
			}
			else {
				logger.debug("Ignoring the object [" + this.Name_+"] as it is not included as special object");
			}
		}catch(Exception e) {
			logger.error("Moving on with the next object",e);
		}
	}

	private QueryResult getQueryMore(QueryResult qr) throws ConnectionException {
		int retryCount = 3;
		int cnt=0;
		while(cnt < retryCount) {
			try {
				return Connection_.queryMore(qr.getQueryLocator());
			}catch(ConnectionException ex) {
				cnt++;
				logger.error("Salesforce read connection timedout retrying ..["+cnt+"]",ex);
			}
		}
		logger.error("Salesforce read connection timed-out after ["+cnt+"] retries.");
		throw new ConnectionException("Salesforce read connection timed-out");
	}

	private QueryResult getQueryResult(String query, int batchSize) throws ConnectionException {
		QueryResult qr=null;
		int retryCount = 3;
		int cnt=0;
		while(cnt < retryCount) {
			try {
				qr =Connection_.queryAll(query);
				return qr;
			}catch(ConnectionException ex) {
				logger.error(query);
				if ((ex instanceof UnexpectedErrorFault) && ((((UnexpectedErrorFault)ex).getExceptionCode() == ExceptionCode.QUERY_TOO_COMPLICATED) ||(((UnexpectedErrorFault)ex).getExceptionCode() == ExceptionCode.OPERATION_TOO_LARGE) || (((UnexpectedErrorFault)ex).getExceptionCode() == ExceptionCode.QUERY_TIMEOUT)))
					throw ex;
				cnt++;
				logger.error("Salesforce read connection timed-out retrying ..["+cnt+"]",ex);
				logger.info("Changing query batch size from " + batchSize + " to " + batchSize/2);
				batchSize = batchSize/2;
				Connection_.setQueryOptions(batchSize);
			}
		}
		logger.error("Salesforce read connection timed-out after ["+cnt+"] retries.");
		throw new ConnectionException("Salesforce read connection timed-out");
	}
	
	private String getTableScriptHeader() {
	    String header = "\n\n\n/********************************************************************" + 
				"\n          SALESFORCE.COM OBJECT " + this.Name_ + "\n*********************************************************************/" + 
    			"\n" + "\nCREATE TABLE IF NOT EXISTS `" + this.getDBTableNameUnquoted() + "` (";
	    return header;
	}
	
	private String getTableScriptFooter() {
		 return "\n\t)ENGINE=InnoDB DEFAULT CHARSET=utf8;";
	}
	
	private String getTableScript(){
		StringBuilder sb = new StringBuilder();
		sb.append(this.getTableScriptHeader());
		for(SfField field : Fields_) {
			sb.append(field.getCreateScript());
		}
		sb=Utility.removeLastChar(sb);
		sb.append(getTableScriptFooter());
		//logger.info("Create table: " + sb.toString());
		return sb.toString();
	}
	/*
	private String getLastSyncDate(DbHelper dbHelper) throws InstantiationException, IllegalAccessException, ClassNotFoundException, SQLException {
		String syncDate=null;
		String sql=null;
		sql = "SELECT LastSyncDate FROM SF_Tables WHERE TableName='" + this.getDBTableName() + "' ORDER BY LastModifiedDate Desc";
		//sql = "SELECT Id FROM "+ this.getDBTableName() + " ORDER BY Id Desc";
		syncDate=(String)dbHelper.executeScalar(sql);
		
		if (hasLastModifiedDate()) {
			sql = "SELECT LastModifiedDate FROM `" + this.getDBTableName() + "` ORDER BY LastModifiedDate Desc";
			//sql = "SELECT Id FROM "+ this.getDBTableName() + " ORDER BY Id Desc";
			syncDate=(String)dbHelper.executeScalar(sql);
			// sometime salesforce.com has multiple rows with the same last modified date. If the process got aborted in the middle of one such timestamp 
			// we need to clean that time-stamp locally and restart the same time-stamp.
			//sql = "DELETE FROM " + this.getDBTableName() + " WHERE LastModifiedDate = '" + modifiedDate + "'";
			//int del=dbHelper.executeStatement(sql);
			//if (del >0)
				//logger.info("***Deleted "+del+" rows***");
		} else if (hasCreatedDate()) {
			sql = "SELECT CreatedDate FROM `" + this.getDBTableName() + "` ORDER BY CreatedDate Desc";
			//sql = "SELECT Id FROM "+ this.getDBTableName() + " ORDER BY Id Desc";
			syncDate=(String)dbHelper.executeScalar(sql);
			// sometime salesforce.com has multiple rows with the same last modified date. If the process got aborted in the middle of one such timestamp 
			// we need to clean that timestamp locally and restart the same timestamp.
			//sql = "DELETE FROM " + this.getDBTableName() + " WHERE CreatedDate = '" + modifiedDate + "'";
			//int del=dbHelper.executeStatement(sql);
			//if (del > 0)
				//logger.info("***Deleted "+del+" rows***");
		}
		
		if (syncDate != null) {
			logger.info("Table [" + this.getDBTableName() + "] has been last modified on [" + syncDate + "]");
			syncDate = syncDate.replace(' ', 'T');
			syncDate = syncDate.replace(".0", ".000Z");
		}
		else {
			sql="TRUNCATE TABLE `" + this.getDBTableName() + "`";
			dbHelper.executeStatement(sql);
			logger.info("***[" + this.getDBTableName() + "] table Truncated***");
		}
		return syncDate;
	}
	*/
	public Date getLastSynced(DbHelper dbHelper) {
		String sql = "SELECT LastSyncDate FROM SF_Tables WHERE TableName='" + this.getDBTableNameUnquoted() + "'";
		try {
			String result = dbHelper.executeScalar(sql);
			if (result != null) {
				Date syncDate = Utility.getMysqldateformat().parse(result);
				return syncDate;
			} else {
				
				return Utility.getOrigin().getTime();
			}
		} catch (Exception e) {
			logger.error("Could not get last synched date/time for object " + this.getDBTableName() );
		}
		return null;
	}
	
	public Date getEarliestAllowedSync(DbHelper dbHelper) {
		String sql = "SELECT DATE_ADD(LastSyncDate, INTERVAL MinSecondsBetweenSyncs SECOND) as 'EarliestAllowedSync' FROM  SF_Tables WHERE TableName='" + this.getDBTableNameUnquoted() + "'";
		try {
			String result = dbHelper.executeScalar(sql);
			if (result != null) {
				Date earliestAllowedSyncDate = Utility.getMysqldateformat().parse(result);
				return earliestAllowedSyncDate;
			} else {
				return Utility.getOrigin().getTime();
			}
		} catch (Exception e) {
			logger.error("Could not get last synched date/time for object " + this.getDBTableName() );
		}
		logger.error("Returning now as Earlest Allowed Sync");
		return new Date();
	}
	
	public void setLastSynced(DbHelper dbHelper, Date lastSuccessfulSync) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException {
		String sql = "UPDATE SF_Tables SET LastSyncDate = '" + Utility.getMysqlutcdateformat().format(lastSuccessfulSync) + "' WHERE TableName='" + this.getDBTableNameUnquoted() + "'";
		dbHelper.executeStatement(sql);
	}
	
    private String getSoql(DbHelper dbHelper, Date maxDate) throws InstantiationException, IllegalAccessException, ClassNotFoundException, SQLException{
		StringBuilder sb=new StringBuilder();
		List<String> localFields = dbHelper.getTableFields(this.getDBTableName());
		sb.append("SELECT ");
		for(SfField field : Fields_){
			if (localFields.contains(field.getName())) 
				sb.append(field.getName() + ",");
		}
		Utility.removeLastChar(sb);
		sb.append(" FROM ");
		sb.append(this.getObjectName());
		sb.append(" ");
		Date syncDate = getLastSynced(dbHelper);
		logger.debug("Table [" + this.getDBTableName() + "] has been last syncd on [" + Utility.getMysqldateformat().format(syncDate) + " UTC]");
		if (this.hasLastModifiedDate()) {
			if (syncDate != null) {
				sb.append(" WHERE LastModifiedDate >= " + Utility.getSoqldateformat().format(syncDate) + "");
				sb.append(" AND LastModifiedDate <= " + Utility.getSoqldateformat().format(maxDate) + "");
			}
			sb.append(" ORDER BY LastModifiedDate ASC");
		}else if (this.hasCreatedDate()) {
			if (syncDate != null) {
				sb.append(" WHERE CreatedDate >= " + Utility.getSoqldateformat().format(syncDate) + "");
			}
			sb.append(" ORDER BY CreatedDate ASC");
		}
		logger.debug(sb.toString());
		return sb.toString();
	}
    
	private int storeInDB(SObject[] sfrecords,DbHelper dbHelper) throws SQLException, InstantiationException, IllegalAccessException, ClassNotFoundException {
		int rcds=0;
		SfRecord sfRecord;
		for(SObject sfrcd:sfrecords){
			sfRecord= new SfRecord();
			rcds += sfRecord.executeUpsert(sfrcd,this.Fields_, this.getDBTableName(),dbHelper);
			sfRecord=null;
		}
		//logger.info("[" + rcds + "]Records loaded into table [" + getDBTableName() + "]");
		return rcds;
	}

}