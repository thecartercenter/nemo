// ELMO.Report.DisplayOptionsEditPane < ELMO.Report.EditPane
(function(ns, klass) {

  // constructor
  ns.DisplayOptionsEditPane = klass = function(parent_view, menus, options) {
    this.parent_view = parent_view;
    this.options = options;
    this.menus = menus;
    this.build();
  }

  // inherit from EditPane
  klass.prototype = new ns.EditPane();
  klass.prototype.constructor = klass;
  klass.prototype.parent = ns.EditPane.prototype;

  klass.prototype.id = "display_options";

  // builds controls
  klass.prototype.build = function() { var self = this;
    var _this = this;

    // call super first
    this.parent.build.call(this);

    // build tally type chooser
    this.tally_type = new ELMO.Control.RadioGroup({inputs: this.cont.find("input[name='tally_type']")});
    this.tally_type.change(function() { _this.broadcast_change("tally_type"); });

    // build form chooser (for std form report)
    this.form_id = new ELMO.Control.Select({
      el: this.cont.find("select#form_id"),
      objs: this.menus.form.objs,
      id_key: "id",
      txt_key: "name",
      prompt: true // prompt is defined in HTML
    })
    this.form_id.change(function() { _this.broadcast_change("form_id"); });

    // build display type chooser
    this.display_type = new ELMO.Control.RadioGroup({inputs: this.cont.find("input[name='display_type']")});
    this.display_type.change(function() { _this.broadcast_change("display_type"); });

    // build option set chooser
    this.percent_type = new ELMO.Control.Select({
      el: this.cont.find("select#percent_style"),
      objs: this.options.percent_types.map(function(pt){ return {name: pt, label: I18n.t("report/report.percent_types." + pt)}; }),
      id_key: "name",
      txt_key: "label"
    })
    this.percent_type.change(function() { _this.broadcast_change("percent_type"); });

    // build bar style chooser
    this.bar_style = new ELMO.Control.RadioGroup({inputs: this.cont.find("input[name='bar_style']")});
    this.bar_style.change(function() { _this.broadcast_change("bar_style"); });

    // build question label chooser
    this.question_labels = new ELMO.Control.RadioGroup({inputs: this.cont.find("input[name='question_labels']")});
    this.question_labels.change(function() { _this.broadcast_change("question_labels"); });

    // build question order chooser
    this.question_order = new ELMO.Control.RadioGroup({inputs: this.cont.find("input[name='question_order']")});
    this.question_order.change(function() { _this.broadcast_change("question_order"); });

    // build group by tag chooser
    this.group_by_tag = $('#group_by_tag');
    this.group_by_tag.change(function() { _this.broadcast_change("group_by_tag"); });

    // build disaggregation chooser
    this.disagg_question_chooser = new ELMO.Report.DisaggQuestionSelector(this.menus.question);
    this.disagg_question_chooser.field.change(function(){ _this.broadcast_change("disagg_question_id"); })

    // setup an event handler for the disaggregate checkbox
    this.cont.find("#disaggregate").change(function(e){
      // if the box has just become checked
      // set the value of the disagg_question_chooser to the first geographic question, if one exists
      if ($(e.target).is(':checked'))
        self.disagg_question_chooser.select_first_geographic();

      _this.broadcast_change("disaggregate");
    })

    // build text responses chooser
    this.text_responses = new ELMO.Control.RadioGroup({inputs: this.cont.find("input[name='text_responses']")});
    this.text_responses.change(function() { _this.broadcast_change("text_responses"); });

    // report title field
    this.title_fld = this.cont.find("input#report_title");

    // register fields to watch for changes
    this.attribs_to_watch = {display_type: true, report_type: true, tally_type: true, report_title: true,
      disaggregate: true, disagg_question_id: true, form_id: true};
  }

  klass.prototype.update = function(report) {
    // store report reference
    this.report = report;

    // update controls
    this.tally_type.update(report.attribs.tally_type)
    this.tally_type.enable(!this.report.has_run());
    this.form_id.update(report.attribs.form_id);
    this.display_type.update(report.attribs.display_type);
    this.percent_type.update(report.attribs.percent_type);
    this.bar_style.update(report.attribs.bar_style);
    this.question_labels.update(report.attribs.question_labels);
    this.question_order.update(report.attribs.question_order);
    this.group_by_tag.prop('checked', report.attribs.group_by_tag);
    this.disagg_question_chooser.update(report);
    this.text_responses.update(report.attribs.text_responses);
    this.title_fld.val(report.attribs.name);

    var is_tally = this.report.attribs.type == 'Report::TallyReport';
    var show;

    show = is_tally;
    this.tally_type.closest(".section")[show ? "show" : "hide"]();
    if (!show) this.tally_type.clear();

    this.display_type.closest(".section")[show ? "show" : "hide"]();
    if (!show) this.display_type.clear();

    // show/hide standard form report stuff
    show = this.report.attribs.type == "Report::StandardFormReport";
    this.form_id.closest(".section")[show ? "show" : "hide"]();
    if (!show) this.form_id.clear();
    this.question_order.closest(".section")[show ? "show" : "hide"]();
    if (!show) this.question_order.clear();
    this.cont.find('#disaggregate').closest('.section')[show ? "show" : "hide"]();
    this.text_responses.closest(".section")[show ? "show" : "hide"]();
    if (!show) this.text_responses.clear();
    this.group_by_tag.closest(".section")[show ? "show" : "hide"]();
    if (!show) this.group_by_tag.prop('checked', false);

    if (show) {
      // set value of disaggregate checkbox
      this.cont.find('#disaggregate').attr('checked', report.attribs.disaggregate);

      // if box is checked then select should be visible, else, not
      this.cont.find('#disagg_qing')[report.attribs.disaggregate ? 'show' : 'hide']();
    } else {
      this.cont.find('#disaggregate').attr('checked', false);
      this.disagg_question_chooser.field.clear();
    }

    show = this.report.attribs.display_type == "table" && is_tally;
    this.percent_type.closest(".section")[show ? "show" : "hide"]();
    if (!show) this.percent_type.clear();

    show = this.report.attribs.display_type == "bar_chart";
    this.bar_style.closest(".section")[show ? "show" : "hide"]();
    if (!show) this.bar_style.clear();
  }

  // extracts data from the view into the model
  klass.prototype.extract = function() {
    this.report.attribs.tally_type = this.tally_type.get();
    this.report.attribs.form_id = this.form_id.get();
    this.report.attribs.display_type = this.display_type.get();
    this.report.attribs.percent_type = this.percent_type.get();
    this.report.attribs.bar_style = this.bar_style.get();
    this.report.attribs.question_labels = this.question_labels.get();
    this.report.attribs.question_order = this.question_order.get();
    this.report.attribs.group_by_tag = this.group_by_tag.prop('checked');
    this.report.attribs.disaggregate = this.cont.find('#disaggregate').is(':checked');
    this.report.attribs.disagg_question_id = this.cont.find('#disaggregate').is(':checked') ? this.disagg_question_chooser.get() : null;
    this.report.attribs.text_responses = this.text_responses.get();
    this.report.attribs.name = this.title_fld.val();
  }

  klass.prototype.fields_for_validation_errors = function() {
    return ['form_id', 'tally_type', 'question_order', 'text_responses', 'name'];
  }

}(ELMO.Report));
