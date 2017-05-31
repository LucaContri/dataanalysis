package com.saiglobal.sf.reporting.processor;

import com.saiglobal.sf.core.utility.dynamiccode.DynamicJavaCode;
import com.saiglobal.sf.core.utility.dynamiccode.DynamicJavaCodeInterface;

public class StandardReportFromExcelTemplate extends AbstractQueryReport {

	private String name,datasource,query,initStmt,finalStmt, javaDynamicCode;
	public StandardReportFromExcelTemplate(String name, String datasource, String query, String initStmt, String finalStmt, String javaDynamicCode) {
		this.name = name;
		this.datasource = datasource;
		this.query = query;
		this.initStmt = initStmt;
		this.finalStmt = finalStmt;
		this.javaDynamicCode = javaDynamicCode;
		
		setHeader(false);
	}
	
	@Override
	protected void setCurrentDataSource() {
		this.gp.setCurrentDataSource(datasource);
	}
	
	@Override
	protected String getQuery() {
		return query;
	}

	@Override
	protected String getReportName() {
		return name;
	}
	
	@Override
	protected DynamicJavaCodeInterface getJavaPostProcessor() throws Exception {
		if (getJavaDynamicCode() != null && !getJavaDynamicCode().equalsIgnoreCase("")) {
			logger.debug("Using Java post processor:");
			logger.debug(getJavaDynamicCode());
			String pointerStart = "public class ";
			String pointerEnd = " implements";
			String className = getReportName().replace(" ", "_").replace("/", "_").replace("\\", "_") + "_Dynamic_Code";
			String orgcClassName = getJavaDynamicCode().substring(
						getJavaDynamicCode().indexOf(pointerStart) + pointerStart.length(),
						getJavaDynamicCode().indexOf(pointerEnd)
					);
			String code = getJavaDynamicCode().replaceFirst(orgcClassName, className);
			return DynamicJavaCode.getDynamicJavaCodeImplementation(code, className);
		}
		return null;
	}
	
	@Override
	protected void initialiseQuery() throws Throwable {
		if (this.initStmt != null) {
			for (String subStatement : this.initStmt.split(";")) {
				if(!subStatement.equalsIgnoreCase("")) {
					st.execute(subStatement);
					logger.info("Executing: " + subStatement);
				}
			}
		}
	}
	
	@Override
	protected void finaliseQuery() throws Throwable {
		if (this.finalStmt != null) {
			for (String subStatement : this.finalStmt.split(";")) {
				if(!subStatement.equalsIgnoreCase("")) {
					st.execute(subStatement);
					logger.info("Executing: " + subStatement);
				}
			}
		}
	}

	public String getInitStmt() {
		return initStmt;
	}

	public void setInitStmt(String initStmt) {
		this.initStmt = initStmt;
	}

	public String getFinalStmt() {
		return finalStmt;
	}

	public void setFinalStmt(String finalStmt) {
		this.finalStmt = finalStmt;
	}

	public String getJavaDynamicCode() {
		return javaDynamicCode;
	}

	public void setJavaDynamicCode(String javaDynamicCode) {
		this.javaDynamicCode = javaDynamicCode;
	}
}
