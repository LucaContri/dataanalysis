package com.saiglobal.sf.reporting.processor;

public class Property100QLDSearchManagerReport extends AbstractQueryReport {
	
	public Property100QLDSearchManagerReport() {
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
				"SELECT " +
				" DISTINCT " +
				" CAST(o.orderid AS VARCHAR) AS 'Order ID', " +
				" CAST(co.certificateorderid AS VARCHAR) AS 'Certificate ID',  " +
				" act.ProductName AS 'Product Name', " +
				" ABS(DATEDIFF(DAY, " +
				" atr.transtime, " +
				" GETDATE())) - ABS(DATEDIFF(WEEK, atr.transtime, GETDATE())*2) - act.overduedays AS 'Overdue', " +
				" atr.transtime 'Trans Date (date)', " +
				" tm.DisplayName 'Trans Method', " +
				" pm.DisplayName 'Payment Method', " +
				" o.OrderID AS 'address (propertyaddress)',  " +
				" CASE WHEN opf1.Value IS NULL THEN '' ELSE opf1.Value END 'Plan Type', " +
				" CASE WHEN opf2.Value IS NULL THEN '' ELSE opf2.Value END 'Lot Number', " +
				" CASE WHEN opf3.Value IS NULL THEN '' ELSE opf3.Value END 'Plan Number', " +
				" CASE WHEN opf4.Value IS NULL THEN '' ELSE opf4.Value END 'Reading Date', " +
				" CASE WHEN opf5.Value IS NULL THEN '' ELSE opf5.Value END 'Settlement Date' " +
				" FROM " +
				" CertificateOrders co with(nolock)  " +
				" JOIN Orders o with(nolock) ON co.OrderID = o.OrderID AND co.StatusID IN (31,32,33,34,35,36)  " +
				" LEFT JOIN OrderPropertyFields opf1 with(nolock) ON o.OrderID = opf1.OrderID AND opf1.InputFieldID IN ('2301',NULL)  " +
				" LEFT JOIN InputFields ifld1 with(nolock) ON opf1.InputFieldID = ifld1.InputFieldID " +
				" LEFT JOIN OrderPropertyFields opf2 with(nolock) ON o.OrderID = opf2.OrderID AND opf2.InputFieldID IN ('3671',NULL)  " +
				" LEFT JOIN InputFields ifld2 with(nolock) ON opf2.InputFieldID = ifld2.InputFieldID  " +
				" LEFT JOIN OrderPropertyFields opf3 with(nolock) ON o.OrderID = opf3.OrderID AND opf3.InputFieldID IN ('2302',NULL)  " +
				" LEFT JOIN InputFields ifld3 with(nolock) ON opf3.InputFieldID = ifld3.InputFieldID " +
				" LEFT JOIN OrderPropertyFields opf4 with(nolock) ON o.OrderID = opf4.OrderID AND opf4.InputFieldID IN ('3697',NULL)  " +
				" LEFT JOIN OrderPropertyFields opf5 with(nolock) ON o.OrderID = opf5.OrderID AND opf5.InputFieldID IN ('3696',NULL)  " +
				" LEFT JOIN InputFields ifld4 with(nolock) ON opf4.InputFieldID = ifld4.InputFieldID  " +
				" JOIN AuthorityCertificateTypes act with(nolock) ON co.AuthorityCertificateTypeID = act.AuthorityCertificateTypeID  " +
				" JOIN dbo.Authorities au with(nolock) ON act.AuthorityID = au.authorityid AND au.State = 'QLD'  " +
				" JOIN PaymentMethods pm with(nolock) ON act.PaymentMethodID = pm.PaymentMethodID  " +
				" JOIN TransMethods tm with(nolock) ON act.TransMethodID = tm.TransMethodID  " +
				" JOIN CertificateTransRecords ctr with(nolock) ON ctr.CertificateOrderID = co.CertificateOrderID JOIN AuthorityTransRecords atr with(nolock) ON atr.AuthorityTransRecordID = ctr.AuthorityTransRecordID "
				+ "WHERE CONVERT(DATETIME,CONVERT(VARCHAR,getdate(),112)) > DATEADD(DAY, act.overduedays + ROUND(act.overduedays/5.0,0)*2, CONVERT(DATETIME,CONVERT(VARCHAR,atr.transtime,112))) and act.AuthorityCertificateTypeID NOT IN (SELECT AuthorityCertificateTypeID FROM dbo.AuthorityCertificateTypes with(NOLOCK) WHERE AuthorityCertificateTypeID IN (17,47,50,55,83,364,365,366,367,368,369,370,371,373,374,375,376,377,378,379,380,381,589,590,591,592,593,594,595,1609,1684,2371,2372,2373,2631,3203,3212,3213,3218,3219,3256,3260,3261,3267,3268,3281,3282,3294,3295,3302,3313,3314,3315,3316,3317,3318,3323,3325,3338,3345,3367,3368,3377,3392,3393,3403,3404,3434,3435,3443,3444,3459,3472,3476,3482,3501,3511,3512,3513,3514,3522,3523,3524,3525,3532,3534,3536,3541,3542,3544,3545,3565,3593,3602,3643,3652,3674,3683,3684,3691,3692,3698,3699,3715,3718,3719,3720,3721,3801,3802,3870,3871,3872,3873,3874,3875,4023,4028,4047,4049,4051,4053,4057,4061,4148,4150,4213,4244,4258,4281,4295,4306,4368,4378,4391,4412,4421,4447,4458,4498,4499,4508,4534,4535,4553,4566,4577,4597,4619,4628,4642,4653,4654,4664,4675,4687,4703,4704,4730,4731,4742,4755,4756,4766,4778,4789,4790,4809,4835,4836,4848,4863,4873,4883,4897,4915,4948,4961,4979,5013,5014,5021,5046,5069,5070,5081,5101,5143,5153,5174,5183,5191,5199,5207,5218,5229,5264,5279,5288,5305,5344,5370,5395,5433,5444,5453,5497,5521,5540,5549,5564,5586,5597,5605,5636,5645,5670,5696,5722,5730,5751,5792,5802,5813,5814,7273,7304,7320,7336,7371,7396,7398,7405,7434,7481,7482,7590,7592,7611,7612,7613,7863,7933,7939,7945,7961,8125,8217,8242,8831,8832,4158, 184,2768,2769,2770,2771,3000,3001,3002,3003,3004,3005,3006,3007,3008,3009,3010,3011,3012,3013,3014,3015,3016,3017,3018,8312,8313,8314,8599,8600,8601,8602,8603,7251,7252) ) "
				+ "and opf1.InputFieldIndex = 1 "
				+ "and opf2.InputFieldIndex = 1 "
				+ "and opf3.InputFieldIndex = 1 "
				+ " ORDER BY 'Product Name', 'Certificate ID' DESC";
		
		return select;
	}

	@Override
	protected void finaliseQuery() throws Exception {
	}
	
	@Override
	protected String getReportName() {
		return "100 QLD Search Manager";
	}
	
}
