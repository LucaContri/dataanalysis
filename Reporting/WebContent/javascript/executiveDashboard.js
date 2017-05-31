// Data
var slaResponseSummary;
var slaResponseDetails;
var loadingCount = 0;
var toDate = new Date();
var fromDate = new Date();
var previousFromDate = new Date();
previousFromDate.setMonth(previousFromDate.getMonth()-1);
var periodDate = "01/" + fromDate.getMonth() + "/" + fromDate.getFullYear();
var previousPeriodDate = "01/" + previousFromDate.getMonth() + "/" + previousFromDate.getFullYear();
// Data Formatters

//Visualizations Options
var summary_table_options = {
	showRowNumber: false, 
	sort: 'disable',
	width: '100%',
	height: '100%',
	allowHtml: true
};

var details_table_options = {
		showRowNumber: false, 
		sort: 'enable',
		width: '100%',
		height: '100%',
		allowHtml: true
	};

var toDateText, fromDateText;

$(document).ready(function() {
	refreshVisualisations();
});

function refreshVisualisations() {
	document.getElementById('summary_container').style.visibility = "hidden";
	document.getElementById('summary_aside').style.visibility = "hidden";
	document.getElementById('details_container').style.visibility = "hidden";
	document.getElementById('details_notes').style.visibility = "hidden";
	//$.mobile.loading('show', {
	//	text : 'Loading',
	//	textVisible : true,
	//	theme : 'a',
	//	html : ""
	//});

	loadingCount++;
	var url = "executiveDashboard?request=SUMMARY&function=OPERATIONS&fromDate=" + periodDate + "&toDate=" + periodDate;
	
	HTTPGetAsync(url, function(
			jsonResponse) {
		slaResponseSummary = jsonResponse;
		updateSummaryTable();
		loadingCount--;
		//if (loadingCount == 0)
			//$.mobile.loading('hide');
	}, function(httpStatus) {
		loadingCount--;
		//if (loadingCount == 0)
			//$.mobile.loading('hide');
	});
}

