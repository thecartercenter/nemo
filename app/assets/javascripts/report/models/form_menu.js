// ELMO.Report.FormMenu < ELMO.Report.ObjectMenu
(function(ns, klass) {

  // constructor
  klass = ns.FormMenu = function(objs) {
    this.objs = objs;
  };
  
  // inherit
  klass.prototype = new ns.ObjectMenu();
  klass.prototype.constructor = klass;
  klass.prototype.parent = ns.ObjectMenu.prototype;

  // gets the names (not fullnames) of the forms with the given ids
  klass.prototype.get_names = function(form_ids) {
    var names = []
    $(this.objs).each(function() { if (form_ids.indexOf(this.id) != -1) names.push(this.name); })
    return names;
  }
  
  // gets the ids of the forms with the given names
  klass.prototype.get_ids_from_names = function(names) {
    var ids = []
    $(this.objs).each(function() { if (names.indexOf(this.name) != -1) ids.push(this.id); })
    return ids;
  }

}(ELMO.Report));