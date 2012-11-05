// ELMO.Control.Control
(function(ns, klass) {
  
  // constructor
  ns.Control = klass = function() {
  }
  
  klass.prototype.build = function() {
      
    // build wrapper
    var wrapper = $("<div>").attr("id", this.id() + "_wrp");
    
    // build label
    if (this.params.label_html)
      var lbl = $("<label>").attr("for", this.id()).html(this.params.label_html);
    
    // build field
    var fld = this.build_field();
    
    if (lbl)
      return wrapper.append(this.params.field_before_label ? fld.after(lbl) : lbl.after(fld));
    else
      return fld;
  }
  
  klass.prototype.id = function() {
    return this.params.prefix ? this.params.prefix + "_" + this.params.name : this.params.name;
  }
  
  klass.prototype.name = function() {
    return this.params.prefix ? this.params.prefix + "[" + this.params.name + "]" : this.params.name;
  }
  
  klass.prototype.appendTo = function(el) {
    this.build().appendTo(el);
  }
}(ELMO.Control));