package com.saiglobal.sf.reporting.processor;

import static net.sf.dynamicreports.report.builder.DynamicReports.cmp;
import static net.sf.dynamicreports.report.builder.DynamicReports.col;
import static net.sf.dynamicreports.report.builder.DynamicReports.report;
import static net.sf.dynamicreports.report.builder.DynamicReports.stl;
import static net.sf.dynamicreports.report.builder.DynamicReports.type;

import java.awt.Color;
import java.sql.ResultSet;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Collections;
import java.util.Comparator;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.HashMap;
import java.util.List;
import java.util.function.Function;
import java.util.function.ToDoubleFunction;
import java.util.function.ToIntFunction;
import java.util.function.ToLongFunction;

import org.apache.log4j.Logger;

import net.sf.dynamicreports.jasper.builder.JasperReportBuilder;
import net.sf.dynamicreports.jasper.constant.JasperProperty;
import net.sf.dynamicreports.report.builder.column.TextColumnBuilder;
import net.sf.dynamicreports.report.builder.style.StyleBuilder;
import net.sf.dynamicreports.report.constant.HorizontalAlignment;
import net.sf.dynamicreports.report.datasource.DRDataSource;

import com.saiglobal.sf.core.data.DbHelper;
import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;

public class NewBusinessVsCancellationsReport implements ReportBuilder {
	
	protected DbHelper db;
	protected GlobalProperties gp;
	protected DRDataSource data = null;
	protected static final Logger logger = Logger.getLogger(NewBusinessVsCancellationsReport.class);
	protected static final SimpleDateFormat periodFormatter = new SimpleDateFormat("yyyy MM");
	protected static final SimpleDateFormat periodDisplayFormatter = new SimpleDateFormat("MMM yy");
	protected static final SimpleDateFormat daysFormatter = new SimpleDateFormat("dd");
	protected static final SimpleDateFormat activityFormatter = new SimpleDateFormat("yyyy-MM-dd");
	
	protected final Calendar reportDate;
	
	public NewBusinessVsCancellationsReport() {
		reportDate = new GregorianCalendar();
		reportDate.setTime(new Date());	
	}
	
	public boolean concatenatedReports() {
		return false;
	}
	
