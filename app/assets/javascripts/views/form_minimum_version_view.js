/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
ELMO.Views.FormMinimumVersionView = class FormMinimumVersionView extends ELMO.Views.ApplicationView {
  get el() { return 'form.form_form'; }

  get events() { return { 'regenerable-field:updated .form_current_version_name': 'handleFormVersionIncremented' }; }

  handleFormVersionIncremented(event, responseData) {
    const val = this.$('.form_minimum_version_id select').val();
    this.$('.form_minimum_version_id select').html(responseData.minimum_version_options);
    return this.$('.form_minimum_version_id select').val(val);
  }
};
