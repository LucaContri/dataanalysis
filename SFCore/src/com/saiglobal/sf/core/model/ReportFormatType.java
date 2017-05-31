package com.saiglobal.sf.core.model;

public enum ReportFormatType {
	CSV("csv","csv"),
	EXCEL("xlsx","xlsx"),
	JPG("jpg","jpg"),
	PDF("pdf","pdf"),
	EXCELTEMPLATE("xlsxTemplate", "xlsx"),
	EXCELTEMPLATEWITHSQL("xlsxTemplateWithSql", "xlsx");
		
	private String name;
	private String ext;
	
	ReportFormatType(String aName, String ext) {
		this.name = aName;
		this.ext = ext;
	}
	
	public String getName() {
		return name;
	}
	
	public String getExtension() {
		return ext;
	}
	
	public static ReportFormatType getValueForName(String typeString) {
		for (ReportFormatType aType : ReportFormatType.values()) {
			if (aType.getName().equals(typeString))
				return aType;
		}
		return null;
	}
}
