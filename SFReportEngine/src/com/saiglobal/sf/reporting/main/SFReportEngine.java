package com.saiglobal.sf.reporting.main;
import static net.sf.dynamicreports.report.builder.DynamicReports.*;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.nio.file.Files;
import java.util.Date;

import net.sf.dynamicreports.jasper.builder.JasperReportBuilder;
import net.sf.dynamicreports.jasper.builder.export.JasperImageExporterBuilder;
import net.sf.dynamicreports.jasper.builder.export.JasperXlsxExporterBuilder;
import net.sf.dynamicreports.jasper.constant.ImageType;

import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.GnuParser;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException;
import org.apache.log4j.Level;
import org.apache.log4j.Logger;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

import com.saiglobal.sf.core.model.ReportFormatType;
import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;
import com.saiglobal.sf.reporting.data.DbHelper;
import com.saiglobal.sf.reporting.processor.*;

public class SFReportEngine {

	protected static final Logger logger = Logger.getLogger("com.saiglobal");
	
	protected static String reportFolder = "C:\\SAI\\reports\\";
	protected static GlobalProperties cmd = null;
	public static String taskName = "sfrepoprtengine";
	
	/**
	 * Apply Apache Commons CLI GnuParser to command-line arguments.
	 * 
	 * @param commandLineArguments
	 *            Command-line arguments to be processed with Gnu-style parser.
	 */
	public static GlobalProperties parseCommandLineArgs(final String[] commandLineArguments, GlobalProperties properties) throws Exception {
		logger.debug(commandLineArguments.toString());
		final CommandLineParser cmdLineGnuParser = new GnuParser();
		final Options gnuOptions = constructGnuOptions();
		CommandLine commandLine;
		try {
			commandLine = cmdLineGnuParser.parse(gnuOptions, commandLineArguments);
			
			if (commandLine.hasOption("rb")) 
				properties.setReportBuilderClass(commandLine.getOptionValue("rb"));
			if (commandLine.hasOption("re")) 
				properties.setReportEmails(commandLine.getOptionValue("re"));
			if (commandLine.hasOption("rf")) 
				properties.setReportFolder(commandLine.getOptionValue("rf"));
			if (commandLine.hasOption("rsftp")) 
				properties.setSftpDetails(commandLine.getOptionValue("rsftp"));
			if (commandLine.hasOption("rff")) 
				properties.setReportFormat(commandLine.getOptionValue("rff"));
			if (commandLine.hasOption("itin")) 
				properties.setIncludeTimeInName(commandLine.getOptionValue("itin"));
			if (commandLine.hasOption("sdth")) 
				properties.setSaveDataToHistory(commandLine.getOptionValue("sdth"));
			if (commandLine.hasOption("cp") && (commandLine.getOptionValue("cp")!=null)) {
				String[] pairs = commandLine.getOptionValue("cp").split(";");
				for (String pair : pairs) {
					String[] nameValue = pair.split(":");
					if ((nameValue != null) && (nameValue.length==2)) {
						properties.addCustom_property(nameValue[0], nameValue[1]);
					}		
				}
			} 
			if (commandLine.hasOption("logLevel")) {
				properties.getTaskProperties().setLogLevel(Level.toLevel(commandLine.getOptionValue("logLevel"), Level.INFO));
			}	
			
			return properties;
		} catch (ParseException parseException) {
			logger.error("Encountered exception while parsing using GnuParser:\n" + parseException.getMessage());
			return null;
		}
	}

	/**
	 * Construct and provide GNU-compatible Options.
	 * 
	 * @return Options expected from command-line of GNU form.
	 */
	public static Options constructGnuOptions() {
		final Options gnuOptions = new Options();

		gnuOptions
		.addOption("rb", "report-builder", true, "Enter the report builder class")
		.addOption("re", "report-emails", true, "Enter the email address to send the report to (comma separated")
		.addOption("rf", "report-folder", true, "Enter the folder to save the report to")
		.addOption("rsftp", "report-sftp", true, "SFTP Details for upload (comma separated server,user,password")
		.addOption("rff", "report-file-format", true, "Enter the file format for the report (csv, pdf, xlsx)")
		.addOption("itin", "Include-time-in-name", true, "Include date/time in the file name")
		.addOption("sdth", "Save-data-to-history", true, "Save report data to history table in db")
		.addOption("cp", "Custom Properties", true, "name1:value1;name2:value2;name3:value3... semicolumn separated pairs of column separated property name and value")
		.addOption("propertyFile", "property file", true, "property file")
		.addOption("subject", "subject", true, "email subject search condition")
		.addOption("from", "from", true, "email from search condition")
		.addOption("logLevel", "logLevel", true, "logLevel");

		return gnuOptions;
	}
	
