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
    if (this.report.attribs.errors)
      this.show_error("Error: " + this.report.attribs.errors);
    // else, the run must have been successful, so render it!
    else
      this.render();
  }
  
  klass.prototype.render = function() {
    // if no matching data, show message
    if (this.report.no_data()) {
      $("#report_info").empty();
      $("#report_body").html("No matching data were found.")
    } else {
      // create an appropriate Display class based on the display_type
      switch (this.report.attribs.display_type) {
        case "BarChart":
          this.display = new ns.BarChartDisplay(this.report);
          break;
        default:
          this.display = new ns.TableDisplay(this.report);
          break;
      }
    
      this.display.render();
    }
  }
  
  klass.prototype.show_title = function() {
    // update the title
    $("h1#title").text("Report: " + this.report.attribs.name);
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
    $("#report_links a").click(function() { _this.controller.show_edit_view(parseInt(this.id.match(/_(\d+)$/)[1])); return false; })
  }
  
}(ELMO.Report));