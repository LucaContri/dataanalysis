package com.saiglobal.scrapers.model;

import java.io.UnsupportedEncodingException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Calendar;

public class CertifiedOrganisation {
	private String Id, Name, Address, Status, TypeOfCertification, City, State, Country, Scope, AuditScope, CertificationStandards, Accredited, CertificationCodes, CertificationBody, CertificationStatus;
	private Calendar DateCertified, DateExpiry;
	private boolean isDeleted = false;
	
	public Object getField(String fieldName) throws UnsupportedOperationException {
		if(fieldName.equalsIgnoreCase("CertificationBody"))
			return getCertificationBody();
		throw new UnsupportedOperationException("Cannot return field " + fieldName + " yet.  I need to be updated");
	}
	
	public boolean isDeleted() {
		return isDeleted;
	}
	public void setDeleted(boolean isDeleted) {
		this.isDeleted = isDeleted;
	}
	public String getScope() {
		return Scope;
	}
	public void setScope(String scope) {
		Scope = scope.replace("\\","").replace("'", "\\'");
	}
	public String getId() {
		return Id;
	}
	public void setId(String id) {
		Id = id;
	}
	public String getName() {
		return Name;
	}
	public void setName(String name) {
		Name = name.replace("\\","").replace("'", "\\'");
	}
	
	public String getStatus() {
		return Status;
	}
	public void setStatus(String status) {
		Status = status.replace("\\","").replace("'", "\\'");
	}
	public String getTypeOfCertification() {
		return TypeOfCertification;
	}
	public void setTypeOfCertification(String typeOfCertification) {
		TypeOfCertification = typeOfCertification.replace("\\","").replace("'", "\\'");
	}
	public String getCity() {
		return City;
	}
	public void setCity(String city) {
		City = city.replace("\\","").replace("'", "\\'");
	}
	public String getCountry() {
		return Country;
	}
	public void setCountry(String country) {
		Country = country.replace("\\","").replace("'", "\\'");
	}
	public String getCertificationStandards() {
		return CertificationStandards;
	}
	public void setCertificationStandards(String certificationStandards) {
		CertificationStandards = certificationStandards.replace("\\","").replace("'", "\\'");
	}
	public String getCertificationCodes() {
		return CertificationCodes;
	}
	public void setCertificationCodes(String certificationCodes) {
		CertificationCodes = certificationCodes.replace("\\","").replace("'", "\\'");
	}
	public String getCertificationBody() {
		return CertificationBody;
	}
	public void setCertificationBody(String certificationBody) {
		CertificationBody = certificationBody.replace("\\","").replace("'", "\\'");
	}
	public Calendar getDateCertified() {
		return DateCertified;
	}
	public void setDateCertified(Calendar dateCertified) {
		DateCertified = dateCertified;
	}

	public String getAddress() {
		return Address;
	}

	public void setAddress(String address) {
		Address = address;
	}

	public String getState() {
		return State;
	}

	public void setState(String state) {
		State = state;
	}

	public String getAuditScope() {
		return AuditScope;
	}

	public void setAuditScope(String auditScope) {
		AuditScope = auditScope;
	}

	public String getAccredited() {
		return Accredited;
	}

	public void setAccredited(String accredited) {
		Accredited = accredited;
	}

	public String getCertificationStatus() {
		return CertificationStatus;
	}

	public void setCertificationStatus(String certificationStatus) {
		CertificationStatus = certificationStatus;
	}

	public Calendar getDateExpiry() {
		return DateExpiry;
	}

	public void setDateExpiry(Calendar dateExpiry) {
		DateExpiry = dateExpiry;
	}
	
	public void setIdFromHash() throws NoSuchAlgorithmException, UnsupportedEncodingException {
		MessageDigest md = MessageDigest.getInstance("SHA-256");
		String tobeHashed = 
				this.getName()==null?"":this.getName()+
				this.getAddress()==null?"":this.getAddress()+
				this.getCity()==null?"":this.getCity()+
				this.getCountry()==null?"":this.getCountry()+
				this.getState()==null?"":this.getState()+
				this.getCertificationStandards()==null?"":this.getCertificationStandards();
		this.setId(new String(md.digest(tobeHashed.getBytes("UTF-8"))));
	}
}