	protected static void init(String[] commandLineArguments) throws Exception {
		// Initialisation
		final Options gnuOptions = constructGnuOptions();
		final CommandLineParser cmdLineGnuParser = new GnuParser();
		
		try {
			CommandLine commandLine = cmdLineGnuParser.parse(gnuOptions, commandLineArguments);
			if (commandLine.hasOption("propertyFile"))
				cmd = Utility.getProperties(commandLine.getOptionValue("propertyFile"));
			
		} catch (ParseException e) {
			logger.error("",e);
			logger.error("Using default property file");
		}
		if (cmd == null)
			cmd = GlobalProperties.getDefaultInstance();
		
		cmd.setCurrentTask(taskName);
		cmd = parseCommandLineArgs(commandLineArguments, cmd);
		if (cmd.getReportFolder()!=null) {
			reportFolder = cmd.getReportFolder();
			if (!reportFolder.endsWith("\\"))
				reportFolder += "\\";
		}
		
		cmd.setCurrentTask(taskName);
	}
	
	public static void main(String[] commandLineArguments) {
		
		DbHelper db = null;
		try {
			init(commandLineArguments);
			logger.setLevel(cmd.getTaskProperties().getLogLevel());
			ReportFormatType format = ReportFormatType.getValueForName(cmd.getReportFormat());
			if (format == null) {
				logger.debug("Format unknown or null.  Using default xlsx");
				format = ReportFormatType.EXCEL;
			}
			
			// Instantiate Report Builder Class
			ReportBuilder reportBuilder = null;
			if(format.equals(ReportFormatType.EXCELTEMPLATEWITHSQL)) {
				String template = cmd.getCustomParameter("xlsxTemplate");
				if ((template != null) && (template != "")) {
					File templateFile = new File(reportFolder + template);
					if (templateFile != null) {
						ReportDetails details = getDetailsFromTemplate(templateFile);
						reportBuilder = new StandardReportFromExcelTemplate(details.getName(), details.getDatasource(), details.getQuery(), details.getInitStmt(), details.getFinalStmt(), details.getJavaDynamicCode());
					}
				}
			} else {
				Class<?> reportBuilderCalss = Class.forName(cmd.getReportBuilderClass());
				reportBuilder = (ReportBuilder)reportBuilderCalss.newInstance();
			}
			
			logger.info("Starting SAI global - Report Engine - " + reportBuilder.getClass().getCanonicalName());
			Utility.startTimeCounter(reportBuilder.getClass().getCanonicalName());
			reportBuilder.setProperties(cmd);
			db = new DbHelper(cmd);
			reportBuilder.setDb(db);
			reportBuilder.init();
			
			// Create report formatted as cmd.getReportFormat() and save it to file
			
			String[] reportNames = reportBuilder.getReportNames();
			// Call Execute method to get report
			JasperReportBuilder[] reports = reportBuilder.generateReports();
			
			for (int i = 0; i < reports.length; i++) {
				logger.info("Building report " + reportNames[i] + " in " + format.getExtension() + " format ");
	
				String reportFileName = reportFolder + reportNames[i];
				if (cmd.isIncludeTimeInName()) {
					reportFileName += "." + Utility.getFiledatetimedisplayformat().format(new Date()) + "." + format.getExtension();
				} else {
					reportFileName += "." + format.getExtension();
				}
				File reportFile = new File(reportFileName);
		        
				File directory = reportFile.getParentFile();
				if(!reportFile.exists()) {
					directory.mkdirs();
					reportFile.createNewFile();
				} else {
					// File already exists.  If appending I need to remove the header
					if (reportBuilder.append())
						reports[i].setShowColumnTitle(false);
				}
				FileOutputStream reportOutputStream = new FileOutputStream(reportFile, format.equals(ReportFormatType.EXCELTEMPLATE)?false:reportBuilder.append()); 
	
				switch (format) {
				case CSV:
					reports[i].toCsv(reportOutputStream);
					break;
				case EXCEL: {
					JasperXlsxExporterBuilder xlsxExporter = export.xlsxExporter(reportOutputStream)
							.setDetectCellType(true)
							.setIgnorePageMargins(true)
							.setWhitePageBackground(true)
							.setRemoveEmptySpaceBetweenColumns(true);
							if (reportBuilder.concatenatedReports()) {
								xlsxExporter.setOnePagePerSheet(true);
								concatenatedReport()
									.setContinuousPageNumbering(true)
									.concatenate(reports)
									.toXlsx(xlsxExporter);
							} else {		
								reports[i].toXlsx(xlsxExporter);
							}
					break;
				}
				case EXCELTEMPLATEWITHSQL:
				case EXCELTEMPLATE: {
					String template = cmd.getCustomParameter("xlsxTemplate");
					if ((template != null) && (template != "")) {
						File templateFile = new File(reportFolder + template);
						if (templateFile.exists()) {
							createFileFromTemplate(templateFile, reportFile, reports[i]);
						}
					}
					break;
				}
				case PDF:
					reports[i].toPdf(reportOutputStream);
					break;
				case JPG: {
					JasperImageExporterBuilder imageExporter = export.imageExporter(reportOutputStream, ImageType.JPG);
					reports[i].toImage(imageExporter);
					break;
				}
				default:
					// Format not available - file will be empty
					logger.info("Format " + format.getName() + " not available - file will be empty");
					break;
				}
			
				reportOutputStream.close();
				
				// Email report
				if ((cmd.getReportEmails() != null) && (cmd.getReportEmails().length>0)) {
					Utility.email(
								cmd, 
								"Emailing report: " + reportNames[i], 
								"Please find attached report " + reportNames[i], 
								new String[] {reportFileName});
				}
				
				// SFTP 
				if (cmd.sftpReports()) {
					File reportFileAux = new File(reportFileName);
					Utility.sftp(cmd.getSftpServer(), cmd.getSftpPort(), cmd.getSftpUser(), cmd.getSftpPassword(), reportFileName, reportFileAux.getName());
				}
				
				// Log Report
				Utility.stopTimeCounter(reportBuilder.getClass().getCanonicalName());
				Utility.logReport(cmd, cmd.getReportBuilderClass(), reportFileName.replace("\\", "/"), cmd.getReportEmailsAsString(), (cmd.sftpReports()?cmd.getSftpServer():null), Utility.getTimeCounterMS(reportBuilder.getClass().getCanonicalName()));
				
				// If Multi page exit the loop after first round
				if (reportBuilder.concatenatedReports()) 
					i = reports.length;// Exit the loop.
			}
			Utility.logAllEventCounter();
			Utility.logAllProcessingTime();
			logger.info("Finished SAI global - Report Engine- " + reportBuilder.getClass().getCanonicalName());
		} catch (Throwable e) {
			Utility.handleError(cmd, e, "Exception in report: " + cmd.getReportBuilderClass());
		} finally {
			if (db != null)
				db.closeConnection();
		}
	}
	
