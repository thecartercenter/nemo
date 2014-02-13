// ELMO.Models.Optioning
//
// Client side model for Optioning
(function(ns, klass) {

  // constructor
  ns.Optioning = klass = function(attribs) { var self = this;
    // copy attribs
    for (var key in attribs) self[key] = attribs[key];

    // build an Option instance out of the given attribs
    self.option = new ELMO.Models.NamedItem(self.option);

    // optioning (option) names are editable if the optioning is not a new record
    //   OR both the option AND optioning are new records
    self.editable = self.id || !self.option.id;

    // alias removable with no question mark
    // note this is a property of optioning
    self.removable = self['removable?'];

    // alias in_use with no question mark
    // note this is a property of option
    self.in_use = self.option['in_use?'];
  };

  klass.prototype.remove = function() { var self = this;
    self.parent.remove(self);
  };

  // get the rank from the position of the associated <li>
  klass.prototype.rank = function() { var self = this;
    return self.div.closest('li').index() + 1;
  };

  // DELEGATE THESE METHODS TO THE UNDERLYING OPTION MODEL

  klass.prototype.locale_str = function() { var self = this;
    return self.option.locale_str();
  };

  // updates a translation of the given field and locale
  klass.prototype.update_translation = function(params) { var self = this;
    self.option.update_translation(params);
  };

  klass.prototype.translation = function(locale) { var self = this;
    return self.option.translation(locale);
  };

  klass.prototype.locales = function() { var self = this;
    return self.option.locales();
  };

})(ELMO.Models);