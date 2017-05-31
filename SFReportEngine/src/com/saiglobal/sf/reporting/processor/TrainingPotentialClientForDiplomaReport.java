package com.saiglobal.sf.reporting.processor;

import static net.sf.dynamicreports.report.builder.DynamicReports.*;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Calendar;
import java.util.GregorianCalendar;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;

import org.apache.commons.lang.StringUtils;
import org.apache.log4j.Logger;

import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;
import com.saiglobal.sf.reporting.data.DbHelper;

import net.sf.dynamicreports.jasper.builder.JasperReportBuilder;
import net.sf.dynamicreports.report.builder.column.TextColumnBuilder;
import net.sf.dynamicreports.report.datasource.DRDataSource;

public class TrainingPotentialClientForDiplomaReport implements ReportBuilder {
	private DbHelper db;
	private GlobalProperties gp;
	
	private DRDataSource[] data = null;
	private static final Logger logger = Logger.getLogger(TrainingPotentialClientForDiplomaReport.class);
	private static final Calendar today = new GregorianCalendar();
	
	private static final String[] diplomas = new String[] {
			//"BSB60407 Advanced Diploma of Management",
			"BSB51607 Diploma of Quality Auditing",
			//"BSB60612 Advanced Diploma of Work Health and Safety"
			};
	private HashMap<String, List<HashSet<String>>> diplomaQualifications = new HashMap<String, List<HashSet<String>>>();
	private HashMap<String, HashSet<String>> coursesQualifications = new HashMap<String, HashSet<String>>();
	private HashMap<String, String> contactDiplomas = new HashMap<String, String>();
	private List<String> leadAuditorCourses = new ArrayList<String>();
	
	private HashSet<String> leadAuditorQualifications = new HashSet<String>();
	
	public TrainingPotentialClientForDiplomaReport() {
		leadAuditorCourses.add("lead auditor in whs management systems");
		leadAuditorCourses.add("lead auditor in quality management systems");
		leadAuditorCourses.add("lead auditor in environmental management systems");
		leadAuditorCourses.add("lead auditor in information security management systems");
		//leadAuditorCourses.add("lead auditor in food safety management systems");
		
		leadAuditorQualifications.add("initiate a quality audit");
		leadAuditorQualifications.add("lead a quality audit");
		leadAuditorQualifications.add("report on a quality audit");
		leadAuditorQualifications.add("participate in a quality audit");
			
	}
	
	public boolean concatenatedReports() {
		return false;
	}
	
	@Override
	public JasperReportBuilder[] generateReports() {
		JasperReportBuilder report = report();
		
		TextColumnBuilder<String> contactIdColumn = col.column("Contact Id", "contact_id", type.stringType());
		TextColumnBuilder<String> contactNameColumn = col.column("Contact Name", "contact_name", type.stringType());
		TextColumnBuilder<String> contactEmailColumn = col.column("Email", "contact_email", type.stringType());
		TextColumnBuilder<String> contactPhoneColumn = col.column("Phone", "contact_phone", type.stringType());
		TextColumnBuilder<String> contactMobileColumn = col.column("Mobile", "contact_mobile", type.stringType());
		TextColumnBuilder<String> contactHomeColumn = col.column("Home Phone", "contact_home", type.stringType());
		TextColumnBuilder<String> contactAddressColumn = col.column("Address", "contact_address", type.stringType());
		TextColumnBuilder<String> contactCityColumn = col.column("City", "contact_city", type.stringType());
		TextColumnBuilder<String> contactStateColumn = col.column("State", "contact_state", type.stringType());
		TextColumnBuilder<String> contactPostcodeColumn = col.column("PostCode", "contact_postcode", type.stringType());
		
		report
		  .setIgnorePageWidth(true)
		  .setIgnorePagination(true)
		  .columns(contactIdColumn, contactNameColumn, contactEmailColumn, contactPhoneColumn, contactMobileColumn, contactHomeColumn, contactAddressColumn, contactCityColumn, contactStateColumn, contactPostcodeColumn )
		  .setDataSource(data[0]);
		
		for (String diplomaName : diplomas) {
			report.addColumn(col.column("Any to complete " + diplomaName,   diplomaName,  type.stringType()));
		}
		
		return new JasperReportBuilder[] {report};
	}
	