	private static ReportDetails getDetailsFromTemplate(File template) {
		try {
			FileInputStream fis = new FileInputStream(template);
			Workbook workbook = new XSSFWorkbook(fis);
			Sheet sheet = workbook.getSheet("details");
			String name = null, datasource = null, query = null, initStmt = null, finalStmt = null, javaDynamicCode = null;
			Row nameRow = sheet.getRow(0);
			Row datasourceRow = sheet.getRow(1);
			Row queryRow = sheet.getRow(2);
			
			if(nameRow != null) {
				Cell nameCell = nameRow.getCell(1);
				if (nameCell != null) {
					name = nameCell.getStringCellValue();
				}
			}
			if(datasourceRow != null) {
				Cell datasourceCell = datasourceRow.getCell(1);
				if (datasourceCell != null) {
					datasource = datasourceCell.getStringCellValue();
				}
			}
			if(queryRow != null) {
				Cell queryCell = queryRow.getCell(1);
				if (queryCell != null) {
					query = queryCell.getStringCellValue();
				}
				Cell initStmtCell = queryRow.getCell(2);
				if (initStmtCell != null) {
					initStmt = initStmtCell.getStringCellValue();
				}
				Cell finalStmtCell = queryRow.getCell(3);
				if (finalStmtCell != null) {
					finalStmt = finalStmtCell.getStringCellValue();
				}
				Cell javaDynamicCodeCell = queryRow.getCell(4);
				if (javaDynamicCodeCell != null) {
					javaDynamicCode = javaDynamicCodeCell.getStringCellValue();
				}
			}
			workbook.close();
			if ((name != null) && (datasource != null) && (query != null)) {
				ReportDetails rd = new ReportDetails(name, datasource, query);
				if (initStmt != null)
					rd.setInitStmt(initStmt);
				if (finalStmt != null)
					rd.setFinalStmt(finalStmt);
				if (javaDynamicCode != null) 
					rd.setJavaDynamicCode(javaDynamicCode);
				
				return rd;
			}
		} catch (Exception e) {
			Utility.handleError(cmd, e);;
		}
		return null;
	}
	
