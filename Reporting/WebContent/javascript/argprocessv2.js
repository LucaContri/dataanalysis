// Data
var apiResponse;
var selectedNode = "ARG";

// Data Formatters
var double_formatter;

// Visualizations Options
var table_options = {
	showRowNumber : false,
	sort : 'enable',
	allowHtml : true,
	width : "100%"
};
var table_queues_options = {
	showRowNumber : false,
	sort : 'disable',
	allowHtml : true,
	width : 625
};

var perf_chart_options = {
	title : 'Performances',
	curveType : 'function',
	width : 625,
	legend : {
		position : 'bottom'
	},
	tooltip: { isHtml: true }
};

var summary_chart_options = {
		title : 'Overall Performances (Avg Days)',
		curveType : 'function',
		width : 1200,
		height: 600,
		legend : {
			position : 'top',
			maxLines: 5
		},
		tooltip: { isHtml: true },
		isStacked: true
	};

$(document)
		.ready(
				function() {
					// Autocomplete change
					$("#parameters_input")
							.tokenInput(
									"processParameters",
									{
										theme : "process",
										hintText : "Filter results by typing any revenue ownership, resource, standards, programs, pathway, ... "
									});

					// Filters Change Update
					$("#parameters_input").change(function() {
						updateProcessData();
					});

					// Init Formatter
					double_formatter = new google.visualization.NumberFormat({
						fractionDigits : 2
					});

					drawFlowChart();

					// Expand Sections
					// $('.to_be_expanded').collapsible('expand');

				});

function drawFlowChart() {
	document.getElementById('Performance_Button').style.display = "inline";
	document.getElementById('SLA_Button').style.display = "inline";
	var data = new google.visualization.DataTable();
	data.addColumn('string', 'Name');
	data.addColumn('string', 'Parent');
	data.addColumn('string', 'ToolTip');

	data.addRows([ [ {
		v : 'ARG',
		f : 'ARG Process'
	}, '', 'Whole process from Work Item finished to ARG comppleted' ], [ {
		v : 'AUDITORS',
		f : 'Auditors'
	}, 'ARG', 'From Work ITem finished to ARG Submitted' ], [ {
		v : 'PRC',
		f : 'PRC'
	}, 'ARG', 'From ARG Submitted to ARG Approved' ], [ {
		v : 'ADMIN',
		f : 'Admin'
	}, 'ARG', 'From ARG Approved to ARG Submitted' ] ]);

	var chart = new google.visualization.OrgChart(document.getElementById('process_flowchart_container'));
	chart.draw(data, {
		allowHtml : true,
		size: 'large'
	});
	chart.setSelection(0);
	google.visualization.events.addListener(chart, 'select', function() {
		switch (chart.getSelection()[0].row) {
		case 0:
			selectedNode = "ARG";
			break;
		case 1:
			selectedNode = "AUDITORS";
			break;
		case 2:
			selectedNode = "PRC";
			break;
		case 3:
			selectedNode = "ADMIN";
			break;
		default:
			break;
		}
		updateProcessData();
	});
}

function displayTab(tab) {
	var tab_id = tab.attr('data-tab');

	$('ul.tabs li').removeClass('current');
	$('.tab-content').removeClass('current');

	tab.addClass('current');
	$("#" + tab_id).addClass('current');
}

function updateProcessData() {
	
	var q = $("#parameters_input").val();
	if (q !="") {
		$.mobile.loading('show', {
			text: 'Loading',
			textVisible: true,
			theme: 'a',
			html: ""
		});
		if (window.XMLHttpRequest) {
			// code for IE7+, Firefox, Chrome, Opera, Safari
			xmlhttp = new XMLHttpRequest();
		} else {
			// code for IE6, IE5
			xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
		}
		
		var url = "argprocessdetailsv2?process=" + selectedNode + "&q=" + $("#parameters_input").val();
		xmlhttp.open("GET", url, true);
		xmlhttp.onreadystatechange = function() {
	        if (xmlhttp.readyState == 4 && xmlhttp.status == 200) {
	        	apiResponse = JSON.parse(xmlhttp.responseText);
	        	updateProcessSummary();
	        	updateProcessDetails();
	        	//if (apiResponse.errorMessage != null && apiResponse.errorMessage.length > 0) {
	    		//	document.getElementById('messages').innerHTML = apiResponse.errorMessage;
	    		//	document.getElementById("messages").style.visibility = "visible";
	    		//}
	        	$.mobile.loading('hide');
	        }
	    };
		xmlhttp.send();
	} else {
		if (apiResponse != null) {
			apiResponse.queues = null;
			apiResponse.performances = null;
			updateProcessSummary();
			updateProcessDetails();
		}
	}
	updateDisplay();
}

