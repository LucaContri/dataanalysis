package com.saiglobal.sf.downloader.processor;

import com.saiglobal.sf.downloader.data.DbHelper;

public interface PostDownloadDataProcessor {
	public void execute() throws Exception;
	
	public String getName();
	
	public void setDb(DbHelper db);
}
