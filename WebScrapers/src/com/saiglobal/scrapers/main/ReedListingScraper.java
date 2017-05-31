package com.saiglobal.scrapers.main;

import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.net.URL;
import java.security.NoSuchAlgorithmException;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.HashMap;
import java.util.List;

import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.GnuParser;
import org.apache.commons.cli.Options;
import org.apache.log4j.Logger;
import org.jsoup.Connection;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;

import com.saiglobal.sf.core.data.DbHelperDataSource;
import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;

public class ReedListingScraper {
	private static final GlobalProperties p = Utility.getProperties("/mnt/disk/SAI/properties/pi.config.properties");
	private static final DbHelperDataSource db = new DbHelperDataSource(p);
	private static String search_page = "http://www.reed.co.uk/jobs/";
	private static final int read_timeout = 30000;
	private static final int maxTries = 3;
	private static final int sleepMin = 5000;
	private static final int sleepVar= 5000;
	private static final Logger logger = Logger.getLogger(ReedListingScraper.class);
	private static int page = 1;
	private static String postCode = "MK18";
	private static int startSalary = 70000;
	
	static {
		// Init
		db.use("jobs");
		p.setCurrentTask("webscraper");
	}
	

	/**
	 * Construct and provide GNU-compatible Options.
	 * 
	 * @return Options expected from command-line of GNU form.
	 */
	public static Options constructGnuOptions() {
		final Options gnuOptions = new Options();

		gnuOptions
		.addOption("sp", "start-page", true, "Enter the start page default 0")
		.addOption("pc", "post-code", true, "Enter the post code default MK18")
		.addOption("ms", "min-salary", true, "Enter the min salary default 70k");
		
		return gnuOptions;
	}
	
	public static void main(String[] commandLineArguments) throws Exception {
		// Parse Arguments
		final Options gnuOptions = constructGnuOptions();
		final CommandLineParser cmdLineGnuParser = new GnuParser();
		try {
		CommandLine commandLine = cmdLineGnuParser.parse(gnuOptions, commandLineArguments);
		if(commandLine.hasOption("sp"))
			page = Integer.parseInt(commandLine.getOptionValue("sp"));
		if(commandLine.hasOption("pc"))
			postCode = commandLine.getOptionValue("pc");
		if(commandLine.hasOption("ms"))
			startSalary = Integer.parseInt(commandLine.getOptionValue("ms"));
		} catch (Exception e) {
			logger.error("Error parsing command line arguments.  Using defaults");
		}
		search_page+=postCode + "?cached=True&proximity=50&pagesize=100&datecreatedoffset=Today&isnewjobssearch=True&salaryfrom=" + startSalary;

		try {
			List<HashMap<String, Object>> scraped = null;
			while ((scraped = scrapePosting()) != null) {
				page++;
				for (HashMap<String, Object> listing : scraped) {
					updateDb(listing);
				}
				int sleep = (int) (sleepMin + Math.random()*sleepVar);
				Thread.sleep(sleep);
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
	
	private static void updateDb(HashMap<String, Object> listing) throws ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException, NoSuchAlgorithmException, UnsupportedEncodingException {
		String update = "insert into listing_reed values ("
				+ clean(listing.get("id")) 
				+ ", " + clean(listing.get("title"))
				+ ", " + clean(listing.get("link"))
				+ ", " + clean(listing.get("postedDate"))
				+ ", " + clean(listing.get("postedBy"))
				+ ", " + clean(listing.get("location"))
				+ ", " + clean(listing.get("type"))
				+ ", " + clean(listing.get("applications")) 
				+ ", " + clean(listing.get("salary"))
				+ ", " + clean(null)
				+ ", " + clean(null)
				+ ", utc_timestamp() "
				+ ", utc_timestamp(), false ) "
			+ " on duplicate key update "
				+ "`applications`=values(`applications`) "
				+ ", `LastUpdated`=values(`lastUpdated`)";
	
			db.executeStatement(update);
	}
	
	private static String clean(Object i) {
		if (i==null)
			return "null";
		if ((i instanceof Integer) || ((i instanceof Double)) || (i instanceof Float))
			return i.toString();
		if (i instanceof Calendar)
			return "'" + Utility.getMysqldateformat().format(((Calendar)i).getTime()) + "'";
		if(i instanceof String) {
			if (((String)i).equalsIgnoreCase(""))
				return "null";
			else
				return "'" + ((String)i).replace("\\","").replace("'", "\\'").trim() + "'";
		}
		return "'" + i.toString().replace("\\","").replace("'", "\\'") + "'";
	}
	
	private static Document getPage(String address) throws IOException, InterruptedException {
		boolean retry = true;
		int tryNo = 1;
		Document retValue = null;
		while (retry) {
			try {
				logger.info("Fetching page: " + address + ". Try no. " + tryNo);
				Connection conn = Jsoup.connect(address).timeout(read_timeout);
				retValue = conn.get();
				retry = false;
			} catch (IOException ioe) {
				logger.error("Error in fetching page: " + address);
				if (tryNo<maxTries) {
					tryNo++;
					Thread.sleep(sleepMin);
				} else {
					throw ioe;
				}
			}
		}
		return retValue;
	}
	
	private static List<HashMap<String, Object>> scrapePosting() throws Exception {
		if(search_page==null)
			return null;
		List<HashMap<String, Object>> retValue = new ArrayList<HashMap<String, Object>>();
		URL address = new URL(search_page+"&pageno="+page);
		Document doc = null;
		doc = getPage(address.toString());

		if (doc != null) {
			Elements jobResults = doc.select("article.job-result");
			if (jobResults!=null && jobResults.size()>0) {
				for (Element jobResult : jobResults) {
					
					try {
						String id = jobResult.getElementsByClass("job-result-anchor").first().attr("id").replace("job", "").trim();
						HashMap<String, Object> listing = new HashMap<String, Object>();
						listing.put("link", jobResult.getElementsByClass("title").first().select("a").attr("href").split("#")[0].trim());
						listing.put("id", id);
						listing.put("title", jobResult.getElementsByClass("title").first().text());
						listing.put("postedBy", jobResult.getElementsByClass("posted-by").first().select("a").first().text());
						listing.put("postedDate", Calendar.getInstance()); // Today
						listing.put("location", jobResult.getElementsByClass("location").first().text());
						listing.put("type", jobResult.getElementsByClass("time").first().text());
						listing.put("salary", jobResult.getElementsByClass("salary").first().text());
						listing.put("applications", Integer.parseInt(jobResult.getElementsByClass("applications").first().text().replace("applications", "").replace("application", "").trim()));
						retValue.add(listing);
					} catch (Exception e) {
						e.printStackTrace();
					}
				}
			}
		}
		if (retValue.size()==0) { 
			//logger.info(doc.toString());
			return null;
		}
		
		return retValue;
	}
}