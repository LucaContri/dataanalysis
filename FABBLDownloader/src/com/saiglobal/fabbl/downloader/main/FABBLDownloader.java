package com.saiglobal.fabbl.downloader.main;

import java.io.File;
import java.io.FileOutputStream;
import java.nio.file.Files;

import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.GnuParser;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException;
import org.apache.log4j.Logger;

import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.TaskProperties;
import com.saiglobal.sf.core.utility.Utility;
import com.saigol.fabbl.downloader.data.DbHelperDataSource;

public class FABBLDownloader {

	private static final Logger logger = Logger.getLogger(FABBLDownloader.class);
	private static String taskName = "fabbldownloader";
	private static DbHelperDataSource db;
	private static GlobalProperties properties = null;
	
	public static void main(final String[] commandLineArguments) {
		boolean gotLock = true;
		String lockName = "";
		
		try {
			Utility.startTimeCounter(taskName);
			final Options gnuOptions = constructGnuOptions();
			final CommandLineParser cmdLineGnuParser = new GnuParser();
			try {
				CommandLine commandLine = cmdLineGnuParser.parse(gnuOptions, commandLineArguments);
				if (commandLine.hasOption("propertyFile"))
					properties = Utility.getProperties(commandLine.getOptionValue("propertyFile"));
				
			} catch (ParseException e) {
				logger.error("Using default property file");
			}
				
			if (properties == null)
				properties = GlobalProperties.getDefaultInstance();
			
			logger.info("Starting SAI Global - FABBL data downloader");
			
			lockName = FABBLDownloader.class.getCanonicalName();
			gotLock = Utility.getLock(lockName);
			if (!gotLock) {
				logger.info("Cannot get lock.  Process already running.  Exiting");
				return;
			}
			
			properties.setCurrentTask(taskName);
			properties.printArguments();
			
			TaskProperties taskProperties = properties.getTaskProperties();
			if (taskProperties == null) {
				taskProperties = new TaskProperties();
				taskProperties.setName(taskName);
				taskProperties.setDisableIfError(false);
				taskProperties.setEmailError(true);
				taskProperties.setEnabled(true);
				properties.setTaskProperty(taskProperties);
			}
			if (taskProperties.isEnabled()) {
				// 1) Copy source to destination
				logger.info("Copying " + properties.getFABBLsourceFile() + " to " + properties.getFABBLdestinationFile());
				Utility.startTimeCounter(taskName + " - Copying DB");
				FileOutputStream os = new FileOutputStream(properties.getFABBLdestinationFile());
				File inFile = new File(properties.getFABBLsourceFile());
				Files.copy(inFile.toPath(), os);
				os.close();
				logger.info("Finished coying file");
				Utility.stopTimeCounter(taskName + " - Copying DB");
				
				db = new  DbHelperDataSource(properties);
				
				// 2) For each table to be sync
				for (String tableName : db.getFabblTablesToSync()) {
					// 2a) Update mysql copy
					db.updateMysqlTable(tableName);
				}
				
				Utility.stopTimeCounter(taskName);
				logger.debug("Successfully downloaded data from fabbl database" );
				logger.info("Total processing time (ms):" + Utility.getTimeCounterMS(taskName));
				Utility.logAllProcessingTime();
			} else {
				logger.info("Salesforce data downloader not enabled");
			}
		} catch (Exception e) {
			Utility.handleError(properties, e);
		} finally {
			if (gotLock)
				Utility.releaseLock(lockName);
		}
	}
	
	public static Options constructGnuOptions() {
		final Options gnuOptions = new Options();

		gnuOptions
		.addOption("propertyFile", "property file", true, "property file");

		return gnuOptions;
	}
}
