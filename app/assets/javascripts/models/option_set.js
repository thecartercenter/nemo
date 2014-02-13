// ELMO.Models.OptionSet
//
// Client side option set model
(function(ns, klass) {

  // constructor
  ns.OptionSet = klass = function(attribs) { var self = this;
    // copy attribs
    for (var key in attribs) self[key] = attribs[key];

    var optionings_attribs = self.optionings;
    self.optionings = new ELMO.Models.OptioningCollection();
    self.optionings.build_items(optionings_attribs);
  };

})(ELMO.Models);