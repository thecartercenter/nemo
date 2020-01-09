/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
ELMO.Views.UserLoginInstructionsView = class UserLoginInstructionsView extends ELMO.Views.ApplicationView {
  get events() {
    return {
      'click .masked a.toggle-mask': 'unmask',
      'click .unmasked a.toggle-mask': 'mask',
    };
  }

  unmask(event) {
    event.preventDefault();
    const container = $(event.target).closest('.mask-container');
    container.find('.masked').addClass('d-none');
    return container.find('.unmasked').removeClass('d-none');
  }

  mask(event) {
    event.preventDefault();
    const container = $(event.target).closest('.mask-container');
    container.find('.unmasked').addClass('d-none');
    return container.find('.masked').removeClass('d-none');
  }
};
