package com.saiglobal.sf.reporting.processor;

import java.text.SimpleDateFormat;
import java.util.Calendar;

import org.apache.commons.lang.StringUtils;

import com.saiglobal.sf.core.model.Region;

public class ClientChurningWorkItemsMultiRegion extends AbstractQueryReport {

	private static final Calendar startFy;
	private static final Calendar endFy;
	private static final SimpleDateFormat periodFormatter = new SimpleDateFormat("yyyy MM");
	private Region[] regions;
	
	public ClientChurningWorkItemsMultiRegion() {
		this.numericPattern = "#,###,###.0000";
		this.columnWidth = new int[] {200,200,100,80};
	}
	
	static {
		startFy = Calendar.getInstance();
		endFy = Calendar.getInstance();
		if (startFy.get(Calendar.MONTH)<Calendar.JULY) {
			endFy.set(startFy.get(Calendar.YEAR),Calendar.JUNE,30);
			startFy.set(startFy.get(Calendar.YEAR)-1,Calendar.JULY,1);
		} else {
			startFy.set(startFy.get(Calendar.YEAR),Calendar.JULY,1);
			endFy.set(startFy.get(Calendar.YEAR)+1,Calendar.JUNE,30);
		}
	}
	
	@Override
	protected void initialiseQuery() {
		if (gp.getCustomParameter("regions") == null) {
			regions = new Region[] {Region.AUSTRALIA_MS_AND_FOOD};
		} else {
			String[] regionsStrings = gp.getCustomParameter("regions").split(",");
			regions = new Region[regionsStrings.length];
			for (int i=0; i<regionsStrings.length; i++) {
				regions[i] = Region.valueOf(regionsStrings[i]);
			}
		}
	}
	
	@Override
	protected String getQuery() {
		String regionWhere = " lbr.`Revenue_Ownership__c` in ('";
		for (Region region : regions) {
			regionWhere += StringUtils.join(region.getRevenueOwnerships(), "', '");
		}
		regionWhere += "') ";
		String query = 
			"select client.Name as `Client Name`, lbr.Revenue_Ownership__c as 'Revenue Ownership', `Cancelled Period`, sum(`Quantity`*`EffectivePrice`) as 'Amount', lbr.`CurrencyIsoCode` as 'Currency'  "
			+ "from salesforce.lost_business_revenue_multi_region lbr "
			+ "inner join salesforce.work_item__c wi on lbr.workItemId = wi.id "
			+ "inner join salesforce.work_package__c wp on wi.Work_Package__c = wp.Id "
			+ "inner join salesforce.certification__c sc on wp.Site_Certification__c = sc.Id "
			+ "inner join salesforce.account site on sc.Primary_client__c = site.Id "
			+ "inner join salesforce.account client on site.ParentId = client.Id "
			+ "where `Cancelled Period` >= '" + periodFormatter.format(startFy.getTime()) + "' "
			+ "and `Cancelled Period` <= '" + periodFormatter.format(endFy.getTime()) + "' "
			+ "and " + regionWhere
			+ "group by `Client Name`, `Revenue Ownership`, `Cancelled Period`, `Currency`";
		return query;
	}

	@Override
	protected String getReportName() {
		return "Opex\\AssuranceGlobalMetrics\\ClientChurning";
	}
}
