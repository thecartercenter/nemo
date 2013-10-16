// ELMO.Report.FormSummaryDisplay < ELMO.Report.Display
(function(ns, klass) {
  
  // constructor
  ns.FormSummaryDisplay = klass = function(report) {
    this.report = report;
  }

  // inherit
  klass.prototype = new ns.Display();
  klass.prototype.constructor = klass;
  klass.prototype.parent = ns.Display.prototype;
  
  klass.prototype.render = function() { var self = this;
    var template = JST['templates/report/form_summary_display'];
    $('.report_body').empty().append(template({
      report: this.report.attribs,
      max_cols: 5
    }));
  }
  
}(ELMO.Report));