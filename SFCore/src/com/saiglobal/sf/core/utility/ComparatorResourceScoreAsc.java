package com.saiglobal.sf.core.utility;

import java.util.Comparator;

import com.saiglobal.sf.core.model.Resource;

/* Note: this comparator imposes orderings that are inconsistent with equals. */
public class ComparatorResourceScoreAsc implements Comparator<Resource> {
	
	@Override
	public int compare(Resource resource1, Resource resource2) {
		return resource1.getScore().compareTo(resource2.getScore());
	}

}
