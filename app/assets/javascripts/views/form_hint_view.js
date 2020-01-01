// TODO: This file was created by bulk-decaffeinate.
// Fix any style issues and re-enable lint.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
// Initializes the popovers for hints on a form. Should be called for any form with hints.
ELMO.Views.FormHintView = class FormHintView extends ELMO.Views.ApplicationView {
  initialize(params) {
    return this.$('a.hint').popover({ html: true });
  }
};
