// ELMO.OptionSet
//
// Client side option set model
(function(ns, klass) {
  
  // constructor
  ns.OptionSet = klass = function(optionings) { var self = this;
    // create model objects for each optioning hash
    self.optionings = optionings.map(function(optioning){ return new ELMO.Optioning(optioning); });
    console.log(self.optionings)
  };
  
  // removes a given optioning from the set
  klass.prototype.remove_optioning = function(optioning) { var self = this;
    self.optionings.splice(self.optionings.indexOf(optioning), 1);
  };
  
  // adds an optioning to the set
  klass.prototype.add_optioning = function(optioning) { var self = this;
    self.optionings.push(optioning);
  };

})(ELMO);