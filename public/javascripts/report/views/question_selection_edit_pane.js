// ELMO.Report.QuestionSelectionEditPane < ELMO.Report.EditPane
(function(ns, klass) {
  
  // constructor
  ns.QuestionSelectionEditPane = klass = function(parent_view, menus) {
    this.parent_view = parent_view;
    this.menus = menus;
    this.build()
  }

  // inherit from EditPane
  klass.prototype = new ns.EditPane();
  klass.prototype.constructor = klass;
  klass.prototype.parent = ns.EditPane.prototype;
  
  klass.prototype.id = "question_selection";

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
    this.calc_chooser.change(function() { _this.broadcast_change("omnibus_calculation"); });
    
    // build radio group
    this.q_sel_type_radio = new ELMO.Control.RadioGroup({inputs: this.cont.find("input[name='q_sel_type']")});
    this.q_sel_type_radio.change(function() { _this.enable_questions_or_option_sets(); });
    
    // build question selector
    this.q_chooser = new ELMO.Control.Multiselect({
      el: this.cont.find("div#question_select"),
      objs: this.menus.question.objs,
      id_key: "id",
      txt_key: "code"
    });
    this.q_chooser.change(function() { _this.broadcast_change("question_selection"); });
    
    // build option set chooser
    this.opt_set_chooser = new ELMO.Control.Select({
      el: this.cont.find("select#option_set"),
      objs: this.menus.option_set.objs,
      id_key: "id",
      txt_key: "name",
      prompt: true
    });
    this.opt_set_chooser.change(function() { _this.broadcast_change("option_set"); });

    
    this.attribs_to_watch = {omnibus_calculation: true, q_sel_type: true, form_selection: true, report_type: true};
  }
  
  klass.prototype.update = function(report, on_show) {
    // store report reference
    this.report = report;

    // update controls
    // the omnibus calculation should be the type of the first calculation in the model since they're all the same
    if (on_show) {
      if (this.report.attribs.omnibus_calculation)
        this.calc_chooser.update(this.report.attribs.omnibus_calculation);
      else if (this.report.attribs.calculations && this.report.attribs.calculations.length > 0)
        this.calc_chooser.update(this.report.attribs.calculations[0].type);
      else
        this.calc_chooser.update("Report::IdentityCalculation");
    
      this.q_chooser.update(this.report.get_calculation_question_ids());
    
      if (!this.q_sel_type_radio.get())
        this.q_sel_type_radio.update(this.report.attribs.option_set_id == null ? "questions" : "option_set");
    
      this.opt_set_chooser.update(this.report.attribs.option_set_id);
    }
    
    // update question choices
    this.q_chooser.update_objs(this.menus.question.for_forms_and_calc_type(this.report.attribs.form_ids, this.calc_chooser.get()));
    
    this.enable_questions_or_option_sets();
  }
  
  // extracts data from the view into the model
  klass.prototype.extract = function(enabled) {
    if (enabled) {
      this.report.attribs.omnibus_calculation = this.calc_chooser.get();
      this.report.set_calculations_by_question_ids(this.q_chooser.get());
      this.report.attribs.option_set_id = this.opt_set_chooser.get();
    } else if (this.report) {
      this.report.attribs.option_set_id = "";
      this.report.attribs.omnibus_calculation = null;
    }
  }
  
  klass.prototype.fields_for_validation_errors = function() {
    return ["questions", "option_set_id"];
  }
  
  klass.prototype.enable_questions_or_option_sets = function() {
    // disable the appropriate control
    this.opt_set_chooser.enable(this.q_sel_type_radio.get() == "option_set");
    this.q_chooser.enable(this.q_sel_type_radio.get() == "questions");
  }
}(ELMO.Report));