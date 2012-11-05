// ELMO.Report.FormSelectionEditPane < ELMO.Report.EditPane
(function(ns, klass) {
  
  // constructor
  ns.FormSelectionEditPane = klass = function() {
    this.build()
  }

  // inherit from EditPane
  klass.prototype = new ns.EditPane();
  klass.prototype.constructor = klass;
  klass.prototype.parent = ns.EditPane.prototype;
  
  klass.prototype.title = "Form Choices";

  // builds controls
  klass.prototype.build = function() {
    // call super first
    this.parent.build.call(this);
  }

  klass.prototype.update = function(report) {
  }

  // extracts data from the view into the model
  klass.prototype.extract = function() {
    
  }
  
}(ELMO.Report));