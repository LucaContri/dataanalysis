// Data
var apiResponse;

// Data Formatters
var int_formatter;
var currency_formatter;
var percentage_formatter;
var decimal_formatter;

// Visualizations Options
var phone_chart_options = {
	width: 750,
	height: 350,
	colors: ['#3366cc', '#dc3912', '#ff9900', 'FF3333'],
	chartArea:{left:35,top:50, bottom:0, right:35},
	legend: { position: 'none'},
	bar: { groupWidth: '70%' },
	isStacked: true,
	series: {2: {type: "line", targetAxisIndex: 1}, 3: {type: "line", targetAxisIndex: 1}}
};

var phone_table_options = {
	showRowNumber: false, 
	sort: 'disable',
	width: 600,
	height: '100%',
	allowHtml: true
};

var new_business_opp_chart_options = {
	width: 750,
	height: 350,
	colors: ['#339933', '#3366cc', '#ff9900', '#dc3912', '#990099'],
	chartArea:{left:35,top:50, bottom:0, right:35},
	legend: { position: 'none'},
	bar: { groupWidth: '70%' },
	isStacked: true,
	series: {
		3: {type: "line", targetAxisIndex: 0},
		4: {type: "line", targetAxisIndex: 1}
	}
};

var new_business_opp_table_options = {
	showRowNumber: false, 
	sort: 'disable',
	width: 600,
	height: '100%',
	allowHtml: true
};
	
var scheduling_audit_chart_options = {
	width: 750,
	height: 350,
	colors: ['#000066', '#33FF33', '#33FF99', '#33FFFF'],
	chartArea:{left:35,top:50, bottom:0, right:35},
	legend: { position: 'none'},
	bar: { groupWidth: '70%' },
	isStacked: true,
	series: {0: {type: "line", targetAxisIndex: 1}}
};

var scheduling_audit_table_options = {
	showRowNumber: false, 
	sort: 'disable',
	width: 600,
	height: '100%',
	allowHtml: true
};

var scheduling_target_chart_options = {
	width: 750,
	height: 350,
	colors: ['#33CC00', '#33FF33', '#33FF99', '#33FFFF'],
	chartArea:{left:35,top:50, bottom:0, right:35},
	legend: { position: 'none'},
	bar: { groupWidth: '70%' },
	isStacked: true
};

var scheduling_target_table_options = {
	showRowNumber: false, 
	sort: 'disable',
	width: 600,
	height: '100%',
	allowHtml: true
};

var scheduling_validated_chart_options = {
	width: 700,
	height: 350,
	colors: ['#33FF99', '#33FFFF'],
	chartArea:{left:35,top:50, bottom:0, right:35},
	legend: { position: 'none'},
	bar: { groupWidth: '70%' },
	isStacked: true
};

var scheduling_validated_table_options = {
	showRowNumber: false, 
	sort: 'disable',
	width: 600,
	height: '100%',
	allowHtml: true
};

var scheduling_auditors_chart_options = {
	width: 700,
	height: 350,
	colors: ['#33FF99', '#33FFFF', '#000066'],
	chartArea:{left:35,top:50, bottom:0, right:35},
	legend: { position: 'none'},
	bar: { groupWidth: '70%' },
	isStacked: true,
	series: {2: {type: "line", targetAxisIndex: 1}}
};

var scheduling_auditors_table_options = {
	showRowNumber: false, 
	sort: 'disable',
	width: 600,
	height: '100%',
	allowHtml: true
};
	
var arg_chart_options = {
	width: 750,
	height: 350,
	colors: ['#3366cc', '#dc3912', '#ff9900'],
	chartArea:{left:35,top:50, bottom:0, right:35},
	legend: { position: 'none'},
	bar: { groupWidth: '80%' },
	isStacked: false,
	series: {2: {type: "line", targetAxisIndex: 1}}
};

var arg_table_options = {
	showRowNumber: false, 
	sort: 'disable',
	width: 600,
	height: '100%',
	allowHtml: true
	
};
var prc_rejections_table_options = {
	sort: 'enable',
	width: 1200,
	height: '100%',
	allowHtml: true
	
};

// Functions

