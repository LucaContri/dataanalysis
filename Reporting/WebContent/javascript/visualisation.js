// Data
var apiResponse;

// Data Formatters
var int_formatter;
var currency_formatter;

// Visualizations Options
var auditdays_chart_options = {
	width: 600,
	height: 300,
	chartArea:{left:0,top:0, bottom:0, right:0, width:"80%",height:"80%"},
	legend: { position: 'right', alignment: 'center'},
	bar: { groupWidth: '75%' },
	colors: ['#FFFF00', '#33FF33', '#33FF99', '#33FFFF', '#000066', '#CC0066'],
	isStacked: true,
	series: {0: {type: "line"},4: {type: "line"}, 5: {type: "line"}}
};


var tis_public_yearly_chart_options = {
	width: 800,
	height: 375,
	chartArea:{top:10, left:90, bottom:0},
	legend: { position: 'right', alignment: 'center'},
	isStacked: true,
	//hAxis: { showTextEvery: 6, slantedText: true, slantedTextAngle: 30},
	series: {3: {type: "line"},4: {type: "line"},5: {type: "line"},6: {type: "line"}}
};
var tis_inhouse_yearly_chart_options = {
	width: 800,
	height: 375,
	chartArea:{top:10, left:90, bottom:0},
	legend: { position: 'right', alignment: 'center'},
	isStacked: true,
	//hAxis: { showTextEvery: 6, slantedText: true, slantedTextAngle: 30},
	vAxis: { minorGridlines: {count:3 }},
	series: {2: {type: "line"}, 3: {type: "line"}}
};
var tis_public_monthly_chart_options = {
	width: 800,
	height: 375,
	chartArea:{top:10, left:90, bottom:0},
	legend: { position: 'right', alignment: 'center'},
	isStacked: true,
	hAxis: { showTextEvery: 2},
	vAxis: { minorGridlines: {count:3 }},
	series: {1: {type: "line"}, 2: {type: "line"}}
};
var tis_public_facetoface_chart_options = {
	width: 800,
	height: 375,
	chartArea:{top:10, left:90, bottom:0},
	legend: { position: 'right', alignment: 'center'},
	isStacked: true,
	hAxis: { showTextEvery: 2},
	vAxis: { minorGridlines: {count:3 }},
	series: {2: {type: "line"}, 3: {type: "line"}}
};
var opportunity_chart_options = {
	width: 500,
	height: 300,
	chartArea:{left:0,top:0, bottom:0, right:0, width:"100%",height:"80%"},
	legend: { position: 'none'},
	bar: { groupWidth: '75%' },
	isStacked: false,
	hAxis: {slantedText: true, slantedTextAngle: 30}
};
var opportunity_delivery_chart_options = {
	width: 500,
	height: 300,
	chartArea:{left:0,top:0, bottom:0, right:0, width:"100%",height:"80%"},
	legend: { position: 'none'},
	bar: { groupWidth: '75%' },
	isStacked: false,
	hAxis: {slantedText: true, slantedTextAngle: 30}
	};
var table_options = {
	showRowNumber: false, 
	sort: 'disable',
	width: 500
};
var tis_small_table_options = {
	showRowNumber: false, 
	sort: 'disable',
	cssClassNames: {tableCell: 'smallText', headerCell: 'smallText'}
};
var tis_super_small_table_options = {
		showRowNumber: false, 
		sort: 'disable',
		cssClassNames: {tableCell: 'smallText', headerCell: 'smallText'}
	};
var tis_table_options = {
	showRowNumber: false, 
	sort: 'disable',
};
var gaugeOptions = {
	min: 0, 
	max: 5, 
	yellowFrom: 2, 
	yellowTo: 4,
	redFrom: 4, 
	redTo: 5, 
	minorTicks: 0.5
};

// Functions
function updateAllVisualisationsForPrinting() {
	$.when( updateAllVisualisations() ).done( function() {
		updateSalesOpportunityDeliveryChartToYesterday("opportunity_delivery_yesterday_chart");
		updateSalesOpportunityDeliveryTableToYesterday("opportunity_delivery_yesterday_table");
		updateOpportunityPipelineChartToYesterday("opportunity_yesterday_chart");
		updateOpportunityPipelineTableToYesterday("opportunity_yesterday_table", "fab_yesterday_ratio_amount", "fab_yesterday_ratio_count");
		
		$('.to_be_expanded').collapsible('expand');
		window.status = "readyForPrinting";
	});
}

