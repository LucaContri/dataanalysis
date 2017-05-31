package com.saiglobal.sf.reporting.processor;

import static net.sf.dynamicreports.report.builder.DynamicReports.cmp;
import static net.sf.dynamicreports.report.builder.DynamicReports.col;
import static net.sf.dynamicreports.report.builder.DynamicReports.report;
import static net.sf.dynamicreports.report.builder.DynamicReports.stl;
import static net.sf.dynamicreports.report.builder.DynamicReports.type;

import java.awt.Color;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.Statement;
import java.sql.Types;
import java.util.Calendar;
import java.util.HashMap;

import org.apache.log4j.Logger;

import net.sf.dynamicreports.jasper.builder.JasperReportBuilder;
import net.sf.dynamicreports.report.builder.style.StyleBuilder;
import net.sf.dynamicreports.report.constant.HorizontalAlignment;
import net.sf.dynamicreports.report.datasource.DRDataSource;

import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;
import com.saiglobal.sf.core.utility.dynamiccode.DynamicJavaCodeInterface;
import com.saiglobal.sf.reporting.data.DbHelper;

public abstract class AbstractQueryReport implements ReportBuilder {
	protected DbHelper db;
	protected GlobalProperties gp;
	protected String[] fields;
	protected int[] fieldTypes;
	protected boolean header = true;
	protected boolean executeStatement = false;
	protected static final Logger logger = Logger.getLogger(AbstractQueryReport.class);
	protected final Calendar reportDate = Calendar.getInstance();
	protected DRDataSource data = null;
	protected String numericPattern;
	protected int[] columnWidth = new int[0];
	protected boolean append = false;
	protected String dateTimePattern = "dd/MM/yyyy HH:mm:ss";
	protected Connection conn = null;
	protected Statement st = null;
	
	public boolean concatenatedReports() {
		return false;
	}
	
	private int getWidth(int i) {
		if ((columnWidth == null) || (i<0) || (columnWidth.length < i+1)) 
			return 100;
		
		return columnWidth[i];
		
	}
	
	@Override
	public JasperReportBuilder[] generateReports() {
		boolean dataAvailable = false;
		try {
			data.moveFirst();
			dataAvailable = data.next();
			data.moveFirst();
		} catch (Exception e) {
			// Ignore
		}
		if (isExecuteStatement() || !dataAvailable) {
			return new JasperReportBuilder[0];
		}
		JasperReportBuilder report = report();
		StyleBuilder boldStyle         = stl.style().bold();
		StyleBuilder boldCenteredStyle = stl.style(boldStyle).setHorizontalAlignment(HorizontalAlignment.CENTER);
		StyleBuilder columnTitleStyle  = stl.style(boldCenteredStyle)
                .setBorder(stl.pen1Point())
                .setBackgroundColor(Color.LIGHT_GRAY);
		
		report
		  .setColumnTitleStyle(columnTitleStyle)
		  .setIgnorePageWidth(true)
		  .setIgnorePagination(true)
		  .setSubtotalStyle(boldStyle);
		  //.highlightDetailEvenRows();
		
		for (int i=0; i<fields.length; i++) {
			try {
				switch (fieldTypes[i]) {
					case Types.BIT:
					case Types.BINARY:
					case Types.BOOLEAN:
						report.addColumn(col.column(fields[i],   fields[i],  type.booleanType() ).setFixedWidth(getWidth(i)));
						break;
					case Types.SMALLINT:
					case Types.TINYINT:
					case Types.INTEGER:
						report.addColumn(col.column(fields[i],   fields[i],  type.integerType() ).setFixedWidth(getWidth(i)));
						break;
					case Types.BIGINT:
						report.addColumn(col.column(fields[i],   fields[i],  type.longType() ).setFixedWidth(getWidth(i)));
						break;
					case Types.DECIMAL:
					case Types.DOUBLE:
						if (numericPattern != null)
							report.addColumn(col.column(fields[i],   fields[i],  type.doubleType() ).setFixedWidth(getWidth(i)).setPattern(numericPattern));
						else 
							report.addColumn(col.column(fields[i],   fields[i],  type.doubleType() ).setFixedWidth(getWidth(i)));
						break;
					case Types.NUMERIC:
						if (numericPattern != null)
							report.addColumn(col.column(fields[i],   fields[i],  type.bigDecimalType() ).setFixedWidth(getWidth(i)).setPattern(numericPattern));
						else 
							report.addColumn(col.column(fields[i],   fields[i],  type.bigDecimalType() ).setFixedWidth(getWidth(i)));
						break;
					case Types.FLOAT:
					case Types.REAL:
						if (numericPattern != null)
							report.addColumn(col.column(fields[i],   fields[i],  type.floatType() ).setFixedWidth(getWidth(i)).setPattern(numericPattern));
						else 
							report.addColumn(col.column(fields[i],   fields[i],  type.floatType() ).setFixedWidth(getWidth(i)));
						break;
					case Types.DATE:
					case Types.TIME:
					case Types.TIMESTAMP:
						report.addColumn(col.column(fields[i],   fields[i],  type.dateType() ).setFixedWidth(getWidth(i)).setPattern(dateTimePattern));
						break;
					default:
						report.addColumn(col.column(fields[i],   fields[i],  type.stringType() ).setFixedWidth(getWidth(i)));
						break;
				}
				
			} catch (Exception e) {
				logger.error(e);
			}
			
		}
		
		if (hasHeader())
			report
				.title(//shows report title
					cmp.horizontalList().add(cmp.image(getClass().getResourceAsStream("sai_logo.gif")).setFixedDimension(getLogoWidth(), getLogoHeight())),
					cmp.horizontalList().add(cmp.text(getTitle())).setFixedDimension(getLogoWidth(), 17).setStyle(boldStyle),
					cmp.horizontalList().add(cmp.text("Updated as " + Utility.getShortdatetimedisplayformat().format(reportDate.getTime()))).setFixedDimension(getLogoWidth(), 17));
		  
	
		report.setDataSource(data);
		
		return new JasperReportBuilder[] {report};
	}
	
