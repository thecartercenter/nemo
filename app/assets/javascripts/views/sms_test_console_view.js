/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
ELMO.Views.SmsTestConsoleView = class SmsTestConsoleView extends ELMO.Views.ApplicationView {
  get el() { return 'form#new_sms_test'; }

  get events() { return { submit: 'submit' }; }

  submit(e) {
    e.preventDefault();

    if (this.$('input#sms_test_from').val().trim() === '') {
      const msg = I18n.t('activerecord.errors.messages.blank');
      $('.sms_test_from .control').prepend(`<div class="form-errors">${msg}</div>`);
      return;
    }

    ELMO.app.loading(true);
    $('.sms_test_result').hide();
    $('.form-errors').remove();

    return $.ajax({
      type: 'POST',
      url: this.$el.attr('action'),
      data: this.$el.serialize(),
      success: (data) => $('.sms_test_result div').html(data),
      error: () => $('.sms_test_result div').html(`<em>${I18n.t('sms_console.submit_error')}</em>`),
      complete: () => {
        ELMO.app.loading(false);
        return $('.sms_test_result').show();
      },
    });
  }
};
