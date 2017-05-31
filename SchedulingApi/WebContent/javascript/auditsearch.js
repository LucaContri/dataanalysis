var apiResponse;
function focusInput() {
	$("#token-input-parameters_input").focus();
}
$(document).ready(function() {
		$("#parameters_input").tokenInput("resourcesList", {
			theme : "auditsearch",
			hintText : "Type any resources name, revenue ownerships and timeframe (optional, default to 5 months) (e.g. \"Haifeng Li\" \"AUS-Food-All\", \"Within 5 Months\")"
		});
		$("input[type=text]").focus();
	});

$(document)
		.ready(function() {$("input[type=text]")
			.change(
					function() {
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
							xmlhttp = new ActiveXObject(
									"Microsoft.XMLHTTP");
						}
						if ($(this).val().length >= 0) {
							var url = "wisearch?q="+ $(this).val();
							xmlhttp.open("GET", url, true);
							xmlhttp.onreadystatechange = function() {
						        if (xmlhttp.readyState == 4 && xmlhttp.status == 200) {
						        	apiResponse = JSON.parse(xmlhttp.responseText);
						        	if (apiResponse) {
										var table_data = new google.visualization.arrayToDataTable(apiResponse);
										var table = new google.visualization.Table(document.getElementById('audits_details'));

										table.draw(table_data,{
											showRowNumber : false,
											width : window.innerWidth * 0.95,
											sort : 'enable',
											allowHtml : true
										});
									}
						        	$.mobile.loading('hide');
						        }
						    };
							xmlhttp.send();							
						}
					});
			});