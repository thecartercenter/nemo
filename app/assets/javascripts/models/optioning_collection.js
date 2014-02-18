// ELMO.Models.OptioningCollection < ELMO.Models.NamedItemCollection
//
// Subclasses NamedItemCollection so that we can add some special functionality.
(function(ns, klass) {

  // constructor
  ns.OptioningCollection = klass = function() { var self = this;
  };

  // inherit from NamedItemCollection
  // we pass the class of the child model to the superclasses constructor
  klass.prototype = new ns.NamedItemCollection(ELMO.Models.Optioning);
  klass.prototype.constructor = klass;
  klass.prototype.parent = ns.NamedItemCollection.prototype;

  // adds an optioning to the set based on a hash of option attribs
  // aborts and returns false if there is a duplicate entry
  // returns new Optioning otherwise
  klass.prototype.add_from_option_attribs = function(attribs) { var self = this;
    // don't add if it's a duplicate
    if (self.has_with_name(attribs.name)) return false;

    // create the Optioning and Option objects
    var optioning = new ELMO.Models.Optioning({id: null, 'removable?': true, option: attribs});

    self.add(optioning);

    return optioning;
  };

})(ELMO.Models);