function updateDisplay() {
	if (selectedNode=="ARG") {
		document.getElementById('process_summary_queues').style.display = "none";
		document.getElementById('process_summary_performances').style.display = "none";
		document.getElementById('process_summary_sla').style.display = "none";
		if (document.getElementById('SLA_Button').className.indexOf('ui-btn-active')>-1 ) {
			document.getElementById('process_summary').style.display = "none";
			document.getElementById('process_summary_all_sla').style.display = "inline-block";
		} else {
			document.getElementById('process_summary').style.display = "inline-block";
			document.getElementById('process_summary_all_sla').style.display = "none";
		}
	} else {
		document.getElementById('process_summary').style.display = "none";
		document.getElementById('process_summary_all_sla').style.display = "none";
		if (document.getElementById('SLA_Button').className.indexOf('ui-btn-active')>-1 ) {
			document.getElementById('process_summary_sla').style.display = "inline-block";
			document.getElementById('process_summary_performances').style.display = "none";
		} else {
			document.getElementById('process_summary_sla').style.display = "none";
			document.getElementById('process_summary_performances').style.display = "inline-block";
		}
	}
}

function updateProcessSummary() {
	// Check Visisbility
	if (((apiResponse.queues == null) || (apiResponse.queues.length == 0)) && ((apiResponse.performances == null) || apiResponse.performances.length == 0)) {
		document.getElementById('process_summary_container').style.display = "none";
		$('#process_summary_header')[0].childNodes[0].childNodes[0].data = 'Process Summary';
		return;
	}
	document.getElementById('process_summary_container').style.display = "inline-block";
	$('#process_summary_header')[0].childNodes[0].childNodes[0].data = 'Process Summary';// as ' + formatDatefromJavaCalendar(apiResponse.lastUpdated);
	
	// Main Process Summary
	if (selectedNode=="ARG") {
		if ((apiResponse.performances != null) && (apiResponse.performances.length > 0)) {
			var chart_data = new google.visualization.DataTable();
			chart_data.addColumn('string', apiResponse.performances[0].groupType);
			apiResponse.performances.map(function(perf) {
				if (perf.reportSlaOnly == false) {
					chart_data.addColumn('number', perf.name);
					chart_data.addColumn({type:'string', role:'tooltip', p: {html:true}});
				} else {
					var all_sla_chart_data = new google.visualization.DataTable();
					all_sla_chart_data.addColumn('string', apiResponse.performances[0].groupType);
					all_sla_chart_data.addColumn('number', "Within SLA");
					all_sla_chart_data.addColumn({type:'string', role:'tooltip', p: {html:true}});
					all_sla_chart_data.addColumn({type:'string', role: 'annotation'  });
					all_sla_chart_data.addColumn('number', "Over SLA");
					all_sla_chart_data.addColumn({type:'string', role:'tooltip', p: {html:true}});
					all_sla_chart_data.addColumn({type:'string', role: 'annotation'  });
					
					var all_rows = [];
					for (var i = 0; i < perf.group.length; i++) {
						var all_row = [ perf.group[i] ];
						all_row.push(Math.round(perf.withinSLA[i]*100)/100);
						all_row.push('<p style="text-align:left"><i>' + perf.name + ' - ' + perf.group[i] + '</i></br>'
									+'<b>Within SLA:</b> '+ Math.round(perf.withinSLA[i]*100)/100 + '</br>' 
									+'<b>Over SLA:</b> '+ Math.round((perf.quantity[i]-perf.withinSLA[i])*100)/100 + '</br>' 
									+'<b>Quantity:</b> ' + Math.round(perf.quantity[i]*100)/100 + '</p>');
						all_row.push(''+Math.round(perf.withinSLA[i]/perf.quantity[i]*10000)/100 +'%');
						all_row.push(Math.round((perf.quantity[i]-perf.withinSLA[i])*100)/100);
						all_row.push('<p style="text-align:left"><i>' + perf.name + ' - ' + perf.group[i] + '</i></br>'
								+'<b>Within SLA:</b> '+ Math.round(perf.withinSLA[i]*100)/100 + '</br>' 
								+'<b>Over SLA:</b> '+ Math.round((perf.quantity[i]-perf.withinSLA[i])*100)/100 + '</br>' 
								+'<b>Quantity:</b> ' + Math.round(perf.quantity[i]*100)/100 + '</p>');
						all_row.push(''+Math.round((1-perf.withinSLA[i]/perf.quantity[i])*10000)/100+'%');
						
						all_rows.push(all_row);
					}
					all_sla_chart_data.addRows(all_rows);
					var all_sla_chart = new google.visualization.ColumnChart(document.getElementById("process_summary_all_sla"));

					all_sla_chart.draw(all_sla_chart_data, {
														title : perf.name + ' within ' + perf.SLA + ' ' + perf.unit,
														width : 1200,
														legend : {
															position : 'bottom'
														},
														tooltip: { isHtml: true },
														isStacked: true
													});
				}
			});
			var rows = [];
			for (var i = 0; i < apiResponse.performances[0].group.length; i++) {
				var row = [ apiResponse.performances[0].group[i] ];
				apiResponse.performances.map(function(perf) {
					if (perf.reportSlaOnly == false) {
						row.push(perf.avg[i]);
						row.push('<p style="text-align:left"><i>' + perf.name + ' - ' + perf.group[i] + '</i></br>'
								+'<b>Average:</b> '+ Math.round(perf.avg[i]*100)/100 + '</br>' 
								+'<b>Quantity:</b> ' + Math.round(perf.quantity[i]*100)/100 + '</br>'
								+'<b>Std Dev:</b> ' + Math.round(perf.stdDev[i]*100)/100 + '</p>');
					}
				});
				rows.push(row);
			}
			chart_data.addRows(rows);
			var chart = new google.visualization.ColumnChart(document.getElementById("process_summary"));

			chart.draw(chart_data, summary_chart_options);
		} else {
			document.getElementById('process_summary').style.display = "none";
			document.getElementById('process_summary_all_sla').style.display = "none";
		}
		return;
	}
	
	// Cycle through all queues
	if ((apiResponse.queues != null) && (apiResponse.queues.length > 0)) {
		document.getElementById('process_summary_queues').style.display = "inline-block";
		
		var table_data = new google.visualization.DataTable();
		table_data.addColumn('string', 'Queue');
		table_data.addColumn('number', 'Qty');
		table_data.addColumn('string', 'Qty Unit');
		table_data.addColumn('number', 'Aging - Average');
		table_data.addColumn('number', 'Aging - Std Dev');
		table_data.addColumn('string', 'Metric Unit');
		var rows = [];
		apiResponse.queues.map(function(queue) {
			rows.push([ queue.name, queue.quantity, queue.quantityUnit,
					queue.agingAvg, queue.agingStdDev, queue.agingUnit ]);
		});
		table_data.addRows(rows);

		double_formatter.format(table_data, 3);
		double_formatter.format(table_data, 4);

		var table = new google.visualization.Table(document.getElementById("process_summary_queues"));
		table.draw(table_data, table_queues_options);
	} else {
		document.getElementById('process_summary_queues').style.display = "none";
	}

	
	// Cycle through all performances
	if ((apiResponse.performances != null) && (apiResponse.performances.length > 0)) {
		//document.getElementById('process_summary_performances').style.display = "inline-block";
		
		document.getElementById("process_summary_sla").innerHTML = '';
		document.getElementById("process_summary_performances").innerHTML = '';
		for (var j = 0; j < apiResponse.performances.length; j++) {
			var perf = apiResponse.performances[j];
			if(perf.withinSLA) {
				var innerDiv = document.createElement("div");
				document.getElementById("process_summary_sla").appendChild(innerDiv);
				var sla_chart_data = new google.visualization.DataTable();
				sla_chart_data.addColumn('string', apiResponse.performances[0].groupType);
				sla_chart_data.addColumn('number', "Within SLA");
				sla_chart_data.addColumn({type:'string', role:'tooltip', p: {html:true}});
				sla_chart_data.addColumn({type:'string', role: 'annotation'  });
				sla_chart_data.addColumn('number', "Over SLA");
				sla_chart_data.addColumn({type:'string', role:'tooltip', p: {html:true}});
				sla_chart_data.addColumn({type:'string', role: 'annotation'  });
				
				var rows = [];
				for (var i = 0; i < perf.group.length; i++) {
					var row = [ perf.group[i] ];
					row.push(Math.round(perf.withinSLA[i]*100)/100);
					row.push('<p style="text-align:left"><i>' + perf.name + ' - ' + perf.group[i] + '</i></br>'
								+'<b>Within SLA:</b> '+ Math.round(perf.withinSLA[i]*100)/100 + '</br>' 
								+'<b>Over SLA:</b> '+ Math.round((perf.quantity[i]-perf.withinSLA[i])*100)/100 + '</br>' 
								+'<b>Quantity:</b> ' + Math.round(perf.quantity[i]*100)/100 + '</p>');
					row.push(''+Math.round(perf.withinSLA[i]/perf.quantity[i]*10000)/100 +'%');
					
					row.push(Math.round((perf.quantity[i]-perf.withinSLA[i])*100)/100);
					row.push('<p style="text-align:left"><i>' + perf.name + ' - ' + perf.group[i] + '</i></br>'
							+'<b>Within SLA:</b> '+ Math.round(perf.withinSLA[i]*100)/100 + '</br>' 
							+'<b>Over SLA:</b> '+ Math.round((perf.quantity[i]-perf.withinSLA[i])*100)/100 + '</br>' 
							+'<b>Quantity:</b> ' + Math.round(perf.quantity[i]*100)/100 + '</p>');
					row.push(''+Math.round((1-perf.withinSLA[i]/perf.quantity[i])*10000)/100+'%');
					rows.push(row);
				}
				sla_chart_data.addRows(rows);
				//var sla_chart = new google.visualization.ColumnChart(document.getElementById("process_summary_sla"));
				var sla_chart = new google.visualization.ColumnChart(innerDiv);
				sla_chart.draw(sla_chart_data, {
													title : perf.name + ' within ' + perf.SLA + ' ' + perf.unit,
													width : 625,
													legend : {
														position : 'bottom'
													},
													tooltip: { isHtml: true },
													isStacked: true
												});
				//break;
			}
			if(perf.group) {
				var innerDiv2 = document.createElement("div");
				document.getElementById("process_summary_performances").appendChild(innerDiv2);
				var chart_data = new google.visualization.DataTable();
				chart_data.addColumn('string', perf.groupType);
				chart_data.addColumn('number', perf.name);
				chart_data.addColumn({type:'string', role:'tooltip', p: {html:true}});
				var rows = [];
				for (var i = 0; i < perf.group.length; i++) {
					var row = [ perf.group[i] ];
					row.push(perf.avg[i]);
					row.push('<p style="text-align:left"><i>' + perf.name + ' - ' + perf.group[i] + '</i></br>'
							+'<b>Average:</b> '+ Math.round(perf.avg[i]*100)/100 + '</br>' 
							+'<b>Quantity:</b> ' + Math.round(perf.quantity[i]*100)/100 + '</br>'
							+'<b>Std Dev:</b> ' + Math.round(perf.stdDev[i]*100)/100 + '</p>');
					rows.push(row);
				}
				chart_data.addRows(rows);
				var chart = new google.visualization.LineChart(innerDiv2);
				chart.draw(chart_data, {
					title : perf.name + ' (' + perf.unit + ')',
					curveType : 'function',
					width : 625,
					legend : {
						position : 'none'
					},
					tooltip: { isHtml: true }
				});
			}
		}
		/*
		var chart_data = new google.visualization.DataTable();
		chart_data.addColumn('string', apiResponse.performances[0].groupType);
		apiResponse.performances.map(function(perf) {
			chart_data.addColumn('number', perf.name);
			chart_data.addColumn({type:'string', role:'tooltip', p: {html:true}});
		});
		
		var rows = [];
		for (var i = 0; i < apiResponse.performances[0].group.length; i++) {
			var row = [ apiResponse.performances[0].group[i] ];
			apiResponse.performances.map(function(perf) {
				row.push(perf.avg[i]);
				row.push('<p style="text-align:left"><i>' + perf.name + ' - ' + perf.group[i] + '</i></br>'
						+'<b>Average:</b> '+ Math.round(perf.avg[i]*100)/100 + '</br>' 
						+'<b>Quantity:</b> ' + Math.round(perf.quantity[i]*100)/100 + '</br>'
						+'<b>Std Dev:</b> ' + Math.round(perf.stdDev[i]*100)/100 + '</p>');
			});
			rows.push(row);
		}
		chart_data.addRows(rows);
		var chart = new google.visualization.LineChart(document.getElementById("process_summary_performances"));

		chart.draw(chart_data, perf_chart_options);
		*/
	} else {
		document.getElementById('process_summary_performances').style.display = "none";
		document.getElementById('process_summary_performances').style.display = "none";
	}
}

