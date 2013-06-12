// ELMO.Report.ReportTitleEditPane < ELMO.Report.EditPane
(function(ns, klass) {

  // constructor
  klass = ns.ReportTitleEditPane = function(parent_view) {
    this.parent_view = parent_view;
    this.build()
  };
  
  // inherit from EditPane
  klass.prototype = new ns.EditPane();
  klass.prototype.constructor = klass;
  klass.prototype.parent = ns.EditPane.prototype;
  
  klass.prototype.id = "report_title";
  
  // builds controls
  klass.prototype.build = function() {
    // call super first
    this.parent.build.call(this);
    
    this.title_fld = this.cont.find("input#report_title");
  }
  
  klass.prototype.update = function(report) {
    // store report reference
    this.report = report;
    
    // update controls
    this.title_fld.val(report.attribs.name);
  }

  // extracts data from the view into the model
  klass.prototype.extract = function() {
    this.report.attribs.name = this.title_fld.val();
  }
  
  klass.prototype.fields_for_validation_errors = function() {
    return ["name"];
  }
}(ELMO.Report));