function updateAllVisualisations() {
	// Load Data
	if (window.XMLHttpRequest) {
	  	// code for IE7+, Firefox, Chrome, Opera, Safari
	  	xmlhttp=new XMLHttpRequest();
	} else {
	  	// code for IE6, IE5
		xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
	}
	  
	//xmlhttp.open("GET","dailyStats?region="+$("#region-select option:selected").val(),false);
	xmlhttp.open("GET","dailyStats",false);
	xmlhttp.send();
	apiResponse = JSON.parse(xmlhttp.responseText);
	
	
	// Init Formatters
	int_formatter = new google.visualization.NumberFormat({
		fractionDigits: 0,
		negativeColor: "#FF0000"
	});
	currency_formatter = new google.visualization.NumberFormat({
		fractionDigits: 0,
		prefix: '$', 
		negativeColor: "red", 
		negativeParens: true
	});

	// Init Visualizations
	updateAuditDaysToBoth('auditdays_chart_header', 'auditdays_chart', 'auditdays_table_header', 'auditdays_table', 'auditdays_table_changes_daily_header', 'auditdays_table_changes_daily', 'auditdays_table_changes_weekly_header', 'auditdays_table_changes_weekly');
	updateSales(opportunity_chart_options, table_options, currency_formatter);
	updateTIS();
}
  
function updateAuditDaysToMS(auditdays_chart_header, auditdays_chart, auditdays_table_header, auditdays_table, auditdays_table_changes_daily_header, auditdays_table_changes_daily, auditdays_table_changes_weekly_header, auditdays_table_changes_weekly) {
	updateAuditDays(apiResponse.msAuditDaysChartData,apiResponse.msAuditDaysTableData, apiResponse.msAuditDaysChangesDailyTableData, apiResponse.msAuditDaysChangesWeeklyTableData, auditdays_chart_options, table_options, auditdays_chart_header, auditdays_chart, auditdays_table_header, auditdays_table, auditdays_table_changes_daily_header, auditdays_table_changes_daily, auditdays_table_changes_weekly_header, auditdays_table_changes_weekly);
}
	
function updateAuditDaysToFood(auditdays_chart_header, auditdays_chart, auditdays_table_header, auditdays_table, auditdays_table_changes_daily_header, auditdays_table_changes_daily, auditdays_table_changes_weekly_header, auditdays_table_changes_weekly) {
	updateAuditDays(apiResponse.foodAuditDaysChartData,apiResponse.foodAuditDaysTableData, apiResponse.foodAuditDaysChangesDailyTableData, apiResponse.foodAuditDaysChangesWeeklyTableData, auditdays_chart_options, table_options, auditdays_chart_header, auditdays_chart, auditdays_table_header, auditdays_table, auditdays_table_changes_daily_header, auditdays_table_changes_daily, auditdays_table_changes_weekly_header, auditdays_table_changes_weekly);
}

function updateAuditDaysToBoth(auditdays_chart_header, auditdays_chart, auditdays_table_header, auditdays_table, auditdays_table_changes_daily_header, auditdays_table_changes_daily, auditdays_table_changes_weekly_header, auditdays_table_changes_weekly) {
	updateAuditDays(apiResponse.bothAuditDaysChartData,apiResponse.bothAuditDaysTableData, apiResponse.bothAuditDaysChangesDailyTableData, apiResponse.bothAuditDaysChangesWeeklyTableData, auditdays_chart_options, table_options, auditdays_chart_header, auditdays_chart, auditdays_table_header, auditdays_table, auditdays_table_changes_daily_header, auditdays_table_changes_daily, auditdays_table_changes_weekly_header, auditdays_table_changes_weekly);
}

