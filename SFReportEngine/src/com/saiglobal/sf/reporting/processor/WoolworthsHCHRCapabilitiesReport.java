package com.saiglobal.sf.reporting.processor;

import static net.sf.dynamicreports.report.builder.DynamicReports.cmp;
import static net.sf.dynamicreports.report.builder.DynamicReports.col;
import static net.sf.dynamicreports.report.builder.DynamicReports.report;
import static net.sf.dynamicreports.report.builder.DynamicReports.stl;
import static net.sf.dynamicreports.report.builder.DynamicReports.type;

import java.awt.Color;
import java.sql.Connection;
import java.sql.Statement;
import java.sql.Types;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;
import java.util.stream.Collectors;

import org.apache.log4j.Logger;

import net.sf.dynamicreports.jasper.builder.JasperReportBuilder;
import net.sf.dynamicreports.report.builder.style.StyleBuilder;
import net.sf.dynamicreports.report.constant.HorizontalAlignment;
import net.sf.dynamicreports.report.datasource.DRDataSource;

import com.saiglobal.sf.core.model.CompetencyType;
import com.saiglobal.sf.core.model.Resource;
import com.saiglobal.sf.core.model.ScheduleParameters;
import com.saiglobal.sf.core.model.SfWorkItemStatus;
import com.saiglobal.sf.core.model.WorkItem;
import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;
import com.saiglobal.sf.core.utility.dynamiccode.DynamicJavaCodeInterface;
import com.saiglobal.sf.reporting.data.DbHelper;

public class WoolworthsHCHRCapabilitiesReport implements ReportBuilder {
	protected DbHelper db;
	protected GlobalProperties gp;
	protected String[] fields;
	protected int[] fieldTypes;
	protected boolean header = true;
	protected boolean executeStatement = false;
	protected static final Logger logger = Logger.getLogger(WoolworthsHCHRCapabilitiesReport.class);
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
	
	private List<WorkItem> getOtherWiAtSite(String siteId, List<WorkItem> otherWis) {
		List<WorkItem> otherWiAtSite = new ArrayList<WorkItem>();
		for (WorkItem workItem : otherWis) {
			if (workItem.getClientSite().getId().equalsIgnoreCase(siteId)) {
				otherWiAtSite.add(workItem);
			}
		}
		return otherWiAtSite;
	}
	
