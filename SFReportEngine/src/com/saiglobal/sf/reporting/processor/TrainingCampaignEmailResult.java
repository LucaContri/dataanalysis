package com.saiglobal.sf.reporting.processor;

import static net.sf.dynamicreports.report.builder.DynamicReports.cmp;
import static net.sf.dynamicreports.report.builder.DynamicReports.col;
import static net.sf.dynamicreports.report.builder.DynamicReports.report;
import static net.sf.dynamicreports.report.builder.DynamicReports.stl;
import static net.sf.dynamicreports.report.builder.DynamicReports.type;

import java.awt.Color;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;

import net.sf.dynamicreports.jasper.builder.JasperReportBuilder;
import net.sf.dynamicreports.jasper.constant.JasperProperty;
import net.sf.dynamicreports.report.builder.column.TextColumnBuilder;
import net.sf.dynamicreports.report.builder.style.StyleBuilder;
import net.sf.dynamicreports.report.constant.HorizontalAlignment;
import net.sf.dynamicreports.report.datasource.DRDataSource;

import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;
import com.saiglobal.sf.reporting.data.DbHelper;

public class TrainingCampaignEmailResult implements ReportBuilder {
	private DbHelper db;
	
	private HashMap<String, DRDataSource> data = new HashMap<String, DRDataSource>();
	private List<String> campaigns = new ArrayList<String>();
	
	@Override
	public JasperReportBuilder[] generateReports() {
		if ((campaigns == null) || (campaigns.size()==0))
			return new JasperReportBuilder[0];
		
		JasperReportBuilder[] reports = new JasperReportBuilder[campaigns.size()];
		
		StyleBuilder boldStyle         = stl.style().bold();
		StyleBuilder boldCenteredStyle = stl.style(boldStyle).setHorizontalAlignment(HorizontalAlignment.CENTER);
		StyleBuilder columnTitleStyle  = stl.style(boldCenteredStyle)
                .setBorder(stl.pen1Point())
                .setBackgroundColor(Color.LIGHT_GRAY);
		
		TextColumnBuilder<String> campaignNameColumn = col.column("Campaign Name", "campaign_name", type.stringType()).setFixedWidth(180);
		TextColumnBuilder<String> emailNameColumn = col.column("Email Name", "email_name", type.stringType()).setFixedWidth(180);
		TextColumnBuilder<String> recipientTypeColumn = col.column("Recipient Type", "recipient_type", type.stringType()).setFixedWidth(180);
		TextColumnBuilder<String> recipientNameColumn = col.column("Recipient Name", "recipient_name", type.stringType()).setFixedWidth(180);
		TextColumnBuilder<String> recipientJobTitleColumn = col.column("Job Title", "recipient_job_title", type.stringType()).setFixedWidth(180);
		TextColumnBuilder<String> recipientCompanyColumn = col.column("Company", "recipient_company", type.stringType()).setFixedWidth(180);
		TextColumnBuilder<String> recipientPhoneColumn = col.column("Phone", "recipient_phone", type.stringType()).setFixedWidth(180);
		TextColumnBuilder<String> recipientEmailColumn = col.column("Email", "recipient_email", type.stringType()).setFixedWidth(180);
		TextColumnBuilder<String> recipientAddressColumn = col.column("Address", "recipient_address", type.stringType()).setFixedWidth(180);
		TextColumnBuilder<Integer> NoOfClicksColumn = col.column("Total Clicks", "number_of_clicks", type.integerType()).setFixedWidth(180);
		TextColumnBuilder<Integer> UniqueClicksColumn = col.column("Unique Clicks", "number_of_unique_clicks", type.integerType()).setFixedWidth(180);
		
		int pointer = 0;
		for (String campaign : campaigns) {
			String[] campaignIds = campaign.split("~");
			JasperReportBuilder report = report();
			
			report
			  .setColumnTitleStyle(columnTitleStyle)
			  .setIgnorePageWidth(true)
			  .setIgnorePagination(true)
			  .setSubtotalStyle(boldStyle)
			  .highlightDetailEvenRows()
			  .columns(
					  campaignNameColumn,
					  emailNameColumn,
					  recipientTypeColumn,
					  recipientNameColumn,
					  recipientJobTitleColumn,
					  recipientCompanyColumn,
					  recipientPhoneColumn,
					  recipientEmailColumn,
					  recipientAddressColumn,
					  NoOfClicksColumn,
					  UniqueClicksColumn
					 )
			  .title(//shows report title
					cmp.horizontalList().add(cmp.image(getClass().getResourceAsStream("sai_logo.gif")).setFixedDimension(360, 50)),
					cmp.horizontalList().add(cmp.text(campaignIds[2])).setFixedDimension(360, 17).setStyle(boldStyle),
					cmp.horizontalList().add(cmp.text("Updated as " + Utility.getShortdatetimedisplayformat().format(new Date()) )).setFixedDimension(360, 17))
			   .addProperty(JasperProperty.EXPORT_XLS_FREEZE_ROW, "5")
			   .setDataSource(data.get(campaign));
			
			reports[pointer] = report;
			pointer++;
		}
		return reports;
	}

	public boolean concatenatedReports() {
		return false;
	}
	
	@Override
	public void setDb(DbHelper db) {
		this.db = db;

	}

	@Override
	public void setProperties(GlobalProperties gp) {
		// 
	}
	