function updateAuditDays(chart_data_array, table_data_array, daily_change_data_array, weekly_change_data_array, chart_options, table_options) {
	document.getElementById('auditdays_chart_header').innerHTML  = 'Audit Days as ' + apiResponse.lastUpdateReportDateText;
	document.getElementById('auditdays_table_header').innerHTML  = '&nbsp;';
	document.getElementById('auditdays_table_changes_daily_header').innerHTML  = 'Changes since yesterday (' + apiResponse.yesterdayReportDateText + ')';
	document.getElementById('auditdays_table_changes_weekly_header').innerHTML  = 'Changes since week start (' + apiResponse.weekStartReportDateText + ')';

	// Audit Days Chart
	if (chart_data_array == null)
		return;
	var chart_data = new google.visualization.arrayToDataTable(chart_data_array);
	var chart = new google.visualization.ColumnChart(document.getElementById('auditdays_chart'));
	chart.draw(chart_data, chart_options);
     
	// Audit Days Table
	if (table_data_array == null)
		return;
	var table_data = new google.visualization.arrayToDataTable(table_data_array);
	var table = new google.visualization.Table(document.getElementById('auditdays_table'));
	
	//int_formatter.format(table_data,1);
	//int_formatter.format(table_data,2);
	//int_formatter.format(table_data,3);
	//int_formatter.format(table_data,4);
	//int_formatter.format(table_data,5);
	//int_formatter.format(table_data,6);
	table.draw(table_data, table_options);
     
	// Yesterday changes Table
	if (daily_change_data_array == null)
		return;
	var table_changes_daily_data = new google.visualization.arrayToDataTable(daily_change_data_array);
	var tableDailyChanges = new google.visualization.Table(document.getElementById('auditdays_table_changes_daily'));
	tableDailyChanges.draw(table_changes_daily_data, table_options);

	// Week start changes Table
	if (weekly_change_data_array == null)
		return;
	var table_changes_week_data = new google.visualization.arrayToDataTable(weekly_change_data_array);
	var tableWeeklyChanges = new google.visualization.Table(document.getElementById('auditdays_table_changes_weekly'));
	tableWeeklyChanges.draw(table_changes_week_data, table_options);
}
  
function updateSales(chart_options, table_options, currency_formatter) {
	document.getElementById('opportunity_header').innerHTML  = 'Opportunity Pipeline as ' + apiResponse.lastUpdateSalesDateText;
	document.getElementById('opportunity_delivery_header').innerHTML  = 'Opportunities Won to Proposed Delivery';

	updateSalesOpportunityDeliveryChartToMonthly("opportunity_delivery_chart");
	updateSalesOpportunityDeliveryTableToMonthly("opportunity_delivery_table");
	updateOpportunityPipelineChartToMonthly("opportunity_chart");
	updateOpportunityPipelineTableToMonthly("opportunity_table", "fab_ratio_amount", "fab_ratio_count");
}

function updateOpportunityPipelineChartToYesterday(target) {
	updateOpportunityPipelineChart(apiResponse.opportunityChartData, opportunity_chart_options, target);
}

function updateOpportunityPipelineChartToWeekly(target) {
	updateOpportunityPipelineChart(apiResponse.opportunityChartWeeklyData, opportunity_chart_options, target);
}

function updateOpportunityPipelineChartToMonthly(target) {
	updateOpportunityPipelineChart(apiResponse.opportunityChartMonthlyData, opportunity_chart_options, target);
}

function updateOpportunityPipelineChart(data, chart_options, target) {
	var chart_data = new google.visualization.arrayToDataTable([
		['Stage', 'Amount', { role: 'style' }, {role: 'annotation'} ],
		[data[1][0], data[1][1], '#33FFCC', ''],
		[data[2][0], data[2][1], '#33FF99', ''],
		[data[3][0], data[3][1], '#33FF66', ''],
		[data[4][0], data[4][1], '#33FF33', ''],
		[data[5][0], data[5][1], '#33FF33', ''],
		[data[6][0], data[6][1], '#FFFF00', '']
	]);
	var chart = new google.visualization.ColumnChart(document.getElementById(target));
	currency_formatter.format(chart_data,1);
	chart.draw(chart_data, chart_options);
}

