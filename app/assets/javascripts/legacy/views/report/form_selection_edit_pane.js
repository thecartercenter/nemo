// ELMO.Report.FormSelectionEditPane < ELMO.Report.EditPane
(function (ns, klass) {
  // constructor
  ns.FormSelectionEditPane = klass = function (parent_view, menus) {
    this.parent_view = parent_view;
    this.menus = menus;
    this.build();
  };

  // inherit from EditPane
  klass.prototype = new ns.EditPane();
  klass.prototype.constructor = klass;
  klass.prototype.parent = ns.EditPane.prototype;

  klass.prototype.id = 'form_selection';

  // builds controls
  klass.prototype.build = function () {
    const _this = this;

    // call super first
    this.parent.build.call(this);

    // build question selector
    this.form_chooser = new ELMO.Control.Multiselect({
      el: this.cont.find('div#form_select'),
      objs: this.menus.form.objs,
      id_key: 'id',
      txt_key: 'name',
    });
    this.form_chooser.change(() => { _this.broadcast_change('form_selection'); });
  };

  klass.prototype.update = function (report) {
    // store report reference
    this.report = report;

    // update controls
    // get selected IDs from model
    if (this.report.attribs.form_ids == 'ALL') this.form_chooser.set_all(true);
    else {
      this.form_chooser.update(this.report.attribs.form_ids);
    }
  };

  // extracts data from the view into the model
  klass.prototype.extract = function (enabled) {
    if (enabled) {
      // send selected IDs to model
      this.report.attribs.form_ids = this.form_chooser.all_selected() ? 'ALL' : this.form_chooser.get();
    }
  };
}(ELMO.Report));
