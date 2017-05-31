// Data
var apiResponse;
var pageNo = 0;

// Visualizations Options

$(document)
		.ready(
				function() {
					loadData();
				});

function loadData() {	
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
	var url = "allocatorOutputTableServlet?batchId=UK%20Forward%20Planning&pageSize=100&pageNo=" + pageNo++;
	xmlhttp.open("GET", url, true);
	xmlhttp.onreadystatechange = function() {
        if (xmlhttp.readyState == 4 && xmlhttp.status == 200) {
        	apiResponse = JSON.parse(xmlhttp.responseText);
        	//if (apiResponse.errorMessage != null && apiResponse.errorMessage.length > 0) {
    		//	document.getElementById('messages').innerHTML = apiResponse.errorMessage;
    		//	document.getElementById("messages").style.visibility = "visible";
    		//}
        	updateTable();
        	$.mobile.loading('hide');
        }
    };
	xmlhttp.send();	
}

function updateTable() {
	if(apiResponse != null) {
		var title = document.getElementById("title");
		var subtitle = document.getElementById("subtitle");
		title.innerHTML = "Resource Allocator Output - " + "Batch: <i>" + apiResponse.name + "</i>";
		subtitle.innerHTML = "Last Update: <i>" + formatUTCDateToLocale(apiResponse.created) + "</i> - Next Update: <i>" + formatUTCDateToLocale(apiResponse.nextUpdate) + "</i>";
		
		var table = document.getElementById("wiTable");
		for (var i = 0; i < apiResponse.events.length; i++) { 
			// Create an empty <tr> element and add it to the 1st position of the table:
			var row = table.insertRow(-1);

			// Insert new cells (<td> elements) at the 1st and 2nd position of the "new" <tr> element:
			var client = row.insertCell(0);
			var wi = row.insertCell(1);
			var auditType = row.insertCell(2);
			var standard = row.insertCell(3);
			var resource = row.insertCell(4);
			var workType = row.insertCell(5);
			var startDate = row.insertCell(6);
			var endDate = row.insertCell(7);
			var notes = row.insertCell(8);

			client.innerHTML = apiResponse.events[i].site;
			wi.innerHTML = '<a href="https://saicompass.my.salesforce.com/' + apiResponse.events[i].wiId + '" target="_blank">' + apiResponse.events[i].wi + "</a>";
			auditType.innerHTML = apiResponse.events[i].wiType;
			standard.innerHTML = apiResponse.events[i].primaryStandard;
			resource.innerHTML = apiResponse.events[i].resource + " (" + apiResponse.events[i].resourceType + ")";
			workType.innerHTML = apiResponse.events[i].subType;
			startDate.innerHTML = formatDate(apiResponse.events[i].startDate) + " " + apiResponse.events[i].timeZoneSidKey;  
			endDate.innerHTML = formatDate(apiResponse.events[i].endDate) + " " + apiResponse.events[i].timeZoneSidKey;
			notes.innerHTML = apiResponse.events[i].notes + '</br><a href="https://maps.google.com?saddr=' + apiResponse.events[i].resourceLocation + '&daddr=' + apiResponse.events[i].siteLocation + '" target="_blank">Directions</a>';
		}
		filter();
		if (apiResponse.more)
			loadData();
	}
}

function clearFilters() {
	document.getElementById("searchClient").value = '';
	document.getElementById("searchWI").value = '';
	document.getElementById("searchAuditType").value = '';
	document.getElementById("searchStandard").value = '';
	document.getElementById("searchResource").value = '';
	document.getElementById("searchStartDate").value = '';
	filter();
}

function filter() {
  $.mobile.loading('show', {
	text: 'Loading',
	textVisible: true,
	theme: 'a',
	html: ""
  });
  // Declare variables 
  var 
  	inputClient, inputWi, inputAuditType, inputStandard, inputResource, inputStartDate, 
  	filterClient, filterWi, filterAuditType, filterStandard, filterResource, filterStartDate, table, tr, 
  	tdClient, tdWi, tdAuditType, tdStandard, tdResource, tdStartDate, i;
  inputClient = document.getElementById("searchClient");
  filterClient = inputClient.value.toUpperCase();
  inputWi = document.getElementById("searchWI");
  filterWi = inputWi.value.toUpperCase();
  inputAuditType = document.getElementById("searchAuditType");
  filterAuditType = inputAuditType.value.toUpperCase();
  inputStandard = document.getElementById("searchStandard");
  filterStandard = inputStandard.value.toUpperCase();
  inputResource = document.getElementById("searchResource");
  filterResource = inputResource.value.toUpperCase();
  inputStartDate = document.getElementById("searchStartDate");
  filterStartDate = inputStartDate.value.toUpperCase();
  table = document.getElementById("wiTable");
  tr = table.getElementsByTagName("tr");

  // Loop through all table rows, and hide those who don't match the search query
  for (i = 0; i < tr.length; i++) {
	tdClient = tr[i].getElementsByTagName("td")[0];
    tdWi = tr[i].getElementsByTagName("td")[1];
    tdAuditType = tr[i].getElementsByTagName("td")[2];
    tdStandard = tr[i].getElementsByTagName("td")[3];
    tdResource = tr[i].getElementsByTagName("td")[4];
    tdStartDate = tr[i].getElementsByTagName("td")[6];
    if (tdClient && tdWi && tdAuditType && tdStandard && tdResource && tdStartDate) {
      if ((tdClient.innerHTML.toUpperCase().indexOf(filterClient) > -1) &&
		  (tdWi.innerHTML.toUpperCase().indexOf(filterWi) > -1) &&
		  (tdAuditType.innerHTML.toUpperCase().indexOf(filterAuditType) > -1) &&
		  (tdStandard.innerHTML.toUpperCase().indexOf(filterStandard) > -1) &&
		  (tdResource.innerHTML.toUpperCase().indexOf(filterResource) > -1) &&
		  (tdStartDate.innerHTML.toUpperCase().indexOf(filterStartDate) > -1)) {
        tr[i].style.display = "";
      } else {
        tr[i].style.display = "none";
      }
    } 
  }
  $.mobile.loading('hide');
}

function formatDate(date) {
	return zeroPad(date.dayOfMonth,2) + "/" + zeroPad(date.month+1,2) + "/" + date.year + " - " +zeroPad(date.hourOfDay,2) + ":" + zeroPad(date.minute,2);; 
}

function formatJSDate(date) {
	return zeroPad(date.getDate(),2) + "/" + zeroPad(date.getMonth()+1,2) + "/" + date.getFullYear() + " - " +zeroPad(date.getHours(),2) + ":" + zeroPad(date.getMinutes(),2) + " " + Intl.DateTimeFormat().resolvedOptions().timeZone; 
}

function formatUTCDateToLocale(date) {
	d = new Date();
	d.setUTCFullYear(date.year);
	d.setUTCMonth(date.month);
	d.setUTCDate(date.dayOfMonth);
	d.setUTCHours(date.hourOfDay);
	d.setUTCMinutes(date.minute);
	d.setUTCSeconds(date.second);
	
	return formatJSDate(d); 
}

function zeroPad(num, places) {
  var zero = places - num.toString().length + 1;
  return Array(+(zero > 0 && zero)).join("0") + num;
}