function updateAllVisualisations() {
	// Load Data
	if (window.XMLHttpRequest) {
	  	// code for IE7+, Firefox, Chrome, Opera, Safari
	  	xmlhttp=new XMLHttpRequest();
	} else {
	  	// code for IE6, IE5
		xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
	}
	  
	xmlhttp.open("GET","kpi",false);
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
		suffix: '%'
	});
	decimal_formatter = new google.visualization.NumberFormat({
		fractionDigits: 2
	});

	// Init Visualizations
	updateSalesPhoneMetrics(apiResponse.lastUpdateSalesPhoneMetrics, apiResponse.salesPhoneMetrics?apiResponse.salesPhoneMetrics.chart:null, apiResponse.salesPhoneMetrics?apiResponse.salesPhoneMetrics.table:null);
	updateSchedulingConfirmedRatiosToFood();
	//updateSchedulingTargetRatios(apiResponse.lastUpdateScheduling, apiResponse.onTargetRatios?apiResponse.onTargetRatios.chart:null, apiResponse.onTargetRatios?apiResponse.onTargetRatios.table:null);
	updateSchedulingValidatedToFood();
	updateSchedulingAuditorsToFood();
	updateAdminARG(apiResponse.lastUpdateAdmin, apiResponse.adminArgProcessing?apiResponse.adminArgProcessing.chart:null, apiResponse.adminArgProcessing?apiResponse.adminArgProcessing.table:null);
	updateAdminPhoneMetrics(apiResponse.lastUpdateAdminPhoneMetrics, apiResponse.adminPhoneMetrics?apiResponse.adminPhoneMetrics.chart:null, apiResponse.adminPhoneMetrics?apiResponse.adminPhoneMetrics.table:null);
	updatePRCARGToFood();
	//updatePRCRejections(apiResponse.lastUpdatePrc, apiResponse.prcRejections);
	updateAuditorsARG(apiResponse.lastUpdateDelivery, apiResponse.deliveryArgProcessing?apiResponse.deliveryArgProcessing.chart:null, apiResponse.deliveryArgProcessing?apiResponse.deliveryArgProcessing.table:null);
	updateOppProcessingDays(apiResponse.lastUpdateNewBusiness, apiResponse.oppProcessingDays?apiResponse.oppProcessingDays.chart:null, apiResponse.oppProcessingDays?apiResponse.oppProcessingDays.table:null);
}

function updateSchedulingConfirmedRatiosToFood() {
	if (apiResponse.schedulingConfirmedRatios && apiResponse.schedulingConfirmedRatios.chart && apiResponse.schedulingConfirmedRatios.table)
		updateSchedulingConfirmedRatios(apiResponse.lastUpdateScheduling, apiResponse.schedulingConfirmedRatios.chart.food, apiResponse.schedulingConfirmedRatios.table.food);
}
function updateSchedulingConfirmedRatiosToMS() {
	if (apiResponse.schedulingConfirmedRatios && apiResponse.schedulingConfirmedRatios.chart && apiResponse.schedulingConfirmedRatios.table)
		updateSchedulingConfirmedRatios(apiResponse.lastUpdateScheduling, apiResponse.schedulingConfirmedRatios.chart.ms, apiResponse.schedulingConfirmedRatios.table.ms);
}
function updateSchedulingConfirmedRatiosToPS() {
	if (apiResponse.schedulingConfirmedRatios && apiResponse.schedulingConfirmedRatios.chart && apiResponse.schedulingConfirmedRatios.table)
		updateSchedulingConfirmedRatios(apiResponse.lastUpdateScheduling, apiResponse.schedulingConfirmedRatios.chart.ps, apiResponse.schedulingConfirmedRatios.table.ps);
}
function updateSchedulingValidatedToFood() {
	if (apiResponse.schedulingValidated && apiResponse.schedulingValidated.chart && apiResponse.schedulingValidated.table)
		updateSchedulingValidated(apiResponse.lastUpdateScheduling, apiResponse.schedulingValidated.chart.food, apiResponse.schedulingValidated.table.food);
}
function updateSchedulingValidatedToMS() {
	if (apiResponse.schedulingValidated && apiResponse.schedulingValidated.chart && apiResponse.schedulingValidated.table)
		updateSchedulingValidated(apiResponse.lastUpdateScheduling, apiResponse.schedulingValidated.chart.ms, apiResponse.schedulingValidated.table.ms);
}
function updateSchedulingValidatedToPS() {
	if (apiResponse.schedulingValidated && apiResponse.schedulingValidated.chart && apiResponse.schedulingValidated.table)
		updateSchedulingValidated(apiResponse.lastUpdateScheduling, apiResponse.schedulingValidated.chart.ps, apiResponse.schedulingValidated.table.ps);
}
function updateSchedulingAuditorsToFood() {
	if (apiResponse.schedulingAuditorsUtilisation && apiResponse.schedulingAuditorsUtilisation.chart && apiResponse.schedulingAuditorsUtilisation.table)
		updateSchedulingAuditors(apiResponse.lastUpdateSchedulingAuditorsUtilisation, apiResponse.schedulingAuditorsUtilisation.chart.food, apiResponse.schedulingAuditorsUtilisation.table.food);
}
function updateSchedulingAuditorsToMS() {
	if (apiResponse.schedulingAuditorsUtilisation && apiResponse.schedulingAuditorsUtilisation.chart && apiResponse.schedulingAuditorsUtilisation.table)
		updateSchedulingAuditors(apiResponse.lastUpdateSchedulingAuditorsUtilisation, apiResponse.schedulingAuditorsUtilisation.chart.ms, apiResponse.schedulingAuditorsUtilisation.table.ms);
}
function updateSchedulingAuditorsToMSPlusFood() {
	if (apiResponse.schedulingAuditorsUtilisation && apiResponse.schedulingAuditorsUtilisation.chart && apiResponse.schedulingAuditorsUtilisation.table)
		updateSchedulingAuditors(apiResponse.lastUpdateSchedulingAuditorsUtilisation, apiResponse.schedulingAuditorsUtilisation.chart.ms_plus_food, apiResponse.schedulingAuditorsUtilisation.table.ms_plus_food);
}

