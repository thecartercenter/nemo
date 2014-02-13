// ELMO.Models.Optioning
//
// Client side model for Optioning
(function(ns, klass) {

  // constructor
  ns.Optioning = klass = function(attribs) { var self = this;
    // copy attribs
    for (var key in attribs) self[key] = attribs[key];

    self.editable = true;
    self.removable = true;
  };

  klass.prototype.remove = function() { var self = this;
    self.parent.remove(self);
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