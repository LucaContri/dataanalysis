package com.saiglobal.scrapers.model;

import java.io.UnsupportedEncodingException;
import java.math.BigInteger;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Calendar;
import java.util.Date;

public class AccrediaCertifiedOrganisation {
	private String id;
	private String CertificateId, CompanyName, Address, Status, Scope, Standards, Codes, CertificationBody, taxNumber;
	private Calendar DateCertified, lastUpdatedbyCB;
	private String centralOffice, structureType;
	public String getTaxCode() {
		return taxNumber;
	}

	public void setTaxCode(String taxCode) {
		this.taxNumber = taxCode;
	}

	public Calendar getLastUpdatedbyCB() {
		return lastUpdatedbyCB;
	}

	public void setLastUpdatedbyCB(Calendar lastUpdated) {
		this.lastUpdatedbyCB = lastUpdated;
	}

	public void setLastUpdatedbyCB(Date lastUpdated) {
		Calendar cal = Calendar.getInstance();
		cal.setTime(lastUpdated);
		this.lastUpdatedbyCB = cal;
	}
	
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
	
	public String getCompanyName() {
		return CompanyName;
	}
	public void setComapnyName(String name) {
		CompanyName = name.replace("\\","").replace("'", "\\'");
	}
	
	public String getStatus() {
		return Status;
	}
	public void setStatus(String status) {
		Status = status.replace("\\","").replace("'", "\\'");
	}
	
	public String getStandards() {
		return Standards;
	}
	public void setStandards(String certificationStandards) {
		Standards = certificationStandards.replace("\\","").replace("'", "\\'");
	}
	public String getCodes() {
		return Codes;
	}
	public void setCodes(String certificationCodes) {
		Codes = certificationCodes.replace("\\","").replace("'", "\\'");
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
	
	public void setDateCertified(Date dateCertified) {
		Calendar cal = Calendar.getInstance();
		cal.setTime(dateCertified);
		DateCertified = cal;
	}

	public String getAddress() {
		return Address;
	}

	public void setAddress(String address) {
		Address = address;
	}

	public String getCertificateId() {
		return CertificateId;
	}

	public void setCertificateId(String certificateId) {
		CertificateId = certificateId;
	}
	
	public void setId(String id) {
		this.id = id;
	}
	
	public String getId() throws NoSuchAlgorithmException, UnsupportedEncodingException {
		if (id == null) {
			MessageDigest md = MessageDigest.getInstance("MD5");
			String  tobeHashed= 
					(this.getCompanyName()==null?"":this.getCompanyName())+
					(this.getAddress()==null?"":this.getAddress()) +
					(this.getStandards()==null?"":this.getStandards()) + 
					(this.getCertificateId()==null?"":this.getCertificateId()) ;			
			md.update(tobeHashed.getBytes(),0,tobeHashed.length());
			id = new BigInteger(1,md.digest()).toString(16);
		}
		return id;
	}

	public String getCentralOffice() {
		return centralOffice;
	}

	public void setCentralOffice(String centralOffice) {
		this.centralOffice = centralOffice;
	}

	public String getStructureType() {
		return structureType;
	}

	public void setStructureType(String structureType) {
		this.structureType = structureType;
	}
}