function updatePRCRejections(last_updated, table_data_array) {
	// Check Visisbility
	if (table_data_array == null)  {
		document.getElementById('prc_container').style.display="none";
		return;
	}
	document.getElementById('prc_container').style.display="inline";
	
	// Headers
	document.getElementById('prc_auditor_mentoring_table_header').innerHTML  = 'Rejections by Auditor / Period as  ' + formatDatefromJavaCalendar(last_updated);
	
	var table_data = new google.visualization.arrayToDataTable(table_data_array);
	var table = new google.visualization.Table(document.getElementById('prc_auditor_mentoring_table'));
	
	table.draw(table_data, prc_rejections_table_options);
}

function updateAdminPhoneMetrics(last_updated, chart_data_array, table_data_array) {
	// Check Visisbility
	if ((chart_data_array == null) || (table_data_array == null) ) {
		document.getElementById('admin_container').style.display="none";
		return;
	}
	document.getElementById('admin_container').style.display="inline";
	
	// Headers
	document.getElementById('admin_phone_header').innerHTML  = 'TIS Phone calls - updated as ' + formatDatefromJavaCalendar(last_updated);
	
	// Chart
	var chart_data = new google.visualization.arrayToDataTable(chart_data_array);
	decimal_formatter.format(chart_data,3);
	var chart = new google.visualization.ColumnChart(document.getElementById('admin_phone_chart'));
	chart.draw(chart_data, phone_chart_options);
     
	var table_data = new google.visualization.arrayToDataTable(table_data_array);
	var table = new google.visualization.Table(document.getElementById('admin_phone_table'));
	
	table_data.setProperty(0,0,'style', 'color: #c2c2c2; background-color: #3366cc;');
	table_data.setProperty(1,0,'style', 'color: #e3e3e3; background-color: #dc3912;');
	table_data.setProperty(2,0,'style', 'color: #1f1f1f; background-color: #ff9900;');
	table_data.setProperty(3,0,'style', 'color: #1f1f1f; background-color: #FF3333;');
	
	table.draw(table_data, phone_table_options);
}

function updateSalesPhoneMetrics(last_updated, chart_data_array, table_data_array) {
	// Check Visisbility
	if ((chart_data_array == null) || (table_data_array == null) ) {
		document.getElementById('sales_container').style.display="none";
		return;
	}
	document.getElementById('sales_container').style.display="inline";
	
	// Headers
	document.getElementById('sales_phone_header').innerHTML  = 'TIS Phone calls - updated as ' + formatDatefromJavaCalendar(last_updated);
	
	// Chart
	var chart_data = new google.visualization.arrayToDataTable(chart_data_array);
	decimal_formatter.format(chart_data,3);
	var chart = new google.visualization.ColumnChart(document.getElementById('sales_phone_chart'));
	chart.draw(chart_data, phone_chart_options);
     
	var table_data = new google.visualization.arrayToDataTable(table_data_array);
	var table = new google.visualization.Table(document.getElementById('sales_phone_table'));
	
	table_data.setProperty(0,0,'style', 'color: #c2c2c2; background-color: #3366cc;');
	table_data.setProperty(1,0,'style', 'color: #e3e3e3; background-color: #dc3912;');
	table_data.setProperty(2,0,'style', 'color: #1f1f1f; background-color: #ff9900;');
	table_data.setProperty(3,0,'style', 'color: #1f1f1f; background-color: #FF3333;');
	
	table.draw(table_data, phone_table_options);
}

