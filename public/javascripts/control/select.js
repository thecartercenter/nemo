// ELMO.Control.Select
(function(ns, klass) {
  
  // constructor
  ns.Select = klass = function(params) {
    this.params = params;

    this.fld = params.el;
    
    this.opts = [];

    // add options
    for (var i = 0; i < this.params.objs.length; i++) {
      var id = this.params.objs[i][this.params.id_key];
      var txt = this.params.objs[i][this.params.txt_key];
      var opt = $("<option>").text(txt).attr("value", id);
      this.opts.push(opt);
      this.fld.append(opt);
    }
  }
  
  // inherit from Control
  klass.prototype = new ns.Control();
  klass.prototype.constructor = klass;
  klass.prototype.parent = ns.Control.prototype;
  
  klass.prototype.update = function(selected_id) {
    for (var i = 0; i < this.opts.length; i++)
      this.opts[i].prop("selected", selected_id == null ? false : (selected_id.toString() == this.opts[i].attr("value")));

    // trigger change event
    this.fld.trigger("change");
  }
  
  klass.prototype.get = function() {
    for (var i = 0; i < this.opts.length; i++)
      if (this.opts[i].prop("selected"))
        return this.opts[i].attr("value");
    return null;
  }
  
  klass.prototype.change = function(func) {
    this.fld.bind("change", func);
  }
  
  klass.prototype.enable = function(which) {
    if (which)
      this.fld.removeAttr("disabled");
    else
      this.fld.attr("disabled", "disabled");
    this.fld.css("color", which ? "" : "#888");
  }
  
}(ELMO.Control));