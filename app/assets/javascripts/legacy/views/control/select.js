// ELMO.Control.Select
(function (ns, klass) {
  // constructor
  ns.Select = klass = function (params) {
    this.params = params;
    this.fld = params.el;
    this.rebuild_options();
  };

  // inherit from Control
  klass.prototype = new ns.Control();
  klass.prototype.constructor = klass;
  klass.prototype.parent = ns.Control.prototype;

  klass.prototype.update = function (selected_id) {
    for (let i = 0; i < this.opts.length; i++) this.opts[i].prop('selected', selected_id == null ? false : (selected_id.toString() == this.opts[i].attr('value')));
  };

  klass.prototype.rebuild_options = function () {
    const _this = this;

    // save the prompt option if necessary
    if (this.params.prompt) var prompt = this.fld.find('option:first')[0].outerHTML;

    // empty old rows
    this.fld.empty();
    this.opts = [];

    // re-add the prompt if appropriate
    if (this.params.prompt) this.fld.append(prompt);

    // if this is a grouped select, add the option sets one by one
    if (this.params.grouped) {
      $(this.params.objs).each(function () {
        // create the optgroup tag
        const grp = $('<optgroup>').attr('label', this.label);
        _this.build_option_group(grp, this);
        _this.fld.append(grp);
      });
    } else this.build_option_group(this.fld, this.params);
  };

  klass.prototype.build_option_group = function (parent, spec) {
    for (let i = 0; i < spec.objs.length; i++) {
      const id = typeof (spec.id_key) === 'function' ? spec.id_key(spec.objs[i]) : spec.objs[i][spec.id_key];
      const txt = typeof (spec.txt_key) === 'function' ? spec.txt_key(spec.objs[i]) : spec.objs[i][spec.txt_key];
      const opt = $('<option>').text(txt).attr('value', id);
      this.opts.push(opt);
      parent.append(opt);
    }
  };

  klass.prototype.update_objs = function (objs) {
    // save new object set and old selection
    this.params.objs = objs;
    const seld = this.get();

    // make the new option tags
    this.rebuild_options();

    // select the proper option again
    this.update(seld);
  };

  klass.prototype.get = function () {
    for (let i = 0; i < this.opts.length; i++) if (this.opts[i].prop('selected')) return this.opts[i].attr('value');
    return null;
  };

  klass.prototype.change = function (func) {
    this.fld.bind('change', func);
  };

  klass.prototype.enable = function (which) {
    if (which) this.fld.removeAttr('disabled');
    else this.fld.attr('disabled', 'disabled');
    this.fld.css('color', which ? '' : '#888');
  };

  klass.prototype.closest = function (sel) {
    return this.fld.closest(sel);
  };

  klass.prototype.clear = function () {
    this.update(null);
  };
}(ELMO.Control));
