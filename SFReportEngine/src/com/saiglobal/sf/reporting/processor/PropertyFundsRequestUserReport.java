package com.saiglobal.sf.reporting.processor;

import java.text.SimpleDateFormat;
import java.util.Calendar;

public class PropertyFundsRequestUserReport extends AbstractQueryReport {
	
	private Calendar today = Calendar.getInstance();
	private Calendar threeMonthsAgo = Calendar.getInstance();
	
	public PropertyFundsRequestUserReport() {
		setExecuteStatement(false);
		setHeader(true);
		dateTimePattern = "d/MM/yyyy";
		//columnWidth = new int[] {200,200,100};
	}
	
	@Override
	protected void setCurrentDataSource() {
		this.gp.setCurrentDataSource("ssr");
	}
	
	@Override
	protected void initialiseQuery() throws Exception {
		threeMonthsAgo.setTime(today.getTime());
		threeMonthsAgo.add(Calendar.MONTH, -3);
	}
	
	@Override
	protected String getQuery() {
		SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-d 00:00:00.000");
		
		String select = 
				"SELECT "
				+ "u.UserName,"
				+ "u.UserLongName,"
				+ "cua.defaultJurisdiction as 'userState',"
				+ "f.FundsRequest_Id,"
				+ "f.LodgeBatch_Id,"
				+ "f.ChequeNumber,"
				+ "f.Created_datetime,"
				+ "cus.userStatusDesc "
				+ "FROM SSR.dbo.TB_FUNDREQUEST f "
				+ "JOIN SSR.dbo.TB_USER u ON f.Created_user_id = u.User_Id "
				+ "JOIN Common.dbo.TB_USERACCOUNT cua ON u.CSMUserAccountID=cua.userAccountID "
				+ "JOIN Common.dbo.TB_USER cu ON cua.userID=cu.userID "
				+ "JOIN Common.dbo.TB_USERSTATUS cus ON cu.userStatusID=cus.userStatusID "
				+ "WHERE f.Created_datetime BETWEEN '" + dateFormat.format(threeMonthsAgo.getTime()) + "' AND '" + dateFormat.format(today.getTime()) + "' "
				+ "ORDER BY UserLongName ASC;";
		
		return select;
	}

	@Override
	protected void finaliseQuery() throws Exception {
	}
	
	@Override
	protected String getReportName() {
		return "Funds Request User Report";
	}
	
}
