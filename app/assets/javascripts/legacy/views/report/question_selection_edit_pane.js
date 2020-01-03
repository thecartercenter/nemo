// ELMO.Report.QuestionSelectionEditPane < ELMO.Report.EditPane
(function (ns, klass) {
  // constructor
  ns.QuestionSelectionEditPane = klass = function (parent_view, menus) {
    this.parent_view = parent_view;
    this.menus = menus;
    this.build();
  };

  // inherit from EditPane
  klass.prototype = new ns.EditPane();
  klass.prototype.constructor = klass;
  klass.prototype.parent = ns.EditPane.prototype;

  klass.prototype.id = 'question_selection';

  // builds controls
  klass.prototype.build = function () {
    const _this = this;

    // call super first
    this.parent.build.call(this);

    // build calculation chooser
    this.calc_chooser = new ELMO.Control.Select({
      el: this.cont.find('select#omnibus_calculation'),
      objs: this.menus.calc_type.objs,
      id_key: 'name',
      txt_key: 'description',
    });
    this.calc_chooser.change(() => { _this.broadcast_change('omnibus_calculation'); });

    // build radio group
    this.q_sel_type_radio = new ELMO.Control.RadioGroup({ inputs: this.cont.find("input[name='q_sel_type']") });
    this.q_sel_type_radio.change(() => { _this.enable_questions_or_option_sets(); });

    // build question selector
    this.q_chooser = new ELMO.Control.Multiselect({
      el: this.cont.find('div#question_select'),
      objs: this.menus.question.objs,
      id_key: 'id',
      txt_key: 'code',
    });
    this.q_chooser.change(() => { _this.broadcast_change('question_selection'); });

    // build option set selector
    this.opt_set_chooser = new ELMO.Control.Multiselect({
      el: this.cont.find('div#option_set_select'),
      objs: this.menus.option_set.objs,
      id_key: 'id',
      txt_key: 'name',
    });
    this.opt_set_chooser.change(() => { _this.broadcast_change('option_set'); });

    this.attribs_to_watch = { omnibus_calculation: true, q_sel_type: true, form_selection: true, report_type: true, tally_type: true };
  };

  klass.prototype.update = function (report, on_show) {
    // store report reference
    this.report = report;

    // update controls
    // the omnibus calculation should be the type of the first calculation in the model since they're all the same
    if (on_show) {
      if (this.report.attribs.omnibus_calculation) this.calc_chooser.update(this.report.attribs.omnibus_calculation);
      else if (this.report.attribs.calculations_attributes && this.report.attribs.calculations_attributes.length > 0) this.calc_chooser.update(this.report.attribs.calculations_attributes[0].type);
      else this.calc_chooser.update('identity');

      const question_ids = this.report.get_calculation_question_ids();
      this.q_chooser.update(question_ids);

      if (!this.q_sel_type_radio.get()) this.q_sel_type_radio.update(question_ids.length > 0 ? 'questions' : 'option_set');

      this.opt_set_chooser.update(this.report.get_option_set_ids());
    }

    // update question choices depending on selected forms
    const filter_options = { form_ids: this.report.attribs.form_ids, calc_type: this.calc_chooser.get(), question_types: ['select_one', 'select_multiple'] };
    this.q_chooser.update_objs(this.menus.question.filter(filter_options));

    this.enable_questions_or_option_sets();
  };

  // extracts data from the view into the model
  klass.prototype.extract = function (enabled) {
    if (enabled) {
      this.report.attribs.omnibus_calculation = this.calc_chooser.get();
      if (this.q_sel_type_radio.get() == 'questions') {
        this.report.set_calculations_by_question_ids(this.q_chooser.get());
        this.report.set_option_set_ids([]);
      } else {
        this.report.set_calculations_by_question_ids([]);
        this.report.set_option_set_ids(this.opt_set_chooser.get());
      }
    } else if (this.report) {
      this.report.attribs.omnibus_calculation = null;
    }
  };

  klass.prototype.fields_for_validation_errors = function () {
    return ['questions', 'option_sets'];
  };

  klass.prototype.enable_questions_or_option_sets = function () {
    // disable the appropriate control
    this.opt_set_chooser.enable(this.q_sel_type_radio.get() == 'option_set');
    this.q_chooser.enable(this.q_sel_type_radio.get() == 'questions');
  };
}(ELMO.Report));
