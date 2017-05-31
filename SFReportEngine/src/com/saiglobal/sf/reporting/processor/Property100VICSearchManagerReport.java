package com.saiglobal.sf.reporting.processor;

public class Property100VICSearchManagerReport extends AbstractQueryReport {
	
	public Property100VICSearchManagerReport() {
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
				"SELECT DISTINCT" +
				" CAST(o.OrderID AS VARCHAR) AS 'Order ID'," +
				" CAST(co.certificateorderid AS VARCHAR) AS 'Certificate ID'," +
				" act.ProductName AS 'Product Name'," +
				" ABS(DATEDIFF(DAY, atr.transtime, GETDATE())) - ABS(DATEDIFF(WEEK, atr.transtime, GETDATE())*2) - act.overduedays AS 'Overdue'," +
				" atr.transtime AS 'Trans Date (date)'," +
				" CAST(o.OrderID AS VARCHAR) AS 'address (propertyaddress)', " +
				" CASE WHEN opf1.Value IS NULL THEN '' ELSE opf1.Value END 'Settlement Date'" +
				" FROM CertificateOrders co with(nolock)" +
				" JOIN Orders o with(nolock) ON co.OrderID = o.OrderID AND co.StatusID IN (31,32,33,34,35,36) " +
				" LEFT JOIN OrderPropertyFields opf1 with(nolock) ON o.OrderID = opf1.OrderID AND opf1.InputFieldID IN ('8', NULL) " +
				" JOIN AuthorityCertificateTypes act with(nolock) ON co.AuthorityCertificateTypeID = act.AuthorityCertificateTypeID and act.ProductState = 'VIC'" +
				" JOIN dbo.Authorities au with(nolock) ON act.AuthorityID = au.authorityid and au.Type IN ('Water', 'Council', 'Heritage', 'Regional', 'State', 'Roads', 'Company') AND act.AuthorityID != '2279'" +
				" AND act.AuthorityID != '3'" +
				" JOIN CertificateTransRecords ctr with(nolock) ON ctr.CertificateOrderID = co.CertificateOrderID" +
				" JOIN AuthorityTransRecords atr with(nolock) ON atr.AuthorityTransRecordID = ctr.AuthorityTransRecordID WHERE CONVERT(DATETIME,CONVERT(VARCHAR,getdate(),112)) > DATEADD(DAY, act.overduedays + ROUND(act.overduedays/5.0,0)*2, CONVERT(DATETIME,CONVERT(VARCHAR,atr.transtime,112))) and act.AuthorityCertificateTypeID NOT IN (SELECT AuthorityCertificateTypeID FROM dbo.AuthorityCertificateTypes with(NOLOCK) WHERE AuthorityCertificateTypeID IN ('17', '47', '50', '55', '83', '364', '365', '366', '367', '368', '369', '370', '371', '373', '374', '375', '376', '377', '378', '379', '380', '381', '1609', '2373', '3203', '3212', '3213', '3218', '3219', '3256', '3260', '3261', '3267', '3268', '3281', '3282', '3294', '3295', '3302', '3313', '3314', '3315', '3316', '3317', '3318', '3323', '3325', '3338', '3345', '3367', '3368', '3377', '3392', '3393','3403','3404','3434','3435','3443','3444','3459','3472','3476','3482','3501','3511','3512','3513','3514','3522','3523','3524','3525','3532','3534','3536','3541','3542','3544','3545','3565','3593','3602','3643','3652','3674','3683','3684','3691','3692','3698','3699','3715','3718','3719','3720','3721','3801','3802','3870','3871','3872','3873','3874','3875','4023','4028','4047','4049','4051','4053','4057','4061','4148','4150','4158','4213','4244','4258','4281','4295','4306','4368','4378','4391','4412','4421','4447','4458','4498','4499','4508','4534','4535','4553','4566','4577','4597','4619','4628','4642','4653','4654','4664','4675','4687','4703','4704','4730','4731','4742','4755','4756','4766','4778','4789','4790','4809','4835','4836','4848','4863','4873','4883','4897','4915','4948','4961','4979','5013','5014','5021','5046','5069','5070','5081','5101','5143','5153','5174','5183','5191','5199','5207','5218','5229','5264','5279','5288','5305','5344','5370','5395','5433','5444','5453','5497','5521','5540','5549','5564','5586','5597','5605','5636','5645','5670','5696','5722','5730','5751','5792','5802','5813','5814','7273','7304','7320','7336','7371','7396','7398','7405','7434','7481','7482','7590','7592','7611','7612','7613','7863','7933','7939','7945','7961','8125','8217','8242')) and act.AuthorityCertificateTypeID NOT IN (SELECT AuthorityCertificateTypeID FROM dbo.AuthorityCertificateTypes with(NOLOCK) WHERE AuthorityCertificateTypeID IN('114','158','159','160','161','162','163','164','165','166','167','168','169','170','171','173','174','175','387','398','408','409','410','534','549','550','551','558','559','560','947','948','1202','1203','1204','1205','1364','1365','1366','1460','1553','1962','1998','1999','2632','2633','2634','2702','2703','2704','2708','2709','2726','2750','2751','2752','2753','2754','2755','2756','2757','2758','2759','8315','8316','8317','8360','8370','8371','8591','8592','8605','8606','8607','8608','8609')) and act.AuthorityCertificateTypeID NOT IN (SELECT AuthorityCertificateTypeID FROM dbo.AuthorityCertificateTypes with(NOLOCK) WHERE AuthorityCertificateTypeID IN('179','271','3851','4062','5923','6446','6622')) " +
				" and act.AuthorityCertificateTypeID != 9281" +
				" order BY ProductName ASC, Overdue DESC";
		
		return select;
	}

	@Override
	protected void finaliseQuery() throws Exception {
	}
	
	@Override
	protected String getReportName() {
		return "100 VIC Search Manager";
	}
	
}
