package com.saiglobal.sf.reporting.processor;

public class Property100Form3SearchManagerReport extends AbstractQueryReport {
	
	public Property100Form3SearchManagerReport() {
		setExecuteStatement(false);
		setHeader(true);
		dateTimePattern = "d/MM/yyyy";
		columnWidth = new int[] {100,100,500};
	}
	
	@Override
	protected void setCurrentDataSource() {
		this.gp.setCurrentDataSource("oscar");
	}
	
	@Override
	protected void initialiseQuery() throws Exception {
	}
	
	@Override
	protected String getQuery() {
		String select = 
				"select " +
				" CAST(o.OrderID AS VARCHAR) AS 'Order ID', " +
				" CAST(co.certificateorderid AS VARCHAR) AS 'Certificate ID', " +
				" au.ProductName AS 'Product Name', " +
				" ABS(DATEDIFF(day, atr.transtime, getdate())) - ABS(DATEDIFF(WEEK, atr.transtime, getdate())*2) - au.overduedays AS 'Overdue', " +
				" atr.transtime AS 'Trans Date (date)', " +
				" CAST(o.OrderID AS VARCHAR) AS 'address (propertyaddress)', " +
				" au.contactphone as 'BCM Phone' " +
				" from " +
				" certificatetransrecords ct WITH(NOLOCK), " +
				" authoritytransrecords atr WITH(NOLOCK), " +
				" authoritycertificatetypes au WITH(NOLOCK), " +
				" certificateorders co WITH(NOLOCK), " +
				" orders o WITH(NOLOCK)  " +
				" where " +
				" co.orderid = o.orderid and co.authoritycertificatetypeid = au.authoritycertificatetypeid and convert(datetime,convert(varchar,getdate(),112)) > DATEADD(DAY, au.overduedays + ROUND(au.overduedays/5.0,0)*2, convert(datetime,convert(varchar,atr.transtime,112))) and co.StatusID in (31,32,33,34,35,36) and au.CertificateTypeID = 108 and ct.certificateorderid = co.certificateorderid and atr.authoritytransrecordid = ct.authoritytransrecordid and o.datesubmitted > '2011/07/01'  " +
				" order by " +
				" au.productname, " +
				" co.certificateorderid DESC";
		
		return select;
	}

	@Override
	protected void finaliseQuery() throws Exception {
	}
	
	@Override
	protected String getReportName() {
		return "100 Form 3 Search Manager";
	}
	
}
