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
    var template = JST['legacy/templates/report/form_summary_display'];
    $('.report_body').empty().append(template({
      report: this.report.attribs,
      max_result_cols: this.report.attribs.question_labels == 'title' ? 5 : 8,
      helper: self
    }));
  }

  klass.prototype.partial = function(name, params) {
    params.helper = this;
    params.report = this.report.attribs;
    var template = JST['legacy/templates/report/form_summary_' + name];
    return template(params);
  }

}(ELMO.Report));