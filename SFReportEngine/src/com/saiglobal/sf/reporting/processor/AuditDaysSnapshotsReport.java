package com.saiglobal.sf.reporting.processor;

public class AuditDaysSnapshotsReport extends AbstractQueryReport {

	public AuditDaysSnapshotsReport() {
		setHeader(false);
		columnWidth = new int[] {150,100,100,100,100,100};
	}
	
	@Override
	protected String getQuery() {
		return "select "
				+ "str_to_date(fv.`Report Date-Time`,'%d/%m/%Y - %T') as 'Snapshot Date-Time',"
				+ "fv.`Revenue Stream`,"
				+ "fv.`Audit Status`,"
				+ "if((fv.`Audit Status` in ('Cancelled')),"
				+ "'Cancelled',"
				+ "if((fv.`Audit Status` in ('Open' , 'Service Change')),"
				+ "'Open',"
				+ "if(fv.`Audit Status` in ('Scheduled', 'Scheduled Offered'), 'Scheduled', 'Confirmed'))) AS `SimpleStatus`,"
				+ "fv.`Period`,"
				+ "fv.`Value` as 'Days' "
				+ "from financial_visisbility fv "
				+ "where Region like 'Australia%' "
				+ "and Source = 'Audit' "
				+ "and Type = 'Days'";
	}

	@Override
	protected String getReportName() {
		return "Tmp\\AuditDaysSnapshots";
	}
	
	@Override
	protected String getTitle() {
		return "Audit Days Snapshots";
	}
}
