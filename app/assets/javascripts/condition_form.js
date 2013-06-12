// ELMO.ConditionForm
//
// Models the Condition section of the Questioning form.
(function(ns, klass) {

  // constructor
  // expects a hash representing the condition object, including the available operators, refable question types, and refable question options.
  ns.ConditionForm = klass = function(condition) { var self = this;
    // save params
    self.condition = condition;
    
    // hookup change event on ref qing select box
    $("#questioning_condition_ref_qing_id").on("change", function(){ self.update_controls($(this).val()); });

  }
  
  // updates the controls and choices in the rest of the form when the ref qing is changed
  klass.prototype.update_controls = function(ref_qing_id) { var self = this;
    // the ref qing is null, clear out all the boxes
    if (!ref_qing_id) {
      $("#questioning_condition_op").emptyExceptFirst();
      $("#questioning_condition_option_id").emptyExceptFirst().hide();
      $("#questioning_condition_value").val("").show();
    
    } else {
    
      // get the ref qing type
      var ref_qtype = self.condition.refable_qing_types[ref_qing_id];
    
      // get the appropriate operators for the qtype (those for which ref_qtype appears in the types array)
      var ops = self.condition.operators.filter(function(o){ return o.types.indexOf(ref_qtype) != -1; });
    
      // get a [name, value] style array based on the ops
      var op_dropdowns = ops.map(function(o){ return [I18n.t("conditions.operators." + o.name), o.name]; });
    
      // load the op dropdown with the appropriate operators and their translations
      $("#questioning_condition_op").emptyExceptFirst().addOptions(op_dropdowns);
    
      // if the ref_qing has options, populate and show the option dropdown
      var opts;
      if (opts = self.condition.refable_qing_option_lists[ref_qing_id]) {
        // add the option list to the option_id box and show it
        $("#questioning_condition_option_id").emptyExceptFirst().addOptions(opts).show();
      
        // hide the text box
        $("#questioning_condition_value").hide();
      
      // else clear and show the textbox
      } else {
        // show the text box
        $("#questioning_condition_value").show();
      
        // hide the options box
        $("#questioning_condition_option_id").empty().hide();
      }
    }
  }
  
})(ELMO);