	public void init() throws Exception {
		// Init Courses
		try {
			String queryCoursesCompetencies = "select course.Id, course.Name, group_concat(distinct c.Competency_Code__c ORDER BY c.Name DESC SEPARATOR ';') as 'competencies' "
					+ "from training.course__c course "
					+ "inner join training.certificate_type__c  ct on course.Id = ct.Course_Name__c "
					+ "inner join training.bridging_object__c bo on ct.Id = bo.Certificate_Type_Name__c "
					+ "inner join training.competency__c c on c.Id = bo.Competency_Name__c "
					+ "where course.status__c='Active' "
					+ "group by course.Id";
			
			ResultSet rs = db.executeSelect(queryCoursesCompetencies, -1);
			while (rs.next()) {
				coursesQualifications.put(proper(rs.getString("course.Name")), new HashSet<String>(Arrays.asList(proper(rs.getString("competencies")).split(";"))));
			}
			
			// Init contact diplomas
			String queryContactDiplomas = "select a.Contact__c as 'contactId', group_concat(a.Name SEPARATOR ',') as 'diplomas' from training.assessment__c a where a.Contact__c is not null and a.IsDeleted=0 group by a.Contact__c";
			
			rs = db.executeSelect(queryContactDiplomas, -1);
			while (rs.next()) {
				contactDiplomas.put(rs.getString("contactId"), rs.getString("diplomas"));
			}
			
			List<HashSet<String>> advancdDiplomaMgmtOptions = new ArrayList<HashSet<String>>(); 
			advancdDiplomaMgmtOptions.add(new HashSet<String>(Arrays.asList("advanced systems leadership", "implementing a whs management system", "compliance program design and management")));
			//advancdDiplomaMgmtOptions.add(new HashSet<String>(Arrays.asList("advanced systems leadership", "implementing an ohs management system", "compliance program design and management")));
			advancdDiplomaMgmtOptions.add(new HashSet<String>(Arrays.asList("advanced systems leadership", "implementing a quality management system", "compliance program design and management")));
			advancdDiplomaMgmtOptions.add(new HashSet<String>(Arrays.asList("advanced systems leadership", "integrated governance risk management and compliance", "compliance program design and management")));
			advancdDiplomaMgmtOptions.add(new HashSet<String>(Arrays.asList("advanced systems leadership", "implementing a whs management system", "advanced greenhouse gas (ghg) compliance")));
			//advancdDiplomaMgmtOptions.add(new HashSet<String>(Arrays.asList("advanced systems leadership", "implementing an ohs management system", "advanced greenhouse gas (ghg) compliance")));
			advancdDiplomaMgmtOptions.add(new HashSet<String>(Arrays.asList("advanced systems leadership", "implementing a quality management system", "advanced greenhouse gas (ghg) compliance")));
			advancdDiplomaMgmtOptions.add(new HashSet<String>(Arrays.asList("advanced systems leadership", "integrated governance risk management and compliance", "advanced greenhouse gas (ghg) compliance")));

			List<HashSet<String>> diplomaOfQualityAuditingOptions = new ArrayList<HashSet<String>>();			
			diplomaOfQualityAuditingOptions.add(new HashSet<String>(Arrays.asList("lead auditor in whs management systems", "integrated governance risk management and compliance", "management systems leadership")));
			diplomaOfQualityAuditingOptions.add(new HashSet<String>(Arrays.asList("lead auditor in whs management systems", "integrated governance risk management and compliance", "whs risk management")));
			//diplomaOfQualityAuditingOptions.add(new HashSet<String>(Arrays.asList("lead auditor in ohs management systems", "integrated governance risk management and compliance", "management systems leadership")));
			//diplomaOfQualityAuditingOptions.add(new HashSet<String>(Arrays.asList("lead auditor in ohs management systems", "integrated governance risk management and compliance", "whs risk management")));
			//diplomaOfQualityAuditingOptions.add(new HashSet<String>(Arrays.asList("lead auditor in whs management systems", "integrated governance risk management and compliance", "ohs risk management")));
			//diplomaOfQualityAuditingOptions.add(new HashSet<String>(Arrays.asList("lead auditor in ohs management systems", "integrated governance risk management and compliance", "ohs risk management")));

			//List<HashSet<String>> diplomaOfQualityAuditingQMSOptions = new ArrayList<HashSet<String>>();
			diplomaOfQualityAuditingOptions.add(new HashSet<String>(Arrays.asList("lead auditor in quality management systems", "integrated governance risk management and compliance", "management systems leadership")));
			diplomaOfQualityAuditingOptions.add(new HashSet<String>(Arrays.asList("lead auditor in quality management systems", "integrated governance risk management and compliance", "whs risk management")));
			//diplomaOfQualityAuditingOptions.add(new HashSet<String>(Arrays.asList("lead auditor in quality management systems", "integrated governance risk management and compliance", "ohs risk management")));

			//List<HashSet<String>> diplomaOfQualityAuditingEMSOptions = new ArrayList<HashSet<String>>();
			diplomaOfQualityAuditingOptions.add(new HashSet<String>(Arrays.asList("lead auditor in environmental management systems", "integrated governance risk management and compliance", "management systems leadership")));
			diplomaOfQualityAuditingOptions.add(new HashSet<String>(Arrays.asList("lead auditor in environmental management systems", "integrated governance risk management and compliance", "whs risk management")));
			//diplomaOfQualityAuditingOptions.add(new HashSet<String>(Arrays.asList("lead auditor in environmental management systems", "integrated governance risk management and compliance", "ohs risk management")));

			//List<HashSet<String>> diplomaOfQualityAuditingISMSOptions = new ArrayList<HashSet<String>>();
			diplomaOfQualityAuditingOptions.add(new HashSet<String>(Arrays.asList("lead auditor in information security management systems", "integrated governance risk management and compliance", "management systems leadership")));
			diplomaOfQualityAuditingOptions.add(new HashSet<String>(Arrays.asList("lead auditor in information security management systems", "integrated governance risk management and compliance", "whs risk management")));
			//diplomaOfQualityAuditingOptions.add(new HashSet<String>(Arrays.asList("lead auditor in information security management systems", "integrated governance risk management and compliance", "ohs risk management")));

			//List<HashSet<String>> diplomaOfQualityAuditingFoodOptions = new ArrayList<HashSet<String>>();
			diplomaOfQualityAuditingOptions.add(new HashSet<String>(Arrays.asList("lead auditor in food safety management systems", "food safety qa management", "management systems leadership")));

			List<HashSet<String>> advancedDiplomaOfWHSOptions = new ArrayList<HashSet<String>>();
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("whs risk management", "implementing a whs management system", "lead auditor in whs management systems", "effective workplace safety and design")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("whs risk management", "implementing a whs management system", "auditing a whs management system", "effective workplace safety and design")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("whs risk management", "implementing a whs management system", "lead auditor in whs management systems", "integrated governance risk management and compliance")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("whs risk management", "implementing a whs management system", "auditing a whs management system", "integrated governance risk management and compliance")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("whs risk management", "implementing a whs management system", "lead auditor in whs management systems", "advanced systems leadership")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("whs risk management", "implementing a whs management system", "auditing a whs management system", "advanced systems leadership")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("whs risk management", "implementing a whs management system", "lead auditor in whs management systems", "compliance program design and management")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("whs risk management", "implementing a whs management system", "auditing a whs management system", "compliance program design and management")));
			/*
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("ohs risk management", "implementing a whs management system", "lead auditor in whs management systems", "effective workplace safety and design")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("ohs risk management", "implementing a whs management system", "auditing a whs management system", "effective workplace safety and design")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("ohs risk management", "implementing a whs management system", "lead auditor in whs management systems", "integrated governance risk management and compliance")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("ohs risk management", "implementing a whs management system", "auditing a whs management system", "integrated governance risk management and compliance")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("ohs risk management", "implementing a whs management system", "lead auditor in whs management systems", "advanced systems leadership")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("ohs risk management", "implementing a whs management system", "auditing a whs management system", "advanced systems leadership")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("ohs risk management", "implementing a whs management system", "lead auditor in whs management systems", "compliance program design and management")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("ohs risk management", "implementing a whs management system", "auditing a whs management system", "compliance program design and management")));

			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("whs risk management", "implementing a ohs management system", "lead auditor in whs management systems", "effective workplace safety and design")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("whs risk management", "implementing a ohs management system", "auditing a whs management system", "effective workplace safety and design")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("whs risk management", "implementing a ohs management system", "lead auditor in whs management systems", "integrated governance risk management and compliance")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("whs risk management", "implementing a ohs management system", "auditing a whs management system", "integrated governance risk management and compliance")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("whs risk management", "implementing a ohs management system", "lead auditor in whs management systems", "advanced systems leadership")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("whs risk management", "implementing a ohs management system", "auditing a whs management system", "advanced systems leadership")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("whs risk management", "implementing a ohs management system", "lead auditor in whs management systems", "compliance program design and management")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("whs risk management", "implementing a ohs management system", "auditing a whs management system", "compliance program design and management")));

			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("ohs risk management", "implementing a ohs management system", "lead auditor in whs management systems", "effective workplace safety and design")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("ohs risk management", "implementing a ohs management system", "auditing a whs management system", "effective workplace safety and design")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("ohs risk management", "implementing a ohs management system", "lead auditor in whs management systems", "integrated governance risk management and compliance")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("ohs risk management", "implementing a ohs management system", "auditing a whs management system", "integrated governance risk management and compliance")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("ohs risk management", "implementing a ohs management system", "lead auditor in whs management systems", "advanced systems leadership")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("ohs risk management", "implementing a ohs management system", "auditing a whs management system", "advanced systems leadership")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("ohs risk management", "implementing a ohs management system", "lead auditor in whs management systems", "compliance program design and management")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("ohs risk management", "implementing a ohs management system", "auditing a whs management system", "compliance program design and management")));

			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("whs risk management", "implementing a whs management system", "lead auditor in ohs management systems", "effective workplace safety and design")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("whs risk management", "implementing a whs management system", "auditing a ohs management system", "effective workplace safety and design")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("whs risk management", "implementing a whs management system", "lead auditor in ohs management systems", "integrated governance risk management and compliance")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("whs risk management", "implementing a whs management system", "auditing a ohs management system", "integrated governance risk management and compliance")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("whs risk management", "implementing a whs management system", "lead auditor in ohs management systems", "advanced systems leadership")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("whs risk management", "implementing a whs management system", "auditing a ohs management system", "advanced systems leadership")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("whs risk management", "implementing a whs management system", "lead auditor in ohs management systems", "compliance program design and management")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("whs risk management", "implementing a whs management system", "auditing a ohs management system", "compliance program design and management")));

			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("ohs risk management", "implementing a whs management system", "lead auditor in ohs management systems", "effective workplace safety and design")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("ohs risk management", "implementing a whs management system", "auditing a ohs management system", "effective workplace safety and design")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("ohs risk management", "implementing a whs management system", "lead auditor in ohs management systems", "integrated governance risk management and compliance")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("ohs risk management", "implementing a whs management system", "auditing a ohs management system", "integrated governance risk management and compliance")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("ohs risk management", "implementing a whs management system", "lead auditor in ohs management systems", "advanced systems leadership")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("ohs risk management", "implementing a whs management system", "auditing a ohs management system", "advanced systems leadership")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("ohs risk management", "implementing a whs management system", "lead auditor in ohs management systems", "compliance program design and management")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("ohs risk management", "implementing a whs management system", "auditing a ohs management system", "compliance program design and management")));

			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("whs risk management", "implementing a ohs management system", "lead auditor in ohs management systems", "effective workplace safety and design")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("whs risk management", "implementing a ohs management system", "auditing a ohs management system", "effective workplace safety and design")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("whs risk management", "implementing a ohs management system", "lead auditor in ohs management systems", "integrated governance risk management and compliance")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("whs risk management", "implementing a ohs management system", "auditing a ohs management system", "integrated governance risk management and compliance")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("whs risk management", "implementing a ohs management system", "lead auditor in ohs management systems", "advanced systems leadership")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("whs risk management", "implementing a ohs management system", "auditing a ohs management system", "advanced systems leadership")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("whs risk management", "implementing a ohs management system", "lead auditor in ohs management systems", "compliance program design and management")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("whs risk management", "implementing a ohs management system", "auditing a ohs management system", "compliance program design and management")));

			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("ohs risk management", "implementing a ohs management system", "lead auditor in ohs management systems", "effective workplace safety and design")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("ohs risk management", "implementing a ohs management system", "auditing a ohs management system", "effective workplace safety and design")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("ohs risk management", "implementing a ohs management system", "lead auditor in ohs management systems", "integrated governance risk management and compliance")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("ohs risk management", "implementing a ohs management system", "auditing a ohs management system", "integrated governance risk management and compliance")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("ohs risk management", "implementing a ohs management system", "lead auditor in ohs management systems", "advanced systems leadership")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("ohs risk management", "implementing a ohs management system", "auditing a ohs management system", "advanced systems leadership")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("ohs risk management", "implementing a ohs management system", "lead auditor in ohs management systems", "compliance program design and management")));
			advancedDiplomaOfWHSOptions.add(new HashSet<String>(Arrays.asList("ohs risk management", "implementing a ohs management system", "auditing a ohs management system", "compliance program design and management")));
			*/
			
