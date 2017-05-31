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

public class PhoneMetricsUpdateV3 implements ReportBuilder {
	private DbHelper db;
	private GlobalProperties gp;
	private static final String subfolder = "\\Mitel\\queue\\";
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
		String subject = "Queue Performance by Member";
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
        
		Cell queueCell = sheet.getRow(3).getCell(1);
		Cell reportDateCell = sheet.getRow(4).getCell(1);
		int employeeIdColumn = 1, employeeNameColumn = 2, employeeCountColumn = 3, employeeDurationColumn = 6, queueStartRow = 7;
		
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
		
		String[] queueArray = queueCell.getStringCellValue().split(" - ");
		String queueId = queueArray[0].split("]")[1].trim();
		String queueName = queueArray[1].trim();
		Row currentRow = null;
		int rowIndex = queueStartRow;
		while ((currentRow = sheet.getRow(rowIndex++)) != null) {	
			// Get Employee Details
			int count = 0, duration = 0;
			Cell employeeIdCell = currentRow.getCell(employeeIdColumn);
			if ((employeeIdCell == null) || (employeeIdCell.getStringCellValue() == null) || (employeeIdCell.getStringCellValue().equalsIgnoreCase("")) || (employeeIdCell.getStringCellValue().equalsIgnoreCase("Totals"))) {
				// No more records
				break;
			}
			Cell employeeNameCell = currentRow.getCell(employeeNameColumn);
			if ((employeeNameCell == null) || (employeeNameCell.getStringCellValue() == null) || (employeeNameCell.getStringCellValue().equalsIgnoreCase("")) || (employeeNameCell.getStringCellValue().equalsIgnoreCase("Totals"))) {
				// No more records
				break;
			}
			Cell countCell = currentRow.getCell(employeeCountColumn);
			if (countCell != null) {
				count = (int) countCell.getNumericCellValue();
			}
			Cell durationCell = currentRow.getCell(employeeDurationColumn);
			if (durationCell != null) {
				String[] durationArray = durationCell.getStringCellValue().split(":");
				if (durationArray.length == 3) {
					duration = Integer.parseInt(durationArray[2]) + Integer.parseInt(durationArray[1])*60 + Integer.parseInt(durationArray[0])*60*60;
				}	
			}
			saveRecord(fromDate, toDate, span, employeeIdCell.getStringCellValue(), employeeNameCell.getStringCellValue(), queueId, queueName, count,duration,0);
		}
		
        logger.info("Parsed " + attachment.getName() + " and updated db");
        workbook.close();
        fis.close();
	}
	
	private void saveRecord(Calendar fromDate, Calendar toDate, String span, String employeeId, String employeeName, String queueId, String queueName, int count,int duration, int requeued) throws Exception {
		db.executeStatement("INSERT INTO `employee_queue_data` VALUES (" +
				"'" + Utility.getMysqldateformat().format(fromDate.getTime()) + "'," +
				"'" + Utility.getMysqldateformat().format(toDate.getTime()) + "'," +
				"'" + span + "'," +
				"'" + employeeId + "'," +
				"'" + employeeName + "'," +
				"'" + queueId + "'," +
				"'" + queueName + "'," +
				count + "," +
				duration + "," +
				requeued+ ")");
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
