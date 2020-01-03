// a select box that shows only questions that can be used to disaggregate the present form
// ELMO.Report.DisaggQuestionSelector
(function (ns, klass) {
  // constructor
  ns.DisaggQuestionSelector = klass = function (question_menu) {
    this.question_menu = question_menu;
    this.visible = true;

    // create the select object
    this.field = new ELMO.Control.Select({
      el: $('select#disagg_qing'),
      prompt: true,
      objs: [],
      id_key: 'id',
      txt_key: 'code',
    });
  };

  // called when the form_id or disagg_question_id has been updated, thus necessitating a change to the available/selected options
  klass.prototype.update = function (report) {
    this.report = report;

    // get the appropriate questions
    const questions = this.filter_questions(report.attribs.form_id);

    // update our select control with the new questions
    this.field.update_objs(questions);

    // update the select control's value
    this.field.update(report.attribs.disagg_question_id);
  };

  // gets the current field value
  klass.prototype.get = function () {
    return this.field.get();
  };

  // selects the first geographic question in the dropdown, or does nothing if none available
  klass.prototype.select_first_geographic = function () {
    // get geographic questions
    const geo_qs = this.filter_questions(this.report.attribs.form_id, true);

    // if there were any matches, update the field to the match's id
    if (geo_qs.length > 0) this.field.update(geo_qs[0].id);
  };

  // gets questions that appear on the form with the given form_id, that are disaggregatable, and that are optionally geographic
  // if form_id is falsy, returns an empty array
  // geographic is optional
  klass.prototype.filter_questions = function (form_id, geographic) {
    if (!form_id) return [];

    const params = { form_ids: [form_id] };

    // add disaggregatable types
    params.question_types = ['select_one'];

    // add geographic if specified
    if (geographic !== undefined) params.geographic = geographic;

    return this.question_menu.filter(params);
  };
}(ELMO.Report));
