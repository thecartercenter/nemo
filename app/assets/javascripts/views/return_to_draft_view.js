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
    $('#override').val('');
    this.accepted = false;
  }

  handleLinkClicked(event) {
    // If accept button was clicked, we just let the link do its thing.
    if (this.accepted) return;

    // Otherwise show the modal instead.
    event.preventDefault();
    event.stopPropagation();
    $('#return-to-draft-modal').modal('show');
  }

  handleModalShown() {
    $('#override').focus();
  }

  handleKeypress(event) {
    if (event.key === 'Enter' && this.isCorrectKeyword()) {
      $('#return-to-draft-modal .btn-primary').trigger('click');
    }
  }

  handleKeyup() {
    $('.btn-primary').toggle(this.isCorrectKeyword());
  }

  handleAcceptClicked() {
    this.accepted = true;
    // Trigger another click on the link so we can use the data-method machinery to make the PUT request.
    $('.return-to-draft-link').trigger('click');
  }

  isCorrectKeyword() {
    return $('#override').val() === this.keyword;
  }
};
