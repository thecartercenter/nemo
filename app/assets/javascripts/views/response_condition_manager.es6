/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
// Handles conditional logic for a single question/answer pair in the response view based on conditions.
ELMO.Views.ResponseConditionManager = class ResponseConditionManager extends ELMO.Views.ApplicationView {
  get events() { return { submit: 'clearOnSubmitIfFalse' }; }

  initialize(options) {
    this.item = options.item;
    this.rootConditionGroup = this.item.conditionGroup;
    this.result = true;
    this.rootChecker = new ELMO.Views.ResponseConditionGroupChecker({
      el: this.$el,
      refresh: this.refresh.bind(this),
      group: this.rootConditionGroup,
    });

    // The leaf node checkers have set their results when they were initialized, and now refresh
    // will call evaluate down the tree to read the leaf node checker results.
    return this.refresh();
  }

  // Gathers results from all checkers and shows/hides the field based on them.
  refresh() {
    const newResult = this.rootChecker.evaluate();

    if (newResult !== this.result) {
      this.result = newResult;
      this.$el.toggle(this.result);
      this.$el.find('input.relevant').first().val(this.result ? 'true' : 'false');

      // Simulate a change event on the control so that later conditions will be re-evaluated.
      return this.$el.find('div.control').find('input, select, textarea').first().trigger('change');
    }
  }

  // When the form is submitted, clears the answer if the eval_result is false.
  clearOnSubmitIfFalse() {
    if (!this.result) {
      this.$el.find("input[type='text'], textarea, select").val('');
      return this.$el.find("input[type='checkbox']:checked, input[type='radio']:checked").each(function () {
        return $(this).removeAttr('checked');
      });
    }
  }

  results() {
    return this.checkers.map((c) => c.result);
  }
};
