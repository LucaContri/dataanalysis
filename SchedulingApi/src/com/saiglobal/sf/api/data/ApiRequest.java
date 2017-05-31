package com.saiglobal.sf.api.data;

import java.util.Date;

public class ApiRequest {
	private String request;
	private String client;
	private String Outcome;
	private Date lastUpdate;
	private long timeMs;
	public String getRequest() {
		return request;
	}
	public void setRequest(String request) {
		this.request = request;
	}
	public String getClient() {
		return client;
	}
	public void setClient(String client) {
		this.client = client;
	}
	public String getOutcome() {
		return Outcome;
	}
	public void setOutcome(String outcome) {
		Outcome = outcome;
	}
	public long getTimeMs() {
		return timeMs;
	}
	public void setTimeMs(long timeMs) {
		this.timeMs = timeMs;
	}
	public Date getLastUpdate() {
		return lastUpdate;
	}
	public void setLastUpdate(Date lastUpdate) {
		this.lastUpdate = lastUpdate;
	}
}
