package com.saiglobal.sice.downloader.implementation;

import java.sql.SQLException;
import java.text.ParseException;

import org.apache.log4j.Logger;

import com.saiglobal.sf.core.data.DbHelperDataSource;
import com.saiglobal.sf.core.utility.GlobalProperties;

public class SICEDownloader {
	private SICEDatabaseHelper dbHelper;
	private static final Logger logger = Logger.getLogger(SICEDownloader.class);
	
	public SICEDownloader(GlobalProperties gps, GlobalProperties gpt) throws InstantiationException, IllegalAccessException, ClassNotFoundException, SQLException {
		this.dbHelper = new SICEDatabaseHelper(new DbHelperDataSource(gps,"sice"), new DbHelperDataSource(gpt,"sicelocal"));
		testConnectionSource();
		testConnectionTarget();
	}
	
	private int testConnectionSource() throws InstantiationException, IllegalAccessException, ClassNotFoundException, SQLException {
		return dbHelper.getSource().executeScalarInt("select 1");
	}
	
	private int testConnectionTarget() throws InstantiationException, IllegalAccessException, ClassNotFoundException, SQLException {
		return dbHelper.getTarget().executeScalarInt("select 1");
	}
	
	public void execute() throws ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException, ParseException {
		dbHelper.createSyncTable();
		for (SICETable table : dbHelper.getTables()) {
			// Drop local if no longer existing in SICE;
			if (table.isDeleted()) {
				// Remove local
				table.dropLocal();
				dbHelper.deleteSyncRecord(table);
			} else {
				if(table.needSync()) {
					// Truncate target table;
					table.truncateLocal();
					logger.info("Truncated table " + table.getName());
					int inserted = table.populateLocal();
					dbHelper.updateSyncRecord(table);
					logger.info("Inserted " + inserted + " records into table " + table.getName());
				}
			}
		}
	}
}
