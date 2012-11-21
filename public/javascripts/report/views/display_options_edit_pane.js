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
  
  klass.prototype.id = "display_options";

  // builds controls
  klass.prototype.build = function() {
    // call super first
    this.parent.build.call(this);
    
    // build display type chooser
    this.display_type = new ELMO.Control.RadioGroup({inputs: this.cont.find("input[name='display_type']")});

    // build option set chooser
    this.percent_type = new ELMO.Control.Select({
      el: this.cont.find("select#percent_style"),
      objs: this.options.percent_types,
      id_key: "name",
      txt_key: "label"
    })
    
    // build question label chooser
    this.bar_style = new ELMO.Control.RadioGroup({inputs: this.cont.find("input[name='bar_style']")});

    // build question label chooser
    this.question_labels = new ELMO.Control.RadioGroup({inputs: this.cont.find("input[name='question_labels']")});

    // setup event handlers
    (function(_this){
      _this.display_type.change(function() { _this.handle_display_type_change(); })
    })(this);
  }
  
  klass.prototype.update = function(report) {
    this.report = report;
    this.display_type.update(report.attribs.display_type);
    this.percent_type.update(report.attribs.percent_type);
    this.bar_style.update(report.attribs.bar_style);
    this.question_labels.update(report.attribs.question_labels);
  }

  // extracts data from the view into the model
  klass.prototype.extract = function() {
    this.report.attribs.display_type = this.display_type.get();
    this.report.attribs.percent_type = this.percent_type.get();
    this.report.attribs.bar_style = this.bar_style.get();
    this.report.attribs.question_labels = this.question_labels.get();
  }
  
  klass.prototype.handle_display_type_change = function() {
    var show;
    show = this.display_type.get() == "Table";
    this.percent_type.closest(".section")[show ? "show" : "hide"]();
    if (!show) this.percent_type.clear();

    show = this.display_type.get() == "BarChart";
    this.bar_style.closest(".section")[show ? "show" : "hide"]();
    if (!show) this.bar_style.clear();
  }

}(ELMO.Report));