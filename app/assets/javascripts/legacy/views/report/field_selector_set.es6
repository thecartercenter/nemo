// ELMO.Report.FieldSelectorSet
(function (ns, klass) {
  // constructor
  ns.FieldSelectorSet = klass = function (cont, menus) {
    const _this = this;
    this.cont = cont;
    this.menus = menus;

    // save and delete boilerplate HTML
    this.boilerplate = this.cont.find('.selectors').children(':first')[0].outerHTML;
    this.cont.find('.selectors').children().remove();

    this.selectors = [];

    // hookup add link
    this.cont.find('a.add').click(() => { _this.add_selectors(1); return false; });
  };

  // updates the set of selectors to match the given report model
  klass.prototype.update = function (report) {
    const self = this;

    // save ref to report
    this.report = report;

    // remove all existing selectors
    $(self.selectors).each(function () { this.remove(); });
    self.selectors = [];

    // add new ones and update them with current values
    if (this.report.attribs.calculations_attributes) {
      self.add_selectors(this.report.attribs.calculations_attributes.length);
      $(this.report.attribs.calculations_attributes).each(function (idx) { self.selectors[idx].update(self.report, this); });
    }
  };

  klass.prototype.get = function () {
    const self = this;
    const ret = [];

    // build array of calculation objects
    $(self.selectors).each(function () {
      ret.push(this.get());
    });
    return ret;
  };

  // adds the given number of selectors to the set
  klass.prototype.add_selectors = function (how_many) {
    const self = this;

    for (let i = 0; i < how_many; i++) {
      // create the element
      var el = $(this.boilerplate).appendTo(this.cont.find('.selectors'));

      // create the selector obj and add to the array
      const selector = new ns.FieldSelector(el, this.menus);

      // update to fill the options
      selector.update(this.report, null);

      // add to array
      this.selectors.push(selector);

      // hookup the remove link
      (function (selector) {
        el.find('a.remove').click(() => { self.remove_selector(selector); return false; });
      }(selector));
    }
  };

  klass.prototype.remove_selector = function (selector) {
    // get the index
    const idx = this.selectors.indexOf(selector);

    // remove the element
    this.selectors[idx].remove();

    // remove from the array if the selector does not exist in db
    if (!this.selectors[idx].exists_in_db()) this.selectors.splice(idx, 1);
  };

  // removes any visible field selectors with nothing selected
  klass.prototype.remove_unselected = function () {
    const self = this;
    for (let i = self.selectors.length - 1; i >= 0; i--) if (self.selectors[i].visible && self.selectors[i].unselected()) this.remove_selector(self.selectors[i]);
  };
}(ELMO.Report));
