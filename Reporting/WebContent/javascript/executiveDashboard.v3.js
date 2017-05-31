// Data
var slaResponseSummary;
var slaResponseDetails;
var loadingCount = 0;
var periodDate,previousPeriodDate;
var monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun","Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
var metricIds = [];

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
		sort: 'disable',
		width: '100%',
		height: '100%',
		allowHtml: true
	};

$(document).ready(function() {
	refreshVisualisations();
	
	$("#select_period" ).change(function() {
		refreshVisualisations();
	});
});

function refreshVisualisations() {
	periodDate = $("#select_period").val();
	previousPeriodDate = getPreviousPeriod();
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

function get(period, metric, product, region, parameter) {
	if (parameter==null)
		parameter = 'slaValueEquivalent';
	if ((slaResponseSummary == null) || (metric == null))
		return null;
	if (slaResponseSummary[period] == null)
		return null;
	if ((product == null) && (region == null)) {
		if (slaResponseSummary[period].metric[metric] == null)
			return null;
		return slaResponseSummary[period].metric[metric][parameter];
	} else {
		if (product == null) {
			if ((slaResponseSummary[period].metric_region[metric] == null) || (slaResponseSummary[period].metric_region[metric][region] == null))
				return null;
			return slaResponseSummary[period].metric_region[metric][region][parameter];
		} else if (region == null) {
			if ((slaResponseSummary[period].metric_product[metric] == null) || (slaResponseSummary[period].metric_product[metric][product] == null))
				return null;
			return slaResponseSummary[period].metric_product[metric][product][parameter];
		} else {
			if (slaResponseSummary[period].metric_product_region[metric] == null)
				return null;
			if (slaResponseSummary[period].metric_product_region[metric][product] == null)
				return null;
			if (slaResponseSummary[period].metric_product_region[metric][product][region] == null)
				return null;
			return slaResponseSummary[period].metric_product_region[metric][product][region][parameter];
		}
	}
}

function updateSummaryTable() {
	separator = 'border-right: 3px solid #e4e9f4; ';
	subtotal_bold = 'font-size: 120%; font-weight: bold; ';
	subtotal = 'font-size: 120%; ';
	if (slaResponseSummary != null) {
		var table_data = new google.visualization.DataTable();
		metricIds = [];
		var table = new google.visualization.Table(document.getElementById("summary"));
		var headerWidth = 100/8;
		var dataWidth = headerWidth;
		var metricGroups = ['Quality', 'Timeliness', 'Utilisation', 'Productivity'];
		var productPortfolios = ['Assurance', 'Knowledge', 'Learning', 'Risk'];
		previousPeriod = formatPeriodFromString(previousPeriodDate);
		currentPeriod = formatPeriodFromString(periodDate);
		table_data.addColumn('string', 'Metric Group');
		table_data.addColumn('string', 'Product Portfolio');
		table_data.addColumn('number', previousPeriod);
		table_data.addColumn('number', currentPeriod);
		table_data.addColumn('number', previousPeriod);
		table_data.addColumn('number', currentPeriod);
		table_data.addColumn('number', previousPeriod);
		table_data.addColumn('number', currentPeriod);
		//table_data.addColumn('number', previousPeriod);
		//table_data.addColumn('number', currentPeriod);
        
		//for ( var metric in slaResponseSummary.current.metric_product_region) {
		for ( var metricIndex in metricGroups) {
			var metric = metricGroups[metricIndex];
			var firstProductPortfolio = true;
			var metricGrouplassName = '';
			//for ( var product in slaResponseSummary.current.metric_product_region[metric]) {
			for ( var productIndex in productPortfolios) {
				var product = productPortfolios[productIndex];
				var row = [];
				row.push({v:metric, p:{className: metricGrouplassName, style:'width:' + dataWidth + '%'}});
				row.push({v:product, p:{className: 'productPortfolioCell', style:separator + 'width:' + dataWidth + '%'}});
				row.push((get('previous',metric,product,'Americas')==null)?{v:null, f:'&nbsp;', p:{style:'width:' + dataWidth + '%'}}:{v:get('previous',metric,product,'Americas'), f:(get('previous',metric,product,'Americas')*100).toFixed(2) + '%', p:{className: getDataCellClassName('previous',metric,product,'Americas'), style:'width:' + dataWidth + '%'}});
				row.push((get('current',metric,product,'Americas')==null)?{v:null, f:'&nbsp;', p:{style:separator + 'width:' + dataWidth + '%'}}:{v:get('current',metric,product,'Americas'), f:(get('current',metric,product,'Americas')*100).toFixed(2) + '%', p:{className: getDataCellClassName('current',metric,product,'Americas'), style:separator + 'width:' + dataWidth + '%'}});
				row.push((get('previous',metric,product,'Apac')==null)?{v:null, f:'&nbsp;', p:{style:'width:' + dataWidth + '%'}}:{v:get('previous',metric,product,'Apac'), f:(get('previous',metric,product,'Apac')*100).toFixed(2) + '%', p:{className: getDataCellClassName('previous',metric,product,'Apac'), style:'width:' + dataWidth + '%'}});
				row.push((get('current',metric,product,'Apac')==null)?{v:null, f:'&nbsp;', p:{style:separator + 'width:' + dataWidth + '%'}}:{v:get('current',metric,product,'Apac'), f:(get('current',metric,product,'Apac')*100).toFixed(2) + '%', p:{className: getDataCellClassName('current',metric,product,'Apac'), style:separator + 'width:' + dataWidth + '%'}});
				row.push((get('previous',metric,product,'Emea')==null)?{v:null, f:'&nbsp;', p:{style:'width:' + dataWidth + '%'}}:{v:get('previous',metric,product,'Emea'), f:(get('previous',metric,product,'Emea')*100).toFixed(2) + '%', p:{className: getDataCellClassName('previous',metric,product,'Emea'), style:'width:' + dataWidth + '%'}});
				row.push((get('current',metric,product,'Emea')==null)?{v:null, f:'&nbsp;', p:{style:'width:' + dataWidth + '%'}}:{v:get('current',metric,product,'Emea'), f:(get('current',metric,product,'Emea')*100).toFixed(2) + '%', p:{className: getDataCellClassName('current',metric,product,'Emea'), style:'width:' + dataWidth + '%'}});
				//row.push((get('previous',metric,product,null)==null)?{v:null, f:'&nbsp;', p:{style:'width:' + dataWidth + '%'}}:{v:get('previous',metric,product,null), f:(get('previous',metric,product,null)*100).toFixed(2) + '%', p:{className: getDataCellClassName('previous',metric,product,null), style:'width:' + dataWidth + '%'}});
				//row.push((get('current',metric,product,null)==null)?{v:null, f:'&nbsp;', p:{style:'width:' + dataWidth + '%'}}:{v:get('current',metric,product,null), f:(get('current',metric,product,null)*100).toFixed(2) + '%', p:{className: getDataCellClassName('current',metric,product,null), style:'width:' + dataWidth + '%'}});
				table_data.addRow(row);
				metricIds.push([null,null,
				                 get('previous',metric,product,'Americas','metricIds'),
				                 get('current',metric,product,'Americas','metricIds'),
				                 get('previous',metric,product,'Apac','metricIds'),
				                 get('current',metric,product,'Apac','metricIds'),
				                 get('previous',metric,product,'Emea','metricIds'),
				                 get('current',metric,product,'Emea','metricIds'),
				                 //get('previous',metric,product,null,'metricIds'),
				                 //get('current',metric,product,null,'metricIds'),
				                 ]);
				if(firstProductPortfolio) {
					metricGrouplassName = 'clear';
					firstProductPortfolio = false;
				}
			}

			var row = [];
			row.push({v:'Overall ' + metric, p:{className: 'subtotal', style:subtotal_bold + 'width:' + dataWidth + '%'}});
			row.push({v:'&nbsp;', p:{className: 'productPortfolioCell subtotal', style:subtotal_bold + separator + 'width:' + dataWidth + '%'}});
			row.push((get('previous',metric,null,'Americas')==null)?{v:null, f:'&nbsp;', p:{className: "subtotal",style:subtotal + 'width:' + dataWidth + '%'}}:{v:get('previous',metric,null,'Americas'), f:(get('previous',metric,null,'Americas')*100).toFixed(2) + '%', p:{className: getDataCellClassName('previous',metric,null,'Americas') + " subtotal_no_gradient", style:subtotal + 'width:' + dataWidth + '%'}});
			row.push((get('current',metric,null,'Americas')==null)?{v:null, f:'&nbsp;', p:{className: "subtotal",style:subtotal + separator + 'width:' + dataWidth + '%'}}:{v:get('current',metric,null,'Americas'), f:(get('current',metric,null,'Americas')*100).toFixed(2) + '%', p:{className: getDataCellClassName('current',metric,null,'Americas') + " subtotal_no_gradient", style:separator + subtotal_bold + 'width:' + dataWidth + '%'}});
			row.push((get('previous',metric,null,'Apac')==null)?{v:null, f:'&nbsp;', p:{className: "subtotal",style:subtotal + 'width:' + dataWidth + '%'}}:{v:get('previous',metric,null,'Apac'), f:(get('previous',metric,null,'Apac')*100).toFixed(2) + '%', p:{className: getDataCellClassName('previous',metric,null,'Apac') + " subtotal_no_gradient", style:subtotal + 'width:' + dataWidth + '%'}});
			row.push((get('current',metric,null,'Apac')==null)?{v:null, f:'&nbsp;', p:{className: "subtotal",style:subtotal + separator + 'width:' + dataWidth + '%'}}:{v:get('current',metric,null,'Apac'), f:(get('current',metric,null,'Apac')*100).toFixed(2) + '%', p:{className: getDataCellClassName('current',metric,null,'Apac') + " subtotal_no_gradient", style:subtotal_bold + separator + 'width:' + dataWidth + '%'}});
			row.push((get('previous',metric,null,'Emea')==null)?{v:null, f:'&nbsp;', p:{className: "subtotal",style:subtotal + 'width:' + dataWidth + '%'}}:{v:get('previous',metric,null,'Emea'), f:(get('previous',metric,null,'Emea')*100).toFixed(2) + '%', p:{className: getDataCellClassName('previous',metric,null,'Emea') + " subtotal_no_gradient", style:subtotal + 'width:' + dataWidth + '%'}});
			row.push((get('current',metric,null,'Emea')==null)?{v:null, f:'&nbsp;', p:{className: "subtotal",style:subtotal + 'width:' + dataWidth + '%'}}:{v:get('current',metric,null,'Emea'), f:(get('current',metric,null,'Emea')*100).toFixed(2) + '%', p:{className: getDataCellClassName('current',metric,null,'Emea') + " subtotal_no_gradient", style:subtotal_bold + 'width:' + dataWidth + '%'}});
			//row.push((get('previous',metric,null,null)==null)?{v:null, f:'&nbsp;', p:{className: "subtotal", style:'width:' + dataWidth + '%'}}:{v:get('previous',metric,null,null), f:(get('previous',metric,null,null)*100).toFixed(2) + '%', p:{className: getDataCellClassName('previous',metric,null,null) + " subtotal_no_gradient", style:'width:' + dataWidth + '%'}});
			//row.push((get('current',metric,null,null)==null)?{v:null, f:'&nbsp;', p:{className: "subtotal",style:'width:' + dataWidth + '%'}}:{v:get('current',metric,null,null), f:(get('current',metric,null,null)*100).toFixed(2) + '%', p:{className: getDataCellClassName('current',metric,null,null) + " subtotal_no_gradient", style:'width:' + dataWidth + '%'}});
			table_data.addRow(row);
			metricIds.push([null,null,
			                 get('previous',metric,null,'Americas','metricIds'),
			                 get('current',metric,null,'Americas','metricIds'),
			                 get('previous',metric,null,'Apac','metricIds'),
			                 get('current',metric,null,'Apac','metricIds'),
			                 get('previous',metric,null,'Emea','metricIds'),
			                 get('current',metric,null,'Emea','metricIds'),
			                 //get('previous',metric,null,null,'metricIds'),
			                 //get('current',metric,null,null,'metricIds'),
			                 ]);
		}
		
		google.visualization.events.addListener(table, 'ready', function () {
			
			var table = document.getElementById('summary').getElementsByClassName('google-visualization-table-table')[0];
			var header = document.createElement("tr");
			header.className = 'google-visualization-table-tr-head';
			header.innerHTML = '<th class="google-visualization-table-th gradient table-head">&nbsp</th>';
			header.innerHTML += '<th class="google-visualization-table-th gradient table-head">&nbsp</th>';
			header.innerHTML += '<th class="google-visualization-table-th gradient table-head" colspan="2">AMERICAs</th>';
			header.innerHTML += '<th class="google-visualization-table-th gradient table-head" colspan="2">APAC</th>';
			header.innerHTML += '<th class="google-visualization-table-th gradient table-head" colspan="2">EMEA</th>';
			//header.innerHTML += '<th class="google-visualization-table-th gradient" colspan="2">Overall</th>';
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
	            var metricsIds = metricIds[row][column];
	            
	            refreshDetails(metricsIds);
	        });
	        
	    });
		
		var table_view = new google.visualization.DataView(table_data);
		
		table.draw(table_view, summary_table_options);
		document.getElementById('summary_container').style.visibility = "visible";
		document.getElementById('summary_aside').style.visibility = "visible";
	}
}

