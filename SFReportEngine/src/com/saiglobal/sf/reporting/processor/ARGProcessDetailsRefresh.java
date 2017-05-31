package com.saiglobal.sf.reporting.processor;

import java.util.Calendar;

import com.saiglobal.sf.core.utility.Utility;

public class ARGProcessDetailsRefresh extends AbstractQueryReport {
	
	public ARGProcessDetailsRefresh() {
		setExecuteStatement(true);
	}
	
	@Override
	protected String getQuery() {
		Calendar now = Calendar.getInstance();
		return "LOCK TABLES sf_business_process_details WRITE, "
					+ "wi_finished_not_submitted WRITE, "
					+ "wi_submitted_without_arg WRITE, "
					+ "wi_finished_to_arg_submitted WRITE, "
					+ "arg_submitted_not_taken WRITE, "
					+ "arg_taken_not_reviewed WRITE, "
					+ "arg_submitted_to_arg_approved WRITE, "
					+ "arg_submitted_to_arg_approved_with_rejections WRITE, "
					+ "arg_submitted_to_arg_approved_with_ta WRITE, "
					+ "ARG_APPROVED_NOT_ASSIGNED_ADMIN WRITE, "
					+ "ARG_ASSIGNED_ADMIN_NOT_COMPLETED WRITE, "
					+ "ARG_APPROVED_TO_ARG_COMPLETED_OR_HOLD WRITE, "
					+ "arg_rejected_to_be_resubmitted WRITE, "
					+ "WI_FINISHED_TO_ARG_COMPLETED_OR_HOLD WRITE, "
					+ "wi_submitted_arg_pending WRITE;"
				+ "TRUNCATE sf_business_process_details;"
				+ "INSERT INTO sf_business_process_details "
				+ "select * from wi_finished_not_submitted union "
				+ "select * from wi_submitted_without_arg union "
				+ "select * from wi_finished_to_arg_submitted where `From` is not null and `To` is not null union "
				+ "select * from arg_submitted_not_taken union "
				+ "select * from arg_taken_not_reviewed union " 
				+ "select * from arg_submitted_to_arg_approved where `From` is not null and `To` is not null union "
				+ "select * from arg_submitted_to_arg_approved_with_rejections where `From` is not null and `To` is not null union "
				+ "select * from arg_submitted_to_arg_approved_with_ta where `From` is not null and `To` is not null union "
				+ "select * from ARG_APPROVED_NOT_ASSIGNED_ADMIN union "
				+ "select * from ARG_ASSIGNED_ADMIN_NOT_COMPLETED union "
				+ "select * from ARG_APPROVED_TO_ARG_COMPLETED_OR_HOLD where `From` is not null and `To` is not null union "
				+ "select * from arg_rejected_to_be_resubmitted union "
				+ "select * from WI_FINISHED_TO_ARG_COMPLETED_OR_HOLD where `From` is not null and `To` is not null union "
				+ "select * from wi_submitted_arg_pending;"
				+ "UNLOCK TABLES;"
				+ "UPDATE sf_tables set LastSyncDate='" + Utility.getMysqldateformat().format(now.getTime()) + "' where TableName='sf_business_process_details'";
	}

	@Override
	protected String getReportName() {
		return null;
	}
}
