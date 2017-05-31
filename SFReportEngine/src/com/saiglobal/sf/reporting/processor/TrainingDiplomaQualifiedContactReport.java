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

public class TrainingDiplomaQualifiedContactReport implements ReportBuilder {
	private DbHelper db;
	private GlobalProperties gp;
	
	private DRDataSource[] data = null;
	private static final Logger logger = Logger.getLogger(TrainingDiplomaQualifiedContactReport.class);
	private static final Calendar today = new GregorianCalendar();
	
	private static final HashSet<String> diplomas = new HashSet<String>(Arrays.asList(new String[] {"BSB60407 Advanced Diploma of Management"}));
	private HashMap<String, List<HashSet<String>>> diplomaQualifications = new HashMap<String, List<HashSet<String>>>();
	private HashMap<String, HashSet<String>> diplomaContacts = new HashMap<String, HashSet<String>>();
	private HashMap<String, HashSet<String>> coursesQualifications = new HashMap<String, HashSet<String>>();
	
	public TrainingDiplomaQualifiedContactReport() {
		
	}
	
	@Override
	public JasperReportBuilder[] generateReports() {
		JasperReportBuilder report = report();
		
		TextColumnBuilder<String> contactIdColumn = col.column("Contact Id", "contact_id", type.stringType());
		TextColumnBuilder<String> contactNameColumn = col.column("Contact Name", "contact_name", type.stringType());		
		
		report
		  .setIgnorePageWidth(true)
		  .setIgnorePagination(true)
		  .columns(contactIdColumn, contactNameColumn)
		  .setDataSource(data[0]);
		
		for (String diplomaName : diplomas) {
			report.addColumn(col.column("Diploma " + diplomaName,   diplomaName,  type.stringType()));
			report.addColumn(col.column(diplomaName + " in SF",   diplomaName+"_issued",  type.booleanType()));
		}
		
		return new JasperReportBuilder[] {report};
	}
	
	public boolean concatenatedReports() {
		return false;
	}
	
	public void init() {
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
			
			// Init Diplomas
			List<HashSet<String>> advancdDiplomaMgmtOptions = new ArrayList<HashSet<String>>(); 
			advancdDiplomaMgmtOptions.add(new HashSet<String>(Arrays.asList("advanced systems leadership", "implementing a whs management system", "compliance program design and management")));
			advancdDiplomaMgmtOptions.add(new HashSet<String>(Arrays.asList("advanced systems leadership", "implementing an ohs management system", "compliance program design and management")));
			
			advancdDiplomaMgmtOptions.add(new HashSet<String>(Arrays.asList("advanced systems leadership", "implementing a quality management system", "compliance program design and management")));
			advancdDiplomaMgmtOptions.add(new HashSet<String>(Arrays.asList("advanced systems leadership", "integrated governance risk management and compliance", "compliance program design and management")));
			advancdDiplomaMgmtOptions.add(new HashSet<String>(Arrays.asList("advanced systems leadership", "implementing a whs management system", "advanced greenhouse gas (ghg) compliance")));
			advancdDiplomaMgmtOptions.add(new HashSet<String>(Arrays.asList("advanced systems leadership", "implementing an ohs management system", "advanced greenhouse gas (ghg) compliance")));
			
			advancdDiplomaMgmtOptions.add(new HashSet<String>(Arrays.asList("advanced systems leadership", "implementing a quality management system", "advanced greenhouse gas (ghg) compliance")));
			advancdDiplomaMgmtOptions.add(new HashSet<String>(Arrays.asList("advanced systems leadership", "integrated governance risk management and compliance", "advanced greenhouse gas (ghg) compliance")));
			
			diplomaQualifications.put((String)diplomas.toArray()[0],advancdDiplomaMgmtOptions);
			
			// Init contacts with diploma issued
			for (String diplomaName : diplomas) {
				diplomaContacts.put(diplomaName, new HashSet<String>());
			}
			
			String query = "select a.Contact__c, a.Id, a.Name from training.assessment__c a "
					+ "where a.Name in ('" + StringUtils.join(diplomas, "','") + "') "
					+ "and a.Contact__c is not null "
					+ "and a.Assessment_Status__c = 'Competent'";
			
			rs = db.executeSelect(query, -1);
			while (rs.next()) {
				diplomaContacts.get(rs.getString("a.Name")).add(rs.getString("a.Contact__c"));
			}
			
			// Get contact competencies
			query = "select cont.Id, cont.Name, LOWER(group_concat(distinct c.Competency_Code__c ORDER BY c.Name DESC SEPARATOR ';')) as 'competencies' "
					+ "from training.assessment_competency__c ac "
					+ "inner join training.competency__c c on c.Id = ac.Competency_Name__c "
					+ "inner join training.assessment__c a on ac.Assessment__c = a.Id "
					+ "inner join training.registration__c r on r.Id = a.Attendee_ID__c "
					+ "inner join training.contact cont on cont.Id = r.Attendee__c "
					+ "where a.Assessment_Status__c = 'Competent' "
					+ "group by cont.Id";

		
			rs = db.executeSelect(query, -1);
			List<String> variables = new ArrayList<String>();
			variables.add("contact_id");
			variables.add("contact_name");
			
			for (String diplomaName : diplomas) {
				variables.add(diplomaName);
				variables.add(diplomaName+"_issued");
			}
			
			data = new DRDataSource[] {
					new DRDataSource(variables.toArray(new String[variables.size()])) 
					} ;
			
			while (rs.next()) {
				HashSet<String> diplomaForContact = getDiplomas(proper(rs.getString("competencies")));
				if (diplomaForContact.size()>0) {
					List<Object> values = new ArrayList<Object>();
					values.add(rs.getString("cont.Id"));
					values.add(rs.getString("cont.Name"));
					for (String diplomaName : diplomas) {
						if (diplomaForContact.contains(diplomaName)) {
							values.add(diplomaName);
							if (diplomaContacts.get(diplomaName).contains(rs.getString("cont.Id")))
								values.add(true);
							else
								values.add(false);
						} else {
							values.add("");
							values.add(false);
						}
					}
					data[0].add(values.toArray());
				}
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
				"\\TIS\\Diplomas_Qualifications" + Utility.getActivitydateformatter().format(today.getTime())
				};
	}
	
	private HashSet<String> getDiplomas(String competencies) {
		HashSet<String> diplomaList = new HashSet<String>();
		HashSet<String> competencyList = new HashSet<String>(Arrays.asList(competencies.split(";")));
		if (competencies != null) {
			for (String diploma : diplomaQualifications.keySet()) {
				for (HashSet<String> courseOption : diplomaQualifications.get(diploma)) {
					if (competencyList.containsAll(getCoursesQualifications(courseOption))) 
						diplomaList.add(diploma);
				}
			}	
		}
		return diplomaList;
	}
	
	private String proper (String input) {
		String output = input.toLowerCase().replaceAll(",", "").replaceAll("&", "and").replaceAll("organizational", "organisational");
		
		return output;
	}
	
	private HashSet<String> getCourseQualifications(String courseName) {
		HashSet<String> qualifications = new HashSet<String>();
		
		if (coursesQualifications.containsKey(courseName)) {
			for (String qualification : coursesQualifications.get(courseName)) {
				qualifications.add(qualification);
			}
		}
		return qualifications;
	}
	
	private HashSet<String> getCoursesQualifications(HashSet<String> courses) {
		HashSet<String> qualifications = new HashSet<String>();
		
		for (String courseName : courses) {
			qualifications.addAll(getCourseQualifications(courseName));
		}
		return qualifications;
	}
	public boolean append() {
		return false;
	}
}
