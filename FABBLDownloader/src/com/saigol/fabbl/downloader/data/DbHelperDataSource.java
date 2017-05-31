package com.saigol.fabbl.downloader.data;

import java.io.FileNotFoundException;
import java.io.PrintWriter;
import java.io.UnsupportedEncodingException;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;

public class DbHelperDataSource extends com.saiglobal.sf.core.data.DbHelperDataSource {
	public static String FABBL_COPY_DATASOURCE = "fabbl_copy";
	public static String FABBL_MYSQL_DATASOURCE = "fabbl_mysql";
	private static String csvFileName = "\\SAI\\tmp\\tmp_table.csv";
	
	public DbHelperDataSource(GlobalProperties cmd) throws InstantiationException, IllegalAccessException, ClassNotFoundException, SQLException {
		super(cmd);
	}
	
	public List<String> getFabblTablesToSync() throws ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException {
		List<String> tables = new ArrayList<String>();
		this.use(FABBL_MYSQL_DATASOURCE);
		ResultSet rs = this.executeSelect("select TableName from fabbl_tables where ToSync = 1 and (LastSyncDate is null or date_add(LastSyncDate, interval MinSecondsBetweenSyncs second)<utc_timestamp())", -1);
		while (rs.next()) {
			tables.add(rs.getString("TableName"));
		}
		return tables;
	}
	
	public void updateMysqlTable(String tableName) throws InstantiationException, IllegalAccessException, ClassNotFoundException, SQLException, FileNotFoundException, UnsupportedEncodingException {
		this.use(FABBL_COPY_DATASOURCE);
		ResultSet rs = this.executeSelectThreadSafe("select * from [" + tableName + "]",-1);
		PrintWriter out = new PrintWriter("\\\\" + cmd.getDbHost(FABBL_MYSQL_DATASOURCE) + csvFileName, "UTF-8");
		out.print(Utility.resultSetToCsv(rs));
		out.close();
		this.use(FABBL_MYSQL_DATASOURCE);
		this.executeStatement("TRUNCATE " + tableName);
		this.executeStatement("LOAD DATA INFILE 'C:" +  csvFileName.replace("\\", "\\\\") + "' INTO TABLE " + tableName + " "
				+ "FIELDS TERMINATED BY ',' ENCLOSED BY '\"'" 
				+ "LINES TERMINATED BY '\\r\\n' "
				+ "IGNORE 1 LINES");
	}
}
