// TODO: This file was created by bulk-decaffeinate.
// Fix any style issues and re-enable lint.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const Cls = (ELMO.Views.FormMinimumVersionView = class FormMinimumVersionView extends ELMO.Views.ApplicationView {
  static initClass() {
    this.prototype.el = 'form.form_form';

    this.prototype.events = { 'regenerable-field:updated .form_current_version_name': 'handleFormVersionIncremented' };
  }

  handleFormVersionIncremented(event, responseData) {
    const val = this.$('.form_minimum_version_id select').val();
    this.$('.form_minimum_version_id select').html(responseData.minimum_version_options);
    return this.$('.form_minimum_version_id select').val(val);
  }
});
Cls.initClass();
