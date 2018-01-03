package com.saiglobal.scrapers.main;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Calendar;
import java.util.List;
import java.util.TimeZone;
import java.util.stream.Collectors;

import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.GnuParser;
import org.apache.commons.cli.Options;
import org.apache.log4j.Level;
import org.apache.log4j.Logger;

import com.saiglobal.scrapers.model.CertifiedOrganisation;
import com.saiglobal.scrapers.model.ProcessorOutput;
import com.saiglobal.scrapers.processors.ProcessorDetails;
import com.saiglobal.scrapers.processors.ScraperProcessor;
import com.saiglobal.sf.core.data.DbHelper;
import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;

public class CertifiedOrganisationScraper {
	protected static Logger logger = null;

	protected static GlobalProperties cmd = null;
	public static String taskName = "scraper";
	private static ScraperProcessor processor = null;
	private static DbHelper db = null;
	private static final long sleepMilliSeconds = 3000;
	private static Throwable e = null;
	/**
	 * Apply Apache Commons CLI GnuParser to command-line arguments.
	 * 
	 * @param commandLineArguments
	 *            Command-line arguments to be processed with Gnu-style parser.
	 */
	public static GlobalProperties parseCommandLineArgs(
			final String[] commandLineArguments, GlobalProperties properties)
			throws Exception {
		// logger.debug(commandLineArguments.toString());
		final CommandLineParser cmdLineGnuParser = new GnuParser();
		final Options gnuOptions = constructGnuOptions();
		CommandLine commandLine;

		commandLine = cmdLineGnuParser.parse(gnuOptions, commandLineArguments);

		if (commandLine.hasOption("p"))
			properties.setScraperProcessor(commandLine.getOptionValue("p"));

		if (commandLine.hasOption("logLevel")) {
			properties.getTaskProperties().setLogLevel(
					Level.toLevel(commandLine.getOptionValue("logLevel"),
							Level.INFO));
		}

		return properties;

	}

	/**
	 * Construct and provide GNU-compatible Options.
	 * 
	 * @return Options expected from command-line of GNU form.
	 */
	public static Options constructGnuOptions() {
		final Options gnuOptions = new Options();

		gnuOptions
				.addOption("p", "processor", true, "Enter the processor class")
				.addOption("propertyFile", "property file", true,
						"property file")
				.addOption("logLevel", "logLevel", true, "logLevel");

		return gnuOptions;
	}

	protected static void init(String[] commandLineArguments) throws Exception {
		// Initialisation
		final Options gnuOptions = constructGnuOptions();
		final CommandLineParser cmdLineGnuParser = new GnuParser();

		CommandLine commandLine = cmdLineGnuParser.parse(gnuOptions,commandLineArguments);
		if (commandLine.hasOption("propertyFile"))
			cmd = Utility.getProperties(commandLine.getOptionValue("propertyFile"));

		if (cmd == null)
			cmd = GlobalProperties.getDefaultInstance();

		cmd.setCurrentTask(taskName);
		cmd = parseCommandLineArgs(commandLineArguments, cmd);
		cmd.setCurrentDataSource("webscrapers");
		
		db = new DbHelper(cmd);
	}