function updateOpportunityPipelineTableToYesterday(target, fab_amount_target, fab_count_target) {
	updateOpportunityPipelineTable(apiResponse.opportunityTableData, table_options, target);
	// FAB Ratios
	updateSalesFabRatio(apiResponse.opportunityFabRatioTableData, 'FAB ($)', gaugeOptions, fab_amount_target);
	var fabRatioCount;
	if (apiResponse.opportunityTableData[2][5] > 0)
		fabRatioCount = Math.round(apiResponse.opportunityTableData[2][1]/apiResponse.opportunityTableData[2][5] * 100) / 100;
	else
		fabRatioCount = 0;
	updateSalesFabRatio(fabRatioCount, 'FAB (#)', gaugeOptions, fab_count_target);
}

function updateOpportunityPipelineTableToWeekly(target, fab_amount_target, fab_count_target) {
	updateOpportunityPipelineTable(apiResponse.opportunityTableWeeklyData, table_options, target);
	// FAB Ratios
	updateSalesFabRatio(apiResponse.opportunityFabRatioWeeklyTableData, 'FAB ($)', gaugeOptions, fab_amount_target);
	var fabRatioCount;
	if (apiResponse.opportunityTableWeeklyData[2][5] > 0)
		fabRatioCount = Math.round(apiResponse.opportunityTableWeeklyData[2][1]/apiResponse.opportunityTableWeeklyData[2][5] * 100) / 100;
	else
		fabRatioCount = 0;
	updateSalesFabRatio(fabRatioCount, 'FAB (#)', gaugeOptions, fab_count_target);
}

function updateOpportunityPipelineTableToMonthly(target, fab_amount_target, fab_count_target) {
	updateOpportunityPipelineTable(apiResponse.opportunityTableMonthlyData, table_options, target);
	// FAB Ratios
	updateSalesFabRatio(apiResponse.opportunityFabRatioMonthlyTableData, 'FAB ($)', gaugeOptions, fab_amount_target);
	var fabRatioCount;
	if (apiResponse.opportunityTableMonthlyData[2][5] > 0)
		fabRatioCount = Math.round(apiResponse.opportunityTableMonthlyData[2][1]/apiResponse.opportunityTableMonthlyData[2][5] * 100) / 100;
	else
		fabRatioCount = 0;
updateSalesFabRatio(fabRatioCount, 'FAB (#)', gaugeOptions, fab_count_target);
}

function updateOpportunityPipelineTable(data, table_options, target) {
	if (data == null)
		return;
	var opportunity_table_data = new google.visualization.DataTable();
	//opportunity_table_data.addColumn('string', '');
	opportunity_table_data.addColumn('number', data[0][1]);
	opportunity_table_data.addColumn('number', data[0][2]);
	opportunity_table_data.addColumn('number', data[0][3]);
	opportunity_table_data.addColumn('number', data[0][4]);
	opportunity_table_data.addColumn('number', data[0][5]);
	opportunity_table_data.addColumn('number', data[0][6]);
	opportunity_table_data.addRow([{v: data[1][1], f: formatAsCurrency(data[1][1])}, {v: data[1][2], f: formatAsCurrency(data[1][2])}, {v: data[1][3], f: formatAsCurrency(data[1][3])}, {v: data[1][4], f: formatAsCurrency(data[1][4])}, {v: data[1][5], f: formatAsCurrency(data[1][5])}, {v: data[1][6], f: formatAsCurrency(data[1][6])}]);
	opportunity_table_data.addRow([data[2][1], data[2][2], data[2][3], data[2][4], data[2][5], data[2][6]]);
	
	var table = new google.visualization.Table(document.getElementById(target));
	
	table.draw(opportunity_table_data, table_options);
}

function updateSalesOpportunityDeliveryTableToMonthly(target) {
	updateSalesOpportunityDeliveryTable(apiResponse.opportunityDeliveryMonthlyTableData, table_options, target);
}

function updateSalesOpportunityDeliveryTableToWeekly(target) {
	updateSalesOpportunityDeliveryTable(apiResponse.opportunityDeliveryWeeklyTableData, table_options, target);
}

function updateSalesOpportunityDeliveryTableToYesterday(target) {
	updateSalesOpportunityDeliveryTable(apiResponse.opportunityDeliveryTableData, table_options, target);
}

