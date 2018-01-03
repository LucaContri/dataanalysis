package com.saiglobal.scrapers.model;

import java.io.UnsupportedEncodingException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;

public class CertifiedOrganisation {
	private static final SimpleDateFormat dateFormat = new SimpleDateFormat("dd/MM/yyyy");
	private String source, id, status, businessLine, companyName, contact, contactEMail, contactPhone, contactFax, address, city, postCode, regionState, country, phone, fax, email, website, standard, grade, scope, exclusion, certificationBody, auditCategory, commercialContact, commercialContactEmail, commercialContactPhone, codes, detailsLink;
	private Double latitude, longitude;
	private Calendar issueDate, expiryDate;
	private boolean deleted = false;
	
	
	public Object getField(String fieldName) throws UnsupportedOperationException {
		if(fieldName.equalsIgnoreCase("certificationBody"))
			return getCertificationBody();
		throw new UnsupportedOperationException("Cannot return field " + fieldName + " yet.  I need to be updated");
	}
	
	public boolean isDeleted() {
		return deleted;
	}
	public void setDeleted(boolean deleted) {
		this.deleted = deleted;
	}
	public String getCodes() {
		return codes;
	}
	public void setCodes(String codes) {
		this.codes = codes;
	}
	public String getCommercialContact() {
		return commercialContact;
	}
	public void setCommercialContact(String commercialContact) {
		this.commercialContact = commercialContact;
	}
	public String getCommercialContactEmail() {
		return commercialContactEmail;
	}
	public void setCommercialContactEmail(String commercialContactEmail) {
		this.commercialContactEmail = commercialContactEmail;
	}
	public String getCommercialContactPhone() {
		return commercialContactPhone;
	}
	public void setCommercialContactPhone(String commercialContactPhone) {
		this.commercialContactPhone = commercialContactPhone;
	}
	public String getAuditCategory() {
		return auditCategory;
	}
	public void setAuditCategory(String auditCategory) {
		this.auditCategory = auditCategory;
	}
	public String getId() {
		return this.id;
	}
	public void setId(String id) {
		this.id = id;
	}
	public String getCompanyName() {
		return companyName;
	}
	public void setCompanyName(String companyName) {
		this.companyName = companyName;
	}
	public String getContact() {
		return contact;
	}
	public void setContact(String contact) {
		this.contact = contact;
	}
	public String getContactEMail() {
		return contactEMail;
	}
	public void setContactEMail(String contactEMail) {
		this.contactEMail = contactEMail;
	}
	public String getContactPhone() {
		return contactPhone;
	}
	public void setContactPhone(String contactPhone) {
		this.contactPhone = contactPhone;
	}
	public String getContactFax() {
		return contactFax;
	}
	public void setContactFax(String contactFax) {
		this.contactFax = contactFax;
	}
	public String getAddress() {
		return address;
	}
	public void setAddress(String address) {
		this.address = address;
	}
	public String getCity() {
		return city;
	}
	public void setCity(String city) {
		this.city = city;
	}
	public String getPostCode() {
		return postCode;
	}
	public void setPostCode(String postCode) {
		this.postCode = postCode;
	}
	public String getRegionState() {
		return regionState;
	}
	public void setRegionState(String regionState) {
		this.regionState = regionState;
	}
	public Double getLatitude() {
		return latitude;
	}
	public void setLatitude(Double latitude) {
		this.latitude = latitude;
	}
	public void setLatitude(String c) {
		if (c!=null) {
			String[] coord = c.split(";");
			if (coord.length==2) {
				try {
					this.latitude = Double.parseDouble(coord[0]);
				} catch (Exception e) {
					// Ignore
				}
			}
		}
	}
	public Double getLongitude() {
		return longitude;
	}
	public void setLongitude(Double longitude) {
		this.longitude = longitude;
	}
	public void setLongitude(String c) {
		if (c!=null) {
			String[] coord = c.split(";");
			if (coord.length==2) {
				try {
					this.longitude = Double.parseDouble(coord[1]);
				} catch (Exception e) {
					// Ignore
				}
			}
		}
	}
	public String getCountry() {
		return country;
	}
	public void setCountry(String country) {
		this.country = country;
	}
	public String getPhone() {
		return phone;
	}
	public void setPhone(String phone) {
		this.phone = phone;
	}
	public String getFax() {
		return fax;
	}
	public void setFax(String fax) {
		this.fax = fax;
	}
	public String getEmail() {
		return email;
	}
	public void setEmail(String email) {
		this.email = email;
	}
	public String getWebsite() {
		return website;
	}
	public void setWebsite(String website) {
		this.website = website;
	}
	public String getStandard() {
		return standard;
	}
	public void setStandard(String standard) {
		this.standard = standard;
	}
	public String getGrade() {
		return grade;
	}
	public void setGrade(String grade) {
		this.grade = grade==null?null:grade.replace("Grade :", "").trim();
	}
	public String getScope() {
		return scope;
	}
	public void setScope(String scope) {
		this.scope = scope==null?null:scope.replace("Scope : ", "").trim();
	}
	public String getExclusion() {
		return exclusion;
	}
	public void setExclusion(String exclusion) {
		this.exclusion = exclusion==null?null:exclusion.replace("Exclusion : ", "").trim();
	}
	public String getCertificationBody() {
		return certificationBody;
	}
	public void setCertificationBody(String certificationBody) {
		this.certificationBody = certificationBody;
	}
	public Calendar getIssueDate() {
		return issueDate;
	}
	public void setIssueDate(Calendar issueDate) {
		this.issueDate = issueDate;
	}
	public void setIssueDate(String issueDate) {
		if (issueDate != null) {
			issueDate = issueDate.replaceAll("Issue Date : ", "").trim();
			try {
				Date id = dateFormat.parse(issueDate);
				this.issueDate = Calendar.getInstance();
				this.issueDate.setTime(id);
			} catch (Exception e) {
				// Ignore
			}
		}
	}
	public Calendar getExpiryDate() {
		return expiryDate;
	}
	public void setExpiryDate(Calendar expiryDate) {
		this.expiryDate = expiryDate;
	}
	public void setExpiryDate(String expiryDate) {
		if (expiryDate != null) {
			expiryDate = expiryDate.replaceAll("Expiry Date : ", "").trim();
			try {
				Date ed = dateFormat.parse(expiryDate);
				this.expiryDate = Calendar.getInstance();
				this.expiryDate.setTime(ed);
			} catch (Exception e) {
				// Ignore
			}
		}
	}
	public void setIdFromHash() throws NoSuchAlgorithmException, UnsupportedEncodingException {
		MessageDigest md = MessageDigest.getInstance("SHA-256");
		String tobeHashed = 
				this.getCompanyName()==null?"":this.getCompanyName()+
				this.getAddress()==null?"":this.getAddress()+
				this.getCity()==null?"":this.getCity()+
				this.getCountry()==null?"":this.getCountry()+
				this.getStandard()==null?"":this.getStandard();
		this.setId(new String(md.digest(tobeHashed.getBytes("UTF-8"))));
	}

	public String getSource() {
		return source;
	}

	public void setSource(String source) {
		this.source = source;
	}

	public String getBusinessLine() {
		return businessLine;
	}

	public void setBusinessLine(String businessLine) {
		this.businessLine = businessLine;
	}

	public String getStatus() {
		return status;
	}

	public void setStatus(String status) {
		this.status = status;
	}

	public String getDetailsLink() {
		return detailsLink;
	}

	public void setDetailsLink(String detailsLink) {
		this.detailsLink = detailsLink;
	}
}