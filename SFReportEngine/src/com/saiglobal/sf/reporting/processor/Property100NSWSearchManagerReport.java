package com.saiglobal.sf.reporting.processor;

public class Property100NSWSearchManagerReport extends AbstractQueryReport {
	
	public Property100NSWSearchManagerReport() {
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
				" distinct  " +
				" CAST(o.orderid AS VARCHAR) AS 'Order ID', " +
				" CAST(co.certificateorderid AS VARCHAR) AS 'Certificate ID', " +
				" au.ProductName AS 'Product Name', " +
				" ABS(DATEDIFF(day, atr.transtime, getdate())) - ABS(DATEDIFF(WEEK, atr.transtime, getdate())*2) - au.overduedays AS 'Overdue', " +
				" atr.transtime AS 'Trans Date (date)', " +
				" tm.DisplayName AS 'Trans Method', " +
				" pm.DisplayName AS 'Payment Method', " +
				" CAST(o.orderid AS VARCHAR) AS 'address (propertyaddress)',  " +
				" p.value AS 'LotPlan' " +
				" from " +
				" certificatetransrecords ct WITH(NOLOCK), " +
				" authoritytransrecords atr WITH(NOLOCK), " +
				" authoritycertificatetypes au WITH(NOLOCK), " +
				" certificatetypes cf WITH(NOLOCK), " +
				" certificateorders co WITH(NOLOCK), " +
				" dbo.PaymentMethods pm WITH(NOLOCK), " +
				" dbo.TransMethods tm WITH(NOLOCK), " +
				" dbo.Authorities ath WITH(NOLOCK), " +
				" orders o WITH(NOLOCK)  " +
				" left outer join orderpropertyfields p WITH(NOLOCK) on o.orderid = p.orderid and p.inputfieldid = 1811 where co.orderid = o.orderid and co.authoritycertificatetypeid = au.authoritycertificatetypeid and convert(datetime,convert(varchar,getdate(),112)) > DATEADD(DAY, au.overduedays + ROUND(au.overduedays/5.0,0)*2, convert(datetime,convert(varchar,atr.transtime,112))) and co.StatusID in (31,32,33,34,36) and ct.certificateorderid = co.certificateorderid and atr.authoritytransrecordid = ct.authoritytransrecordid and au.authorityid = ath.AuthorityID and au.authorityid != 140 and au.PaymentMethodID = pm.PaymentMethodID and au.TransMethodID = tm.TransMethodID and au.ProductState = 'NSW' and au.AuthorityCertificateTypeID not in (SELECT AuthorityCertificateTypeID FROM AuthorityCertificateTypes with(NOLOCK) WHERE AuthorityCertificateTypeID in (2608, 4064)) " +
				" order by " +
				" 'Product Name', " +
				" 'Certificate ID' desc";
		
		return select;
	}

	@Override
	protected void finaliseQuery() throws Exception {
	}
	
	@Override
	protected String getReportName() {
		return "100 NSW Search Manager";
	}
	
}
