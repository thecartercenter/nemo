/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
ELMO.Views.BroadcastsView = class BroadcastsView extends ELMO.Views.FormView {
  get el() { return '.broadcast_form'; }

  get events() {
    return {
      'change #broadcast_medium': 'medium_changed',
      'change #broadcast_recipient_selection': 'recipient_selection_changed',
      'keyup #broadcast_body': 'update_char_limit',
    };
  }

  initialize(options) {
    this.medium_changed();
    this.recipient_selection_changed();

    return this.$('#broadcast_recipient_ids').select2({ ajax: (new ELMO.Utils.Select2OptionBuilder()).ajax(options.recipient_options_url) });
  }

  recipient_selection_changed(e) {
    const specific = this.form_value('broadcast', 'recipient_selection') === 'specific';
    return this.showField('recipient_ids', specific);
  }

  medium_changed(e) {
    const selected = this.form_value('broadcast', 'medium');
    const sms_possible = (selected !== 'email_only') && (selected !== '');
    this.$('#char_limit').toggle(sms_possible);
    this.showField('which_phone', sms_possible);
    this.showField('subject', !sms_possible);
    if (sms_possible) { return this.update_char_limit(); }
  }

  update_char_limit() {
    const div = this.$('#char_limit');
    if (div.is(':visible')) {
      const diff = 140 - this.$('#broadcast_body').val().length;
      const msg = I18n.t(`broadcast.chars.${diff >= 0 ? 'remaining' : 'too_many'}`);
      div.text(`${Math.abs(diff)} ${msg}`);
      return div.css('color', diff >= 0 ? 'black' : '#d02000');
    }
  }
};
