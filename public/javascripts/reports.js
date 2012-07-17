(function (report, undefined) {
  // === PRIVATE ===
  var RERUN_FIELDS = ["aggregation", "fields", "filter", "unreviewed", "unique_rows", "pri_grouping", "sec_grouping"];
  var ROW_COL_PERCENT_TYPE_OPTIONS = ["Percentage By Row", "Percentage By Column"];
  var FIELD_SELECTS_SELECTOR = "#report_form #fields #field_dropdowns"
  var ALLOWED_DATA_TYPES_PER_AGGREGATION = {
    "Average": ["integer", "decimal"],
    "Minimum": ["integer", "decimal", "text", "datetime", "date", "time"],
    "Maximum": ["integer", "decimal", "text", "datetime", "date", "time"],
    "Sum": ["integer", "decimal"]
  }
  var HELP_WIDTH = 200;
  var params_at_last_save = {};
  var params_at_last_submit = {};
  var field_choice_hash = {};
  
  // === PUBLIC ===
  
  // public methods and properties  
  report.obj = {};
  report.form = {};

  // initializes things
  report.init = function() {
    // save params
    load_params_from_form(params_at_last_save);
    load_params_from_form(params_at_last_submit);
    
    // build field choice hash
    $.each(report.obj.field_choices, function (fcs_idx, choice_set) {
      $.each(choice_set.choices, function (c_idx, choice) { field_choice_hash[choice.full_id] = choice; });
    });
    
    // hook up buttons and links
    $('#report_report_save').click(function(){view(true); return false;});
    $('#report_report_preview').click(function(){view(false); return false;});
    $('#edit_form_link').click(function(){report.toggle_form(); return false;});
    $('a#show_help').click(function(){report.toggle_help(); return false;});
    $('a.add_field').click(function(){add_field(); return false;});
    
    // hook up important form controls to watch for changes
    $('#report_report_aggregation_id').change(function(){form_changed("aggregation")});
    $('#report_report_pri_grouping_attributes_form_choice').change(function(){form_changed("pri_grouping")});
    $('#report_report_sec_grouping_attributes_form_choice').change(function(){form_changed("sec_grouping")});
    $('#report_report_display_type').change(function(){form_changed("display_type")});

    hookup_field_events();
    
    // hook up unsaved check
    $(window).bind('beforeunload', function() {
      if (save_required())
        return 'This report has unsaved changes. Are you sure you want to go to another page without saving?';
    });
    
    // ensure the correct labels per display type
    form_changed("_all");
    
    // redraw report
    redraw();
  }
  
  // on init, loop over all fields and add controls for them by cloning the original one
  
  // shows/hides the edit form
  report.toggle_form = function() {
    $('#report_form').toggle();
    $('#edit_form_link').text($('#report_form').is(":visible") ? "Hide Edit Controls" : "Edit This Report")
  }
  
  // shows/hides the help text
  report.toggle_help = function() {
    // determine if showing or hiding
    var showing = !!$('a#show_help').text().match(/Show/);

    // adjust width
    var w = $('div.form_field').width();
    $('div.form_field').width(w + (showing ? 1 : -1) * HELP_WIDTH);

    // show/hide text
    $('div.form_field_details, div.help')[showing ? "show" : "hide"]();
    
    // change link text
    $('a#show_help').text((showing ? "Hide" : "Show") + " Help")
  }
  
  report.show_success = function() {
    Utils.show_flash({type: "success", msg: "Report saved successfully.", hide_after: 3})
  }
  
  // === PRIVATE ===
  
  function add_field() {
    // copy the existing box and select the appropriate record
    $(FIELD_SELECTS_SELECTOR + ' > div:first').clone().appendTo(FIELD_SELECTS_SELECTOR);
    $(FIELD_SELECTS_SELECTOR + ' > div:last select').val("");
    hookup_field_events();
    form_changed("fields");
  }
  
  function remove_field(e) {
    var existing = $(FIELD_SELECTS_SELECTOR + " select");
    // don't remove the last field
    if (existing.length == 1)
      existing.val("");
    else
      $(e.target).parent().remove();
    form_changed("fields");
  }
  
  // ensures the appropriate events are hooked up for all field dropdowns
  function hookup_field_events() {
    $(FIELD_SELECTS_SELECTOR + ' a.remove_field').unbind('click');
    $(FIELD_SELECTS_SELECTOR + ' a.remove_field').click(function(e) {remove_field(e); return false;});
    $(FIELD_SELECTS_SELECTOR + ' select').unbind('change');
    $(FIELD_SELECTS_SELECTOR + ' select').change(function(){form_changed("fields");})
  }
  
  function form_changed(src) {
    // get the latest form params
    load_params_from_form(report.form);
    
    // shortcuts
    var agg = report.form.aggregation;
    var disp_type = report.form.display_type;
    
    if (src == "aggregation" || src == "_all") {
      // show/hide fields
      $("div#fields")[agg != "" && agg != "Tally" ? "show" : "hide"]();
      
      // show pri grouping as long as agg is not list or blank
      show_or_hide_and_clear_select_field("div#pri_grouping", agg != "" && agg != "List");
    }
    
    if (src == "aggregation" || src == "fields" || src == "_all") {
      
      // remove other boxes if not a list and first box is attrib or qtype
      var not_list_and_first_is_attrib_or_qtype = agg != "List" && $(FIELD_SELECTS_SELECTOR + " select").val().match(/^(attrib|qtype)_/)
      if (not_list_and_first_is_attrib_or_qtype)
        $(FIELD_SELECTS_SELECTOR + " div").each(function (i, div){if (i != 0) $(div).remove()});
        
      // show/hide add field link
      $("a.add_field")[!not_list_and_first_is_attrib_or_qtype ? "show" : "hide"]();
      
      refresh_field_choices();

      // show sec grouping if is tally or if not list and only one fieldlet
      show_or_hide_and_clear_select_field("div#sec_grouping", agg == "Tally" || (agg != "" && agg != "List" && one_effective_field()));

      // show bar chart display type if 1) agg is not list or blank 2) fields are numeric
      show_hide_display_type_option("Bar Chart", (agg != "" && agg != "List") && fields_are_numeric());
    }
    
    // unique row checkbox only visible if list
    if (src == "aggregation" || src == "_all")
      show_or_hide_and_clear_checkbox_field("div#unique_rows", agg == "List")
    
    // percent field only visible if tally && table
    if (src == "display_type" || src == "aggregation" || src == "_all")
      show_or_hide_and_clear_select_field("div#percent_type", disp_type == "Table" && agg == "Tally");
    
    // show/hide by col/row percent types
    if (src == "pri_grouping" || src == "sec_grouping" || src == "_all") {
      
      // save reference to the select field
      var sel = $('#report_report_percent_type');

      // if report has two groupings, show, else hide
      if (report.form.pri_grouping && report.form.sec_grouping) {
        
        // only add if they're not there already
        if (sel[0].length < 4)
          for (var i = 0; i < 2; i++) sel.append("<option value=\"" + ROW_COL_PERCENT_TYPE_OPTIONS[i] + "\">" + 
            ROW_COL_PERCENT_TYPE_OPTIONS[i] + "</option>");
      
      } else {
        // remove the last two items
        if (sel[0].length == 4) 
          for (var i = 0; i < 2; i++) $("#report_report_percent_type option:last").remove();
      }
    }
    
    // show/hide bar style
    if (src == "display_type" || src == "sec_grouping" || src == "_all")
      $('div#bar_style')[report.form.display_type == "Bar Chart" && report.form.sec_grouping ? "show" : "hide"]();
  }
  
  // shows/hides a select box and clears its value if hiding
  function show_or_hide_and_clear_select_field(selector, show_or_hide) {
    $(selector)[show_or_hide ? "show" : "hide"]();
    if (!show_or_hide) $(selector + " select").val("");
  }

  // shows/hides a checkbox and clears its value if hiding
  function show_or_hide_and_clear_checkbox_field(selector, show_or_hide) {
    $(selector)[show_or_hide ? "show" : "hide"]();
    if (!show_or_hide) $(selector + " input").removeAttr("checked");
  }
  
  // checks if there is only one effective field (one field that is not a question type)
  function one_effective_field() {
    var flds = report.form.fields;
    var count = 0;
    for (var i = 0; i < flds.length; i++)
      if (flds[i] != "") {
        // increment the count
        count++;
        // if the count is more than one or this is a question type field, return false
        if (count > 1 || flds[i].match(/^qtype_/)) return false;
      }
    return true;
  }
  
  // checks if all the selected fields are numeric (integer or decimal)
  // returns true if this is a tally report
  function fields_are_numeric() {
    if (report.form.aggregation == "Tally") return true;
    var flds = report.form.fields;
    for (var i = 0; i < flds.length; i++)
      // if this field is not numeric, return false
      if (flds[i] != "" && ["integer", "decimal"].indexOf(field_choice_hash[flds[i]].data_type) == -1)
        return false;
    return true;
  }
  
  // shows or hides a given display type option
  function show_hide_display_type_option(name, show_or_hide) {
    var option = $("#report_report_display_type option[value='" + name + "']");
    // add the option if it's not already there
    if (show_or_hide) {
      if (option.length == 0) $("#report_report_display_type").append($("<option>").val(name).text(name));
    } else
      // remove the option
      option.remove();
  }
  
  // makes sure the field choices are appropriate for the selected aggregation and other field choices
  function refresh_field_choices() {
    // loop over each field dropdown
    $(FIELD_SELECTS_SELECTOR + ' select').each(function(sel_idx, sel) {
      sel = $(sel);
      // save the existing value
      var old_val = sel.val();
      
      // clear the box and add the blank
      sel.empty();
      $("<option>").appendTo(sel);
      
      // stop here if no aggregation
      var agg = report.form.aggregation;
      if (agg == "") return;
      
      // loop over each choice set
      $.each(report.obj.field_choices, function(cs_idx, choice_set) {
        
        // reject set if this is not the first box and not appropriate for first box choice
        if (sel_idx != 0 && agg != "List" && choice_set.name != "Questions") return;
        
        // no question type fields for lists
        if (agg == "List" && choice_set.name == "Question Types") return;
        
        // otherwise create optgroup
        var optgroup = $("<optgroup>").attr("label", choice_set.name);
        
        // loop over each choice in set
        $.each(choice_set.choices, function(c_idx, choice) {
          // reject if data type not appropriate for aggregation
          if ((adt = ALLOWED_DATA_TYPES_PER_AGGREGATION[agg]) && adt.indexOf(choice.data_type) == -1) return;
          
          // otherwise add option
          $("<option>").val(choice.full_id).text(choice.name).appendTo(optgroup);
        });
        
        // append optgroup unless it's empty
        if (optgroup.children().length > 0) optgroup.appendTo(sel);
      });
      
      // restore old choice if possible
      sel.val(old_val);
    });
    
    // reload params in case they changed
    load_params_from_form(report.form);
  }
  
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
    load_params_from_form(params_at_last_submit);
    
    // show the loading indicator
    $("#report_form div.loader").show();
    
    Utils.ajax_with_session_timeout_check({
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
          // save the params
          params_at_last_save = $.extend({}, params_at_last_submit);
          
          // if we're currently on the 'new' page, redirect to 'edit'
          if (window.location.pathname.match(/reports\/new/)) {
            window.location.href = "/report/reports/" + report.obj.id + "/edit?show_success=1";
            return;
          } else {
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
        Utils.show_flash({type: "error", msg: "Error: " + error})

        // hide the loading indicator
        $("#report_form div.loader").hide();
      }
    })
  }

  // redraws the report
  function redraw() {
    // load current settings from form
    load_params_from_form(report.form);
  
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
      // draw the appropriate report type
      switch (report.form.display_type) {
        case "Table": draw_table(); break;
        case "Bar Chart": draw_bar_chart(); break;
      }
    }

    // update the title
    set_title();
  }
  
  // draws the report as a bar chart (uses google viz api)
  function draw_bar_chart() {
    
    // set up data
    var data = new google.visualization.DataTable();
    
    // add first column (pri_grouping)
    data.addColumn('string', 'main');
    
    // add rest of columns (sec_grouping)
    $(report.obj.headers.col).each(function(idx, ch){data.addColumn('number', ch.name || "[Null]");})
    
    $(report.obj.headers.row).each(function(r, rh){
      // build the row
      var row = [rh.name || "[Null]"];
      $(report.obj.headers.col).each(function(c, ch) {row.push(report.obj.data[r][c] || 0);});
      // add it
      data.addRow(row)
    });

    var cont_height = Math.max(200, Math.min(800, report.obj.headers.row.length * 40));
    var cont_width = $("#content").width() - $("#report_form").width() - 50;
    var options = {
      width: cont_width, 
      height: cont_height,
      vAxis: {title: report.obj.header_titles.row},
      hAxis: {title: report.form.aggregation},
      chartArea: {top: 0, left: 150, height: cont_height - 50, width: cont_width - 300},
      isStacked: !!$('#report_report_bar_style_stacked').attr("checked")
    };

    var chart = new google.visualization.BarChart($('#report_body')[0]);
    chart.draw(data, options);
  }
  
  function draw_table() {

    var tbl = $("<table>");

    // column label row
    if (report.obj.header_titles.col) {
      var trow = $("<tr>");
      
      // blank cells for row grouping label and row header, if necessary
      if (report.obj.header_titles.row) { $("<th>").appendTo(trow); $("<th>").appendTo(trow); }
     
      // col grouping label
      $("<th>").addClass("col_grouping_label").attr("colspan", report.obj.headers.col.length).
        text(report.obj.header_titles.col).appendTo(trow);
      
      // row total cell
      if (show_totals("row")) $("<th>").appendTo(trow);
      
      tbl.append(trow);
    }
    
    // header row
    if (report.form.aggregation == "List" || report.obj.headers.col.length > 1 || report.obj.headers.row.length > 1) {
      var trow = $("<tr>");
    
      // blank cells for row grouping label and row header, if necessary
      if (report.obj.header_titles.row) { $("<th>").appendTo(trow); $("<th>").appendTo(trow); }
    
      // rest of header cells
      $(report.obj.headers.col).each(function(idx, ch) {
        $("<th>").addClass("col").text(ch.name || "[Null]").appendTo(trow);
      });

      // row total header
      if (show_totals("row"))
        $("<th>").addClass("row_total").text("Total").appendTo(trow);

      tbl.append(trow);
    }
    
    // create the row grouping label
    var row_grouping_label;
    if (report.obj.header_titles.row) {
      var txt = report.obj.header_titles.row.replace(/\s+/g, "<br/>")
      row_grouping_label = $("<th>").addClass("row_grouping_label").attr("rowspan", report.obj.headers.row.length);
      row_grouping_label.append($("<div>").html(txt));
    }
  
    // body
    $(report.obj.headers.row).each(function(r, rh) {
      trow = $("<tr>");
    
      // add the row grouping label if it is defined (also delete it so it doesn't get added again)
      if (row_grouping_label) {
        trow.append(row_grouping_label);
        row_grouping_label = null;
      }
    
      // row header
      if (rh != null) $("<th>").addClass("row").text(rh.name || "[Null]").appendTo(trow);
    
      // row cells
      $(report.obj.headers.col).each(function(c, ch) {
        // get cell type
        var typ = typeof(report.obj.data[r][c]);
        
        // get cell value
        var val = report.obj.data[r][c];
        if (val == null) val = "";
        
        // calculate percentage if necessary
        if (val != "" && report.form.percent_type != "") {
          switch (report.form.percent_type) {
            case "Percentage Overall": val /= report.obj.grand_total; break;
            case "Percentage By Row": val /= report.obj.totals["row"][r]; break;
            case "Percentage By Column": val /= report.obj.totals["col"][c]; break;
          }
          val = format_percent(val);
        }
        $("<td>").text(val).addClass(typ).appendTo(trow);
      });
    
      // row total
      if (show_totals("row")) {
        var val = report.obj.totals["row"][r];
        
        // don't display 0s
        if (val == 0) val = "";

        // calculate percentage if necessary
        if (report.form.percent_type != "" && val != "") 
          val = format_percent(val / report.obj.grand_total);
        
        // add the cell
        $("<td>").addClass("row_total").text(val).addClass("number").appendTo(trow);
      }
      
      tbl.append(trow);
    });
  
    // footer
    if (show_totals("col")) {
      trow = $("<tr>");
    
      // blank cells for row grouping label and row header, if necessary
      if (report.obj.header_titles.row) { $("<th>").appendTo(trow); }
     
      // row header
      $("<th>").addClass("row").addClass("col_total").text("Total").appendTo(trow);
    
      // row cells
      $(report.obj.totals.col).each(function(c, ct) {
        var val = ct;
        
        // don't display 0s
        if (val == 0) val = "";

        // calculate percentage if necessary
        if (report.form.percent_type != "" && val != "")
          val = format_percent(val / report.obj.grand_total);
        
        // add cell
        $("<td>").addClass("col_total").text(val).addClass("number").appendTo(trow);
      });
    
      // grand total
      if (show_totals("row")) {
        var val = (gt = report.obj.grand_total) > 0 ? gt : "";
        
        // calculate percentage if necessary
        if (report.form.percent_type != "" && val != "") 
          val = format_percent(1);
          
        $("<td>").addClass("row_total").addClass("col_total").text(val).addClass("number").appendTo(trow);
      }

      tbl.append(trow);
    }
    
    // clear any old stuff
    $('#report_body').empty()
    
    // add a row count
    $('#report_body').append($("<div>").attr("id", "row_count").text("Total Rows: " + report.obj.data.length));
    
    // add the table
    $('#report_body').append(tbl);
  }
  
  // checks whether total rows should be shown for a table report
  function show_totals(row_or_col) {
    // totals object must be defined
    return report.obj.totals && report.obj.totals[row_or_col] && (
      // no need to show percentages if they will all be 100%
      row_or_col == "row" ? 
        report.form.sec_grouping && report.form.percent_type != "Percentage By Row" : 
        report.form.pri_grouping && report.form.percent_type != "Percentage By Column"
    )
  }
  
  // updates the title of the report
  function set_title() {
    // set title
    $("#content h1").text(report.form.name);
  }
  
  // formats a given fraction as a percentage
  function format_percent(frac) {
    return (frac * 100).toFixed(1) + "%";
  }
  
  function load_params_from_form(target) {
    var fields = {
      name: "name",
      filter: "filter_attributes_str",
      unreviewed: "unreviewed",
      unique_rows: "unique_rows",
      pri_grouping: "pri_grouping_attributes_form_choice",
      sec_grouping: "sec_grouping_attributes_form_choice",
      display_type: "display_type",
      percent_type: "percent_type",
      bar_style: "bar_style"
    }
    $.each(fields, function(attr, id){
      // get the form field
      var ff_id = "#report_report_" + fields[attr]
      var ff = $(ff_id);
      // if field is a grouping, get both name and value
      if (attr.match(/_grouping$/)) {
        // if value is null/none, just set to null
        if (ff.val() == "")
          target[attr] = null;
        else
          target[attr] = {name: $(ff_id + " :selected").text(), id: ff.val()};
      }
      else if (attr == "bar_style")
        target[attr] = !!$("#report_report_bar_style_stacked").attr("checked");
      // if it's a checkbox, get whether it's checked or not
      else if (ff.attr("type") == "checkbox")
        target[attr] = ff.is(':checked');
      // else just get the value
      else
        target[attr] = ff.val();
    });
    
    // get aggregation name
    target["aggregation"] = $('#report_report_aggregation_id option:selected').text();
    
    // get attribs/questions dropdown values
    target["fields"] = $("#report_form #fields #field_dropdowns select").map(function(){return $(this).val();});
  }
  
  // checks if a re-run of the report is needed
  function rerun_required() {
    var cur_params = {};
    load_params_from_form(cur_params);
    
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
    load_params_from_form(cur_params);
    return param_diff(params_at_last_save, cur_params).length != 0;
  }
  
  // compares two sets of parameters
  function param_diff(a,b) {
    var changed_keys = [];
    
    // for each parameter, if it has changed, add it to array
    for (var k in a) {

      // figure out of the param has changed, depending on its type
      var changed = false;
      if (k == "fields")
        changed = !Utils.array_eq(a[k], b[k]);
      else if (k.match(/_grouping$/)) 
        changed = (a[k] == null || b[k] == null) ? a[k] != b[k] : a[k].id != b[k].id;
      else
        changed = a[k] != b[k];
        
      // if it has changed, save the key
      if (changed) changed_keys.push(k);
    }
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