function refreshDetails(metricsIds) {
	document.getElementById('details_container').style.visibility = "hidden";
	document.getElementById('details_notes').style.visibility = "hidden";
	loadingCount++;
	
	var url = "executiveDashboard?request=DETAILS&function=OPERATIONS&metricsIds=" + metricsIds;
	
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
		var uniqueRegion = slaResponseDetails[0].metric.regionDisplayName; 
		var uniqueProductPortfolio = slaResponseDetails[0].metric.productPortfolio; 
		var uniqueMetricGroup = slaResponseDetails[0].metric.metricGroup;
		for (var r = 1; r < slaResponseDetails.length; r++) {
			if (slaResponseDetails[r].metric.regionDisplayName != uniqueRegion) {
				uniqueRegion = null;
			}
			if (slaResponseDetails[r].metric.productPortfolio != uniqueProductPortfolio) {
				uniqueProductPortfolio = null;
			}
			if (slaResponseDetails[r].metric.metricGroup != uniqueMetricGroup) {
				uniqueMetricGroup = null;
			}
		}
		document.getElementById('details_header').innerHTML  = (uniqueRegion==null?"":(uniqueRegion + " - ")) + (uniqueProductPortfolio==null?"":(uniqueProductPortfolio + " - ")) + (uniqueMetricGroup==null?"":(uniqueMetricGroup + " - ")) + formatPeriodFromJavaCalendar(slaResponseDetails[0].period);
		
		var table_data = new google.visualization.DataTable();
		var table = new google.visualization.Table(document.getElementById("details"));
		
		table_data.addColumn('string', 'Region');
		//table_data.addColumn('string', 'Country');
		table_data.addColumn('string', 'Product Portfolio');
		table_data.addColumn('string', 'Metric'); 
		table_data.addColumn('string', 'Business Unit');
		//table_data.addColumn('string', 'Business Owner'); 
		table_data.addColumn('number', 'Service Level'); 
		table_data.addColumn('number', 'Target');
		table_data.addColumn('number', 'Volume');
		table_data.addColumn('number', 'Norm. Service Level');
		table_data.addColumn('number', 'Weight');
		//table_data.addColumn('string', 'Prepared By');
		//table_data.addColumn('string', 'Prepared Date');
		
		var detailsNotes = [];
		noteNo = 1;
		var slaValueEquivalent = 0, totalWeight = 0;
		for (var r = 0; r < slaResponseDetails.length; r++) {
			totalWeight += slaResponseDetails[r].weight;
		}
		for (var r = 0; r < slaResponseDetails.length; r++) {
			var metricDetails = slaResponseDetails[r];
			if (detailsNotes[metricDetails.metric.Id] == null) {
				//var metricTarget = formatDecimal(metricDetails.metric.valueTarget,2) + " " + metricDetails.metric.valueUnit; 
				//if (metricDetails.metric.valueUnit == '%')
				//	metricTarget = formatDecimal(metricDetails.metric.valueTarget*100,2) + " " + metricDetails.metric.valueUnit; 
				detailsNotes[metricDetails.metric.Id] = { 
						"noteNo": noteNo++,
						"note":
							//'<u>Metric definition</u>: ' + metricDetails.metric.valueDefinition + '</br>' +
							//'<u>Metric target</u>: ' + metricTarget + '</br>' +
							//'<u>Service Level definition</u>: ' + 
							metricDetails.metric.slaDefinition};
			}
			var row = [];
			row.push({v:metricDetails.regionDisplayName});
			//row.push({v:metricDetails.subRegion});
			row.push({v:metricDetails.productPortfolio});
			row.push({v:metricDetails.metric.metric, f:metricDetails.metric.metric + "<sup>(" + detailsNotes[metricDetails.metric.Id].noteNo + ")</sup>" });
			row.push({v:metricDetails.team});
			//row.push({v:metricDetails.businessOwner});
			row.push({v:metricDetails.slaValue, f:formatDecimal(metricDetails.slaValue*100,2) + "%", p:{className:"tdcenter " + getRAGCellClassNameFromValue(metricDetails.slaValue, metricDetails.targetAmber, metricDetails.targetGreen) }});
			row.push({v:metricDetails.targetGreen, f:formatDecimal(metricDetails.targetGreen*100,2) + "%", p:{className:"tdcenter"}});
			row.push({v:metricDetails.volume, f:metricDetails.volume + " " + metricDetails.metric.volumeUnit, p:{className:"tdcenter"}});
			row.push({v:metricDetails.slaValueEquivalent, f:formatDecimal(metricDetails.slaValueEquivalent*100,2) + "%", p:{className:"tdcenter " + getRAGCellClassNameFromValue(metricDetails.slaValueEquivalent)}});
			row.push({v:formatDecimal(metricDetails.weight/totalWeight*100,2), f:formatDecimal(metricDetails.weight/totalWeight*100,2) + '%', p:{className:"tdcenter"}});
			//row.push({v:metricDetails.preparedBy, p:{className:"tdcenter"}});
			//row.push({v:formatDatefromJavaCalendar(metricDetails.preparedDateTime,0), p:{className:"tdcenter"}});
			table_data.addRow(row);
			slaValueEquivalent += metricDetails.slaValueEquivalent*metricDetails.weight;
		}
		slaValueEquivalent = slaValueEquivalent/totalWeight;
		// Add Total
		table_data.addRow([
	                   {v:'Overall', p:{className:"total"}},
	                   //{v:'&nbsp;', p:{className:"total"}},
	                   {v:'&nbsp;', p:{className:"total"}},
	                   {v:'&nbsp;', p:{className:"total"}},
	                   {v:'&nbsp;', p:{className:"total"}},
	                   //{v:'&nbsp;', p:{className:"total"}},
	                   {v:0, f:'&nbsp;', p:{className:"total"}},
	                   {v:0, f:'&nbsp;', p:{className:"total"}},
	                   {v:0, f:'&nbsp;', p:{className:"total"}},
	                   {v:slaValueEquivalent, f:formatDecimal(slaValueEquivalent*100,2) + "%", p:{className:getRAGCellClassNameFromValue(slaValueEquivalent)+ " total tdcenter"}},
	                   {v:0, f:'&nbsp;', p:{className:"total"}},
	                   //{v:'&nbsp;', p:{className:"total"}},
	                   //{v:'&nbsp;', p:{className:"total"}}
	                   ]);
		
		var table_view = new google.visualization.DataView(table_data);
		
		table.draw(table_view, details_table_options);
		
		// Update Notes
		$("#details_notes_list").empty();
		for (var i=1; i<=countElements(detailsNotes); i++) {
			var detailNote = findNote(detailsNotes, i);
			$("#details_notes_list").append( '<li>' + detailNote.note + '</li>' );
		}
		
		document.getElementById('details_container').style.visibility = "visible";
		document.getElementById('details_notes').style.visibility = "visible";
	}
}