function updateSalesFabRatio(fabRatio, fabName, options, target) {
	var gaugeData = new google.visualization.DataTable();
	gaugeData.addColumn('number', fabName);
	gaugeData.addRows(2);
	gaugeData.setCell(0, 0, fabRatio);
	var gauge = new google.visualization.Gauge(document.getElementById(target));
	gauge.draw(gaugeData, options);
}
  
function updateSalesOpportunityDeliveryTable(data, table_options, target) {
	if (data == null)
		return;
	var opportunity_delivery_table_data = new google.visualization.arrayToDataTable(data);
	var delivery_table = new google.visualization.Table(document.getElementById(target));
	
	currency_formatter.format(opportunity_delivery_table_data,0);
	currency_formatter.format(opportunity_delivery_table_data,1);
	currency_formatter.format(opportunity_delivery_table_data,2);
	currency_formatter.format(opportunity_delivery_table_data,3);
	currency_formatter.format(opportunity_delivery_table_data,4);
	currency_formatter.format(opportunity_delivery_table_data,5);
	currency_formatter.format(opportunity_delivery_table_data,6);
	currency_formatter.format(opportunity_delivery_table_data,7);
	delivery_table.draw(opportunity_delivery_table_data, table_options);
}

function updateSalesOpportunityDeliveryChartToMonthly(target) {
	updateSalesOpportunityDeliveryChart(apiResponse.opportunityDeliveryMonthlyChartData, opportunity_delivery_chart_options, target);
}

function updateSalesOpportunityDeliveryChartToWeekly(target) {
	updateSalesOpportunityDeliveryChart(apiResponse.opportunityDeliveryWeeklyChartData, opportunity_delivery_chart_options, target);
}

function updateSalesOpportunityDeliveryChartToYesterday(target) {
	updateSalesOpportunityDeliveryChart(apiResponse.opportunityDeliveryChartData, opportunity_delivery_chart_options, target);
}

function updateSalesOpportunityDeliveryChart(data, chart_options, target) {
	// Opportunity Data Chart
	if (data == null)
		return;
	var chart_data = new google.visualization.arrayToDataTable([
		['Period', 'Amount', { role: 'style' }, {role: 'annotation'} ],
		[data[1][0], data[1][1], '#FFFF00', ''],
		[data[2][0], data[2][1], '#33FF00', ''],
		[data[3][0], data[3][1], '#33FF33', ''],
		[data[4][0], data[4][1], '#33FF66', ''],
		[data[5][0], data[5][1], '#33FF99', ''],
		[data[6][0], data[6][1], '#33FFCC', ''],
		[data[7][0], data[7][1], '#33FFFF', ''],
		[data[8][0], data[8][1], '#99FFFF', '']
	]);
	currency_formatter.format(chart_data,1);
	var chart = new google.visualization.ColumnChart(document.getElementById(target));
	chart.draw(chart_data, chart_options);
}

