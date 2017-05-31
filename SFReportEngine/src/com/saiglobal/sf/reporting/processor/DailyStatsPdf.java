package com.saiglobal.sf.reporting.processor;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.URL;
import java.net.URLConnection;
import java.util.Date;

import com.saiglobal.sf.core.utility.Utility;

public class DailyStatsPdf extends AbstractQueryReport {

	public DailyStatsPdf() {
		super();
		setExecuteStatement(true);
	}

	@Override
	protected void initialiseQuery() throws Throwable {
		String reportFileName = gp.getReportFolder() + "\\DailyStats\\DailyStats";

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
			URL apiAddress = new URL("http://ausydhq-cotap06:8080/Reporting/dailyStats?forceRefresh=true");
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
			String cmdString = "C:\\Progra~2\\wkhtmltopdf\\bin\\wkhtmltopdf.exe -O Portrait --debug-javascript --javascript-delay 120000 http://ausydhq-cotap06:8080/Reporting/DailyStatsForA4PrintingPortrait.html " + reportFileName;
			//String cmdString = "C:\\Progra~1\\wkhtmltopdf\\bin\\wkhtmltopdf.exe -O Portrait http://ausydhq-cotap06:8080/Reporting/DailyStatsForA4PrintingPortrait.html " + reportFileName;
			Process proc = rt.exec(cmdString);
			proc.waitFor();
		} catch (Throwable t) {
			throw t;
		}

		try {
			// Email report
			Utility.email(gp, "Emailing DailyStats ",
					"Please find attached Daily Stats",
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