function updateSummaryTable() {
	if (slaResponseSummary != null) {
		var table_data = new google.visualization.DataTable();
		var table = new google.visualization.Table(document.getElementById("summary"));
		var headerWidth = 100/10;
		var dataWidth = headerWidth;
		
		previousPeriod = slaResponseSummary[0][2].replace('AMERICAs (', '').replace(')','');
		currentPeriod = slaResponseSummary[0][4].replace('AMERICAs (', '').replace(')','');
		table_data.addColumn('string', slaResponseSummary[0][0]);
		table_data.addColumn('string', slaResponseSummary[0][1]);
		table_data.addColumn('number', previousPeriod);
		table_data.addColumn('number', currentPeriod);
		table_data.addColumn('number', previousPeriod);
		table_data.addColumn('number', currentPeriod);
		table_data.addColumn('number', previousPeriod);
		table_data.addColumn('number', currentPeriod);
		table_data.addColumn('number', previousPeriod);
		table_data.addColumn('number', currentPeriod);
        
		for (var r = 1; r < slaResponseSummary.length; r++) {
			var row = [];
			var metricGrouplassName = 'clear';
			var totalClassName = '';
			if(slaResponseSummary[r][1]=='Overall') {
				totalClassName = 'subtotal';
				slaResponseSummary[r][0] = 'Overall ' + slaResponseSummary[r][0];
				slaResponseSummary[r][1] = '&nbsp;';
			}
			if (slaResponseSummary[r][0] != slaResponseSummary[r-1][0]) 
				metricGrouplassName = getMetricGroupClassNameForRow(r);
			
			row.push({v:slaResponseSummary[r][0], p:{className: metricGrouplassName + " " + totalClassName, style:'width:' + dataWidth + '%'}});
			row.push({v:slaResponseSummary[r][1], p:{className: 'productPortfolioCell' + " " + totalClassName, style:'width:' + dataWidth + '%'}});
			
			row.push((slaResponseSummary[r][2]==null)?{v:null, f:'&nbsp;', p:{className: totalClassName, style:'width:' + dataWidth + '%'}}:{v:slaResponseSummary[r][2], f:(slaResponseSummary[r][2]*100).toFixed(2) + '%', p:{className: getDataCellClassName(r,2) + " " + totalClassName, style:'width:' + dataWidth + '%'}});
			row.push((slaResponseSummary[r][4]==null)?{v:null, f:'&nbsp;', p:{className: totalClassName, style:'width:' + dataWidth + '%'}}:{v:slaResponseSummary[r][4], f:(slaResponseSummary[r][4]*100).toFixed(2) + '%', p:{className: getDataCellClassName(r,4) + " " + totalClassName, style:'width:' + dataWidth + '%'}});
			row.push((slaResponseSummary[r][7]==null)?{v:null, f:'&nbsp;', p:{className: totalClassName, style:'width:' + dataWidth + '%'}}:{v:slaResponseSummary[r][7], f:(slaResponseSummary[r][7]*100).toFixed(2) + '%', p:{className: getDataCellClassName(r,7) + " " + totalClassName, style:'width:' + dataWidth + '%'}});
			row.push((slaResponseSummary[r][9]==null)?{v:null, f:'&nbsp;', p:{className: totalClassName, style:'width:' + dataWidth + '%'}}:{v:slaResponseSummary[r][9], f:(slaResponseSummary[r][9]*100).toFixed(2) + '%', p:{className: getDataCellClassName(r,9) + " " + totalClassName, style:'width:' + dataWidth + '%'}});
			row.push((slaResponseSummary[r][12]==null)?{v:null, f:'&nbsp;', p:{className: totalClassName, style:'width:' + dataWidth + '%'}}:{v:slaResponseSummary[r][12], f:(slaResponseSummary[r][12]*100).toFixed(2) + '%', p:{className: getDataCellClassName(r,12) + " " + totalClassName, style:'width:' + dataWidth + '%'}});
			row.push((slaResponseSummary[r][14]==null)?{v:null, f:'&nbsp;', p:{className: totalClassName, style:'width:' + dataWidth + '%'}}:{v:slaResponseSummary[r][14], f:(slaResponseSummary[r][14]*100).toFixed(2) + '%', p:{className: getDataCellClassName(r,14) + " " + totalClassName, style:'width:' + dataWidth + '%'}});
			row.push((slaResponseSummary[r][17]==null)?{v:null, f:'&nbsp;', p:{className: totalClassName, style:'width:' + dataWidth + '%'}}:{v:slaResponseSummary[r][17], f:(slaResponseSummary[r][17]*100).toFixed(2) + '%', p:{className: getDataCellClassName(r,17) + " " + totalClassName, style:'width:' + dataWidth + '%'}});
			row.push((slaResponseSummary[r][19]==null)?{v:null, f:'&nbsp;', p:{className: totalClassName, style:'width:' + dataWidth + '%'}}:{v:slaResponseSummary[r][19], f:(slaResponseSummary[r][19]*100).toFixed(2) + '%', p:{className: getDataCellClassName(r,19) + " " + totalClassName, style:'width:' + dataWidth + '%'}});
			
			table_data.addRow(row);
		}
		
		google.visualization.events.addListener(table, 'ready', function () {
			
			var table = document.getElementById('summary').getElementsByClassName('google-visualization-table-table')[0];
			var header = document.createElement("tr");
			header.className = 'google-visualization-table-tr-head';
			header.innerHTML = '<th class="google-visualization-table-th gradient">&nbsp</th>';
			header.innerHTML += '<th class="google-visualization-table-th gradient">&nbsp</th>';
			header.innerHTML += '<th class="google-visualization-table-th gradient" colspan="2">AMERICAs</th>';
			header.innerHTML += '<th class="google-visualization-table-th gradient" colspan="2">APAC</th>';
			header.innerHTML += '<th class="google-visualization-table-th gradient" colspan="2">EMEA</th>';
			header.innerHTML += '<th class="google-visualization-table-th gradient" colspan="2">Overall</th>';
			table.tHead.insertBefore(header, table.tHead.firstChild);
			
	        // delete all cells with the class "delete"
	        var deletions = document.getElementById('summary').getElementsByClassName('delete');
	        while (deletions.length) {
	            deletions[0].parentNode.removeChild(deletions[0]);
	        }
	        
	        // Clear innerHTML for 'clear' class
	        var clears = document.getElementById('summary').getElementsByClassName('clear');
	        for (var j = 0; j < clears.length; j++) {
	        	clears[j].innerHTML = '&nbsp;';
            }
	        
	        // handle all rowspan elements
	        // pick some limit to the upper number of rows that a cell can span
	        var maxRows = 4;
	        for (var i = 2; i <= maxRows; i++) {
	            var cells = document.getElementById('summary').getElementsByClassName('rowspan_' + i);
	            for (var j = 0; j < cells.length; j++) {
	                cells[j].rowSpan = i;
	            }
	        }
	        
	        // handle all colspan elements
	        // pick some limit to the upper number of columns that a cell can span
	        var maxCols = 3;
	        for (var i = 2; i <= maxCols; i++) {
	            var cells = document.getElementById('summary').getElementsByClassName('colspan_' + i);
	            for (var j = 0; j < cells.length; j++) {
	                cells[j].colSpan = i;
	            }
	        }
	        
	        $('.dataCell').on('click', function () {
	            var column = parseInt( $(this).index() );
	            var row = parseInt( $(this).parent().index() );
	            var metricsIds = null;
	            var period = periodDate;
	            
	            switch (column) {
				case 2: period = previousPeriodDate; metricsIds = slaResponseSummary[row+1][6]; break;
				case 3: metricsIds = slaResponseSummary[row+1][6]; break;
				case 4: period = previousPeriodDate; metricsIds = slaResponseSummary[row+1][11]; break;
				case 5: metricsIds = slaResponseSummary[row+1][11]; break;
				case 6: period = previousPeriodDate; metricsIds = slaResponseSummary[row+1][16]; break;
				case 7: metricsIds = slaResponseSummary[row+1][16]; break;
				case 8: period = previousPeriodDate; metricsIds = slaResponseSummary[row+1][21]; break;
				case 9: metricsIds = slaResponseSummary[row+1][21]; break;
				default:
					break;
	            }
	            refreshDetails(metricsIds, period);
	        });
	        
	    });
		
		var table_view = new google.visualization.DataView(table_data);
		
		table.draw(table_view, summary_table_options);
		document.getElementById('summary_container').style.visibility = "visible";
		document.getElementById('summary_aside').style.visibility = "visible";
	}
}

