package com.saiglobal.sf.core.model;

import java.text.ParseException;
import java.util.Calendar;
import java.util.StringTokenizer;

import com.saiglobal.sf.core.utility.Utility;

public class Competency implements Comparable<Competency> {
	private CompetencyType type;
	private String competencyName;
	private String Id;
	private SfResourceCompetencyRankType[] ranks;
	private String workItemId = null;
	private Calendar competencyExpiry = null;
	
	public Competency(String id, String name, CompetencyType type, String ranksString, String workItemId, String competencyExpiry) {
		this.competencyName = name;
		this.Id = id;
		this.type = type;
		setRanks(ranksString);
		if(workItemId != null && !workItemId.equalsIgnoreCase("") && !workItemId.equalsIgnoreCase("null"))
			this.workItemId = workItemId;
		if(competencyExpiry != null && !competencyExpiry.equalsIgnoreCase("") && !competencyExpiry.equalsIgnoreCase("null"))
			setCompetencyExpiry(competencyExpiry);
	}
	
	public Competency(String id, String name, CompetencyType type, String ranksString) {
		this.competencyName = name;
		this.Id = id;
		this.type = type;
		setRanks(ranksString);
	}
	
	public CompetencyType getType() {
		return type;
	}
	public void setType(CompetencyType type) {
		this.type = type;
	}
	public String getCompetencyName() {
		return competencyName;
	}
	public void setCompetencyName(String competencyName) {
		this.competencyName = competencyName;
	}
	public String getId() {
		return Id;
	}
	public void setId(String id) {
		Id = id;
	}
	
	public boolean equals(Object o) {
		if (o == null)
			return false;
		if (o instanceof Competency) {
			return ((Competency) o).getId().equals(this.getId());
		}
		return super.equals(o);
	}

	@Override
	public int compareTo(Competency o) {
		if (o == null)
			return 1;
		return ((Competency)o).getCompetencyName().compareTo(this.getCompetencyName());
	}

	public SfResourceCompetencyRankType[] getRanks() {
		return ranks;
	}

	public void setRanks(SfResourceCompetencyRankType[] ranks) {
		this.ranks = ranks;
	}
	
	private void setRanks(String ranksString) {
		try {
		if ((ranksString != null) && !ranksString.equals("")) {
			StringTokenizer st = new StringTokenizer(ranksString, ";");
			this.ranks = new SfResourceCompetencyRankType[st.countTokens()];
			int index = 0;
			while (st.hasMoreTokens()) {
				this.ranks[index++] = SfResourceCompetencyRankType.getValueForName(st.nextToken());
			}
		} else {
			this.ranks = new SfResourceCompetencyRankType[0];
		}
		} catch (Exception e) {
			e.printStackTrace();
		}
		
	}
	
	public String getWorkItemId() {
		return workItemId;
	}

	public void setWorkItemId(String workItemId) {
		this.workItemId = workItemId;
	}

	public Calendar getCompetencyExpiry() {
		return competencyExpiry;
	}

	public void setCompetencyExpiry(Calendar competencyExpiry) {
		this.competencyExpiry = competencyExpiry;
	}

	public void setCompetencyExpiry(String competencyExpiry) {
		 try {
			 Calendar aux = Calendar.getInstance();
			aux.setTime(Utility.getActivitydateformatter().parse(competencyExpiry));
			this.competencyExpiry = aux;
		} catch (ParseException e) {}
	}
}

