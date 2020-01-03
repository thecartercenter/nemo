// ELMO.Report.OptionSetMenu < ELMO.Report.ObjectMenu
(function (ns, klass) {
  // constructor
  klass = ns.OptionSetMenu = function (option_sets) {
    this.objs = option_sets;
  };

  // inherit
  klass.prototype = new ns.ObjectMenu();
  klass.prototype.constructor = klass;
  klass.prototype.parent = ns.ObjectMenu.prototype;
}(ELMO.Report));
