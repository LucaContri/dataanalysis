package com.saiglobal.sf.reporting.main;

import java.io.BufferedReader;
import java.io.FileWriter;
import java.io.InputStream;
import java.io.InputStreamReader;

import org.apache.commons.lang.StringUtils;

import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;


public class CustomTablesBackup extends SFReportEngine {
	
	public static void main(String[] commandLineArguments) {
		// Initialization
		try {
			init(commandLineArguments);
		} catch (Exception e) {
			logger.error("", e);
		}
		GlobalProperties tis_gp = Utility.getProperties("C:\\SAI\\Properties\\global.config.training.properties");
		String[] certification_tables = new String[] {
				"sf_data",
				"sf_data_processors", 
				"sf_report_history",
				"sf_tables",
				"saig_australian_postcodes",
				"saig_geocode_cache", 
				"saig_postcodes_to_sla4", 
				"saig_resource_utilization", 
				"saig_schedulingapi_log", 
				"saig_travel_airports"
				};
		String[] tis_tables = new String[] {
				"sf_data",
				"sf_data_processors", 
				"sf_tables",
				};
		
		String certificationCmdString = "\"\\Program Files\\MySQL\\MySQL Server 5.6\\bin\\mysqldump\" -h " + cmd.getDbHost() + " -u" + cmd.getDbUser() + " -p" + cmd.getDbPassword() + " salesforce " + StringUtils.join(certification_tables, " ");
		String certificationBackupFile = reportFolder+"Backup\\salesforce_custom_tables.sql";
		String tisCmdString = "\"\\Program Files\\MySQL\\MySQL Server 5.6\\bin\\mysqldump\" -h " + tis_gp.getDbHost() + " -u" + tis_gp.getDbUser() + " -p" + tis_gp.getDbPassword() + " salesforce " + StringUtils.join(tis_tables, " ");
		String tisBackupFile = reportFolder+"Backup\\training_custom_tables.sql";
		
		try {  
			// Call mysqldump to create backup of custom tables for certification database
            Runtime rt = Runtime.getRuntime();
            logger.info("Running cmd:" + certificationCmdString);
            Process proc = rt.exec(certificationCmdString);
            InputStreamReader isr = new InputStreamReader(proc.getInputStream());
            BufferedReader outputReader = new BufferedReader(isr);
        	FileWriter fw = new FileWriter(certificationBackupFile);
        	String line = null;
        	while ((line = outputReader.readLine()) != null) {
        		fw.write(line+"\n");
        	}
        	
            proc.waitFor();
            logger.info("Finished cmd.  Exit code:" + proc.exitValue());
            if (proc.exitValue()!=0) {
            	InputStream errorStream = proc.getErrorStream();
            	byte[] buffer = new byte[errorStream.available()];
                errorStream.read(buffer);
                logger.error(new String(buffer));
                Utility.handleError(cmd, new Exception("Backup Error: " + new String(buffer)));
                //System.out.println(new String(buffer));
                errorStream.close();
            } else {
            	logger.info("Dumped tables: " + StringUtils.join(certification_tables, " ") + " as file " + certificationBackupFile);
            }
            
            fw.close();
            isr.close();
        	outputReader.close();
        	
        	// Call mysqldump to create backup of custom tables for tis database
        	logger.info("Running cmd:" + tisCmdString);
            proc = rt.exec(tisCmdString);
            isr = new InputStreamReader(proc.getInputStream());
            outputReader = new BufferedReader(isr);
        	fw = new FileWriter(tisBackupFile);
        	line = null;
        	while ((line = outputReader.readLine()) != null) {
        		fw.write(line+"\n");
        	}
        	
            proc.waitFor();
            logger.info("Finished cmd.  Exit code:" + proc.exitValue());
            if (proc.exitValue()!=0) {
            	InputStream errorStream = proc.getErrorStream();
            	byte[] buffer = new byte[errorStream.available()];
                errorStream.read(buffer);
                logger.error(new String(buffer));
                //System.out.println(new String(buffer));
                errorStream.close();
            } else {
            	logger.info("Dumped tables: " + StringUtils.join(tis_tables, " ") + " as file " + tisBackupFile);
            }
            
            fw.close();
            isr.close();
        	outputReader.close();
        	
        } catch (Throwable t) {
           Utility.handleError(cmd, new Exception("Exception in Backup: " + t.getMessage()));
        }
		Utility.logAllProcessingTime();		
	}
}
