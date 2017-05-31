package com.saiglobal.sf.core.utility;

import javax.mail.Message;
import javax.mail.MessagingException;
import javax.mail.search.SearchTerm;

public class CustomSearchCondition extends SearchTerm {
	
	private static final long serialVersionUID = 1L;
	private String subjectSearch;
	private String fromSearch;
	private boolean dontSearchFrom;
	private boolean dontSearchSubject;
	
	public CustomSearchCondition(String subjectSearch, String fromSearch) {
		super();
		this.fromSearch = fromSearch;
		this.subjectSearch = subjectSearch;
		this.dontSearchFrom = (fromSearch == null) || (fromSearch == "");
		this.dontSearchSubject = (subjectSearch == null) || (subjectSearch == "");
	}
	@Override
	public boolean match(Message message) {
		try {
            if ((message.getSubject().toLowerCase().contains(subjectSearch.toLowerCase()) || dontSearchSubject) &&
            		(message.getFrom()[0].toString().equalsIgnoreCase(fromSearch) || dontSearchFrom)) {
                return true;
            }
        } catch (MessagingException ex) {
            Utility.getLogger().error(ex);
        }
        return false;
	}
}
