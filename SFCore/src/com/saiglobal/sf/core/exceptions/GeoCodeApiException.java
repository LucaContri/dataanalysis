package com.saiglobal.sf.core.exceptions;

import com.google.code.geocoder.model.GeocoderStatus;

public class GeoCodeApiException extends Exception {
	private static final long serialVersionUID = 1L;
	private String address;
	private GeocoderStatus responseStatus;
	
	public GeoCodeApiException(String address, GeocoderStatus responseStatus) {
		this.address = address;
		this.responseStatus = responseStatus;
	}
	
	public String getAddress() {
		return address;
	}
	public void setAddress(String address) {
		this.address = address;
	}
	public GeocoderStatus getResponseStatus() {
		return responseStatus;
	}
	public void setResponseStatus(GeocoderStatus responseStatus) {
		this.responseStatus = responseStatus;
	}
}