function updateProcessDetails() {
	// Check Visisbility
	if (((apiResponse.queues == null) || (apiResponse.queues.length == 0))
			&& ((apiResponse.performances == null) || apiResponse.performances.length == 0)) {
		document.getElementById('process_details_container').style.display = "none";
		$('#process_details_header')[0].childNodes[0].childNodes[0].data = 'Process Details';
		return;
	}
	document.getElementById('process_details_container').style.display = "inline";
	$('#process_details_header')[0].childNodes[0].childNodes[0].data = 'Process Details';// as ' + formatDatefromJavaCalendar(apiResponse.lastUpdated);
	
	// Remove all tabs from process_details_container
	$('.tab-content').remove();
	$('.tab-link').remove();

	// Cycle through all queues and performances
	if ((apiResponse.queues != null) && (apiResponse.queues.length > 0)) {
		apiResponse.queues.map(function(queue, i) {
			if ((queue.name != null) && (queue.details != null)) {
				// Add a new tab in process_details_container
				var tabname = 'tab-' + queue.name.split(' ').join('-');
				$('#process_details_container').append(
						'<div id="' + tabname + '" class="tab-content'
								+ (i == 0 ? ' current' : '') + '"></div>');
				$('#tab_links').append(
						'<li class="tab-link' + (i == 0 ? ' current' : '')
								+ '" data-tab="' + tabname
								+ '" onclick="displayTab($(this))">'
								+ queue.name + '</li>');
				var table_data = new google.visualization.arrayToDataTable(
						queue.details);
				var table = new google.visualization.Table(document
						.getElementById(tabname));
				table.draw(table_data, table_options);
			}
		});
	}
	if ((apiResponse.performances != null)
			&& (apiResponse.performances.length > 0)) {
		apiResponse.performances
				.map(function(perf, i) {
					if ((perf.name != null) && (perf.details != null)) {
						// Add a new tab in process_details_container
						var tabname = 'tab-' + perf.name.split(' ').join('-');
						$('#process_details_container')
								.append(
										'<div id="'
												+ tabname
												+ '" class="tab-content'
												+ (((apiResponse.queues.length == 0) && (i == 0)) ? ' current'
														: '') + '"></div>');
						$('#tab_links')
								.append(
										'<li class="tab-link'
												+ (((apiResponse.queues.length == 0) && (i == 0)) ? ' current'
														: '')
												+ '" data-tab="'
												+ tabname
												+ '" onclick="displayTab($(this))">'
												+ perf.name + '</li>');
						var table_data = new google.visualization.arrayToDataTable(
								perf.details);
						var table = new google.visualization.Table(document
								.getElementById(tabname));
						table.draw(table_data, table_options);
					}
				});
	}
}

function formatDatefromJavaCalendar(date) {
	return zeroPad(date.dayOfMonth,2) + '/' + zeroPad((date.month+1),2) + '/' + date.year + ' ' + zeroPad(date.hourOfDay,2) + ':' + zeroPad(date.minute,2);
}

function zeroPad(num, places) {
  var zero = places - num.toString().length + 1;
  return Array(+(zero > 0 && zero)).join("0") + num;
}