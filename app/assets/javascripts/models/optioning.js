// ELMO.Models.Optioning
//
// Client side model for Optioning
(function(ns, klass) {

  // constructor
  ns.Optioning = klass = function(attribs) { var self = this;
    // copy attribs
    for (var key in attribs) self[key] = attribs[key];
  };

  // returns a space delimited list of all locales for this optioning's option
  klass.prototype.locale_str = function() { var self = this;
    if (self.option.name_translations) {
      // get all locales with non-blank translations
      var locales = Object.keys(self.option.name_translations).filter(function(l){
        return self.option.name_translations[l] && self.option.name_translations[l] != '';
      });
      return locales.join(' ');
    } else
      return '';
  };

  // updates a translation of the given field and locale in the option model
  klass.prototype.update_translation = function(params) { var self = this;
    // ensure there is a name_translations hash
    if (!self.option.name_translations)
      self.option.name_translations = {};

    // add the value, trimming whitespace
    self.option.name_translations[params.locale] = params.value.trim();

    // also set the name attrib if this is the current locale
    if (params.locale == I18n.locale)
      self.option.name = params.value;
  };

})(ELMO.Models);