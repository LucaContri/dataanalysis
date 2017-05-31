// Data
var apiResponse;
var pageNo = 0;
var dp;

// Visualizations Options

$(document)
		.ready(
				function() {
					loadData();
				});

function addEvents() {
	// generate and load events
    for (var i = 0; i < apiResponse.events.length; i++) {
    	var colour = "#ffd5d5";
        if(apiResponse.events[i].type == "BOP")
        	colour = "#adad85";
        if(apiResponse.events[i].type == "ALLOCATOR") {
        	colour = "#5cd65c";
        	if (apiResponse.events[i].subType == "TRAVEL")
        		colour = "#c2f0c2";
    	}
        if(apiResponse.events[i].type == "COMPASS") {
        	colour = "#809fff";
        	if (apiResponse.events[i].subType == "Follow Up")
        		colour = "#e6ecff";
        }
        
        var e = new DayPilot.Event({
            start: new DayPilot.Date(formatDate(apiResponse.events[i].startDate)),
            end: new DayPilot.Date(formatDate(apiResponse.events[i].endDate)),
            id: apiResponse.events[i].eventId,
            resource: apiResponse.events[i].resourceId,
            text: apiResponse.events[i].wi,
            backColor: colour,
            type: apiResponse.events[i].type,
            subType: apiResponse.events[i].subType,
            site: apiResponse.events[i].site,
            auditor: apiResponse.events[i].resource,
            auditorLocation: apiResponse.events[i].resourceLocation,
            returnDistance: apiResponse.events[i].returnDistance,
            returnTravelTime: apiResponse.events[i].returnTravelTime,
            startText:formatDate2(apiResponse.events[i].startDate),
            endText: formatDate2(apiResponse.events[i].endDate),
            bubbleHtml: 
            	apiResponse.events[i].wi + " (" + apiResponse.events[i].type + " - " + apiResponse.events[i].subType + ")</br>" +
	    		"Site: " + apiResponse.events[i].site + "</br>" +
	    		"Auditor: " + apiResponse.events[i].resource + "</br>" +
	    		"Auditor Location: " + apiResponse.events[i].resourceLocation + "</br>" +
	    		"Return Distance (km): " + apiResponse.events[i].returnDistance + "</br>" +
	    		"Return Travel Time (hr): " + apiResponse.events[i].returnTravelTime + "</br>" +
	    		"Start: " + formatDate2(apiResponse.events[i].startDate) + "</br>" +
	    		"End: " + formatDate2(apiResponse.events[i].endDate)
        });
        
        dp.events.add(e);
    }	
    if(apiResponse.more)
    	loadData();
    else
    	dp.init();
}

