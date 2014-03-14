// ELMO.Condition
//
// Models a question relevance condition.
(function(ns, klass) {

  // constructor
  ns.Condition = klass = function(params) {
    // save params
    this.params = params;

    // get refs to main row and ref'd question row
    this.row = $("#qing_" + this.params.questioning_id);
    this.rq_row = $("#qing_" + this.params.ref_qing_id);

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
    self.rq_row.find("div.control").find("input, select, textarea").on('change', function(){ self.refresh(); });
    self.rq_row.find("div.control input[type='text']").on('keyup', function(){ self.refresh(); });

    // hookup form submit to clear irrelevant fields
    self.rq_row.parents("form").on('submit', function() { self.clear_on_submit_if_false(); });

    // do initial computation
    self.refresh();
  }

  // evals the condition and shows/hides accordingly
  klass.prototype.refresh = function() {
    // evaluate
    this.eval_result = this.eval();

    // show/hide it and set relevance
    this.row[this.eval_result ? "show" : "hide"]();
    this.row.find("input.relevant").val(this.eval_result ? "true" : "false");

    // simulate a change event on the control in the tr
    this.row.find("div.control").find("input, select, textarea").first().trigger("change");
  }

  // evaluates the referred question and shows/hides the question
  klass.prototype.eval = function() {

    // automatic false if ref'd question is not visible
    if (!this.rq_row.is(":visible")) return false;

    // get both sides of comparison
    var lhs = this.lhs();
    var rhs = this.rhs();

    // perform comparison
    switch (this.params.op) {
      case "eq": return lhs == rhs;
      case "lt": return lhs < rhs;
      case "gt": return lhs > rhs;
      case "leq": return lhs <= rhs;
      case "geq": return lhs >= rhs;
      case "neq": return lhs != rhs;
      case "inc": return lhs.indexOf(rhs) != -1;
      case "ninc": return lhs.indexOf(rhs) == -1;
      default: return false;
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
          return this.rq_row.find("div.control textarea").val();

        case "integer":
          return parseInt(this.rq_row.find("div.control input[type='text']").val());

        case "decimal":
          return parseFloat(this.rq_row.find("div.control input[type='text']").val());

        case "select_one":
          return parseInt(this.rq_row.find("select").val());

        case "datetime": case "date": case "time":
          return (new ELMO.TimeFormField(this.rq_row.find("div.control"))).extract_str();

        case "select_multiple":
          // use prev sibling call to get to rails gen'd hidden field that holds the id
          return this.rq_row.find("div.control input:checked").map(function(){
            // given a checkbox, get the value of the associated option_id hidden field made by rails
            // this field is the nearest prior sibling input tag with name attribute ending in [option_id]
            return parseInt($(this).prevAll("input[name$='[option_id]']").first().val());
          }).get();

        default:
          return this.rq_row.find("div.control input[type='text']").val();
      }
    }
  }

  // determines the right hand side of the comparison, which comes from the value specified in the question definition
  klass.prototype.rhs = function() {
    switch (this.rq_type) {
      case "address": case "text": case "location": case "long_text":
      case "datetime": case "date": case "time":
        return this.params.value;

      case "integer": case "decimal":
        return parseFloat(this.params.value);

      case "select_one": case "select_multiple":
        return this.params.option_id;
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
})(ELMO);