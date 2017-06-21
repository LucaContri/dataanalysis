package com.saiglobal.sice.downloader.implementation;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.text.ParseException;
import java.util.Comparator;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.stream.Collectors;

import com.saiglobal.sf.core.utility.Utility;

public class SICERecord {
	private List<SICEField> fields;
	private HashMap<String, Object> values;
	
	public SICERecord(ResultSet rs, List<SICEField> fields) throws SQLException, ParseException {
		this.fields = fields;
		this.values = new HashMap<String, Object>();
		for (SICEField field : fields) {
			switch(field.getSqlType()) {
			case Types.BIT:
			case Types.BINARY:
			case Types.BOOLEAN:
				this.values.put(field.getName(), rs.getBoolean(field.getName()));
				break;
			case Types.SMALLINT:
			case Types.TINYINT:
			case Types.INTEGER:
				this.values.put(field.getName(), rs.getInt(field.getName()));
				break;
			case Types.BIGINT:
				this.values.put(field.getName(), rs.getLong(field.getName()));
				break;
			case Types.DECIMAL:
			case Types.DOUBLE:
				this.values.put(field.getName(), rs.getDouble(field.getName()));
				break;
			case Types.NUMERIC:
				this.values.put(field.getName(), rs.getDouble(field.getName()));
				break;
			case Types.FLOAT:
			case Types.REAL:
				this.values.put(field.getName(), rs.getDouble(field.getName()));
			case Types.DATE:
				String d = rs.getString(field.getName());
				if (d==null) {
					this.values.put(field.getName(), (d==null)?null:Utility.getActivitydateformatter().parse(d));
				} else {
					this.values.put(field.getName(), (d==null)?null:Utility.getActivitydateformatter().parse(d));
				}
				break;
			case Types.TIMESTAMP:
				String d1 = rs.getString(field.getName());
				this.values.put(field.getName(), (d1==null)?null:Utility.getMysqlutcdateformat().parse(d1));
				break;
			case Types.TIME:
			case Types.VARCHAR:
			case Types.CHAR:
				this.values.put(field.getName(), rs.getString(field.getName()));
				break;			
			default:
				this.values.put(field.getName(), rs.getString(field.getName()));
			}
			
		}
	}
	
	public String toMySQLValues() {
		Comparator<SICEField> byPosition = (f1, f2) -> f1.getOrdinalPosition()-f2.getOrdinalPosition();
		return "(" 
				+ this.fields.stream()
				.sorted(byPosition)
				.map(f -> 
					(values.get(f.getName())==null)?
							"null":
							(f.getMySQLType().contains("VARCHAR") || f.getMySQLType().contains("TEXT") || f.getMySQLType().contains("BLOB")?
									("'"+values.get(f.getName()).toString().replace("\\", "\\\\").replace("'", "\\'")+"'"):
									(f.getMySQLType().contains("DATETIME")?
											("'"+Utility.getMysqldateformat().format((Date)values.get(f.getName()))+"'"):
											values.get(f.getName()).toString())))
				.collect(Collectors.joining(", "))
				+ ")";
	}
}
