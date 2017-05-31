package com.saiglobal.sf.core.schedule;


import com.saiglobal.sf.core.data.DbHelper;

public abstract class AbstractBusinessRule extends Object implements ProcessorRule {

	protected DbHelper db;
	public AbstractBusinessRule(DbHelper db) {
		this.db = db;
	}
}
