package com.saiglobal.sf.reporting.processor;

import java.io.File;
import java.util.List;

import javax.mail.search.SearchTerm;

import com.saiglobal.sf.core.utility.CustomSearchCondition;
import com.saiglobal.sf.core.utility.Utility;

public class DownloadEmailAttachementAndFtp extends AbstractQueryReport {
	
	public DownloadEmailAttachementAndFtp() {
		super();
		setExecuteStatement(true);
	}
	
	@Override
	protected void initialiseQuery() {
		try {
			String subjectSearch = gp.getCustomParameter("subject");
			String fromSearch = gp.getCustomParameter("from");
			
			SearchTerm searchCondition = new CustomSearchCondition(subjectSearch, fromSearch);
			logger.info("Downloading email attachements from: " + fromSearch + " with subject like: " + subjectSearch);
			List<String> attachments = Utility.downloadAttachmentsFromEmail(gp, new SearchTerm[] {searchCondition}, true, gp.getReportFolder() +"\\Tmp");
			
			if (gp.sftpReports()) {
				for (String attachment : attachments) {
					File reportFileAux = new File(attachment);
					Utility.sftp(gp.getSftpServer(), gp.getSftpPort(), gp.getSftpUser(), gp.getSftpPassword(), attachment, reportFileAux.getName());
					reportFileAux.delete();
					logger.info("Deleting " + reportFileAux.getName() + " from file system");
				}
			}
			
		} catch (Exception e) {
			Utility.handleError(gp, e);
		}
	}
	
	@Override
	protected String getQuery() {
		return "";
	}

	@Override
	protected String getReportName() {
		return null;
	}

}
