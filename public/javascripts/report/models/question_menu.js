// ELMO.Report.QuestionMenu < ELMO.Report.ObjectMenu
(function(ns, klass) {

  // constructor
  klass = ns.QuestionMenu = function(questions) {
    this.objs = questions;
  };
  
  // inherit
  klass.prototype = new ns.ObjectMenu();
  klass.prototype.constructor = klass;
  klass.prototype.parent = ns.ObjectMenu.prototype;
  
  
  klass.prototype.for_forms_and_calc_type = function(form_ids, calc_type) {
    var o = [];
    
    // sort the form_id array for fast comparison
    form_ids = form_ids.sort();
    
    for (var i = 0; i < this.objs.length; i++) {
      var type = this.objs[i].type;
      // ZeroNonzeroCalculations must have integer or decimal questions
      if (calc_type == "Report::ZeroNonzeroCalculation" && !(type == "integer" || type == "decimal"))
        continue;
      
      // IdentityCalculation must have select type
      if (calc_type == "Report::IdentityCalculation" && !(type == "select_one" || type == "select_multiple"))
        continue;
        
      // question must appear on one of the given forms
      if (Sassafras.Utils.intersect(this.objs[i].form_ids, form_ids).length == 0)
        continue;
      
      // if we get this far, we can push  
      o.push(this.objs[i]);
    }
    return o;
  }
  
}(ELMO.Report));