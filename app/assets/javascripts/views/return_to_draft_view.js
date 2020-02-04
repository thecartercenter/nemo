// Controls "return to draft status" button and modal.
ELMO.Views.ReturnToDraftView = class ReturnToDraftView extends ELMO.Views.ApplicationView {
  get el() { return '#action-links-and-modal'; }

  get events() {
    return {
      'click .return-to-draft-link': 'handleLinkClicked',
      'shown.bs.modal #return-to-draft-modal': 'handleModalShown',
      'click #return-to-draft-modal .btn-primary': 'handleAcceptClicked',
      'keyup #override': 'handleKeyup',
    };
  }

  initialize(params) {
    this.keyword = params.keyword;
    // Ensure box is empty in case cached.
    this.$('#override').val('');
    this.accepted = false;
  }

  handleLinkClicked(event) {
    // If accept button was clicked, we just let the link do its thing.
    if (this.accepted) return;

    // Otherwise show the modal instead.
    event.preventDefault();
    event.stopPropagation();
    this.$('#return-to-draft-modal').modal('show');
  }

  handleModalShown() {
    this.$('#override').focus();
  }

  handleKeyup(event) {
    const correctKeyword = this.$(event.target).val() === this.keyword;
    this.$('.btn-primary').toggle(correctKeyword);
  }

  handleAcceptClicked() {
    this.accepted = true;
    // Trigger another click on the link so we can use the data-method machinery to make the PUT request.
    this.$('.return-to-draft-link').trigger('click');
  }
};
