// ELMO.Models.OptionSet
//
// Client side option set model
(function(ns, klass) {

  // constructor
  ns.OptionSet = klass = function(attribs) { var self = this;
    // copy attribs
    for (var key in attribs) self[key] = attribs[key];

    self.optionings = (new ELMO.Models.OptioningCollection()).build_items(self.optionings);
    self.option_levels = (new ELMO.Models.NamedItemCollection()).build_items(self.option_levels);
  };

})(ELMO.Models);