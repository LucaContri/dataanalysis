package com.saiglobal.sf.reporting.processor;

import java.io.File;
import java.io.FileInputStream;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Calendar;
import java.util.List;

import javax.mail.search.SearchTerm;

import org.apache.log4j.Logger;
import org.apache.poi.hssf.usermodel.HSSFSheet;
import org.apache.poi.hssf.usermodel.HSSFWorkbook;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.Row;

import net.sf.dynamicreports.jasper.builder.JasperReportBuilder;

import com.saiglobal.sf.core.utility.CustomSearchCondition;
import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;
import com.saiglobal.sf.reporting.data.DbHelper;

public class PhoneMetricsUpdateV2 implements ReportBuilder {
	private DbHelper db;
	private GlobalProperties gp;
	private static final String subfolder = "\\Mitel\\employee\\";
	private static final Logger logger = Logger.getLogger(PhoneMetricsUpdate.class);
	
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
		this.db = db;
	}

	@Override
	public void setProperties(GlobalProperties gp) {
		this.gp = gp;
		this.gp.setCurrentDataSource("mitel");
	}

	@Override
	public void init() throws Exception {
		// Collect latest report(s) from reporting@saiglobal.com
		String subject = "Employee Performance by Queue";
		String from = "Helen.Sun@saiglobal.com";
		downloadMitelReports(subject, from, subfolder);
		
		// Read Mitel reports folder and parse files
		List<File> attachments = new ArrayList<File>();
		File mitelFolder = new File(gp.getReportFolder()+subfolder);
		
		if (mitelFolder.isDirectory())
			attachments.addAll(Arrays.asList(mitelFolder.listFiles()));
		
	    // Update db_certification with phone metrics data
	    for (File file : attachments) {
	    	parseAndUpdateDb(file);
	    	file.delete();
	    	logger.info("Deleted local file " + file.getName());
	    }
	}
	
	private void parseAndUpdateDb(File attachment) throws Exception {
		DateFormat dateFormat = new SimpleDateFormat("M/d/yyyy");
		
		FileInputStream fis = new FileInputStream(attachment);
		
		HSSFWorkbook workbook = new HSSFWorkbook(fis);
		HSSFSheet sheet = workbook.getSheetAt(0);
        
		Cell employeeCell = sheet.getRow(3).getCell(1);
		Cell reportDateCell = sheet.getRow(4).getCell(1);
		int outboundCountColumn = 8, outboundDurationColumn = 14, noACDCountColumn = 7, noACDDurationColumn = 12, transferredToCountColumn = 9, transferredFromCountColumn = 10, conferanceCountColumn = 11, queueNameColumn = 1, queueCountColumn = 2, queueDurationColumn = 3, queueRequeuedColumn = 5, queueStartRow = 7;
		
		String[] dates = reportDateCell.getStringCellValue().replaceAll("Created on", "").split("-");
		Calendar fromDate = Calendar.getInstance();
		fromDate.setTime(dateFormat.parse(dates[0].trim()));
		Calendar toDate = Calendar.getInstance();
		toDate.setTime(dateFormat.parse(dates[1].trim()));
		String span = "OTHER";
		
		if (fromDate.compareTo(toDate)==0) {
			span = "DAY";
		} else if ((fromDate.get(Calendar.MONTH)==toDate.get(Calendar.MONTH)) && (fromDate.get(Calendar.DAY_OF_MONTH) == 1) && (toDate.get(Calendar.DAY_OF_MONTH) == toDate.getActualMaximum(Calendar.DAY_OF_MONTH))) {
			span = "MONTH";
		} else if ((fromDate.get(Calendar.YEAR)==toDate.get(Calendar.YEAR)) && (fromDate.get(Calendar.MONTH)==Calendar.JANUARY) && (toDate.get(Calendar.MONTH)==Calendar.DECEMBER) && (fromDate.get(Calendar.DAY_OF_MONTH) == 1) && (toDate.get(Calendar.DAY_OF_MONTH) == toDate.getActualMaximum(Calendar.DAY_OF_MONTH))) {
			span = "YEAR";
		}
		
		String[] employeeArray = employeeCell.getStringCellValue().split(" - ");
		String employeeId = employeeArray[0].trim();
		String employeeName = employeeArray[1].trim();
		Row currentRow = null;
		int rowIndex = queueStartRow;
		while ((currentRow = sheet.getRow(rowIndex++)) != null) {
			if (currentRow.getRowNum() == queueStartRow) {
				// Get Outbound details
				int outboundCount = 0, outboundDuration = 0;
				Cell outboundCountCell = currentRow.getCell(outboundCountColumn);
				if (outboundCountCell != null) {
					outboundCount = (int) outboundCountCell.getNumericCellValue();
				}
				Cell outboundDurationCell = currentRow.getCell(outboundDurationColumn);
				if (outboundDurationCell != null) {
					String[] duration = outboundDurationCell.getStringCellValue().split(":");
					if (duration.length == 3) {
						outboundDuration = Integer.parseInt(duration[2]) + Integer.parseInt(duration[1])*60 + Integer.parseInt(duration[0])*60*60;
					}	
				}
				saveRecord(fromDate, toDate, span, employeeId, employeeName, "OUTBOUND", outboundCount,outboundDuration,0);
				
				// Get No ACD details
				int noACDCount = 0, noACDDuration = 0;
				Cell noACDCountCell = currentRow.getCell(noACDCountColumn);
				if (noACDCountCell != null) {
					noACDCount = (int) noACDCountCell.getNumericCellValue();
				}
				Cell noACDDurationCell = currentRow.getCell(noACDDurationColumn);
				if (noACDDurationCell != null) {
					String[] duration = noACDDurationCell.getStringCellValue().split(":");
					if (duration.length == 3) {
						noACDDuration = Integer.parseInt(duration[2]) + Integer.parseInt(duration[1])*60 + Integer.parseInt(duration[0])*60*60;
					}	
				}
				saveRecord(fromDate, toDate, span, employeeId, employeeName, "NOACD", noACDCount,noACDDuration,0);
				
				// Get Transferred To details
				int transferredToCount = 0;
				Cell transferredToCountCell = currentRow.getCell(transferredToCountColumn);
				if (transferredToCountCell != null) {
					transferredToCount = (int) transferredToCountCell.getNumericCellValue();
				}
				
				saveRecord(fromDate, toDate, span, employeeId, employeeName, "TRANSTO", transferredToCount,0,0);
				
				// Get Transferred From details
				int transferredFromCount = 0;
				Cell transferredFromCountCell = currentRow.getCell(transferredFromCountColumn);
				if (transferredFromCountCell != null) {
					transferredFromCount = (int) transferredFromCountCell.getNumericCellValue();
				}
				
				saveRecord(fromDate, toDate, span, employeeId, employeeName, "TRANSFROM", transferredFromCount,0,0);
				
				// Get Conference Calls details
				int conferanceCount = 0;
				Cell conferanceCountCell = currentRow.getCell(conferanceCountColumn);
				if (conferanceCountCell != null) {
					conferanceCount = (int) conferanceCountCell.getNumericCellValue();
				}
				
				saveRecord(fromDate, toDate, span, employeeId, employeeName, "CONF", conferanceCount,0,0);
				
			}
			// Get actual Queues Details
			int count = 0, duration = 0, requeuedCount = 0;
			Cell queueIdCell = currentRow.getCell(queueNameColumn);
			if ((queueIdCell == null) || (queueIdCell.getStringCellValue() == null) || (queueIdCell.getStringCellValue().equalsIgnoreCase("")) || (queueIdCell.getStringCellValue().equalsIgnoreCase("Totals"))) {
				// No more records
				break;
			}
			
			Cell countCell = currentRow.getCell(queueCountColumn);
			if (countCell != null) {
				count = (int) countCell.getNumericCellValue();
			}
			Cell requeuedCell = currentRow.getCell(queueRequeuedColumn);
			if (requeuedCell != null) {
				requeuedCount = (int) requeuedCell.getNumericCellValue();
			}
			Cell durationCell = currentRow.getCell(queueDurationColumn);
			if (durationCell != null) {
				String[] durationArray = durationCell.getStringCellValue().split(":");
				if (durationArray.length == 3) {
					duration = Integer.parseInt(durationArray[2]) + Integer.parseInt(durationArray[1])*60 + Integer.parseInt(durationArray[0])*60*60;
				}	
			}
			saveRecord(fromDate, toDate, span, employeeId, employeeName, queueIdCell.getStringCellValue(), count,duration,requeuedCount);
		}
		
        logger.info("Parsed " + attachment.getName() + " and updated db");
        workbook.close();
        fis.close();
	}
	
	private void saveRecord(Calendar fromDate, Calendar toDate, String span, String employeeId, String employeeName, String queueId, int count,int duration, int requeued) throws Exception {
		db.executeStatement("INSERT INTO `employee_queue_data` VALUES (" +
				"'" + Utility.getMysqldateformat().format(fromDate.getTime()) + "'," +
				"'" + Utility.getMysqldateformat().format(toDate.getTime()) + "'," +
				"'" + span + "'," +
				"'" + employeeId + "'," +
				"'" + employeeName + "'," +
				"'" + queueId + "'," +
				count + "," +
				duration + "," +
				requeued+ ") ON DUPLICATE KEY UPDATE EmployeeId=EmployeeId");
	}
	
	private List<String> downloadMitelReports(String subject, String from, String subFolder) throws Exception {
		SearchTerm searchCondition = new CustomSearchCondition(subject,from); 
        return Utility.downloadAttachmentsFromEmail(gp, new SearchTerm[] {searchCondition}, true, this.gp.getReportFolder() +subFolder);
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
