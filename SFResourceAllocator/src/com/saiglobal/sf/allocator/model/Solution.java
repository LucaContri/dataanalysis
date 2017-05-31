package com.saiglobal.sf.allocator.model;

import java.util.HashMap;
import java.util.TreeSet;

import com.saiglobal.sf.core.model.ResourceEvent;

public class Solution {

	private double cost;
	private HashMap<String, TreeSet<ResourceEvent>> solution;
	
	public double getCost() {
		return cost;
	}
	public void setCost(double cost) {
		this.cost = cost;
	}
	public HashMap<String, TreeSet<ResourceEvent>> getSolution() {
		return solution;
	}
	public void setSolution(HashMap<String, TreeSet<ResourceEvent>> solution) {
		this.solution = solution;
	}

}
