package com.saiglobal.reporting.model;

public enum CustomFilters {
	WOW("All Woolworths Standards", "a36d0000001AuHlAAK,a36d000000159CZAAY,a36d00000004ZXrAAM,a36d0000000CrA3AAK,a36d0000000Cr9yAAC,a36900000004FRQAA2,a36900000004FRRAA2,a36900000004FRPAA2,a36d00000004ZXwAAM,a36d0000000CtD2AAK,a36d0000000Ci6VAAS,a36d0000000Ci6QAAS,a36900000004F2EAAU,a360W000001YamyQAC"),
	MCD("All McDonalds Standards", "a36900000004F28AAE,a36900000004F2BAAU,a36900000004FREAA2,a36900000004FRHAA2,a36900000004FRMAA2,a36d0000000CoKeAAK,a36d0000000CoKjAAK,a36d0000000CoKKAA0,a36d0000000CoKoAAK,a36d0000000CoKPAA0,a36d0000000CoKtAAK,a36d0000000CoKUAA0,a36d0000000CoKyAAK,a36d0000000CoKZAA0,a36d0000000CoL3AAK,a36d0000000CoL8AAK,a36d0000000CoLcAAK,a36d0000000CoLDAA0,a36d0000000CoLhAAK,a36d0000000CoLIAA0,a36d0000000CoLmAAK,a36d0000000CoLNAA0,a36d0000000CoLrAAK,a36d0000000CoLSAA0,a36d0000000CoLXAA0,a36d0000000Con7AAC,a36d0000000CrA8AAK,a36d0000000CrAcAAK,a36d0000000CrAhAAK,a36d0000000CrAmAAK,a36d0000000CrANAA0,a36d0000000CrArAAK,a36d0000000CrASAA0,a36d0000000CrAwAAK,a36d0000000CrAXAA0,a36d0000000CrB1AAK,a36d0000000CrB6AAK,a36d0000000CrBaAAK,a36d0000000CrBBAA0,a36d0000000CrBfAAK,a36d0000000CrBGAA0,a36d0000000CrBkAAK,a36d0000000CrBLAA0,a36d0000000CrBpAAK,a36d0000000CrBQAA0,a36d0000000CrBuAAK,a36d0000000CrBVAA0,a36d0000000CrBzAAK,a36d0000000CrC4AAK,a36d0000000CrC9AAK,a36d0000000CrCEAA0,a36d0000000CrCJAA0,a36d0000000CrCOAA0,a36d0000000CuaAAAS,a36d0000000CuaFAAS,a36d0000000CubNAAS,a36d0000000CubSAAS,a36d0000000CumaAAC,a36d0000000CumfAAC,a36d0000000CumkAAC,a36d0000000CumLAAS,a36d0000000CumQAAS,a36d0000000CumVAAS,a36d0000000CvPdAAK,a36d0000000D286AAC,a36d0000000D28BAAS,a36d0000000g1QhAAI,a36d0000000g1QXAAY,a36d0000000g1RnAAI,a36d0000000g2m6AAA,a36d0000000g2mBAAQ,a36d0000000g2mGAAQ,a36d0000000g2mLAAQ,a36d0000000g2mQAAQ,a36d0000000g2mVAAQ,a36d0000001590sAAA,a36d0000001590xAAA,a36d00000015912AAA,a36d00000015917AAA,a36d0000001591lAAA,a36d0000001591qAAA,a36d0000001591RAAQ,a36d0000001591vAAA,a36d0000001596MAAQ"),
	BRC("All BRC Standards", "a36900000004Ex0AAE,a36900000004Ex1AAE,a36900000004Ex2AAE,a36900000004FR0AAM,a36900000004FRSAA2,a36900000004FRTAA2,a36d00000004KeMAAU,a36d0000000Co9HAAS,a36d0000000Co9RAAS,a36d0000000Cua5AAC,a36d0000000fxweAAA"),
	MANDS("All M&S Standards", "a36d0000000CodbAAC,a36d0000000CodCAAS,a36d0000000CodHAAS,a36d0000000CodMAAS,a36d0000000CodRAAS,a36d0000000CodWAAS,a36d0000000Cx1sAAC,a36d0000000g28PAAQ,a36d0000000g28QAAQ,a36d0000000g28RAAQ,a36d0000000g28SAAQ,a36d0000001591WAAQ"),
	TESCO("All Tesco Standards", "a36d0000000Chj8AAC,a36d0000000ChjSAAS,a36d0000000ChjXAAS,a36d0000000Chl9AAC,a36d0000000ChxPAAS,a36d0000000Ci1bAAC,a36d0000000CvZTAA0,a36d0000000CvZYAA0,a36d0000000Cz0QAAS,a36d0000000Cz0VAAS,a36d0000000g27vAAA,a36d0000000g27wAAA,a36d0000000g27xAAA,a36d0000000g27yAAA,a36d0000000g27zAAA,a36d0000000g280AAA,a36d0000000g281AAA,a36d0000000g282AAA,a36d0000000g283AAA,a36d0000000g284AAA,a36d0000000g285AAA,a36d0000000g286AAA,a36d0000000g287AAA,a36d0000000g288AAA,a36d0000000g289AAA,a36d0000000g28AAAQ,a36d0000000g28BAAQ"),
	TGI("All TGI Standards", "a36d0000000g28JAAQ,a36d0000000Nvy5AAC,a36d0000000NvyAAAS"),
	CDG("All CDG Standards", "a36d0000000g28aAAA,a36d0000000g28bAAA,a36d0000000g28cAAA,a36d0000000g28dAAA,a36d0000000g28YAAQ,a36d0000000g28ZAAQ,a36d0000000g2A6AAI,a36d0000000g2ABAAY");
	
	public String name;
	public String ids;
	CustomFilters(String name, String ids) {
		this.name = name;
		this.ids = ids;
	}
}
