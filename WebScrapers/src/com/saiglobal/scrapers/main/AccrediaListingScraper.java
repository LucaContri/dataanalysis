package com.saiglobal.scrapers.main;

import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.net.URL;
import java.security.NoSuchAlgorithmException;
import java.sql.SQLException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
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

import com.saiglobal.scrapers.model.AccrediaCertifiedOrganisation;
import com.saiglobal.sf.core.data.DbHelperDataSource;
import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;

public class AccrediaListingScraper {
	private static final GlobalProperties p = Utility.getProperties();
	private static final DbHelperDataSource db = new DbHelperDataSource(p);
	private static String search_page = "http://www.accredia.it/ppsearch/accredia_companymask_remote.jsp?submit=analizza";
	private static final int read_timeout = 30000;
	private static final int maxTries = 3;
	private static final int sleepMin = 5000;
	private static final int sleepVar= 5000;
	private static final Logger logger = Logger.getLogger(AccrediaListingScraper.class);
	private static int page = 0;
	private static final SimpleDateFormat dateParser1 = new SimpleDateFormat("dd-MM-yyyy");
	private static final SimpleDateFormat dateParser2 = new SimpleDateFormat("dd/MM/yyyy");
	private static String[] trackHistoryFields = new String[] {"CertificationBody"};
	
	static {
		// Init
		db.use("analytics");
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
		.addOption("sp", "start-page", true, "Enter the start page default 0");
		
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
		} catch (Exception e) {
			logger.error("Error parsing command line arguments.  Using defaults");
		}
		String lockName = AccrediaListingScraper.class.getCanonicalName();
		boolean gotLock = Utility.getLock(lockName);
		
		if (!gotLock) {
			logger.info("Cannot get lock.  Process already running.  Exiting");
			return;
		}