	private int getLogoHeight() {
		double logo_width_height_ratio = 208/34;
		return (int) ((int) getLogoWidth()/logo_width_height_ratio);
	}
	private int getLogoWidth() {
		int logo_width = 208;
		if ((columnWidth == null) || (columnWidth.length == 0))
			return 200;
		int progressiveWidth = 0;
		int previousProgressiveWidth = 0;
		int i = 0;
		while ((progressiveWidth<logo_width) && (i<columnWidth.length)) {
			previousProgressiveWidth = progressiveWidth;
			progressiveWidth += columnWidth[i++];
		}
		if (progressiveWidth-logo_width<logo_width-previousProgressiveWidth)
			return progressiveWidth;
		else
			return previousProgressiveWidth;
	}
	
	public boolean hasHeader() {
		return header;
	}


	public void setHeader(boolean header) {
		this.header = header;
	}
	
	protected boolean isExecuteStatement() {
		return executeStatement;
	}

	protected void setExecuteStatement(boolean executeStatement) {
		this.executeStatement = executeStatement;
	}
	
	@Override
	public void setDb(DbHelper db) {
		this.db = db;
	}

	@Override
	public void setProperties(GlobalProperties gp) {
		this.gp = gp;
		setCurrentDataSource();
	}
	
	// Default defined in property file. Override to set alternative datasource.  Datasource needs to be defined in property file
	protected void setCurrentDataSource() {
		
	}
	
	protected DynamicJavaCodeInterface getJavaPostProcessor() throws Exception {
		return null;
	}

	protected void initialiseQuery() throws Throwable {
		
	}
	
	protected void finaliseQuery() throws Throwable {
		
	}
	
	@Override
	public void init() throws Throwable {
		try  {
			conn = db.getConnection();
			st = conn.createStatement();
			
			initialiseQuery();
			String query = getQuery();
			if ((query == null) || (query == "")) 
				return;
			if (isExecuteStatement()) {
				// Allow multiple statements ; separated
				for (String subStatement : query.split(";")) {
					st.execute(subStatement);
					logger.info("Executing: " + subStatement);
				}
				return;
			}
			conn = db.getConnection();
			st = conn.createStatement();
			logger.debug(query);
			ResultSet rs = st.executeQuery(query);
			
			if(rs != null) {
				// Init fields and types
				ResultSetMetaData rsmd = rs.getMetaData();
				fields = new String[rsmd.getColumnCount()];
				fieldTypes= new int[rsmd.getColumnCount()];
				for (int i=1; i<=fields.length; i++) {
					fields[i-1] = rsmd.getColumnLabel(i);
					fieldTypes[i-1] = rsmd.getColumnType(i);
				}
				
				DynamicJavaCodeInterface javaPostProcessor = getJavaPostProcessor();
				
				// Init data
				data = new DRDataSource(fields);
				while (rs.next()) {
					HashMap<String, Object> valuesMap = new HashMap<String, Object>();
					Object[] values = new Object[fields.length];
					for (int i=1; i<=values.length; i++) {
						if (rs.getObject(i)==null) {
							values[i-1] = null;
						} else {
							if ((fieldTypes[i-1]==Types.DOUBLE) || (fieldTypes[i-1]==Types.DECIMAL))
								values[i-1] = rs.getDouble(i);
							else
								values[i-1] = rs.getObject(i);
						}
						valuesMap.put(fields[i-1], values[i-1]);
					}
					// Java field post processing
					if(javaPostProcessor != null) {
						javaPostProcessor.execute(valuesMap);
						// Update values
						for (int i = 0; i < values.length; i++) {
							values[i] = valuesMap.get(fields[i]);
						}
					}
					data.add(values);
				}
			}
			finaliseQuery();
		} catch (Exception e) {
			throw e;
		} finally {
			if (st != null) {
				try {
					st.close();
				} catch (Exception ignore) { /* ignore close errors */
				}
			}
			if (conn != null) {
				try {
					conn.close();
				} catch (Exception ignore) { /* ignore close errors */
				}
			}
		}
	}

	@Override
	public String[] getReportNames() {
		if (isExecuteStatement())
			return new String[0];
		return new String[] {getReportName()};
	}
	
	protected abstract String getQuery();
	protected abstract String getReportName();
	
	protected String getTitle() {
		return getReportName();
	}
	
	public boolean append() {
		return append;
	}
}
