package com.saiglobal.sice.downloader.implementation;

import java.sql.SQLException;
import java.sql.Types;

public class SICEField {
	private String name, type, defaultValue;
	private int sqlType;
	private boolean nullable;
	private int fieldLength = 2048;
	private int ordinalPosition;
	
	public SICEField(String name, String dataType, String defaultValue, boolean nullable, int fieldLength, int ordinalPosition) throws SQLException {
		setName(name);
		setType(dataType);
		setDefaultValue(defaultValue);
		setNullable(nullable);
		setFieldLength(fieldLength);
		if(getFieldLength()==0)
			setFieldLength(256);
		setOrdinalPosition(ordinalPosition);
		
		if (this.type.equalsIgnoreCase("abstime")) {this.setSqlType(Types.TIME); return;}
		if (this.type.equalsIgnoreCase("anyarray")) {this.setSqlType(Types.ARRAY); return;}
		if (this.type.equalsIgnoreCase("ARRAY")) {this.setSqlType(Types.ARRAY); return;}
		if (this.type.equalsIgnoreCase("bigint")) {this.setSqlType(Types.BIGINT); return;}
		if (this.type.equalsIgnoreCase("boolean")) {this.setSqlType(Types.BOOLEAN); return;}
		if (this.type.equalsIgnoreCase("bytea")) {this.setSqlType(Types.BLOB); return;}
		if (this.type.equalsIgnoreCase("char")) {this.setSqlType(Types.CHAR); return;}
		if (this.type.equalsIgnoreCase("character varying")) {this.setSqlType(Types.VARCHAR); return;}
		if (this.type.equalsIgnoreCase("date")) {this.setSqlType(Types.DATE); return;}
		if (this.type.equalsIgnoreCase("inet")) {this.setSqlType(Types.VARCHAR); return;}
		if (this.type.equalsIgnoreCase("integer")) {this.setSqlType(Types.INTEGER); return;}
		if (this.type.equalsIgnoreCase("interval")) {this.setSqlType(Types.VARCHAR); return;}
		if (this.type.equalsIgnoreCase("name")) {this.setSqlType(Types.VARCHAR); return;}
		if (this.type.equalsIgnoreCase("numeric")) {this.setSqlType(Types.DECIMAL); return;}
		if (this.type.equalsIgnoreCase("oid")) {this.setSqlType(Types.VARCHAR); return;}
		if (this.type.equalsIgnoreCase("real")) {this.setSqlType(Types.REAL); return;}
		if (this.type.equalsIgnoreCase("regproc")) {this.setSqlType(Types.VARCHAR); return;}
		if (this.type.equalsIgnoreCase("smallint")) {this.setSqlType(Types.SMALLINT); return;}
		if (this.type.equalsIgnoreCase("text")) {this.setSqlType(Types.LONGVARCHAR); return;}
		if (this.type.equalsIgnoreCase("timestamp with time zone")) {this.setSqlType(Types.TIMESTAMP_WITH_TIMEZONE); return;}
		if (this.type.equalsIgnoreCase("timestamp without time zone")) {this.setSqlType(Types.TIMESTAMP); return;}
		if (this.type.equalsIgnoreCase("xid")) {this.setSqlType(Types.VARCHAR); return;}
	}
	
	public String getName() {
		return name;
	}
	public void setName(String name) {
		this.name = name;
	}
	public String getType() {
		return type;
	}
	public void setType(String type) {
		this.type = type;
	}
	public String getDefaultValue() {
		return defaultValue;
	}
	public void setDefaultValue(String defaultValue) {
		this.defaultValue = defaultValue;
	}
	public boolean isNullable() {
		return nullable;
	}
	public void setNullable(boolean nullable) {
		this.nullable = nullable;
	}
	
	public String getMySQLType() {
		String mysqlType = null;
		switch (sqlType) {
			case Types.BIT:
			case Types.BINARY:
			case Types.BOOLEAN:
				mysqlType = "BOOLEAN";
				break;
			case Types.SMALLINT:
			case Types.TINYINT:
			case Types.INTEGER:
				mysqlType = "INT(11)";
				break;
			case Types.BIGINT:
				mysqlType = "BOOLEAN";
				break;
			case Types.DECIMAL:
			case Types.DOUBLE:
				mysqlType = "DECIMAL(20,4)";
				break;
			case Types.NUMERIC:
				mysqlType = "DECIMAL(20,4)";
				break;
			case Types.FLOAT:
			case Types.REAL:
				mysqlType = "DECIMAL(20,4)";
			case Types.DATE:
			case Types.TIME:
			case Types.TIMESTAMP:
				mysqlType = "DATETIME";
				break;
			case Types.LONGVARCHAR:
				mysqlType = "TEXT";
				break;
			case Types.BLOB:
				mysqlType = "BLOB";
				break;
			case Types.VARCHAR:
			case Types.CHAR:
				mysqlType = "VARCHAR(" + fieldLength + ")";
				break;			
			default:
				mysqlType = "VARCHAR(" + fieldLength + ")";
		}
		
		return mysqlType;
	}
	
	public int getFieldLength() {
		return fieldLength;
	}
	public void setFieldLength(int fieldLength) {
		this.fieldLength = fieldLength;
	}

	public int getOrdinalPosition() {
		return ordinalPosition;
	}

	public void setOrdinalPosition(int ordinalPosition) {
		this.ordinalPosition = ordinalPosition;
	}

	public int getSqlType() {
		return sqlType;
	}

	public void setSqlType(int sqlType) {
		this.sqlType = sqlType;
	}
}
