package com.saiglobal.sice.downloader.implementation;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.text.ParseException;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;
import java.util.TimeZone;
import java.util.stream.Collectors;

import org.apache.log4j.Logger;

public class SICETable {
	private static final Logger logger = Logger.getLogger(SICETable.class);
	private String name, schemaName;
	private SICEDatabaseHelper dbHelper;
	private List<SICEField> fields;
	private LocalSICETable localTable;
	private boolean deleted = false;
	private boolean isNew = false;
	private int queryPage = 0; 
	private final int queryPageSize = 1000;
	
	public static SICETable getDeletedTable(LocalSICETable localTable) {
		SICETable table = new SICETable();
		table.setLocalTable(localTable);
		table.name = localTable.getName();
		table.deleted= true;
		return table;
	}
	
	private SICETable() {
		super();
	}
	
	public SICETable(SICEDatabaseHelper dbHelper, String name, String schemaName) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException, ParseException {
		this.name = name;
		this.schemaName = schemaName;
		this.dbHelper = dbHelper;
		this.localTable = dbHelper.getLocalTable(this);
		//this.createLocalIfNotExists();
	}
	
	public List<SICEField> getFields() throws ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException {
		if (fields == null) {
			fields = new ArrayList<SICEField>();
			ResultSet rs = dbHelper.getSource().executeSelect("select * from INFORMATION_SCHEMA.COLUMNS where table_name = '" + name + "' and table_schema='" + schemaName + "'", -1);
			while (rs.next()) {
				fields.add(new SICEField(rs.getString("column_name"), rs.getString("data_type"), rs.getString("column_default"), rs.getString("is_nullable").equalsIgnoreCase("YES"), rs.getInt("character_maximum_length"), rs.getInt("ordinal_position")));
			}
		}
		return fields;
	}
	
	public LocalSICETable getLocalTable() {
		return localTable;
	}

	public void setLocalTable(LocalSICETable localTable) {
		this.localTable = localTable;
	}

	public String getName() {
		return name;
	}
	
	public String getPrimaryKeyString() {
		return "";
	}
	
	public List<SICERecord> getRecords() throws ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException, ParseException {
		List<SICERecord> retValue = new ArrayList<SICERecord>();
		ResultSet rs = dbHelper.getSource().executeSelect("select * from " + schemaName + "." + this.getName() + " LIMIT " + queryPageSize + " OFFSET " + (queryPage++*queryPageSize), -1);
		while (rs.next()) {
			retValue.add(new SICERecord(rs, getFields()));
		}
		return retValue;
	} 
	
	public void dropLocal() throws ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException {
		dbHelper.getTarget().executeStatement("drop table if exists `" + name + "`;");
		logger.info("Dropped local table " + this.getLocalTable().getName());
	}
	
	public void createLocalIfNotExists() throws ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException {
		// Local create statement
		String createTable = "CREATE TABLE IF NOT EXISTS `" + this.getName() + "` (\n";
		createTable += this.getFields().stream().map(f -> "`" + f.getName() + "` " + f.getMySQLType() + " " + (f.isNullable()?"":"NOT NULL ")).collect(Collectors.joining(",\n"));
			createTable += this.getPrimaryKeyString(); //PRIMARY KEY (`code`)
			createTable += ") ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT;";
		// Execute create statement
		dbHelper.getTarget().executeStatement(createTable);
		logger.debug(createTable);
		logger.info("Created local table " + this.getName());
	}
	
	public void truncateLocal() throws ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException {
		dbHelper.getTarget().executeStatement("truncate `" + this.getLocalTable().getName() + "`;");
	}
	
	public int populateLocal() throws ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException, ParseException {
		// target insert statement
		this.queryPage = 0;
		Calendar lastSync = Calendar.getInstance(TimeZone.getTimeZone("UTC"));
		int retValue = 0;
		List<SICERecord> records = new ArrayList<SICERecord>();
		while ((records = this.getRecords()).size()>0) {
			String insert = 
					"INSERT INTO `" + this.getLocalTable().getName() + "` VALUES \n" 
					+ records.stream().map(r -> r.toMySQLValues()).collect(Collectors.joining(",\n")) 
					+ ";";
				
			// Execute create statement
			int partInsert = dbHelper.getTarget().executeStatement(insert);
			retValue += partInsert;
			logger.info("Inserted " + partInsert + " records into target table " + this.getLocalTable().getName());
		}
		this.getLocalTable().setLastSyncd(lastSync);
		
		return retValue;
	}

	public boolean isDeleted() {
		return deleted;
	}

	public boolean isNew() {
		return isNew;
	}

	public void setNew(boolean isNew) {
		this.isNew = isNew;
	}

	public boolean needSync() {
		return this.getLocalTable().isSync() && this.getLocalTable().isSyncDue();
	}
	
	
}
