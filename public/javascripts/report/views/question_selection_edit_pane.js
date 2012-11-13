// ELMO.Report.QuestionSelectionEditPane < ELMO.Report.EditPane
(function(ns, klass) {
  
  // constructor
  ns.QuestionSelectionEditPane = klass = function(menus) {
    this.menus = menus;
    this.build()
  }

  // inherit from EditPane
  klass.prototype = new ns.EditPane();
  klass.prototype.constructor = klass;
  klass.prototype.parent = ns.EditPane.prototype;
  
  klass.prototype.title = "Question Choices";

  // builds controls
  klass.prototype.build = function() {
    var _this = this
    
    // call super first
    this.parent.build.call(this);
    
    // build calculation chooser
    this.calc_chooser = new ELMO.Control.Select({
      el: this.cont.find("select#omnibus_calculation"),
      objs: this.menus.calc_type.objs,
      id_key: "name",
      txt_key: "title"
    });
    
    // build radio group
    this.q_sel_type_radio = new ELMO.Control.RadioGroup({inputs: this.cont.find("input[name='q_sel_type']")});
    
    // build question selector
    this.q_chooser = new ELMO.Control.Multiselect({
      el: this.cont.find("div#question_select"),
      objs: this.menus.question.objs,
      id_key: "id",
      txt_key: "code"
    });
    
    // build option set chooser
    this.opt_set_chooser = new ELMO.Control.Select({
      el: this.cont.find("select#option_set"),
      objs: this.menus.option_set.objs,
      id_key: "id",
      txt_key: "name"
    });
    
    // setup event handlers
    (function(_this){
      _this.calc_chooser.change(function(){ _this.handle_calculation_change(); })
      _this.q_sel_type_radio.change(function() { _this.handle_q_sel_type_change(); })
    })(this);
  }
  
  klass.prototype.update = function(report) {
    this.report = report;
    
    // the omnibus calculation should be the type of the first calculation in the model since they're all the same
    if (this.report.attribs.calculations && this.report.attribs.calculations.length > 0)
      this.calc_chooser.update(this.report.attribs.calculations[0].type);
    else
      this.calc_chooser.update("Report::IdentityCalculation");
      
    this.q_chooser.update(this.report.get_calculation_question_ids());
    this.q_sel_type_radio.update(this.report.attribs.option_set_id == null ? "questions" : "option_set");
    this.opt_set_chooser.update(this.report.attribs.option_set_id);
  }
  
  // extracts data from the view into the model
  klass.prototype.extract = function() {
    this.report.attribs.omnibus_calculation = this.calc_chooser.get();
    if (this.q_sel_type_radio.get() == "questions") {
      this.report.set_calculations_by_question_ids(this.q_chooser.get());
      this.report.attribs.option_set_id = null;
    } else {
      this.report.set_calculations_by_question_ids([]);
      this.report.attribs.option_set_id = this.opt_set_chooser.get();
    }
  }
  
  klass.prototype.handle_calculation_change = function() {
    this.q_chooser.update_objs(this.menus.question.for_calc_type(this.calc_chooser.get()));
  }
  
  klass.prototype.handle_q_sel_type_change = function() {
    // disable the appropriate control
    this.opt_set_chooser.enable(this.q_sel_type_radio.get() == "option_set");
    this.q_chooser.enable(this.q_sel_type_radio.get() == "questions");
  }
  
  klass.prototype.fields_for_validation_errors = function() {
    return ["questions", "option_set_id"];
  }
  
}(ELMO.Report));