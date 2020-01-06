/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
ELMO.Views.FormSettingsView = class FormSettingsView extends ELMO.Views.ApplicationView {
  get el() { return 'form.form_form'; }

  get events() {
    return {
      'click .more-settings': 'show_setting_fields',
      'click .less-settings': 'hide_setting_fields',
      'click #form_smsable': 'show_hide_sms_settings',
      'click #form_sms_relay': 'show_hide_recipients',
    };
  }

  initialize(options) {
    this.show_fields_with_errors();
    this.show_hide_sms_settings();
    this.show_hide_recipients();
    this.recipient_options_url = options.recipient_options_url;
    return this.init_recipient_select();
  }

  show_setting_fields(event) {
    if (event) { event.preventDefault(); }
    $('.more-settings').hide();
    $('.less-settings').show();
    return $('.setting-fields').show();
  }

  hide_setting_fields(event) {
    if (event) { event.preventDefault(); }
    $('.more-settings').show();
    $('.less-settings').hide();
    return $('.setting-fields').hide();
  }

  show_fields_with_errors() {
    if (this.$('.setting-fields .form-field.has-errors').length > 0) {
      return this.show_setting_fields();
    }
  }

  show_hide_sms_settings() {
    let m;
    const read_only = this.$('#smsable div.ro-val').length > 0;
    if (read_only) {
      m = this.$('#smsable div.ro-val').data('val') ? 'show' : 'hide';
    } else {
      m = this.$('#form_smsable').is(':checked') ? 'show' : 'hide';
    }

    return this.$('.sms-fields')[m]();
  }

  show_hide_recipients() {
    let m;
    const read_only = this.$('#sms_relay div.ro-val').length > 0;
    if (read_only) {
      m = this.$('#sms_relay div.ro-val').data('val') ? 'show' : 'hide';
    } else {
      m = this.$('#form_sms_relay').is(':checked') ? 'show' : 'hide';
    }

    return this.$('.form_recipient_ids')[m]();
  }

  init_recipient_select() {
    return this.$('#form_recipient_ids').select2({ ajax: (new ELMO.Utils.Select2OptionBuilder()).ajax(this.recipient_options_url) });
  }
};
