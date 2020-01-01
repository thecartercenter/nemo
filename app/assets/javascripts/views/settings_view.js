/* eslint-disable
    camelcase,
    no-multi-assign,
    no-unused-vars,
*/
// TODO: This file was created by bulk-decaffeinate.
// Fix any style issues and re-enable lint.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const Cls = (ELMO.Views.SettingsView = class SettingsView extends ELMO.Views.ApplicationView {
  static initClass() {
    this.prototype.el = 'form.setting_form';

    this.prototype.events = {
      'click #external_sql .control a': 'select_external_sql',
      'click .adapter-settings a.show-credential-fields': 'show_change_credential_fields',
      'click .using-incoming-sms-token': 'show_using_incoming_sms_token_modal',
      'click .using-universal-sms-token': 'show_using_universal_sms_token_modal',
      'click .credential-fields input[type=checkbox]:checked': 'clear_sms_fields',
    };
  }

  initialize(options) {
    this.need_credentials = options.need_credentials || {};
    return this.show_credential_fields_with_errors();
  }

  select_external_sql(event) {
    this.$('#external_sql .control pre').selectText();
    return false;
  }

  show_change_credential_fields(event) {
    this.$(event.target).hide();
    this.$(event.target).closest('.adapter-settings').find('.credential-fields').show();
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
    const adapters = this.$('.form-field.has-errors:hidden').closest('.adapter-settings');
    this.$(adapters).find('.credential-fields').show();
    return this.$(adapters).find('a.show-credential-fields').hide();
  }

  clear_sms_fields(event) {
    const inputs = this.$(event.target).closest('.adapter-settings').find('input[type=text]');
    return this.$(inputs).val('');
  }
});
Cls.initClass();
