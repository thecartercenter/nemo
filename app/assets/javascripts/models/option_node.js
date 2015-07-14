// ELMO.Models.OptionNode < ELMO.Models.NamedItem
//
// Client side model for OptionNode
(function(ns, klass) {

  // constructor
  ns.OptionNode = klass = function(attribs) { var self = this;
    // copy attribs
    for (var key in attribs) self[key] = attribs[key];

    if (self.option) {
      // also translations from option. these are the ones we'll actually use.
      self.name = self.option.name;
      self.name_translations = self.option.name_translations;

      // copy coordinates
      self.latitude = self.option.latitude;
      self.longitude = self.option.longitude;
    }

    // names are editable if the node is not a new record
    //   OR both the option AND node are new records
    self.editable = true;

    // alias removable with no question mark
    // note this is a property of option node
    self.removable = self['removable?'];

    // alias in_use with no question mark
    // note this is a property of option
    self.in_use = self.option['in_use?'];
  };

  // inherit from NamedItem
  klass.prototype = new ns.NamedItem();
  klass.prototype.constructor = klass;
  klass.prototype.parent = ns.NamedItem.prototype;

  // update the latitude/longitude value
  klass.prototype.update_coordinate = function (params) { var self = this;
    self[params.field] = params.value;
  };

})(ELMO.Models);
