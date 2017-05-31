package com.saiglobal.sf.reporting.processor;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.GregorianCalendar;
import java.util.List;

import com.saiglobal.sf.core.utility.Utility;

public class Top120RevenuesByMonthCrosstab extends AbstractQueryReport {

	private static final SimpleDateFormat periodDisplayFormatter = new SimpleDateFormat("MMM yy");
	
	public Top120RevenuesByMonthCrosstab() {
		setHeader(true);
	}
	
	private List<Calendar> getPeriods() {
		List<Calendar> periods = new ArrayList<Calendar>();
		Calendar aux = new GregorianCalendar(2013, Calendar.JULY, 31);
		while (aux.before(reportDate)) {
			Calendar period = new GregorianCalendar(aux.get(Calendar.YEAR), aux.get(Calendar.MONTH),1);
			periods.add(period);
			aux.add(Calendar.MONTH, 1);
			aux.set(Calendar.DAY_OF_MONTH, aux.getActualMaximum(Calendar.DAY_OF_MONTH));
		}
		
		return periods;
	}
	@Override
	protected String getQuery() {
		String dynamicFieldst = "";
		String dynamicFields = "";
		for (Calendar period : getPeriods()) {
			dynamicFieldst += "t.`" + Utility.getPeriodformatter().format(period.getTime()) + "` as '" + periodDisplayFormatter.format(period.getTime()) + "',";
			dynamicFields += "sum(if (date_format(i.Invoice_Processed_Date__c,'%Y-%m') = '" + Utility.getPeriodformatter().format(period.getTime()) + "', i.Total_Amount__c , 0)) as '" + Utility.getPeriodformatter().format(period.getTime()) + "',";
		}
				
		return "select "
				+ "gp.ParentId as 'GrandParent',"
				+ "p.Name as 'Parent',"
				+ "a.Name as 'Client',"
				+ "a.Id,"
				+ "a.Client_Segmentation__c as 'ClientSegmentation',"
				+ "a.client_Number__c as 'ClientNumber',"
				+ "rm.Name as 'RelationshipManager',"
				+ "sc.Name as 'ServiceDeliveryCoordinator',"
				+ dynamicFieldst
				+ "t.Currency "
				+ "from account a "
				+ "left join salesforce.account p ON a.ParentId = p.Id "
				+ "left join salesforce.account gp ON gp.Id = p.ParentId "
				+ "left join salesforce.User rm on rm.Id = a.Relationship_Manager__c "
				+ "left join salesforce.user sc on sc.Id = a.Service_Delivery_Coordinator__c "
				+ "left join ( "
				+ "select "
				+ "i.Billing_Client__c,"
				+ dynamicFields
				+ "i.CurrencyIsoCode as 'Currency' "
				+ "from salesforce.invoice__c i "
				+ "where "
				+ "date_format(i.Invoice_Processed_Date__c, '%Y-%m') >= '2013-07' "
				+ "and i.isDeleted=0 "
				+ "and i.Status__c in ('Open', 'Closed') "
				+ "group by i.Billing_Client__c) t on a.Id = t.Billing_Client__c "
				+ "where a.IsDeleted=0 "
				+ "and a.Client_Segmentation__c = 'Managed Plus' "
				+ "and a.Client_Ownership__c='Australia' "
				+ "and a.Client_Account_Status__c not in ('Pre-Sales') "
				+ "group by a.Id";
	}

	@Override
	protected String getReportName() {
		return "\\Clients\\Top120\\Top120.revenuesByMonth." + Utility.getActivitydateformatter().format(reportDate.getTime());
	}
}
