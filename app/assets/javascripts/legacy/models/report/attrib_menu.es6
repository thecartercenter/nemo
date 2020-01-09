// ELMO.Report.AttribMenu < ELMO.Report.ObjectMenu
(function (ns, klass) {
  // constructor
  klass = ns.AttribMenu = function (objs) {
    this.objs = objs;
  };

  // inherit
  klass.prototype = new ns.ObjectMenu();
  klass.prototype.constructor = klass;
  klass.prototype.parent = ns.ObjectMenu.prototype;
}(ELMO.Report));
