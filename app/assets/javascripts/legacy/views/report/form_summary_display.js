// ELMO.Report.FormSummaryDisplay < ELMO.Report.Display
(function (ns, klass) {
  // constructor
  ns.FormSummaryDisplay = klass = function (report) {
    this.report = report;
  };

  // inherit
  klass.prototype = new ns.Display();
  klass.prototype.constructor = klass;
  klass.prototype.parent = ns.Display.prototype;

  klass.prototype.render = function () {
    const self = this;
    $('.report-body').empty().append(this.report.attribs.html);
  };
}(ELMO.Report));