	@Override
	public JasperReportBuilder[] generateReports() {
		JasperReportBuilder report = report();
		int rowHeight = 18;
		StyleBuilder boldStyle         = stl.style().bold();
		StyleBuilder boldCenteredStyle = stl.style(boldStyle).setHorizontalAlignment(HorizontalAlignment.CENTER);
		StyleBuilder columnTitleStyle  = stl.style(boldCenteredStyle)
                .setBorder(stl.pen1Point())
                .setBackgroundColor(Color.LIGHT_GRAY);

		TextColumnBuilder<String> revenueOwnershipColumn = col.column("Revenue Ownership", "revenue_ownership", type.stringType()).setFixedWidth(300).setFixedHeight(rowHeight);
		TextColumnBuilder<String> certificationNameColumn = col.column("Site Cert", "certification_name", type.stringType()).setFixedWidth(80).setFixedHeight(rowHeight);
		TextColumnBuilder<String> statusColumn = col.column("Status", "status", type.stringType()).setFixedWidth(100).setFixedHeight(rowHeight);
		TextColumnBuilder<String> reasonColumn = col.column("Reason", "reason", type.stringType()).setFixedWidth(80).setFixedHeight(rowHeight);
		TextColumnBuilder<String> workPackageTypeColumn = col.column("Work Package Type", "work_package_type", type.stringType()).setFixedWidth(80).setFixedHeight(rowHeight);
		TextColumnBuilder<String> workItemNameColumn = col.column("Work Item Name", "work_item_name", type.stringType()).setFixedWidth(80).setFixedHeight(rowHeight);
		TextColumnBuilder<String> calculatedColumn = col.column("Period calculated", "calculated", type.stringType()).setFixedWidth(80).setFixedHeight(rowHeight);
		TextColumnBuilder<String> serviceTargetPeriodColumn = col.column("Period Target", "period", type.stringType()).setFixedWidth(80).setFixedHeight(rowHeight);
		TextColumnBuilder<Date> serviceTargetDateColumn = col.column("Target Date", "service_target_date", type.dateType()).setFixedWidth(80).setFixedHeight(rowHeight);
		TextColumnBuilder<String> wiCreatedPeriodColumn = col.column("Period WI Created", "period_created", type.stringType()).setFixedWidth(80).setFixedHeight(rowHeight);
		TextColumnBuilder<String> createdByColumn = col.column("Created By", "created_by", type.stringType()).setFixedWidth(80).setFixedHeight(rowHeight);
		
		TextColumnBuilder<Double> requiredDurationColumn  = col.column("Required Duration",   "required_duration",  type.doubleType()).setFixedWidth(80).setFixedHeight(rowHeight);

		report
		  .setColumnTitleStyle(columnTitleStyle)
		  .setIgnorePageWidth(true)
		  .setIgnorePagination(true)
		  .setSubtotalStyle(boldStyle)
		  .highlightDetailEvenRows()
		  .columns(
				  revenueOwnershipColumn,
				  certificationNameColumn,
				  statusColumn,
				  reasonColumn,
				  workPackageTypeColumn,
				  workItemNameColumn,
				  calculatedColumn,
				  serviceTargetPeriodColumn,
				  serviceTargetDateColumn,
				  wiCreatedPeriodColumn,
				  createdByColumn,
				  requiredDurationColumn
				  );
		  
		report.title(
					cmp.horizontalList().add(cmp.image(getClass().getResourceAsStream("sai_logo.gif")).setFixedDimension(300, 50)),
					cmp.horizontalList().add(cmp.text(getReportNames()[0])).setFixedDimension(300, 17).setStyle(boldStyle),
					cmp.horizontalList().add(cmp.text("New Business vs. Cancellations")),
					cmp.horizontalList().add(cmp.text("Updated as " + Utility.getShortdatetimedisplayformat().format(new Date()) )).setFixedDimension(300, 17))
		  .addProperty(JasperProperty.EXPORT_XLS_FREEZE_ROW, "5")
		  .setDataSource(data);
		
		return new JasperReportBuilder[] {report};
	}

	@Override
	public void setDb(com.saiglobal.sf.reporting.data.DbHelper db) {
		this.db = db;
	}

	@Override
	public void setProperties(GlobalProperties gp) {
		this.gp = gp;
	}

