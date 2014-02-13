// ELMO.Models.Option < ELMO.Models.NamedItem
//
// Client side model for Option
(function(ns, klass) {

  // constructor
  ns.Option = klass = function(attribs) { var self = this;
    // copy attribs
    for (var key in attribs) self[key] = attribs[key];
  };

  // inherit from NamedItem
  klass.prototype = new ns.NamedItem();
  klass.prototype.constructor = klass;
  klass.prototype.parent = ns.NamedItem.prototype;

})(ELMO.Models);