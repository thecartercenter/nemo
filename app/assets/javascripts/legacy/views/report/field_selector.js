// ELMO.Report.FieldSelector
// Models a dropdown box for choosing a field, which is either an attribute or a question.
(function (ns, klass) {
  // constructor
  ns.FieldSelector = klass = function (cont, menus, question_types) {
    this.cont = cont;
    this.menus = menus;
    this.question_types = question_types;
    this.visible = true;

    // create the select object
    this.field = new ELMO.Control.Select({
      el: this.cont.find('select.field'),
      grouped: true,
      prompt: true,
    });
  };

  klass.prototype.update = function (report, calc_attribs) {
    this.report = report;
    this.calc = calc_attribs;

    this.field.update_objs([
      {
        label: I18n.t('report/report.attribute.other'),
        objs: this.menus.attrib.objs,
        id_key(obj) { return `attrib1_name:${obj.name}`; },
        txt_key: 'title',
      }, {
        label: I18n.t('activerecord.models.question.other'),
        objs: this.menus.question.filter({ form_ids: this.report.attribs.form_ids, question_types: this.question_types }),
        id_key(obj) { return `question1_id:${obj.id}`; },
        txt_key: 'code',
      },
    ]);

    let key;
    if (!this.calc) key = '';
    else if (this.calc.question1_id) key = `question1_id:${this.calc.question1_id}`;
    else key = `attrib1_name:${this.calc.attrib1_name}`;

    this.field.update(key);
  };

  // removes the DOM object, sets visible to false, and sets the selected value to nil
  klass.prototype.remove = function () {
    const self = this;
    self.cont.remove();
    self.visible = false;
    self.field.clear();
  };

  // returns whether this selector represents a field that exists in the database
  klass.prototype.exists_in_db = function () {
    return this.calc && this.calc.id;
  };

  klass.prototype.unselected = function () {
    return !this.field.get();
  };

  klass.prototype.get = function () {
    let field_val = this.field.get();
    const field_params = {};

    if (this.exists_in_db()) field_params.id = this.calc.id;

    if (!field_val) {
      if (field_params.id) field_params._destroy = true;
    } else {
      field_val = field_val.split(':');

      // set both values blank to start
      field_params.question1_id = '';
      field_params.attrib1_name = '';

      // build the attrib obj
      field_params.type = 'Report::IdentityCalculation';
      field_params[field_val[0]] = field_val[1];
    }

    return field_params;
  };
}(ELMO.Report));
