// ELMO.Control.Multiselect
(function (ns, klass) {
  // constructor
  ns.Multiselect = klass = function (params) {
    const _this = this;
    this.params = params;

    this.dom_id = parseInt(Math.random() * 1000000);
    this.fld = params.el;
    this.rebuild_options();

    // initialize callback to empty function
    this.change_callback = function () {};

    // hookup events
    this.fld.find('.links a.select_all').click(() => { _this.set_all(true); _this.change_callback(); });
    this.fld.find('.links a.deselect_all').click(() => { _this.set_all(false); _this.change_callback(); });
  };

  // inherit from Control
  klass.prototype = new ns.Control();
  klass.prototype.constructor = klass;
  klass.prototype.parent = ns.Control.prototype;

  klass.prototype.build_field = function () {

  };

  klass.prototype.rebuild_options = function () {
    const _this = this;

    // empty old rows
    this.fld.find('.choices').empty();
    this.rows = [];

    // add new rows
    for (let i = 0; i < this.params.objs.length; i++) {
      const id = this.params.objs[i][this.params.id_key];
      const txt = this.params.objs[i][this.params.txt_key];
      const row = $('<div>');
      const dom_id = `${this.dom_id}_${i}`;

      $('<input>').attr('type', 'checkbox').attr('value', id).attr('id', dom_id)
        .click(() => { _this.change_callback(); })
        .appendTo(row);
      $('<label>').attr('for', dom_id).html(`&nbsp;${txt}`).appendTo(row);

      this.rows.push(row);

      this.fld.find('.choices').append(row);
    }
  };

  klass.prototype.update = function (selected_ids) {
    // convert selected_ids to string
    for (var i = 0; i < selected_ids.length; i++) selected_ids[i] = selected_ids[i].toString();

    for (var i = 0; i < this.rows.length; i++) {
      const checked = selected_ids.indexOf(this.rows[i].find('input').attr('value')) != -1;
      this.rows[i].find('input').prop('checked', checked);
    }

    this.toggle_select_all();
  };

  klass.prototype.change = function (func) {
    this.change_callback = func;
  };


  klass.prototype.update_objs = function (objs) {
    this.params.objs = objs;
    const seld = this.get();
    this.rebuild_options();
    this.update(seld);
  };

  klass.prototype.get = function () {
    const seld = [];
    for (let i = 0; i < this.rows.length; i++) if (this.rows[i].find('input').prop('checked')) seld.push(this.rows[i].find('input').attr('value'));
    return seld;
  };

  klass.prototype.enable = function (which) {
    if (which) this.fld.find("input[type='checkbox']").removeAttr('disabled');
    else this.fld.find("input[type='checkbox']").attr('disabled', 'disabled');
    this.fld.css('color', which ? '' : '#888');
  };

  klass.prototype.set_all = function (which) {
    for (let i = 0; i < this.rows.length; i++) this.rows[i].find('input').prop('checked', which);
  };

  // checks if select all links should be toggled, and toggles them
  klass.prototype.toggle_select_all = function () {
    // check if the links are enabled at all
    if (this.fld.find('.links a.select_all')) {
      let all_checked = true;
      let any_checked = false;
      for (let i = 0; i < this.rows.length; i++) {
        if (this.rows[i].find('input').prop('checked')) any_checked = true;
        else all_checked = false;

        if (!all_checked && any_checked) break;
      }

      // show/hide select all links
      this.fld.find('.links a.select_all')[!all_checked ? 'show' : 'hide']();
      this.fld.find('.links a.deselect_all')[any_checked ? 'show' : 'hide']();
    }
  };

  klass.prototype.all_selected = function () {
    for (let i = 0; i < this.rows.length; i++) if (!this.rows[i].find('input').prop('checked')) return false;
    return true;
  };
}(ELMO.Control));