function updateTIS() {
	// Headers
	document.getElementById('tis_public_yearly_chart_header').innerHTML  = 'Public - Current Financial Year (as ' + apiResponse.lastUpdateTISDateText + ')';
	document.getElementById('tis_public_yearly_table_header').innerHTML  = 'Running Totals';
	document.getElementById('tis_public_elearning_monthly_chart_header').innerHTML  = 'eLearning - Current Month (as ' + apiResponse.lastUpdateTISDateText + ')';
	document.getElementById('tis_public_facetoface_monthly_chart_header').innerHTML  = 'Face To Face- Current Month (as ' + apiResponse.lastUpdateTISDateText + ')';
	document.getElementById('tis_inhouse_chart_header').innerHTML  = 'InHouse - Current Financial Year (as ' + apiResponse.lastUpdateTISDateText + ')';
	document.getElementById('tis_inhouse_table_header').innerHTML  = 'Running Totals';
		
	//Public Yearly Chart
	if (apiResponse.tisPublicYearlyChartData == null)
		return;
	var chart_data = new google.visualization.arrayToDataTable(apiResponse.tisPublicYearlyChartData);
	currency_formatter.format(chart_data,1);
	currency_formatter.format(chart_data,2);
	currency_formatter.format(chart_data,3);
	currency_formatter.format(chart_data,4);
	currency_formatter.format(chart_data,5);
	currency_formatter.format(chart_data,6);
	currency_formatter.format(chart_data,7);
	var chart = new google.visualization.AreaChart(document.getElementById('tis_public_yearly_chart'));
	chart.draw(chart_data, tis_public_yearly_chart_options);
	
	//Public Yearly Table
	if (apiResponse.tisPublicYearlyTableData == null)
		return;
	var table_data = new google.visualization.arrayToDataTable(apiResponse.tisPublicYearlyTableData);
	currency_formatter.format(table_data,1);
	currency_formatter.format(table_data,2);
	currency_formatter.format(table_data,3);
	currency_formatter.format(table_data,4);
	currency_formatter.format(table_data,5);
	currency_formatter.format(table_data,6);
	currency_formatter.format(table_data,7);
	var table = new google.visualization.Table(document.getElementById('tis_public_yearly_table'));
	table.draw(table_data, tis_table_options);
	
	// Public Monthly eLearning Chart
	if (apiResponse.tisPublicELearningMonthlyChartData == null)
		return;
	var elearning_month_chart_data = new google.visualization.arrayToDataTable(apiResponse.tisPublicELearningMonthlyChartData);
	currency_formatter.format(elearning_month_chart_data,1);
	currency_formatter.format(elearning_month_chart_data,2);
	currency_formatter.format(elearning_month_chart_data,3);
	var elearning_month_chart = new google.visualization.AreaChart(document.getElementById('tis_public_elearning_monthly_chart'));
	elearning_month_chart.draw(elearning_month_chart_data, tis_public_monthly_chart_options);
	
	// Public Monthly Face To Face Chart
	if (apiResponse.tisPublicFaceToFaceMonthlyChartData == null)
		return;
	var facetoface_month_chart_data = new google.visualization.arrayToDataTable(apiResponse.tisPublicFaceToFaceMonthlyChartData);
	currency_formatter.format(facetoface_month_chart_data,1);
	currency_formatter.format(facetoface_month_chart_data,2);
	currency_formatter.format(facetoface_month_chart_data,3);
	currency_formatter.format(facetoface_month_chart_data,4);
	var facetoface_month_chart = new google.visualization.AreaChart(document.getElementById('tis_public_facetoface_monthly_chart'));
	facetoface_month_chart.draw(facetoface_month_chart_data, tis_public_facetoface_chart_options);
	
	//Public Monthly Table
	if (apiResponse.tisPublicMonthlyTableData == null)
		return;
	var monthly_table_data = new google.visualization.arrayToDataTable(apiResponse.tisPublicMonthlyTableData);
	for (var i=1; i<monthly_table_data.getNumberOfColumns(); i++) {
		currency_formatter.format(monthly_table_data,i);
	}
	var monthly_table = new google.visualization.Table(document.getElementById('tis_public_monthly_table'));
	monthly_table.draw(monthly_table_data, tis_super_small_table_options);
	
	//InHouse Yearly Chart
	if (apiResponse.tisInHouseChartData == null)
		return;
	var inhouse_chart_data = new google.visualization.arrayToDataTable(apiResponse.tisInHouseChartData);
	currency_formatter.format(inhouse_chart_data,1);
	currency_formatter.format(inhouse_chart_data,2);
	currency_formatter.format(inhouse_chart_data,3);
	var inhouse_chart = new google.visualization.AreaChart(document.getElementById('tis_inhouse_chart'));
	inhouse_chart.draw(inhouse_chart_data, tis_inhouse_yearly_chart_options);
	
	//InHouse Yearly Table
	if (apiResponse.tisInHouseTableData == null)
		return;
	var inhouse_table_data = new google.visualization.arrayToDataTable(apiResponse.tisInHouseTableData);
	currency_formatter.format(inhouse_table_data,1);
	currency_formatter.format(inhouse_table_data,2);
	currency_formatter.format(inhouse_table_data,3);
	var inhouse_table = new google.visualization.Table(document.getElementById('tis_inhouse_table'));
	inhouse_table.draw(inhouse_table_data, tis_table_options);
}
 
function formatAsCurrency(x) {
	return '$'+ Math.round(x).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}
  