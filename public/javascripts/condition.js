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

    // get question type
    this.rq_type = this.rq_row.attr("class").substring(17);
    
    // default to relevant
    this.eval_result = true;
  }
  
  // hooks up controls and performs an immediate refresh
  klass.prototype.init = function() {
    // hookup controls
    (function(_this){ _this.rq_row.find("div.form_field_control").find("input, select, textarea").change(
      function(){ _this.refresh(); }) })(this);
    (function(_this){ _this.rq_row.find("div.form_field_control input[type='text']").keyup(
      function(){ _this.refresh(); }) })(this);
      
    // hookup form submit to clear irrelevant fields
    (function(_this){ _this.rq_row.parents("form").submit(
      function(){ _this.clear_on_submit_if_false(); }) })(this);

    this.refresh();
  }
  
  // evals the condition and shows/hides accordingly
  klass.prototype.refresh = function() {
    // evaluate
    this.eval_result = this.eval();
    
    // show/hide it and set relevance
    this.row[this.eval_result ? "show" : "hide"]();
    this.row.find("input.relevant").val(this.eval_result ? "true" : "false");
    
    // simulate a change event on the control in the tr
    this.row.find("div.form_field_control").find("input, select, textarea").first().trigger("change");
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
      case "is equal to": return lhs == rhs;
      case "is less than": return lhs < rhs;
      case "is greater than": return lhs > rhs;
      case "is less than or equal to": return lhs <= rhs;
      case "is greater than or equal to": return lhs >= rhs;
      case "is not equal to": return lhs != rhs;
      case "includes": return lhs.indexOf(rhs) != -1;
      case "does not include": return lhs.indexOf(rhs) == -1;
      default: return false;
    }
  }
  
  // determines the left hand side of the comparison, which comes from the referred question
  klass.prototype.lhs = function() {
    switch (this.rq_type) {
      case "address": case "text": case "location":
        return this.rq_row.find("div.form_field_control input[type='text']").val();

      case "long_text":
        return this.rq_row.find("div.form_field_control textarea").val();
      
      case "integer": 
        return parseInt(this.rq_row.find("div.form_field_control input[type='text']").val());
        
      case "decimal":
        return parseFloat(this.rq_row.find("div.form_field_control input[type='text']").val());
      
      case "select_one":
        return parseInt(this.rq_row.find("select").val());
      
      case "datetime": case "date": case "time":
        return (new ELMO.TimeFormField(this.rq_row.find("div.form_field_control"))).extract_str();
      
      case "select_multiple":
        // use prev sibling call to get to rails gen'd hidden field that holds the id
        return this.rq_row.find("div.form_field_control input:checked").map(function(){ 
          // given a checkbox, get the value of the associated option_id hidden field made by rails
          // this field is the nearest prior sibling input tag with name attribute ending in [option_id]
          return parseInt($(this).prevAll("input[name$='[option_id]']").first().val()); 
        }).get();
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