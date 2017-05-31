// Data
var slaResponse;
var selectedMetric, selectedMeasure, selectedRegion;
var loadingCount = 0;
var toDate = new Date();
var fromDate = new Date();
var overSlaColumnNumber = 11;

// Data Formatters

//Visualizations Options
var heatmap_table_options = {
	showRowNumber: false, 
	sort: 'disable',
	width: '100%',
	height: '100%',
	cssClassNames: {tableCell: 'mediumText', headerCell: 'mediumText'},
	allowHtml: true
};

var details_table_options = {
	showRowNumber : false,
	sort : 'enable',
	allowHtml : true,
	width : "100%",
	cssClassNames: {tableCell: 'mediumText', headerCell: 'mediumText'}	
};
var toDateText, fromDateText;

$(document).ready(function() {
	
	HTTPGetAsync("dailyStatsParameters?region=GLOBAL", function(regions) {
		for (var i = 0; i < regions.length; i++) {
			if (regions[i][1]!=null) {
				$("#region-select").append("<optgroup label='" + regions[i][1] + "'>");
				$("#region-select").append("<option value='" + regions[i][0] + "' " + (i==0?"SELECTED":"") + ">" + regions[i][1] + "</option>");
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
		refreshVisualisations();
	},
	function(httpStatus) {
		$.mobile.loading('hide');
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
	document.getElementById('heatmap_container').style.visibility = "hidden";
	$.mobile.loading('show', {
		text : 'Loading',
		textVisible : true,
		theme : 'a',
		html : ""
	});

	loadingCount++;
	var url = "kpiv2?allSLAs=true" + "&region=" + $("#region-select option:selected").val();
	if (fromDateText != null)
		url += "&fromDate=" + fromDateText;
	if (toDateText != null)
		url += "&toDate=" + toDateText;
	
	HTTPGetAsync(url, function(
			jsonResponse) {
		slaResponse = jsonResponse;
		updateHeatmap();
		loadingCount--;
		if (loadingCount == 0)
			$.mobile.loading('hide');
	}, function(httpStatus) {
		loadingCount--;
		if (loadingCount == 0)
			$.mobile.loading('hide');
	});
}

function updateHeatmap() {
	if (slaResponse != null) {
		var heatmap_table_data = new google.visualization.DataTable();
		var heatmap_table = new google.visualization.Table(document.getElementById("heatmap"));
		var headerWidth = 100/slaResponse[0].length;
		var dataWidth = headerWidth;
		
		for (var i = 1; i < slaResponse[0].length; i++) {
			heatmap_table_data.addColumn('string', slaResponse[0][i]);
		}
        var completed = true;
		for (var r = 1; r < slaResponse.length; r=r+2) {
			var row = [];
			if (completed) {
				row.push({v:slaResponse[r][1], f:'<span title="' + slaResponse[r][0] + '">' + slaResponse[r][1] + '</span>', p:{className: 'rowspan_2', style:'width:' + headerWidth + '%'}});
			} else {
				row.push({v:slaResponse[r][1], p:{className: 'delete', style:'width:' + headerWidth + '%'}});
			}
			
			row.push({v:slaResponse[r][2], p:{style:'width:' + headerWidth + '%'}});
			for (var c = 3; c < slaResponse[r].length; c++) {
				var classText = "";
				var withinSLA = 100;
				var outsideSLA = 0;
				
				if(slaResponse[r][c]!=0 && slaResponse[r+1][c]!=0) {
					withinSLA = Math.round((1-slaResponse[r+1][c]/slaResponse[r][c])*100,2);
					outsideSLA = Math.round(slaResponse[r+1][c]/slaResponse[r][c]*100,2);
					classText = 'class="redbar" style="width:' + outsideSLA + '%;"';
				}
				
				var tooltip = slaResponse[r][c] + ' items ' + (completed?'completed':'in backlog') + '.\n';
				tooltip += slaResponse[r+1][c] + ' outside SLA (' + outsideSLA + '%).\n';
				tooltip += (slaResponse[r][c] - slaResponse[r+1][c]) + ' within SLA (' + withinSLA + '%).';						
				var span = '<span ' + classText + ' title="' + tooltip + '">' + slaResponse[r][c] + '</span>';
				row.push({v:span, p:{className: 'dataCell', style:'width:' + dataWidth + '%'}});
			}
			heatmap_table_data.addRow(row);
			completed= !completed;
		}
        
		google.visualization.events.addListener(heatmap_table, 'ready', function () {
	        // delete all cells with the class "delete"
	        var deletions = document.getElementById('heatmap').getElementsByClassName('delete');
	        while (deletions.length) {
	            deletions[0].parentNode.removeChild(deletions[0]);
	        }
	        
	        // handle all rowspan elements
	        // pick some limit to the upper number of rows that a cell can span
	        var maxRows = 3;
	        for (var i = 2; i <= maxRows; i++) {
	            var cells = document.getElementById('heatmap').getElementsByClassName('rowspan_' + i);
	            for (var j = 0; j < cells.length; j++) {
	                cells[j].rowSpan = i;
	            }
	        }
	        
	        // handle all colspan elements
	        // pick some limit to the upper number of columns that a cell can span
	        var maxCols = 3;
	        for (var i = 2; i <= maxCols; i++) {
	            var cells = document.getElementById('heatmap').getElementsByClassName('colspan_' + i);
	            for (var j = 0; j < cells.length; j++) {
	                cells[j].colSpan = i;
	            }
	        }
	        
	        $('.dataCell').on('click', function () {
	            var column = parseInt( $(this).index() );
	            var row = parseInt( $(this).parent().index() );
	            heatmap_table_data.setProperty(row, column, 'className', heatmap_table_data.getProperty(row, column, 'className') + ' selected');
	            selectedMetric = heatmap_table_data.getValue(row, 0);
	            selectedMeasure = heatmap_table_data.getValue(row, 1);
	            selectedRegion = heatmap_table_data.getColumnLabel(column);
	            if (selectedRegion=="Measure")  
	            	selectedRegion = heatmap_table_data.getColumnLabel(column+1);
	        	else if (selectedMeasure == 'WIP' && selectedMetric != "Lapsed Certification")
	        		selectedRegion = heatmap_table_data.getColumnLabel(column+1);
	            refreshDetails();
	        });
	    });
	    
		heatmap_table.draw(heatmap_table_data, heatmap_table_options);
		document.getElementById('heatmap_container').style.visibility = "visible";
		selectedMetric = null;
		selectedMeasure = null;
		selectedRegion = null;
		refreshDetails();
	}
}

function refreshDetails() {
	document.getElementById('details_container').style.visibility = "hidden";
	if(selectedMetric != null && selectedMeasure != null && selectedRegion != null) {
		$.mobile.loading('show', {
			text : 'Loading',
			textVisible : true,
			theme : 'a',
			html : ""
		});

		loadingCount++;
		var url = "kpiv2?sla=" + selectedMetric + "&regionName=" + selectedRegion + "&getDetails=" + selectedMeasure + "&detailsFormat=json";
		if (fromDateText != null)
			url += "&fromDate=" + fromDateText;
		if (toDateText != null)
			url += "&toDate=" + toDateText;
		
		HTTPGetAsync(url, function(
				details) {
			updateDetails(details);
			loadingCount--;
			if (loadingCount == 0)
				$.mobile.loading('hide');
		}, function(httpStatus) {
			loadingCount--;
			if (loadingCount == 0)
				$.mobile.loading('hide');
		});
	}
}

function updateDetails(details) {
	if (details != null) {
		var details_table_data = new google.visualization.arrayToDataTable(details);
		var details_table = new google.visualization.Table(document.getElementById("details"));
		
	    for (var r = 0; r < details_table_data.getNumberOfRows(); r++) {
	    	if (details_table_data.getValue(r,overSlaColumnNumber)=="1") {
	    		for (var c = 0; c < details_table_data.getNumberOfColumns(); c++) {
					details_table_data.setProperty(r,c,'className','detailsOverSLA mediumText');
				}
	    	}
	    }
	    details_table_data.removeColumn(overSlaColumnNumber);
		details_table.draw(details_table_data, details_table_options);
		document.getElementById('details_container').style.visibility = "visible";
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
