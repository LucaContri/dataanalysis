package com.saiglobal.sf.reporting.processor;

public class PropertyCBARegistrationsInProgress extends AbstractQueryReport {
	
	public PropertyCBARegistrationsInProgress() {
		dateTimePattern = "d/MM/yyyy";
		columnWidth = new int[] {80,100,250,100,180};
	}
	
	@Override
	protected void initialiseQuery() {
	}
	
	@Override
	protected void setCurrentDataSource() {
		this.gp.setCurrentDataSource("ssr");
	}
	
	@Override
	protected String getQuery() {
		String select = "select " + 
				"T2.Account_code as Account, " + 
				"T2.LoanAccountNumber as Account_Number, " + 
				"T2.MatterName as Matter_Name, " + 
				"CAST(CONVERT(varchar(10),T1.Settlement_Date,101 ) as Date) as Settlement_Date, " + 
				"CAST(CONVERT(varchar(10),T2.Expected_datetime,101 ) as Date) as Expected_Lodgement_Date, " + 
				"CAST(CONVERT(varchar(10),T2.lodged_datetime,101 ) as Date) as Lodgement_Date, " + 
				"CAST(CONVERT(varchar(10),T3.Requisition_Date,101 ) as Date) AS Requisition_Date, " + 
				"NULL as Registration_Date, " + 
				"T2.Authority as Authority, " + 
				"T2.MatterSSRNumber as SSR_Number, " + 
				"T2.IsFileWithClient as With_Client from(select " + 
				"TB_ACCOUNT.Account_code, " + 
				"TB_MATTER.MatterSSRNumber, " + 
				"MAX(TB_SETTLEMENT.Settlement_datetime) as Settlement_Date FROM TB_MATTER INNER JOIN " + 
				"TB_ACCOUNT ON TB_MATTER.Account_Id = TB_ACCOUNT.Account_Id INNER JOIN " + 
				"TB_SERVICE ON TB_MATTER.Matter_Id = TB_SERVICE.Matter_Id INNER JOIN " + 
				"TB_SETTLEMENT ON TB_SERVICE.Service_Id = TB_SETTLEMENT.Service_Id  " + 
				"WHERE  TB_MATTER.MatterStatus_Id = '6'  " + 
				"AND (TB_ACCOUNT.Account_code = '3cbablss'  " + 
				"OR TB_ACCOUNT.Account_code = '3lpcsyd' " + 
				"OR TB_ACCOUNT.Account_code = '4cbaqlpc' " + 
				"OR TB_ACCOUNT.Account_code = '5cbablsm' " + 
				"OR TB_ACCOUNT.Account_code = '5cbavms' " + 
				"OR TB_ACCOUNT.Account_code = '6cbavrel' " + 
				"OR TB_ACCOUNT.Account_code = '7cbablsp' " + 
				"OR TB_ACCOUNT.Account_code = '7lpcper')  " + 
				"AND TB_SERVICE.ServiceStatus_Id <> '6' " + 
				"AND TB_SERVICE.ServiceStatus_Id <> '2' group by TB_MATTER.MatterSSRNumber, " + 
				"TB_ACCOUNT.Account_code) T1 right join (select " + 
				"TB_LOANACCOUNT.LoanAccountNumber, " + 
				"TB_ACCOUNT.Account_code, " + 
				"TB_SERVICE.Expected_datetime, " + 
				"TB_MATTER.MatterSSRNumber, " + 
				"TB_REGISTRATION.Due_datetime, " + 
				"TB_MATTER.MatterName, " + 
				"Convert(nvarchar(50),TB_AUSTSTATE.StateShort_desc)+' - '+Convert(nvarchar(50),TB_AUTHORITY.AuthorityShort_desc) as Authority, " + 
				"TB_DOCUMENT.lodged_datetime, " + 
				"TB_MATTER.IsFileWithClient FROM " + 
				"TB_MATTER INNER JOIN " + 
				"TB_ACCOUNT ON TB_MATTER.Account_Id = TB_ACCOUNT.Account_Id INNER JOIN " + 
				"TB_LOANACCOUNT ON TB_MATTER.Matter_Id = TB_LOANACCOUNT.Matter_Id INNER JOIN " + 
				"TB_SERVICE ON TB_MATTER.Matter_Id = TB_SERVICE.Matter_Id INNER JOIN " + 
				"TB_REGISTRATION ON TB_SERVICE.Service_Id = TB_REGISTRATION.Service_Id INNER JOIN " + 
				"TB_AUTHORITY ON TB_REGISTRATION.Authority_Id = TB_AUTHORITY.Authority_Id INNER JOIN " + 
				"TB_DOCUMENT ON TB_DOCUMENT.Matter_Id = TB_MATTER.Matter_Id INNER JOIN " + 
				"TB_AUSTSTATE ON TB_AUSTSTATE.AustState_Id=TB_MATTER.TransactionState_Id  " + 
				"WHERE  TB_MATTER.MatterStatus_Id = '6'  " + 
				"AND (TB_ACCOUNT.Account_code = '3cbablss'  " + 
				"OR TB_ACCOUNT.Account_code = '3lpcsyd' " + 
				"OR TB_ACCOUNT.Account_code = '4cbaqlpc' " + 
				"OR TB_ACCOUNT.Account_code = '5cbablsm' " + 
				"OR TB_ACCOUNT.Account_code = '5cbavms' " + 
				"OR TB_ACCOUNT.Account_code = '6cbavrel' " + 
				"OR TB_ACCOUNT.Account_code = '7cbablsp' " + 
				"OR TB_ACCOUNT.Account_code = '7lpcper')  " + 
				"AND TB_LOANACCOUNT.IsPrimaryAccount='Y' " + 
				"AND TB_SERVICE.ServiceStatus_Id <> '6'  " + 
				"AND TB_SERVICE.ServiceStatus_Id <> '2'  " + 
				"AND TB_DOCUMENT.isLodgeLocked = 'Y' group by TB_MATTER.MatterSSRNumber, " + 
				"TB_ACCOUNT.Account_code, " + 
				"TB_REGISTRATION.Due_datetime, " + 
				"TB_SERVICE.Expected_datetime, " + 
				"TB_LOANACCOUNT.LoanAccountNumber, " + 
				"TB_MATTER.MatterName, " + 
				"Convert(nvarchar(50),TB_AUSTSTATE.StateShort_desc)+' - '+Convert(nvarchar(50),TB_AUTHORITY.AuthorityShort_desc), " + 
				"TB_DOCUMENT.lodged_datetime, " + 
				"TB_MATTER.IsFileWithClient) T2 on T1.MatterSSRNumber = T2.MatterSSRNumber left join(select " + 
				"TB_MATTER.MatterSSRNumber, " + 
				"MAX(TB_MATTERNOTE.Created_datetime) AS Requisition_Date FROM " + 
				"TB_MATTER INNER JOIN " + 
				"TB_ACCOUNT ON TB_MATTER.Account_Id = TB_ACCOUNT.Account_Id INNER JOIN " + 
				"TB_DOCUMENT ON TB_DOCUMENT.Matter_Id = TB_MATTER.Matter_Id INNER JOIN " + 
				"TB_MATTERNOTE ON TB_MATTER.Matter_Id = TB_MATTERNOTE.Matter_Id                       " + 
				"WHERE  TB_MATTER.MatterStatus_Id = '6'  " + 
				"AND (TB_ACCOUNT.Account_code = '3cbablss'  " + 
				"OR TB_ACCOUNT.Account_code = '3lpcsyd' " + 
				"OR TB_ACCOUNT.Account_code = '4cbaqlpc' " + 
				"OR TB_ACCOUNT.Account_code = '5cbablsm' " + 
				"OR TB_ACCOUNT.Account_code = '5cbavms' " + 
				"OR TB_ACCOUNT.Account_code = '6cbavrel' " + 
				"OR TB_ACCOUNT.Account_code = '7cbablsp' " + 
				"OR TB_ACCOUNT.Account_code = '7lpcper') " + 
				"AND TB_MATTERNOTE.MatterNoteType_Id = '14'group by " + 
				"TB_MATTER.MatterSSRNumber) T3 on T1.MatterSSRNumber = T3.MatterSSRNumber OR T2.MatterSSRNumber = T3.MatterSSRNumber";
		
		return select;
	}

	@Override
	protected String getReportName() {
		return "Registrations In Progress - CBA";
	}
	
}