function findNote(detailsNotes, i) {
	for (var noteNo in detailsNotes) {
		if(detailsNotes[noteNo].noteNo==i)
			return detailsNotes[noteNo];
	}
	return null;
}

function countElements(arr) {
	var i = 0;
	for (var index in arr) {
		i++;
	}
	return i;
}

function getMetricGroupClassNameForRow(rowNo) {
	var r;
	for (r=Math.min(rowNo+1,slaResponseSummary.length-1); r<slaResponseSummary.length; r++) {
		if (slaResponseSummary[r][0] != slaResponseSummary[rowNo][0])
			break;
	}
	return '';//'rowspan_' + (r-rowNo); 
}

function getDataCellClassName(period,metric,product,region, targetAmber, targetGreen) {
	return 'dataCell ' + getRAGCellClassNameFromValue(get(period, metric, product, region));
}

function getRAGCellClassNameFromValue(v, targetAmber, targetGreen) {
	if (v == null)
		return '';
	if (targetAmber==null)
		targetAmber = slaResponseSummary.targetAmberEquivalent;
	if (targetGreen==null)
		targetGreen = slaResponseSummary.targetGreenEquivalent;
	if (v >= targetGreen)
		return 'Green';
	if (v >= targetAmber)
		return 'Amber';
	return 'Red';
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
	//xmlhttp.timeout = 20000;
	//xmlhttp.ontimeout = function () { alert("Timed out!!!"); }
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
			+ '/' + d.getFullYear();
}

function formatPeriodFromJavaCalendar(date) {
	var d = new Date(date.year, date.month, date.dayOfMonth, date.hourOfDay,date.minute, date.second, 0);
	return monthNames[d.getMonth()] + ' ' + d.getFullYear(); 
}

function formatPeriodFromString(dateString) {
	var parts =dateString.split('/');
	var d = new Date(parts[2], parts[1]-1, parts[0], 0,0, 0, 0);
	return monthNames[d.getMonth()] + ' ' + d.getFullYear(); 
}

function getPreviousPeriod() {
	var parts =periodDate.split('/');
	var d = new Date(parts[2],parts[1]-1,parts[0]);
	if (d.getMonth()==0)
		return d.getDate() + '/12/' + (d.getFullYear()-1);
	else
		return d.getDate() + '/' + d.getMonth() + '/' + d.getFullYear();
}
