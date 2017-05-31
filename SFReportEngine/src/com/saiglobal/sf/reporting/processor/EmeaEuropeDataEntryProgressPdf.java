package com.saiglobal.sf.reporting.processor;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.URL;
import java.net.URLConnection;
import java.util.Date;

import com.saiglobal.sf.core.utility.Utility;

public class EmeaEuropeDataEntryProgressPdf extends AbstractQueryReport {

	public EmeaEuropeDataEntryProgressPdf() {
		super();
		setExecuteStatement(true);
	}

	@Override
	protected void initialiseQuery() {
		String reportFileName = gp.getReportFolder() + "\\EMEA\\DataEntryProgress\\DataEntryProgressEurope";

		// Generate Report
		try {
			if (gp.isIncludeTimeInName()) {
				reportFileName += "."
						+ Utility.getActivitydateformatter().format(new Date())
						+ ".pdf";
			} else {
				reportFileName += ".pdf";
			}
			
			// Force Data Refresh first
			URL apiAddress = new URL("http://ausydhq-cotap06:8080/Reporting/EmeaEuropeCompassProgressForPrinting.html");
			URLConnection connection = apiAddress.openConnection();
			BufferedReader in = new BufferedReader(new InputStreamReader(
					connection.getInputStream()));
			while (in.readLine() != null) {
			}
			in.close();

			// Wait
			Thread.sleep(200000);
						
			// Call wkhtmltopdf to create pdf with Fresh Data
			Runtime rt = Runtime.getRuntime();
			String cmdString = "C:\\Progra~2\\wkhtmltopdf\\bin\\wkhtmltopdf.exe -O Portrait --javascript-delay 120000 --print-media-type http://ausydhq-cotap06:8080/Reporting/EmeaEuropeCompassProgressForPrinting.html " + reportFileName;
			//String cmdString = "C:\\Progra~1\\wkhtmltopdf\\bin\\wkhtmltopdf.exe -O Portrait http://ausydhq-cotap06:8080/Reporting/EmeaEuropeCompassProgressForPrinting.html " + reportFileName;
			Process proc = rt.exec(cmdString);
			proc.waitFor();
		} catch (Throwable t) {
			Utility.handleError(gp, t);
		}

		try {
			// Email report
			Utility.email(gp, "Emailing Post Compass Roll-out Data Entry Progress Report",
					"Please find attached Post Compass Roll-out Data Entry Progress Report",
					new String[] { reportFileName });
		} catch (Exception e) {
			Utility.handleError(gp, e);
		}
		Utility.logAllProcessingTime();
	}

	@Override
	protected String getQuery() {
		return "";
	}

	@Override
	protected String getReportName() {
		return null;
	}

}
