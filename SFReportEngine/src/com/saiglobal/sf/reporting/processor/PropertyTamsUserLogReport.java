package com.saiglobal.sf.reporting.processor;

public class PropertyTamsUserLogReport extends AbstractQueryReport {
	
	public PropertyTamsUserLogReport() {
		setExecuteStatement(false);
		setHeader(true);
		dateTimePattern = "d/MM/yyyy";
		columnWidth = new int[] {100,100,200};
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
		
		String select = 
				"SELECT "
				+ "u.userName,"
				+ "(c.givenNames +' '+ c.surname) as 'Name',"
				+ "r.roleName,"
				+ "aa.accountCode as 'PrimaryAccount',"
				+ "su.userStatusDesc "
				+ "FROM common.dbo.TB_user u "
				+ "INNER JOIN common.dbo.TB_USERACCOUNT ua ON u.userID = ua.userID "
				+ "INNER JOIN common.dbo.TB_USERASSIGN us ON ua.userAccountID = us.userAccountID "
				+ "INNER JOIN common.dbo.tb_role r ON us.roleID = r.roleID "
				+ "INNER JOIN common.dbo.TB_PERMISSIONASSIGN pa ON r.roleID = pa.roleID "
				+ "INNER JOIN common.dbo.TB_PERMISSION p ON pa.permissionID = p.permissionID "
				+ "INNER JOIN common.dbo.TB_OPERATION o ON p.operationID = o.operationID "
				+ "INNER JOIN common.dbo.TB_ACCOUNT a ON a.accountID = ua.accountID "
				+ "join common.dbo.TB_CONTACT c on c.contactID = u.contactID "
				+ "join common.dbo.TB_USERSTATUS su on su.userStatusID = u.userStatusID "
				+ "JOIN common.dbo.TB_ACCOUNT aa ON aa.accountID = u.primaryAccountID "
				+ "WHERE "
				+ "r.rolename like '%TAMS%'";
		
		return select;
	}

	@Override
	protected void finaliseQuery() throws Exception {
	}
	
	@Override
	protected String getReportName() {
		return "Tams User Log";
	}
}
