package com.saiglobal.sf.reporting.processor;

public class PropertyAwatingConsignmentReport extends AbstractQueryReport {
	
	public PropertyAwatingConsignmentReport() {
		setExecuteStatement(false);
		setHeader(true);
		dateTimePattern = "d/MM/yyyy";
		columnWidth = new int[] {80,500,100,100,150,100,100,150,};
	}
	
	@Override
	protected void setCurrentDataSource() {
		this.gp.setCurrentDataSource("ssr");
	}
	
	@Override
	protected void initialiseQuery() throws Exception {
		String stmt =
				  "IF OBJECT_ID(N'tempdb.dbo.#FooNSW', 'U') IS NOT NULL BEGIN DROP TABLE #FooNSW;END;"
				+ "IF OBJECT_ID(N'tempdb.dbo.#FooVIC', 'U') IS NOT NULL BEGIN DROP TABLE #FooVIC;END;"
				+ "IF OBJECT_ID(N'tempdb.dbo.#FooTAS', 'U') IS NOT NULL BEGIN DROP TABLE #FooTAS;END;"
				+ "IF OBJECT_ID(N'tempdb.dbo.#FooQLD', 'U') IS NOT NULL BEGIN DROP TABLE #FooQLD;END;"
				+ "IF OBJECT_ID(N'tempdb.dbo.#FooACT', 'U') IS NOT NULL BEGIN DROP TABLE #FooACT;END;"
				+ "IF OBJECT_ID(N'tempdb.dbo.#FooNT', 'U') IS NOT NULL BEGIN DROP TABLE #FooNT;END;"
				+ "IF OBJECT_ID(N'tempdb.dbo.#FooSA', 'U') IS NOT NULL BEGIN DROP TABLE #FooSA;END;"
				+ "IF OBJECT_ID(N'tempdb.dbo.#FooWA', 'U') IS NOT NULL BEGIN DROP TABLE #FooWA;END;"
				+ "CREATE TABLE #FooNSW (matter_ID varchar(50), matterSSRNumber varchar(50), Entered_Date DateTime,Warning_Date DateTime,Expiry_Date DateTime,loanAccountNumber varchar(50), matterName varchar(200), created_datetime DateTime,matterStatus_desc varchar(50),transactiontype_id int,StatusID int,workflowID int,stateDesc varchar(50),StateName varchar(50),userlongname varchar(50),settlement_datetime DateTime,transactionstate_id int,package_desc varchar(50),transactiontype_desc varchar(50),IsRelease varchar(50),IsRefinance varchar(50),IsPurchase varchar(50));"
				+ "CREATE TABLE #FooVIC (matter_ID varchar(50), matterSSRNumber varchar(50), Entered_Date DateTime,Warning_Date DateTime,Expiry_Date DateTime,loanAccountNumber varchar(50), matterName varchar(200), created_datetime DateTime,matterStatus_desc varchar(50),transactiontype_id int,StatusID int,workflowID int,stateDesc varchar(50),StateName varchar(50),userlongname varchar(50),settlement_datetime DateTime,transactionstate_id int,package_desc varchar(50),transactiontype_desc varchar(50),IsRelease varchar(50),IsRefinance varchar(50),IsPurchase varchar(50));"
				+ "CREATE TABLE #FooTAS (matter_ID varchar(50), matterSSRNumber varchar(50), Entered_Date DateTime,Warning_Date DateTime,Expiry_Date DateTime,loanAccountNumber varchar(50), matterName varchar(200), created_datetime DateTime,matterStatus_desc varchar(50),transactiontype_id int,StatusID int,workflowID int,stateDesc varchar(50),StateName varchar(50),userlongname varchar(50),settlement_datetime DateTime,transactionstate_id int,package_desc varchar(50),transactiontype_desc varchar(50),IsRelease varchar(50),IsRefinance varchar(50),IsPurchase varchar(50));"
				+ "CREATE TABLE #FooQLD (matter_ID varchar(50), matterSSRNumber varchar(50), Entered_Date DateTime,Warning_Date DateTime,Expiry_Date DateTime,loanAccountNumber varchar(50), matterName varchar(200), created_datetime DateTime,matterStatus_desc varchar(50),transactiontype_id int,StatusID int,workflowID int,stateDesc varchar(50),StateName varchar(50),userlongname varchar(50),settlement_datetime DateTime,transactionstate_id int,package_desc varchar(50),transactiontype_desc varchar(50),IsRelease varchar(50),IsRefinance varchar(50),IsPurchase varchar(50));"
				+ "CREATE TABLE #FooACT (matter_ID varchar(50), matterSSRNumber varchar(50), Entered_Date DateTime,Warning_Date DateTime,Expiry_Date DateTime,loanAccountNumber varchar(50), matterName varchar(200), created_datetime DateTime,matterStatus_desc varchar(50),transactiontype_id int,StatusID int,workflowID int,stateDesc varchar(50),StateName varchar(50),userlongname varchar(50),settlement_datetime DateTime,transactionstate_id int,package_desc varchar(50),transactiontype_desc varchar(50),IsRelease varchar(50),IsRefinance varchar(50),IsPurchase varchar(50));"
				+ "CREATE TABLE #FooNT (matter_ID varchar(50), matterSSRNumber varchar(50), Entered_Date DateTime,Warning_Date DateTime,Expiry_Date DateTime,loanAccountNumber varchar(50), matterName varchar(200), created_datetime DateTime,matterStatus_desc varchar(50),transactiontype_id int,StatusID int,workflowID int,stateDesc varchar(50),StateName varchar(50),userlongname varchar(50),settlement_datetime DateTime,transactionstate_id int,package_desc varchar(50),transactiontype_desc varchar(50),IsRelease varchar(50),IsRefinance varchar(50),IsPurchase varchar(50));"
				+ "CREATE TABLE #FooSA (matter_ID varchar(50), matterSSRNumber varchar(50), Entered_Date DateTime,Warning_Date DateTime,Expiry_Date DateTime,loanAccountNumber varchar(50), matterName varchar(200), created_datetime DateTime,matterStatus_desc varchar(50),transactiontype_id int,StatusID int,workflowID int,stateDesc varchar(50),StateName varchar(50),userlongname varchar(50),settlement_datetime DateTime,transactionstate_id int,package_desc varchar(50),transactiontype_desc varchar(50),IsRelease varchar(50),IsRefinance varchar(50),IsPurchase varchar(50));"
				+ "CREATE TABLE #FooWA (matter_ID varchar(50), matterSSRNumber varchar(50), Entered_Date DateTime,Warning_Date DateTime,Expiry_Date DateTime,loanAccountNumber varchar(50), matterName varchar(200), created_datetime DateTime,matterStatus_desc varchar(50),transactiontype_id int,StatusID int,workflowID int,stateDesc varchar(50),StateName varchar(50),userlongname varchar(50),settlement_datetime DateTime,transactionstate_id int,package_desc varchar(50),transactiontype_desc varchar(50),IsRelease varchar(50),IsRefinance varchar(50),IsPurchase varchar(50));"
				+ "INSERT #FooNSW EXEC up_GetAwaitingConsignmentQueue 'anzret','ANZ','1','NSW';"
				+ "INSERT #FooNSW EXEC up_GetAwaitingConsignmentQueue 'anzsbf','ANZ','1','NSW';"
				+ "INSERT #FooNSW EXEC up_GetAwaitingConsignmentQueue 'anzbus','ANZ','1','NSW';"
				+ "INSERT #FooVIC EXEC up_GetAwaitingConsignmentQueue 'anzret','ANZ','2','VIC';"
				+ "INSERT #FooVIC EXEC up_GetAwaitingConsignmentQueue 'anzsbf','ANZ','2','VIC';"
				+ "INSERT #FooVIC EXEC up_GetAwaitingConsignmentQueue 'anzbus','ANZ','2','VIC';"
				+ "INSERT #FooTAS EXEC up_GetAwaitingConsignmentQueue 'anzret','ANZ','3','TAS';"
				+ "INSERT #FooTAS EXEC up_GetAwaitingConsignmentQueue 'anzsbf','ANZ','3','TAS';"
				+ "INSERT #FooTAS EXEC up_GetAwaitingConsignmentQueue 'anzbus','ANZ','3','TAS';"
				+ "INSERT #FooQLD EXEC up_GetAwaitingConsignmentQueue 'anzret','ANZ','4','QLD';"
				+ "INSERT #FooQLD EXEC up_GetAwaitingConsignmentQueue 'anzsbf','ANZ','4','QLD';"
				+ "INSERT #FooQLD EXEC up_GetAwaitingConsignmentQueue 'anzbus','ANZ','4','QLD';"
				+ "INSERT #FooACT EXEC up_GetAwaitingConsignmentQueue 'anzret','ANZ','5','ACT';"
				+ "INSERT #FooACT EXEC up_GetAwaitingConsignmentQueue 'anzsbf','ANZ','5','ACT';"
				+ "INSERT #FooACT EXEC up_GetAwaitingConsignmentQueue 'anzbus','ANZ','5','ACT';"
				+ "INSERT #FooNT EXEC up_GetAwaitingConsignmentQueue 'anzret','ANZ','6','NT';"
				+ "INSERT #FooNT EXEC up_GetAwaitingConsignmentQueue 'anzsbf','ANZ','6','NT';"
				+ "INSERT #FooNT EXEC up_GetAwaitingConsignmentQueue 'anzbus','ANZ','6','NT';"
				+ "INSERT #FooSA EXEC up_GetAwaitingConsignmentQueue 'anzret','ANZ','7','SA';"
				+ "INSERT #FooSA EXEC up_GetAwaitingConsignmentQueue 'anzsbf','ANZ','7','SA';"
				+ "INSERT #FooSA EXEC up_GetAwaitingConsignmentQueue 'anzbus','ANZ','7','SA';"
				+ "INSERT #FooWA EXEC up_GetAwaitingConsignmentQueue 'anzret','ANZ','8','WA';"
				+ "INSERT #FooWA EXEC up_GetAwaitingConsignmentQueue 'anzsbf','ANZ','8','WA';"
				+ "INSERT #FooWA EXEC up_GetAwaitingConsignmentQueue 'anzbus','ANZ','8','WA';";
		
		st.executeUpdate(stmt);
	}
	
