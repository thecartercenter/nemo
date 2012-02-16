(function (report, undefined) {
  // === PRIVATE ===
  var RERUN_FIELDS = ["kind", "filter", "pri_grouping", "sec_grouping"];
  var params_at_last_save = {};
  var params_at_last_submit = {};
  
  // === PUBLIC ===
  
  // public methods and properties  
  report.obj = {};
  report.form = {};

  // initializes things
  report.init = function() {
    // save params
    load_current_params(params_at_last_save);
    load_current_params(params_at_last_submit);
    
    // hook up buttons
    $('#report_report_view_and_save').click(function(){view(true); return false;});
    $('#report_report_view').click(function(){view(false); return false;});
    $('#edit_form_link').click(function(){report.toggle_form(); return false;});
    
    // hook up unsaved check
    $(window).bind('beforeunload', function() {
      if (save_required())
        return 'This report has unsaved changes. Are you sure you want to go to another page without saving?';
    });
    
    // redraw report
    redraw();
  }
  
  // shows/hides the edit form
  report.toggle_form = function() {
    $('#report_form').toggle();
    $('#edit_form_link').text($('#report_form').is(":visible") ? "Hide Edit Controls" : "Edit This Report")
  }
  
  report.show_success = function() {
    Utils.show_flash({type: "success", msg: "Report saved successfully.", hide_after: 3})
  }
  
  // === PRIVATE ===
  
  // decides whether to contact the server and redraws the report
  // save - whether the changes should be saved or only displayed
  function view(save) {
    // if save or rerun is required, send to server
    // otherwise just redraw
    var rerun = report.obj.errors || !report.obj.has_run || rerun_required();
    if (rerun || save)
      submit_to_server({save: save})
    else
      redraw();
  }

  // sends the report parameters to the server via ajax
  // options include:
  //   save: whether the parameters should be saved or not
  function submit_to_server(options) {
    var form = $('#report_form form');
    
    // save the current parameters
    load_current_params(params_at_last_submit);
    
    // show the loading indicator
    $("#report_form div.loader").show();
    
    $.ajax({
      type: 'POST',
      url: form.attr("action"),
      data: form.serialize() + "&save=" + !!options.save,
      success: function(data, status, jqxhr) {
        // if new data returned, save it
        if ($.type(data) == "object") report.obj = data;
        
        // show success or error message
        if (report.obj.errors)
          Utils.show_flash({type: "error", msg: report.obj.errors})
        else if (options.save) {
          // if we're currently on the 'new' page, redirect to 'edit'
          if (window.location.pathname.match(/reports\/new/)) {
            window.location.href = "/report/reports/" + report.obj.id + "/edit?show_success=1";
            return;
          } else {
            // save the params
            params_at_last_save = $.extend({}, params_at_last_submit);
            
            // show the successful save message
            report.show_success();
          }
        } else
          Utils.clear_flash()
        
        // always redraw on successful server request
        redraw();
        
        // hide the loading indicator
        $("#report_form div.loader").hide();
      },
      error: function(jqxhr, status, error) {
        // display error
        Utils.show_flash({type: "error", msg: "Unknown error."})

        // hide the loading indicator
        $("#report_form div.loader").hide();
      }
    })
  }

  // redraws the report
  function redraw() {
    // load current settings from form
    load_current_params(report.form);
  
    // if report has errors, don't show anything
    if (report.obj.errors) {
      $('#report_body').empty().text("Could not display report due to an error.")

    // if report has never been successfully run, direct user to controls
    } else if (!report.obj.has_run) {
      $('#report_body').empty().text("Please use the controls on the left to create this report.");
      
    // if no data, say so
    } else if (report.obj.data == null) {
      $('#report_body').empty().text("No matching data were found. Try adjusting the filter parameter.");

    } else {
    
      var tbl = $("<table>");
    
      // header row (only print if is at least one grouping)
      if (has_groupings()) {
        var trow = $("<tr>");
    
        // blank cell in corner
        $("<th>").appendTo(trow);
    
        // rest of header cells
        $(report.obj.headers.col).each(function(idx, ch) {
          $("<th>").addClass("col").text(ch || "[Null]").appendTo(trow);
        });
        tbl.append(trow);
      }
    
      // row total header
      if (show_totals("row"))
        $("<th>").addClass("row_total").text("Total").appendTo(trow);
      
      // body
      $(report.obj.headers.row).each(function(r, rh) {
        trow = $("<tr>");
      
        // row header
        $("<th>").addClass("row").text(rh || "[Null]").appendTo(trow);
      
        // row cells
        $(report.obj.headers.col).each(function(c, ch) {
          $("<td>").text(report.obj.data[r][c] || "").appendTo(trow);
        });
      
        // row total
        if (show_totals("row"))
          $("<td>").addClass("row_total").text(report.obj.totals["row"][r]).appendTo(trow);

        tbl.append(trow);
      });
    
      // footer
      if (show_totals("col")) {
        trow = $("<tr>");
      
        // row header
        $("<th>").addClass("row").addClass("col_total").text("Total").appendTo(trow);
      
        // row cells
        $(report.obj.totals.col).each(function(c, ct) {
          $("<td>").addClass("col_total").text(ct > 0 ? ct : "").appendTo(trow);
        });
      
        // row total
        if (show_totals("row"))
          $("<td>").addClass("row_total").addClass("col_total").text((gt = report.obj.grand_total) > 0 ? gt : "").appendTo(trow);

        tbl.append(trow);
      }
    
      $('#report_body').empty().append(tbl);
    }

    // update the title
    set_title();
  }
  
  // checks whether total rows should be shown for a table report
  function show_totals(row_or_col) {
    return (row_or_col == "row") ? report.form.sec_grouping : report.form.pri_grouping
  }
  
  // updates the title of the report
  function set_title() {
    // set title
    $("#content h1").text(report.form.name);
  }
  
  function load_current_params(target) {
    var fields = {
      kind: "kind", 
      name: "name",
      pri_grouping: "pri_grouping_attributes_form_choice",
      sec_grouping: "sec_grouping_attributes_form_choice", 
      filter: "filter_attributes_str"
    }
    $.each(fields, function(attr, id){target[attr] = $("#report_report_" + fields[attr]).val();});
  }
  
  // checks if a re-run of the report is needed
  function rerun_required() {
    var cur_params = {};
    load_current_params(cur_params);
    
    var cp = param_diff(params_at_last_submit, cur_params);
    
    // check all changed params to see if any is in rerun_fields list
    for (var i = 0; i < cp.length; i++) 
      if (RERUN_FIELDS.indexOf(cp[i]) != -1)
          return true;
    
    // return false if get to this point
    return false;
  }
  
  // checks if any params have changed since last save
  function save_required() {
    var cur_params = {};
    load_current_params(cur_params);
    return param_diff(params_at_last_save, cur_params).length != 0;
  }
  
  // compares two sets of parameters
  function param_diff(a,b) {
    var changed_keys = [];
    
    // for each parameter, if it has changed, add it to array
    for (var k in a)
      if (a[k] != b[k])
        changed_keys.push(k);
    
    return changed_keys;
  }
  
  // checks if the report has no groupings
  function has_groupings() {
    return report.form.pri_grouping || report.form.sec_grouping
  }

  // sends the report parameters to the server
  // along with an indication if the report should be run and/or if it should be saved 
  // if re-run is requested, report is redrawn on request completion
  // if request results in error, it is displayed and report is not redrawn
  function send() {
  
  }
}(report = {}));