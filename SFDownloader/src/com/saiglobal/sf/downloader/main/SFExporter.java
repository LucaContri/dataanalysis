package com.saiglobal.sf.downloader.main;

import java.nio.file.Files;
import java.nio.file.Paths;

import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.GnuParser;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException;
import org.apache.log4j.Logger;

import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.TaskProperties;
import com.saiglobal.sf.core.utility.Utility;
import com.saiglobal.sf.downloader.data.DbHelper;

public class SFExporter {

	private static final Logger logger = Logger.getLogger(SFExporter.class);
	public static String taskName = "sfdownloader";
	public static void main(final String[] commandLineArguments) {
		boolean gotLock = true;
		String lockName = "";
		try {
			Utility.startTimeCounter("SFExporter");
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
			
			logger.info("Starting SAI Global - Salesforce data exporter on database " + properties.getCurrentDataSource());
			
			lockName = "SFExporter." + properties.getSfUser() + ".lck";
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
				DbHelper dbHelper=new DbHelper(properties);
				Files.createDirectories(Paths.get(properties.getReportFolder() + "/export/"));
				for (String table : dbHelper.getIncludedObjects()) {
					/*
					 Files.write(Paths.get(properties.getReportFolder() + "/export/" + properties.getCurrentDataSource() + "." + table + ".csv"),
						     (Iterable<String>)Utility.resultSetToStringStream(dbHelper.executeSelect("select * from `" + table + "`", -1))::iterator,
						     StandardOpenOption.CREATE,
					         StandardOpenOption.TRUNCATE_EXISTING);
					 */
					Files.deleteIfExists(Paths.get(properties.getReportFolder() + "/export/" + properties.getCurrentDataSource() + "." + table + ".csv"));
					String cmd = "SELECT * INTO OUTFILE '" + properties.getReportFolder() + "/export/" + properties.getCurrentDataSource() + "." + table + ".csv' "
							+ "FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' "
							+ "LINES TERMINATED BY '\n' "
							+ "FROM `" + table + "`";
					logger.info("Exporting " + properties.getReportFolder() + "/export/" + properties.getCurrentDataSource() + "." + table + ".csv'");
					logger.info(cmd);
					dbHelper.executeSelect(cmd,-1);
					
				}
				logger.info("Total processing time (ms):" + Utility.getTimeCounterMS("SFExporter"));
				//Utility.logAllProcessingTime();
			} else {
				logger.info("Salesforce data exporter not enabled");
			}
		} catch (Exception e) {
			Utility.handleError(Utility.getProperties(), e);
		} finally {			
			if (gotLock)
				Utility.releaseLock(lockName);
			logger.info("Finished SAI Global - Salesforce data exporter");
		}
	}
	
	public static Options constructGnuOptions() {
		final Options gnuOptions = new Options();

		gnuOptions
		.addOption("propertyFile", "property file", true, "property file");

		return gnuOptions;
	}
}
