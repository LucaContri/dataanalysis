package com.saiglobal.scrapers.processors;

import java.util.Calendar;

public class ProcessorDetails {
	private String id, source, page, processorClass;
	private long totalRecords, recordsToFetch, recordsFetched;
	private Calendar start, end;
	private boolean completed = false;
	private String exception = null;
	
	public String getId() {
		return id;
	}
	public void setId(String id) {
		this.id = id;
	}
	public String getSource() {
		return source;
	}
	public void setSource(String source) {
		this.source = source;
	}
	public String getPage() {
		return page;
	}
	public void setPage(String page) {
		this.page = page;
	}
	public long getTotalRecords() {
		return totalRecords;
	}
	public void setTotalRecords(long totalRecords) {
		this.totalRecords = totalRecords;
	}
	public Calendar getStart() {
		return start;
	}
	public void setStart(Calendar start) {
		this.start = start;
	}
	public Calendar getEnd() {
		return end;
	}
	public void setEnd(Calendar end) {
		this.end = end;
	}
	public boolean isCompleted() {
		return completed;
	}
	public void setCompleted(boolean completed) {
		this.completed = completed;
	}
	public String getProcessorClass() {
		return processorClass;
	}
	public void setProcessorClass(String processorClass) {
		this.processorClass = processorClass;
	}
	public long getRecordsFetched() {
		return recordsFetched;
	}
	public void setRecordsFetched(long recordsFetched) {
		this.recordsFetched = recordsFetched;
	}
	public String getException() {
		return exception;
	}
	public void setException(String exception) {
		this.exception = exception;
	}
	public long getRecordsToFetch() {
		return recordsToFetch;
	}
	public void setRecordsToFetch(long recordsToFetch) {
		this.recordsToFetch = recordsToFetch;
	}
}
