(function (Form, undefined) {
  
  // private flag var for reminding to save
  var ranks_changed = false;
  
  Form.hookup_rank_boxes = function() {
    // hookup boxes themselves
    $("input.rank_box").change(Form.recalc_ranks);
    
    // hookup submit button
    $("input.submit").click(Form.submit_form);

    // hookup before submit event
    $("form.form_form").submit(Form.before_submit);

    
    // hookup unsaved check
    $(window).bind('beforeunload', function() {
      if (ranks_changed)
        return 'You have not yet saved the changes you made to the question order. ' + 
          'You should click the \'Save Ranks\' button if you want to save these changes.';
    });
  }
  
  Form.recalc_ranks = function(e) {
    // get the clicked row and table body
    var changed_box = e.target;
    var clicked_row = e.target.parentNode.parentNode.parentNode;
    var tbody = clicked_row.parentNode;

    // get all the rows
    var rows = $(tbody).children("tr");

    // get the new and old ranks
    var old_rank = $.inArray(clicked_row, rows) + 1;
    var new_rank = isNaN(parseInt(changed_box.value)) ? old_rank : Math.max(1, Math.min(rows.length, parseInt(changed_box.value)));
    
    // if ranks have changed, move rows
    if (old_rank != new_rank) {
      
      // set flag
      ranks_changed = true;
      
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
      rows = $(tbody).children("tr");
    }

    // update numbers
    var boxes = $("input.rank_box");
    for (var i = 0; i < boxes.length; i++) boxes[i].value = i + 1;

    // restore the focus
    changed_box.focus()
  }
  
  // submits the form when the submit button is clicked
  Form.submit_form = function() {
    $("form.form_form").submit();
  }
  
  Form.before_submit = function() {
    // unset flag so that beforeunload event is not triggered
    ranks_changed = false;
    
    // copy ranks into main form
    var hidden_div = $("<div>").hide();                     // this bit makes sure the updated values get copied
    $("input.rank_box").each(function(){ hidden_div.append($(this.outerHTML).val($(this).val())); });
    $("form.form_form").append(hidden_div);
    
    // allow submission to proceed
    return true;
  }
  
  Form.print = function(form_id) {
    // show appropriate loading indicator
    $('#loading_indicator_' + form_id).show();

    // load form show page into div
    Utils.ajax_with_session_timeout_check({
      url: "/forms/" + form_id,
      method: "get",
      data: {print: 1},
      success: function(data) {
        // replace div contents
        $('#form_to_print').html(data);
        
        // hide loading indicator
        $('#loading_indicator_' + form_id).hide();
        
        // show print dialog
        window.print();
      }
    });

  }
}(Form = {}));

$(document).ready(Form.hookup_rank_boxes);