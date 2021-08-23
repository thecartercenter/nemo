/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
ELMO.Views.SettingsView = class SettingsView extends ELMO.Views.ApplicationView {
  get el() { return 'form.setting_form'; }

  get events() {
    return {
      'click #copy-btn-external_sql': 'selectExternalSql',
      'click .adapter-settings a.show-credential-fields': 'show_change_credential_fields',
      'click .using-incoming-sms-token': 'show_using_incoming_sms_token_modal',
      'click .using-universal-sms-token': 'show_using_universal_sms_token_modal',
      'click .credential-fields input[type=checkbox]:checked': 'clear_sms_fields',
    };
  }

  initialize(options) {
    this.need_credentials = options.need_credentials || {};
    new Clipboard('#copy-btn-external_sql');
    return this.show_credential_fields_with_errors();
  }

  selectExternalSql() {
    $('#copy-value-external_sql').selectText();
  }

  show_change_credential_fields(event) {
    $(event.target).hide();
    $(event.target).closest('.adapter-settings').find('.credential-fields').show();
    return false;
  }

  show_using_universal_sms_token_modal(event) {
    event.preventDefault();
    ELMO.app.loading(true);

    return $.ajax({
      url: ELMO.app.url_builder.build('settings', 'using_incoming_sms_token_message?missionless=1'),
      success(data) {
        return new ELMO.Views.UsingIncomingSmsTokenModalView({ html: data.message.replace(/\n/g, '<br/>') });
      },
      complete() {
        return ELMO.app.loading(false);
      },
    });
  }

  show_using_incoming_sms_token_modal(event) {
    event.preventDefault();
    ELMO.app.loading(true);

    return $.ajax({
      url: ELMO.app.url_builder.build('settings', 'using_incoming_sms_token_message'),
      success(data) {
        return new ELMO.Views.UsingIncomingSmsTokenModalView({ html: data.message.replace(/\n/g, '<br/>') });
      },
      complete() {
        return ELMO.app.loading(false);
      },
    });
  }

  show_credential_fields_with_errors() {
    const adapters = $('.form-field.has-errors:hidden').closest('.adapter-settings');
    $(adapters).find('.credential-fields').show();
    return $(adapters).find('a.show-credential-fields').hide();
  }

  clear_sms_fields(event) {
    const inputs = $(event.target).closest('.adapter-settings').find('input[type=text]');
    return $(inputs).val('');
  }
};
