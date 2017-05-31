package com.saiglobal.sf.reporting.processor;

import java.sql.ResultSet;

import org.apache.log4j.Logger;

import net.sf.dynamicreports.jasper.builder.JasperReportBuilder;

import com.saiglobal.sf.core.data.DbHelperDataSource;
import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;
import com.saiglobal.sf.downloader.sf.SfHelper;
import com.saiglobal.sf.reporting.data.DbHelper;

public class DatabaseDataConsistency implements ReportBuilder {
	private DbHelperDataSource db;
	private GlobalProperties gp;
	private SfHelper sf;
	private static double diffThreashold = 0.005;
	private static final Logger logger = Logger.getLogger(DatabaseDataConsistency.class);
	
	@Override
	public JasperReportBuilder[] generateReports() {
		// Not used.  Not a real report
		return new JasperReportBuilder[0];
	}

	public boolean concatenatedReports() {
		return false;
	}
	
	@Override
	public void setDb(DbHelper db) {
		this.db = new DbHelperDataSource(this.gp, this.gp.getCurrentDataSource());
	}

	@Override
	public void setProperties(GlobalProperties gp) {
		this.gp = gp;
		gp.setSfReadTimeOut(180000);
		this.sf = new SfHelper(gp); 
	}

	@Override
	public void init() throws Exception {
		try {
			diffThreashold = Double.parseDouble(this.gp.getCustomParameter("diffThreashold"));
		} catch (Exception e) {
			// Ignore and use default
		}
		boolean emailResult = false;
		StringBuffer body = new StringBuffer();
		StringBuffer csvData = new StringBuffer();

		ResultSet rs = db.executeSelectThreadSafe("select sft.*, "
				+ "max(if(isc.TABLE_SCHEMA = '" + this.gp.getDbSchema() + "' and isc.COLUMN_NAME = 'isDeleted', true, false)) as 'HasIsDeleted',"
				+ "max(if(isc.TABLE_SCHEMA = '" + this.gp.getDbSchema() + "' and isc.COLUMN_NAME = 'isArchived', true, false)) as 'HasIsArchived' "
				+ "from sf_tables sft "
				+ "left join information_schema.COLUMNS isc on isc.table_name = sft.TableName "
				+ "WHERE sft.ToSync=1 "
				+ "group by sft.TableName;", -1);
		body.append("Local tables with record count that differs from Salesforce count of more than " + diffThreashold*100 +"%\n\n");
		csvData.append("Table,# Replica db,# Compass,% Diff\n");
		while (rs.next()) {
			int dbCount = -1;
			int sfCount = -1;
			try {
				String querydb = "select count(Id) from `" + rs.getString("TableName") + "` where 1=1" + (rs.getBoolean("HasIsDeleted")?" and IsDeleted=0":"") + (rs.getBoolean("HasIsArchived")?" and IsArchived=0":"");
				dbCount = db.executeScalarInt(querydb);
				sfCount = sf.count(rs.getString("TableName"));
				double err = ((double)Math.abs(sfCount - dbCount))/((double)sfCount);
				System.out.println(rs.getString("TableName") + "," + dbCount + "," + sfCount + "," + err);
				if (err>=diffThreashold) {
					emailResult = true;
					csvData.append(rs.getString("TableName") + "," + dbCount + "," + sfCount + "," + ((double)Math.round(err*10000))/100 + "%\n");
				}
			} catch (Exception e) {
				logger.error("Error for table " + rs.getString("TableName"), e);
				emailResult = true;
				csvData.append(rs.getString("TableName") + "," + dbCount + "," + sfCount + ",error\n");
			}
		}
		if (emailResult) {
			body.append(Utility.csvToHtmlTable(csvData.toString()));
			Utility.email(gp, this.gp.getCurrentDataSource() + " database data consistency", body.toString(), null);
		}
	}
	
	
	@Override
	public String[] getReportNames() {
		// Not used.  Not a real report
		return new String[0];
	}
	
	public boolean append() {
		return false;
	}
}
