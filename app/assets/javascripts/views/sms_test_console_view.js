// TODO: This file was created by bulk-decaffeinate.
// Fix any style issues and re-enable lint.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const Cls = (ELMO.Views.SmsTestConsoleView = class SmsTestConsoleView extends ELMO.Views.ApplicationView {
  static initClass() {
    this.prototype.el = 'form#new_sms_test';

    this.prototype.events = { submit: 'submit' };
  }

  submit(e) {
    e.preventDefault();

    if (this.$('input#sms_test_from').val().trim() === '') {
      const msg = I18n.t('activerecord.errors.messages.blank');
      this.$('.sms_test_from .control').prepend(`<div class="form-errors">${msg}</div>`);
      return;
    }

    ELMO.app.loading(true);
    this.$('.sms_test_result').hide();
    this.$('.form-errors').remove();

    return $.ajax({
      type: 'POST',
      url: this.$el.attr('action'),
      data: this.$el.serialize(),
      success: (data) => this.$('.sms_test_result div').html(data),
      error: () => this.$('.sms_test_result div').html(`<em>${I18n.t('sms_console.submit_error')}</em>`),
      complete: () => {
        ELMO.app.loading(false);
        return this.$('.sms_test_result').show();
      },
    });
  }
});
Cls.initClass();