	public static void main(String[] commandLineArguments) throws ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException {
		boolean gotLock = false;
		try {
			init(commandLineArguments);

			// Instantiate Processor Class
			if (cmd.getScraperProcessor() == null || cmd.getScraperProcessor().equalsIgnoreCase(""))
				throw new Exception("Missing Processor Class.  Please specify as Command Line Parameter -p ...");
			Class<?> processorClass = Class.forName(cmd.getScraperProcessor());
			processor = (ScraperProcessor) processorClass.newInstance();
			
			logger = Logger.getLogger(CertifiedOrganisationScraper.class);
			if (cmd.getTaskProperties() != null && cmd.getTaskProperties().getLogLevel() != null)
				logger.setLevel(cmd.getTaskProperties().getLogLevel());
			
			logger.info("Starting SAI global - Certified Organisation Scraper - " + processor.getClass().getCanonicalName());
			Utility.startTimeCounter(processor.getClass().getCanonicalName());
			
			gotLock = Utility.getLock(processor.getClass().getName());

			if (!gotLock) {
				logger.info("Cannot get lock.  Process already running.  Exiting");
				return;
			}
			// Init processor
			processor.init(cmd, db);
			
			if (processor.getDetails().getSource() == null
					|| processor.getDetails().getSource().equalsIgnoreCase("")
					|| processor.getDetails().getId() == null
					|| processor.getDetails().getId().equalsIgnoreCase(""))
				throw new Exception(
						"Processor not initialised properly.  Missing Source and/or Processor Id");

			// Check if there is a processor that did not terminate the task
			// ... if so start this processor from last page fetched.
			boolean fullScrape = false;
			ProcessorDetails lastIncompletedDetails = getLastIncompletedProcessorDetails(processorClass);
			if (lastIncompletedDetails != null) {
				processor.getDetails().setPage(lastIncompletedDetails.getPage());
			} else {
				fullScrape = true;
			}
			
			// Save processor details in log
			updateProcessorDetails(processor.getDetails());
			
			ProcessorOutput processorOutput = processor.getCertifiedOrganisations();
			
			while (processorOutput != null && processorOutput.getList() != null && processorOutput.getList().size() > 0) {
				updateDatabase(processorOutput.getList());
				updateProcessorDetails(processor.getDetails());
				if (processorOutput.getNextPage() != null) {
					processor.getDetails().setPage(processorOutput.getNextPage());
					Thread.sleep(sleepMilliSeconds);
					processorOutput = processor.getCertifiedOrganisations();
				} else {
					processorOutput = null;
					processor.getDetails().setCompleted(true);
				}
			}
			
			/* If processor finishes without any exceptions 
			 * and it started from first page 
			 * anything that was not updated is assumed as deleted
			 */
			if(fullScrape)
				markAsDeleted(processor.getDetails().getId());

			Utility.startTimeCounter(processor.getClass().getCanonicalName());
			Utility.logAllEventCounter();
			Utility.logAllProcessingTime();
			logger.info("Finished SAI global - Certified Organisation Scraper - " + processor.getClass().getCanonicalName());

		} catch (Throwable ae) {
			Utility.handleError(cmd, ae,"Exception in scraper: " + cmd.getScraperProcessor());
			e = ae;
		} finally {
			if (gotLock) {
				if(e != null)
					processor.getDetails().setException(e.toString());
				processor.getDetails().setEnd(Calendar.getInstance(TimeZone.getTimeZone("UTC")));
				updateProcessorDetails(processor.getDetails());
			}
			
			if (db != null)
				db.closeConnection();
			
			if (gotLock)
				Utility.releaseLock(processor.getClass().getName());
		}
	}

	private static ProcessorDetails getLastIncompletedProcessorDetails(Class<?> c) throws ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException {
		ProcessorDetails lastProcessor = getLastProcessorDetails(c);
		if (lastProcessor == null || lastProcessor.isCompleted()) 
			return null;
		else 
			return lastProcessor;
	}
	
	private static ProcessorDetails getLastProcessorDetails(Class<?> c) throws ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException {
		ProcessorDetails retValue = null;
		ResultSet rs = db.executeSelect("SELECT * from scrapers_log where class = '" + c.getCanonicalName() + "' order by `start` desc limit 1", -1);
		while (rs.next()) {
			retValue = new ProcessorDetails();
			retValue.setCompleted(rs.getBoolean("completed"));
			if (rs.getDate("end") != null) {
				retValue.setEnd(Calendar.getInstance());
				retValue.getEnd().setTime(rs.getDate("end"));
			}
			retValue.setException(rs.getString("exception"));
			retValue.setId(rs.getString("id"));
			retValue.setPage(rs.getString("page"));
			retValue.setProcessorClass(rs.getString("class"));
			retValue.setRecordsFetched(rs.getLong("fetched"));
			retValue.setSource(rs.getString("source"));
			if(rs.getDate("start")!=null) {
				retValue.setStart(Calendar.getInstance());
				retValue.getStart().setTime(rs.getDate("start"));
			}
			retValue.setTotalRecords(rs.getLong("totalRecords"));
			retValue.setRecordsToFetch(rs.getLong("recordsToFetch"));
		}
			
		return retValue;
	}

