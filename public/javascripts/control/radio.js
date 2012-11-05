// ELMO.Control.Radio
(function(ns, klass) {
  
  // constructor
  ns.Radio = klass = function(params) {
    this.params = params;
    this.build();
  }
  
  // inherit from Control
  klass.prototype = new ns.Control();
  klass.prototype.constructor = klass;
  klass.prototype.parent = ns.Control.prototype;
  
  klass.prototype.build_field = function () {
    
    this.fld = $("<input>").attr("type", "radio");
    
    // add name and ID
    this.fld = this.fld.attr("name", this.name()).attr("id", this.id())
    
    // add value if necessary
    this.fld = this.fld.attr("value", this.params.value);
    
    return this.fld;
  }
  
  klass.prototype.id = function() {
    return this.parent.id.call(this) + "_" + this.params.value;
  }
  
  klass.prototype.checked = function(c) {
    return this.fld.prop("checked", c);
  }
  
  klass.prototype.value = function() {
    return this.fld.attr("value");
  }
  
  klass.prototype.change = function(func) {
    this.fld.bind("change", func);
  }
  
}(ELMO.Control));