// ELMO.Report.ReportTypeEditPane < ELMO.Report.EditPane
(function (ns, klass) {
  // constructor
  ns.ReportTypeEditPane = klass = function (parent_view) {
    this.parent_view = parent_view;
    this.build();
  };

  // inherit from EditPane
  klass.prototype = new ns.EditPane();
  klass.prototype.constructor = klass;
  klass.prototype.parent = ns.EditPane.prototype;

  klass.prototype.id = 'report_type';

  // builds controls
  klass.prototype.build = function () {
    const _this = this;

    // call super first
    this.parent.build.call(this);

    // make type chooser
    this.type_chooser = new ELMO.Control.RadioGroup({ inputs: this.cont.find("input[name='report_type']") });
    this.type_chooser.change(() => { _this.broadcast_change('report_type'); });

    // handle example link clicks
    this.cont.find('a.show-examples').click((e) => {
      $(e.target).closest('label').find('div.examples').toggle();
      e.stopPropagation();
      e.preventDefault();
    });
  };

  klass.prototype.update = function (report) {
    // store report reference
    this.report = report;

    // update controls
    this.type_chooser.update(this.report.attribs.type);
    this.type_chooser.enable(this.report.new_record);
  };

  // extracts data from the view into the model
  klass.prototype.extract = function () {
    this.report.attribs.type = this.type_chooser.get();
  };

  klass.prototype.fields_for_validation_errors = function () {
    return ['type'];
  };
}(ELMO.Report));
