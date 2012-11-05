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
  
  
  klass.prototype.for_calc_type = function(calc_type) {
    var o = [];
    for (var i = 0; i < this.objs.length; i++) {
      // ZeroNonzeroCalculations must have integer or decimal questions
      var type = this.objs[i].type;
      if ((calc_type == "Report::ZeroNonzeroCalculation" && (type == "integer" || type == "decimal")) ||
          (calc_type == "Report::IdentityCalculation" && (type == "select_one" || type == "select_multiple")))
            o.push(this.objs[i]);
    }
    return o;
  }
}(ELMO.Report));