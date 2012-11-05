// ELMO.Report.ReportController
(function(ns, klass) {
  
  // constructor
  ns.ReportController = klass = function(init_data) {
    this.report_in_db = new ns.Report(init_data.report);
    
    // create copy of report to be referenced each run
    this.report_last_run = this.report_in_db.clone();
    
    // create supporting models
    this.options = init_data.options;
    this.menus = {
      calc_type: new ns.CalcTypeMenu(this.options.calculation_types),
      question: new ns.QuestionMenu(this.options.questions),
      option_set: new ns.OptionSetMenu(this.options.option_sets)
    }
    
    // create report view
    this.report_view = new ns.ReportView(this, this.report_in_db);
    
    // create edit view
    this.edit_view = new ns.EditView(this.menus, this.options, this);
    
    // show unhandled error if exists
    if (init_data.unhandled_error)
      this.report_view.show_error("System Error: " + init_data.unhandled_error);
    
    // otherwise, if is new record, show dialog first page
    else if (!this.report_in_db.has_run())
      this.show_edit_view(0);
      
    // otherwise, the report must have already run, so update the view
    else
      this.report_view.update(this.report_last_run);
  }

  klass.prototype.show_edit_view = function(idx) {
    //$("#report_body, #report_links").hide();
    this.edit_view.show(this.report_last_run.clone(), idx);
  }
  
  // sends an ajax request to server
  klass.prototype.run_report = function(report) {
    
    // hide dialog and show loading indicator
    this.edit_view.hide();
    this.report_view.show_loading_indicator(true);
  
    // get hash from report
    var to_serialize = {}
    to_serialize["report"] = report.to_hash();
    if (report.attribs.id) to_serialize["id"] = report.attribs.id;
  
    // comply with REST stuff
    to_serialize["_method"] = report.attribs.new_record ? "post" : "put"
    var url = "/report/reports/" + (report.attribs.new_record ? "" : report.attribs.id);
  
    // send ajax (use currying for event handlers)
    (function(_this) {
      Utils.ajax_with_session_timeout_check({
        type: 'POST',
        url: url,
        data: $.param(to_serialize),
        success: function(d, s, j) { _this.run_success(d, s, j); },
        error: function(j, s, e) { _this.run_error(j, s, e); }
      })
    })(this);
  }
  
  klass.prototype.run_success = function(data, status, jqxhr) {
    // hide load ind
    this.report_view.show_loading_indicator(false);

    // if unhandled error in report run process display it
    if (data.unhandled_error)
      this.report_view.show_error("System Error: " + data.unhandled_error);
      
    // otherwise, if the 'just created' flag is set, redirect to the show action so that links, etc., will work
    else if (data.report.just_created) {
      this.report_view.show_loading_indicator(true);
      window.location.href = "/report/reports/" + data.report.id
      
    // otherwise we can process the updated report object
    } else {
      this.report_last_run = new ns.Report(data.report);
      this.display_report(this.report_last_run);
    }
  }
  
  klass.prototype.run_error = function(jqxhr, status, error) {
    // hide load ind
    this.report_view.show_loading_indicator(false);
    
    // show error
    var msg = error == "" ? "Error contacting server" : "System Error: " + error;
    this.report_view.show_error(msg);
  }
  
  klass.prototype.display_report = function(report) {
    this.report_view.update(report);
  }
}(ELMO.Report));