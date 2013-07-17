// ELMO.OptionSet
//
// Client side option set model
(function(ns, klass) {
  
  // constructor
  ns.OptionSet = klass = function(optionings) { var self = this;
    // create model objects for each optioning hash
    self.optionings = optionings.map(function(optioning){ return new ELMO.Optioning(optioning); });
    
    // create an array for removed optionings
    self.removed_optionings = [];
  };
  
  // removes a given optioning from the set
  klass.prototype.remove_optioning = function(optioning) { var self = this;
    var removed = self.optionings.splice(self.optionings.indexOf(optioning), 1);

    // if the removed optioning has an id, save it as it will need to be destroyed
    if (removed[0].id)
      self.removed_optionings.push(removed[0]);
  };
  
  // adds an optioning to the set
  klass.prototype.add_optioning = function(optioning) { var self = this;
    self.optionings.push(optioning);
  };

})(ELMO);