	private String cleanUp(String input) {
		return input
				.replaceAll(":", "")
				.replaceAll("/", "")
				.replaceAll("\\\\", "")
				.replaceAll("\\*", "")
				.replaceAll("\\?", "")
				.replaceAll("\\\"", "")
				.replaceAll("<", "")
				.replaceAll(">", "")
				.replaceAll("|", "");
	}
	
	@Override
	public void init() throws Exception {
		// Get Campaign to be processed.
		String campaignQuery = "select c.Id, c.Name, c.Type, c.StartDate, c.EndDate, er.Date_Sent__c, er.Id, er.Name "
				+ "from training.campaign c "
				+ "inner join training.xtma_email_result__c er on er.Campaign__c = c.Id "
				+ "where c.IsDeleted=0 and date_format(er.Date_Sent__c, '%Y-%m-%d')=date_format(date_add(now(), INTERVAL -3 DAY), '%Y-%m-%d')";
				//+ "where c.Id='701200000011nhGAAQ' and er.Date_Sent__c='2014-05-20 00:07:23'";
		ResultSet rs = db.executeSelect(campaignQuery, -1);
		while (rs.next()) {
			campaigns.add(rs.getString("c.Id" ) + "~" + rs.getString("er.Id") + "~" + cleanUp(rs.getString("c.Name")) + "-" + cleanUp(rs.getString("er.Name")));
		}
		
		List<String> variables = new ArrayList<String>();
		variables.add("campaign_name");
		variables.add("email_name");
		variables.add("recipient_type");
		variables.add("recipient_name");
		variables.add("recipient_job_title");
		variables.add("recipient_company");
		variables.add("recipient_email");
		variables.add("recipient_phone");	
		variables.add("recipient_address");
		variables.add("number_of_clicks");
		variables.add("number_of_unique_clicks");
		
		// For each campaign
		for (String campaign : campaigns) {
			DRDataSource campaignData = new DRDataSource(variables.toArray(new String[variables.size()]));
			String[] campaignIds = campaign.split("~");
			String campaignDetailQuery = "select "
					+ "c.Name as 'Campaign.Name', "
					+ "er.Name as 'Email.Name',"
					+ "if (cont.Id is null, 'Lead', 'Contact') as 'RecipientType',"
					+ "if (cont.Id is null, lead.Id, cont.Id) as 'RecipientId',"
					+ "if (cont.Id is null, lead.Name, cont.Name) as 'RecipientName',"
					+ "if (cont.Id is null, lead.Email, cont.Email) as 'RecipientEmail',"
					+ "if (cont.Id is null, lead.Phone, cont.Phone) as 'RecipientPhone',"
					+ "if (cont.Id is null, lead.Company, cont.Contact_Company__c) as 'RecipientCompany',"
					+ "if (cont.Id is null, lead.Job_title__c, cont.Job_Title__c) as 'RecipientJobTitle',"
					+ "if (cont.Id is null, concat(lead.Mailing_Street__c, ' ' , lead.Mailing_City__c, ' ', lead.Mailing_State_Province__c, ' ', lead.Mailing_Country__c, ' ', lead.Mailing_Zip_Postal_Code__c), concat(cont.MailingStreet, ' ' , cont.MailingCity, ' ', cont.MailingState, ' ', cont.MailingCountry, ' ', cont.MailingPostalCode)) as 'RecipientAddress',"
					+ "ier.Number_of_Total_Clicks__c as 'IndividualEmailResult.Number_of_Total_Clicks', "
					+ "ier.Number_of_Unique_Clicks__c as 'IndividualEmailResult.Number_of_Unique_Clicks' "
					+ "from training.campaign c "
					+ "inner join training.xtma_email_result__c er on er.Campaign__c = c.Id "
					+ "inner join training.xtma_individual_email_result__c ier on (ier.Campaign__c = c.Id and ier.Name=er.Name) "
					//+ "inner join training.xtma_individual_email_result__c ier on (ier.Name=er.Name) "
					+ "left join training.contact cont on ier.Contact__c = cont.Id "
					+ "left join training.lead lead on ier.Lead__c = lead.Id "
					+ "where c.Id='" + campaignIds[0] + "' "
					+ "and ier.Name=er.Name "
					+ "and er.Id = '" + campaignIds[1] + "' "
					+ "and ier.Number_of_Total_Clicks__c>0 "
					+ "and ier.Date_Unsubscribed__c is null "
					+ "order by ier.Number_of_Total_Clicks__c desc;";
			
			rs = db.executeSelect(campaignDetailQuery, -1);
			while (rs.next()) {
				campaignData.add(
						rs.getString("Campaign.Name"),
						rs.getString("Email.Name"),
						rs.getString("RecipientType"),
						rs.getString("RecipientName"),
						rs.getString("RecipientJobTitle"),
						rs.getString("RecipientCompany"),
						rs.getString("RecipientEmail"),
						rs.getString("RecipientPhone"),
						rs.getString("RecipientAddress"),
						rs.getInt("IndividualEmailResult.Number_of_Total_Clicks"),
						rs.getInt("IndividualEmailResult.Number_of_Unique_Clicks")
					);
			}
			data.put(campaign, campaignData);
		}
	}

	@Override
	public String[] getReportNames() {
		if ((campaigns == null) || (campaigns.size()==0))
			return new String[0];
		String[] reportNames = new String[campaigns.size()];
		int pointer =0;
		for (String campaign : campaigns) {
			String[] campaignIds = campaign.split("~");
			reportNames[pointer] = "TIS\\marketing\\" + campaignIds[2];
			pointer++;
		}
		return reportNames;
	}
	public boolean append() {
		return false;
	}
}
