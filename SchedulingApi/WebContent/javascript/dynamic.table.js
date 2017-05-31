var months_names = new Array("January", "February", "March", 
"April", "May", "June", "July", "August", "September", 
"October", "November", "December");

var dynamicTable = (function() {
    
    var _tableId, _table, 
        _fields, _headers, 
        _defaultText;
    
    function _buildSubHeader(names, item) {
    	var row = '';
    	if (names && names.length > 0) {
    		row = '<tr>';
	    	$.each(names, function(index, name) {
	    		row += '<th class="resources">';
        		if (name=='periods') {
        			row += '<table class="days">';
        			row += '<tr class="resources">';
        			for(var period in item[name+'']) {
        				row += '<th class="days">' + months_names[item[name+''][period].name.substring(5,7)-1]  + ' ' + item[name+''][period].name.substring(0,4) + '</th>';
        			}
        			row += '</tr>';
        			row += '</table>';
        		}
        		row += '</th>';
	    	});
    		row += '</tr>';
    	}
		return row;
    }
   
    /** Builds the row with columns from the specified names. 
     *  If the item parameter is specified, the memebers of the names array will be used as property names of the item; otherwise they will be directly parsed as text.
     */
    function _buildRowColumns(names, item) {
    	 var row = '';
	        if (names && names.length > 0) {
	        	row = '<tr class="resources">';
	            $.each(names, function(index, name) {
	            	if (item) {
	            		row += '<td class="resources">';
	            		if (name=='periods') {
		                	row += '<table class="days">';
				        	row += '<tr class="days">';
				        	for(var period in item[name+'']) {
				        		
				        		row += '<td class="days">';
				        		var eventArray = new Array();
			        			for(var day in item[name+''][period].days) {
			        				//row += item[name+''][period].days[day] + '&nbsp\n';
			        				eventArray.push(['Y', item[name+''][period].name.substring(5,7), item[name+''][period].days[day], item[name+''][period].name.substring(0,4), '1:00 AM', '12:00 PM', '', '']);
			        			}
				        		row += getCalendarWithEventsHtml(item[name+''][period].name.substring(5,7), item[name+''][period].name.substring(0,4), eventArray);
				        		row += '</td>';				        	
				        	}
							row += '</tr>';
							row += '</table>';
		                } else {
		            		var c = item[name+''];
		                	row += c;
		                }
		                row += '</td>';
	            	} else {
	            		row += '<th class="resources">' + name + '</th>';
	            	}
	            });
	            row += '</tr>';
	        }
        return row;
    }
    
    /** Builds and sets the headers of the table. */
    function _setHeaders() {
        // if no headers specified, we will use the fields as headers.
        _headers = (_headers == null || _headers.length < 1) ? _fields : _headers; 
        var h = _buildRowColumns(_headers);
        if (_table.children('thead').length < 1) _table.prepend('<thead></thead>');
        _table.children('thead').html(h);
    }
    
    function _setNoItemsInfo() {
        if (_table.length < 1) return; //not configured.
        var colspan = _headers != null && _headers.length > 0 ? 
            'colspan="' + _headers.length + '"' : '';
        var content = '<tr class="no-items"><td ' + colspan + ' style="text-align:center">' + 
            _defaultText + '</td></tr>';
        if (_table.children('tbody').length > 0)
            _table.children('tbody').html(content);
        else _table.append('<tbody>' + content + '</tbody>');
    }
    
    function _removeNoItemsInfo() {
        var c = _table.children('tbody').children('tr');
        if (c.length == 1 && c.hasClass('no-items')) _table.children('tbody').empty();
    }
    
    return {
        /** Configres the dynamic table. */
        config: function(tableId, fields, headers, defaultText) {
            _tableId = tableId;
            _table = $('#' + tableId);
            _fields = fields || null;
            _headers = headers || null;
            _defaultText = defaultText || 'No items to list...';
            _setHeaders();
            _setNoItemsInfo();
            return this;
        },
        /** Loads the specified data to the table body. */
        load: function(data, append) {
            if (_table.length < 1) return; //not configured.
            _setHeaders();
            _removeNoItemsInfo();
            if (data && data.length > 0) {
                var rows = '';
                $.each(data, function(index, item) {
                	if (index==0) {
	            		rows += _buildSubHeader(_fields, item);
                	}
                    rows += _buildRowColumns(_fields, item);
                });
                var mthd = append ? 'append' : 'html';
                _table.children('tbody')[mthd](rows);
            }
            else {
                _setNoItemsInfo();
            }
            return this;
        },
        /** Clears the table body. */
        clear: function() {
            _setNoItemsInfo();
            return this;
        }
    };
}());
