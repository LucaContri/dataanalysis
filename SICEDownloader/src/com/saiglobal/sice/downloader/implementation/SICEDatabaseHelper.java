package com.saiglobal.sice.downloader.implementation;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.text.ParseException;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;

import org.apache.log4j.Logger;

import com.saiglobal.sf.core.data.DbHelperDataSource;
import com.saiglobal.sf.core.utility.Utility;

public class SICEDatabaseHelper {
	private static final Logger logger = Logger.getLogger(SICEDatabaseHelper.class);
	private final String schemaName = "public";
	private DbHelperDataSource dbSource;
	private DbHelperDataSource dbTarget;
	private List<SICETable> tables;
	private List<LocalSICETable> localTables;
	public final String syncTable = "SICE_Tables";
	private final String syncTablereateSql = 
			"CREATE TABLE IF NOT EXISTS " + syncTable + " ( Id INT AUTO_INCREMENT NOT NULL," +
			   "TableName VARCHAR(100), " +
			   "LastSyncDate DATETIME, "+
			   "ToSync BOOLEAN NOT NULL DEFAULT 0, "
			   + "MinSecondsBetweenSyncs INT(10) UNSIGNED DEFAULT 3600, " +
			   "PRIMARY KEY (Id)"+
			   ") ENGINE = InnoDB ROW_FORMAT = DEFAULT;";
	
	public SICEDatabaseHelper(DbHelperDataSource dbSource, DbHelperDataSource dbTarget) {
		this.dbSource = dbSource;
		this.dbTarget = dbTarget;
	}
	
	
	public DbHelperDataSource getSource() {
		return dbSource;
	}


	public DbHelperDataSource getTarget() {
		return dbTarget;
	}


	public List<SICETable> getTables() throws ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException, ParseException {
		if (tables == null) {
			tables = new ArrayList<SICETable>();
			ResultSet rs = dbSource.executeSelect("select tableName from pg_catalog.pg_tables where schemaname='" + schemaName + "' order by tableName", -1);
			while (rs.next()) {
				tables.add(new SICETable(this, rs.getString("tablename"), this.schemaName));
			}
			logger.info("Retrived " + tables.size() + " table names form SICE schema " + this.schemaName);
		}
		
		return tables;
	}
	
	public SICETable getTable(String tableName) throws ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException, ParseException {
		for (SICETable table : getTables()) {
			if (table.getName().equalsIgnoreCase(tableName))
				return table;
		}
		return null;
	}
	
	public int getTableCount() throws ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException, ParseException {
		return getTables().size();
	}
	
	public List<SICETable>  getTablesToBeSynched() throws ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException, ParseException {
		List<SICETable> retValue = new ArrayList<SICETable>();
		for (SICETable table : getTables()) {
			if(table.getLocalTable().isSync())
				retValue.add(table);
		}
		return retValue;
	}
	
	private List<LocalSICETable> getLocalTables() throws ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException, ParseException {
		if(localTables == null) {
			localTables = new ArrayList<LocalSICETable>();
			ResultSet rs = dbTarget.executeSelect("SELECT *, if(date_add(LastSyncDate, interval MinSecondsBetweenSyncs second)<utc_timestamp(),true,false) as 'SyncDue' from `" + syncTable + "`", -1);
			while (rs.next()) {
				Calendar lastSync = Calendar.getInstance();
				lastSync.setTime(Utility.getMysqldateformat().parse(rs.getString("LastSyncDate")));
				localTables.add(new LocalSICETable(rs.getInt("id"), rs.getString("TableName"), lastSync, rs.getBoolean("ToSync"), rs.getBoolean("SyncDue")));
			}
		}
		return localTables;
	}
	
	public void createSyncTable() throws ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException {
		dbTarget.executeStatement(getSyncTableCreateSql());
	}
	
	public void truncateSyncTable() throws ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException {
		dbTarget.executeStatement("truncate `" + syncTable + "`;");
	}
	
	public void createSyncRecord(SICETable table) throws ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException {
		dbTarget.executeInsert("INSERT INTO `" + syncTable + "` VALUES (NULL, '" + table.getName() + "', '1970-01-01', 0, 3600)");
	}
	
	public void deleteSyncRecord(SICETable table) throws ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException {
		dbTarget.executeInsert("DELETE FROM `" + syncTable + "` WHERE Id= " + table.getLocalTable().getId());
	}
	
	public void updateSyncRecord(SICETable table) throws ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException {
		dbTarget.executeStatement("UPDATE `" + syncTable + "` set LastSyncDate = '" + Utility.getMysqlutcdateformat().format(table.getLocalTable().getLastSyncd().getTime()) + "' WHERE Id = " + table.getLocalTable().getId());
	}
	
	private String getSyncTableCreateSql() {
		return syncTablereateSql;
	}


	public LocalSICETable getLocalTable(SICETable siceTable) throws ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException, ParseException {
		if(!getLocalTables().stream().filter(t -> t.getName().equalsIgnoreCase(siceTable.getName())).findFirst().isPresent()) {
			createSyncRecord(siceTable);
			siceTable.setNew(true);
			siceTable.createLocalIfNotExists();
			localTables = null;
		}
		
		return getLocalTables().stream().filter(t -> t.getName().equalsIgnoreCase(siceTable.getName())).findFirst().get();
	}
	
}
