// Data
var slaResponse;
var loadingCount = 0;
var green ='#99CC33';
var amber ='#FF9933';
var red ='#FF3333';
var line1 = 'orange';
var line2 = 'yellow';var toDate = new Date();
var fromDate = new Date();

// Data Formatters

//Visualizations Options

var toDateText, fromDateText;

var gauge_options = {
	width : 200,
	height : 200,
	redColor : red,
	redFrom : 0,
	redTo : 60,
	yellowColor : amber,
	yellowFrom : 60,
	yellowTo : 80,
	greenColor : green,
	greenFrom : 80,
	greenTo : 100,
	minorTicks : 5,
	animation : {
		duration : 400, 
		easing:'linear', 
		startup: true}
};

var pie_options = {
        is3D: true,
        width : 250,
    	  height : 250,
    	  legend: 'none',
    	slices: {
          0: { color: green },
          1: { color: red }
        }
      };

var stacked_column_chart_options = {
        width: '100%',
        height: 400,
        colors:[green,red,line1,line2],
        legend: { position: 'bottom', maxLines: 3 },
        bar: { groupWidth: '65%' },
        isStacked: true,
        series: {2: {type: "line", targetAxisIndex: 1}, 3: {type: "line", targetAxisIndex: 0}}
      };

$(document).ready(function() {
	var url = "kpiv2?querySLAs";
	if (document.getElementById("multiRegion").checked) {
		url += "&multiRegion=true";
	} 
	HTTPGetAsync(url, function(slas) {
		$("#sla-select").append("<option value=''>Select a metric...</option>");
		for (var i = 0; i < slas.length; i++) {
			$("#sla-select").append("<option value='" + slas[i].id + "'>" + slas[i].name + "</option>");
		}
		$("#sla-select").selectmenu();
		$("#sla-select").selectmenu("refresh");
		$.mobile.loading('hide');
	},
	function(httpStatus) {
		$.mobile.loading('hide');
	});
	
	/*
	HTTPGetAsync("kpiv2?queryRegions", function(regions) {
		$("#region-select").append("<option value=''>Select a region...</option>");
		for (var i = 0; i < regions.length; i++) {
			$("#region-select").append("<option value='" + regions[i].id + "'>" + regions[i].name + "</option>");
		}
		$("#region-select").selectmenu();
		$("#region-select").selectmenu("refresh");
		$.mobile.loading('hide');
	},
	function(httpStatus) {
		$.mobile.loading('hide');
	});
	*/
	HTTPGetAsync("dailyStatsParameters?region=APAC_ALL,EMEA_ALL,AUSTRALIA_PRODUCT_SERVICE", function(regions) {
		for (var i = 0; i < regions.length; i++) {
			if (regions[i][1]!=null) {
				$("#region-select").append("<optgroup label='" + regions[i][1] + "'>");
				$("#region-select").append("<option value='" + regions[i][0] + "'>" + regions[i][1] + "</option>");
				if (regions[i][2]!=null) {
					for (var j = 0; j < regions[i][2].length; j++) {
						$("#region-select").append("<option value='" + regions[i][2][j][0] + "'>" + regions[i][2][j][1] + "</option>");
					} 
				}
				$("#region-select").append("</optgroup>");
			}
		}
		$("#region-select").selectmenu();
		$("#region-select").selectmenu("refresh");
		$.mobile.loading('hide');
	},
	function(httpStatus) {
		$.mobile.loading('hide');
	});
	
	
	$("#sla-select").change(function() {
		refreshVisualisations();
	});
	
	$("#region-select").change(function() {
		refreshVisualisations();
	});
	
	$( "#from-date" ).datepicker( "option", "dateFormat", "dd/mm/yy" );
	$( "#to-date" ).datepicker( "option", "dateFormat", "dd/mm/yy" );
	$( "#from-date" ).datepicker( "option", "onSelect", fromDateSelected );
	$( "#to-date" ).datepicker( "option", "onSelect", toDateSelected );
	var toDate = new Date();
	fromDateText = "1/" + (toDate.getMonth()+1) + "/" + toDate.getFullYear();
	toDateText = toDate.getDate() + "/" + (toDate.getMonth()+1) + "/" + toDate.getFullYear();
	$( "#from-date" ).datepicker("setDate", fromDateText);
	$( "#to-date" ).datepicker("setDate", toDateText);
	$( "#from-date" ).datepicker("show");
	$( "#from-date" ).datepicker("hide");
});

function fromDateSelected(dateText, inst) {
	if ((inst.id === "from-date") && (fromDateText !== dateText)) {
		fromDateText = dateText;
		refreshVisualisations();
	}
}

