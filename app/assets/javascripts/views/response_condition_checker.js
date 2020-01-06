/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
// Evaluates a single condition in the responses view.
ELMO.Views.ResponseConditionChecker = class ResponseConditionChecker extends ELMO.Views.ApplicationView {
  initialize(options) {
    this.refresh = options.refresh;
    this.condition = options.condition;

    this.rqElement = this.leftQingElement(this.$el, this.condition.leftQingId);
    this.rqType = this.rqElement.data('qtype-name');
    this.result = true;

    // These handlers must be set dynamically based on rqElement.
    this.rqElement.find('div.control').find('input, select, textarea').on('change', () => this.checkAndTell());
    this.rqElement.find('div.control input[type=text]').on('keyup', () => this.checkAndTell());
    this.rqElement.find('div.control input[type=number]').on('keyup', () => this.checkAndTell());
    if (this.rqType === 'long_text') { this.textarea().on('tbwchange', () => this.checkAndTell()); }

    // Set result to initial value on page load. Don't refresh because the manager calls refresh just
    // once on page load (if we 'tell' when each checker initializes, the manager would evaluate many times)
    return this.check();
  }

  checkAndTell() {
    this.check();
    return this.refresh();
  }

  evaluate() {
    return this.result;
  }

  // Checks the result of the condition and sets the result value.
  check() {
    // Temporarily ignoring these.
    if (this.condition.rightSideIsQing) {
      this.result = true;
      return;
    }

    if (!this.rqElement.is(':visible')) {
      this.result = false;
      return;
    }

    const actual = this.actual();
    const expected = this.expected();

    // For select_one questions, the actual will be an array of selected option_node_ids.
    // We should return true if the expected option_node_id is anywhere in that list.
    // So `eq` just becomes `inc` and `neq` becomes `ninc`.
    // We could label it this way in the condition form but it seems that would be confusing.
    let {
      op,
    } = this.condition;
    if (this.rqType === 'select_one') {
      if (op === 'eq') { op = 'inc'; }
      if (op === 'neq') { op = 'ninc'; }
    }

    switch (op) {
      case 'eq': this.result = this.testEquality(actual, expected); break;
      case 'lt': this.result = actual < expected; break;
      case 'gt': this.result = actual > expected; break;
      case 'leq': this.result = actual <= expected; break;
      case 'geq': this.result = actual >= expected; break;
      case 'neq': this.result = this.testInequality(actual, expected); break;
      case 'inc': this.result = actual.indexOf(expected) !== -1; break;
      case 'ninc': this.result = actual.indexOf(expected) === -1; break;
      default: this.result = false;
    }
  }

  // We walk up the node tree until a descendant node contains the given qing ID.
  // Once found we return the first matching child.
  leftQingElement(srcElement, leftQingId) {
    const parent = srcElement.parent().closest('.node');
    if (!(parent.length > 0)) { return null; }
    const children = parent.find(`.node[data-qing-id=${leftQingId}]`);
    if (children.length > 0) {
      return children.first();
    }
    return this.leftQingElement(parent, leftQingId);
  }

  // Uses a special array comparison method if appropriate.
  testEquality(a, b) {
    if ($.isArray(a) && $.isArray(b)) {
      return a.equalsArray(b);
    }
    return a === b;
  }

  // For inequality conditions, ignore nulls for relevance test
  // unless null is the value being checked by the condition
  // improves UX for appearing/disappearing questions.
  testInequality(refValue, expected) {
    if ($.isArray(refValue) && $.isArray(expected)) {
      if (refValue.equalsArray([]) && !expected.equalsArray([])) {
        return false;
      }
      return !refValue.equalsArray(expected);
    }
    // If you aren't checking for "not null"
    if ((refValue === null) && (expected !== null)) {
      return false;
    }
    return refValue !== expected;
  }

  // Gets the actual answer for the referred question.
  actual() {
    switch (this.rqType) {
      case 'long_text':
        // Strip wrapping <p> tag for comparison.
        return this.longTextContent().trim().replace(/(^<p>|<\/p>$)/ig, '');

      case 'integer': case 'decimal': case 'counter':
        return parseFloat(this.rqElement.find('div.control input[type=number]').val());

      case 'select_one':
        // Return all selected option_node_ids.
        return this.rqElement.find('select').map(function () {
          const id = $(this).val();
          if (id) { return id; } return null;
        }).get();

      case 'select_multiple':
        // Use prev sibling call to get to rails gen'd hidden field that holds the id
        return this.rqElement.find('div.control input:checked').map(function () {
          // Given a checkbox, get the value of the associated option_node_id hidden field made by rails
          // this field is the nearest prior sibling input with name attribute ending in [option_node_id].
          return $(this).closest('.choice').find("input[name$='[option_node_id]']").first()
            .val();
        }).get();

      case 'datetime': case 'date': case 'time':
        var selects = this.rqElement.find('div.control select');
        if (selects.map(function () { return $(this).val() === ''; }).get().indexOf(true) !== -1) {
          return null;
        }
        // Figure out if this is a datetime, date, or time field
        // this is based on the known ID naming scheme for the rails date controls
        const type = selects.attr('id').match(/([a-z]+)_value_\di$/)[1];

        // Get array of select values and pad any single digit values with a zero
        const vals = selects.map(function () { return $(this).val().lpad('0', 2); }).get();

        const str_bits = [];
        if ((type === 'datetime') || (type === 'date')) { str_bits.push(vals.slice(0, 3).join('-')); }
        if ((type === 'datetime') || (type === 'time')) { str_bits.push(vals.slice(-3).join(':')); }
        return str_bits.join(' ');


      default:
        return this.rqElement.find("div.control input[type='text']").val();
    }
  }

  // Gets the expected answer from the condition definition.
  expected() {
    switch (this.rqType) {
      case 'integer': case 'decimal': case 'counter': return parseFloat(this.condition.value);
      case 'select_one': case 'select_multiple': return this.condition.optionNodeId;
      default: return this.condition.value;
    }
  }

  longTextContent() {
    // Use wysiwyg editor if available, else use textarea value (usually just on startup).
    if (this.textarea().trumbowyg) {
      return this.textarea().trumbowyg('html');
    }
    return this.textarea().val();
  }

  textarea() {
    return this.rqElement.find('div.control textarea');
  }
};
