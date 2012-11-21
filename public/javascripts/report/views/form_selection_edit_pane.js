// ELMO.Report.FormSelectionEditPane < ELMO.Report.EditPane
(function(ns, klass) {
  
  // constructor
  ns.FormSelectionEditPane = klass = function(menus) {
    this.menus = menus;
    this.build()
  }

  // inherit from EditPane
  klass.prototype = new ns.EditPane();
  klass.prototype.constructor = klass;
  klass.prototype.parent = ns.EditPane.prototype;
  
  klass.prototype.id = "form_selection";

  // builds controls
  klass.prototype.build = function() {
    // call super first
    this.parent.build.call(this);
    
    // build question selector
    this.form_chooser = new ELMO.Control.Multiselect({
      el: this.cont.find("div#form_select"),
      objs: this.menus.form.objs,
      id_key: "id",
      txt_key: "full_name"
    });
  }

  klass.prototype.update = function(report) {
    this.report = report;
    // get selected IDs from model
    if (this.report.attribs.form_ids == "ALL")
      this.form_chooser.set_all(true)
    else
      this.form_chooser.update(this.report.attribs.form_ids);
  }

  // extracts data from the view into the model
  klass.prototype.extract = function() {
    // send selected IDs to model
    this.report.attribs.form_ids = this.form_chooser.all_selected() ? "ALL" : Sassafras.Utils.array_to_ints(this.form_chooser.get());
  }
  
}(ELMO.Report));