// ELMO.Report.FieldSelectorSet
(function(ns, klass) {
  
  // constructor
  ns.FieldSelectorSet = klass = function(cont, menus) {
    var _this = this;
    this.cont = cont;
    this.menus = menus;
    
    // save and delete boilerplate HTML
    this.boilerplate = this.cont.find(".selectors").children(":first")[0].outerHTML;
    this.cont.find(".selectors").children().remove();
    
    this.selectors = [];
    this.deleted = [];
    
    // hookup add link
    this.cont.find("a.add").click(function(){ _this.add_selectors(1); return false; });
  }

  klass.prototype.update = function(report) {
    var _this = this;

    // save refs
    this.report = report;
    var calcs = $.extend(true, [], this.report.attribs.calculations);
    
    // remove any calculations that we've already marked deleted
    for (var i = calcs.length - 1; i >= 0; i--)
      if (this.deleted.indexOf(calcs[i].id) != -1)
        calcs.splice(i, 1);
    
    // get diff between num of calculations in report and cur number of selectors
    var diff = calcs.length - this.selectors.length;

    // add/delete any field_selectors if necessary
    if (diff < 0)
      this.remove_selectors(-diff);
    else if (diff > 0)
      this.add_selectors(diff);
    
    // update existing field_selectors to match report calculations
    $(calcs).each(function(idx, calc) {
      _this.selectors[idx].update(_this.report, calc);
    });
  }
  
  klass.prototype.get = function() { var self = this;
    var ret = [];
    
    // build array of calculation objects, excepting deleted objects
    $(self.selectors).each(function(){
      if (!this.calc || !this.calc.id || self.deleted.indexOf(this.calc.id) == -1)
        ret.push(this.get());
    });
    
    console.log(ret)
    return ret;
  }
  
  klass.prototype.add_selectors = function(how_many) {
    var _this = this;
    
    for (var i = 0; i < how_many; i++) {
      // create the element
      var el = $(this.boilerplate).appendTo(this.cont.find(".selectors"))
      
      // create the selector obj and add to the array
      var selector = new ns.FieldSelector(el, this.menus);
      
      // update to fill the options
      selector.update(this.report, null);
      
      // add to array
      this.selectors.push(selector);
      
      // hookup the remove link
      (function(_selector){
        el.find("a.remove").click(function(){ _this.remove_selector(_selector); return false; })
      })(selector);
    }
  }
  
  klass.prototype.remove_selectors = function(how_many) {
    // remove elements
    var old_num = this.selectors.length;
    for (var i = old_num - 1; i >= old_num - how_many; i--)
      this.remove_selector(this.selectors[i]);
  }
  
  klass.prototype.remove_selector = function(selector) {
    // get the index
    var idx = this.selectors.indexOf(selector);
    
    // remove the element
    this.selectors[idx].cont.remove();
    
    // save the ID (for deletion purposes) if it exists
    if (this.selectors[idx].calc && this.selectors[idx].calc.id)
      this.deleted.push(this.selectors[idx].calc.id);
    console.log("deleted", this.deleted)
    
    // remove from the array
    this.selectors.splice(idx, 1);
  }

}(ELMO.Report));