// ELMO.Control.RadioGroup
(function(ns, klass) {
  
  // constructor
  ns.RadioGroup = klass = function(params) {
    this.params = params;
    this.members = [];
    
    for (var i = 0; i < params.values.length; i++) {
      this.members.push(new ns.Radio({
        name: params.name,
        value: params.values[i],
        label_html: params.labels_html[i],
        click: function() { params.click(params.values[i]) },
        field_before_label: params.field_before_label
      }));
    }
  }
  
  klass.prototype.update = function(selected_value) {
    var selected_idx = this.params.values.indexOf(selected_value);
    
    // if value not found, uncheck all
    if (selected_idx == -1)
      for (var i = 0; i < this.members.length; i++)
        this.members[i].checked(false)
    else
      this.members[selected_idx].checked(true);
    
    // trigger change handler
    if (this.change_handler) this.change_handler();
  }
  
  klass.prototype.get = function() {
    for (var i = 0; i < this.members.length; i++)
      if (this.members[i].checked())
        return this.members[i].value();
  }
  
  klass.prototype.change = function(func) {
    this.change_handler = func;
    for (var i = 0; i < this.members.length; i++)
      this.members[i].change(func);
  }
  
  klass.prototype.append_all_to = function(cont) {
    for (var i = 0; i < this.members.length; i++)
      this.members[i].appendTo(cont);
  }
}(ELMO.Control));