package com.saiglobal.sf.reporting.processor;

import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Calendar;

public class PropertySearchManagerQualityReport extends AbstractQueryReport {
	
	private Calendar today = Calendar.getInstance();
	private Calendar yesterday = Calendar.getInstance();
	
	public PropertySearchManagerQualityReport() {
		setExecuteStatement(false);
		setHeader(true);
		dateTimePattern = "d/MM/yyyy";
		//columnWidth = new int[] {80,500,100,100,150,100,100,150,};
	}
	
	@Override
	protected void setCurrentDataSource() {
		this.gp.setCurrentDataSource("oscar");
	}
	
	@Override
	protected void initialiseQuery() throws Exception {
		yesterday.setTime(today.getTime());
		yesterday.add(Calendar.DAY_OF_MONTH, -1);
	}
	
	@Override
	protected String getQuery() {
		SimpleDateFormat dateFormat = new SimpleDateFormat("MM/d/yyyy");
		
		String select = 
				"SELECT     " +
				" 'NonConformingItem' AS 'QualityCategoryRoot'," +
				" CAST(CONVERT(varchar(10),oe.Created,101 ) as Date) AS 'CreatedDateTime'," +
				" 'N/A' AS 'Site'," +
				" CAST(oe.OrderID as nvarchar) AS 'Account'," +
				" oe.ReporterUserName AS 'CreatedBy'," +
				" 'N/A' AS 'AusState'," +
				" CAST(co.CertificateOrderID  as nvarchar) AS 'SSRNumber'," +
				" 'N/A' AS 'LoanNumber'," +
				" 'N/A' AS 'MatterName'," +
				" 'N' AS 'IsMatterWithClient'," +
				" 'Espreon' AS 'WhosAtFault'," +
				" 'N' AS 'IsSLAMissed'," +
				" 'N' AS 'IsWorkflowPaused'," +
				" 'Y' AS 'IsAvoidable'," +
				" oe.ErrorUserName AS 'CausedBy'," +
				" 'Process Error' AS 'L2Description'," +
				" oe.Error AS 'L3Description'," +
				" act.ProductName AS 'L4Description'," +
				" 'Re-Training / Issue Highlighted' AS 'L5Description'," +
				" 'Low' AS 'RiskSeverity'," +
				" 'Near Miss' AS 'Impact'," +
				" '0' AS 'ImpactValue'," +
				" ' | ' + oe.Error + + oe.AdditonalComments AS 'Comments'," +
				" '' AS 'ID' " +
				" FROM           " +
				" OperatorErrors oe with(nolock)       " +
				" inner join  CertificateOrders co with(nolock) ON oe.CertificateOrderID = co.CertificateOrderID       " +
				" inner join  AuthorityCertificateTypes act with(nolock) on co.AuthorityCertificateTypeID = act.AuthorityCertificateTypeID " +
				" left outer join CertificateBills cb with(nolock) on co.CertificateOrderID = cb.CertificateOrderID  " +
				" WHERE  " +
				" oe.Created BETWEEN '" + dateFormat.format(yesterday.getTime()) + "' AND '" + dateFormat.format(today.getTime()) + "'       " +
				" ORDER BY oe.OrderID";
		
		return select;
	}

	@Override
	protected void finaliseQuery() throws Exception {
	}
	
	@Override
	protected String getReportName() {
		DateFormat sqlDateFormat = new SimpleDateFormat("yyyyMMdd");
		return "searchManagerQualityerrorupload " + sqlDateFormat.format(yesterday.getTime());
	}
	
}