			//diplomaQualifications.put(diplomas[0],advancdDiplomaMgmtOptions);
			diplomaQualifications.put(diplomas[0],diplomaOfQualityAuditingOptions);
			//diplomaQualifications.put(diplomas[2],advancedDiplomaOfWHSOptions);
			
			
			String query = "select cont.Id, cont.Name, cont.Phone, cont.HomePhone, cont.MobilePhone, cont.Email, "
					+ "cont.MailingStreet,cont.MailingCity ,cont.MailingState, cont.MailingPostalCode, "
					+ "LOWER(group_concat(distinct c.Competency_Code__c ORDER BY c.Name DESC SEPARATOR ';')) as 'competencies' "
					+ "from training.assessment_competency__c ac "
					+ "inner join training.competency__c c on c.Id = ac.Competency_Name__c "
					+ "inner join training.assessment__c a on ac.Assessment__c = a.Id "
					+ "inner join training.registration__c r on r.Id = a.Attendee_ID__c "
					+ "inner join training.contact cont on cont.Id = r.Attendee__c "
					//+ "where a.Assessment_Status__c = 'Competent' "
					//+ "and cont.id='0032000000a6a87AAA'"
					+ "group by cont.Id";
/*
			String query2 = "select cont.Id, cont.Name, cont.Phone, cont.HomePhone, cont.MobilePhone, cont.Email, "
					+ "cont.MailingStreet,cont.MailingCity ,cont.MailingState, cont.MailingPostalCode, "
					+ "LOWER(group_concat(distinct c.Name ORDER BY c.Name DESC SEPARATOR ';')) as 'courses' "
					+ "from training.registration__c r  "
					+ "inner join training.contact cont on cont.Id = r.Attendee__c "
					+ "inner join training.class__c c on c.Id = r.Class_Name__c "
					+ "where r.Status__c = 'Confirmed' and r.Class_End_Date__c<now() "
					//+ "and cont.id='0032000000bfwobAAA' "
					+ "group by cont.Id";
*/	
			rs = db.executeSelect(query, -1);
			//rs = db.executeSelect(query2, -1);
			List<String> variables = new ArrayList<String>();
			variables.add("contact_id");
			variables.add("contact_name"); 
			variables.add("contact_email"); 
			variables.add("contact_phone"); 
			variables.add("contact_mobile"); 
			variables.add("contact_home"); 
			variables.add("contact_address");
			variables.add("contact_city");
			variables.add("contact_state");
			variables.add("contact_postcode");
			
