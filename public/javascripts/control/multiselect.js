// ELMO.Control.Multiselect
(function(ns, klass) {
  
  // constructor
  ns.Multiselect = klass = function(params) {
    this.params = params;

    this.fld = params.el;
    this.rebuild_options();
    this.dom_id = parseInt(Math.random() * 1000000);
  }
  
  // inherit from Control
  klass.prototype = new ns.Control();
  klass.prototype.constructor = klass;
  klass.prototype.parent = ns.Control.prototype;
  
  klass.prototype.build_field = function () {
    
  }
  
  klass.prototype.rebuild_options = function() {
    // empty old rows
    this.fld.empty();
    this.rows = [];
    
    // add new rows
    for (var i = 0; i < this.params.objs.length; i++) {
      var id = this.params.objs[i][this.params.id_key];
      var txt = this.params.objs[i][this.params.txt_key];
      var row = $("<div>");
      var dom_id = this.dom_id + "_" + i;
      
      $("<input>").attr("type", "checkbox").attr("value", id).attr("id", dom_id).appendTo(row);
      $("<label>").attr("for", dom_id).html("&nbsp;" + txt).appendTo(row);
      
      this.rows.push(row);
      this.fld.append(row);
    }
  }
  
  klass.prototype.update = function(selected_ids) {
    // convert selected_ids to string
    for (var i = 0; i < selected_ids.length; i++)
      selected_ids[i] = selected_ids[i].toString();
      
    this.update_without_triggering(selected_ids);
  }
  
  klass.prototype.update_without_triggering = function(selected_ids) {
    for (var i = 0; i < this.rows.length; i++)
      this.rows[i].find("input").prop("checked", selected_ids.indexOf(this.rows[i].find("input").attr("value")) != -1);
  }
  
  klass.prototype.update_objs = function(objs) {
    this.params.objs = objs;
    var seld = this.get();
    this.rebuild_options();
    this.update_without_triggering(seld);
  }
  
  klass.prototype.get = function() {
    var seld = [];
    for (var i = 0; i < this.rows.length; i++)
      if (this.rows[i].find("input").prop("checked"))
        seld.push(this.rows[i].find("input").attr("value"));
    return seld;
  }
  
  klass.prototype.enable = function(which) {
    if (which)
      this.fld.find("input[type='checkbox']").removeAttr("disabled");
    else
      this.fld.find("input[type='checkbox']").attr("disabled", "disabled");
    this.fld.css("color", which ? "" : "#888");
  }
  
}(ELMO.Control));