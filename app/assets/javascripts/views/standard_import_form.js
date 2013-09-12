// ELMO.Views.StandardImportForm
//
// View model for importing standard objects.
(function(ns, klass) {

  // constructor
  ns.StandardImportForm = klass = function(params) { var self = this;

    // setup the link
    $('a.import_standard').click(function(){ self.show_dialog(); return false; });
  };

  klass.prototype.show_dialog = function() { var self = this;
    console.log('foo');
  }
  
})(ELMO.Views);
