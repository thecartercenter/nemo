/* eslint-disable
    consistent-return,
    no-multi-assign,
    no-return-assign,
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
// Controls "return to draft status" button and modal.
const Cls = (ELMO.Views.ReturnToDraftView = class ReturnToDraftView extends ELMO.Views.ApplicationView {
  static initClass() {
    this.prototype.el = '#action-links-and-modal';

    this.prototype.events = {
      'click .return-to-draft-link': 'handleLinkClicked',
      'shown.bs.modal #return-to-draft-modal': 'handleModalShown',
      'click #return-to-draft-modal .btn-primary': 'handleAcceptClicked',
      'keyup #override': 'handleKeyup',
    };
  }

  initialize(params) {
    this.keyword = params.keyword;
    this.$('#override').val(''); // Ensure box is empty in case cached.
    return this.accepted = false;
  }

  handleLinkClicked(event) {
    // If accept button was clicked, we just let the link do it's thing.
    if (this.accepted) { return; }

    event.preventDefault();
    event.stopPropagation();
    return this.$('#return-to-draft-modal').modal('show');
  }

  handleModalShown(event) {
    return this.$('#override').focus();
  }

  handleKeyup(event) {
    return this.$('.btn-primary').toggle(this.$(event.target).val() === this.keyword);
  }

  handleAcceptClicked(event) {
    this.accepted = true;
    // Trigger another click on the link so we can use the data-method machinery to make the PUT request.
    return this.$('.return-to-draft-link').trigger('click');
  }
});
Cls.initClass();