	@Override
	protected String getQuery() {
		String select = 
				  "SELECT matterSSRNumber AS 'SSR #', matterName AS 'Matter Name', loanAccountNumber AS 'Loan Account', settlement_datetime AS 'Settlement Date', matterStatus_desc AS 'Matter Status', Entered_Date AS 'Entered', Expiry_Date AS 'Due Date', package_desc AS 'Service Package', '' AS 'OFI Name', '' AS 'OFI Phone', transactiontype_desc AS 'Purchase', 'NSW' AS 'State' FROM #FooNSW "
				+ "UNION "
				+ "SELECT matterSSRNumber AS 'SSR #', matterName AS 'Matter Name', loanAccountNumber AS 'Loan Account', settlement_datetime AS 'Settlement Date', matterStatus_desc AS 'Matter Status', Entered_Date AS 'Entered', Expiry_Date AS 'Due Date', package_desc AS 'Service Package', '' AS 'OFI Name', '' AS 'OFI Phone', transactiontype_desc AS 'Purchase', 'VIC' AS 'State' FROM #FooVIC "
				+ "UNION "
				+ "SELECT matterSSRNumber AS 'SSR #', matterName AS 'Matter Name', loanAccountNumber AS 'Loan Account', settlement_datetime AS 'Settlement Date', matterStatus_desc AS 'Matter Status', Entered_Date AS 'Entered', Expiry_Date AS 'Due Date', package_desc AS 'Service Package', '' AS 'OFI Name', '' AS 'OFI Phone', transactiontype_desc AS 'Purchase', 'TAS' AS 'State' FROM #FooTAS "
				+ "UNION "
				+ "SELECT matterSSRNumber AS 'SSR #', matterName AS 'Matter Name', loanAccountNumber AS 'Loan Account', settlement_datetime AS 'Settlement Date', matterStatus_desc AS 'Matter Status', Entered_Date AS 'Entered', Expiry_Date AS 'Due Date', package_desc AS 'Service Package', '' AS 'OFI Name', '' AS 'OFI Phone', transactiontype_desc AS 'Purchase', 'ACT' AS 'State' FROM #FooACT "
				+ "UNION "
				+ "SELECT matterSSRNumber AS 'SSR #', matterName AS 'Matter Name', loanAccountNumber AS 'Loan Account', settlement_datetime AS 'Settlement Date', matterStatus_desc AS 'Matter Status', Entered_Date AS 'Entered', Expiry_Date AS 'Due Date', package_desc AS 'Service Package', '' AS 'OFI Name', '' AS 'OFI Phone', transactiontype_desc AS 'Purchase', 'NT' AS 'State' FROM #FooNT "
				+ "UNION "
				+ "SELECT matterSSRNumber AS 'SSR #', matterName AS 'Matter Name', loanAccountNumber AS 'Loan Account', settlement_datetime AS 'Settlement Date', matterStatus_desc AS 'Matter Status', Entered_Date AS 'Entered', Expiry_Date AS 'Due Date', package_desc AS 'Service Package', '' AS 'OFI Name', '' AS 'OFI Phone', transactiontype_desc AS 'Purchase', 'SA' AS 'State' FROM #FooSA "
				+ "UNION "
				+ "SELECT matterSSRNumber AS 'SSR #', matterName AS 'Matter Name', loanAccountNumber AS 'Loan Account', settlement_datetime AS 'Settlement Date', matterStatus_desc AS 'Matter Status', Entered_Date AS 'Entered', Expiry_Date AS 'Due Date', package_desc AS 'Service Package', '' AS 'OFI Name', '' AS 'OFI Phone', transactiontype_desc AS 'Purchase', 'WA' AS 'State' FROM #FooWA "
				+ "UNION "
				+ "SELECT matterSSRNumber AS 'SSR #', matterName AS 'Matter Name', loanAccountNumber AS 'Loan Account', settlement_datetime AS 'Settlement Date', matterStatus_desc AS 'Matter Status', Entered_Date AS 'Entered', Expiry_Date AS 'Due Date', package_desc AS 'Service Package', '' AS 'OFI Name', '' AS 'OFI Phone', transactiontype_desc AS 'Purchase', 'QLD' AS 'State' FROM #FooQLD "
				+ "ORDER BY State";
		
		return select;
	}

	@Override
	protected void finaliseQuery() throws Exception {
		String stmt = 
				  "DROP TABLE #FooNSW;"
				+ "DROP TABLE #FooVIC;"
				+ "DROP TABLE #FooTAS;"
				+ "DROP TABLE #FooQLD;"
				+ "DROP TABLE #FooACT;"
				+ "DROP TABLE #FooSA;"
				+ "DROP TABLE #FooWA;";
		st.executeUpdate(stmt);
	}
	
	@Override
	protected String getReportName() {
		return "Awating Consignment Report";
	}
	
}
