package com.saiglobal.sf.reporting.processor;

public class EnlightenAdminWIPbyStream extends AbstractQueryReport {

	public EnlightenAdminWIPbyStream() {
		setHeader(true);
		append = false;
	}
	
	@Override
	protected String getQuery() {
		return "select "
				+ "`Stream`,"
				+ "sum(if (`Activity` = 'New Business', `WIP`, 0)) as 'New Business',"
				+ "sum(if (`Activity` = 'ARG', `WIP`, 0)) as 'ARG' "
				+ "from Enlighten_Admin_WIP "
				+ "group by `Stream`";
	}

	@Override
	protected String getReportName() {
		return "\\Enlighten\\Admin_WIP_by_Stream";
	}
}
