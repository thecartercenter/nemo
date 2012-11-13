// ELMO.Report.DisplayOptionsEditPane < ELMO.Report.EditPane
(function(ns, klass) {
  
  // constructor
  ns.DisplayOptionsEditPane = klass = function(menus, options) {
    this.options = options;
    this.build();
  }
  
  // inherit from EditPane
  klass.prototype = new ns.EditPane();
  klass.prototype.constructor = klass;
  klass.prototype.parent = ns.EditPane.prototype;
  
  klass.prototype.title = "Display Options";

  // builds controls
  klass.prototype.build = function() {
    // call super first
    this.parent.build.call(this);
    
    // add option set chooser
    this.percent_type = new ELMO.Control.Select({
      el: this.cont.find("select#percent_style"),
      objs: this.options.percent_types,
      id_key: "name",
      txt_key: "label"
    })
  }
  
  klass.prototype.update = function(report) {
    this.report = report;
    this.percent_type.update(report.attribs.percent_type);
  }

  // extracts data from the view into the model
  klass.prototype.extract = function() {
    this.report.attribs.percent_type = this.percent_type.get();
  }

}(ELMO.Report));