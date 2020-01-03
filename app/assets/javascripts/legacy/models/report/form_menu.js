// ELMO.Report.FormMenu < ELMO.Report.ObjectMenu
(function (ns, klass) {
  // constructor
  klass = ns.FormMenu = function (objs) {
    this.objs = objs;
  };

  // inherit
  klass.prototype = new ns.ObjectMenu();
  klass.prototype.constructor = klass;
  klass.prototype.parent = ns.ObjectMenu.prototype;

  // gets the names (not fullnames) of the forms with the given ids
  // Assumes `form_ids` is an array of strings.
  klass.prototype.get_names = function (form_ids) {
    const names = [];
    $(this.objs).each(function () { if (form_ids.indexOf(this.id.toString()) != -1) names.push(this.name); });
    return names;
  };

  // Gets the ids of the forms with the given names.
  // Returns an arrat of strings.
  klass.prototype.get_ids_from_names = function (names) {
    const ids = [];
    $(this.objs).each(function () { if (names.indexOf(this.name) != -1) ids.push(this.id.toString()); });
    return ids;
  };
}(ELMO.Report));