function toDateSelected(dateText, inst) {
	if ((inst.id === "to-date") && (toDateText !== dateText)) {
		toDateText = dateText;
		refreshVisualisations();
	}
}

function refreshVisualisations() {
	document.getElementById('sla_container').style.visibility = "hidden";
	$.mobile.loading('show', {
		text : 'Loading',
		textVisible : true,
		theme : 'a',
		html : ""
	});

	loadingCount++;
	var url = "kpiv2?sla=" + $("#sla-select option:selected").val()+"&region=" + $("#region-select option:selected").val();
	if (fromDateText != null)
		url += "&fromDate=" + fromDateText;
	if (toDateText != null)
		url += "&toDate=" + toDateText;
	
	$("#backlog_details").attr('href', url + "&getDetails=backlog");
	$("#performance_details").attr('href', url + "&getDetails=completed");
	HTTPGetAsync(url, function(
			jsonResponse) {
		slaResponse = jsonResponse;
		updateSLASummary();
		loadingCount--;
		if (loadingCount == 0)
			$.mobile.loading('hide');
	}, function(httpStatus) {
		loadingCount--;
		if (loadingCount == 0)
			$.mobile.loading('hide');
	});
}

function updateSLASummary() {
	if (slaResponse != null) {
		document.getElementById('target_header').innerHTML = "SLA target: " + slaResponse.slaTargetText;
		
		if (slaResponse.hasProcessing) {
			document.getElementById('performance_summary_header').style.visibility = "visible";
			document.getElementById('performance_summary').style.visibility = "visible";
			document.getElementById('performance_notes').style.visibility = "visible";
			document.getElementById('performance_details').style.visibility = "visible";
			
			// Headers
			document.getElementById('performance_summary_header').innerHTML = "% " + slaResponse.slaName + " within SLA Target";
	
			// Performance Gauge
			var gauge_data = google.visualization.arrayToDataTable([
					[ 'Label', 'Value' ],
					['% SLA', {v:Math.round((1 - slaResponse.qtyProcessedOverSLA/ slaResponse.qtyProcessed) * 100), f: Math.round((1 - slaResponse.qtyProcessedOverSLA/ slaResponse.qtyProcessed) * 100) + "%"}], ]);
	
			var gauge_chart = new google.visualization.Gauge(document.getElementById('performance_summary'));
			gauge_chart.draw(gauge_data , gauge_options);
			
			// Performance Notes
			document.getElementById('performance_notes').innerHTML = "<ul class=\"summary\">" +
					"<li>" + slaResponse.qtyProcessed + " items processed</li>" +
					"<li>" + (slaResponse.qtyProcessed  - slaResponse.qtyProcessedOverSLA) + " within SLA target</li>" +
					"<li>" + slaResponse.qtyProcessedOverSLA + " over SLA target</li>" +
					"<li>Average wait before processing " + formatDecimal(slaResponse.avgProcessingTimeHrs,1) + " Hrs</li>" +
					"</ul>";
			
			if (slaResponse.processedByPeriod != null) {
				document.getElementById('performance_details_period_header').style.visibility = "visible";
				document.getElementById('performance_details_period').style.visibility = "visible";
				document.getElementById('performance_details_period_header').innerHTML = "Timeline";
				
				// Performance Details by Period
		        var details_period_data = new google.visualization.DataTable();
		        details_period_data.addColumn('string', 'Period');
		        details_period_data.addColumn('number', '# Within SLA');
		        details_period_data.addColumn('number', '# Over SLA');
		        details_period_data.addColumn('number', '% Within SLA');
		        //details_period_data.addColumn('number', 'Avg Proc.Time (Hrs)');
		        var all_rows = [];
		        for (var i = 1; i < slaResponse.processedByPeriod.length; i++) {
					all_rows.push([
					               slaResponse.processedByPeriod[i][0],
					               slaResponse.processedByPeriod[i][1]-slaResponse.processedByPeriod[i][2],
					               slaResponse.processedByPeriod[i][2],
					               formatDecimal((slaResponse.processedByPeriod[i][1]-slaResponse.processedByPeriod[i][2])/slaResponse.processedByPeriod[i][1]*100,2),
					               //slaResponse.processedByPeriod[i][3]
					               ]);
				}
		        details_period_data.addRows(all_rows);
		        var details_period_chart = new google.visualization.ColumnChart(document.getElementById('performance_details_period'));
		        details_period_chart.draw(details_period_data, stacked_column_chart_options);
			} else {
				document.getElementById('performance_details_period_header').style.visibility = "hidden";
				document.getElementById('performance_details_period').style.visibility = "hidden";
			}
		} else {
			document.getElementById('performance_summary_header').style.visibility = "hidden";
			document.getElementById('performance_summary').style.visibility = "hidden";
			document.getElementById('performance_notes').style.visibility = "hidden";
			document.getElementById('performance_details').style.visibility = "hidden";
			document.getElementById('performance_details_period_header').style.visibility = "hidden";
			document.getElementById('performance_details_period').style.visibility = "hidden";
		}
		
		if (slaResponse.hasBacklog) {
			document.getElementById('backlog_summary_header').style.visibility = "visible";
			document.getElementById('backlog_summary').style.visibility = "visible";
			document.getElementById('backlog_notes').style.visibility = "visible";
			document.getElementById('backlog_details').style.visibility = "visible";
			
			// Headers
			document.getElementById('backlog_summary_header').innerHTML = "Current " + slaResponse.slaName + " backlog";

			// Backlog Chart 
			var pie_data = google.visualization.arrayToDataTable([
	          ['Aging', 'Hours per Day'],
	          ['Within SLA', slaResponse.qtyBacklog - slaResponse.qtyBacklogOverSLA],
	          ['Over SLA', slaResponse.qtyBacklogOverSLA]
	        ]);
	
			var pie_chart = new google.visualization.PieChart(document.getElementById('backlog_summary'));
	        pie_chart.draw(pie_data, pie_options);
	        
			// Backlog Notes
	        document.getElementById('backlog_notes').innerHTML = "<ul class=\"summary\">" +
			"<li>" + slaResponse.qtyBacklog + " total items" + (slaResponse.activityDuration>0?" (" + formatDecimal(slaResponse.activityDuration*slaResponse.qtyBacklog/60, 1) + " Hrs)":"") + "</li>" +
			"<li>" + (slaResponse.qtyBacklogOverSLA) + " items (" + Math.round(slaResponse.qtyBacklogOverSLA/ slaResponse.qtyBacklog * 100) +" %) over SLA target</li>" + 
			"<li>Average aging: " + formatDecimal(slaResponse.avgAgingTimeHrs,1) + " Hrs</li>" +
			"</ul>";
		} else {
			document.getElementById('backlog_summary_header').style.visibility = "hidden";
			document.getElementById('backlog_summary').style.visibility = "hidden";
			document.getElementById('backlog_notes').style.visibility = "hidden";
			document.getElementById('backlog_details').style.visibility = "hidden";
		}

		document.getElementById('sla_container').style.visibility = "visible";
	} else {
		document.getElementById('performance_summary_header').style.visibility = "hidden";
		document.getElementById('performance_summary').style.visibility = "hidden";
		document.getElementById('performance_notes').style.visibility = "hidden";
		document.getElementById('performance_details').style.visibility = "hidden";
		document.getElementById('performance_details_period_header').style.visibility = "hidden";
		document.getElementById('performance_details_period').style.visibility = "hidden";
		document.getElementById('backlog_summary_header').style.visibility = "hidden";
		document.getElementById('backlog_summary').style.visibility = "hidden";
		document.getElementById('backlog_notes').style.visibility = "hidden";
		document.getElementById('backlog_details').style.visibility = "hidden";
	}
}

