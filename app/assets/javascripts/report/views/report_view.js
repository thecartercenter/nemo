// ELMO.Report.ReportView
(function(ns, klass) {
  
  // constructor
  ns.ReportView = klass = function(controller, report) {
    // save refs
    this.controller = controller;
    this.report = report;
    
    // show title
    this.show_title();
    
    // show links
    this.hookup_links();
  }
  
  klass.prototype.update = function(report) {
    this.report = report;
    
    // show the title
    this.show_title();

    // if there was a handled error with the report model, display it
    if (this.report.attribs.errors && this.report.attribs.errors.base)
      this.show_error("Error: " + this.report.attribs.errors.base.join(', '));
    // else, the run must have been successful, so render it!
    else {
      Utils.clear_flash();
      this.render();
    }
  }
  
  klass.prototype.render = function() {
    // clear out info bar
    $(".report_info").empty();

    // if no matching data, show message
    if (this.report.attribs.empty) {
      $(".report_body").html(I18n.t("report/report.no_match"))

    } else {
      // add the generated date/time to info bar
      console.log(this.report)
      $('<div>').append(I18n.t('report/report.generated_at') + ' ' + this.report.attribs.generated_at).appendTo($(".report_info"));

      // create an appropriate Display class based on the display_type
      if (this.report.attribs.type == "Report::StandardFormReport")
        this.display = new ns.FormSummaryDisplay(this.report);
      
      else if (this.report.attribs.display_type == 'bar_chart')
        this.display = new ns.BarChartDisplay(this.report);
      
      else
        this.display = new ns.TableDisplay(this.report);

      this.display.render();
    }
  }
  
  klass.prototype.show_title = function() {
    ELMO.app.set_title(I18n.t("activerecord.models.report/report.one") + ": " + this.report.attribs.name);
  }
  
  klass.prototype.show_loading_indicator = function(yn) {
    $("#report_load_ind img")[yn ? "show" : "hide"]();
  }
  
  klass.prototype.show_error = function(msg) {
    Utils.show_flash({type: "error", msg: msg});
  }
  
  // hookup link events
  klass.prototype.hookup_links = function() {
    var _this = this;
    $(".report_top_links a#edit_link").click(function() { _this.controller.show_edit_view(1); return false; })
  }
  
}(ELMO.Report));