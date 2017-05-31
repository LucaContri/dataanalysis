package com.saiglobal.sf.allocator.main;


import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.GnuParser;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException;
import org.apache.log4j.Level;
import org.apache.log4j.Logger;

import com.saiglobal.sf.allocator.data.DbHelper;
import com.saiglobal.sf.allocator.implementation.Allocator;
import com.saiglobal.sf.allocator.processor.Processor;
import com.saiglobal.sf.core.model.ScheduleParameters;
import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;

public class ResourceAllocator {
	private static Logger logger = Logger.getLogger("com.saiglobal");
	public static String taskName = "sfallocator";
	private static GlobalProperties cmd = null;
	
	public static GlobalProperties parseCommandLineArgs(final String[] commandLineArguments, GlobalProperties properties) throws Exception {
		logger.debug(commandLineArguments.toString());
		final CommandLineParser cmdLineGnuParser = new GnuParser();
		final Options gnuOptions = constructGnuOptions();
		CommandLine commandLine;
		try {
			commandLine = cmdLineGnuParser.parse(gnuOptions, commandLineArguments);
			
			if (commandLine.hasOption("ai")) 
				properties.setAllocatorImplementationClass(commandLine.getOptionValue("ai"));
			if (commandLine.hasOption("re")) 
				properties.setReportEmails(commandLine.getOptionValue("re"));
			if (commandLine.hasOption("includePipeline")) 
				properties.setIncludePipeline(commandLine.getOptionValue("includePipeline"));
			if (commandLine.hasOption("scoreAvailabilityDayReward")) 
				properties.setScoreAvailabilityDayReward(commandLine.getOptionValue("scoreAvailabilityDayReward"));
			if (commandLine.hasOption("scoreCapabilityAuditPenalty")) 
				properties.setScoreCapabilityAuditPenalty(commandLine.getOptionValue("scoreCapabilityAuditPenalty"));
			if (commandLine.hasOption("scoreContractorPenalties")) 
				properties.setScoreContractorPenalties(commandLine.getOptionValue("scoreContractorPenalties"));
			if (commandLine.hasOption("scoreDistanceKmPenalty")) 
				properties.setScoreDistanceKmPenalty(commandLine.getOptionValue("scoreDistanceKmPenalty"));
			if (commandLine.hasOption("logLevel")) {
				properties.getTaskProperties().setLogLevel(Level.toLevel(commandLine.getOptionValue("logLevel"), Level.INFO));
			}
			if (commandLine.hasOption("cp") && (commandLine.getOptionValue("cp")!=null)) {
				String[] pairs = commandLine.getOptionValue("cp").split(";");
				for (String pair : pairs) {
					String[] nameValue = pair.split(":");
					if ((nameValue != null) && (nameValue.length==2)) {
						properties.addCustom_property(nameValue[0], nameValue[1]);
					}		
				}
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
		.addOption("ai", "allocator-implementation", true, "Enter the allocator implementation class")
		.addOption("re", "report-emails", true, "Enter the email address to send the report to (comma separated")
		.addOption("cp", "Custom Properties", true, "name1:value1;name2:value2;name3:value3... semicolumn separated pairs of column separated property name and value")
		.addOption("propertyFile", "property file", true, "property file")
		.addOption("includePipeline", "includePipeline", true, "includePipeline")
		.addOption("scoreAvailabilityDayReward", "scoreAvailabilityDayReward", true, "scoreAvailabilityDayReward")
		.addOption("scoreCapabilityAuditPenalty", "scoreCapabilityAuditPenalty", true, "scoreCapabilityAuditPenalty")
		.addOption("scoreContractorPenalties", "scoreContractorPenalties", true, "scoreContractorPenalties")
		.addOption("scoreDistanceKmPenalty", "scoreDistanceKmPenalty", true, "scoreDistanceKmPenalty")
		.addOption("logLevel", "logLevel", true, "logLevel");
		
		return gnuOptions;
	}
	
	public static void main(String[] commandLineArguments) throws Exception {
		// Initialization
		final Options gnuOptions = constructGnuOptions();
		final CommandLineParser cmdLineGnuParser = new GnuParser();
		
		boolean gotLock = true;
		String lockName = null;
		
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
		
		try {
			lockName = ResourceAllocator.class.getCanonicalName() + "-" + cmd.getAllocatorImplementationClass();
			gotLock = Utility.getLock(lockName);
			if (!gotLock) {
				logger.info("Cannot get lock.  Process already running.  Exiting");
				return;
			}
			
			// Instantiate Report Builder Class
			Class<?> allocatorCalss = Class.forName(cmd.getAllocatorImplementationClass());
			Allocator allocator = (Allocator) allocatorCalss.newInstance();
			
			// Input parameters
			ScheduleParameters parameters = allocator.getParameters(cmd);
			
			// Override parameters from properties
			if (cmd.isIncludePipeline())
				parameters.setIncludePipeline(cmd.isIncludePipeline());
			if (cmd.getScoreAvailabilityDayReward()!=null) 
				parameters.setScoreAvailabilityDayReward(cmd.getScoreAvailabilityDayReward());
			if (cmd.getScoreCapabilityAuditPenalty() != null)
				parameters.setScoreCapabilityAuditPenalty(cmd.getScoreCapabilityAuditPenalty());
			if (cmd.getScoreContractorPenalties() != null)
				parameters.setScoreContractorPenalties(cmd.getScoreContractorPenalties());
			if(cmd.getScoreDistanceKmPenalty()!=null)
				parameters.setScoreDistanceKmPenalty(cmd.getScoreDistanceKmPenalty());
			
			logger.setLevel(cmd.getTaskProperties().getLogLevel());
			
			logger.info("Starting SAI global - Resource Allocator" );
			// Call Processor to do the actual scheduling/allocation of resources to WI
		
			DbHelper db = new DbHelper(cmd);
			
			long startTime = System.currentTimeMillis();
			logger.info("Starting Processor...");
			Processor processor = allocator.getProcessor(db, parameters);
			processor.execute();
			long finishTime = System.currentTimeMillis();
			logger.info("Finished processing.  Total Execution time (s): " + (finishTime-startTime)/(1000));
		} catch (Exception e) {
			logger.error("", e);
			Utility.handleError(cmd, e);
		} finally {
			if (gotLock)
				Utility.releaseLock(lockName);
		}
	}
}
