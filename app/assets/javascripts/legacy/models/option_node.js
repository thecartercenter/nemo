// ELMO.Models.OptionNode < ELMO.Models.NamedItem
//
// Client side model for OptionNode
(function (ns, klass) {
  // constructor
  ns.OptionNode = klass = function (attribs) {
    const self = this;
    ns.NamedItem.call(self, attribs);

    if (self.option) {
      // also translations from option. these are the ones we'll actually use.
      self.name = self.option.name;
      self.name_translations = self.option.name_translations;

      // copy coordinates
      self.latitude = self.option.latitude;
      self.longitude = self.option.longitude;

      // Copy value
      self.value = self.option.value;
    }

    // names are editable if the node is not a new record
    //   OR both the option AND node are new records
    self.editable = true;
  };

  // inherit from NamedItem
  klass.prototype = Object.create(ns.NamedItem.prototype);
  klass.prototype.constructor = klass;
  klass.prototype.parent = ns.NamedItem.prototype;

  // update the latitude/longitude value
  klass.prototype.update_coordinate = function (params) {
    const self = this;
    self[params.field] = params.value;
  };
}(ELMO.Models));
