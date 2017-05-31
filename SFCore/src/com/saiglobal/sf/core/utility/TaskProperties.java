package com.saiglobal.sf.core.utility;

import org.apache.log4j.Level;

public class TaskProperties {
	private String name;
	private boolean enabled;
	private boolean disableIfError;
	private boolean emailError;
	private Level logLevel;
	
	public boolean isEnabled() {
		return enabled;
	}
	public void setEnabled(boolean enabled) {
		this.enabled = enabled;
	}
	public boolean disableIfError() {
		return disableIfError;
	}
	public void setDisableIfError(boolean disableIfError) {
		this.disableIfError = disableIfError;
	}
	public boolean emailError() {
		return emailError;
	}
	public void setEmailError(boolean emailError) {
		this.emailError = emailError;
	}
	public String getName() {
		return name;
	}
	public void setName(String name) {
		this.name = name;
	}
	public Level getLogLevel() {
		return logLevel;
	}
	public void setLogLevel(Level logLevel) {
		this.logLevel = logLevel;
	}
}
