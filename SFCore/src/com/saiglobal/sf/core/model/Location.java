package com.saiglobal.sf.core.model;

import java.util.TimeZone;

public class Location extends GenericSfObject {
	private String address_1;
	private String address_2;
	private String address_3;
	private String city;
	private String country;
	private String state;
	private String stateDescription;
	private String postCode;
	private TimeZone timeZone;
	private double latitude;
	private double longitude;
	private double metropolitanRadius; // Used for travelling time calculations only if the Location is a SAIG office
	private String[] contactsText;
	private String contact_name;
	private String contact_title;
	private String contact_email;
	private String contact_phone;

	public Location(String name, String address_1, String address_2, String address_3, String city, String country, String state, String postCode, double latitude, double longitude) {
		
		setName(name);
		this.address_1 = address_1;
		this.address_2 = address_2;
		this.address_3 = address_3;
		this.city = city;
		this.country = country;
		this.state = state;
		this.postCode = postCode;
		this.latitude = latitude;
		this.longitude = longitude;
		this.metropolitanRadius = 0; // default 0
	}
		
	public Location() {
	}
	
	
	public TimeZone getTimeZone() {
		return timeZone;
	}

	public void setTimeZone(TimeZone timeZone) {
		this.timeZone = timeZone;
	}

	public String getStateDescription() {
		return stateDescription;
	}

	public void setStateDescription(String stateDescription) {
		this.stateDescription = stateDescription;
	}

	public String[] getContactsText() {
		return contactsText;
	}

	public void setContactsText(String[] contactsText) {
		this.contactsText = contactsText;
	}

	public String getContact_title() {
		return contact_title;
	}

	public void setContact_title(String contact_title) {
		this.contact_title = contact_title;
	}

	public String getContact_email() {
		return contact_email;
	}

	public void setContact_email(String contact_email) {
		this.contact_email = contact_email;
	}

	public String getContact_name() {
		return contact_name;
	}

	public void setContact_name(String contact_name) {
		this.contact_name = contact_name;
	}
	
	public String getContact_phone() {
		return contact_phone;
	}

	public void setContact_phone(String contact_phone) {
		this.contact_phone = contact_phone;
	}

	public String getCountry() {
		return country;
	}
	public void setCountry(String country) {
		this.country = country;
	}
	public String getState() {
		return state;
	}
	public void setState(String state) {
		this.state = state;
		if (this.stateDescription == null)
			this.stateDescription = state;
	}
	public String getPostCode() {
		return postCode;
	}
	public void setPostCode(String postCode) {
		this.postCode = postCode;
	}
	public double getLatitude() {
		return latitude;
	}
	public void setLatitude(double latitude) {
		this.latitude = latitude;
	}
	public double getLongitude() {
		return longitude;
	}
	public void setLongitude(double longitude) {
		this.longitude = longitude;
	}

	public String getAddress_1() {
		return address_1;
	}

	public void setAddress_1(String address_1) {
		this.address_1 = address_1;
	}

	public String getAddress_2() {
		return address_2;
	}

	public void setAddress_2(String address_2) {
		this.address_2 = address_2;
	}

	public String getAddress_3() {
		return address_3;
	}

	public void setAddress_3(String address_3) {
		this.address_3 = address_3;
	}

	public String getCity() {
		return city;
	}

	public void setCity(String city) {
		this.city = city;
	}

	public double getMetropolitanRadius() {
		return metropolitanRadius;
	}

	public void setMetropolitanRadius(double metropolitanRadius) {
		this.metropolitanRadius = metropolitanRadius;
	}
	
	public String getFullAddress() {
		StringBuilder address = new StringBuilder("");
		if (this.getAddress_1()!=null) address.append(this.getAddress_1()+ " ") ;
		if (this.getAddress_2()!=null) address.append(this.getAddress_2()+ " ");
		if (this.getAddress_3()!=null) address.append(this.getAddress_3()+ " ");
		if (this.getCity()!=null) address.append(this.getCity()+ " ");
		if (this.getState()!=null) address.append(this.getState()+ " ");
		if (this.getCountry()!=null) address.append(this.getCountry()+ " ");
		if (this.getPostCode()!=null) address.append(this.getPostCode()+ " ");
		return address.toString().trim();
	}
}
