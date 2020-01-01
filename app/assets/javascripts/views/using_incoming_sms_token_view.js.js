/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const Cls = (ELMO.Views.UsingIncomingSmsTokenModalView = class UsingIncomingSmsTokenModalView extends ELMO.Views.ApplicationView {
  static initClass() {
    this.prototype.el = '#using-incoming-sms-token-modal';
  }

  initialize(options) {
    this.$('.modal-body').html(options.html);
    return this.show();
  }

  show() {
    return this.$el.modal('show');
  }
});
Cls.initClass();