function updateOppProcessingDays(last_updated, chart_data_array, table_data_array) {
	// Check Visisbility
	if ((chart_data_array == null) || (table_data_array == null) ) {
		document.getElementById('new_business_container').style.display="none";
		return;
	}
	document.getElementById('new_business_container').style.display="inline";
	
	// Headers
	document.getElementById('newBusiness_processing_header').innerHTML  = 'Opportunity Processing as ' + formatDatefromJavaCalendar(last_updated);
	
	// Chart
	var chart_data = new google.visualization.arrayToDataTable(chart_data_array);
	percentage_formatter.format(chart_data,5);
	
	var chart_view = new google.visualization.DataView(chart_data);
	//chart_view.hideColumns(1,5);
	chart_view.setColumns([0,1,2,3,4,5]);
	//var chart_data = new google.visualization.arrayToDataTable(chart_data_array);
	
	var chart = new google.visualization.ColumnChart(document.getElementById('newBusiness_processing_chart'));
	chart.draw(chart_view, new_business_opp_chart_options);
     
	// Table
	for (var i = 1; i < table_data_array[5].length; i++) {
		table_data_array[5][i] = decimal_formatter.formatValue(table_data_array[5][i]);
		table_data_array[6][i] = decimal_formatter.formatValue(table_data_array[6][i]);
	}
	var table_data = new google.visualization.arrayToDataTable(table_data_array);
	var table = new google.visualization.Table(document.getElementById('newBusiness_processing_table'));
	//'#339933', '#3366cc', '#ff9900', '#dc3912', '#990099'
	table_data.setProperty(0,0,'style', 'color: #c2c2c2; background-color: #339933;');
	table_data.setProperty(1,0,'style', 'color: #e3e3e3; background-color: #3366cc;');
	table_data.setProperty(2,0,'style', 'color: #1f1f1f; background-color: #ff9900;');
	table_data.setProperty(3,0,'style', 'color: #e3e3e3; background-color: #dc3912;');
	table_data.setProperty(4,0,'style', 'color: #e3e3e3; background-color: #990099;');

	table.draw(table_data, new_business_opp_table_options);
}

function updateSchedulingValidated(last_updated, chart_data_array, table_data_array) {
	// Check Visisbility
	if ((chart_data_array == null) || (table_data_array == null) ) {
		document.getElementById('scheduling_container').style.display="none";
		return;
	}
	document.getElementById('scheduling_container').style.display="inline";
	
	// Headers
	document.getElementById('scheduling_validated_header').innerHTML  = 'Site Certification Data Validation as ' + formatDatefromJavaCalendar(last_updated);
	
	// Chart
	var chart_data = new google.visualization.arrayToDataTable(chart_data_array);
	percentage_formatter.format(chart_data,1);
	percentage_formatter.format(chart_data,2);
	var chart = new google.visualization.ColumnChart(document.getElementById('scheduling_validated_chart'));
	chart.draw(chart_data, scheduling_validated_chart_options);
     
	// Table
	var table_data = new google.visualization.arrayToDataTable(table_data_array);
	var table = new google.visualization.Table(document.getElementById('scheduling_validated_table'));

	table_data.setProperty(0,0,'style', 'color: #000000; background-color: #33FF99;');
	table_data.setProperty(1,0,'style', 'color: #000000; background-color: #33FFFF;');
	
	table.draw(table_data, scheduling_validated_table_options);
}
function updateSchedulingAuditors(last_updated, chart_data_array, table_data_array) {
	// Check Visisbility
	if ((chart_data_array == null) || (table_data_array == null) ) {
		document.getElementById('scheduling_container').style.display="none";
		return;
	}
	document.getElementById('scheduling_container').style.display="inline";
	
	// Headers
	document.getElementById('scheduling_auditors_header').innerHTML  = 'Auditors vs Contractors Utilisation as ' + formatDatefromJavaCalendar(last_updated);
	
	// Chart
	var chart_data = new google.visualization.arrayToDataTable(chart_data_array);
	percentage_formatter.format(chart_data,1);
	percentage_formatter.format(chart_data,2);
	percentage_formatter.format(chart_data,3);
	var chart = new google.visualization.ColumnChart(document.getElementById('scheduling_auditors_chart'));
	chart.draw(chart_data, scheduling_auditors_chart_options);
     
	// Table
	var table_data = new google.visualization.arrayToDataTable(table_data_array);
	var table = new google.visualization.Table(document.getElementById('scheduling_auditors_table'));

	table_data.setProperty(0,0,'style', 'color: #000000; background-color: #33FF99;');
	table_data.setProperty(1,0,'style', 'color: #000000; background-color: #33FFFF;');
	table_data.setProperty(2,0,'style', 'color: #FFFFFF; background-color: #000066;');
	
	table.draw(table_data, scheduling_auditors_table_options);
}
function updateSchedulingConfirmedRatios(last_updated, chart_data_array, table_data_array) {
	// Check Visisbility
	if ((chart_data_array == null) || (table_data_array == null) ) {
		document.getElementById('scheduling_container').style.display="none";
		return;
	}
	document.getElementById('scheduling_container').style.display="inline";
	
	// Headers
	document.getElementById('scheduling_audit_chart_header').innerHTML  = 'Confirmed, Scheduled & Open Ratios as ' + formatDatefromJavaCalendar(last_updated);
	
	// Audit Days Chart
	var chart_data = new google.visualization.arrayToDataTable(chart_data_array);
	var chart = new google.visualization.ColumnChart(document.getElementById('scheduling_audit_chart'));
	chart.draw(chart_data, scheduling_audit_chart_options);
     
	// Audit Days Table
	var table_data = new google.visualization.arrayToDataTable(table_data_array);
	var table = new google.visualization.Table(document.getElementById('scheduling_audit_table'));

	table_data.setProperty(0,0,'style', 'color: #ffffff; background-color: #000066;');
	table_data.setProperty(1,0,'style', 'color: #000000; background-color: #33FF33;');
	table_data.setProperty(2,0,'style', 'color: #000000; background-color: #33FF99;');
	table_data.setProperty(3,0,'style', 'color: #000000; background-color: #33FFFF;');
	
	table.draw(table_data, scheduling_audit_table_options);
}

