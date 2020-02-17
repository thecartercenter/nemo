/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
ELMO.Views.RegenerableFieldView = class RegenerableFieldView extends ELMO.Views.ApplicationView {
  get events() { return { 'click .regenerate': 'regenerateField' }; }

  regenerateField(event) {
    event.preventDefault();

    const target = $(event.currentTarget);
    const handler = target.data('handler');
    const confirmMsg = target.data('confirm-msg');

    const container = target.closest('.regenerable-field');
    const displayEl = container.find('span[data-value]');
    const inlineLoadInd = container.find('div.inline-load-ind img');
    const successIndicator = container.find('.success');
    const errorIndicator = container.find('.failure');

    // If confirm text is provided and there is a current value,
    // show a confirmation dialog
    if (confirmMsg && displayEl.data('value') && !window.confirm(confirmMsg)) {
      return false;
    }

    // Disable the button and ensure that only the loading indicator is shown
    target.attr('disabled', 'disabled');
    successIndicator.hide();
    errorIndicator.hide();
    inlineLoadInd.show();

    return $.ajax({
      method: 'patch',
      url: handler,
      success: (data) => {
        // Trigger an event that other views can subscribe to, with the response data as the first param.
        this.$el.trigger('regenerable-field:updated', [data]);
        if (displayEl.length > 0) {
          displayEl.data({ value: data.value });
          displayEl.text(data.value);
        }
        inlineLoadInd.hide();
        return successIndicator.show();
      },
      error() {
        if (ELMO.unloading) return;
        inlineLoadInd.hide();
        return errorIndicator.show();
      },
      complete() {
        return target.removeAttr('disabled');
      },
    });
  }
};