			for (String diplomaName : diplomas) {
				variables.add(diplomaName);
			}
			
			data = new DRDataSource[] {
					new DRDataSource(variables.toArray(new String[variables.size()])) 
					} ;
			
			while (rs.next()) {
				List<Object> values = new ArrayList<Object>();
				values.add(rs.getString("cont.Id"));
				values.add(rs.getString("cont.Name"));
				values.add(rs.getString("cont.Email"));
				values.add(rs.getString("cont.Phone"));
				values.add(rs.getString("cont.MobilePhone"));
				values.add(rs.getString("cont.HomePhone"));
				values.add(rs.getString("cont.MailingStreet"));
				values.add(rs.getString("cont.MailingCity"));
				values.add(rs.getString("cont.MailingState"));
				values.add(rs.getString("cont.MailingPostalCode"));
				for (String  diplomaName : diplomas) {
					//List<HashSet<String>> missingCoursesOptions  = getMissingCourseToDiplomav2(diplomaName, proper(rs.getString("courses")));
					List<HashSet<String>> missingCoursesOptions  = getMissingCourseToDiploma(diplomaName, proper(rs.getString("competencies")));
					if (missingCoursesOptions == null) {
						// Already got diploma
						values.add("");
					} else {
						// Check if does not already have the diploma via some other competency combination
						if (contactDiplomas.containsKey(rs.getString("cont.Id")) && contactDiplomas.get(rs.getString("cont.Id")).toLowerCase().contains(diplomaName.toLowerCase()) ) {
							// Already got diploma
							values.add("");
						} else {
							// Get the options with one course only
							HashSet<String> anyMissingCourse = new HashSet<String>();
							for (HashSet<String> missingCoursesOption : missingCoursesOptions) {
								if (missingCoursesOption.size()==1) {
									anyMissingCourse.add((String)missingCoursesOption.toArray()[0]);
								}
							}
							values.add(StringUtils.join(anyMissingCourse.toArray(),";"));
						}
					}
				}
				data[0].add(values.toArray());
			}
		} catch (SQLException e) {
			logger.error("", e);
			Utility.handleError(gp, e);
		} catch (ClassNotFoundException e) {
			logger.error("", e);
			Utility.handleError(gp, e);
		} catch (IllegalAccessException e) {
			logger.error("", e);
			Utility.handleError(gp, e);		
		} catch (InstantiationException e) {
			logger.error("", e);
			Utility.handleError(gp, e);
		}
	}
	
	public void setDb(DbHelper db) {
		this.db = db;
	}

	public void setProperties(GlobalProperties gp) {
		this.gp = gp;
	}
	
	public String[] getReportNames() {
		return new String[] {
				"\\TIS\\Diplomas_Potential_Clients" + Utility.getActivitydateformatter().format(today.getTime())
				};
	}

	private List<HashSet<String>> getMissingCourseToDiploma(String diplomaName, String competencies) throws Exception {
		// Return a list of set of courses any of which will complete the diploma passed as parameter.
		// If diploma is already completed returns null;
		// If Set is empty, there is no such option (i.e. more than one course needed to complete diploma)
		List<HashSet<String>> missingCoursesToDiploma = new ArrayList<HashSet<String>>();
		if (competencies != null) {
			HashSet<String> competencyList = new HashSet<String>(Arrays.asList(competencies.split(";")));
			if ((diplomaName != null) && (diplomaQualifications.containsKey(diplomaName))) {
				for (HashSet<String> courseOption : diplomaQualifications.get(diplomaName)) {
					HashSet<String> missingCoursesOption = new HashSet<String>();
					for (String courseName : courseOption) {
						if (!competencyList.containsAll(getCourseQualifications(courseName))) 
							missingCoursesOption.add(courseName);
					}
					if (missingCoursesOption.size()==0) {
						// Diploma already completed
						return null;
					}
					missingCoursesToDiploma.add(missingCoursesOption);
				}
			}
			
		}
		
		return missingCoursesToDiploma;
	}
	/*
	private List<HashSet<String>> getMissingCourseToDiplomav2(String diplomaName, String courses) throws Exception {
		// Return a list of set of courses any of which will complete the diploma passed as parameter.
		// If diploma is already completed returns null;
		// If Set is empty, there is no such option (i.e. more than one course needed to complete diploma)
		List<HashSet<String>> missingCoursesToDiploma = new ArrayList<HashSet<String>>();
		if (courses!= null) {
			HashSet<String> coursesList = new HashSet<String>(Arrays.asList(courses.split(";")));
			if ((diplomaName != null) && (diplomaQualifications.containsKey(diplomaName))) {
				for (HashSet<String> courseOption : diplomaQualifications.get(diplomaName)) {
					HashSet<String> missingCoursesOption = new HashSet<String>();
					for (String courseName : courseOption) {
						if (!coursesList.contains(courseName)) 
							missingCoursesOption.add(courseName);
					}
					if (missingCoursesOption.size()==0) {
						// Diploma already completed
						return null;
					}
					missingCoursesToDiploma.add(missingCoursesOption);
				}
			}
			
		}
		
		return missingCoursesToDiploma;
	}*/
	
	private String proper (String input) {
		String output = input.toLowerCase().replaceAll(",", "").replaceAll("&", "and").replaceAll("organizational", "organisational");
		
		return output;
	}
	
	private HashSet<String> getCourseQualifications(String courseName) throws Exception {
		HashSet<String> qualifications = new HashSet<String>();
		// For any lead auditor course we use hardcoded qualifications
		if (leadAuditorCourses.contains(courseName))
			return leadAuditorQualifications;
		
		if (coursesQualifications.containsKey(courseName)) {
			for (String qualification : coursesQualifications.get(courseName)) {
				qualifications.add(qualification);
			}
		} else {
			logger.error("Course " + courseName + " does not have qualifications");
			throw new Exception();
		}
		return qualifications;
	}
	public boolean append() {
		return false;
	}
}


