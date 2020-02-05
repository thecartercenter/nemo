// Controls "return to draft status" button and modal.
ELMO.Views.ReturnToDraftView = class ReturnToDraftView extends ELMO.Views.ApplicationView {
  get el() { return '#action-links-and-modal'; }

  get events() {
    return {
      'click .return-to-draft-link': 'handleLinkClicked',
      'shown.bs.modal #return-to-draft-modal': 'handleModalShown',
      'click #return-to-draft-modal .btn-primary': 'handleAcceptClicked',
      'keypress #override': 'handleKeypress',
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

  handleKeypress(event) {
    if (event.key === 'Enter' && this.isCorrectKeyword()) {
      this.$('#return-to-draft-modal .btn-primary').trigger('click');
    }
  }

  handleKeyup() {
    this.$('.btn-primary').toggle(this.isCorrectKeyword());
  }

  handleAcceptClicked() {
    this.accepted = true;
    // Trigger another click on the link so we can use the data-method machinery to make the PUT request.
    this.$('.return-to-draft-link').trigger('click');
  }

  isCorrectKeyword() {
    return this.$('#override').val() === this.keyword;
  }
};
