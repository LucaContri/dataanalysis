package com.saiglobal.sf.downloader.main;

import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.GnuParser;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException;
import org.apache.log4j.Logger;

import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.TaskProperties;
import com.saiglobal.sf.core.utility.Utility;
import com.saiglobal.sf.downloader.sf.SfDownloader;

public class SFDataDuplicator {

	private static final Logger logger = Logger.getLogger(SFDataDuplicator.class);
	public static String taskName = "sfdownloader";
	public static void main(final String[] commandLineArguments) {
		boolean gotLock = true;
		String lockName = "";
		try {
			Utility.startTimeCounter("SFDataDuplicator");
			GlobalProperties properties = null;
			final Options gnuOptions = constructGnuOptions();
			final CommandLineParser cmdLineGnuParser = new GnuParser();
			try {
				CommandLine commandLine = cmdLineGnuParser.parse(gnuOptions, commandLineArguments);
				if (commandLine.hasOption("propertyFile"))
					properties = Utility.getProperties(commandLine.getOptionValue("propertyFile"));
				
			} catch (ParseException e) {
				logger.error("", e);
				logger.error("Using default property file");
			}
				
			if (properties == null)
				properties = GlobalProperties.getDefaultInstance();
			
			logger.info("Starting SAI Global - Salesforce data downloader on domain " + properties.getSfUser().split("@")[1]);
			
			lockName = "SFDataDuplicator." + properties.getSfUser() + ".lck";
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
				taskProperties.setDisableIfError(true);
				taskProperties.setEmailError(true);
				taskProperties.setEnabled(true);
				properties.setTaskProperty(taskProperties);
			}
			if (taskProperties.isEnabled()) {
				SfDownloader sfd = new SfDownloader(properties);
				sfd.execute();
				Utility.stopTimeCounter("SFDataDuplicator");
				logger.debug("Successfully downloaded data from Salesforce.com" );
				logger.info("Total processing time (ms):" + Utility.getTimeCounterMS("SFDataDuplicator"));
				//Utility.logAllProcessingTime();
			} else {
				logger.info("Salesforce data downloader not enabled");
			}
		} catch (Exception e) {
			Utility.handleError(Utility.getProperties(), e);
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
