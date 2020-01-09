/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
// Evaluates a single condition in the responses view.
ELMO.Views.ResponseConditionGroupChecker = class ResponseConditionGroupChecker extends ELMO.Views.ApplicationView {
  initialize(options) {
    this.conditionGroup = options.group;
    return this.checkers = this.conditionGroup.members.map((m) => {
      if (m.type === 'ConditionGroup') {
        return new ELMO.Views.ResponseConditionGroupChecker({ el: this.$el, refresh: options.refresh, group: m });
      }
      return new ELMO.Views.ResponseConditionChecker({ el: this.$el, refresh: options.refresh, condition: m });
    });
  }

  // Unlike the manager and the leaf node checkers, do NOT do anything to initialize here. The manager takes
  // care of that by calling refresh in its initialization.

  // Evaluates the children and returns the result.
  evaluate() {
    if (this.conditionGroup.trueIf === 'always') {
      return this.applyNegation(true);
    } else if (this.conditionGroup.trueIf === 'all_met') {
      return this.applyNegation(this.childrenAllMet());
    } // any_met
    return this.applyNegation(this.childrenAnyMet());
  }

  childrenAllMet() {
    const results = this.results();
    return results.indexOf(false) === -1;
  }

  childrenAnyMet() {
    return this.results().indexOf(true) !== -1;
  }

  applyNegation(bool) {
    if (this.conditionGroup.negate) {
      return !bool;
    }
    return bool;
  }

  results() {
    return this.checkers.map((c) => c.evaluate());
  }
};
