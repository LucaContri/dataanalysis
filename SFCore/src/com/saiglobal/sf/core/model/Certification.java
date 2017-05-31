package com.saiglobal.sf.core.model;

import java.util.List;

import javax.xml.bind.annotation.XmlElement;

public class Certification extends GenericSfObject {
	@XmlElement(name = "WorkItem")
	public List<WorkItem> workItems;
}
