// Data
var apiResponse;

// Data Formatters
var int_formatter;
var currency_formatter;
var percentage_formatter;

// Visualizations Options
var auditdays_chart_options = {
	width: 700,
	height: 300,
	chartArea:{left:0,top:0, bottom:0, right:0, width:"80%",height:"80%"},
	legend: { position: 'right', alignment: 'center'},
	bar: { groupWidth: '75%' },
	colors: ['#33FF33', '#33FF99', '#33FFFF', '#000066', '#CC0066'],
	isStacked: true,
	series: {3: {type: "line"}, 4: {type: "line"} }
};


var tis_public_yearly_running_totals_chart_options = {
	width: 800,
	height: 375,
	chartArea:{top:10, left:90, bottom:0},
	legend: { position: 'right', alignment: 'center'},
	isStacked: true,
	//hAxis: { showTextEvery: 6, slantedText: true, slantedTextAngle: 30},
	series: {1: {type: "line"},3: {type: "line"}}
};

var tis_elearning_yearly_running_totals_chart_options = {
	width: 800,
	height: 375,
	chartArea:{top:10, left:90, bottom:0},
	legend: { position: 'right', alignment: 'center'},
	isStacked: true,
	//hAxis: { showTextEvery: 6, slantedText: true, slantedTextAngle: 30},
	series: {1: {type: "line"},2: {type: "line"}}
};

var tis_public_yearly_period_totals_chart_options = {
	width: 800,
	height: 375,
	chartArea:{top:10, left:90, bottom:0},
	legend: { position: 'right', alignment: 'center'},
	isStacked: true,
	hAxis: { slantedText: true, slantedTextAngle: 30},
	vAxis: { minValue: -50000},
	series: {1: {type: "line"},3: {type: "line"}}
};

var tis_elearning_yearly_period_totals_chart_options = {
	width: 800,
	height: 375,
	chartArea:{top:10, left:90, bottom:0},
	legend: { position: 'right', alignment: 'center'},
	isStacked: true,
	hAxis: { slantedText: true, slantedTextAngle: 30},
	series: {1: {type: "line"},2: {type: "line"}}
};

