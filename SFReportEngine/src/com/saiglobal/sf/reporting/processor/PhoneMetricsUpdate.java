package com.saiglobal.sf.reporting.processor;

import java.io.File;
import java.io.FileInputStream;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Calendar;
import java.util.Date;
import java.util.HashMap;
import java.util.Iterator;
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

public class PhoneMetricsUpdate implements ReportBuilder {
	private DbHelper db_certification;
	private GlobalProperties gp;
	
	private static final String[] measures = new String[] {"ACD calls offered", "ACD calls handled", "Average speed of answer (hh:mm:ss)", "Average ACD handling time (hh:mm:ss)"};
	private static final String[] queues = new String[] {"Public Training", "Assessments", "In-House", "Pre-course Enq.", "Other Enquiries", "Invoice Enq.", "Online Learning", "Cancellation", "Recognition", "Online Course TA"};
	private static final int[] createdDateCoordinates = new int[] {5,1};
	private static final Logger logger = Logger.getLogger(PhoneMetricsUpdate.class);
	private static final String subfolder = "\\Mitel\\Queue\\";
	
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
		this.db_certification = db;
	}

	@Override
	public void setProperties(GlobalProperties gp) {
		this.gp = gp;
	}

	@Override
	public void init() throws Exception {
		// Collect latest report(s) from reporting@saiglobal.com
		String subject = "Queue Group Performance by Queue";
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
		FileInputStream fis = new FileInputStream(attachment);
		
		HSSFWorkbook workbook = new HSSFWorkbook(fis);
		HSSFSheet sheet = workbook.getSheetAt(0);
        
		HashMap<String, Integer> measureColumns = new HashMap<String, Integer>();
		HashMap<String, Integer> queueRows = new HashMap<String, Integer>();
		
		
		for (String metric : measures) {
			measureColumns.put(metric, 0);
		}
		for (String queue : queues) {
			queueRows.put(queue, 0);
		}
		
        //Iterate through each cell of spreadsheet to find required data 
        Iterator<Row> rowIterator = sheet.iterator();
        while(rowIterator.hasNext()) {
            Row row = rowIterator.next();

            //For each row, iterate through each columns
            Iterator<Cell> cellIterator = row.cellIterator();
            while(cellIterator.hasNext()) {
                Cell cell = cellIterator.next();
                if(cell.getCellType()==Cell.CELL_TYPE_STRING) {
                	//System.out.println(cell.getStringCellValue());
                	if (measureColumns.containsKey(cell.getStringCellValue())) {
                    	measureColumns.put(cell.getStringCellValue(), cell.getColumnIndex());
                    } else if (queueRows.containsKey(cell.getStringCellValue())) {
                    	queueRows.put(cell.getStringCellValue(), cell.getRowIndex());
                    } 
                }
            }
        }
        
        DateFormat dateFormat = new SimpleDateFormat("M/d/yyyy");
        Cell reportDateCell = sheet.getRow(createdDateCoordinates[0]).getCell(createdDateCoordinates[1]);
        Date reportDate = dateFormat.parse(reportDateCell.getStringCellValue().replaceAll("Created on", "").split("-")[0].trim());
        Calendar reportDateCalendar = Calendar.getInstance();
        reportDateCalendar.setTime(reportDate);
        
        for (String measure : measureColumns.keySet()) {
        	for (String queue : queueRows.keySet()) {
				Cell cell = sheet.getRow(queueRows.get(queue)).getCell(measureColumns.get(measure));
				if(cell.getCellType()==Cell.CELL_TYPE_NUMERIC) {
					db_certification.addToData("Australia", "Mitel", measure, queue, reportDateCalendar, cell.getNumericCellValue(), Double.toString(cell.getNumericCellValue()), true);
				} else if (cell.getCellType()==Cell.CELL_TYPE_STRING) {
					String[] duration = cell.getStringCellValue().split(":");
					if (duration.length == 3) {
						double durationNumeric = Double.parseDouble(duration[2])/(3600*24) + Double.parseDouble(duration[1])/(60*24) + Double.parseDouble(duration[0])/24;
						db_certification.addToData("Australia", "Mitel", measure, queue, reportDateCalendar,durationNumeric, Double.toString(durationNumeric), true);
					}
				}
			}
		}
        logger.info("Parsed " + attachment.getName() + " and updated db");
        fis.close();
        workbook.close();
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
