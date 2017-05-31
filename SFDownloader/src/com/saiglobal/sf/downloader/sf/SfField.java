package com.saiglobal.sf.downloader.sf;

import com.saiglobal.sf.core.utility.Utility;
import com.sforce.soap.partner.Field;

public class SfField {

	private String Name_;
	private boolean IsPrimary_ = false;
	private Field Field_;
	private int Precision_;
	private int Length_;

	public SfField(Field field) {
		this.Field_ = field;
		this.Name_ = field.getName();
		
		if (field.getName().toLowerCase().equals("id")) {
			this.IsPrimary_ = true;
		}
		this.Precision_ = field.getPrecision();
		this.Length_ = field.getLength();
	}

	public Field getField_() {
		return Field_;
	}

	public void setField_(Field field_) {
		Field_ = field_;
	}
	
	public String getDBFieldName() {
		//if (Utilities.inArray(DBHelper.getKeywords(), this.Name_))
		//	return "`" + this.Name_ + "`";
		//else
			return "`" + this.Name_+ "`";
	}

	public String getName() {
		return Name_;
	}

	private String getDBType() {
		String dbType;
		switch (this.Field_.getType())
		{
			case id:
			case reference:
				dbType = "VARCHAR("+this.Length_+")";
				break;
			case percent:
			case _double:
			case currency:				
				dbType = "DOUBLE(" +this.Precision_+ "," + this.Field_.getScale() +")";
				break;
			case _boolean :
				dbType = "BOOLEAN";
				break;
			case base64:
				dbType = "LONGBLOB";
				break;
			case date:
				dbType = "DATE";
				break;
			case datetime:
				dbType = "DATETIME";
				break;
			case _int:
				dbType = "INT";
				break;
			case time:
				dbType = "TIME";
				break;
			case phone:
			case string:
			case textarea:
			case url:
			case email:
			case picklist:
			case multipicklist:
			case combobox:
			case encryptedstring:
				if (this.Length_ < 256){
					dbType = "TINYTEXT";
				}else if(this.Length_ >=256 && this.Length_ < 65535){
					dbType = "TEXT";
				}else {
					dbType = "LONGTEXT";
				}
				break;
			default: //calculated,
				if (this.Length_ < 256){
					dbType = "VARCHAR(" + this.Length_ + ")";
				}else if(this.Length_ >=256 && this.Length_ < 65535){
					dbType = "TEXT";
				}else {
					dbType = "LONGTEXT";
				}
				break;
				
		}
		return dbType;
	}

	private String getNullable() {
		if (!Field_.isNillable()) {
			return " NOT NULL";
		} else {
			return "";
		}
	}

	private String getPrimary() {
		if (this.IsPrimary_)
			return " PRIMARY KEY";
		else
			return "";
	}

	public String getCreateScript() {
		return "\n\t\t" + getDBFieldName() + " " + this.getDBType() + getNullable() + getPrimary() + ",";
	}

	public String getUpsertScript() {
		return " " + this.getDBFieldName() + " = VALUES(" + this.getDBFieldName() + "),";
	}
	
	public String convertToMySql(String oldVal) {
		String newValue = oldVal;
		boolean wrap = true;
		if (this.getDBType().equals("BOOLEAN")) {
			wrap = false;
			if (oldVal.toLowerCase().equals("true")) {
				newValue = "1";
			} else {
				newValue = "0";
			}
		} else if (oldVal.endsWith(".000Z")){
			newValue = oldVal.replace(".000Z", "");
		}
		newValue = Utility.addSlashes(newValue);
		if (wrap) {
			newValue = "'" + newValue + "'";
		}
		return newValue;
	}
}
