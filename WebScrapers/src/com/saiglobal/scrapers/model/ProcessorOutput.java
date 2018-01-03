package com.saiglobal.scrapers.model;

import java.util.List;

public class ProcessorOutput {
	private List<CertifiedOrganisation> list = null;
	private String nextPage = null;
	public List<CertifiedOrganisation> getList() {
		return list;
	}
	public void setList(List<CertifiedOrganisation> list) {
		this.list = list;
	}
	public String getNextPage() {
		return nextPage;
	}
	public void setNextPage(String nextPage) {
		this.nextPage = nextPage;
	}
}
