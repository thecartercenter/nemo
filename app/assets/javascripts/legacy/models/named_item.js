// ELMO.Models.NamedItem
//
// Client side model for OptionNodes and OptionLevels, both of which have name_translations
(function (ns, klass) {
  // constructor
  ns.NamedItem = klass = function (attribs) {
    const self = this;

    attribs = attribs || {};

    // copy attribs
    for (const key in attribs) self[key] = attribs[key];

    // default name and name_translations if empty
    if (!self.name_translations) {
      self.name_translations = {};
      self.name = '';
    }

    // set defaults for boolean flags
    self.removable = true;
    self.editable = true;
  };

  // get the rank from the position of the associated <li>
  klass.prototype.rank = function () {
    const self = this;
    return self.div.closest('li').index() + 1;
  };

  // returns a space delimited list of all locales for this item
  klass.prototype.locale_str = function () {
    const self = this;
    if (self.name_translations) {
      // get all locales with non-blank translations
      const locales = self.locales().filter((l) => {
        return self.name_translations[l] && self.name_translations[l] != '';
      });
      return locales.join(' ');
    } return '';
  };

  // updates a translation of the given field and locale
  klass.prototype.update_translation = function (params) {
    const self = this;
    // ensure there is a name_translations hash
    if (!self.name_translations) self.name_translations = {};

    // add the value, trimming whitespace
    self.name_translations[params.locale] = params.value.trim();

    // update name (current locale or default locale or first non-blank value)
    const names = [self.name_translations[I18n.locale], self.name_translations[I18n.default_locale]];
    for (const locale in self.name_translations) names.push(self.name_translations[locale]);
    self.name = names.filter((n) => { return n && n != ''; })[0] || '';
  };

  klass.prototype.translation = function (locale) {
    const self = this;
    if (locale) return self.name_translations[locale];
    return self.name;
  };

  klass.prototype.locales = function () {
    const self = this;
    return Object.keys(self.name_translations);
  };
}(ELMO.Models));
