package com.saiglobal.sf.reporting.processor;

import java.text.SimpleDateFormat;
import java.util.Calendar;

public class ClientChurningWorkItems extends AbstractQueryReport {

	private static final Calendar startFy;
	private static final Calendar endFy;
	private static final SimpleDateFormat periodFormatter = new SimpleDateFormat("yyyy MM");
	
	public ClientChurningWorkItems() {
		this.numericPattern = "#,###,###.0000";
		this.columnWidth = new int[] {200,80,100,80};
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
	protected String getQuery() {
		String query = 
				"select `Client Name`, `Stream`, `Cancelled Period`, sum(`Quantity`*`EffectivePrice`) as 'Amount', 'AUD' as 'Currency', group_concat(distinct lbr.WorkItemName) as 'Work Items' "
				+ "from salesforce.lost_business_revenue lbr "
				+ "where `Cancelled Period` >= '" + periodFormatter.format(startFy.getTime()) + "' "
				+ "and `Cancelled Period` <= '" + periodFormatter.format(endFy.getTime()) + "' "
				+ "group by `Client Name`, `Stream`, `Cancelled Period`";
		return query;
	}

	@Override
	protected String getReportName() {
		return "Opex\\AssuranceGlobalMetrics\\ClientChurning";
	}
}
