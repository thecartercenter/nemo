// ELMO.Report.GroupingEditPane < ELMO.Report.EditPane
// This pane is for choosing row and col headers for a ResponseTallyReport
(function(ns, klass) {

  // constructor
  ns.GroupingEditPane = klass = function(parent_view, menus, options) {
    this.parent_view = parent_view;
    this.menus = menus;
    this.options = options;
    this.build();
  }

  // inherit from EditPane
  klass.prototype = new ns.EditPane();
  klass.prototype.constructor = klass;
  klass.prototype.parent = ns.EditPane.prototype;

  klass.prototype.id = "grouping";

  // builds controls
  klass.prototype.build = function() {
    // call super first
    this.parent.build.call(this);

    this.pri = new ns.FieldSelector($(".primary.field_selector"), this.menus, this.options.headerable_qtype_names);
    this.sec = new ns.FieldSelector($(".secondary.field_selector"), this.menus, this.options.headerable_qtype_names);

    this.attribs_to_watch = {report_type: true, tally_type: true, form_selection: true};
  }

  klass.prototype.update = function(report) {
    // store report reference
    this.report = report;

    // update controls
    this.pri.update(report, this.report.calculation_by_rank(1));
    this.sec.update(report, this.report.calculation_by_rank(2));
  }

  klass.prototype.extract = function(enabled) {
    if (enabled) {
      this.report.attribs.calculations_attributes = [this.pri.get(), this.sec.get()];
    }
  }

}(ELMO.Report));