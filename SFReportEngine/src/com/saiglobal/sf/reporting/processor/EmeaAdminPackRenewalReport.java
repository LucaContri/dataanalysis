package com.saiglobal.sf.reporting.processor;

public class EmeaAdminPackRenewalReport extends AbstractQueryReport {

	public EmeaAdminPackRenewalReport() {
		setHeader(true);
	}
	
	@Override
	protected String getQuery() {
		return "select * from emea_pack_renewals;";
	}

	@Override
	protected String getReportName() {
		return "\\Emea\\Admin\\Pack Renewals";
	}
}
