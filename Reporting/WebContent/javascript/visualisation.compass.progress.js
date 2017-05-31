// Data
var auditDaysResponse;
var activeSitesResponse;
var activeSiteCertsResponse;
var loginHistoryResponse;
var loadingCount = 0;

// Data Formatters
var int_formatter;
var currency_formatter;

var gauge_options = {
	      width: 250, height: 250,
	      redFrom:0, redTo:60,
	      yellowFrom:60, yellowTo:80,
	      greenFrom:80, greenTo:100,
	      minorTicks: 5
	    };

var auditdays_chart_options = {
		width: 800,
		height: 300,
		chartArea:{left:0,top:0, bottom:0, right:0, width:"80%",height:"80%"},
		legend: { position: 'right', alignment: 'center'},
		bar: { groupWidth: '75%' },
		colors: ['#33FF33', '#33FF99', '#33FFFF', '#000066', '#CC0066'],
		isStacked: true,
		series: {3: {type: "line"}, 4: {type: "line"} }
	};


var table_options = {
	showRowNumber: false, 
	sort: 'disable',
	width:'100%',
	height:'100%'
};
var forPrinting = false;
// Functions
function refreshVisualisationsForPrinting() {
	forPrinting = true;
	$.when( refreshVisualisations() ).done( function() {		
		$('.to_be_expanded').collapsible('expand');
		window.status = "readyForPrinting";
	});
}

function refreshVisualisations() {
	if (forPrinting) {
		auditdays_chart_options.width = 900;
		table_options.width = 900;
	} else {
		auditdays_chart_options.width = window.innerWidth*0.95;
		table_options.width = window.innerWidth*0.95;
	}
	$.mobile.loading('show', {
		text: 'Loading',
		textVisible: true,
		theme: 'a',
		html: ""
	});
	loadingCount++;
	HTTPGetAsync("dailyStats?monthsToReport=12&region="+$("#region-select option:selected").val(), function(jsonResponse) {
		auditDaysResponse = jsonResponse;
		updateAuditDays(auditDaysResponse.bothAuditDaysChartData,auditDaysResponse.bothAuditDaysTableData, auditDaysResponse.bothAuditDaysChangesDailyTableData, auditDaysResponse.bothAuditDaysChangesWeeklyTableData, auditDaysResponse.bothAuditDaysChangesMonthlyTableData, auditdays_chart_options, table_options, 'auditdays_chart_header', 'auditdays_chart', 'auditdays_table_header', 'auditdays_table', 'auditdays_table_changes_daily_header', 'auditdays_table_changes_daily', 'auditdays_table_changes_weekly_header', 'auditdays_table_changes_weekly', 'auditdays_table_changes_monthly_header', 'auditdays_table_changes_monthly');
		loadingCount--;
		if (loadingCount==0)
			$.mobile.loading('hide');
	});
	
	loadingCount++;
	HTTPGetAsync("compassRolloutProgress?function=activeSites&region="+$("#region-select option:selected").val(), function(jsonResponse) {
		activeSitesResponse = jsonResponse;
		updateActiveSites();
		loadingCount--;
		if (loadingCount==0)
			$.mobile.loading('hide');
	});
	
	loadingCount++;
	HTTPGetAsync("compassRolloutProgress?function=activeSiteCerts&region="+$("#region-select option:selected").val(), function(jsonResponse) {
		activeSiteCertsResponse = jsonResponse;
		updateActiveSitesCerts();
		loadingCount--;
		if (loadingCount==0)
			$.mobile.loading('hide');
	});
	/*
	loadingCount++;
	HTTPGetAsync("compassRolloutProgress?function=loginHistory&region="+$("#region-select option:selected").val(), function(jsonResponse) {
		loginHistoryResponse = jsonResponse;
		updateLoginHistory();
		loadingCount--;
		if (loadingCount==0)
			$.mobile.loading('hide');
	});
	*/
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
	
}

function updateVisualisations() {
	updateAuditDays(auditDaysResponse.bothAuditDaysChartData,auditDaysResponse.bothAuditDaysTableData, auditDaysResponse.bothAuditDaysChangesDailyTableData, auditDaysResponse.bothAuditDaysChangesWeeklyTableData, auditDaysResponse.bothAuditDaysChangesMonthlyTableData, auditdays_chart_options, table_options, 'auditdays_chart_header', 'auditdays_chart', 'auditdays_table_header', 'auditdays_table', 'auditdays_table_changes_daily_header', 'auditdays_table_changes_daily', 'auditdays_table_changes_weekly_header', 'auditdays_table_changes_weekly', 'auditdays_table_changes_monthly_header', 'auditdays_table_changes_monthly');
	updateActiveSites();
	updateActiveSitesCerts();
	updateLoginHistory();
}

