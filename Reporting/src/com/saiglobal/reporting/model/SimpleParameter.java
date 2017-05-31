package com.saiglobal.reporting.model;

public class SimpleParameter implements Comparable<Object> {
	String name;
	String id;
	
	public SimpleParameter (String name, String id) {
		this.name = name;
		this.id = id;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public String getId() {
		return id;
	}

	public void setId(String id) {
		this.id = id;
	}

	@Override
	public int compareTo(Object o) {
		if (!(o instanceof SimpleParameter))
			return 0;
		return this.name.compareTo(((SimpleParameter) o).name);
	}
}