	@Override
	public void init() throws Throwable {
		fields = new String[] {
				"Client Site", 
				"Client Site Location", 
				"HCHR Work Item Id", 
				"HCHR Work Item", 
				"HCHR Work Item Date", 
				"HCHR Work Item Period", 
				"HCHR WI Standards", 
				"HCHR WI Codes", 
				"Resource Id", 
				"Resource Name", 
				"Resource Capacity", 
				"Resource Type", 
				"Resource Location", 
				"Resource Distance", 
				"Resource Distance Group", 
				"Other Site Certs", 
				"Other WIs", 
				"Other WIs Standards",
				"Other WIs Codes",
				"Can Perform Other WIs at Site"};
		fieldTypes = new int[] {
				Types.VARCHAR, 
				Types.VARCHAR, 
				Types.VARCHAR, 
				Types.VARCHAR, 
				Types.DATE,
				Types.VARCHAR,
				Types.VARCHAR,
				Types.VARCHAR,
				Types.VARCHAR, 
				Types.VARCHAR, 
				Types.DECIMAL, 
				Types.VARCHAR, 
				Types.VARCHAR, 
				Types.DECIMAL,
				Types.DECIMAL,
				Types.VARCHAR, 
				Types.VARCHAR, 
				Types.VARCHAR,
				Types.VARCHAR,
				Types.INTEGER};
		data = new DRDataSource(fields);
		
		ScheduleParameters parameters = new ScheduleParameters();
		parameters.setIncludeCodeIds(new String[] {"a1sd0000002ALCtAAO"}); // WOW:HCHR
		Calendar startDate = Calendar.getInstance();
		startDate.set(2017, Calendar.APRIL, 1);
		Calendar endDate = Calendar.getInstance();
		endDate.set(2018, Calendar.MARCH, 31);
		parameters.setStartDate(startDate.getTime());
		parameters.setEndDate(endDate.getTime());
		parameters.setWiCountries(new String[] {"Australia"});
		parameters.setAuditorsCountries(new String[] {"Australia"});
		parameters.setWorkItemsStatus(new SfWorkItemStatus[] {
				SfWorkItemStatus.Open,
				SfWorkItemStatus.Scheduled,
				SfWorkItemStatus.ScheduledOffered,
				SfWorkItemStatus.Servicechange,
				SfWorkItemStatus.Confirmed
		});
		parameters.setExludeFollowups(true);
		//parameters.setResourceIds(new String[] {"a0nd0000007SAEaAAO"});
		//parameters.setWorkItemIds(new String[] {"a3I0W000001xxaJUAQ"});
		parameters.setLoadCalendar(false);
		
		List<WorkItem> hchrWis = db.getWorkItemBatch(parameters);
		parameters.setIncludeCodeIds(null);
		parameters.setWorkItemIds(hchrWis.stream().map(wi -> wi.getId()).toArray(s -> new String[s]));
		hchrWis = db.getWorkItemBatch(parameters);
		List<Resource> allResources = db.getResourceBatch(parameters);
		
		parameters.setWorkItemIds(null);
		parameters.setIncludeSiteIds(hchrWis.stream().map(wi -> wi.getClientSite().getId()).toArray(s -> new String[s]));
		parameters.setExcludeWorkItemIds(hchrWis.stream().map(wi -> wi.getId()).toArray(s -> new String[s]));
		List<WorkItem> otherWis = db.getWorkItemBatch(parameters);
		
		for (WorkItem hchrWi : hchrWis) {
			for (Resource resource : allResources) {
				if(resource.canPerform(hchrWi) && resource.getCapacity()>0) {
					Object[] values = new Object[fields.length];
					values[0] = hchrWi.getClientSite().getName();
					values[1] = hchrWi.getClientLocation();
					values[2] = hchrWi.getId();
					values[3] = hchrWi.getName();
					values[4] = hchrWi.getStartDate();
					values[5] = Utility.getPeriodformatter().format(hchrWi.getStartDate());
					values[6] = hchrWi.getRequiredCompetencies().stream().filter(c -> c.getType().equals(CompetencyType.STANDARD) || c.getType().equals(CompetencyType.PRIMARYSTANDARD)).map(c -> c.getCompetencyName()).collect(Collectors.joining(", "));
					values[7] = hchrWi.getRequiredCompetencies().stream().filter(c -> c.getType().equals(CompetencyType.CODE)).map(c -> c.getCompetencyName()).collect(Collectors.joining(", "));
					values[8] = resource.getId();
					values[9] = resource.getName();
					values[10] = resource.getCapacity();
					values[11] = resource.getType()==null?"":resource.getType().getName();
					values[12] = resource.getHome().getFullAddress();
					double distance = Utility.calculateDistanceKm(resource.getHome(), hchrWi.getClientSite(), db); 
					values[13] = distance;
					values[14] = Math.ceil(distance/100)*100;
					List<WorkItem> otherWisAtSite = getOtherWiAtSite(hchrWi.getClientSite().getId(), otherWis);
					values[15] = otherWisAtSite.stream().map(wi -> wi.getSiteCertification().getName()).collect(Collectors.joining(", "));
					values[16] = otherWisAtSite.stream().map(wi -> wi.getName()).collect(Collectors.joining(", "));
					values[17] = otherWisAtSite.stream().map(wi -> wi.getRequiredCompetencies().stream().filter(c -> c.getType().equals(CompetencyType.PRIMARYSTANDARD) || c.getType().equals(CompetencyType.STANDARD)).map(c -> c.getCompetencyName()).collect(Collectors.joining(", "))).collect(Collectors.joining(", "));
					values[18] = otherWisAtSite.stream().map(wi -> wi.getRequiredCompetencies().stream().filter(c -> c.getType().equals(CompetencyType.CODE)).map(c -> c.getCompetencyName()).collect(Collectors.joining(", "))).collect(Collectors.joining(", "));
					
					boolean canPerformOtherAudits = true;
					for (WorkItem otherWiAtSite : otherWisAtSite) {
						if(!resource.hasCompetencies(otherWiAtSite.getRequiredCompetencies())) {
							canPerformOtherAudits = false;
							break;
						}
					}
					values[19] = canPerformOtherAudits?1:0;
					data.add(values);
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
	
	protected String getQuery() {
		return null;
	}
	
	protected String getReportName() {
		return "Resource Planning\\Demand Supply\\Woolworths HCHR Capabilities";
	}
	
	protected String getTitle() {
		return getReportName();
	}
	
	public boolean append() {
		return append;
	}
}
