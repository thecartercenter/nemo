/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
ELMO.Views.UsingIncomingSmsTokenModalView = class UsingIncomingSmsTokenModalView extends ELMO.Views.ApplicationView {
  get el() { return '#using-incoming-sms-token-modal'; }

  initialize(options) {
    this.$('.modal-body').html(options.html);
    return this.show();
  }

  show() {
    return this.$el.modal('show');
  }
};
