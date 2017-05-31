package com.saiglobal.sf.downloader.sf;

import java.sql.SQLException;
import java.util.Calendar;
import java.util.List;

import org.apache.log4j.Logger;

import com.saiglobal.sf.core.utility.Utility;
import com.saiglobal.sf.downloader.data.DbHelper;
import com.sforce.soap.partner.FieldType;
import com.sforce.soap.partner.sobject.SObject;

public class SfRecord {
	
	private static final Logger logger = Logger.getLogger(SfRecord.class);
	public SfRecord() {
	}
	
	private String getUpsertScript(String dbTableName,String keys,String values,String upsert) {
		return  "INSERT INTO " + dbTableName + " (" + keys + ") VALUES (" + values + 
				") ON DUPLICATE KEY UPDATE " + upsert + ";";
	}

	public int executeUpsert(SObject sfRecord_,List<SfField> fields, String dbTableName,DbHelper dbHelper) throws InstantiationException, IllegalAccessException, ClassNotFoundException, SQLException {
		StringBuilder updateStmt = new StringBuilder();;
		String insertStmt = null;
		StringBuilder insertFields=new StringBuilder();
		StringBuilder valueFields=new StringBuilder();
		List<String> localFields;
		localFields = dbHelper.getTableFields(dbTableName);
		
		for(SfField sfField :fields) {
			if (!localFields.contains(sfField.getName())) {
				logger.debug("Skipping field " + sfField.getName() + " as not existing on local db");
				continue;
			}
			insertFields.append(sfField.getDBFieldName());
			insertFields.append(",");
			if ((sfRecord_.getField(sfField.getName()) == null) || (sfField.getField_().getType().equals(FieldType.address))) {
				valueFields.append("null");
				valueFields.append(",");
			} else {
				String val = null;
				Object valObj = sfRecord_.getField(sfField.getName());
				if (valObj instanceof Calendar)
					val = Utility.getMysqldateformat().format(((Calendar)valObj).getTime());
				else
					val = valObj.toString();
				valueFields.append(sfField.convertToMySql(val) + ",");
			}
			updateStmt.append(sfField.getUpsertScript());
		}
		insertFields = Utility.removeLastChar(insertFields);
		valueFields  = Utility.removeLastChar(valueFields);
		updateStmt   = Utility.removeLastChar(updateStmt);
		try {
			insertStmt = getUpsertScript(dbTableName,insertFields.toString(),valueFields.toString(),updateStmt.toString());
			//logger.info(insertStmt);
			return dbHelper.executeStatement(insertStmt);
		} catch(SQLException ex) {
			logger.error("Error occurred during UPSERT",ex);
			dbHelper.LogError(dbTableName, Utility.addSlashes(insertStmt));
			return -1;
			//throw ex;
		} catch(InstantiationException ex) {
			logger.error("Error occurred during UPSERT",ex);
			dbHelper.LogError(dbTableName, Utility.addSlashes(insertStmt));
			throw ex;
		} catch(IllegalAccessException ex) {
			logger.error("Error occurred during UPSERT",ex);
			dbHelper.LogError(dbTableName, Utility.addSlashes(insertStmt));
			throw ex;
		} catch(ClassNotFoundException ex) {
			logger.error("Error occurred during UPSERT",ex);
			dbHelper.LogError(dbTableName, Utility.addSlashes(insertStmt));
			throw ex;
		}
	}

}
