// ELMO.Report.CalcTypeMenu < ELMO.Report.ObjectMenu
(function(ns, klass) {

  // constructor
  klass = ns.CalcTypeMenu = function(calc_types) {
    this.objs = calc_types;
  };
  
  // inherit
  klass.prototype = new ns.ObjectMenu();
  klass.prototype.constructor = klass;
  klass.prototype.parent = ns.ObjectMenu.prototype;
  
}(ELMO.Report));