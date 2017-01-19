// ELMO.Views.ConditionChecker
//
// Models a question relevance condition. Knows how to grab values
// from the response form and show/hide the Condition's question.
(function(ns, klass) {

  // constructor
  ns.ConditionChecker = klass = function(condition, inst_num) {
    this.condition = condition;

    // get refs to main row and ref'd question row
    this.row = this.form_row(this.condition.questioning_id, inst_num);
    this.rq_row = this.form_row(this.condition.ref_qing_id, inst_num);

    // check if readonly
    this.read_only = this.row.is('.read_only');

    // get question type
    this.rq_type = this.rq_row.data('qtype-name');

    // default to relevant
    this.eval_result = true;
  }

  // hooks up controls and performs an immediate refresh
  klass.prototype.init = function() { var self = this;
    // hookup controls
    this.rq_row.find("div.control").find("input, select, textarea").on('change', function(){ self.refresh(); });
    this.rq_row.find("div.control input[type='text']").on('keyup', function(){ self.refresh(); });

    if (this.rq_type == 'long_text' && !this.read_only)
      this.get_ckeditor().on('change', function() { self.refresh(); });

    // hookup form submit to clear irrelevant fields
    this.rq_row.parents("form").on('submit', function() { self.clear_on_submit_if_false(); });

    // do initial computation
    this.refresh();
  }

  // evals the condition and shows/hides accordingly
  klass.prototype.refresh = function() {
    var new_result = this.eval();

    // If the eval_result changed
    if (new_result != this.eval_result) {
      this.eval_result = new_result;

      // show/hide it and set relevance
      this.row[this.eval_result ? "show" : "hide"]();
      this.row.find("input.relevant").val(this.eval_result ? "true" : "false");

      // Simulate a change event on the control so that later conditions will be re-evaluated.
      this.row.find("div.control").find("input, select, textarea").first().trigger("change");
    }
  }

  // evaluates the referred question and shows/hides the question
  klass.prototype.eval = function() {

    // automatic false if ref'd question is not visible
    if (!this.rq_row.is(":visible")) return false;

    // get both sides of comparison
    var lhs = this.lhs();
    var rhs = this.rhs();

    // perform comparison
    switch (this.condition.op) {
      case "eq": return this.test_equality(lhs, rhs);
      case "lt": return lhs < rhs;
      case "gt": return lhs > rhs;
      case "leq": return lhs <= rhs;
      case "geq": return lhs >= rhs;
      case "neq": return this.test_inequality(lhs, rhs);
      case "inc": return lhs.indexOf(rhs) != -1;
      case "ninc": return lhs.indexOf(rhs) == -1;
      default: return false;
    }
  }

  // Uses a special array comparison method if appropriate.
  klass.prototype.test_equality = function(a,b) {
    return $.isArray(a) && $.isArray(b) ? a.equalsArray(b) : a == b;
  };

  // for inequality conditions, ignore nulls for relevance test
  // unless null is the value being checked by the condition
  // improves UX for appearing/disappearing questions
  klass.prototype.test_inequality = function(ref_value, expected) {
    if($.isArray(ref_value) && $.isArray(expected)) {
      if(ref_value.equalsArray([]) && !expected.equalsArray([])) {
        return false
      } else {
        return !ref_value.equalsArray(expected)
      }
    } else {
      // if you aren't checking for "not null"
      if(ref_value == null && expected != null) {
        return false
      }
      else {
        return ref_value != expected
      }
    }
  }

  // determines the left hand side of the comparison, which comes from the referred question
  klass.prototype.lhs = function() {

    // if readonly, use the data-val attrib
    if (this.read_only) {
      // get inner div
      var wrapper = this.rq_row.find('div.control div.ro-val');

      // return val, or just div innerHTML if not defined
      return typeof(wrapper.data('val')) == 'undefined' ? wrapper.text() : wrapper.data('val');

    } else {

      switch (this.rq_type) {
        case "long_text":
          // Use ckeditor if available, else use textarea value (usually just on startup).
          var ckeditor = this.get_ckeditor();
          var content = ckeditor ? ckeditor.getData() : this.rq_row.find("div.control textarea").val();

          // Strip wrapping <p> tag for comparison.
          return content.replace(/(^<p>|<\/p>$)/ig, "")

        case "integer":
        case "decimal":
          return parseFloat(this.rq_row.find("div.control input[type='text']").val());

        case "select_one":
          var last_option_node_id;

          // Get last non-null/blank selected option_node_id
          this.rq_row.find("select").each(function() {
            var this_id = $(this).val();
            if (this_id) last_option_node_id = parseInt(this_id);
          });
          return last_option_node_id;

        case "select_multiple":
          // use prev sibling call to get to rails gen'd hidden field that holds the id
          return this.rq_row.find("div.control input:checked").map(function() {
            // given a checkbox, get the value of the associated option_node_id hidden field made by rails
            // this field is the nearest prior sibling input with name attribute ending in [option_node_id]
            return parseInt($(this).prevAll("input[name$='[option_node_id]']").first().val());
          }).get();

        case "datetime": case "date": case "time":
          return (new ELMO.TimeFormField(this.rq_row.find("div.control"))).extract_str();

        default:
          return this.rq_row.find("div.control input[type='text']").val();
      }
    }
  }

  // determines the right hand side of the comparison, which comes from the value specified in the question definition
  klass.prototype.rhs = function() {
    switch (this.rq_type) {
      case "address": case "text": case "location":
      case "datetime": case "date": case "time":
        return this.condition.value;

      case "long_text":
        return this.condition.value;

      case "integer": case "decimal":
        return parseFloat(this.condition.value);

      case "select_one": case "select_multiple":
        return this.condition.option_node_id;
    }
  }

  // when the form is submitted, clears the answer if the eval_result is false
  klass.prototype.clear_on_submit_if_false = function() {
    if (!this.eval_result) {
      // clear text boxes and selects
      this.row.find("input[type='text'], textarea, select").val("");

      // clear checkboxes and radio buttons
      this.row.find("input[type='checkbox']:checked, input[type='radio']:checked").each(function() {
        $(this).removeAttr('checked'); });
    }
  }

  klass.prototype.get_ckeditor = function() {
    return CKEDITOR.instances[this.rq_row.find("div.control textarea").attr('id')];
  }

  // Gets a jQuery object for the form row for the given questioning id and inst_num.
  klass.prototype.form_row = function(qing_id, inst_num) {
    return $('.form_field[data-qing-id=' + qing_id + '][data-inst-num=' + inst_num + ']');
  }

})(ELMO.Views);
