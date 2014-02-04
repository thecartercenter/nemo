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

    // update option name (current locale or default locale or first non-blank value)
    var names = [self.option.name_translations[I18n.locale], self.option.name_translations[I18n.default_locale]];
    for (var locale in self.option.name_translations)
      names.push(self.option.name_translations[locale]);
    self.option.name = names.filter(function(n){ return n && n != ''; })[0] || '';
  };

})(ELMO.Models);