function drawSchedule() {
	if (dp == null) {
		var title = document.getElementById("logo");
		title.innerHTML = apiResponse.name;
		var subtitle = document.getElementById("claim");
		subtitle.innerHTML = "Last Updated: <i>" + formatDate2(apiResponse.created) + " UTC</i>";
		
	    dp = new DayPilot.Scheduler("dp");
	
	    // view
	    dp.startDate = new DayPilot.Date(formatDate(apiResponse.startDate));  // or just dp.startDate = "2013-03-25";
	    dp.endDate = new DayPilot.Date(formatDate(apiResponse.endDate));  // or just dp.startDate = "2013-03-25";
	    dp.cellGroupBy = "Month";
	    dp.days = 300;
	    dp.cellDuration = 1440; // one day
	    
	    dp.moveBy = 'Full';
	    
	    dp.timeHeaders = [
	        { groupBy: "Month" },
	        { groupBy: "Week" },
	        { groupBy: "Cell", format: "d" }
	    ];
	    dp.scale = "Day";
	
	    // bubble, sync loading
	    // see also DayPilot.Event.data.staticBubbleHTML property
	    dp.bubble = new DayPilot.Bubble();
	
	    dp.contextMenu = new DayPilot.Menu({items: [
		    	{text:"Show event ID", onclick: function() {alert("Event value: " + this.source.value());} },
		    	{text:"Show event text", onclick: function() {alert("Event text: " + this.source.text());} },
		    	{text:"Show event start", onclick: function() {alert("Event start: " + this.source.start().toStringSortable());} },
		    	//{text:"Go to Compass:", href: "https://saicompass.my.salesforce.com/"+this.source.value()}
		    	
		    ]});
	
	    dp.treeEnabled = true;
	    dp.rowHeaderWidth = 200;
	    dp.cellWidth = 70;
	    dp.resources = apiResponse.resources;
	
	    dp.eventHoverHandling = "Bubble";
	    
	    dp.onBeforeEventRender = function(args) {
	    	//args.e.bubbleHtml = args.e.text;
	    };
	    
	    // event moving
	    dp.onEventMoved = function (args) {
	    	//dp.message("Moved: " + args.e.text());
	    };
	
	    // event resizing
	    dp.onEventResized = function (args) {
	    	//dp.message("Resized: " + args.e.text());
	    };
	
	    // event creating
	    dp.onTimeRangeSelected = function (args) {
	        //var name = prompt("New event name:", "Event");
	        //dp.clearSelection();
	        //if (!name) return;
	        //var e = new DayPilot.Event({
	        //    start: args.start,
	    	//    end: args.end,
	    	//    id: DayPilot.guid(),
	    	//    resource: args.resource,
	    	//    text: name
	    	//});
	    	//dp.events.add(e);
	    	//dp.message("Created");
	    };
	    
	    dp.onEventClicked = function(args) {
	        alert("Name: " + args.e.text() + " (" + args.e.data.type + " - " + args.e.data.subType + ")\n" +
	        		"Site: " + args.e.data.site + "\n" +
	        		"Auditor: " + args.e.data.auditor + "\n" +
	        		"Auditor Location: " + args.e.data.auditorLocation + "\n" +
	        		"Return Distance (km): " + args.e.data.returnDistance + "\n" +
	        		"Return Travel Time (hr): " + args.e.data.returnTravelTime + "\n" +
	        		"Type: " + args.e.data.type + "\n" +
	        		"Start: " + args.e.data.startText + "\n" +
	        		"End: " + args.e.data.endText
	        	);
	    };
	    
	    dp.onTimeHeaderClick = function(args) {
	        //alert("clicked: " + args.header.start);
	    };
	}
	addEvents();
	
}

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
	
	var url = "allocatorOutputServlet?batchId=UK%20Forward%20Planning&pageSize=100&pageNo=" + pageNo++;
	xmlhttp.open("GET", url, true);
	xmlhttp.onreadystatechange = function() {
        if (xmlhttp.readyState == 4 && xmlhttp.status == 200) {
        	apiResponse = JSON.parse(xmlhttp.responseText);
        	//if (apiResponse.errorMessage != null && apiResponse.errorMessage.length > 0) {
    		//	document.getElementById('messages').innerHTML = apiResponse.errorMessage;
    		//	document.getElementById("messages").style.visibility = "visible";
    		//}
        	drawSchedule();
        	$.mobile.loading('hide');
        }
    };
	xmlhttp.send();
	
}

function formatDate(date) {
	//2013-03-25T00:00:00
	var ret = date.year + "-" + zeroPad(date.month+1,2) + "-" + zeroPad(date.dayOfMonth,2) + "T" +zeroPad(date.hourOfDay,2) + ":" + zeroPad(date.minute,2) + ":" + zeroPad(date.second,2);
	return ret; 
}

function formatDate2(date) {
	var ret = zeroPad(date.dayOfMonth,2) + "/" + zeroPad(date.month+1,2) + "/" + date.year + " @ " +zeroPad(date.hourOfDay,2) + ":" + zeroPad(date.minute,2);
	return ret; 
}

function zeroPad(num, places) {
	  var zero = places - num.toString().length + 1;
	  return Array(+(zero > 0 && zero)).join("0") + num;
	}