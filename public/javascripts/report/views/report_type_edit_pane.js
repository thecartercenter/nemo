// ELMO.Report.ReportTypeEditPane < ELMO.Report.EditPane
(function(ns, klass) {
  
  // constructor
  ns.ReportTypeEditPane = klass = function() {
    this.build();
  }

  // inherit from EditPane
  klass.prototype = new ns.EditPane();
  klass.prototype.constructor = klass;
  klass.prototype.parent = ns.EditPane.prototype;
  
  klass.prototype.title = "Report Type";

  // builds controls
  klass.prototype.build = function() {
    var _this = this;

    // call super first
    this.parent.build.call(this);

    // make type chooser
    this.type_chooser = new ELMO.Control.RadioGroup({inputs: this.cont.find("input[name='report_type']")});
  }
  
  klass.prototype.update = function(report) {
    this.report = report;
    this.type_chooser.update(this.report.attribs.type);
  }

  // extracts data from the view into the model
  klass.prototype.extract = function() {
    this.report.attribs.type = this.type_chooser.get();
  }
  
  klass.prototype.fields_for_validation_errors = function() {
    return ["type"];
  }

}(ELMO.Report));