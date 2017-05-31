package com.saiglobal.sf.reporting.processor;

import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Calendar;

public class PropertySSRQualityExtract extends AbstractQueryReport {
	private Calendar today = Calendar.getInstance();
	private Calendar yesterday = Calendar.getInstance();
	
	public PropertySSRQualityExtract() {
		setExecuteStatement(false);
		setHeader(false);
		dateTimePattern = "d/MM/yyyy";
	}
	
	@Override
	protected void setCurrentDataSource() {
		this.gp.setCurrentDataSource("ssr");
	}
	
	@Override
	protected void initialiseQuery() {
		//today.set(2015, Calendar.JANUARY, 6);
		yesterday.setTime(today.getTime());
		yesterday.add(Calendar.DAY_OF_MONTH, -1);
	}
	
	@Override
	protected String getQuery() {
		
		
		DateFormat sqlDateFormat = new SimpleDateFormat("dd-MMM-yyyy");
		String select = "SELECT " +
		"'Requisition' AS QualityCategoryRoot,"
		+ "CAST(CONVERT(varchar(10),qi.CreatedDateTime,101 ) as Date) AS CreatedDateTime," +
		//"REPLACE('/'+LEFT(CONVERT(varchar(10),qi.CreatedDateTime,103 ),2),'/0','')+RIGHT(CONVERT(varchar(10),qi.CreatedDateTime,103 ),8) AS CreatedDateTime, " +
		//"qi.CreatedDateTime AS CreatedDateTime, " +
		"s.Site_code As Site," +
		"a.Account_code AS Account," +
		"rtrim(ltrim(cu.UserLongName)) AS CreatedBy," +
		"aus.StateShort_desc AS AustState," +
		"m.MatterSSRNumber AS SSRNumber," +
		"la.LoanAccountNumber AS LoanNumber," +
		"m.MatterName AS MatterName," +
		"m.IsFileWithClient AS IsMatterWithClient," +
		"tr.PartyAtFault As WhosAtFault," +
		"m.IsOutsideSLA AS IsSLAMissed," +
		"CASE tr.IsParked WHEN 1 THEN 'Y' END as IsWorkflowPaused," +
		"CASE tr.IsAvoidableByEspreon WHEN 1 THEN 'Y' ELSE 'N' END as IsAvoidable," +
		"cbu.UserLongName AS CausedBy," +
		"l2.[description] as L2Description," +
		"l3.[description] as L3Description," +
		"l4.[description] as L4Description," +
		"'' AS L5Description," +
		"rs.ShortDescription AS RiskSeverity," +
		"CASE qi.IsActualImpact WHEN 1 THEN 'ACTUAL' ELSE 'Near Miss' END as Impact," +
		"qi.ImpactValue AS ImpactValue," +
		"qi.Comments AS Comments," +
		"tr.QualityItemID AS ID " +
		"FROM " +
		"TB_Requisition tr " +
		"LEFT join tb_qualityItem qi on qi.QualityItemID = tr.QualityItemID " +
		"LEFT join tb_user cu on qi.createdUserID = cu.user_id " +
		"LEFT join tb_user cbu on qi.CausedByUserID = cbu.user_id " +
		"join tb_service ser on tr.service_id = ser.service_id " +
		"join tb_matter m on m.matter_id = ser.matter_id " +
		"join tb_account a on m.account_id = a.account_id " +
		"join tb_site s on s.site_id = a.site_id " +
		"LEFT join tb_austState aus on aus.AustState_id = m.TransactionState_Id " +
		"LEFT join tb_loanAccount la on la.matter_id = m.matter_Id and la.IsPrimaryAccount = 'y' " +
		"left join tb_qualitycategory l2 on qi.level2qualityCategoryID = l2.qualityCategoryID " +
		"left join tb_qualitycategory l3 on qi.level3qualityCategoryID = l3.qualityCategoryID " +
		"left join tb_qualitycategory l4 on qi.level4qualityCategoryID = l4.qualityCategoryID " +
		"left join TB_RISKSEVERITY rs on rs.RiskSeverityID = qi.RiskSeverityID " +
		"where qi.CreatedDateTime > '" + sqlDateFormat.format(yesterday.getTime()) + "' AND qi.CreatedDateTime < '" + sqlDateFormat.format(today.getTime()) + "' " +
		" UNION " +
		"SELECT " +
		"'Rework' AS QualityCategoryRoot, "
		+ "CAST(CONVERT(varchar(10),qi.CreatedDateTime,101 ) as Date) AS CreatedDateTime," +
		//"REPLACE('/'+LEFT(CONVERT(varchar(10),qi.CreatedDateTime,103 ),2),'/0','')+RIGHT(CONVERT(varchar(10),qi.CreatedDateTime,103 ),8) AS CreatedDateTime, " +
		//"qi.CreatedDateTime AS CreatedDateTime, " +
		"s.Site_code As Site," +
		"a.Account_code AS Account," +
		"rtrim(ltrim(cu.UserLongName)) AS CreatedBy," +
		"aus.StateShort_desc AS AustState," +
		"m.MatterSSRNumber AS SSRNumber," +
		"la.LoanAccountNumber AS LoanNumber," +
		"m.MatterName AS MatterName," +
		"m.IsFileWithClient AS IsMatterWithClient," +
		"CASE r.IsClientCausedRework WHEN 1 THEN 'Client' ELSE 'Espreon' END as WhosAtFault," +
		"m.IsOutsideSLA AS IsSLAMissed," +
		"CASE r.IsParked WHEN 1 THEN 'Y' ELSE 'N' END as IsWorkflowPaused," +
		"'' AS IsAvoidable," +
		"cbu.UserLongName AS CausedBy," +
		"l2.[description] as L2Description," +
		"l3.[description] as L3Description," +
		"l4.[description] as L4Description," +
		"'' AS L5Description," +
		"rs.ShortDescription AS RiskSeverity," +
		"CASE qi.IsActualImpact WHEN 1 THEN 'ACTUAL' ELSE 'Near Miss' END as Impact," +
		"qi.ImpactValue AS ImpactValue," +
		"qi.Comments AS Comments," +
		"r.QualityItemID AS ID " +
		"FROM " +
		"TB_MatterRework  r " +
		"LEFT join tb_qualityItem qi on qi.QualityItemID = r.QualityItemID " +
		"LEFT join tb_user cu on qi.createdUserID = cu.user_id " +
		"LEFT join tb_user cbu on qi.CausedByUserID = cbu.user_id " +
		"join tb_matter m on m.matter_id = r.matter_id " +
		"join tb_account a on m.account_id = a.account_id " +
		"join tb_site s on s.site_id = a.site_id " +
		"LEFT join tb_austState aus on aus.AustState_id = m.TransactionState_Id " +
		"LEFT join tb_loanAccount la on la.matter_id = m.matter_Id and la.IsPrimaryAccount = 'y' " +
		"left join tb_qualitycategory l2 on qi.level2qualityCategoryID = l2.qualityCategoryID " +
		"left join tb_qualitycategory l3 on qi.level3qualityCategoryID = l3.qualityCategoryID " +
		"left join tb_qualitycategory l4 on qi.level4qualityCategoryID = l4.qualityCategoryID " +
		"left join TB_RISKSEVERITY rs on rs.RiskSeverityID = qi.RiskSeverityID " +
		"where qi.CreatedDateTime > '" + sqlDateFormat.format(yesterday.getTime()) + "' AND qi.CreatedDateTime < '" + sqlDateFormat.format(today.getTime()) + "'" +
		" UNION " +
		"SELECT " +
		"'NonConformingItem' AS QualityCategoryRoot,"
		+ "CAST(CONVERT(varchar(10),qit.CreatedDateTime,101 ) as Date) AS CreatedDateTime," +
		//"REPLACE('/'+LEFT(CONVERT(varchar(10),qit.CreatedDateTime,103 ),2),'/0','')+RIGHT(CONVERT(varchar(10),qit.CreatedDateTime,103 ),8) AS CreatedDateTime, " +
		//"qit.CreatedDateTime AS CreatedDateTime, " +
		"'' As Site," +
		"'' AS Account," +
		"rtrim(ltrim(cu.UserLongName)) AS CreatedBy," +
		"'' AS AustState," +
		"'' AS SSRNumber," +
		"'' AS LoanNumber," +
		"'' AS MatterName," +
		"'' AS IsMatterWithClient," +
		"'' as WhosAtFault," +
		"'' AS IsSLAMissed," +
		"'' AS IsWorkflowPaused," +
		"'' AS IsAvoidable," +
		"cbu.UserLongName AS CausedBy," +
		"l2.[description] as L2Description," +
		"l3.[description] as L3Description," +
		"l4.[description] as L4Description," +
		"q.Description AS L5Description," +
		"rs.ShortDescription AS RiskSeverity," +
		"CASE qit.IsActualImpact WHEN 1 THEN 'ACTUAL' ELSE 'Near Miss' END as Impact," +
		"qit.ImpactValue AS ImpactValue," +
		"qit.Comments AS Comments," +
		"n.QualityItemID AS ID " +
		"from TB_NonConformingItem n " +
		"LEFT join tb_qualityItem qit on qit.QualityItemID = n.QualityItemID " +
		"join tb_qualityCategory q on q.QualityCategoryID = n.Level5QualityCategoryID " +
		"LEFT join tb_user cu on qit.CreatedUserID = cu.user_id " +
		"LEFT join tb_user cbu on qit.CausedByUserID = cbu.user_id " +
		"LEFT join TB_RISKSEVERITY rs on rs.RiskSeverityID = qit.RiskSeverityID " +
		"left join tb_qualitycategory l2 on qit.level2qualityCategoryID = l2.qualityCategoryID " +
		"left join tb_qualitycategory l3 on qit.level3qualityCategoryID = l3.qualityCategoryID " +
		"left join tb_qualitycategory l4 on qit.level4qualityCategoryID = l4.qualityCategoryID " +
		"where qit.qualityItemID in (select qualityItemID from tb_qualityItem qi where qi.CreatedDateTime > '" + sqlDateFormat.format(yesterday.getTime()) + "' AND qi.CreatedDateTime < '" + sqlDateFormat.format(today.getTime()) + "')";
		
		return select;
	}

	@Override
	protected String getReportName() {
		DateFormat sqlDateFormat = new SimpleDateFormat("yyyyMMdd");
		return "errorupload " + sqlDateFormat.format(yesterday.getTime());
	}
	
}
