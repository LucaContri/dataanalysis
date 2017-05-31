package com.saiglobal.sf.reporting.processor;

import java.text.SimpleDateFormat;
import java.util.Calendar;

public class PropertyTAMSBalancesReport extends AbstractQueryReport {
	
	public PropertyTAMSBalancesReport() {
		setExecuteStatement(false);
		setHeader(true);
		dateTimePattern = "d/MM/yyyy";
		//columnWidth = new int[] {80,500,100,100,150,100,100,150,};
	}
	
	@Override
	protected void setCurrentDataSource() {
		this.gp.setCurrentDataSource("ssr");
	}
	
	@Override
	protected void initialiseQuery() throws Exception {
	}
	
	@Override
	protected String getQuery() {
		SimpleDateFormat dateFormat = new SimpleDateFormat("MM/d/yyyy");
		Calendar today = Calendar.getInstance();
		String select = 
				"SELECT  " +
				" DISTINCT " +
				" tm.SSR AS 'SSR', " +
				" tm.[Initial Deposit Date] AS 'Initial Deposit Date', " +
				" tm.[Stmt Date] AS 'Stmt Date', " +
				" tm.Created AS 'Created', " +
				" tm.Loan AS 'Loan', " +
				" tm.Matter AS 'Matter', " +
				" tm.Balance AS 'Balance', " +
				" tm.Reconciled AS 'Reconciled', " +
				" tm.[Unreconciled (Depricated)] AS 'Unreconciled (Depricated)', " +
				" tm.MatterStatus 'Status', " +
				" tm.ClientId AS 'ClientId', " +
				" tm.AusState AS 'State' " +
				" FROM TB_TRUSTCLIENTREF tcr " +
				" INNER JOIN( " +
				" SELECT  " +
				" DISTINCT " +
				" tcr.SSRNumber AS 'SSR', " +
				" CONVERT(VARCHAR,Min(td.effective_datetime),103) AS 'Initial Deposit Date', " +
				" CONVERT(VARCHAR,MAX(ts.statement_date),103) AS 'Stmt Date', " +
				" CONVERT(VARCHAR,MIN(td.created_datetime),103) AS 'Created', " +
				" tcr.LoanNumber AS 'Loan', " +
				" tcr.MatterName AS 'Matter', " +
				" SUM(case when ta.accountName = 'NSW' AND (td.trustTranType_Id <> 55 or td.tran_amt < 0) then td.tran_amt else 0 end)  AS 'Balance', " +
				" SUM(case when td.isSuspenseItem='N' AND (td.trustTranType_Id <> 55 or td.tran_amt < 0) then td.tran_amt else 0 end) AS 'Reconciled', " +
				" '' AS 'Unreconciled (Depricated)', " +
				" ms.MatterStatus_desc AS 'MatterStatus', " +
				" tcr.trustClientRef_Id AS 'refId', " +
				" tcr.trustClient_Id AS 'ClientId', " +
				" m.Matter_Id AS 'MatterID', " +
				" aus.StateShort_desc AS 'AusState' " +
				" FROM TB_TRUSTCLIENTREF tcr " +
				" LEFT JOIN TB_TRUSTDETAIL td ON tcr.trustClientRef_Id=td.trustClientRef_Id " +
				" LEFT JOIN TB_TRUSTSTATEMENT ts ON td.trustStatement_Id=ts.trustStatement_id " +
				" LEFT JOIN TB_TRUSTACCOUNT ta ON td.trustAccount_Id=ta.trustAccount_Id " +
				" LEFT JOIN TB_MATTER m ON tcr.SSRNumber=m.MatterSSRNumber " +
				" LEFT JOIN TB_MATTERSTATUS ms ON m.MatterStatus_Id=ms.MatterStatus_Id " +
				" LEFT JOIN TB_AUSTSTATE aus ON m.TransactionState_Id=aus.AustState_Id " +
				" WHERE (tcr.Updated_datetime between '05/09/2014 00:00:00' and '" + dateFormat.format(today.getTime()) + "')  " +
				" GROUP BY " +
				" tcr.SSRNumber, " +
				" tcr.LoanNumber, " +
				" tcr.Updated_datetime, " +
				" tcr.MatterName, " +
				" ms.MatterStatus_desc, " +
				" tcr.trustClientRef_Id, " +
				" tcr.trustClient_Id, " +
				" m.Matter_Id, " +
				" aus.StateShort_desc " +
				" ) tm ON tcr.SSRNumber=tm.SSR AND tm.Balance <> 0 AND tm.Balance > 0 " +
				" UNION " +
				" SELECT  " +
				" DISTINCT " +
				" tm.SSR AS 'SSR', " +
				" tm.[Initial Deposit Date] AS 'Initial Deposit Date', " +
				" tm.[Stmt Date] AS 'Stmt Date', " +
				" tm.Created AS 'Created', " +
				" tm.Loan AS 'Loan', " +
				" tm.Matter AS 'Matter', " +
				" tm.Balance AS 'Balance', " +
				" tm.Reconciled AS 'Reconciled', " +
				" tm.[Unreconciled (Depricated)] AS 'Unreconciled (Depricated)', " +
				" tm.MatterStatus 'Status', " +
				" tm.ClientId AS 'ClientId', " +
				" tm.AusState AS 'State' " +
				" FROM TB_TRUSTCLIENTREF tcr " +
				" INNER JOIN( " +
				" SELECT  " +
				" DISTINCT " +
				" tcr.SSRNumber AS 'SSR', " +
				" CONVERT(VARCHAR,Min(td.effective_datetime),103) AS 'Initial Deposit Date', " +
				" CONVERT(VARCHAR,MAX(ts.statement_date),103) AS 'Stmt Date', " +
				" CONVERT(VARCHAR,MIN(td.created_datetime),103) AS 'Created', " +
				" tcr.LoanNumber AS 'Loan', " +
				" tcr.MatterName AS 'Matter', " +
				" SUM(case when ta.accountName = 'VIC' AND (td.trustTranType_Id <> 55 or td.tran_amt < 0) then td.tran_amt else 0 end)  AS 'Balance', " +
				" SUM(case when td.isSuspenseItem='N' AND (td.trustTranType_Id <> 55 or td.tran_amt < 0) then td.tran_amt else 0 end) AS 'Reconciled', " +
				" '' AS 'Unreconciled (Depricated)', " +
				" ms.MatterStatus_desc AS 'MatterStatus', " +
				" tcr.trustClientRef_Id AS 'refId', " +
				" tcr.trustClient_Id AS 'ClientId', " +
				" m.Matter_Id AS 'MatterID', " +
				" aus.StateShort_desc AS 'AusState' " +
				" FROM TB_TRUSTCLIENTREF tcr " +
				" LEFT JOIN TB_TRUSTDETAIL td ON tcr.trustClientRef_Id=td.trustClientRef_Id " +
				" LEFT JOIN TB_TRUSTSTATEMENT ts ON td.trustStatement_Id=ts.trustStatement_id " +
				" LEFT JOIN TB_TRUSTACCOUNT ta ON td.trustAccount_Id=ta.trustAccount_Id " +
				" LEFT JOIN TB_MATTER m ON tcr.SSRNumber=m.MatterSSRNumber " +
				" LEFT JOIN TB_MATTERSTATUS ms ON m.MatterStatus_Id=ms.MatterStatus_Id " +
				" LEFT JOIN TB_AUSTSTATE aus ON m.TransactionState_Id=aus.AustState_Id " +
				" WHERE (tcr.Updated_datetime between '05/09/2014 00:00:00' and '" + dateFormat.format(today.getTime()) + "')  " +
				" GROUP BY " +
				" tcr.SSRNumber, " +
				" tcr.LoanNumber, " +
				" tcr.Updated_datetime, " +
				" tcr.MatterName, " +
				" ms.MatterStatus_desc, " +
				" tcr.trustClientRef_Id, " +
				" tcr.trustClient_Id, " +
				" m.Matter_Id, " +
				" aus.StateShort_desc " +
				" ) tm ON tcr.SSRNumber=tm.SSR AND tm.Balance <> 0 AND tm.Balance > 0 " +
				" UNION " +
				" SELECT  " +
				" DISTINCT " +
				" tm.SSR AS 'SSR', " +
				" tm.[Initial Deposit Date] AS 'Initial Deposit Date', " +
				" tm.[Stmt Date] AS 'Stmt Date', " +
				" tm.Created AS 'Created', " +
				" tm.Loan AS 'Loan', " +
				" tm.Matter AS 'Matter', " +
				" tm.Balance AS 'Balance', " +
				" tm.Reconciled AS 'Reconciled', " +
				" tm.[Unreconciled (Depricated)] AS 'Unreconciled (Depricated)', " +
				" tm.MatterStatus 'Status', " +
				" tm.ClientId AS 'ClientId', " +
				" tm.AusState AS 'State' " +
				" FROM TB_TRUSTCLIENTREF tcr " +
				" INNER JOIN( " +
				" SELECT  " +
				" DISTINCT " +
				" tcr.SSRNumber AS 'SSR', " +
				" CONVERT(VARCHAR,Min(td.effective_datetime),103) AS 'Initial Deposit Date', " +
				" CONVERT(VARCHAR,MAX(ts.statement_date),103) AS 'Stmt Date', " +
				" CONVERT(VARCHAR,MIN(td.created_datetime),103) AS 'Created', " +
				" tcr.LoanNumber AS 'Loan', " +
				" tcr.MatterName AS 'Matter', " +
				" SUM(case when ta.accountName = 'QLD' AND (td.trustTranType_Id <> 55 or td.tran_amt < 0) then td.tran_amt else 0 end)  AS 'Balance', " +
				" SUM(case when td.isSuspenseItem='N' AND (td.trustTranType_Id <> 55 or td.tran_amt < 0) then td.tran_amt else 0 end) AS 'Reconciled', " +
				" '' AS 'Unreconciled (Depricated)', " +
				" ms.MatterStatus_desc AS 'MatterStatus', " +
				" tcr.trustClientRef_Id AS 'refId', " +
				" tcr.trustClient_Id AS 'ClientId', " +
				" m.Matter_Id AS 'MatterID', " +
				" aus.StateShort_desc AS 'AusState' " +
				" FROM TB_TRUSTCLIENTREF tcr " +
				" LEFT JOIN TB_TRUSTDETAIL td ON tcr.trustClientRef_Id=td.trustClientRef_Id " +
				" LEFT JOIN TB_TRUSTSTATEMENT ts ON td.trustStatement_Id=ts.trustStatement_id " +
				" LEFT JOIN TB_TRUSTACCOUNT ta ON td.trustAccount_Id=ta.trustAccount_Id " +
				" LEFT JOIN TB_MATTER m ON tcr.SSRNumber=m.MatterSSRNumber " +
				" LEFT JOIN TB_MATTERSTATUS ms ON m.MatterStatus_Id=ms.MatterStatus_Id " +
				" LEFT JOIN TB_AUSTSTATE aus ON m.TransactionState_Id=aus.AustState_Id " +
				" WHERE (tcr.Updated_datetime between '05/09/2014 00:00:00' and '" + dateFormat.format(today.getTime()) + "')  " +
				" GROUP BY " +
				" tcr.SSRNumber, " +
				" tcr.LoanNumber, " +
				" tcr.Updated_datetime, " +
				" tcr.MatterName, " +
				" ms.MatterStatus_desc, " +
				" tcr.trustClientRef_Id, " +
				" tcr.trustClient_Id, " +
				" m.Matter_Id, " +
				" aus.StateShort_desc " +
				" ) tm ON tcr.SSRNumber=tm.SSR AND tm.Balance <> 0 AND tm.Balance > 0 " +
				" UNION " +
				" SELECT  " +
				" DISTINCT " +
				" tm.SSR AS 'SSR', " +
				" tm.[Initial Deposit Date] AS 'Initial Deposit Date', " +
				" tm.[Stmt Date] AS 'Stmt Date', " +
				" tm.Created AS 'Created', " +
				" tm.Loan AS 'Loan', " +
				" tm.Matter AS 'Matter', " +
				" tm.Balance AS 'Balance', " +
				" tm.Reconciled AS 'Reconciled', " +
				" tm.[Unreconciled (Depricated)] AS 'Unreconciled (Depricated)', " +
				" tm.MatterStatus 'Status', " +
				" tm.ClientId AS 'ClientId', " +
				" tm.AusState AS 'State' " +
				" FROM TB_TRUSTCLIENTREF tcr " +
				" INNER JOIN( " +
				" SELECT  " +
				" DISTINCT " +
				" tcr.SSRNumber AS 'SSR', " +
				" CONVERT(VARCHAR,Min(td.effective_datetime),103) AS 'Initial Deposit Date', " +
				" CONVERT(VARCHAR,MAX(ts.statement_date),103) AS 'Stmt Date', " +
				" CONVERT(VARCHAR,MIN(td.created_datetime),103) AS 'Created', " +
				" tcr.LoanNumber AS 'Loan', " +
				" tcr.MatterName AS 'Matter', " +
				" SUM(case when ta.accountName = 'SA' AND (td.trustTranType_Id <> 55 or td.tran_amt < 0) then td.tran_amt else 0 end)  AS 'Balance', " +
				" SUM(case when td.isSuspenseItem='N' AND (td.trustTranType_Id <> 55 or td.tran_amt < 0) then td.tran_amt else 0 end) AS 'Reconciled', " +
				" '' AS 'Unreconciled (Depricated)', " +
				" ms.MatterStatus_desc AS 'MatterStatus', " +
				" tcr.trustClientRef_Id AS 'refId', " +
				" tcr.trustClient_Id AS 'ClientId', " +
				" m.Matter_Id AS 'MatterID', " +
				" aus.StateShort_desc AS 'AusState' " +
				" FROM TB_TRUSTCLIENTREF tcr " +
				" LEFT JOIN TB_TRUSTDETAIL td ON tcr.trustClientRef_Id=td.trustClientRef_Id " +
				" LEFT JOIN TB_TRUSTSTATEMENT ts ON td.trustStatement_Id=ts.trustStatement_id " +
				" LEFT JOIN TB_TRUSTACCOUNT ta ON td.trustAccount_Id=ta.trustAccount_Id " +
				" LEFT JOIN TB_MATTER m ON tcr.SSRNumber=m.MatterSSRNumber " +
				" LEFT JOIN TB_MATTERSTATUS ms ON m.MatterStatus_Id=ms.MatterStatus_Id " +
				" LEFT JOIN TB_AUSTSTATE aus ON m.TransactionState_Id=aus.AustState_Id " +
				" WHERE (tcr.Updated_datetime between '05/09/2014 00:00:00' and '" + dateFormat.format(today.getTime()) + "')  " +
				" GROUP BY " +
				" tcr.SSRNumber, " +
				" tcr.LoanNumber, " +
				" tcr.Updated_datetime, " +
				" tcr.MatterName, " +
				" ms.MatterStatus_desc, " +
				" tcr.trustClientRef_Id, " +
				" tcr.trustClient_Id, " +
				" m.Matter_Id, " +
				" aus.StateShort_desc " +
				" ) tm ON tcr.SSRNumber=tm.SSR AND tm.Balance <> 0 AND tm.Balance > 0 " +
				" UNION " +
				" SELECT  " +
				" DISTINCT " +
				" tm.SSR AS 'SSR', " +
				" tm.[Initial Deposit Date] AS 'Initial Deposit Date', " +
				" tm.[Stmt Date] AS 'Stmt Date', " +
				" tm.Created AS 'Created', " +
				" tm.Loan AS 'Loan', " +
				" tm.Matter AS 'Matter', " +
				" tm.Balance AS 'Balance', " +
				" tm.Reconciled AS 'Reconciled', " +
				" tm.[Unreconciled (Depricated)] AS 'Unreconciled (Depricated)', " +
				" tm.MatterStatus 'Status', " +
				" tm.ClientId AS 'ClientId', " +
				" tm.AusState AS 'State' " +
				" FROM TB_TRUSTCLIENTREF tcr " +
				" INNER JOIN( " +
				" SELECT  " +
				" DISTINCT " +
				" tcr.SSRNumber AS 'SSR', " +
				" CONVERT(VARCHAR,Min(td.effective_datetime),103) AS 'Initial Deposit Date', " +
				" CONVERT(VARCHAR,MAX(ts.statement_date),103) AS 'Stmt Date', " +
				" CONVERT(VARCHAR,MIN(td.created_datetime),103) AS 'Created', " +
				" tcr.LoanNumber AS 'Loan', " +
				" tcr.MatterName AS 'Matter', " +
				" SUM(case when ta.accountName = 'WA' AND (td.trustTranType_Id <> 55 or td.tran_amt < 0) then td.tran_amt else 0 end)  AS 'Balance', " +
				" SUM(case when td.isSuspenseItem='N' AND (td.trustTranType_Id <> 55 or td.tran_amt < 0) then td.tran_amt else 0 end) AS 'Reconciled', " +
				" '' AS 'Unreconciled (Depricated)', " +
				" ms.MatterStatus_desc AS 'MatterStatus', " +
				" tcr.trustClientRef_Id AS 'refId', " +
				" tcr.trustClient_Id AS 'ClientId', " +
				" m.Matter_Id AS 'MatterID', " +
				" aus.StateShort_desc AS 'AusState' " +
				" FROM TB_TRUSTCLIENTREF tcr " +
				" LEFT JOIN TB_TRUSTDETAIL td ON tcr.trustClientRef_Id=td.trustClientRef_Id " +
				" LEFT JOIN TB_TRUSTSTATEMENT ts ON td.trustStatement_Id=ts.trustStatement_id " +
				" LEFT JOIN TB_TRUSTACCOUNT ta ON td.trustAccount_Id=ta.trustAccount_Id " +
				" LEFT JOIN TB_MATTER m ON tcr.SSRNumber=m.MatterSSRNumber " +
				" LEFT JOIN TB_MATTERSTATUS ms ON m.MatterStatus_Id=ms.MatterStatus_Id " +
				" LEFT JOIN TB_AUSTSTATE aus ON m.TransactionState_Id=aus.AustState_Id " +
				" WHERE (tcr.Updated_datetime between '05/09/2014 00:00:00' and '" + dateFormat.format(today.getTime()) + "')  " +
				" GROUP BY " +
				" tcr.SSRNumber, " +
				" tcr.LoanNumber, " +
				" tcr.Updated_datetime, " +
				" tcr.MatterName, " +
				" ms.MatterStatus_desc, " +
				" tcr.trustClientRef_Id, " +
				" tcr.trustClient_Id, " +
				" m.Matter_Id, " +
				" aus.StateShort_desc " +
				" ) tm ON tcr.SSRNumber=tm.SSR AND tm.Balance <> 0 AND tm.Balance > 0 " +
				" UNION " +
				" SELECT  " +
				" DISTINCT " +
				" tm.SSR AS 'SSR', " +
				" tm.[Initial Deposit Date] AS 'Initial Deposit Date', " +
				" tm.[Stmt Date] AS 'Stmt Date', " +
				" tm.Created AS 'Created', " +
				" tm.Loan AS 'Loan', " +
				" tm.Matter AS 'Matter', " +
				" tm.Balance AS 'Balance', " +
				" tm.Reconciled AS 'Reconciled', " +
				" tm.[Unreconciled (Depricated)] AS 'Unreconciled (Depricated)', " +
				" tm.MatterStatus 'Status', " +
				" tm.ClientId AS 'ClientId', " +
				" tm.AusState AS 'State' " +
				" FROM TB_TRUSTCLIENTREF tcr " +
				" INNER JOIN( " +
				" SELECT  " +
				" DISTINCT " +
				" tcr.SSRNumber AS 'SSR', " +
				" CONVERT(VARCHAR,Min(td.effective_datetime),103) AS 'Initial Deposit Date', " +
				" CONVERT(VARCHAR,MAX(ts.statement_date),103) AS 'Stmt Date', " +
				" CONVERT(VARCHAR,MIN(td.created_datetime),103) AS 'Created', " +
				" tcr.LoanNumber AS 'Loan', " +
				" tcr.MatterName AS 'Matter', " +
				" SUM(case when ta.accountName = 'ACT' AND (td.trustTranType_Id <> 55 or td.tran_amt < 0) then td.tran_amt else 0 end)  AS 'Balance', " +
				" SUM(case when td.isSuspenseItem='N' AND (td.trustTranType_Id <> 55 or td.tran_amt < 0) then td.tran_amt else 0 end) AS 'Reconciled', " +
				" '' AS 'Unreconciled (Depricated)', " +
				" ms.MatterStatus_desc AS 'MatterStatus', " +
				" tcr.trustClientRef_Id AS 'refId', " +
				" tcr.trustClient_Id AS 'ClientId', " +
				" m.Matter_Id AS 'MatterID', " +
				" aus.StateShort_desc AS 'AusState' " +
				" FROM TB_TRUSTCLIENTREF tcr " +
				" LEFT JOIN TB_TRUSTDETAIL td ON tcr.trustClientRef_Id=td.trustClientRef_Id " +
				" LEFT JOIN TB_TRUSTSTATEMENT ts ON td.trustStatement_Id=ts.trustStatement_id " +
				" LEFT JOIN TB_TRUSTACCOUNT ta ON td.trustAccount_Id=ta.trustAccount_Id " +
				" LEFT JOIN TB_MATTER m ON tcr.SSRNumber=m.MatterSSRNumber " +
				" LEFT JOIN TB_MATTERSTATUS ms ON m.MatterStatus_Id=ms.MatterStatus_Id " +
				" LEFT JOIN TB_AUSTSTATE aus ON m.TransactionState_Id=aus.AustState_Id " +
				" WHERE (td.created_datetime between '05/09/2014 00:00:00' and '" + dateFormat.format(today.getTime()) + "')  " +
				" GROUP BY " +
				" tcr.SSRNumber, " +
				" tcr.LoanNumber, " +
				" tcr.Updated_datetime, " +
				" tcr.MatterName, " +
				" ms.MatterStatus_desc, " +
				" tcr.trustClientRef_Id, " +
				" tcr.trustClient_Id, " +
				" m.Matter_Id, " +
				" aus.StateShort_desc " +
				" ) tm ON tcr.SSRNumber=tm.SSR AND tm.Balance <> 0 AND tm.Balance > 0 " +
				" UNION " +
				" SELECT  " +
				" DISTINCT " +
				" tm.SSR AS 'SSR', " +
				" tm.[Initial Deposit Date] AS 'Initial Deposit Date', " +
				" tm.[Stmt Date] AS 'Stmt Date', " +
				" tm.Created AS 'Created', " +
				" tm.Loan AS 'Loan', " +
				" tm.Matter AS 'Matter', " +
				" tm.Balance AS 'Balance', " +
				" tm.Reconciled AS 'Reconciled', " +
				" tm.[Unreconciled (Depricated)] AS 'Unreconciled (Depricated)', " +
				" tm.MatterStatus 'Status', " +
				" tm.ClientId AS 'ClientId', " +
				" tm.AusState AS 'State' " +
				" FROM TB_TRUSTCLIENTREF tcr " +
				" INNER JOIN( " +
				" SELECT  " +
				" DISTINCT " +
				" tcr.SSRNumber AS 'SSR', " +
				" CONVERT(VARCHAR,Min(td.effective_datetime),103) AS 'Initial Deposit Date', " +
				" CONVERT(VARCHAR,MAX(ts.statement_date),103) AS 'Stmt Date', " +
				" CONVERT(VARCHAR,MIN(td.created_datetime),103) AS 'Created', " +
				" tcr.LoanNumber AS 'Loan', " +
				" tcr.MatterName AS 'Matter', " +
				" SUM(case when ta.accountName = 'TAS' AND (td.trustTranType_Id <> 55 or td.tran_amt < 0) then td.tran_amt else 0 end)  AS 'Balance', " +
				" SUM(case when td.isSuspenseItem='N' AND (td.trustTranType_Id <> 55 or td.tran_amt < 0) then td.tran_amt else 0 end) AS 'Reconciled', " +
				" '' AS 'Unreconciled (Depricated)', " +
				" ms.MatterStatus_desc AS 'MatterStatus', " +
				" tcr.trustClientRef_Id AS 'refId', " +
				" tcr.trustClient_Id AS 'ClientId', " +
				" m.Matter_Id AS 'MatterID', " +
				" aus.StateShort_desc AS 'AusState' " +
				" FROM TB_TRUSTCLIENTREF tcr " +
				" LEFT JOIN TB_TRUSTDETAIL td ON tcr.trustClientRef_Id=td.trustClientRef_Id " +
				" LEFT JOIN TB_TRUSTSTATEMENT ts ON td.trustStatement_Id=ts.trustStatement_id " +
				" LEFT JOIN TB_TRUSTACCOUNT ta ON td.trustAccount_Id=ta.trustAccount_Id " +
				" LEFT JOIN TB_MATTER m ON tcr.SSRNumber=m.MatterSSRNumber " +
				" LEFT JOIN TB_MATTERSTATUS ms ON m.MatterStatus_Id=ms.MatterStatus_Id " +
				" LEFT JOIN TB_AUSTSTATE aus ON m.TransactionState_Id=aus.AustState_Id " +
				" WHERE (tcr.Updated_datetime between '05/09/2014 00:00:00' and '" + dateFormat.format(today.getTime()) + "')  " +
				" GROUP BY " +
				" tcr.SSRNumber, " +
				" tcr.LoanNumber, " +
				" tcr.Updated_datetime, " +
				" tcr.MatterName, " +
				" ms.MatterStatus_desc, " +
				" tcr.trustClientRef_Id, " +
				" tcr.trustClient_Id, " +
				" m.Matter_Id, " +
				" aus.StateShort_desc " +
				" ) tm ON tcr.SSRNumber=tm.SSR AND tm.Balance <> 0 AND tm.Balance > 0 " +
				" UNION  " +
				" SELECT  " +
				" DISTINCT " +
				" tm.SSR AS 'SSR', " +
				" tm.[Initial Deposit Date] AS 'Initial Deposit Date', " +
				" tm.[Stmt Date] AS 'Stmt Date', " +
				" tm.Created AS 'Created', " +
				" tm.Loan AS 'Loan', " +
				" tm.Matter AS 'Matter', " +
				" tm.Balance AS 'Balance', " +
				" tm.Reconciled AS 'Reconciled', " +
				" tm.[Unreconciled (Depricated)] AS 'Unreconciled (Depricated)', " +
				" tm.MatterStatus 'Status', " +
				" tm.ClientId AS 'ClientId', " +
				" tm.AusState AS 'State' " +
				" FROM TB_TRUSTCLIENTREF tcr " +
				" INNER JOIN( " +
				" SELECT  " +
				" DISTINCT " +
				" tcr.SSRNumber AS 'SSR', " +
				" CONVERT(VARCHAR,Min(td.effective_datetime),103) AS 'Initial Deposit Date', " +
				" CONVERT(VARCHAR,MAX(ts.statement_date),103) AS 'Stmt Date', " +
				" CONVERT(VARCHAR,MIN(td.created_datetime),103) AS 'Created', " +
				" tcr.LoanNumber AS 'Loan', " +
				" tcr.MatterName AS 'Matter', " +
				" SUM(case when ta.accountName = 'SUNCORPT-QLD' AND (td.trustTranType_Id <> 55 or td.tran_amt < 0) then td.tran_amt else 0 end)  AS 'Balance', " +
				" SUM(case when td.isSuspenseItem='N' AND (td.trustTranType_Id <> 55 or td.tran_amt < 0) then td.tran_amt else 0 end) AS 'Reconciled', " +
				" '' AS 'Unreconciled (Depricated)', " +
				" ms.MatterStatus_desc AS 'MatterStatus', " +
				" tcr.trustClientRef_Id AS 'refId', " +
				" tcr.trustClient_Id AS 'ClientId', " +
				" m.Matter_Id AS 'MatterID', " +
				" aus.StateShort_desc AS 'AusState' " +
				" FROM TB_TRUSTCLIENTREF tcr " +
				" LEFT JOIN TB_TRUSTDETAIL td ON tcr.trustClientRef_Id=td.trustClientRef_Id " +
				" LEFT JOIN TB_TRUSTSTATEMENT ts ON td.trustStatement_Id=ts.trustStatement_id " +
				" LEFT JOIN TB_TRUSTACCOUNT ta ON td.trustAccount_Id=ta.trustAccount_Id " +
				" LEFT JOIN TB_MATTER m ON tcr.SSRNumber=m.MatterSSRNumber " +
				" LEFT JOIN TB_MATTERSTATUS ms ON m.MatterStatus_Id=ms.MatterStatus_Id " +
				" LEFT JOIN TB_AUSTSTATE aus ON m.TransactionState_Id=aus.AustState_Id " +
				" WHERE (tcr.Updated_datetime between '05/09/2014 00:00:00' and '" + dateFormat.format(today.getTime()) + "')  " +
				" GROUP BY " +
				" tcr.SSRNumber, " +
				" tcr.LoanNumber, " +
				" tcr.Updated_datetime, " +
				" tcr.MatterName, " +
				" ms.MatterStatus_desc, " +
				" tcr.trustClientRef_Id, " +
				" tcr.trustClient_Id, " +
				" m.Matter_Id, " +
				" aus.StateShort_desc " +
				" ) tm ON tcr.SSRNumber=tm.SSR AND tm.Balance <> 0 AND tm.Balance > 0 " +
				" UNION " +
				" SELECT  " +
				" DISTINCT " +
				" tm.SSR AS 'SSR', " +
				" tm.[Initial Deposit Date] AS 'Initial Deposit Date', " +
				" tm.[Stmt Date] AS 'Stmt Date', " +
				" tm.Created AS 'Created', " +
				" tm.Loan AS 'Loan', " +
				" tm.Matter AS 'Matter', " +
				" tm.Balance AS 'Balance', " +
				" tm.Reconciled AS 'Reconciled', " +
				" tm.[Unreconciled (Depricated)] AS 'Unreconciled (Depricated)', " +
				" tm.MatterStatus 'Status', " +
				" tm.ClientId AS 'ClientId', " +
				" tm.AusState AS 'State' " +
				" FROM TB_TRUSTCLIENTREF tcr " +
				" INNER JOIN( " +
				" SELECT  " +
				" DISTINCT " +
				" tcr.SSRNumber AS 'SSR', " +
				" CONVERT(VARCHAR,Min(td.effective_datetime),103) AS 'Initial Deposit Date', " +
				" CONVERT(VARCHAR,MAX(ts.statement_date),103) AS 'Stmt Date', " +
				" CONVERT(VARCHAR,MIN(td.created_datetime),103) AS 'Created', " +
				" tcr.LoanNumber AS 'Loan', " +
				" tcr.MatterName AS 'Matter', " +
				" SUM(case when ta.accountName = 'BANKWEST-WA' AND (td.trustTranType_Id <> 55 or td.tran_amt < 0) then td.tran_amt else 0 end)  AS 'Balance', " +
				" SUM(case when td.isSuspenseItem='N' AND (td.trustTranType_Id <> 55 or td.tran_amt < 0) then td.tran_amt else 0 end) AS 'Reconciled', " +
				" '' AS 'Unreconciled (Depricated)', " +
				" ms.MatterStatus_desc AS 'MatterStatus', " +
				" tcr.trustClientRef_Id AS 'refId', " +
				" tcr.trustClient_Id AS 'ClientId', " +
				" m.Matter_Id AS 'MatterID', " +
				" aus.StateShort_desc AS 'AusState' " +
				" FROM TB_TRUSTCLIENTREF tcr " +
				" LEFT JOIN TB_TRUSTDETAIL td ON tcr.trustClientRef_Id=td.trustClientRef_Id " +
				" LEFT JOIN TB_TRUSTSTATEMENT ts ON td.trustStatement_Id=ts.trustStatement_id " +
				" LEFT JOIN TB_TRUSTACCOUNT ta ON td.trustAccount_Id=ta.trustAccount_Id " +
				" LEFT JOIN TB_MATTER m ON tcr.SSRNumber=m.MatterSSRNumber " +
				" LEFT JOIN TB_MATTERSTATUS ms ON m.MatterStatus_Id=ms.MatterStatus_Id " +
				" LEFT JOIN TB_AUSTSTATE aus ON m.TransactionState_Id=aus.AustState_Id " +
				" WHERE (tcr.Updated_datetime between '05/09/2014 00:00:00' and '" + dateFormat.format(today.getTime()) + "')  " +
				" GROUP BY " +
				" tcr.SSRNumber, " +
				" tcr.LoanNumber, " +
				" tcr.Updated_datetime, " +
				" tcr.MatterName, " +
				" ms.MatterStatus_desc, " +
				" tcr.trustClientRef_Id, " +
				" tcr.trustClient_Id, " +
				" m.Matter_Id, " +
				" aus.StateShort_desc " +
				" ) tm ON tcr.SSRNumber=tm.SSR AND tm.Balance <> 0 AND tm.Balance > 0 " +
				" ORDER BY tm.AusState";
		
		return select;
	}

	@Override
	protected void finaliseQuery() throws Exception {
	}
	
	@Override
	protected String getReportName() {
		return "TAMS Balances";
	}
	
}
