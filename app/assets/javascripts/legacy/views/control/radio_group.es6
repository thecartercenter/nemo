// ELMO.Control.RadioGroup
(function (ns, klass) {
  // constructor
  ns.RadioGroup = klass = function (params) {
    this.params = params;
    this.inputs = params.inputs;
    this.values = [];

    for (let i = 0; i < this.inputs.size(); i++) this.values.push(this.inputs[i].value);
  };

  klass.prototype.update = function (selected_value) {
    const selected_idx = this.values.indexOf(selected_value);

    // if value not found, uncheck all
    if (selected_idx == -1) for (let i = 0; i < this.inputs.length; i++) $(this.inputs[i]).prop('checked', false);
    else $(this.inputs[selected_idx]).prop('checked', true);
  };

  klass.prototype.enable = function (which) {
    for (let i = 0; i < this.inputs.length; i++) $(this.inputs[i]).attr('disabled', !which);
  };

  klass.prototype.get = function () {
    return this.inputs.filter(':checked').val();
  };

  klass.prototype.change = function (func) {
    for (let i = 0; i < this.inputs.length; i++) $(this.inputs[i]).on('change', func);
  };

  klass.prototype.closest = function (sel) {
    return $(this.inputs[0]).closest(sel);
  };

  klass.prototype.clear = function () {
    this.update(null);
  };
}(ELMO.Control));