	@Override
	public void init() {
		List<String> dataVariables = new ArrayList<String>();
		
		dataVariables.add("revenue_ownership");
		dataVariables.add("certification_name");
		dataVariables.add("status");
		dataVariables.add("reason");
		dataVariables.add("work_package_type");
		dataVariables.add("work_item_name");
		dataVariables.add("calculated");
		dataVariables.add("period");
		dataVariables.add("service_target_date");
		dataVariables.add("period_created");
		dataVariables.add("created_by");
		dataVariables.add("required_duration");
		
		data = new DRDataSource(dataVariables.toArray(new String[dataVariables.size()]));
		
		String queryCancelled = "SELECT " +
				"c.Operational_Ownership__c as 'Business Unit' " +
				", c.Name " +
				",'Cancellation' AS 'Status' " +
				", wi.Cancellation_Reason__c as 'Reason' " +
				", wi.Work_Package_Type__c " +
				", wi.Name " +
				", DATE_FORMAT(wi.Service_target_date__c,'%Y %m') AS 'Period' " +
				", wi.Service_target_date__c " +
				", wi.Required_Duration__c/8 AS 'Days' " +
				"FROM work_item__c wi " +
					"INNER JOIN recordtype rt on wi.RecordTypeId = rt.Id " +
					"INNER JOIN work_package__c wp on wp.Id = wi.Work_Package__c " +
					"INNER JOIN certification__c c on c.Id = wp.Site_Certification__c " +
					"INNER JOIN certification__c cp on cp.Id = c.Primary_Certification__c " +
				"WHERE " +
					"wi.Status__c='Cancelled' " +
					"AND rt.Name = 'Audit' " +
					"AND c.Operational_Ownership__c IN ('AUS - Management Systems', 'AUS - Food') " +
					"AND NOT(wi.Cancellation_Reason__c IN ('Other') AND wi.service_change_reason__c is null AND cp.Sample_Service__c = true) " +
				"ORDER BY c.Operational_Ownership__c, `Period`, `Status`, `Reason`";
		
		String queryNewBusiness = "SELECT " +
					"c.Operational_Ownership__c as 'Business Unit' " +
					", c.Id " +
					", c.Name " +
					", DATE_FORMAT(wi.Service_target_date__c,'%Y %m') AS 'Period' " +
					", wi.Service_target_date__c " +
					", DATE_FORMAT(wi.CreatedDate,'%Y %m') AS 'PeriodCreated' " +
					", 'New Business' AS 'Status' " +
					", wi.Work_Item_Stage__c as 'Reason' " +
					", sclc.Duration__c " +
					", sclc.Frequency__c " +
					", sclc.Is_Recurring__c " +
					", sclc.IsDeleted " +
					", wi.Work_Package__c " +
					", wi.Work_Package_Type__c " +
					", wi.Id " +
					", wi.Name " +
					",wi.Required_Duration__c/8 AS 'Days' " +
					", u.Name " + 
				"FROM work_item__c wi " +
					"INNER JOIN user u on wi.CreatedById = u.Id " +
					"INNER JOIN recordtype rt on wi.RecordTypeId = rt.Id " +
					"INNER JOIN work_package__c wp on wp.Id = wi.Work_Package__c " +
					"INNER JOIN certification__c c on c.Id = wp.Site_Certification__c " +
					"INNER JOIN site_certification_lifecycle__c sclc on sclc.Work_Item__c=wi.Id " +
				"WHERE " +
					"rt.Name = 'Audit' " +
					"AND c.Operational_Ownership__c IN ('AUS - Management Systems', 'AUS - Food') " +
					//"AND (u.Name in ('Edison Li', 'Marvin Isidro')) " +
					"AND wi.Work_Package_Type__c='Initial' " + 
					"ORDER BY `Business Unit`, c.Id, `Period`";
		ResultSet rs;
		try {
			rs = db.executeSelect(queryNewBusiness, -1);
			HashMap<String, List<Record>> siteCertification = new HashMap<String, List<Record>>();
			while (rs.next()) {
				Record aRecord = new Record();
				aRecord.setOperational_Ownership(rs.getString("Business Unit"));
				aRecord.setCertId(rs.getString("c.Id"));
				aRecord.setCertName(rs.getString("c.Name"));
				aRecord.setStatus(rs.getString("Status"));
				aRecord.setReason(rs.getString("Reason"));
				aRecord.setWork_Package_Type(rs.getString("wi.Work_Package_Type__c"));
				aRecord.setWiName(rs.getString("wi.Name"));
				aRecord.setPeriod(rs.getString("Period"));
				aRecord.setPeriodCreated(rs.getString("PeriodCreated"));
				Date serviceTargetDate = null;
				if (rs.getString("wi.Service_target_date__c")!=null) {
					serviceTargetDate = activityFormatter.parse(rs.getString("wi.Service_target_date__c"));
					aRecord.setCalculated("false");
				} else {
					aRecord.setCalculated("true");
				}
				aRecord.setService_target_date(serviceTargetDate);
				aRecord.setDays(rs.getDouble("Days"));
				aRecord.setFrequency(rs.getInt("sclc.Frequency__c"));
				aRecord.setIs_Recurring__c(rs.getBoolean("sclc.Is_Recurring__c"));
				aRecord.setCreatedBy(rs.getString("u.Name"));
				
				List<Record> aList = siteCertification.get(aRecord.getCertId());
				if (aList == null)
					aList = new ArrayList<Record>();
				
				aList.add(aRecord);
				siteCertification.put(aRecord.getCertId(), aList);
			}
			for (String siteCertId : siteCertification.keySet()) {
				List<Record> aList = siteCertification.get(siteCertId);
				if ((aList != null) && (aList.size()>0)) {
					for (Record record : aList) {
						if ((record.getService_target_date() == null)) {
							// Figure out service target date and period from other records in the list
							calculateTargetDates(aList);
						}
						data.add(
								record.getOperational_Ownership(),
								record.getCertName(),
								record.getStatus(),
								record.getReason(),
								record.getWork_Package_Type(),
								record.getWiName(),
								record.getCalculated(),
								record.getPeriod(),
								record.getService_target_date(),
								record.getPeriodCreated(),
								record.getCreatedBy(),
								record.getDays()
						);
					}
				}
			}
			
			rs = db.executeSelect(queryCancelled, -1);
			while (rs.next()) {
				Date serviceTargetDate = null;
				if (rs.getString("wi.Service_target_date__c")!=null)
					serviceTargetDate = activityFormatter.parse(rs.getString("wi.Service_target_date__c"));
				data.add(
						rs.getString("Business Unit"),
						rs.getString("c.Name"),
						rs.getString("Status"),
						rs.getString("Reason"),
						rs.getString("wi.Work_Package_Type__c"),
						rs.getString("wi.Name"),
						"false",
						rs.getString("Period"),
						serviceTargetDate,
						"",
						"Cancellation",
						rs.getDouble("Days")
				);
			}
		} catch (Exception e) {
			logger.error("", e);
		}
		
	}
	