	public static void markAsDeleted(String processorId) throws Exception {
		if (processorId == null || processorId.equalsIgnoreCase(""))
			return;
		db.executeStatement("update certified_organisations set IsDeleted = 1 where `Source` = '"
				+ processor.getDetails().getSource()
				+ "' and Id in (select Id from certified_organisations where `Source` = '"
				+ processor.getDetails().getSource()
				+ "' and processorId not in ('"
				+ processor.getDetails().getId() + "'))");
	}

	public static void updateDatabase(List<CertifiedOrganisation> cos) throws Exception {
		if(cos == null || cos.size()==0)
			return;
		
		// Track history fields
		for (String fieldName : processor.getTrackHistoryFields()) {
			String insert = "INSERT INTO certified_organisations_history " +
				cos.stream()
					.filter(co -> co != null)
					.map(co -> "(select "
						+ Utility.clean(processor.getDetails().getSource())
						+ ","
						+ Utility.clean(co.getId())
						+ ","
						+ Utility.clean(fieldName)
						+ ",utc_timestamp()"
						+ ", (SELECT " + fieldName + " FROM certified_organisations where Id=" + Utility.clean(co.getId()) + ") "
						+ ","
						+ Utility.clean(co.getField(fieldName)) + ","
						+ Utility.clean(processor.getDetails().getId())
						+ " from certified_organisations where"
						+ " Id=" + Utility.clean(co.getId())
						+ " and CertificationBody not in (" + Utility.clean(co.getField(fieldName)) + "))")
					.collect(Collectors.joining(" UNION "));
			logger.debug(insert);
			db.executeStatement(insert);
		}
		
		String	update = "INSERT INTO certified_organisations " +
		cos.stream()
			.filter(co -> co != null)
			.map(co -> "select "
				+ Utility.clean(processor.getDetails().getSource())
				+ ","
				+ Utility.clean(co.getId())
				+ ","
				+ Utility.clean(co.getStatus())
				+ ","
				+ Utility.clean(co.getCompanyName())
				+ ","
				+ Utility.clean(co.getContact())
				+ ","
				+ Utility.clean(co.getContactEMail())
				+ ","
				+ Utility.clean(co.getContactPhone())
				+ ","
				+ Utility.clean(co.getContactFax())
				+ ","
				+ Utility.clean(co.getCommercialContact())
				+ ","
				+ Utility.clean(co.getCommercialContactEmail())
				+ ","
				+ Utility.clean(co.getCommercialContactPhone())
				+ ","
				+ Utility.clean(co.getAddress())
				+ ","
				+ Utility.clean(co.getCity())
				+ ","
				+ Utility.clean(co.getPostCode())
				+ ","
				+ Utility.clean(co.getRegionState())
				+ ","
				+ Utility.clean(co.getLatitude())
				+ ","
				+ Utility.clean(co.getLongitude())
				+ ","
				+ Utility.clean(co.getCountry())
				+ ","
				+ Utility.clean(co.getPhone())
				+ ","
				+ Utility.clean(co.getFax())
				+ ","
				+ Utility.clean(co.getEmail())
				+ ","
				+ Utility.clean(co.getWebsite())
				+ ","
				+ Utility.clean(co.getGrade())
				+ ","
				+ Utility.clean(co.getScope())
				+ ","
				+ Utility.clean(co.getExclusion())
				+ ","
				+ Utility.clean(co.getCertificationBody())
				+ ","
				+ Utility.clean(co.getAuditCategory())
				+ ","
				+ Utility.clean(co.getBusinessLine())
				+ ","
				+ Utility.clean(co.getStandard())
				+ ","
				+ Utility.clean(co.getCodes())
				+ ","
				+ Utility.clean(co.getIssueDate())
				+ ","
				+ Utility.clean(co.getExpiryDate())
				+ ","
				+ Utility.clean(co.getDetailsLink())
				+ ","
				+ Utility.clean(processor.getDetails().getId())
				+ ",utc_timestamp() "
				+ ",utc_timestamp() "
				+ ","
				+ co.isDeleted())
			.collect(Collectors.joining(" UNION ")) +
		" on duplicate key update "
		+ "`status`=values(`status`) "
		+ ", `companyName`=values(`companyName`) "
		+ ", `contact`=values(`contact`) "
		+ ", `contactEMail`=values(`contactEMail`) "
		+ ", `contactPhone`=values(`contactPhone`) "
		+ ", `contactFax`=values(`contactFax`) "
		+ ", `commercialContact`=values(`commercialContact`) "
		+ ", `commercialContactEMail`=values(`commercialContactEMail`) "
		+ ", `commercialContactPhone`=values(`commercialContactPhone`) "
		+ ", `address`=values(`address`) "
		+ ", `city`=values(`city`) "
		+ ", `postCode`=values(`postCode`) "
		+ ", `regionState`=values(`regionState`) "
		+ ", `latitude`=values(`latitude`) "
		+ ", `longitude`=values(`longitude`) "
		+ ", `country`=values(`country`) "
		+ ", `phone`=values(`phone`) "
		+ ", `fax`=values(`fax`) "
		+ ", `email`=values(`email`) "
		+ ", `website`=values(`website`) "
		+ ", `grade`=values(`grade`) "
		+ ", `scope`=values(`scope`) "
		+ ", `exclusion`=values(`exclusion`) "
		+ ", `certificationBody`=values(`certificationBody`) "
		+ ", `auditCategory`=values(`auditCategory`) "
		+ ", `businessLine`=values(`businessLine`) "
		+ ", `standard`=values(`standard`) "
		+ ", `codes`=values(`codes`) "
		+ ", `issueDate`=values(`issueDate`) "
		+ ", `expiryDate`=values(`expiryDate`) "
		+ ", `detailsLink`=values(`detailsLink`) "
		+ ", `processorId`=values(`processorId`) "
		+ ", `lastUpdated`=values(`lastUpdated`) "
		+ ", `isDeleted`=values(`isDeleted`) ";
			
		logger.debug(update);
		db.executeStatement(update);	
	}
	