function refreshDetails(metricsIds, period) {
	document.getElementById('details_container').style.visibility = "hidden";
	document.getElementById('details_notes').style.visibility = "hidden";
	loadingCount++;
	
	var url = "executiveDashboard?request=DETAILS&function=OPERATIONS&fromDate=" + period + "&toDate=" + period + "&metricsIds=" + metricsIds;
	
	HTTPGetAsync(url, function(
			jsonResponse) {
		slaResponseDetails = jsonResponse;
		updateDetailsTable();
		loadingCount--;
		//if (loadingCount == 0)
			//$.mobile.loading('hide');
	}, function(httpStatus) {
		loadingCount--;
		//if (loadingCount == 0)
			//$.mobile.loading('hide');
	});
}

function updateDetailsTable() {
	if (slaResponseDetails != null && (Object.prototype.toString.call( slaResponseDetails ) === '[object Array]') && slaResponseDetails.length > 0) {
		// Header
		document.getElementById('details_header').innerHTML  = slaResponseDetails[0].metric.productPortfolio + " - " + slaResponseDetails[0].metric.metricGroup;
		
		var table_data = new google.visualization.DataTable();
		var table = new google.visualization.Table(document.getElementById("details"));
		
		table_data.addColumn('string', 'Region');
		table_data.addColumn('string', 'Country');
		table_data.addColumn('string', 'Product Portfolio');
		table_data.addColumn('string', 'Team');
		table_data.addColumn('string', 'Metric Name'); 
		table_data.addColumn('string', 'Business Owner'); 
		table_data.addColumn('number', 'Service Level'); 
		table_data.addColumn('number', 'SLA');
		table_data.addColumn('number', 'Volume');
		table_data.addColumn('string', 'Prepared By');
		table_data.addColumn('string', 'Prepared Date');
		table_data.addColumn('string', 'Link');
        
		var detailsNotes = {};
		var noteNo = 0;
		var slaOverallNum=0, volumeOverall=0;
		var overallRag = 'Green';
		var overallVolumeUnit = slaResponseDetails[0].metric.volumeUnit;
		for (var r = 0; r < slaResponseDetails.length; r++) {
			var metricDetails = slaResponseDetails[r];
			if (detailsNotes[metricDetails.metric.Id] == null) {
				noteNo++;
				var metricTarget = formatDecimal(metricDetails.metric.valueTarget,2) + " " + metricDetails.metric.valueUnit; 
				if (metricDetails.metric.valueUnit == '%')
					metricTarget = formatDecimal(metricDetails.metric.valueTarget*100,2) + " " + metricDetails.metric.valueUnit; 
				detailsNotes[metricDetails.metric.Id] = 
					'<u>Metric definition</u>: ' + metricDetails.metric.valueDefinition + '</br>' +
					'<u>Metric target</u>: ' + metricTarget + '</br>' +
					'<u>Service Level definition</u>: ' + metricDetails.metric.slaDefinition;
			}
			var row = [];
			row.push({v:metricDetails.metric.regionDisplayName});
			row.push({v:metricDetails.subRegion});
			row.push({v:metricDetails.metric.productPortfolio});
			row.push({v:metricDetails.metric.team});
			row.push({v:metricDetails.metric.metric, f:metricDetails.metric.metric + "<sup>(" + noteNo + ")</sup>" });
			row.push({v:metricDetails.metric.businessOwner});
			var rag = 'Green';
			if (metricDetails.slaValue<metricDetails.metric.slaTargetGreen) {
				rag = 'Amber';
				overallRag = 'Amber';
			}
			if (metricDetails.slaValue<metricDetails.metric.slaTargetAmber) {
				rag = 'Red';
				overallRag = 'Red';
			}
			if (metricDetails.metric.volumeUnit != overallVolumeUnit)
				overallVolumeUnit = 'items';
			row.push({v:metricDetails.slaValue, f:formatDecimal(metricDetails.slaValue*100,2) + "%", p:{className:"tdcenter " + rag}});
			row.push({v:metricDetails.metric.slaTargetGreen, f:formatDecimal(metricDetails.metric.slaTargetGreen*100,2) + "%", p:{className:"tdcenter"}});
			volumeOverall += metricDetails.volume;
			slaOverallNum += metricDetails.volume * metricDetails.slaValue; 
			row.push({v:metricDetails.volume, f:metricDetails.volume + " " + metricDetails.metric.volumeUnit, p:{className:"tdcenter"}});
			row.push({v:metricDetails.preparedBy, p:{className:"tdcenter"}});
			row.push({v:formatDatefromJavaCalendar(metricDetails.preparedDateTime,0), p:{className:"tdcenter"}});
			row.push(null);
			table_data.addRow(row);
		}
		// Add Total
		if (overallVolumeUnit != null)
			table_data.addRow([
		                   {v:'Overall', p:{className:"total"}},
		                   {v:'&nbsp;', p:{className:"total"}},
		                   {v:'&nbsp;', p:{className:"total"}},
		                   {v:'&nbsp;', p:{className:"total"}},
		                   {v:'&nbsp;', p:{className:"total"}},
		                   {v:'&nbsp;', p:{className:"total"}},
		                   {v:slaOverallNum/volumeOverall*100, f:formatDecimal(slaOverallNum/volumeOverall*100,2) + "%", p:{className:overallRag + " total tdcenter"}},
		                   {v:0, f:'&nbsp;', p:{className:"total"}},
		                   {v:volumeOverall, f:volumeOverall + " " + overallVolumeUnit, p:{className:"total tdcenter"}},
		                   {v:'&nbsp;', p:{className:"total"}},{v:'&nbsp;', p:{className:"total"}},{v:'&nbsp;', p:{className:"total"}}
		                   ]);
				
		var table_view = new google.visualization.DataView(table_data);
		
		table.draw(table_view, details_table_options);
		
		// Update Notes
		$("#details_notes_list").empty();
		for (var noteNo in detailsNotes) {
			$("#details_notes_list").append( '<li>' + detailsNotes[noteNo] + '</li>' );
		}
		
		document.getElementById('details_container').style.visibility = "visible";
		document.getElementById('details_notes').style.visibility = "visible";
	}
}

function getMetricGroupClassNameForRow(rowNo) {
	var r;
	for (r=Math.min(rowNo+1,slaResponseSummary.length-1); r<slaResponseSummary.length; r++) {
		if (slaResponseSummary[r][0] != slaResponseSummary[rowNo][0])
			break;
	}
	return '';//'rowspan_' + (r-rowNo); 
}

function getDataCellClassName(r,c) {
	if (slaResponseSummary[0][c].indexOf('Status')>0 || c<2) 
		return 'dataCell';
		
	if (slaResponseSummary[r][c+1]==2)
		return 'dataCell Green';
	
	if (slaResponseSummary[r][c+1]==1)
		return 'dataCell Amber';
	
	if (slaResponseSummary[r][c+1]==0)
		return 'dataCell Red';
	
	return 'dataCell';
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