	private void calculateTargetDates(List<Record> aSiteCert) {
		// Sort List first by service target date with nulls at the end
		Collections.sort(aSiteCert, new RecordComparator());
		boolean firstSurvelliance = true;
		for (int pointer=0; pointer<aSiteCert.size(); pointer++) {
			Record record = aSiteCert.get(pointer);
			if (record.getService_target_date()==null) {
				if (pointer==0) {
					// Something we can't figure out
					logger.info("Found wi with null service target date and no other wi in same site cert with non null service target date: " + record.getWiName());
				}
				Record refernceWi = null;
				int advance = 3;
				
				if (record.getReason().startsWith("Re-Cert")) {
					// Set Target date record.getFrequency() months from last wi in Initial package
					refernceWi = getLastFromInitialPackage(aSiteCert);
					advance = 3;
				} else {
					// Survelliance.  Set target date record.getFrequency() from last wi regardless of work package
					refernceWi = getLastExcludingRecert(aSiteCert);
					if (firstSurvelliance) {
						advance = 3;
						firstSurvelliance = false;
					} else {
						advance = 0;
					}
				}
				if (refernceWi == null) {
					logger.info("Cannot figure our refernceWI for: " + record.getWiName());
				} else {
					Calendar targetDate = new GregorianCalendar();
					targetDate.setTime(refernceWi.getService_target_date());
					targetDate.add(Calendar.MONTH, record.getFrequency()-advance);
					record.setService_target_date(targetDate.getTime());
					record.setPeriod(periodFormatter.format(targetDate.getTime()));
				}
			}
		}
	}
	
	private Record getLastExcludingRecert(List<Record> aList) {
		Record last = null;

		for (Record record : aList) {
			if (!record.getReason().startsWith("Re-Cert") && (record.getService_target_date() != null)) {
				if ((last == null) || (record.getService_target_date().after(last.getService_target_date()))) 
					last = record;
			}
		}
		return last;
	}
	
	private Record getLastFromInitialPackage(List<Record> aList) {
		Record last = null;

		for (Record record : aList) {
			if ((record.getWork_Package_Type().startsWith("Initial")) && (record.getService_target_date() != null)) {
				if ((last == null) || (record.getService_target_date().after(last.getService_target_date()))) 
					last = record;
			}
		}
		return last;
	}
	
	@Override
	public String[] getReportNames() {
		return new String[] {"New Business vs Cancellations Report"};
	}
	
	public boolean append() {
		return false;
	}
}

class Record {
	public String Operational_Ownership;
	public String certId;
	public String certName;
	public String Period;
	public String PeriodCreated;
	
	public Date Service_target_date;
	private String Status;
	private String Reason;
	private int Frequency;
	private boolean Is_Recurring__c;
	private String Work_Package_Type;
	private String wiName;
	private double Days;
	private String Calculated;
	private String CreatedBy;
	
