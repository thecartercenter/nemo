// Initializes the popovers for hints on a form. Should be called for any form with hints.
ELMO.Views.FormHintView = class FormHintView extends ELMO.Views.ApplicationView {
  get el() {
    // el needs to be the full page body so we can get click events for dismissing the popover
    return 'body';
  }

  get events() {
    return {
      'click a.hint': 'toggle',
      click: 'dismissAll',
    };
  }

  initialize() {
    this.$('a.hint').popover({ html: true });
  }

  toggle(e) {
    // Show the popover when link is clicked. Don't propagate up so the dismissAll method doesn't fire.
    this.$(e.currentTarget).popover('show');
    e.stopPropagation();
  }

  dismissAll(e) {
    // Don't dismiss anything if click was on a popover itself.
    if (this.$(e.target).parents('.popover').length) {
      return;
    }
    this.$('a.hint').popover('hide');
  }
};
