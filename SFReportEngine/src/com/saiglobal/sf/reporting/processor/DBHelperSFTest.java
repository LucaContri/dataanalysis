package com.saiglobal.sf.reporting.processor;

import java.sql.ResultSet;

import com.saiglobal.sf.core.data.DbHelperDataSource;
import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;

public class DBHelperSFTest {

	public DBHelperSFTest() {
		// TODO Auto-generated constructor stub
	}
	public static void main(String[] args) throws Exception {
		DbHelperDataSource db = new DbHelperDataSource(Utility.getProperties());
		db.use(GlobalProperties.SALESFORCE_DATASOURCE);
		
		ResultSet rs = db.executeSelect("select Id, Name, CreatedDate, Amount from opportunity limit 10", -1);
		while (rs.next()) {
			System.out.println(rs.getString("Id") + ", " + rs.getString("Name"));
		}
	}
}
