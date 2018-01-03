package com.saiglobal.scrapers.processors;

import java.io.IOException;
import java.net.URL;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;
import java.util.TimeZone;

import org.apache.log4j.Logger;
import org.jsoup.HttpStatusException;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;

import com.saiglobal.scrapers.model.CertifiedOrganisation;
import com.saiglobal.scrapers.model.ProcessorOutput;
import com.saiglobal.sf.core.data.DbHelper;
import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;

public class JASANZProcessor implements ScraperProcessor {
	private static String[] trackHistoryFields = new String[] {"CertificationBody"};
	private static final String base = "http://www.jas-anz.com.au";
	private static final String search_page = base + "/our-directory/certified-organisations";
	private static final int read_timeout = 30000;
	private static final int maxTries = 3;
	private static final int sleepMin = 5000;
	private static final SimpleDateFormat dateFormat = new SimpleDateFormat("dd/MM/yyyy");
	private static final Logger logger = Logger.getLogger(JASANZProcessor.class);
	private String nextPage = null;
	private ProcessorDetails details = null;
	
	public JASANZProcessor() {
		super();
		this.details = new ProcessorDetails();
		this.details.setSource("JASANZ");
		this.details.setId("JASANZ - " + Utility.getMysqldateformat().format(Calendar.getInstance().getTime()));
		this.details.setStart(Calendar.getInstance(TimeZone.getTimeZone("UTC")));
		this.details.setTotalRecords(-1); // Not known yet
		this.details.setRecordsToFetch(-1); // Not known yet
		this.details.setRecordsFetched(0);
		this.details.setPage(search_page + "?accredited_body=All");
		this.details.setProcessorClass(this.getClass().getCanonicalName());
	}
	
	@Override
	public void init(GlobalProperties gp, DbHelper db) throws Exception,Throwable {
		
	}

	@Override
	public ProcessorOutput getCertifiedOrganisations() throws Exception {
		ProcessorOutput out = new ProcessorOutput();
		out.setList(new ArrayList<CertifiedOrganisation>());
		if (this.details.getPage() == null) {
			this.details.setPage(search_page + "?accredited_body=All");
		}
		for (String id : getCertifiedOrganisationsId()) {
			out.getList().add(getCertifiedOrganisationDetails(id));
		} 
		out.setNextPage(nextPage);
		this.details.setRecordsFetched(this.details.getRecordsFetched()+out.getList().size());
		return out;
	}

	@Override
	public String[] getTrackHistoryFields() {
		return trackHistoryFields;
	}

	@Override
	public ProcessorDetails getDetails() {
		return details;
	}

	private List<String> getCertifiedOrganisationsId() throws Exception {
		List<String> retValue = new ArrayList<String>();
		if (this.details == null || this.details.getPage() == null)
			return retValue;
		
		URL address = new URL(this.details.getPage());
		Document doc = null;
		doc = getPage(address.toString());

		if (doc != null) {
			this.nextPage = null;
			Elements nextPage = doc.getElementsByClass("pager-next");
			if(nextPage != null && nextPage.size()==1) {
				Elements nextPageLink = nextPage.first().getElementsByTag("a");
				if (nextPageLink != null && nextPageLink.size()==1) {
					String nextPageLinkString = nextPageLink.first().attr("href");
					if (nextPageLinkString != null) {
						this.nextPage = JASANZProcessor.base + nextPageLinkString;  
					}
				}
			}
			if (this.details.getTotalRecords()<0) {
				Elements headers = doc.getElementsByClass("view-header");
				if (headers != null && headers.size()==1) {
					String header = headers.first().text();
					String[] headerParts = header.split("of");
					if(headerParts != null && headerParts.length==2) {
						try {
							this.details.setTotalRecords(Long.parseLong(headerParts[1].replace("results", "").replace(",","").replace(" ", "").trim()));
							String[] headerParts2 = headerParts[0].split("-");
							if(headerParts2 != null && headerParts2.length==2) {
								this.details.setRecordsToFetch(
										this.details.getTotalRecords() -
										Long.parseLong(headerParts2[0].replace("Displaying", "").replace(",","").replace(" ", "").trim())
										+ 1
										);
							}
							
						} catch (Exception e) {
							// Ignore
						}
					}
				}
			}
			
			Elements table = doc.getElementsByClass("cols-5");
			if (table != null && table.size()==1) {
				Elements rows = table.first().getElementsByTag("tr");
				if (rows != null && rows.size()>1) {
					boolean header = true;
					for (Element row : rows) {
						if (header) {
							header = false;
							continue;
						}
						Elements cells = row.getElementsByTag("td");
						if (cells != null && cells.size()==5) {
							Elements detailsLink = cells.get(1).getElementsByTag("a");
							if (detailsLink != null && detailsLink.size()==1) {
								String[] aux = detailsLink.get(0).attr("href").split("/");
								retValue.add(aux[aux.length-1]);
							}
						}
					}
				}
			}
		}
		return retValue;
	}
	