function updateActiveSites() {
	// Check Visisbility
	if ((activeSitesResponse == null) || (activeSitesResponse.table == null)) {
		document.getElementById('active_sites_container').style.display="none";
		return;
	}
	document.getElementById('active_sites_container').style.display="inline";
	
	// Headers
	document.getElementById('active_sites_table_header').firstChild.firstChild.data  = 'Active Sites and Site Certifications Summary (as ' + formatDatefromJavaCalendar(activeSitesResponse.lastUpdateDate,0) + ' UTC)';
	
	// Chart
	var totalActiveSites = 0;
	var totalActiveSitesNoCert = 0;
	for (var int = 1; int < activeSitesResponse.table.length; int++) {
		totalActiveSites += activeSitesResponse.table[int][1];
		totalActiveSitesNoCert += activeSitesResponse.table[int][2];
	}

	var data = google.visualization.arrayToDataTable([
      ['Label', 'Value'],
      ['% Certs', Math.round((1-totalActiveSitesNoCert/totalActiveSites)*100)],
    ]);

    var chart = new google.visualization.Gauge(document.getElementById('active_sites_chart'));
    chart.draw(data, gauge_options);
    
	// Table
	var table_data = new google.visualization.arrayToDataTable(activeSitesResponse.table);
	var table = new google.visualization.Table(document.getElementById('active_sites_table'));
	
	table.draw(table_data, table_options );	
}

function updateActiveSitesCerts() {
	// Check Visisbility
	if ((activeSiteCertsResponse == null) || (activeSiteCertsResponse.table == null)) {
		document.getElementById('active_site_certs_container').style.display="none";
		return;
	}
	document.getElementById('active_site_certs_container').style.display="inline";
	
	// Headers
	document.getElementById('active_site_certs_table_header').firstChild.firstChild.data  = 'Active Site Certifications Summary (as ' + formatDatefromJavaCalendar(activeSiteCertsResponse.lastUpdateDate,0) + ' UTC)';

	// Chart
	var totalActiveSites = 0;
	var totalActiveSitesNotValidated = 0;
	for (var int = 1; int < activeSiteCertsResponse.table.length; int++) {
		totalActiveSites += activeSiteCertsResponse.table[int][1];
		totalActiveSitesNotValidated += activeSiteCertsResponse.table[int][2];
	}

	var data = google.visualization.arrayToDataTable([
      ['Label', 'Value'],
      ['% Validated', Math.round((1-totalActiveSitesNotValidated/totalActiveSites)*100)],
    ]);

    var chart = new google.visualization.Gauge(document.getElementById('active_site_certs_chart'));
    chart.draw(data, gauge_options);
    
	// Table
	var table_data = new google.visualization.arrayToDataTable(activeSiteCertsResponse.table);
	var table = new google.visualization.Table(document.getElementById('active_site_certs_table'));
	
	table.draw(table_data, table_options );
}

function updateLoginHistory() {
	// Check Visisbility
	if ((loginHistoryResponse == null) || (loginHistoryResponse.table == null)) {
		document.getElementById('login_history_container').style.display="none";
		return;
	}
	document.getElementById('login_history_container').style.display="inline";
	
	// Headers
	document.getElementById('login_history_table_header').firstChild.firstChild.data = 'User Login History (as ' + formatDatefromJavaCalendar(loginHistoryResponse.lastUpdateDate,0) + ' UTC)';

	// Audit Days Table
	var table_data = new google.visualization.arrayToDataTable(loginHistoryResponse.table);
	var table = new google.visualization.Table(document.getElementById('login_history_table'));
	
	table.draw(table_data, table_options );
}