	private static void updateProcessorDetails(ProcessorDetails details) throws ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException {
		if (details == null) 
			return;
		String update = "INSERT INTO scrapers_log values ("
				+ Utility.clean(details.getSource())
				+ ","
				+ Utility.clean(details.getId())
				+ ","
				+ Utility.clean(details.getProcessorClass())
				+ ","
				+ Utility.clean(details.getStart())
				+ ","
				+ Utility.clean(details.getEnd())
				+ ","
				+ Utility.clean(details.getPage())
				+ ","
				+ Utility.clean(details.getTotalRecords())
				+ ","
				+ Utility.clean(details.getRecordsToFetch())
				+ ","
				+ Utility.clean(details.getRecordsFetched())
				+ ","
				+ details.isCompleted()
				+ ","
				+ Utility.clean(details.getException())
				+ ") "
				+ "on duplicate key update "
				+ "`end`=values(`end`) "
				+ ", `page`=values(`page`) "
				+ ", `totalRecords`=values(`totalRecords`) "
				+ ", `recordsToFetch`=values(`recordsToFetch`) "
				+ ", `fetched`=values(`fetched`) "
				+ ", `completed`=values(`completed`) "
				+ ", `exception`=values(`exception`)";
	
		db.executeStatement(update);
	}
}