	private static CertifiedOrganisation getCertifiedOrganisationDetails(String id) throws Exception {
		CertifiedOrganisation co = new CertifiedOrganisation();
		co.setId(id);
		URL address = new URL(search_page + "/" + id);
		Document doc = null;
		try {
			doc = getPage(address.toString());
		} catch (IOException ioe) {
			logger.error("Error reading page: " + address.toString());
			if (ioe instanceof HttpStatusException && ((HttpStatusException) ioe).getStatusCode() == 404) {
				// Page Not Found.  Mark as Deleted
				co.setDeleted(true);
				return co;
			} else {
				throw ioe;
			}
		}
		if (doc != null) {
			co.setDetailsLink(address.toString());
			Elements title = doc.getElementsByClass("description");
			if (title != null && title.size()==1 && title.get(0).text() != null) { 
				co.setCompanyName(title.get(0).text().trim());
			} else {
				co.setDeleted(true);
			}
			Elements typeOfCert = doc.getElementsByClass("views-field-type");
			if (typeOfCert!= null && typeOfCert.size()==1 && typeOfCert.get(0).childNodeSize()==2) { 
				co.setBusinessLine(typeOfCert.get(0).childNode(1).toString().trim());
			}
			Elements status = doc.getElementsByClass("views-field-status");
			if (status!= null && status.size()==1 && status.get(0).childNodeSize()==2) { 
				co.setStatus(status.get(0).childNode(1).toString().trim());
			} 
			Elements city = doc.getElementsByClass("views-field-location");
			if (city!= null && city.size()==1 && city.get(0).childNodeSize()==2) { 
				co.setCity(city.get(0).childNode(1).toString().trim());
			}
			Elements country = doc.getElementsByClass("views-field-country");
			if (country!= null && country.size()==1 && country.get(0).childNodeSize()==2) { 
				co.setCountry(country.get(0).childNode(1).toString().trim());
			}
			Elements scope = doc.getElementsByClass("views-field-scope");
			if (scope!= null && scope.size()==1 && scope.get(0).childNodeSize()==2) { 
				co.setScope(scope.get(0).childNode(1).toString().trim());
			}
			Elements standard = doc.getElementsByClass("views-field-standard");
			if (standard!= null && standard.size()==1 && standard.get(0).childNodeSize()==2) { 
				co.setStandard(standard.get(0).childNode(1).toString().trim());
			}
			Elements codes = doc.getElementsByClass("views-field-code");
			if (codes!= null && codes.size()==1 && codes.get(0).childNodeSize()==2) { 
				co.setCodes(codes.get(0).childNode(1).toString().trim());
			}
			Elements date = doc.getElementsByClass("views-field-date");
			if (date!= null && date.size()==1 && date.get(0).childNodeSize()==2) {
				String dateString = date.get(0).childNode(1).toString().trim();
				Calendar dateCert = Calendar.getInstance();
				try {
					dateCert.setTime(dateFormat.parse(dateString));
				} catch (Exception e) {
					// Ignore
					dateCert = null;
				}
				co.setIssueDate(dateCert);
			} else {
			}
			Elements cb = doc.getElementsByClass("views-field-accredited-body");
			if (cb!= null && cb.size()==1 && cb.get(0).childNodeSize()==2) { 
				co.setCertificationBody(cb.get(0).childNode(1).toString().trim());
			}
		}

		return co;
	}
	
	private static Document getPage(String address) throws IOException, InterruptedException {
		boolean retry = true;
		int tryNo = 1;
		Document retValue = null;
		while (retry) {
			try {
				logger.info("Fetching page: " + address + ". Try no. " + tryNo);
				retValue = Jsoup.connect(address).timeout(read_timeout).get();
				retry = false;
			} catch (IOException ioe) {
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
}
