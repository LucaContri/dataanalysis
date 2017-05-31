package com.saiglobal.jhtmltopdf.main;

import java.io.IOException;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.sql.ResultSet;
import java.sql.SQLException;

import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.GnuParser;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException;
import org.apache.log4j.Logger;

import com.saiglobal.sf.core.data.DbHelperDataSource;
import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;

public class JHtmlToPdf {
	static HtmlToPdfRequest request = null;
	//static final int execution_timeout = 120000;
	static final String dbsource = "analytics";
	static final String lockName = "JHtmlToPdf.lck";
	static GlobalProperties cmd = Utility.getProperties();
	static DbHelperDataSource db = new DbHelperDataSource(cmd, dbsource);
	
	protected static final Logger logger = Logger.getLogger(JHtmlToPdf.class);
	
	public static void main(String[] commandLineArguments) throws Exception {
		boolean gotLock = true;
		
		request = parseCommandLineArgs(commandLineArguments);
		
		addRequestToQueue(request);
		
		gotLock = Utility.getLock(lockName);
		if (!gotLock) {
			logger.info("Cannot get lock.  Process already running.  Exiting");
			// Another process will process our request
			return;
		}
		try {
			// Process all pending request
			while ((request = getNextPendingRequest()) != null) {
				processRequest(request);
			}
		} catch (Throwable t) {
			Utility.handleError(cmd, t);
		} finally {
			if (gotLock)
				Utility.releaseLock(lockName);
		}
	}

	private static void addRequestToQueue(HtmlToPdfRequest request) throws ClassNotFoundException, IllegalAccessException, InstantiationException, UnknownHostException, SQLException {
		// Insert request for pdf processing in database fifo queue
		request.setId(db.executeInsert("insert into jhtmltopdf_queue values ("
				+ "null,"
				+ "'" + InetAddress.getLocalHost().getHostName() + "',"
				+ "utc_timestamp(),"
				+ "null,"
				+ "'" + request.getWkHtmlToPdf().replace("\\", "\\\\") + "',"
				+ "'" + request.getWkHtmlToPdfOpt().replace("\\", "\\\\") + "',"
				+ "'" + request.getWebpage().replace("\\", "\\\\") + "',"
				+ "'" + request.getPdfFile().replace("\\", "\\\\") + "',"
				+ "false,"
				+ "0)"));		
	}
	
	

	private static HtmlToPdfRequest getNextPendingRequest() throws ClassNotFoundException, IllegalAccessException, InstantiationException, UnknownHostException, SQLException {
		ResultSet rs = db.executeSelect("select * from jhtmltopdf_queue where CreatedBy='" + InetAddress.getLocalHost().getHostName() + "' and processed=0 order by CreatedTimestamp asc limit 1", -1);
		while(rs.next()) {
			HtmlToPdfRequest request = new HtmlToPdfRequest();
			request.setId(rs.getInt("Id"));
			request.setWkHtmlToPdf(rs.getString("wkhtmltopdf_exe"));
			request.setWkHtmlToPdfOpt(rs.getString("wkhtmltopdf_opt"));
			request.setWebpage(rs.getString("webpage"));
			request.setPdfFile(rs.getString("pdfFileName"));
			
			return request;
		}
		return null;
	}
	
	private static void processRequest(HtmlToPdfRequest request) throws ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException {
		try {
			// Call wkhtmltopdf to create pdf with Fresh Data
			Runtime rt = Runtime.getRuntime();
			String cmdString = request.getWkHtmlToPdf() + " " + request.getWkHtmlToPdfOpt() + " " + request.getWebpage() + " " + request.getPdfFile();
			Process proc = rt.exec(cmdString);
			int retCode = proc.waitFor();
			if(retCode==0)
				markRequstAsProcessed(request);
			
		} catch (IOException ioe) {
			Utility.handleError(cmd, ioe);
		} catch (InterruptedException ie) {
			Utility.handleError(cmd, ie);
		} catch (Exception e) {
			e.printStackTrace();
		}
	};
	
	private static void markRequstAsProcessed(HtmlToPdfRequest request) throws ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException {
		db.executeStatement("update jhtmltopdf_queue set processed=1, processedTimestamp = utc_timestamp() where id=" + request.getId());
	}
	
	public static HtmlToPdfRequest parseCommandLineArgs(final String[] commandLineArguments) throws Exception {
		logger.debug(commandLineArguments.toString());
		HtmlToPdfRequest request = new HtmlToPdfRequest();
		final CommandLineParser cmdLineGnuParser = new GnuParser();
		final Options gnuOptions = constructGnuOptions();
		CommandLine commandLine;
		try {
			commandLine = cmdLineGnuParser.parse(gnuOptions, commandLineArguments);
			
			if (commandLine.hasOption("wkHtmlToPdf_exe")) 
				request.setWkHtmlToPdf(commandLine.getOptionValue("wkHtmlToPdf_exe"));
			else 
				request.setWkHtmlToPdf("C:\\Progra~2\\wkhtmltopdf\\bin\\wkhtmltopdf.exe");
			if (commandLine.hasOption("wp")) 
				 request.setWebpage(commandLine.getOptionValue("wp"));
			if (commandLine.hasOption("wkHtmlToPdf_opt")) 
				request.setWkHtmlToPdfOpt(commandLine.getOptionValue("wkHtmlToPdf_opt"));
			else 
				request.setWkHtmlToPdfOpt("");
			if (commandLine.hasOption("pdf")) 
				request.setPdfFile(commandLine.getOptionValue("pdf")); 
				
			if ((request.getWkHtmlToPdf() == null) || (request.getWebpage() == null) || (request.getPdfFile() == null)) {
				throw new Exception("Wrong number of parameters");
			}
		} catch (ParseException parseException) {
			logger.error("Encountered exception while parsing using GnuParser:\n" + parseException.getMessage());
			throw parseException;
		}
		
		return request; 
	}
	
	public static Options constructGnuOptions() {
		final Options gnuOptions = new Options();

		gnuOptions
		.addOption("wkHtmlToPdf_exe", "wkHtmlToPdf_exec", true, "Enter full path to wkhtmltopdf executable")
		.addOption("wp", "webpage", true, "Enter the webpage address to be converted")
		.addOption("wkHtmlToPdf_opt", "wkHtmlToPdf_options", true, "Enter wkhtmltopdf options")
		.addOption("pdf", "pdf_file", true, "Enter the full path to the pdf file to be created");

		return gnuOptions;
	}
}

class HtmlToPdfRequest {
	int id;
	String wkHtmlToPdf = null;
	String wkHtmlToPdfOpt = null;
	String webpage = null;
	String pdfFile = null;
	
	public int getId() {
		return id;
	}
	public void setId(int id) {
		this.id = id;
	}
	public String getWkHtmlToPdf() {
		return wkHtmlToPdf;
	}
	public void setWkHtmlToPdf(String wkHtmlToPdf) {
		this.wkHtmlToPdf = wkHtmlToPdf;
	}
	public String getWkHtmlToPdfOpt() {
		return wkHtmlToPdfOpt;
	}
	public void setWkHtmlToPdfOpt(String wkHtmlToPdfOpt) {
		this.wkHtmlToPdfOpt = wkHtmlToPdfOpt;
	}
	public String getWebpage() {
		return webpage;
	}
	public void setWebpage(String webpage) {
		this.webpage = webpage;
	}
	public String getPdfFile() {
		return pdfFile;
	}
	public void setPdfFile(String pdfFile) {
		this.pdfFile = pdfFile;
	}
	
}
