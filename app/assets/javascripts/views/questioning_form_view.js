/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
// Newer view to manage Questioning form.
const Cls = (ELMO.Views.QuestioningFormView = class QuestioningFormView extends ELMO.Views.QuestionFormView {
  static initClass() {
    this.prototype.events = {
      'change select[id$="_qtype_name"]': 'toggleFields',
      'change select[id$="_option_set_id"]': 'toggleFields',
      'change select[id$="_metadata_type"]': 'toggleFields',
      'click #questioning_read_only': 'toggleFields',
      'click #questioning_required': 'toggleFields',
      'keyup #questioning_default': 'toggleFields',
    };
  }

  initialize(options) {
    this.defaultableTypes = options.defaultableTypes;
    return this.toggleFields();
  }

  toggleFields() {
    super.toggleFields();
    this.showField('default', this.showDefault());
    this.showField('read_only', this.showReadOnly());
    this.showField('required', this.showRequired());
    this.showField('all_levels_required', this.showAllLevelsRequired());
    this.showField('hidden', this.showHidden());
    this.showField('display_logic', this.showDisplayLogic());
    return this.showField('skip_logic', this.showSkipLogic());
  }

  showDefault() {
    return this.defaultableTypes.indexOf(this.fieldValue('qtype_name')) !== -1;
  }

  showReadOnly() {
    return this.showDefault() && ((this.fieldValue('default') || '').trim() !== '');
  }

  showRequired() {
    return !this.fieldValue('read_only') && super.metadataTypeBlank();
  }

  showAllLevelsRequired() {
    return this.showRequired()
      && (this.fieldValue('required').toString() === 'true')
      && (this.fieldValue('qtype_name') === 'select_one')
      && this.selectedOptionData('option_set_id', 'multilevel');
  }

  showHidden() {
    return super.metadataTypeBlank();
  }

  showDisplayLogic() {
    return super.metadataTypeBlank();
  }

  showSkipLogic() {
    return super.metadataTypeBlank();
  }
});
Cls.initClass();