function updateAuditDays(chart_data_array, table_data_array, daily_change_data_array, weekly_change_data_array, monthly_change_data_array, chart_options, table_options) {
	// Check Visisbility
	if ((chart_data_array == null) || (table_data_array == null) || (daily_change_data_array == null) || (weekly_change_data_array == null)) {
		document.getElementById('audit_days_container').style.display="none";
		return;
	}
	document.getElementById('audit_days_container').style.display="inline";
	
	// Headers
	document.getElementById('auditdays_chart_header').firstChild.firstChild.data  = 'Audit Days (as ' + formatDatefromJavaCalendar(auditDaysResponse.lastUpdateReportDate, -11) + ' UTC)';
	document.getElementById('auditdays_table_changes_daily_header').innerHTML  = 'Daily changes (from ' + formatDatefromJavaCalendar(auditDaysResponse.yesterdayReportDate, -11) + ' to ' + formatDatefromJavaCalendar(auditDaysResponse.lastUpdateReportDate, -11) + ' UTC)';
	document.getElementById('auditdays_table_changes_weekly_header').innerHTML  = 'Weekly changes (from ' + formatDatefromJavaCalendar(auditDaysResponse.weekStartReportDate, -11) + ' to ' + formatDatefromJavaCalendar(auditDaysResponse.lastUpdateReportDate, -11) + ' UTC)';
	document.getElementById('auditdays_table_changes_monthly_header').innerHTML  = 'Monthly changes (from ' + formatDatefromJavaCalendar(auditDaysResponse.monthStartReportDate, -11) + ' to ' + formatDatefromJavaCalendar(auditDaysResponse.lastUpdateReportDate, -11) + ' UTC)';

	// Audit Days Chart
	var chart_data = new google.visualization.arrayToDataTable(chart_data_array);
	var chart = new google.visualization.ColumnChart(document.getElementById('auditdays_chart'));
	
	chart.draw(chart_data, chart_options);
     
	// Audit Days Table
	var table_data = new google.visualization.DataTable();
	var table_changes_daily_data = new google.visualization.DataTable();
	var table_changes_week_data = new google.visualization.DataTable();
	var table_changes_month_data = new google.visualization.DataTable();
	for (var int = 0; int < table_data_array[0].length; int++) {
		var type = (int==0)?'string':'number';
		table_data.addColumn(type, table_data_array[0][int]);
		table_changes_daily_data.addColumn(type, table_data_array[0][int]);
		table_changes_week_data.addColumn(type, table_data_array[0][int]);
		table_changes_month_data.addColumn(type, table_data_array[0][int]);
	}
	var rows = [];
	rows.push(table_data_array[3]);
	rows.push(table_data_array[2]);
	rows.push(table_data_array[1]);
	rows.push(table_data_array[6]);
	rows.push(table_data_array[4]);
	table_data.addRows(rows);
	
	rows = [];
	rows.push(daily_change_data_array[3]);
	rows.push(daily_change_data_array[2]);
	rows.push(daily_change_data_array[1]);
	table_changes_daily_data.addRows(rows);
	
	rows = [];
	rows.push(weekly_change_data_array[3]);
	rows.push(weekly_change_data_array[2]);
	rows.push(weekly_change_data_array[1]);
	table_changes_week_data.addRows(rows);
	
	rows = [];
	rows.push(monthly_change_data_array[3]);
	rows.push(monthly_change_data_array[2]);
	rows.push(monthly_change_data_array[1]);
	table_changes_month_data.addRows(rows);
	
	//var table_data = new google.visualization.arrayToDataTable(table_data_array);
	var table = new google.visualization.Table(document.getElementById('auditdays_table'));
	//table_options.width = window.innerWidth*0.95;
	table.draw(table_data, table_options);
     
	// Yesterday changes Table
	//var table_changes_daily_data = new google.visualization.arrayToDataTable(daily_change_data_array);
	var tableDailyChanges = new google.visualization.Table(document.getElementById('auditdays_table_changes_daily'));
	tableDailyChanges.draw(table_changes_daily_data, table_options);

	// Week start changes Table
	//var table_changes_week_data = new google.visualization.arrayToDataTable(weekly_change_data_array);
	var tableWeeklyChanges = new google.visualization.Table(document.getElementById('auditdays_table_changes_weekly'));
	tableWeeklyChanges.draw(table_changes_week_data, table_options);
	
	// Month start changes Table
	//var table_changes_month_data = new google.visualization.arrayToDataTable(monthly_change_data_array);
	var tableMonthlyChanges = new google.visualization.Table(document.getElementById('auditdays_table_changes_monthly'));
	tableMonthlyChanges.draw(table_changes_month_data, table_options);
}
 
function formatAsCurrency(x) {
	return '$'+ Math.round(x).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

function formatDatefromJavaCalendar(date, spread) {
	var d = new Date(date.year, date.month, date.dayOfMonth, date.hourOfDay, date.minute, date.second, 0);
	d.setHours(d.getHours()+spread);
	return d.getDate() + '/' + (d.getMonth()<9?'0'+(d.getMonth()+1):(d.getMonth()+1)) + '/' + d.getFullYear() + ' - ' + (d.getHours()<10?'0'+d.getHours():d.getHours()) + ':' + (d.getMinutes()<10?'0'+d.getMinutes():d.getMinutes());
}

function HTTPGetAsync(url, onCompleteCb)
{
	var xmlhttp;
	if (window.XMLHttpRequest) {
		// code for IE7+, Firefox, Chrome, Opera, Safari
		xmlhttp = new XMLHttpRequest();
	} else {
		// code for IE6, IE5
		xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
	}
	
	xmlhttp.open("GET", url, true);
	xmlhttp.onreadystatechange = function() {
        if (xmlhttp.readyState == 4 && xmlhttp.status == 200) {
        	onCompleteCb(JSON.parse(xmlhttp.responseText));
        }
    };
	xmlhttp.send();
};