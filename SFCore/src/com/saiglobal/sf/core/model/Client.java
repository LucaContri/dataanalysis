package com.saiglobal.sf.core.model;

import java.util.List;

import javax.xml.bind.annotation.XmlElement;
import javax.xml.bind.annotation.XmlTransient;

public class Client extends GenericSfObject {
	@XmlTransient
	private List<ClientSite> clientSites;
	
	@XmlElement(name="ClientSite")
	public List<ClientSite> getClientSites() {
		return clientSites;
	}
	public void setClientSites(List<ClientSite> clientSites) {
		this.clientSites = clientSites;
	}
	

}