var tis_inhouse_yearly_chart_options = {
	width: 800,
	height: 375,
	chartArea:{top:10, left:90, bottom:0},
	legend: { position: 'right', alignment: 'center'},
	isStacked: true,
	//hAxis: { showTextEvery: 6, slantedText: true, slantedTextAngle: 30},
	vAxis: { minorGridlines: {count:3 }},
	series: {1: {type: "line"}}
};
var tis_inhouse_yearly_period_chart_options = {
	width: 800,
	height: 375,
	chartArea:{top:10, left:90, bottom:0},
	legend: { position: 'right', alignment: 'center'},
	isStacked: true,
	hAxis: { slantedText: true, slantedTextAngle: 30},
	series: {1: {type: "line"}}
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
	series: {1: {type: "line"}, 3: {type: "line"}}
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

var net_opportunity_chart_options = {
	width: 800,
	height: 450,
	chartArea:{left:90,top:20, bottom:0, right:0, width:"100%",height:"80%"},
	colors: ['#00CC66', '#009900', '#33CCFF', '#3399FF','#3366FF' ,'#3333FF', '#CC0066'],
	legend: { position: 'none'},
	bar: { groupWidth: '75%' },
	isStacked: true,
	hAxis: {slantedText: true, slantedTextAngle: 30},
	series: {6: {type: "line"}}
	};
var net_opportunity_table_options = {
	showRowNumber: false, 
	sort: 'disable',
	width: 800,
	height: '100%',
	cssClassNames: {tableCell: 'mediumText', headerCell: 'mediumText'},
	allowHtml: true
};
var table_options = {
	showRowNumber: false, 
	sort: 'disable',
	width: 600,
	height: '100%',
	allowHtml: true
};
var top_opp_table_options = {
	showRowNumber: false, 
	sort: 'enable',
	width: '100%',
	height: '100%'
};

var audit_changes_table_options = {
	showRowNumber: false, 
	sort: 'disable',
	width: '100%',
	height: '100%'
};
var changes_table_options = {
		showRowNumber: false, 
		sort: 'disable',
		width: 500,
		height: '100%'
	};
var tis_small_table_options = {
	showRowNumber: false, 
	sort: 'disable',
	cssClassNames: {tableCell: 'smallText', headerCell: 'smallText'},
	width: '100%',
	height: '100%'
};
var tis_super_small_table_options = {
		showRowNumber: false, 
		sort: 'disable',
		cssClassNames: {tableCell: 'smallText', headerCell: 'smallText'},
		width: '100%',
		height: '100%'
	};
var tis_table_options = {
	showRowNumber: false, 
	sort: 'disable',
	width: 400,
	height: '100%'
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

// Tooltips
$(function() {
    $( document ).tooltip({
      items: "[data-open-substatus], [title]",
      content: function() {
        var element = $( this );
        var data;
        if ( element.is( "[ms-data-open-substatus]" ) ) {
        	data = apiResponse.msOpenSubStatusTableData;
        } else if ( element.is( "[food-data-open-substatus]" ) ) {
        	data = apiResponse.foodOpenSubStatusTableData;
        } else if ( element.is( "[both-data-open-substatus]" ) ) {
        	data = apiResponse.bothOpenSubStatusTableData;
        } else {
        	return null;
        }
    	var retHtml = "";//"<p>Open Substatus:</p>";
    	if (data != null) {
        	retHtml += "<table>";
        	retHtml += "<tr>";
        	for (var i = 0; i < data[0].length; i++) {
        		retHtml += "<th>" + data[0][i] + "</th>";
        	}
        	retHtml += "</tr>";
        	for (var i = 1; i < data.length; i++) {
        		retHtml += "<tr>";
        		for (var j = 0; j < data[i].length; j++) {
            		retHtml += "<td>" + data[i][j] + "</td>";
            	}
				retHtml += "</tr>";
			} 
        	retHtml += "</table>";
    	}
    	return retHtml;
        
      }
    });
  });

// Functions
function updateAllVisualisationsForPrinting() {
	$.when( updateAllVisualisations() ).done( function() {
		//updateSalesOpportunityDeliveryChartToYesterday("opportunity_delivery_yesterday_chart");
		//updateSalesOpportunityDeliveryTableToYesterday("opportunity_delivery_yesterday_table");
		//updateOpportunityPipelineChartToYesterday("opportunity_yesterday_chart");
		//updateOpportunityPipelineTableToYesterday("opportunity_yesterday_table", "fab_yesterday_ratio_amount", "fab_yesterday_ratio_count");
		updateTISPublicYearlyToPeriodTotals("tis_public_yearly_chart_header", "tis_public_yearly_table_header", "tis_public_yearly_chart", "tis_public_yearly_table");
		updateTISelearningYearlyToPeriodTotals("tis_elearning_yearly_chart_header", "tis_elearning_yearly_table_header", "tis_elearning_yearly_chart", "tis_elearning_yearly_table");
		updateTISInHouseToPeriodTotals();
		
		$('.to_be_expanded').collapsible('expand');
		window.status = "readyForPrinting";
		
		document.getElementById('top_opportunities_header').innerHTML  = 'Open opportunities over $50k as ' + apiResponse.lastUpdateSalesDateText;
		var space = Math.round(1225 - (apiResponse.opportunityTopAmountsTableData.length-1) * 40);
		document.getElementById('top_opportunities_spacer').style.height = "" + space + "px";
		
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
	percentage_formatter = new google.visualization.NumberFormat({
		fractionDigits: 2,
		suffix: '%', 
	});

	// Init Visualizations
	updateAuditDaysToBoth('auditdays_chart_header', 'auditdays_chart', 'auditdays_table_header', 'auditdays_table', 'auditdays_table_changes_daily_header', 'auditdays_table_changes_daily', 'auditdays_table_changes_weekly_header', 'auditdays_table_changes_weekly', 'auditdays_table_changes_monthly_header', 'auditdays_table_changes_monthly');
	updateSales(opportunity_chart_options, table_options, currency_formatter);
	//updateNetOpportunitiesToBoth();
	updateTIS();
}

function updateTopOpportunities() {
	// Check Visisbility
	if (apiResponse.opportunityTopAmountsTableData == null) {
		document.getElementById('opportunity_container').style.display="none";
		return;
	}
	document.getElementById('opportunity_container').style.display="inline";
	
	var table_data = new google.visualization.arrayToDataTable(apiResponse.opportunityTopAmountsTableData);
	var table = new google.visualization.Table(document.getElementById('top_opportunities'));
	currency_formatter.format(table_data,4);
	
	table.draw(table_data, top_opp_table_options);
}

function updateAuditDaysToMS(auditdays_chart_header, auditdays_chart, auditdays_table_header, auditdays_table, auditdays_table_changes_daily_header, auditdays_table_changes_daily, auditdays_table_changes_weekly_header, auditdays_table_changes_weekly, auditdays_table_changes_monthly_header, auditdays_table_changes_monthly) {
	updateAuditDays("ms",apiResponse.msAuditDaysChartData,apiResponse.msAuditDaysTableData, apiResponse.msAuditDaysChangesDailyTableData, apiResponse.msAuditDaysChangesWeeklyTableData, apiResponse.msAuditDaysChangesMonthlyTableData, auditdays_chart_options, table_options, auditdays_chart_header, auditdays_chart, auditdays_table_header, auditdays_table, auditdays_table_changes_daily_header, auditdays_table_changes_daily, auditdays_table_changes_weekly_header, auditdays_table_changes_weekly);
}
	
function updateAuditDaysToFood(auditdays_chart_header, auditdays_chart, auditdays_table_header, auditdays_table, auditdays_table_changes_daily_header, auditdays_table_changes_daily, auditdays_table_changes_weekly_header, auditdays_table_changes_weekly, auditdays_table_changes_monthly_header, auditdays_table_changes_monthly) {
	updateAuditDays("food",apiResponse.foodAuditDaysChartData,apiResponse.foodAuditDaysTableData, apiResponse.foodAuditDaysChangesDailyTableData, apiResponse.foodAuditDaysChangesWeeklyTableData, apiResponse.foodAuditDaysChangesMonthlyTableData, auditdays_chart_options, table_options, auditdays_chart_header, auditdays_chart, auditdays_table_header, auditdays_table, auditdays_table_changes_daily_header, auditdays_table_changes_daily, auditdays_table_changes_weekly_header, auditdays_table_changes_weekly);
}

function updateAuditDaysToBoth(auditdays_chart_header, auditdays_chart, auditdays_table_header, auditdays_table, auditdays_table_changes_daily_header, auditdays_table_changes_daily, auditdays_table_changes_weekly_header, auditdays_table_changes_weekly, auditdays_table_changes_monthly_header, auditdays_table_changes_monthly) {
	updateAuditDays("both",apiResponse.bothAuditDaysChartData,apiResponse.bothAuditDaysTableData, apiResponse.bothAuditDaysChangesDailyTableData, apiResponse.bothAuditDaysChangesWeeklyTableData, apiResponse.bothAuditDaysChangesMonthlyTableData, auditdays_chart_options, table_options, auditdays_chart_header, auditdays_chart, auditdays_table_header, auditdays_table, auditdays_table_changes_daily_header, auditdays_table_changes_daily, auditdays_table_changes_weekly_header, auditdays_table_changes_weekly);
}

function updateAuditDays(type, chart_data_array, table_data_array, daily_change_data_array, weekly_change_data_array, monthly_change_data_array, chart_options, table_options) {
	// Check Visisbility
	if ((chart_data_array == null) || (table_data_array == null) || (daily_change_data_array == null) || (weekly_change_data_array == null) || (monthly_change_data_array == null)) {
		document.getElementById('audit_days_container').style.display="none";
		return;
	}
	document.getElementById('audit_days_container').style.display="inline";
	
	// Headers
	document.getElementById('auditdays_chart_header').innerHTML  = 'Audit Days as ' + apiResponse.lastUpdateReportDateText;
	document.getElementById('auditdays_table_header').innerHTML  = '&nbsp;';
	document.getElementById('auditdays_table_changes_daily_header').innerHTML  = 'Changes since yesterday (' + apiResponse.yesterdayReportDateText + ')';
	document.getElementById('auditdays_table_changes_weekly_header').innerHTML  = 'Changes since week start (' + apiResponse.weekStartReportDateText + ')';
	document.getElementById('auditdays_table_changes_monthly_header').innerHTML  = 'Changes since month start (' + apiResponse.monthStartReportDateText + ')';

	// Audit Days Chart
	var chart_data = new google.visualization.arrayToDataTable(chart_data_array);
	var chart = new google.visualization.ColumnChart(document.getElementById('auditdays_chart'));
	chart.draw(chart_data, chart_options);
     
	// Audit Days Table
	var table_data = new google.visualization.arrayToDataTable(table_data_array);
	table_data.Gf[2].c[0].v = "<a href=\"#\" title=\"\" " + type + "-data-open-substatus=\"\">Open</a>";
	var table = new google.visualization.Table(document.getElementById('auditdays_table'));
	var daily_revenue = 1750;
	table_data.addRow([{v:'Confirmed minus Budget ($)'},
	                   {v:table_data_array[7][1]*daily_revenue, f: formatAsCurrency(table_data_array[7][1]*daily_revenue)},
	                   {v:table_data_array[7][2]*daily_revenue, f: formatAsCurrency(table_data_array[7][2]*daily_revenue)},
	                   {v:table_data_array[7][3]*daily_revenue, f: formatAsCurrency(table_data_array[7][3]*daily_revenue)},
	                   {v:table_data_array[7][4]*daily_revenue, f: formatAsCurrency(table_data_array[7][4]*daily_revenue)},
	                   {v:table_data_array[7][5]*daily_revenue, f: formatAsCurrency(table_data_array[7][5]*daily_revenue)},
	                   {v:table_data_array[7][6]*daily_revenue, f: formatAsCurrency(table_data_array[7][6]*daily_revenue)}]);
	
	table.draw(table_data, table_options);
     
	// Yesterday changes Table
	var table_changes_daily_data = new google.visualization.arrayToDataTable(daily_change_data_array);
	var tableDailyChanges = new google.visualization.Table(document.getElementById('auditdays_table_changes_daily'));
	tableDailyChanges.draw(table_changes_daily_data, changes_table_options);

	// Week start changes Table
	var table_changes_week_data = new google.visualization.arrayToDataTable(weekly_change_data_array);
	var tableWeeklyChanges = new google.visualization.Table(document.getElementById('auditdays_table_changes_weekly'));
	tableWeeklyChanges.draw(table_changes_week_data, changes_table_options);
	
	// Month start changes Table
	var table_changes_month_data = new google.visualization.arrayToDataTable(monthly_change_data_array);
	var tableMonthlyChanges = new google.visualization.Table(document.getElementById('auditdays_table_changes_monthly'));
	tableMonthlyChanges.draw(table_changes_month_data, changes_table_options);
}

function updateNetOpportunitiesToBoth() {
	updateNetOpportunities(apiResponse.netOpportunityChartData.ms_plus_food,apiResponse.netOpportunityTableData.ms_plus_food,apiResponse.churnRatioTableData.ms_plus_food, apiResponse.shrinkageRatioTableData.ms_plus_food);
}

function updateNetOpportunitiesToMs() {
	updateNetOpportunities(apiResponse.netOpportunityChartData.ms,apiResponse.netOpportunityTableData.ms,apiResponse.churnRatioTableData.ms, apiResponse.shrinkageRatioTableData.ms);
}

function updateNetOpportunitiesToFood() {
	updateNetOpportunities(apiResponse.netOpportunityChartData.food,apiResponse.netOpportunityTableData.food,apiResponse.churnRatioTableData.food, apiResponse.shrinkageRatioTableData.food);
}

function updateNetOpportunities(chart_data_array, table_data_array, churn_table_data_array, shrinkage_table_data_array) {
	document.getElementById('net_opportunity_header').innerHTML  = 'Opportunities vs Cancellations as ' + apiResponse.netOpportunitiesDateText;
	
	// Check Visibility
	if ((table_data_array == null) || (chart_data_array == null)) {
		document.getElementById('net_opportunity_container').style.display="none";
		return;
	}
	document.getElementById('net_opportunity_container').style.display="inline";
	
	var chart_data = new google.visualization.arrayToDataTable(chart_data_array);
	var chart = new google.visualization.ColumnChart(document.getElementById('net_opportunity_chart'));
	currency_formatter.format(chart_data,1);
	currency_formatter.format(chart_data,2);
	currency_formatter.format(chart_data,3);
	currency_formatter.format(chart_data,4);
	currency_formatter.format(chart_data,5);
	currency_formatter.format(chart_data,6);
	currency_formatter.format(chart_data,7);
	
	chart.draw(chart_data, net_opportunity_chart_options);
	
	// Table
	var table_data = new google.visualization.arrayToDataTable(table_data_array);
	var table = new google.visualization.Table(document.getElementById('net_opportunity_table'));
	for (var i = 1; i < table_data.getNumberOfColumns(); i++) {
		currency_formatter.format(table_data,i);
	}
	
	table_data.setProperty(0,0,'style', 'color: #000000; background-color: #00CC66; text-shadow:none;');
	table_data.setProperty(1,0,'style', 'color: #000000; background-color: #009900; text-shadow:none;');
	table_data.setProperty(2,0,'style', 'color: #000000; background-color: #33CCFF; text-shadow:none;');
	table_data.setProperty(3,0,'style', 'color: #000000; background-color: #3399FF; text-shadow:none;');
	table_data.setProperty(4,0,'style', 'color: #bbbbbb; background-color: #3366FF; text-shadow:none;');
	table_data.setProperty(5,0,'style', 'color: #bbbbbb; background-color: #3333FF; text-shadow:none;');
	table_data.setProperty(6,0,'style', 'color: #bbbbbb; background-color: #CC0066; text-shadow:none;');
	
	table_data.addRow(["Churn Ratio", 
			{v: churn_table_data_array[1][1], f: formatAsPercentage(churn_table_data_array[1][1])},
			{v: churn_table_data_array[1][1], f: formatAsPercentage(churn_table_data_array[1][2])},
			{v: churn_table_data_array[1][1], f: formatAsPercentage(churn_table_data_array[1][3])},
			{v: churn_table_data_array[1][1], f: formatAsPercentage(churn_table_data_array[1][4])},
			{v: churn_table_data_array[1][1], f: formatAsPercentage(churn_table_data_array[1][5])},
			{v: churn_table_data_array[1][1], f: formatAsPercentage(churn_table_data_array[1][6])},
			{v: churn_table_data_array[1][1], f: formatAsPercentage(churn_table_data_array[1][7])},
			{v: churn_table_data_array[1][1], f: formatAsPercentage(churn_table_data_array[1][8])},
			{v: churn_table_data_array[1][1], f: formatAsPercentage(churn_table_data_array[1][9])},
			{v: churn_table_data_array[1][1], f: formatAsPercentage(churn_table_data_array[1][10])},
			{v: churn_table_data_array[1][1], f: formatAsPercentage(churn_table_data_array[1][11])},
			{v: churn_table_data_array[1][1], f: formatAsPercentage(churn_table_data_array[1][12])}
	]);
	
	table_data.addRow(["Shrinkage Ratio", 
   			{v: shrinkage_table_data_array[1][1], f: formatAsPercentage(shrinkage_table_data_array[1][1])},
   			{v: shrinkage_table_data_array[1][1], f: formatAsPercentage(shrinkage_table_data_array[1][2])},
   			{v: shrinkage_table_data_array[1][1], f: formatAsPercentage(shrinkage_table_data_array[1][3])},
   			{v: shrinkage_table_data_array[1][1], f: formatAsPercentage(shrinkage_table_data_array[1][4])},
   			{v: shrinkage_table_data_array[1][1], f: formatAsPercentage(shrinkage_table_data_array[1][5])},
   			{v: shrinkage_table_data_array[1][1], f: formatAsPercentage(shrinkage_table_data_array[1][6])},
   			{v: shrinkage_table_data_array[1][1], f: formatAsPercentage(shrinkage_table_data_array[1][7])},
   			{v: shrinkage_table_data_array[1][1], f: formatAsPercentage(shrinkage_table_data_array[1][8])},
   			{v: shrinkage_table_data_array[1][1], f: formatAsPercentage(shrinkage_table_data_array[1][9])},
   			{v: shrinkage_table_data_array[1][1], f: formatAsPercentage(shrinkage_table_data_array[1][10])},
   			{v: shrinkage_table_data_array[1][1], f: formatAsPercentage(shrinkage_table_data_array[1][11])},
   			{v: shrinkage_table_data_array[1][1], f: formatAsPercentage(shrinkage_table_data_array[1][12])}
   	]);
	table.draw(table_data, net_opportunity_table_options);
	
	// Churn Table
	//var churn_table_data = new google.visualization.arrayToDataTable(churn_table_data_array);
	//var churn_table = new google.visualization.Table(document.getElementById('net_opportunity_churn_table'));
	//for (var i = 1; i < churn_table_data.getNumberOfColumns(); i++) {
	//	percentage_formatter.format(churn_table_data,i);
	//}
	//churn_table.draw(churn_table_data, net_opportunity_table_options);
}

function updateSales(chart_options, table_options, currency_formatter) {
	document.getElementById('opportunity_header').innerHTML  = 'Opportunity Pipeline as ' + apiResponse.lastUpdateSalesDateText;
	document.getElementById('opportunity_delivery_header').innerHTML  = 'Opportunities Won to Proposed Delivery';

	updateSalesOpportunityDeliveryChartToMonthly("opportunity_delivery_chart");
	updateSalesOpportunityDeliveryTableToMonthly("opportunity_delivery_table");
	updateOpportunityPipelineChartToMonthly("opportunity_chart");
	updateOpportunityPipelineTableToMonthly("opportunity_table", "fab_ratio_amount", "fab_ratio_count");
	updateTopOpportunities();
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
	// Check Visibility
	if (data == null) {
		document.getElementById('opportunity_container').style.display="none";
		return;
	}
	document.getElementById('opportunity_container').style.display="inline";
	
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
	if (apiResponse.opportunityTableData == null)
		return;
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
	if (apiResponse.opportunityTableMonthlyData == null)
		return;
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
	if (apiResponse.opportunityTableMonthlyData == null)
		return;
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
	// Check Visibility
	if (data == null) {
		document.getElementById('opportunity_container').style.display="none";
		return;
	}
	document.getElementById('opportunity_container').style.display="inline";

	var opportunity_table_data = new google.visualization.DataTable();
	opportunity_table_data.addColumn('string', '');
	opportunity_table_data.addColumn('number', data[0][1]);
	opportunity_table_data.addColumn('number', data[0][2]);
	opportunity_table_data.addColumn('number', data[0][3]);
	opportunity_table_data.addColumn('number', data[0][4]);
	opportunity_table_data.addColumn('number', data[0][5]);
	opportunity_table_data.addColumn('number', data[0][6]);
	opportunity_table_data.addRow([data[1][0], {v: data[1][1], f: formatAsCurrency(data[1][1])}, {v: data[1][2], f: formatAsCurrency(data[1][2])}, {v: data[1][3], f: formatAsCurrency(data[1][3])}, {v: data[1][4], f: formatAsCurrency(data[1][4])}, {v: data[1][5], f: formatAsCurrency(data[1][5])}, {v: data[1][6], f: formatAsCurrency(data[1][6])}]);
	opportunity_table_data.addRow([data[2][0], data[2][1], data[2][2], data[2][3], data[2][4], data[2][5], data[2][6]]);
	//opportunity_table_data.addRow([data[3][0], data[3][1], data[3][2], data[3][3], data[3][4], data[3][5], data[3][6]]);
	//opportunity_table_data.addRow([data[4][0], data[4][1], data[4][2], data[4][3], data[4][4], data[4][5], data[4][6]]);
	
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
	// Check Visibility
	if (fabRatio == null) {
		document.getElementById('opportunity_container').style.display="none";
		return;
	}
	document.getElementById('opportunity_container').style.display="inline";
	var gaugeData = new google.visualization.DataTable();
	gaugeData.addColumn('number', fabName);
	gaugeData.addRows(2);
	gaugeData.setCell(0, 0, fabRatio);
	var gauge = new google.visualization.Gauge(document.getElementById(target));
	gauge.draw(gaugeData, options);
}
  
function updateSalesOpportunityDeliveryTable(data, table_options, target) {
	// Check Visibility
	if (data == null) {
		document.getElementById('opportunity_container').style.display="none";
		return;
	}
	document.getElementById('opportunity_container').style.display="inline";
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
	// Check Visibility
	if (data == null) {
		document.getElementById('opportunity_container').style.display="none";
		return;
	}
	document.getElementById('opportunity_container').style.display="inline";
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

function updateTISelearningYearlyToPeriodTotals(chart_header_target, table_header_target, chart_target, table_target) {
	// Headers
	document.getElementById('tis_elearning_yearly_chart_header').innerHTML  = 'Current Financial Year (as ' + apiResponse.lastUpdateTISDateText + ')';
	document.getElementById('tis_elearning_yearly_table_header').innerHTML  = 'Period Totals';
	
	//eLearning Yearly Chart
	if (apiResponse.tisElearningYearlyPeriodTotalsChartData == null)
		return;
	var chart_data = new google.visualization.arrayToDataTable(apiResponse.tisElearningYearlyPeriodTotalsChartData);
	currency_formatter.format(chart_data,1);
	currency_formatter.format(chart_data,2);
	currency_formatter.format(chart_data,3);
	var chart_view = new google.visualization.DataView(chart_data);
	chart_view.hideColumns([3]);
	
	var chart = new google.visualization.ColumnChart(document.getElementById(chart_target));
	chart.draw(chart_view, tis_elearning_yearly_period_totals_chart_options);
	
	//eLearning Yearly Table
	if (apiResponse.tisElearningYearlyPeriodTotalsTableData == null)
		return;
	var table_data = new google.visualization.arrayToDataTable(apiResponse.tisElearningYearlyPeriodTotalsTableData);
	currency_formatter.format(table_data,1);
	currency_formatter.format(table_data,2);
	currency_formatter.format(table_data,3);
	var table = new google.visualization.Table(document.getElementById(table_target));
	var view = new google.visualization.DataView(table_data);
	view.hideColumns([3]);
	table.draw(view, tis_table_options);
}

function updateTISPublicYearlyToPeriodTotals(chart_header_target, table_header_target, chart_target, table_target) {
	// Headers
	document.getElementById(chart_header_target).innerHTML  = 'Current Financial Year (as ' + apiResponse.lastUpdateTISDateText + ')';
	document.getElementById(table_header_target).innerHTML  = 'Period Totals';
	
	//Public Yearly Chart
	if (apiResponse.tisPublicYearlyPeriodTotalsChartData == null)
		return;
	var chart_data = new google.visualization.arrayToDataTable(apiResponse.tisPublicYearlyPeriodTotalsChartData);
	currency_formatter.format(chart_data,1);
	currency_formatter.format(chart_data,2);
	currency_formatter.format(chart_data,3);
	currency_formatter.format(chart_data,4);
	var chart_view = new google.visualization.DataView(chart_data);
	chart_view.hideColumns([2,4]);
	
	var chart = new google.visualization.ColumnChart(document.getElementById(chart_target));
	chart.draw(chart_view, tis_public_yearly_period_totals_chart_options);
	
	//Public Yearly Table
	if (apiResponse.tisPublicYearlyPeriodTotalsTableData == null)
		return;
	var table_data = new google.visualization.arrayToDataTable(apiResponse.tisPublicYearlyPeriodTotalsTableData);
	currency_formatter.format(table_data,1);
	currency_formatter.format(table_data,2);
	currency_formatter.format(table_data,3);
	currency_formatter.format(table_data,4);
	var table = new google.visualization.Table(document.getElementById(table_target));
	var view = new google.visualization.DataView(table_data);
	view.hideColumns([2,4]);
	table.draw(view, tis_table_options);
}

function updateTISelearningYearlyToRunningTotals(chart_header_target, table_header_target, chart_target, table_target) {
	// Headers
	document.getElementById('tis_elearning_yearly_chart_header').innerHTML  = 'Current Financial Year (as ' + apiResponse.lastUpdateTISDateText + ')';
	document.getElementById('tis_elearning_yearly_table_header').innerHTML  = 'Running Totals';
	
	//eLearning Yearly Chart
	if (apiResponse.tisElearningYearlyRunningTotalsChartData == null)
		return;
	var chart_data = new google.visualization.arrayToDataTable(apiResponse.tisElearningYearlyRunningTotalsChartData);
	currency_formatter.format(chart_data,1);
	currency_formatter.format(chart_data,2);
	currency_formatter.format(chart_data,3);
	var chart_view = new google.visualization.DataView(chart_data);
	chart_view.hideColumns([3]);
	
	var chart = new google.visualization.AreaChart(document.getElementById(chart_target));
	chart.draw(chart_view, tis_elearning_yearly_running_totals_chart_options);
	
	//eLearning Yearly Table
	if (apiResponse.tisElearningYearlyRunningTotalsTableData == null)
		return;
	var table_data = new google.visualization.arrayToDataTable(apiResponse.tisElearningYearlyRunningTotalsTableData);
	currency_formatter.format(table_data,1);
	currency_formatter.format(table_data,2);
	currency_formatter.format(table_data,3);
	var table = new google.visualization.Table(document.getElementById(table_target));
	var view = new google.visualization.DataView(table_data);
	view.hideColumns([3]);
	table.draw(view, tis_table_options);	
}

function updateTISPublicYearlyToRunningTotals(chart_header_target, table_header_target, chart_target, table_target) {
	// Headers
	document.getElementById(chart_header_target).innerHTML  = 'Current Financial Year (as ' + apiResponse.lastUpdateTISDateText + ')';
	document.getElementById(table_header_target).innerHTML  = 'Running Totals';
			
	//Public Yearly Chart
	if (apiResponse.tisPublicYearlyRunningTotalsChartData == null)
		return;
	var chart_data = new google.visualization.arrayToDataTable(apiResponse.tisPublicYearlyRunningTotalsChartData);
	currency_formatter.format(chart_data,1);
	currency_formatter.format(chart_data,2);
	currency_formatter.format(chart_data,3);
	currency_formatter.format(chart_data,4);
	var chart_view = new google.visualization.DataView(chart_data);
	chart_view.hideColumns([2,4]);
	
	var chart = new google.visualization.AreaChart(document.getElementById(chart_target));
	chart.draw(chart_view, tis_public_yearly_running_totals_chart_options);
	
	//Public Yearly Table
	if (apiResponse.tisPublicYearlyRunningTotalsTableData == null)
		return;
	var table_data = new google.visualization.arrayToDataTable(apiResponse.tisPublicYearlyRunningTotalsTableData);
	currency_formatter.format(table_data,1);
	currency_formatter.format(table_data,2);
	currency_formatter.format(table_data,3);
	currency_formatter.format(table_data,4);
	var table = new google.visualization.Table(document.getElementById(table_target));
	var view = new google.visualization.DataView(table_data);
	view.hideColumns([2,4]);
	table.draw(view, tis_table_options);	
}

function updateTIS() {
	// Check Visibility Public
	if ((apiResponse.tisElearningMonthlyChartData == null) 
			|| (apiResponse.tisPublicMonthlyChartData == null) 
			|| (apiResponse.tisPublicMonthlyTableData == null)
			|| (apiResponse.tisElearningMonthlyTableData == null)			
			|| (apiResponse.tisPublicYearlyRunningTotalsChartData == null)
			|| (apiResponse.tisPublicYearlyRunningTotalsTableData == null)
			|| (apiResponse.tisElearningYearlyRunningTotalsChartData == null)
			|| (apiResponse.tisElearningYearlyRunningTotalsTableData == null)) {
		document.getElementById('training_public_container').style.display="none"
		document.getElementById('training_elearning_container').style.display="none"
		
	} else {
		document.getElementById('training_public_container').style.display="inline";
		document.getElementById('training_elearning_container').style.display="inline";
		
		// Yearly
		updateTISPublicYearlyToRunningTotals('tis_public_yearly_chart_header', 'tis_public_yearly_table_header', 'tis_public_yearly_chart', 'tis_public_yearly_table');
		updateTISelearningYearlyToRunningTotals('tis_elearning_yearly_chart_header', 'tis_elearning_yearly_table_header', 'tis_elearning_yearly_chart', 'tis_elearning_yearly_table');
		
		// Monthly
		document.getElementById('tis_public_monthly_chart_header').innerHTML  = 'Current Month (as ' + apiResponse.lastUpdateTISDateText + ')';
		document.getElementById('tis_elearning_monthly_chart_header').innerHTML  = 'Current Month (as ' + apiResponse.lastUpdateTISDateText + ')';
		
		// Public Monthly eLearning Chart
		var elearning_month_chart_data = new google.visualization.arrayToDataTable(apiResponse.tisElearningMonthlyChartData);
		currency_formatter.format(elearning_month_chart_data,1);
		currency_formatter.format(elearning_month_chart_data,2);
		currency_formatter.format(elearning_month_chart_data,3);
		var elearning_chart_view = new google.visualization.DataView(elearning_month_chart_data);
		elearning_chart_view.hideColumns([3]);
		
		var elearning_month_chart = new google.visualization.AreaChart(document.getElementById('tis_elearning_monthly_chart'));
		elearning_month_chart.draw(elearning_chart_view, tis_public_monthly_chart_options);
		
		// Public Monthly Face To Face Chart
		var facetoface_month_chart_data = new google.visualization.arrayToDataTable(apiResponse.tisPublicMonthlyChartData);
		currency_formatter.format(facetoface_month_chart_data,1);
		currency_formatter.format(facetoface_month_chart_data,2);
		currency_formatter.format(facetoface_month_chart_data,3);
		currency_formatter.format(facetoface_month_chart_data,4);
		var facetoface_chart_view = new google.visualization.DataView(facetoface_month_chart_data);
		facetoface_chart_view.hideColumns([2,4]);
		var facetoface_month_chart = new google.visualization.AreaChart(document.getElementById('tis_public_monthly_chart'));
		facetoface_month_chart.draw(facetoface_chart_view, tis_public_facetoface_chart_options);
		
		//Public Monthly Table
		var public_monthly_table_data = new google.visualization.arrayToDataTable(cleanArray(apiResponse.tisPublicMonthlyTableData));
		for (var i=1; i<public_monthly_table_data.getNumberOfColumns(); i++) {
			currency_formatter.format(public_monthly_table_data,i);
		}
		var facetoface_table_view = new google.visualization.DataView(public_monthly_table_data);
		facetoface_table_view.hideRows([1,3]);
		var public_monthly_table = new google.visualization.Table(document.getElementById('tis_public_monthly_table'));
		public_monthly_table.draw(facetoface_table_view, tis_super_small_table_options);
		
		//eLearning Monthly Table
		var elearning_monthly_table_data = new google.visualization.arrayToDataTable(cleanArray(apiResponse.tisElearningMonthlyTableData));
		for (var i=1; i<elearning_monthly_table_data.getNumberOfColumns(); i++) {
			currency_formatter.format(elearning_monthly_table_data,i);
		}
		var elearning_table_view = new google.visualization.DataView(elearning_monthly_table_data);
		elearning_table_view.hideRows([2]);
		var elearning_monthly_table = new google.visualization.Table(document.getElementById('tis_elearning_monthly_table'));
		elearning_monthly_table.draw(elearning_table_view, tis_super_small_table_options);
	}
	
	// Check Visibility In House
	if ((apiResponse.tisInHouseRunningTotalsChartData == null) || (apiResponse.tisInHouseRunningTotalsChartData == null)) {
		document.getElementById('training_inhouse_container').style.display="none"
		return;
	}
	document.getElementById('training_inhouse_container').style.display="inline";
	
	updateTISInHouseToRunningTotals();
}

function updateTISInHouseToRunningTotals() {
	// Headers
	document.getElementById('tis_inhouse_chart_header').innerHTML  = 'InHouse - Current Financial Year (as ' + apiResponse.lastUpdateTISDateText + ')';
	document.getElementById('tis_inhouse_table_header').innerHTML  = 'Running Totals';
	
	//InHouse Yearly Chart
	if (apiResponse.tisInHouseRunningTotalsChartData == null)
		return;
	var inhouse_chart_data = new google.visualization.arrayToDataTable(apiResponse.tisInHouseRunningTotalsChartData);
	currency_formatter.format(inhouse_chart_data,1);
	currency_formatter.format(inhouse_chart_data,2);
	//currency_formatter.format(inhouse_chart_data,3);
	var inhouse_chart = new google.visualization.AreaChart(document.getElementById('tis_inhouse_chart'));
	inhouse_chart.draw(inhouse_chart_data, tis_inhouse_yearly_chart_options);
	
	//InHouse Yearly Table
	if (apiResponse.tisInHouseRunningTotalsChartData == null)
		return;
	var inhouse_table_data = new google.visualization.arrayToDataTable(apiResponse.tisInHouseRunningTotalsTableData);
	currency_formatter.format(inhouse_table_data,1);
	currency_formatter.format(inhouse_table_data,2);
	//currency_formatter.format(inhouse_table_data,3);
	var inhouse_table = new google.visualization.Table(document.getElementById('tis_inhouse_table'));
	inhouse_table.draw(inhouse_table_data, tis_table_options);
}

function updateTISInHouseToPeriodTotals() {
	// Headers
	document.getElementById('tis_inhouse_chart_header').innerHTML  = 'InHouse - Current Financial Year (as ' + apiResponse.lastUpdateTISDateText + ')';
	document.getElementById('tis_inhouse_table_header').innerHTML  = 'Period Totals';
	
	//InHouse Yearly Chart
	if (apiResponse.tisInHousePeriodTotalsChartData == null)
		return;
	var inhouse_chart_data = new google.visualization.arrayToDataTable(apiResponse.tisInHousePeriodTotalsChartData);
	currency_formatter.format(inhouse_chart_data,1);
	currency_formatter.format(inhouse_chart_data,2);
	//currency_formatter.format(inhouse_chart_data,3);
	var inhouse_chart = new google.visualization.ColumnChart(document.getElementById('tis_inhouse_chart'));
	inhouse_chart.draw(inhouse_chart_data, tis_inhouse_yearly_period_chart_options);
	
	//InHouse Yearly Table
	if (apiResponse.tisInHousePeriodTotalsChartData == null)
		return;
	var inhouse_table_data = new google.visualization.arrayToDataTable(apiResponse.tisInHousePeriodTotalsChartData);
	currency_formatter.format(inhouse_table_data,1);
	currency_formatter.format(inhouse_table_data,2);
	//currency_formatter.format(inhouse_table_data,3);
	var inhouse_table = new google.visualization.Table(document.getElementById('tis_inhouse_table'));
	inhouse_table.draw(inhouse_table_data, tis_table_options);	
}

function formatAsCurrency(x) {
	return '$'+ Math.round(x).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

function formatAsPercentage(x) {
	return (x*100).toFixed(2) + '%';
}
 
function cleanArray(actual){
  if (!(actual instanceof Array))
	  return actual;
  var newArray = new Array();
  for(var i = 0; i<actual.length; i++){
	  if (actual[i] instanceof Array) {
		  newArray.push(cleanArray(actual[i]));
	  } else if (actual[i] != null) {
		  newArray.push(actual[i]);
	  } else {
	  	  console.log(actual[i]);
	  }
  }
  return newArray;
}