function HTTPGetAsync(url, onCompleteCb, onError) {
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
		} else if (xmlhttp.readyState == 4 && xmlhttp.status != 200) {
			onError(xmlhttp.status);
		}
	};
	xmlhttp.send();
}

function formatDecimal(n, d) {
	return Math.round(n*Math.pow(10, d))/Math.pow(10, d);
}

function formatDatefromJavaCalendar(date, spread) {
	var d = new Date(date.year, date.month, date.dayOfMonth, date.hourOfDay,
			date.minute, date.second, 0);
	d.setHours(d.getHours() + spread);
	return d.getDate()
			+ '/'
			+ (d.getMonth() < 9 ? '0' + (d.getMonth() + 1) : (d.getMonth() + 1))
			+ '/' + d.getFullYear();// + ' - ' +
									// (d.getHours()<10?'0'+d.getHours():d.getHours())
									// + ':' +
									// (d.getMinutes()<10?'0'+d.getMinutes():d.getMinutes());
}

function appendSla(sla, selectId) {
	if ((sla != null) && (sla instanceof Array) && (sla.length >= 2)) {	
		if ((sla.length>=3) && (sla[2] != null)) {
			$(selectId).append("<optgroup label='" + sla[1] + "'>");
			$(selectId).append("<option value='" + sla[0] + "'>" + region[1] + "</option>");
			for ( var i = 0; i < sla[2].length; i++) {
				appendSla(sla[2][i], selectId);
			}
			$(selectId).append("</optgroup>");
		} else {
			$(selectId).append("<option value='" + sla[0] + "'>" + sla[1] + "</option>");
		}
	}
};
