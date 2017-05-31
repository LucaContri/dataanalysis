var response;
var val;
$(function() {
	var GET = {};
	var query = window.location.search.substring(1).split("&");
	for (var i = 0, max = query.length; i < max; i++)
	{
	    if (query[i] === "") // check for trailing & with no param
	        continue;

	    var param = query[i].split(/=(.+)?/);
	    
	    GET[decodeURIComponent(param[0])] = decodeURIComponent(param[1] || "");
	}
	if(GET.query && GET.datasource) {
		 $("#download").attr("href", "./reportServlet?query="+GET.query+"&datasource="+GET.datasource+"&action=download");
		 $.get("./reportServlet?query="+GET.query+"&datasource="+GET.datasource, function(r) {
         	response = r;
         	updateFilters();
         });
	} else {
	    $.get("./reportServlet?getReportsList=true", function(jsonList) {
	    		//$("#download").hide();
	    		$("#filters").hide();
	            var pkg = $("<optgroup>", {label: ""});
	            for(var i in jsonList)
	            {
	                var dataset = jsonList[i];
	                if(dataset.group != pkg.attr("label"))
	                {
	                    pkg = $("<optgroup>", {label: dataset.group}).appendTo($("#list"));
	                }
	                pkg.append($("<option>", {value: dataset.id}).text(dataset.group+":" +dataset.name));
	            }
	            $("#list").chosen();
	            $("#list").bind("change", function(event) {
	            	$("#download").hide();
	            	$("#preview").hide();
	            	val = $(this).val();
	                $.get("./reportServlet?getReport="+val, function(r) {
	                	response = r;
	                	updateFilters();
	                });
	            	
	        });
	    });  
	}
});

function updateFilters() {
	/*
	if(response.report.reportFilters) {
		var filterHint = 'Filter results by typing any ';
		for(i in response.report.reportFilters) {
			filterHint += response.report.reportFilters[i].name;
		}
    	// Display filters
		var val = $("#list").val();
    	$("#filters").show();
    	$("#filters")
    			.tokenInput(
    					"reports?getFiletersForReport="+val,
    					{
    						theme : "process",
    						hintText : filterHint
    					});
    	// Filters Change Update
		$("#parameters_input").change(function() {
			updatePreview();
		});
    } else {
    	updatePreview();
    }
    */
	updatePreview();
}

function updatePreview() {
	/*
	$("#loading").empty().text("Loading...");    
    $("#download").attr("href", "./reportServlet?downloadReport="+val);
    $("#download").show();
    var preview_table_data = new google.visualization.arrayToDataTable(response.preview);
	var preview_table = new google.visualization.Table(document.getElementById("preview"));
	
    preview_table.draw(preview_table_data, {
    	showRowNumber : false,
    	sort : 'enable',
    	allowHtml : true,
    	width : "100%"});
	$("#preview").show();
    $("#loading").empty();
    */
    updatePivot();
    $("#download").attr("href", "./reportServlet?downloadReport="+val);
    $("#download").show();
}

function updatePivot() {
	var renderers = $.extend(
        $.pivotUtilities.renderers, 
        $.pivotUtilities.c3_renderers, 
        $.pivotUtilities.d3_renderers, 
        $.pivotUtilities.export_renderers
        );

    $("#pivot").pivotUI(response.preview, {renderers: renderers}, true);
}