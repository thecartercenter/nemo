/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
// Newer view to manage Question form.
ELMO.Views.QuestionFormView = class QuestionFormView extends ELMO.Views.FormView {
  // We use $= because the start of the ID can vary depending on whether
  // it's a question form or questioning form.
  // Note, these events must be redefined in any child classes.
  get events() {
    return {
      'change select[id$="_qtype_name"]': 'toggleFields',
      'change select[id$="_metadata_type"]': 'toggleFields',
    };
  }

  initialize(options) {
    return this.toggleFields();
  }

  toggleFields() {
    this.showField('auto_increment', this.showAutoIncrement());
    return this.showField('metadata_type', this.showMetaDataType());
  }

  showAutoIncrement() {
    return this.fieldValue('qtype_name') === 'counter';
  }

  showMetaDataType() {
    return this.fieldValue('qtype_name') === 'datetime';
  }

  metadataTypeBlank() {
    return !this.showMetaDataType() || (this.fieldValue('metadata_type') === '');
  }

  // Gets form field value, or static value if field is read-only
  fieldValue(attrib) {
    const div = this.fieldElement(attrib);
    if (div.is('.read-only')) {
      const wrapper = div.find('.ro-val');
      if (typeof wrapper.data('val') !== 'undefined') { return wrapper.data('val'); } return wrapper.text();
    }
    // Rails checkbox fields have a hidden field followed by a checkbox. We need to ignore the hidden.
    const field = div.find('input[type!=hidden], select, textarea');
    if (field.attr('type') === 'checkbox') {
      return field.is(':checked');
    }
    return field.val();
  }

  // Gets a data- value from the selected option for the given select-type field,
  // or from the div.ro-val tag if read only.
  selectedOptionData(attrib, dataAttrib) {
    const div = this.fieldElement(attrib);
    if (div.is('.read-only')) {
      return div.find('.ro-val').data(dataAttrib);
    }
    return div.find('option:selected').data(dataAttrib);
  }

  fieldElement(attrib) {
    return this.$(`.form-field[data-field-name=${attrib}] .control`);
  }
};