function updateSchedulingTargetRatios(last_updated, chart_data_array, table_data_array) {
	// Check Visisbility
	if ((chart_data_array == null) || (table_data_array == null) ) {
		document.getElementById('scheduling_container').style.display="none";
		return;
	}
	document.getElementById('scheduling_container').style.display="inline";
	
	// Headers
	document.getElementById('scheduling_target_chart_header').innerHTML  = 'Work Item Scheduled vs Target as ' + formatDatefromJavaCalendar(last_updated);
	
	// Chart
	var chart_data = new google.visualization.arrayToDataTable(chart_data_array);
	var chart = new google.visualization.ColumnChart(document.getElementById('scheduling_target_chart'));
	chart.draw(chart_data, scheduling_target_chart_options);
     
	// Table
	var table_data = new google.visualization.arrayToDataTable(table_data_array);
	var table = new google.visualization.Table(document.getElementById('scheduling_target_table'));

	table_data.setProperty(0,0,'style', 'color: #ffffff; background-color: #33CC00;');
	table_data.setProperty(1,0,'style', 'color: #000000; background-color: #33FF33;');
	table_data.setProperty(2,0,'style', 'color: #000000; background-color: #33FF99;');
	table_data.setProperty(3,0,'style', 'color: #000000; background-color: #33FFFF;');
	
	table.draw(table_data, scheduling_target_table_options);
}

function updateAdminARG(last_updated, chart_data_array, table_data_array) {
	// Check Visisbility
	if ((chart_data_array == null) || (table_data_array == null) ) {
		document.getElementById('admin_container').style.display="none";
		return;
	}
	document.getElementById('admin_container').style.display="inline";
	
	// Headers
	document.getElementById('admin_arg_header').innerHTML  = 'ARG as ' + formatDatefromJavaCalendar(last_updated);
	
	// ARG Days Chart
	var chart_data = new google.visualization.arrayToDataTable(chart_data_array);
	decimal_formatter.format(chart_data,3);
	var chart = new google.visualization.ColumnChart(document.getElementById('admin_arg_chart'));
	chart.draw(chart_data, arg_chart_options);
	
	// ARG Days Table
	for (var i = 1; i < table_data_array[3].length; i++) {
		table_data_array[3][i] = decimal_formatter.formatValue(table_data_array[3][i]);
	}
	var table_data = new google.visualization.arrayToDataTable(table_data_array);
	var table = new google.visualization.Table(document.getElementById('admin_arg_table'));
	table_data.setProperty(0,0,'style', 'color: #c2c2c2; background-color: #3366cc;');
	table_data.setProperty(1,0,'style', 'color: #e3e3e3; background-color: #dc3912;');
	table_data.setProperty(2,0,'style', 'color: #1f1f1f; background-color: #ff9900;');
	
	table.draw(table_data, arg_table_options);
}

