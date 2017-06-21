package com.saiglobal.sice.downloader.main;

import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.GnuParser;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException;
import org.apache.log4j.Level;
import org.apache.log4j.Logger;

import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.TaskProperties;
import com.saiglobal.sf.core.utility.Utility;
import com.saiglobal.sice.downloader.implementation.SICEDownloader;

public class SICEDataDuplicator {

	private static final Logger logger = Logger.getLogger("com.saiglobal");
	public static String taskName = "SICEDataDuplicator";
	public static void main(final String[] commandLineArguments) {
		boolean gotLock = true;
		String lockName = "";
		try {
			Utility.startTimeCounter("SICEDataDuplicator");
			GlobalProperties propertiesSource = null;
			GlobalProperties propertiesTarget = null;
			final Options gnuOptions = constructGnuOptions();
			final CommandLineParser cmdLineGnuParser = new GnuParser();
			try {
				CommandLine commandLine = cmdLineGnuParser.parse(gnuOptions, commandLineArguments);
				if (commandLine.hasOption("propertyFile")) {
					propertiesSource = Utility.getProperties(commandLine.getOptionValue("propertyFile"));
					propertiesTarget = Utility.getProperties(commandLine.getOptionValue("propertyFile"));
				} 
			} catch (ParseException e) {
				logger.error("", e);
				logger.error("Using default property file");
			}
				
			if (propertiesSource == null) {
				propertiesSource = GlobalProperties.getDefaultInstance();
				propertiesTarget = GlobalProperties.getDefaultInstance();
			}
			try {
				CommandLine commandLine = cmdLineGnuParser.parse(gnuOptions, commandLineArguments);
				if (commandLine.hasOption("cp") && (commandLine.getOptionValue("cp")!=null)) {
					String[] pairs = commandLine.getOptionValue("cp").split(";");
					for (String pair : pairs) {
						String[] nameValue = pair.split(":");
						if ((nameValue != null) && (nameValue.length==2)) {
							propertiesSource.addCustom_property(nameValue[0], nameValue[1]);
							propertiesTarget.addCustom_property(nameValue[0], nameValue[1]);
						}		
					}
				}
				propertiesSource.setCurrentTask(taskName);
				propertiesTarget.setCurrentTask(taskName);
				
				TaskProperties taskProperties = propertiesSource.getTaskProperties();
				if (taskProperties == null) {
					taskProperties = new TaskProperties();
					taskProperties.setName(taskName);
					taskProperties.setDisableIfError(true);
					taskProperties.setEmailError(true);
					taskProperties.setEnabled(true);
					propertiesSource.setTaskProperty(taskProperties);
					propertiesTarget.setTaskProperty(taskProperties);
			
				}
				if (commandLine.hasOption("logLevel")) {
					propertiesSource.getTaskProperties().setLogLevel(Level.toLevel(commandLine.getOptionValue("logLevel"), Level.INFO));
					propertiesTarget.getTaskProperties().setLogLevel(Level.toLevel(commandLine.getOptionValue("logLevel"), Level.INFO));
				}
			} catch (ParseException e) {
				logger.error("", e);
				logger.error("Using defaults");
			}
			logger.setLevel(propertiesSource.getTaskProperties().getLogLevel());
			logger.info("Starting SAI Global - SICE data downloader");
			
			lockName = "SICEDataDuplicator.lck";
			gotLock = Utility.getLock(lockName);
			if (!gotLock) {
				logger.info("Cannot get lock.  Process already running.  Exiting");
				return;
			}
			if (propertiesSource.getTaskProperties().isEnabled()) {
				SICEDownloader downloader = new SICEDownloader(propertiesSource, propertiesTarget);
				downloader.execute();
				Utility.stopTimeCounter("SICEDataDuplicator");
				logger.debug("Successfully downloaded data from SICE" );
				logger.info("Total processing time (ms):" + Utility.getTimeCounterMS("SICEDataDuplicator"));
			} else {
				logger.info("SICE downloader not enabled");
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
		.addOption("propertyFile", "property file", true, "property file")
		.addOption("cp", "Custom Properties", true, "name1:value1;name2:value2;name3:value3... semicolumn separated pairs of column separated property name and value")
		.addOption("logLevel", "logLevel", true, "logLevel");

		return gnuOptions;
	}

}