		try {
			List<String> notNoBeDeletedId = new ArrayList<String>();
			List<AccrediaCertifiedOrganisation> scraped = null;
			while ((scraped = scrapeCertifiedOrganisations()) != null) {
				page++;
				for (AccrediaCertifiedOrganisation co : scraped) {
					// Track history fields
					/*
					for (String fieldName : trackHistoryFields) {
						if (db.executeScalarInt("select " + fieldName + "=" + clean(co.getField(fieldName)) + " from accredia_certified_organisations where Id=" + clean(co.getId()))<=0) {
							db.executeStatement(
									"INSERT INTO accredia_certified_organisations_history values ("
									+ clean(co.getId())
									+ "," + clean(fieldName)
									+ ",utc_timestamp()"
									+ ", (SELECT " + fieldName + " FROM accredia_certified_organisations where Id=" + clean(co.getId()) + ")"
									+ "," + clean(co.getField(fieldName)) + ")"
									);
						}
					}
					*/
					// Update database
					updateDb(co);
					// Remove not to be deleted
					notNoBeDeletedId.add(""+co.getId());
				}
				int sleep = (int) (sleepMin + Math.random()*sleepVar);
				Thread.sleep(sleep);
			}
			// Mark not updated as deleted
			//db.executeStatement("update accredia_certified_organisations set IsDeleted=1 where Id not in ('" + StringUtils.join(notNoBeDeletedId.toArray(new String[notNoBeDeletedId.size()]), "','") + "')");
		} catch (Exception e) {
			Utility.handleError(p, e);
		} finally {
			if (gotLock)
				Utility.releaseLock(lockName);
		}
	}
	private static void updateDb(AccrediaCertifiedOrganisation co) throws ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException, NoSuchAlgorithmException, UnsupportedEncodingException {
		String update = "insert into accredia_certified_organisations values ("
				+ clean(co.getId()) 
				+ ", " + clean(co.getCertificateId()) 
				+ ", " + clean(co.getCompanyName())
				+ ", " + clean(co.getTaxCode())
				+ ", " + clean(co.getStatus())
				+ ", " + clean(co.getAddress())
				+ ", " + clean(co.getScope()) 
				+ ", " + clean(co.getStandards())
				+ ", " + clean(co.getCodes())
				+ ", " + clean(co.getCertificationBody())
				+ ", " + clean(co.getDateCertified())
				+ ", " + clean(co.getLastUpdatedbyCB())
				+ ", utc_timestamp()"
				+ ", utc_timestamp()"
				+ "," + co.isDeleted() + ") "
			+ " on duplicate key update "
				+ "`CertificateId`=values(`CertificateId`) "
				+ ", `CompanyName`=values(`CompanyName`) "
				+ ", `TaxFileNumber`=values(`TaxFileNumber`) "
				+ ", `Status`=values(`Status`) "
				+ ", `Address`=values(`Address`) "
				+ ", `Scope`=values(`Scope`) "
				+ ", `Standards`=values(`Standards`) "
				+ ", `Codes`=values(`Codes`) "
				+ ", `CertificationBody`=values(`CertificationBody`) "
				+ ", `DateCertified`=values(`DateCertified`) "
				+ ", `LastUpdatedByCB`=values(`LastUpdatedByCB`) "
				+ ", `Created`=values(`Created`) "
				+ ", `LastUpdated`=values(`LastUpdated`) "
				+ ", `IsDeleted`=values(`IsDeleted`) ";
	
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
	
	private static List<AccrediaCertifiedOrganisation> scrapeCertifiedOrganisations() throws Exception {
		if(search_page==null)
			return null;
		List<AccrediaCertifiedOrganisation> retValue = new ArrayList<AccrediaCertifiedOrganisation>();
		URL address = new URL(search_page+"&page="+page);
		Document doc = null;
		doc = getPage(address.toString());

		if (doc != null) {
			Elements tables = doc.getElementsByClass("certificate");
			if (tables!=null && tables.size()>0) {
				for (Element table : tables) {
					
						AccrediaCertifiedOrganisation co = new AccrediaCertifiedOrganisation();
						co.setCertificateId(table.select("div.certnum").first().text().replace("N.Certificato:", "").trim());
						Element left = table.select("div.descr").get(1);
						Element right = table.select("div.descr").get(2);
						try {co.setDateCertified(dateParser1.parse(left.select("div").get(1).text().replace("Emesso il", "").replace('\u00A0',' ').trim()));} catch (Exception e) {logger.error("Certificate: " + co.getCertificateId() + " missing date certified");}
						try {co.setStatus(left.select("div.status").first().text());} catch (Exception e) {logger.error("Certificate: " + co.getCertificateId() + " missing status");}
						try {co.setCertificationBody(left.select("div.descrOrg").first().text());} catch (Exception e) {logger.error("Certificate: " + co.getCertificateId() + " missing cb");}
						try {co.setComapnyName(right.select("div.ragsoc").first().text());} catch (Exception e) {logger.error("Certificate: " + co.getCertificateId() + " missing company name");}
						try {co.setAddress(right.select("div.sede").first().text());} catch (Exception e) {logger.error("Certificate: " + co.getCertificateId() + " missing address");}
						try {co.setScope(right.select("div:containsOwn(Scopo:)").first().text().replace("Scopo:", "").replace('\u00A0',' ').trim());} catch (Exception e) {logger.error("Certificate: " + co.getCertificateId() + " missing scope");}
						try {co.setStandards(right.select("div:containsOwn(Norma:)").first().text().replace("Norma:", "").replace('\u00A0',' ').trim());} catch (Exception e) {logger.error("Certificate: " + co.getCertificateId() + " missing standards");}
						try {co.setCodes(right.select("div.settore").first().text().replace("Settori:", "").trim());} catch (Exception e) {logger.error("Certificate: " + co.getCertificateId() + " missing codes");}
						try {co.setLastUpdatedbyCB(dateParser2.parse(table.select("div.lastUpdate").first().text().replace("Dati aggiornati dall'Organismo il", "").replace('\u00A0',' ').trim()));} catch (Exception e) {logger.error("Certificate: " + co.getCertificateId() + " missing last updated");}
						try {co.setTaxCode(table.select("div.fiscalcode").first().text().replace('\u00A0',' ').trim());} catch (Exception e) {logger.error("Certificate: " + co.getCertificateId() + " missing tax number");}
						retValue.add(co);
				}
			}
		}
		if (retValue.size()==0) 
			logger.info(doc.toString());
		
		return retValue;
	}
}