// ELMO.Report.FieldsEditPane < ELMO.Report.EditPane
// This pane is for choosing fields for a ListReport
(function (ns, klass) {
  // constructor
  ns.FieldsEditPane = klass = function (parent_view, menus, options) {
    this.parent_view = parent_view;
    this.menus = menus;
    this.options = options;
    this.build();
  };

  // inherit from EditPane
  klass.prototype = new ns.EditPane();
  klass.prototype.constructor = klass;
  klass.prototype.parent = ns.EditPane.prototype;

  klass.prototype.id = 'fields';

  // builds controls
  klass.prototype.build = function () {
    // call super first
    this.parent.build.call(this);

    this.fields = new ns.FieldSelectorSet($('.report_edit_pane.fields .field_selector_set'), this.menus);

    this.attribs_to_watch = { report_type: true, form_selection: true };
  };

  klass.prototype.update = function (report) {
    // store report reference
    this.report = report;

    this.fields.update(this.report);
  };

  klass.prototype.extract = function (enabled) {
    if (enabled) {
      this.report.attribs.calculations_attributes = this.fields.get();
    }
  };

  // before validation handler; removes any fields in the set with nothing selected
  klass.prototype.before_validation = function () {
    this.fields.remove_unselected();
  };

  klass.prototype.fields_for_validation_errors = function () {
    return ['fields'];
  };
}(ELMO.Report));
