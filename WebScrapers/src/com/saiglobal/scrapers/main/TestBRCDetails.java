package com.saiglobal.scrapers.main;

public class TestBRCDetails {

	public static void main(String[] args) {
		try {
			BRCDetailsScraper.updateBRCDetails("1799561");
		} catch (Exception e) {
			
			e.printStackTrace();
		}

	}

}
