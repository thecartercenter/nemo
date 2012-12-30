// ELMO.Report.DisplayOptionsEditPane < ELMO.Report.EditPane
(function(ns, klass) {
  
  // constructor
  ns.DisplayOptionsEditPane = klass = function(parent_view, menus, options) {
    this.parent_view = parent_view;
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
    var _this = this;
    
    // call super first
    this.parent.build.call(this);
    
    // build display type chooser
    this.display_type = new ELMO.Control.RadioGroup({inputs: this.cont.find("input[name='display_type']")});
    this.display_type.change(function() { _this.broadcast_change("display_type"); });

    // build option set chooser
    this.percent_type = new ELMO.Control.Select({
      el: this.cont.find("select#percent_style"),
      objs: this.options.percent_types,
      id_key: "name",
      txt_key: "label"
    })
    this.percent_type.change(function() { _this.broadcast_change("percent_type"); });
    
    // build question label chooser
    this.bar_style = new ELMO.Control.RadioGroup({inputs: this.cont.find("input[name='bar_style']")});
    this.bar_style.change(function() { _this.broadcast_change("bar_style"); });

    // build question label chooser
    this.question_labels = new ELMO.Control.RadioGroup({inputs: this.cont.find("input[name='question_labels']")});
    this.question_labels.change(function() { _this.broadcast_change("question_labels"); });
    
    // register fields to watch for changes
    this.attribs_to_watch = {display_type: true, report_type: true};
  }
  
  klass.prototype.update = function(report) {
    // store report reference
    this.report = report;

    // update controls
    this.display_type.update(report.attribs.display_type);
    this.percent_type.update(report.attribs.percent_type);
    this.bar_style.update(report.attribs.bar_style);
    this.question_labels.update(report.attribs.question_labels);
    
    var is_tally = this.report.attribs.type && this.report.attribs.type.match(/TallyReport/);
    
    var show;
    show = is_tally;
    this.display_type.closest(".section")[show ? "show" : "hide"]();
    if (!show) this.display_type.clear();
    
    show = this.report.attribs.display_type == "Table" && is_tally;
    this.percent_type.closest(".section")[show ? "show" : "hide"]();
    if (!show) this.percent_type.clear();

    show = this.report.attribs.display_type == "BarChart";
    this.bar_style.closest(".section")[show ? "show" : "hide"]();
    if (!show) this.bar_style.clear();
  }

  // extracts data from the view into the model
  klass.prototype.extract = function() {
    this.report.attribs.display_type = this.display_type.get();
    this.report.attribs.percent_type = this.percent_type.get();
    this.report.attribs.bar_style = this.bar_style.get();
    this.report.attribs.question_labels = this.question_labels.get();
  }

}(ELMO.Report));