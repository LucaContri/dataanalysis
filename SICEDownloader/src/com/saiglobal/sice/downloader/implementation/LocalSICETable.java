package com.saiglobal.sice.downloader.implementation;

import java.util.Calendar;

public class LocalSICETable {
	private int id;
	private String name;
	private Calendar lastSyncd;
	private boolean sync;
	private boolean syncDue;
	
	public LocalSICETable(int id, String name, Calendar lastSyncd, boolean sync, boolean syncDue) {
		super();
		this .id = id;
		this.name = name;
		this.lastSyncd = lastSyncd;
		this.sync = sync;
		this.syncDue = syncDue;
	}
	
	public String getName() {
		return name;
	}
	
	public Calendar getLastSyncd() {
		return lastSyncd;
	}
	
	public void setLastSyncd(Calendar lastSyncd) {
		this.lastSyncd = lastSyncd;
	}
	public boolean isSync() {
		return sync;
	}
	
	public int getId() {
		return id;
	}

	public boolean isSyncDue() {
		return syncDue;
	}
}
