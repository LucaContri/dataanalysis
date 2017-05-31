package com.saiglobal.sf.core.data;

import com.saiglobal.sf.core.utility.GlobalProperties;

public class DbHelperDataSource extends DbHelper {
	public static final String defaultDataSourceName = "compass";

	public DbHelperDataSource(GlobalProperties cmd) {
		this.cmd = cmd;
		cmd.setCurrentDataSource(defaultDataSourceName);
	}
	
	public DbHelperDataSource(GlobalProperties cmd, String dataSourceName) {
		this.cmd = cmd;
		cmd.setCurrentDataSource(dataSourceName);
	}
	
	public String getDataSourceName() {
		return cmd.getCurrentDataSource();
	}

	public void use(String dataSourceName) {
		closeConnection();
		conn = null;
		this.cmd.setCurrentDataSource(dataSourceName);
	}
}
