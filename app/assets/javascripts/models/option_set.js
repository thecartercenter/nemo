// ELMO.Models.OptionSet
//
// Client side option set model
(function(ns, klass) {

  // constructor
  ns.OptionSet = klass = function(attribs) { var self = this;
    // copy attribs
    for (var key in attribs) self[key] = attribs[key];
    
    // create an array for removed optionings
    self.removed_optionings = [];
    
    // maintain a hash by option name for fast duplicate checking
    self.options_by_name = {};

    // create model objects for each optioning hash
    var optioning_attribs = self.optionings;
    self.optionings = [];
    optioning_attribs.forEach(function(optioning){ self.add_optioning(new ELMO.Models.Optioning(optioning)); });
  };
  
  // adds a newly created option to the set (also creates optioning); returns the new optioning
  klass.prototype.add_option = function(option_params) { var self = this;
    var oing = new ELMO.Models.Optioning({id: null, removable: true, option: option_params});
    self.add_optioning(oing);
    return oing;
  };
  
  // adds an optioning to the set
  klass.prototype.add_optioning = function(optioning) { var self = this;
    self.optionings.push(optioning);
    
    // add to lookup hash
    self.options_by_name[optioning.option.name] = optioning.option;
  };

  // removes a given optioning from the set
  klass.prototype.remove_optioning = function(optioning) { var self = this;
    var removed = self.optionings.splice(self.optionings.indexOf(optioning), 1);

    // if the removed optioning has an id, save it as it will need to be destroyed
    if (removed[0].id)
      self.removed_optionings.push(removed[0]);
    
    // remove from hash
    delete self.options_by_name[optioning.option.name];
  };
  
  // quickly checks if this set currently has an option with the given name
  klass.prototype.has_option_with_name = function(name) { var self = this;
    return !!self.options_by_name[name];
  };
  
})(ELMO.Models);