	public String getCreatedBy() {
		return CreatedBy;
	}
	public void setCreatedBy(String createdBy) {
		CreatedBy = createdBy;
	}
	public String getPeriodCreated() {
		return PeriodCreated;
	}
	public void setPeriodCreated(String periodCreated) {
		PeriodCreated = periodCreated;
	}
	public String getOperational_Ownership() {
		return Operational_Ownership;
	}
	public void setOperational_Ownership(String operational_Ownership) {
		Operational_Ownership = operational_Ownership;
	}
	public String getCertId() {
		return certId;
	}
	public void setCertId(String certId) {
		this.certId = certId;
	}
	public String getCertName() {
		return certName;
	}
	public void setCertName(String certName) {
		this.certName = certName;
	}
	public String getPeriod() {
		return Period;
	}
	public void setPeriod(String period) {
		Period = period;
	}
	public Date getService_target_date() {
		return Service_target_date;
	}
	public void setService_target_date(Date service_target_date) {
		Service_target_date = service_target_date;
	}
	public String getStatus() {
		return Status;
	}
	public void setStatus(String status) {
		Status = status;
	}
	public String getReason() {
		return Reason;
	}
	public void setReason(String reason) {
		Reason = reason;
	}
	public int getFrequency() {
		return Frequency;
	}
	public void setFrequency(int frequency) {
		Frequency = frequency;
	}
	public boolean isIs_Recurring__c() {
		return Is_Recurring__c;
	}
	public void setIs_Recurring__c(boolean is_Recurring__c) {
		Is_Recurring__c = is_Recurring__c;
	}
	public String getWork_Package_Type() {
		return Work_Package_Type;
	}
	public void setWork_Package_Type(String work_Package_Type) {
		Work_Package_Type = work_Package_Type;
	}
	public String getWiName() {
		return wiName;
	}
	public void setWiName(String wiName) {
		this.wiName = wiName;
	}
	public double getDays() {
		return Days;
	}
	public void setDays(double days) {
		Days = days;
	}
	public String getCalculated() {
		return Calculated;
	}
	public void setCalculated(String calculated) {
		Calculated = calculated;
	}	
}

class RecordComparator implements Comparator<Record> {

	@Override
	public int compare(Record r1, Record r2) {
		if ((r1.getService_target_date()==null) && (r2.getService_target_date()==null))
			return 0;
		if (r1.getService_target_date()==null)
			return 1;
		if (r2.getService_target_date()==null)
			return -1;
		return r1.getService_target_date().compareTo(r2.getService_target_date());
	}

	public static <T, U extends Comparable<? super U>> Comparator<T> comparing(
			Function<? super T, ? extends U> arg0) {
		// TODO Auto-generated method stub
		return null;
	}

	public static <T, U> Comparator<T> comparing(
			Function<? super T, ? extends U> arg0, Comparator<? super U> arg1) {
		// TODO Auto-generated method stub
		return null;
	}

	public static <T> Comparator<T> comparingDouble(
			ToDoubleFunction<? super T> arg0) {
		// TODO Auto-generated method stub
		return null;
	}

	public static <T> Comparator<T> comparingInt(ToIntFunction<? super T> arg0) {
		// TODO Auto-generated method stub
		return null;
	}

	public static <T> Comparator<T> comparingLong(ToLongFunction<? super T> arg0) {
		// TODO Auto-generated method stub
		return null;
	}

	public static <T extends Comparable<? super T>> Comparator<T> naturalOrder() {
		// TODO Auto-generated method stub
		return null;
	}

	public static <T> Comparator<T> nullsFirst(Comparator<? super T> arg0) {
		// TODO Auto-generated method stub
		return null;
	}

	public static <T> Comparator<T> nullsLast(Comparator<? super T> arg0) {
		// TODO Auto-generated method stub
		return null;
	}

	public static <T extends Comparable<? super T>> Comparator<T> reverseOrder() {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public Comparator<Record> reversed() {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public Comparator<Record> thenComparing(Comparator<? super Record> arg0) {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public <U extends Comparable<? super U>> Comparator<Record> thenComparing(
			Function<? super Record, ? extends U> arg0) {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public <U> Comparator<Record> thenComparing(
			Function<? super Record, ? extends U> arg0,
			Comparator<? super U> arg1) {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public Comparator<Record> thenComparingDouble(
			ToDoubleFunction<? super Record> arg0) {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public Comparator<Record> thenComparingInt(
			ToIntFunction<? super Record> arg0) {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public Comparator<Record> thenComparingLong(
			ToLongFunction<? super Record> arg0) {
		// TODO Auto-generated method stub
		return null;
	}
}