function updatePRCARGToFood() {
	if (apiResponse.prcArgProcessing && apiResponse.prcArgProcessing.chart && apiResponse.prcArgProcessing.table)
		updatePRCARG(apiResponse.lastUpdatePrc, apiResponse.prcArgProcessing.chart.food, apiResponse.prcArgProcessing.table.food);
}
function updatePRCARGToMS() {
	if (apiResponse.prcArgProcessing && apiResponse.prcArgProcessing.chart && apiResponse.prcArgProcessing.table)
		updatePRCARG(apiResponse.lastUpdatePrc, apiResponse.prcArgProcessing.chart.ms, apiResponse.prcArgProcessing.table.ms);
}
function updatePRCARGToPS() {
	if (apiResponse.prcArgProcessing && apiResponse.prcArgProcessing.chart && apiResponse.prcArgProcessing.table)
		updatePRCARG(apiResponse.lastUpdatePrc, apiResponse.prcArgProcessing.chart.ps, apiResponse.prcArgProcessing.table.ps);
}
function updatePRCARG(last_updated, chart_data_array, table_data_array) {
	// Check Visisbility
	if ((chart_data_array == null) || (table_data_array == null) ) {
		document.getElementById('prc_container').style.display="none";
		return;
	}
	document.getElementById('prc_container').style.display="inline";
	
	// Headers
	document.getElementById('prc_arg_header').innerHTML  = 'ARG as ' + formatDatefromJavaCalendar(last_updated);
	
	// ARG Days Chart
	var chart_data = new google.visualization.arrayToDataTable(chart_data_array);
	decimal_formatter.format(chart_data,3);
	var chart = new google.visualization.ColumnChart(document.getElementById('prc_arg_chart'));
	chart.draw(chart_data, arg_chart_options);
	
	// ARG Days Table
	for (var i = 1; i < table_data_array[3].length; i++) {
		table_data_array[3][i] = decimal_formatter.formatValue(table_data_array[3][i]);
	}
	var table_data = new google.visualization.arrayToDataTable(table_data_array);
	var table = new google.visualization.Table(document.getElementById('prc_arg_table'));
	table_data.setProperty(0,0,'style', 'color: #c2c2c2; background-color: #3366cc;');
	table_data.setProperty(1,0,'style', 'color: #e3e3e3; background-color: #dc3912;');
	table_data.setProperty(2,0,'style', 'color: #1f1f1f; background-color: #ff9900;');
	
	table.draw(table_data, arg_table_options);
}

function updateAuditorsARG(last_updated, chart_data_array, table_data_array) {
	// Check Visisbility
	if ((chart_data_array == null) || (table_data_array == null) ) {
		document.getElementById('auditors_container').style.display="none";
		return;
	}
	document.getElementById('auditors_container').style.display="inline";
	
	// Headers
	document.getElementById('auditors_arg_header').innerHTML  = 'ARG Submission as ' + formatDatefromJavaCalendar(last_updated);
	
	// ARG Days Chart
	var chart_data = new google.visualization.arrayToDataTable(chart_data_array);
	decimal_formatter.format(chart_data,3);
	var chart = new google.visualization.ColumnChart(document.getElementById('auditors_arg_chart'));
	chart.draw(chart_data, arg_chart_options);
	
	// ARG Days Table
	for (var i = 1; i < table_data_array[3].length; i++) {
		table_data_array[3][i] = decimal_formatter.formatValue(table_data_array[3][i]);
	}
	var table_data = new google.visualization.arrayToDataTable(table_data_array);
	var table = new google.visualization.Table(document.getElementById('auditors_arg_table'));
	table_data.setProperty(0,0,'style', 'color: #c2c2c2; background-color: #3366cc;');
	table_data.setProperty(1,0,'style', 'color: #e3e3e3; background-color: #dc3912;');
	table_data.setProperty(2,0,'style', 'color: #1f1f1f; background-color: #ff9900;');
	
	table.draw(table_data, arg_table_options);
}

function formatAsCurrency(x) {
	return '$'+ Math.round(x).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

function formatDatefromJavaCalendar(date) {
	return date.dayOfMonth + '/' + (date.month+1) + '/' + date.year;
}
  