	private static void createFileFromTemplate(File template, File out, JasperReportBuilder report) throws Exception {
		FileOutputStream os = new FileOutputStream(out);
		Files.copy(template.toPath(), os);
		os.close();
		
		FileInputStream fis = new FileInputStream(out);
		Workbook workbook = new XSSFWorkbook(fis);
		Sheet sheet = workbook.getSheet("data");
		
		File tmp = File.createTempFile(out.getName(), "xlsx");
		FileOutputStream tmpos = new FileOutputStream(tmp);
		JasperXlsxExporterBuilder xlsxExporter = export.xlsxExporter(tmpos)
				.setDetectCellType(true)
				.setIgnorePageMargins(true)
				.setWhitePageBackground(true)
				.setRemoveEmptySpaceBetweenColumns(true);
		
		report.toXlsx(xlsxExporter);
		tmpos.close();
		
		FileInputStream tmpis = new FileInputStream(tmp);
		Workbook tmpwb = new XSSFWorkbook(tmpis);
		Sheet tmpsh = tmpwb.getSheetAt(0);
		
		int rowIndex = 0, columnIndex = 0;
		for (Row tmpRow : tmpsh) {
			rowIndex = tmpRow.getRowNum();
			if (rowIndex==0) {
				// Skip header
				continue;
			}
			Row row = sheet.getRow(rowIndex);
			if (row == null)
				row = sheet.createRow(rowIndex);
			for (Cell tmpCell : tmpRow) {
				columnIndex = tmpCell.getColumnIndex();
				Cell cell = row.getCell(columnIndex);
				if (cell == null)
					cell = row.createCell(columnIndex);
				cell.setCellType(tmpCell.getCellType());
				switch (tmpCell.getCellType()) {
				case Cell.CELL_TYPE_BOOLEAN:
					cell.setCellValue(tmpCell.getBooleanCellValue());
					break;
				case Cell.CELL_TYPE_NUMERIC:
					tmpCell.setCellType(Cell.CELL_TYPE_STRING);
					if (!tmpCell.getStringCellValue().equalsIgnoreCase("")) {
						cell.setCellValue(Double.parseDouble(tmpCell.getStringCellValue()));
					}
					break;
				case Cell.CELL_TYPE_STRING:
					cell.setCellValue(tmpCell.getStringCellValue());
					break;
				default:
					cell.setCellValue(tmpCell.getStringCellValue());
					break;
				}
			}
		}
		tmpwb.close();
		tmpis.close();
		tmp.delete();
		fis.close();
		
		//Open FileOutputStream to write updates
        FileOutputStream output_file =new FileOutputStream(out);
        //write changes
        workbook.write(output_file);
        workbook.close();
        //close the stream
        output_file.close();
        
	}
}

class ReportDetails {
	public String name, datasource, query, initStmt, finalStmt, javaDynamicCode;

	public ReportDetails(String name, String datasource, String query) {
		super();
		this.name = name;
		this.datasource = datasource;
		this.query = query;
		this.initStmt = null;
		this.finalStmt = null;
		this.javaDynamicCode = null;
	}
	
	public String getJavaDynamicCode() {
		return javaDynamicCode;
	}

	public void setJavaDynamicCode(String javaDynamicCode) {
		this.javaDynamicCode = javaDynamicCode;
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


	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public String getDatasource() {
		return datasource;
	}

	public void setDatasource(String datasource) {
		this.datasource = datasource;
	}

	public String getQuery() {
		return query;
	}

	public void setQuery(String query) {
		this.query = query;
	}
	
}
