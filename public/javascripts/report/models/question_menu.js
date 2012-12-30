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
  
  
  klass.prototype.filter = function(options) {
    var o = [];
    
    // default to identity calculation
    if (!options.calc_type) options.calc_type = "Report::IdentityCalculation";
    
    // sort the form_id array for fast comparison
    if (options.form_ids && options.form_ids != "ALL")
      options.form_ids = options.form_ids.sort();
    
    for (var i = 0; i < this.objs.length; i++) {
      var type = this.objs[i].type;
      // ZeroNonzeroCalculations must have integer or decimal questions
      if (options.calc_type == "Report::ZeroNonzeroCalculation" && !(type == "integer" || type == "decimal"))
        continue;
      
      // IdentityCalculation can have any type given in question_types
      if (options.calc_type == "Report::IdentityCalculation" && options.question_types && options.question_types.indexOf(this.objs[i].type) == -1)
        continue;
        
      // question must appear on one of the given forms
      if (options.form_ids != "ALL" && Sassafras.Utils.intersect(this.objs[i].form_ids, options.form_ids).length == 0)
        continue;
      
      // if we get this far, we can push  
      o.push(this.objs[i]);
    }
    return o;
  }
  
}(ELMO.Report));