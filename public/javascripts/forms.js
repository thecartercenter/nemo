function form_recalc_ranks(box) {
  // get the clicked row and table body
  var clicked_row = box.parentNode.parentNode.parentNode;
  var tbody = clicked_row.parentNode;
  
  // get all the rows
  var rows = form_get_rows(tbody);
  
  // get the new and old ranks
  var old_rank = rows.indexOf(clicked_row) + 1;
  var new_rank = isNaN(parseInt(box.value)) ? old_rank : Math.max(1, Math.min(rows.length, parseInt(box.value)));

  // if ranks have changed, move rows
  if (old_rank != new_rank) {
    // get the new_rankth row in the table
    var target_row = rows[new_rank-1];
    
    // remove the clicked row
    tbody.removeChild(clicked_row);
  
    // insert the row above/beneath the target row
    if (new_rank < old_rank)
      tbody.insertBefore(clicked_row, target_row);
    else
      tbody.insertBefore(clicked_row, target_row.nextSibling);
    
    // get the updated rows
    rows = form_get_rows(tbody);
  }
    
  // fix numbers
  for (var i = 0; i < rows.length; i++)
    rows[i].firstChild.nextSibling.nextSibling.nextSibling.firstChild.nextSibling.firstChild.value = i + 1;
  
  // restore the focus
  box.focus()
}

function form_get_rows(tbody) {
  var rows = [];
  for (var i = 0; i < tbody.childNodes.length; i++)
    if (tbody.childNodes[i].tagName == "TR")
      rows.push(tbody.childNodes[i]);
  return rows;
}

function form_submit_ranks(form_id) {
  $('#batch_form')[0].action = "/forms/" + form_id + "/update_ranks";
  $('#batch_form')[0].submit();
}

(function (Form, undefined) {
  Form.print = function(form_id) {
    // show appropriate loading indicator
    $('#index_table_loading_indicator_' + form_id).show();

    // load form show page into div
    Utils.ajax_with_session_timeout_check({
      url: "/forms/" + form_id,
      method: "get",
      data: {print: 1},
      success: function(data) {
        // replace div contents
        $('#form_to_print').html(data);
        
        // hide loading indicator
        $('#index_table_loading_indicator_' + form_id).hide();
        
        // show print dialog
        window.print();
      }
    });

  }
}(Form = {}));