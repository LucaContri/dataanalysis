package com.saiglobal.sf.core.model;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Date;

public class GenericSfObject {
	private String Id;
	private String Name;
	private Date LastModified;
	
	public GenericSfObject() {
		
	}
	
	public GenericSfObject(ResultSet rs) throws SQLException {
		this.Id = rs.getString("Id");
		this.Name = rs.getString("Name");
		this.LastModified = new Date(rs.getTimestamp("LastModifiedDate").getTime());
	}
	
	public GenericSfObject(String id, String name, Date lastModified) {
		this.Id = id;
		this.Name = name;
		this.LastModified = lastModified;
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
		Name = name;
	}
	public Date getLastModified() {
		return LastModified;
	}
	public void setLastModified(Date lastModified) {
		LastModified = lastModified;
	}
}
